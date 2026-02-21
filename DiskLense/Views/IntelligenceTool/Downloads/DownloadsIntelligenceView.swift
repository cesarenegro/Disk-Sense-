import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct DownloadsIntelligenceView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model = DownloadsIntelligenceViewModel()
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
                    CustomProgressWheelView(
                        progress: model.progress,
                        title: "Scanning…",
                        subtitle: model.statusText,
                        size: 200
                    )
                    .frame(width: 240, height: 240)
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
                Text("Download Folder Intelligence")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text("Analyze Downloads and suggest safe cleanups")
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

            Menu {
                Picker("Age", selection: $model.ageThresholdDays) {
                    ForEach(DownloadsAgeFilter.allCases, id: \.self) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "calendar")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text(model.ageThresholdDays.title)
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
            Text("Suggestions")
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
                        DownloadsCategorySection(
                            tag: tag,
                            items: items,
                            open: { model.reveal($0) },
                            trash: { model.trash($0) },
                            queue: { actionList.add(item: ActionListItem(title: $0.name, path: $0.path, size: $0.size, source: "Downloads")) },
                            isQueued: { item in
                                actionList.items.contains(where: { $0.path == item.path })
                            }
                        )
                    }
                }

                if model.items.isEmpty && !model.isScanning {
                    CustomEmptyStateView(
                        title: "No Suggestions",
                        message: "Scan Downloads to find cleanup candidates.",
                        icon: "arrow.down.circle",
                        actionTitle: "Scan Downloads",
                        action: { model.scanDownloads() }
                    )
                    .frame(height: 240)
                }
            }
        }
    }
}

private struct DownloadsCategorySection: View {
    let tag: String
    let items: [DownloadItem]
    let open: (DownloadItem) -> Void
    let trash: (DownloadItem) -> Void
    let queue: (DownloadItem) -> Void
    let isQueued: (DownloadItem) -> Bool
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
                        DownloadRow(
                            item: item,
                            open: { open(item) },
                            trash: { trash(item) },
                            queue: { queue(item) },
                            isQueued: isQueued(item)
                        )
                    }
                }
            }
        }
    }
}

private struct DownloadRow: View {
    let item: DownloadItem
    let open: () -> Void
    let trash: () -> Void
    let queue: () -> Void
    let isQueued: Bool

