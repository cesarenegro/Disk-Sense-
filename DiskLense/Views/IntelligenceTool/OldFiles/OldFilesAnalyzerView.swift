import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct OldFilesAnalyzerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model = OldFilesAnalyzerViewModel()
    @StateObject private var actionList = ActionListManager.shared

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.contentTop, AppTheme.contentBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                header

                controls

                if model.isScanning {
                    ProgressView(value: model.progress)
                        .frame(width: 320)
                        .tint(.white)
                    Text(model.statusText)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.75))
                }

                resultsHeader

                resultsList

                Spacer()
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)
            .padding(.bottom, 24)
        }
    }

    private var header: some View {
        HStack {
            Button("←") { dismiss() }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            Spacer()

            VStack(spacing: 6) {
                Text("Old Files Analyzer")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text("Find files that are old, unused, or outdated")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            SidebarStyleButton(
                title: "Scan Downloads",
                assetIcon: Asset.icSmartClean,
                isEnabled: !model.isScanning,
                action: { model.scanDownloads() }
            )

            SidebarStyleButton(
                title: "Manual Selection",
                assetIcon: Asset.icSmartClean,
                isEnabled: !model.isScanning,
                action: { model.pickRootAndScan() }
            )

            Menu {
                Picker("Age", selection: $model.ageFilter) {
                    ForEach(OldFileAgeFilter.allCases, id: \.self) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "calendar")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text(model.ageFilter.title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.pillRadius, style: .continuous)
                        .fill(Color("ButtonDropDown"))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.pillRadius, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
            }
            .frame(width: 200, height: 44)
            .buttonStyle(.plain)
        }
    }

    private var resultsHeader: some View {
        HStack {
            Text("Detected Files")
                .font(.headline)
                .foregroundColor(.white)

            Spacer()

            Text("\(model.items.count) items")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }

    private var resultsList: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(model.groupedItems.keys.sorted(), id: \.self) { tag in
                    if let items = model.groupedItems[tag] {
                        OldFilesCategorySection(
                            tag: tag,
                            items: items,
                            open: { model.reveal($0) },
                            trash: { model.trash($0) },
                            queue: { actionList.add(item: ActionListItem(title: $0.name, path: $0.path, size: $0.size, source: "Old Files")) },
                            isQueued: { item in
                                actionList.items.contains(where: { $0.path == item.path })
                            },
                            setSelected: { item, isOn in
                                if isOn {
                                    actionList.add(item: ActionListItem(title: item.name, path: item.path, size: item.size, source: "Old Files"))
                                } else {
                                    actionList.remove(path: item.path)
                                }
                            }
                        )
                    }
                }

                if model.items.isEmpty && !model.isScanning {
                    CustomEmptyStateView(
                        title: "No Old Files Found",
                        message: "Choose a folder to analyze for old and unused files.",
                        icon: "clock.arrow.circlepath",
                        actionTitle: "Scan Downloads",
                        action: { model.scanDownloads() }
                    )
                    .frame(height: 240)
                }
            }
        }
    }
}

private struct OldFilesCategorySection: View {
    let tag: String
    let items: [OldFileItem]
    let open: (OldFileItem) -> Void
    let trash: (OldFileItem) -> Void
    let queue: (OldFileItem) -> Void
    let isQueued: (OldFileItem) -> Bool
    let setSelected: (OldFileItem, Bool) -> Void
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Button {
                    isExpanded.toggle()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .foregroundColor(.white.opacity(0.75))
                        Text(tag)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)

                Spacer()

                Text("\(items.count) items")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }

            if isExpanded {
                VStack(spacing: 10) {
                    ForEach(items) { item in
                        OldFileRow(
                            item: item,
                            open: { open(item) },
                            trash: { trash(item) },
                            queue: { queue(item) },
                            isQueued: isQueued(item),
                            setSelected: { isOn in
                                setSelected(item, isOn)
                            }
                        )
                    }
                }
            }
        }
    }
}

private struct OldFileRow: View {
    let item: OldFileItem
    let open: () -> Void
    let trash: () -> Void
    let queue: () -> Void
    let isQueued: Bool
    let setSelected: (Bool) -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                SelectionCheckbox(isSelected: Binding(get: { isQueued }, set: { setSelected($0) }))

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)

                    Text(item.reason)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.65))
                        .lineLimit(2)
                }

                Spacer()

                Text(item.formattedSize)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
            }

            HStack {
                Text(item.path)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.55))
                    .lineLimit(1)

                Spacer()

                Button("Reveal") { open() }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))

                Button(isQueued ? "Queued" : "Add to Action List") { queue() }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    .foregroundColor(isQueued ? .green : .blue)
                    .disabled(isQueued)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

@MainActor
final class OldFilesAnalyzerViewModel: ObservableObject {
    @Published var isScanning = false
    @Published var progress: Double = 0
    @Published var statusText: String = ""
    @Published var currentRootPath: String?
    @Published var items: [OldFileItem] = []
    @Published var ageFilter: OldFileAgeFilter = .days90

    var groupedItems: [String: [OldFileItem]] {
        Dictionary(grouping: items) { $0.tag }
            .mapValues { $0.sorted { $0.size > $1.size } }
    }

