import SwiftUI
import AppKit

struct ProjectJunkDetectorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model = ProjectJunkDetectorViewModel()
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
                Text("Project Junk Detector")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text("Find safe‑to‑remove developer and creative caches")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            SidebarStyleButton(
                title: "Scan",
                assetIcon: Asset.icSmartClean,
                isEnabled: !model.isScanning,
                action: { model.scanDefault() }
            )

            SidebarStyleButton(
                title: "Manual Selection",
                assetIcon: Asset.icSmartClean,
                isEnabled: !model.isScanning,
                action: { model.pickRootAndScan() }
            )

            SidebarStyleButton(
                title: "Rescan",
                assetIcon: Asset.icSmartClean,
                isEnabled: !model.isScanning && model.currentRootPath != nil,
                action: { model.scanCurrentRoot() }
            )
        }
    }

    private var resultsHeader: some View {
        HStack {
            Text("Detected Caches")
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
                ForEach(model.groupedItems.keys.sorted(), id: \.self) { category in
                    if let items = model.groupedItems[category] {
                        ProjectJunkCategorySection(
                            category: category,
                            items: items,
                            open: { model.reveal($0) },
                            trash: { model.trash($0) },
                            queue: { actionList.add(item: ActionListItem(title: $0.title, path: $0.path, size: $0.size, source: "Project Junk")) },
                            isQueued: { item in
                                actionList.items.contains(where: { $0.path == item.path })
                            },
                            isSelected: { item in
                                actionList.items.contains(where: { $0.path == item.path })
                            },
                            setSelected: { item, isOn in
                                if isOn {
                                    actionList.add(item: ActionListItem(title: item.title, path: item.path, size: item.size, source: "Project Junk"))
                                } else {
                                    actionList.remove(path: item.path)
                                }
                            }
                        )
                    }
                }

                if model.items.isEmpty && !model.isScanning {
                    CustomEmptyStateView(
                        title: "No Caches Found",
                        message: "Choose a folder to scan for developer and creative caches.",
                        icon: "hammer",
                        actionTitle: "Select Folder",
                        action: { model.pickRootAndScan() }
                    )
                    .frame(height: 240)
                }
            }
        }
    }
}

private struct ProjectJunkRow: View {
    let item: ProjectJunkItem
    let open: () -> Void
    let trash: () -> Void
    let queue: () -> Void
    let isQueued: Bool
    let isSelected: Bool
    let setSelected: (Bool) -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                SelectionCheckbox(isSelected: Binding(get: { isSelected }, set: { setSelected($0) }))

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)

                    Text(item.description)
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