    var body: some View {
        VStack(spacing: 8) {
            HStack {
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

                Button("Move to Trash") { trash() }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.9))
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
final class DownloadsIntelligenceViewModel: ObservableObject {
    @Published var isScanning = false
    @Published var progress: Double = 0
    @Published var statusText: String = ""
    @Published var items: [DownloadItem] = []
    @Published var ageThresholdDays: DownloadsAgeFilter = .days30

    var groupedItems: [String: [DownloadItem]] {
        Dictionary(grouping: items) { $0.tag }
            .mapValues { $0.sorted { $0.size > $1.size } }
    }

    func scanDownloads() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let downloads = home.appendingPathComponent("Downloads")
        scan(root: downloads)
    }

    func reveal(_ item: DownloadItem) {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: item.path)])
    }

    func trash(_ item: DownloadItem) {
        do {
            try FileManager.default.trashItem(at: URL(fileURLWithPath: item.path), resultingItemURL: nil)
        } catch {
            return
        }
        items.removeAll { $0.id == item.id }
    }

    private func scan(root: URL) {
        isScanning = true
        progress = 0
        statusText = "Scanning…"
        items.removeAll()

        let ageDays = ageThresholdDays.days

        Task.detached(priority: .utility) {
            let results = Self.scanDownloads(root: root, ageDays: ageDays) { progress, current in
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

    nonisolated private static func scanDownloads(
        root: URL,
        ageDays: Int,
        onProgress: @escaping (Double, String) -> Void
    ) -> [DownloadItem] {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey, .creationDateKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants],
            errorHandler: { _, _ in true }
        ) else { return [] }

        var fileMap: [String: URL] = [:]
        var archiveBases: [String: URL] = [:]
        var results: [DownloadItem] = []

        let cutoff = Date().addingTimeInterval(TimeInterval(-ageDays * 86_400))
        var processed = 0

        let installedApps = installedApplicationNames()

        for case let url as URL in enumerator {
            processed += 1
            if processed % 800 == 0 {
                onProgress(min(Double(processed) / 60_000.0, 0.98), url.path)
            }

            guard let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey, .creationDateKey]) else {
                continue
            }
            guard values.isRegularFile == true else { continue }

            let size = Int64(values.fileSize ?? 0)
            if size <= 0 { continue }

            let name = url.lastPathComponent
            let ext = url.pathExtension.lowercased()
            let base = url.deletingPathExtension().lastPathComponent

            fileMap[name] = url

            if isArchive(ext) {
                archiveBases[base] = url
            }

            if isInstaller(ext) {
                let modified = values.contentModificationDate ?? values.creationDate ?? Date()
                if modified < cutoff {
                    let appInstalled = installedApps.contains(where: { $0.contains(base.lowercased()) })
                    if appInstalled {
                        results.append(DownloadItem(
                            name: name,
                            path: url.path,
                            size: size,
                            tag: "Installed Apps",
                            reason: "Installer appears unused; app already installed"
                        ))
                    } else {
                        results.append(DownloadItem(
                            name: name,
                            path: url.path,
                            size: size,
                            tag: "Installers",
                            reason: "Installer older than \(ageDays) days"
                        ))
                    }
                }
            }

            if isMedia(ext) {
                let modified = values.contentModificationDate ?? values.creationDate ?? Date()
                if modified < cutoff {
                    let tag = mediaTag(for: ext)
                    results.append(DownloadItem(
                        name: name,
                        path: url.path,
                        size: size,
                        tag: tag,
                        reason: "Media file older than \(ageDays) days"
                    ))
                }
            }
        }

        // Archive extracted but archive still present
        let fileNames = Set(fileMap.keys)
        for (base, archiveUrl) in archiveBases {
            if fileNames.contains(base) || fileNames.contains(base + "/") {
                let size = JunkAnalyzer.directorySize(atPath: archiveUrl.path)
                results.append(DownloadItem(
                    name: archiveUrl.lastPathComponent,
                    path: archiveUrl.path,
                    size: size,
                    tag: "Archives",
                    reason: "Archive and extracted folder both exist"
                ))
            }
        }

        return results.sorted { $0.size > $1.size }
    }

    nonisolated private static func isInstaller(_ ext: String) -> Bool {
        ["dmg", "pkg", "iso"].contains(ext)
    }

    nonisolated private static func isArchive(_ ext: String) -> Bool {
        ["zip", "rar", "7z", "tar", "gz"].contains(ext)
    }

    nonisolated private static func isMedia(_ ext: String) -> Bool {
        mediaTag(for: ext) != "Other Media"
    }

    nonisolated private static func mediaTag(for ext: String) -> String {
        if ["jpg", "jpeg", "png", "gif", "heic", "webp"].contains(ext) { return "Images" }
        if ["mp4", "mov", "mkv", "avi", "m4v"].contains(ext) { return "Videos" }
        if ["mp3", "wav", "m4a", "flac", "aac"].contains(ext) { return "Audio" }
        return "Other Media"
    }

    nonisolated private static func installedApplicationNames() -> [String] {
        let fm = FileManager.default
        let appDirs = ["/Applications", ("~/Applications" as NSString).expandingTildeInPath]
        var names: [String] = []

        for dir in appDirs {
            guard let contents = try? fm.contentsOfDirectory(atPath: dir) else { continue }
            for item in contents where item.hasSuffix(".app") {
                let name = (item as NSString).deletingPathExtension.lowercased()
                names.append(name)
            }
        }
        return names
    }
}

struct DownloadItem: Identifiable {
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

enum DownloadsAgeFilter: String, CaseIterable {
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
            .frame(width: 200)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

#Preview {
    DownloadsIntelligenceView()
        .frame(width: 1000, height: 720)
}