    func scanDownloads() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let scanRoots = [
            home.appendingPathComponent("Downloads"),
            home.appendingPathComponent("Documents"),
            home.appendingPathComponent("Desktop"),
            home.appendingPathComponent("Pictures"),
            home.appendingPathComponent("Movies"),
            home.appendingPathComponent("Music")
        ]
        currentRootPath = home.path
        scan(roots: scanRoots)
    }

    func pickRootAndScan() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        if panel.runModal() == .OK, let url = panel.url {
            currentRootPath = url.path
            scan(roots: [url])
        }
    }

    func reveal(_ item: OldFileItem) {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: item.path)])
    }

    func trash(_ item: OldFileItem) {
        do {
            try FileManager.default.trashItem(at: URL(fileURLWithPath: item.path), resultingItemURL: nil)
        } catch {
            return
        }
        items.removeAll { $0.id == item.id }
    }

    private func scan(roots: [URL]) {
        isScanning = true
        progress = 0
        statusText = "Scanning…"
        items.removeAll()

        let ageDays = ageFilter.days

        Task.detached(priority: .utility) {
            let results = Self.scanOldFiles(roots: roots, ageDays: ageDays) { progress, current in
                Task { @MainActor in
                    self.progress = progress
                    self.statusText = current
                }
            }

            Task { @MainActor in
                self.items = results
                self.isScanning = false
                self.progress = 1
                self.statusText = "Scan complete"
            }
        }
    }

    nonisolated private static func scanOldFiles(
        roots: [URL],
        ageDays: Int,
        onProgress: @escaping (Double, String) -> Void
    ) -> [OldFileItem] {
        let fm = FileManager.default
        var results: [OldFileItem] = []
        let cutoff = Date().addingTimeInterval(TimeInterval(-ageDays * 86_400))
        var processed = 0

        for root in roots {
            guard let enumerator = fm.enumerator(
                at: root,
                includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey, .creationDateKey, .contentAccessDateKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants],
                errorHandler: { _, _ in true }
            ) else { continue }

            for case let url as URL in enumerator {
                processed += 1
                if processed % 800 == 0 {
                    onProgress(min(Double(processed) / 80_000.0, 0.98), url.path)
                }

                guard let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey, .creationDateKey, .contentAccessDateKey]) else {
                    continue
                }
                guard values.isRegularFile == true else { continue }

                let size = Int64(values.fileSize ?? 0)
                if size <= 0 { continue }

                let created = values.creationDate
                let modified = values.contentModificationDate
                let accessed = values.contentAccessDate

                let path = url.path
                let ext = url.pathExtension.lowercased()
                let isDownloads = path.contains("/Downloads/")
                let isDocuments = path.contains("/Documents/") || path.contains("/Desktop/")

                let modifiedOld = (modified ?? created ?? Date()) < cutoff
                let neverOpened = accessed == nil && modifiedOld

                let downloadedOnce: Bool = {
                    guard isDownloads, let c = created, let m = modified else { return false }
                    let delta = abs(c.timeIntervalSince(m))
                    if delta > 300 { return false }
                    if let a = accessed {
                        return abs(a.timeIntervalSince(c)) < 300
                    }
                    return true
                }()

                let isInstaller = isDownloads && ["dmg", "pkg", "iso"].contains(ext) && modifiedOld

                var tag: String?
                var reason = ""

                if isInstaller {
                    tag = "Obsolete Installers"
                    reason = "Installer in Downloads older than \(ageDays) days"
                } else if downloadedOnce && modifiedOld {
                    tag = "Forgotten Downloads"
                    reason = "Downloaded once and never opened"
                } else if neverOpened {
                    tag = "Never Opened"
                    reason = "No access date and old modification"
                } else if modifiedOld && isDocuments {
                    tag = "Stale Documents"
                    reason = "Not modified in \(ageDays) days"
                }

                if let tag {
                    results.append(OldFileItem(
                        name: url.lastPathComponent,
                        path: path,
                        size: size,
                        tag: tag,
                        reason: reason
                    ))
                }
            }
        }

        return results.sorted { $0.size > $1.size }
    }
}

struct OldFileItem: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let size: Int64
    let tag: String
    let reason: String

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

enum OldFileAgeFilter: String, CaseIterable {
    case days30
    case days90
    case year1

    var title: String {
        switch self {
        case .days30: return "30 days"
        case .days90: return "90 days"
        case .year1: return "1 year"
        }
    }

    var days: Int {
        switch self {
        case .days30: return 30
        case .days90: return 90
        case .year1: return 365
        }
    }
}

private struct SidebarStyleButton: View {
    let title: String
    let assetIcon: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(assetIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .opacity(isEnabled ? 1 : 0.5)

                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.pillRadius, style: .continuous)
                    .fill(isEnabled ? AppTheme.accent : Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.pillRadius, style: .continuous)
                    .stroke(Color.white.opacity(isEnabled ? 0.25 : 0.12), lineWidth: 1)
            )
            .frame(width: 200, height: 44)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

#Preview {
    OldFilesAnalyzerView()
        .frame(width: 1000, height: 720)
}