private struct ProjectJunkCategorySection: View {
    let category: String
    let items: [ProjectJunkItem]
    let open: (ProjectJunkItem) -> Void
    let trash: (ProjectJunkItem) -> Void
    let queue: (ProjectJunkItem) -> Void
    let isQueued: (ProjectJunkItem) -> Bool
    let isSelected: (ProjectJunkItem) -> Bool
    let setSelected: (ProjectJunkItem, Bool) -> Void
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Button {
                    isExpanded.toggle()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .foregroundColor(.white.opacity(0.75))
                        Text(category)
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
                        ProjectJunkRow(
                            item: item,
                            open: { open(item) },
                            trash: { trash(item) },
                            queue: { queue(item) },
                            isQueued: isQueued(item),
                            isSelected: isSelected(item),
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

@MainActor
final class ProjectJunkDetectorViewModel: ObservableObject {
    @Published var isScanning = false
    @Published var progress: Double = 0
    @Published var statusText: String = ""
    @Published var currentRootPath: String?
    @Published var items: [ProjectJunkItem] = []

    var groupedItems: [String: [ProjectJunkItem]] {
        Dictionary(grouping: items) { $0.category }
            .mapValues { $0.sorted { $0.size > $1.size } }
    }

    private let bookmarkKey = "projectJunkBookmarks"

    func pickRootAndScan() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        if panel.runModal() == .OK, let url = panel.url {
            saveBookmarks(for: [url])
            currentRootPath = url.path
            scan(root: url)
        }
    }

    func scanDefault() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        currentRootPath = home.path
        scan(root: home)
    }

    func scanCurrentRoot() {
        guard let path = currentRootPath else { return }
        scan(root: URL(fileURLWithPath: path))
    }

    func reveal(_ item: ProjectJunkItem) {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: item.path)])
    }

    func trash(_ item: ProjectJunkItem) {
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

        Task.detached(priority: .utility) {
            let results = Self.scanForJunk(root: root) { progress, current in
                Task { @MainActor in
                    self.progress = progress
                    self.statusText = current
                }
            }

            Task { @MainActor in
                self.items = results.sorted { $0.size > $1.size }
                self.isScanning = false
                self.progress = 1
                self.statusText = "Scan complete"
            }
        }
    }

    private func saveBookmarks(for urls: [URL]) {
        let data = urls.compactMap { url in
            try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        }
        UserDefaults.standard.set(data, forKey: bookmarkKey)
    }

    nonisolated private static func scanForJunk(
        root: URL,
        onProgress: @escaping (Double, String) -> Void
    ) -> [ProjectJunkItem] {
        var results: [ProjectJunkItem] = []
        let fm = FileManager.default
        let installedApps = installedAppNames()

        let patterns: [ProjectJunkPattern] = [
            // Xcode
            .fixed(category: "Xcode", title: "Xcode DerivedData", description: "Build artifacts and caches created by Xcode.", path: "~/Library/Developer/Xcode/DerivedData", requiredApps: ["xcode"]),
            .fixed(category: "Xcode", title: "Xcode Archives", description: "Archived builds stored by Xcode.", path: "~/Library/Developer/Xcode/Archives", requiredApps: ["xcode"]),
            .fixed(category: "Xcode", title: "Xcode Device Support", description: "iOS device support files for Xcode.", path: "~/Library/Developer/Xcode/iOS DeviceSupport", requiredApps: ["xcode"]),
            .fixed(category: "Xcode", title: "Xcode Previews Cache", description: "Preview build caches used by SwiftUI previews.", path: "~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex", requiredApps: ["xcode"]),

            // Swift / SPM
            .glob(category: "Swift / SPM", title: "Swift .build", description: "SwiftPM build output folders.", name: ".build", requiredApps: []),
            .glob(category: "Swift / SPM", title: "Package.resolved Cache", description: "Resolved package metadata stored in repos.", name: "Package.resolved", requiredApps: []),

            // Node / Web
            .glob(category: "Node / Web", title: "node_modules", description: "Node dependencies (can be reinstalled).", name: "node_modules", requiredApps: []),
            .glob(category: "Node / Web", title: ".next", description: "Next.js build cache.", name: ".next", requiredApps: []),
            .glob(category: "Node / Web", title: "dist", description: "Build output folder.", name: "dist", requiredApps: []),
            .glob(category: "Node / Web", title: "build", description: "Build output folder.", name: "build", requiredApps: []),

            // Adobe / Design
            .fixed(category: "Adobe", title: "Adobe Media Cache", description: "Adobe media cache files.", path: "~/Library/Application Support/Adobe/Common/Media Cache Files", requiredApps: ["adobe", "photoshop", "illustrator", "premiere", "after effects", "lightroom"]),
            .fixed(category: "Adobe", title: "After Effects Disk Cache", description: "After Effects disk cache.", path: "~/Library/Application Support/Adobe/Common/Media Cache", requiredApps: ["after effects"]),
            .fixed(category: "Adobe", title: "Adobe Cache (Sandbox)", description: "Adobe app cache in sandbox containers.", path: "~/Library/Containers/com.adobe.*", requiredApps: ["adobe"]),
            .fixed(category: "Blender", title: "Blender Cache", description: "Blender cache data.", path: "~/Library/Application Support/Blender", requiredApps: ["blender"]),
            .fixed(category: "Figma", title: "Figma Cache", description: "Figma cache files.", path: "~/Library/Application Support/Figma", requiredApps: ["figma"]),
            .fixed(category: "Figma", title: "Figma Cache (Sandbox)", description: "Figma cache files in sandbox container.", path: "~/Library/Containers/com.figma.Desktop/Data/Library/Application Support/Figma", requiredApps: ["figma"]),
            .fixed(category: "AutoCAD", title: "AutoCAD Cache", description: "AutoCAD cache and temp files.", path: "~/Library/Application Support/Autodesk", requiredApps: ["autocad", "autodesk"]),
            .fixed(category: "SketchUp", title: "SketchUp Cache", description: "SketchUp caches and temp files.", path: "~/Library/Application Support/SketchUp", requiredApps: ["sketchup"]),
            .fixed(category: "SketchUp", title: "SketchUp Cache (Sandbox)", description: "SketchUp cache in sandbox container.", path: "~/Library/Containers/com.sketchup.*", requiredApps: ["sketchup"])
        ]

        let rootPath = root.path
        let expandedPatterns = patterns.map { $0.expanded() }
        let knownTokens = Set(expandedPatterns.flatMap { $0.requiredApps }.map { $0.lowercased() })

        var processed = 0

        // Check fixed paths first (only if app is installed)
        for pattern in expandedPatterns {
            processed += 1
            onProgress(min(Double(processed) / 200.0, 0.8), pattern.displayPath)

            if pattern.isFixed, shouldInclude(pattern: pattern, installedApps: installedApps) {
                if fm.fileExists(atPath: pattern.displayPath) {
                    let size = JunkAnalyzer.directorySize(atPath: pattern.displayPath)
                    if size > 0 {
                        results.append(ProjectJunkItem(
                            category: pattern.category,
                            title: pattern.title,
                            description: pattern.description,
                            path: pattern.displayPath,
                            size: size
                        ))
                    }
                }
            }
        }

        // Enumerate inside root for glob matches
        guard let enumerator = fm.enumerator(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants],
            errorHandler: { _, _ in true }
        ) else { return results }

        for case let url as URL in enumerator {
            processed += 1
            if processed % 600 == 0 {
                onProgress(min(0.8 + Double(processed) / 80_000.0, 0.98), url.path)
            }

            let name = url.lastPathComponent
            guard let pattern = expandedPatterns.first(where: { !$0.isFixed && $0.name == name }) else { continue }
            guard shouldInclude(pattern: pattern, installedApps: installedApps) else { continue }

            let size = JunkAnalyzer.directorySize(atPath: url.path)
            if size > 0 {
                results.append(ProjectJunkItem(
                    category: pattern.category,
                    title: pattern.title,
                    description: pattern.description,
                    path: url.path,
                    size: size
                ))
            }
        }

        results.append(contentsOf: otherAppCaches(installedApps: installedApps, knownTokens: knownTokens))

        return results.filter { $0.path.hasPrefix(rootPath) || $0.path.hasPrefix(FileManager.default.homeDirectoryForCurrentUser.path) }
    }

    nonisolated private static func installedAppNames() -> [String] {
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

    nonisolated private static func shouldInclude(pattern: ProjectJunkPattern, installedApps: [String]) -> Bool {
        if pattern.requiredApps.isEmpty { return true }
        for token in pattern.requiredApps.map({ $0.lowercased() }) {
            if installedApps.contains(where: { $0.contains(token) }) {
                return true
            }
        }
        return false
    }

    nonisolated private static func otherAppCaches(installedApps: [String], knownTokens: Set<String>) -> [ProjectJunkItem] {
        let fm = FileManager.default
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let cacheRoots = ["\(home)/Library/Caches", "\(home)/Library/Application Support"]

        let tokens = installedApps
            .flatMap { $0.split(separator: " ").map { String($0) } }
            .map { $0.lowercased() }
            .filter { $0.count >= 4 && !knownTokens.contains($0) }

        guard !tokens.isEmpty else { return [] }

        var results: [ProjectJunkItem] = []
        var seenPaths = Set<String>()

        for root in cacheRoots {
            guard let contents = try? fm.contentsOfDirectory(atPath: root) else { continue }
            for name in contents {
                let lower = name.lowercased()
                guard tokens.contains(where: { lower.contains($0) }) else { continue }

                let path = "\(root)/\(name)"
                guard !seenPaths.contains(path) else { continue }
                seenPaths.insert(path)

                let size = JunkAnalyzer.directorySize(atPath: path)
                if size > 0 {
                    results.append(ProjectJunkItem(
                        category: "Other Apps",
                        title: "Cache: \(name)",
                        description: "App cache and support data.",
                        path: path,
                        size: size
                    ))
                }
            }
        }

        return results
    }
}

struct ProjectJunkItem: Identifiable {
    let id = UUID()
    let category: String
    let title: String
    let description: String
    let path: String
    let size: Int64

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

struct ProjectJunkPattern {
    let category: String
    let title: String
    let description: String
    let name: String
    let path: String
    let isFixed: Bool
    let requiredApps: [String]

    static func fixed(category: String, title: String, description: String, path: String, requiredApps: [String]) -> ProjectJunkPattern {
        ProjectJunkPattern(category: category, title: title, description: description, name: "", path: path, isFixed: true, requiredApps: requiredApps)
    }

    static func glob(category: String, title: String, description: String, name: String, requiredApps: [String]) -> ProjectJunkPattern {
        ProjectJunkPattern(category: category, title: title, description: description, name: name, path: "", isFixed: false, requiredApps: requiredApps)
    }

    func expanded() -> ProjectJunkPattern {
        ProjectJunkPattern(
            category: category,
            title: title,
            description: description,
            name: name,
            path: (path as NSString).expandingTildeInPath,
            isFixed: isFixed,
            requiredApps: requiredApps
        )
    }

    var displayPath: String { isFixed ? path : name }
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
    ProjectJunkDetectorView()
        .frame(width: 1000, height: 720)
}
