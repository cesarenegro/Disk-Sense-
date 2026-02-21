import Foundation
import SwiftUI

@MainActor
final class ActionListManager: ObservableObject {
    static let shared = ActionListManager()

    @Published var items: [ActionListItem] = []
    @Published var logs: [ActionLogEntry] = []

    private let logKey = "sc.actionListLogs"

    private init() {
        loadLogs()
    }

    func add(item: ActionListItem) {
        guard !items.contains(where: { $0.path == item.path }) else { return }
        items.append(item)
    }

    func remove(path: String) {
        items.removeAll { $0.path == path }
    }

    func clear() {
        items.removeAll()
    }

    var totalBytes: Int64 {
        items.reduce(0) { $0 + $1.size }
    }

    func confirmTrashSelected() async {
        var moved: [ActionListItem] = []
        for item in items {
            let url = URL(fileURLWithPath: item.path)
            do {
                try FileManager.default.trashItem(at: url, resultingItemURL: nil)
                moved.append(item)
            } catch {
                continue
            }
        }

        if !moved.isEmpty {
            let entry = ActionLogEntry(date: Date(), items: moved)
            logs.insert(entry, at: 0)
            persistLogs()
        }

        items.removeAll { moved.contains($0) }
    }

    func openTrash() {
        let trashPath = ("~/.Trash" as NSString).expandingTildeInPath
        NSWorkspace.shared.open(URL(fileURLWithPath: trashPath))
    }

    private func persistLogs() {
        #if RELEASE_SCREENSHOT
        return
        #endif
        if let data = try? JSONEncoder().encode(logs) {
            UserDefaults.standard.set(data, forKey: logKey)
        }
    }

    func clearLogs() {
        logs.removeAll()
        UserDefaults.standard.removeObject(forKey: logKey)
    }

    private func loadLogs() {
        #if RELEASE_SCREENSHOT
        return
        #endif
        guard let data = UserDefaults.standard.data(forKey: logKey),
              let decoded = try? JSONDecoder().decode([ActionLogEntry].self, from: data) else { return }
        logs = decoded
    }
}

#if RELEASE_SCREENSHOT
extension ActionListManager {
    func applyScreenshotDemoData(_ demo: ScreenshotDemoData) {
        items = demo.actionList.items.map {
            ActionListItem(title: $0.title, path: $0.path, size: $0.size, source: $0.source)
        }
        logs = demo.actionList.logs.compactMap { entry in
            guard let date = demo.parsedDate(entry.date) else { return nil }
            let items = entry.items.map {
                ActionListItem(title: $0.title, path: $0.path, size: $0.size, source: $0.source)
            }
            return ActionLogEntry(date: date, items: items)
        }
    }
}
#endif

struct ActionListItem: Identifiable, Hashable, Codable {
    let id: UUID
    let title: String
    let path: String
    let size: Int64
    let source: String

    init(id: UUID = UUID(), title: String, path: String, size: Int64, source: String) {
        self.id = id
        self.title = title
        self.path = path
        self.size = size
        self.source = source
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

struct ActionLogEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let items: [ActionListItem]

    init(id: UUID = UUID(), date: Date, items: [ActionListItem]) {
        self.id = id
        self.date = date
        self.items = items
    }

    var totalSize: Int64 {
        items.reduce(0) { $0 + $1.size }
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
}
