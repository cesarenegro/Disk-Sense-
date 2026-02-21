import SwiftUI
import UniformTypeIdentifiers

struct DiskVisualizerView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model = DiskVisualizerViewModel()

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

                listHeader

                folderList

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
                Text("Disk Visualizer")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text("Storage map with hierarchical drill‑down")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            SidebarStyleButton(
                title: "Select Folder",
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

            Toggle("Treat packages as folders", isOn: $model.expandPackages)
                .toggleStyle(.switch)
                .foregroundColor(.white.opacity(0.8))
        }
    }

    private var listHeader: some View {
        HStack {
            Text(model.currentRootName)
                .font(.headline)
                .foregroundColor(.white)

            Spacer()

            Text("Top \(model.topN)")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }

    private var folderList: some View {
        ScrollView {
            VStack(spacing: 10) {
                ForEach(model.currentChildren.prefix(model.topN), id: \.path) { node in
                    Button {
                        model.drillDown(to: node.path)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "folder")
                                .foregroundColor(.white.opacity(0.8))

                            VStack(alignment: .leading, spacing: 3) {
                                Text(node.displayName)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)

                                HStack(spacing: 6) {
                                    Text(node.categoryTag)
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.6))

                                    Text("•")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.45))

                                    Text("\(node.childCount) folders")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 3) {
                                Text(node.formattedSize)
                                    .font(.system(.body, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.9))

                                Text(node.percentageText)
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.65))
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
                    .buttonStyle(.plain)
                }

                if model.canGoUp {
                    Button("Go Up") { model.goUp() }
                        .buttonStyle(.bordered)
                        .tint(.white.opacity(0.2))
                        .padding(.top, 8)
                }
            }
        }
    }
}

@MainActor
final class DiskVisualizerViewModel: ObservableObject {
    @Published var isScanning = false
    @Published var progress: Double = 0
    @Published var statusText: String = ""
    @Published var currentRootPath: String?
    @Published var expandPackages: Bool = false

    let topN: Int = 20

    private var rootStack: [String] = []
    private var nodes: [String: FolderNode] = [:]
    private var childrenByParent: [String: [String]] = [:]

    private let bookmarkKey = "diskVisualizerBookmarks"

    var currentRootName: String {
        guard let path = currentRootPath else { return "No Folder Selected" }
        return URL(fileURLWithPath: path).lastPathComponent
    }

    var currentChildren: [FolderNode] {
        guard let root = currentRootPath else { return [] }
        let childPaths = childrenByParent[root] ?? []
        return childPaths.compactMap { nodes[$0] }
            .sorted { $0.cumulativeSize > $1.cumulativeSize }
    }

    var canGoUp: Bool { rootStack.count > 1 }

    func pickRootAndScan() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        if panel.runModal() == .OK, let url = panel.url {
            saveBookmarks(for: [url])
            rootStack = [url.path]
            currentRootPath = url.path
            scan(root: url)
        }
    }

    func scanCurrentRoot() {
        guard let path = currentRootPath else { return }
        scan(root: URL(fileURLWithPath: path))
    }

    func drillDown(to path: String) {
        rootStack.append(path)
        currentRootPath = path
    }

    func goUp() {
        guard rootStack.count > 1 else { return }
        _ = rootStack.popLast()
        currentRootPath = rootStack.last
    }

    private func scan(root: URL) {
        isScanning = true
        progress = 0
        statusText = "Scanning…"
        nodes.removeAll()
        childrenByParent.removeAll()

        Task.detached(priority: .utility) { [expandPackages] in
            let results = Self.scanFolders(root: root, expandPackages: expandPackages) { progress, current in
                Task { @MainActor in
                    self.progress = progress
                    self.statusText = current
                }
            }

            Task { @MainActor in
                self.nodes = results.nodes
                self.childrenByParent = results.children
                self.isScanning = false
                self.progress = 1
                self.statusText = "Scan complete"
                if self.currentRootPath == nil {
                    self.rootStack = [root.path]
                    self.currentRootPath = root.path
                }
            }
        }
    }

    private func saveBookmarks(for urls: [URL]) {
        let data = urls.compactMap { url in
            try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        }
        UserDefaults.standard.set(data, forKey: bookmarkKey)
    }

    private struct ScanResults {
        let nodes: [String: FolderNode]
        let children: [String: [String]]
    }

    nonisolated private static func scanFolders(
        root: URL,
        expandPackages: Bool,
        onProgress: @escaping (Double, String) -> Void
    ) -> ScanResults {
        let fm = FileManager.default
        var nodes: [String: FolderNode] = [:]
        var childrenByParent: [String: [String]] = [:]

        guard let enumerator = fm.enumerator(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey, .fileSizeKey, .isPackageKey, .isHiddenKey, .isSymbolicLinkKey],
            options: expandPackages ? [.skipsHiddenFiles] : [.skipsHiddenFiles, .skipsPackageDescendants],
            errorHandler: { _, _ in true }
        ) else {
            return ScanResults(nodes: nodes, children: childrenByParent)
        }

        let rootPath = root.path
        var processed = 0

        for case let url as URL in enumerator {
            processed += 1
            if processed % 400 == 0 {
                onProgress(min(Double(processed) / 50_000.0, 0.95), url.path)
            }

            guard let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isRegularFileKey, .fileSizeKey, .isPackageKey, .isHiddenKey, .isSymbolicLinkKey]) else {
                continue
            }

            if values.isSymbolicLink == true { continue }

            if values.isDirectory == true {
                ensureNode(path: url.path, nodes: &nodes, children: &childrenByParent)
                let parent = url.deletingLastPathComponent().path
                if parent.hasPrefix(rootPath) {
                    childrenByParent[parent, default: []].append(url.path)
                }

                if values.isPackage == true, !expandPackages {
                    let packageSize = JunkAnalyzer.directorySize(atPath: url.path)
                    addSize(packageSize, to: parent, nodes: &nodes)
                }
                continue
            }

            if values.isRegularFile == true, let size = values.fileSize {
                let parent = url.deletingLastPathComponent().path
                addSize(Int64(size), to: parent, nodes: &nodes)
                ensureNode(path: parent, nodes: &nodes, children: &childrenByParent)
            }
        }

        // compute cumulative sizes
        let sortedPaths = nodes.keys.sorted { $0.count > $1.count }
        for path in sortedPaths {
            let childPaths = childrenByParent[path] ?? []
            let childSum = childPaths.compactMap { nodes[$0]?.cumulativeSize }.reduce(0, +)
            if var node = nodes[path] {
                node.cumulativeSize = node.directSize + childSum
                nodes[path] = node
            }
        }

        // set percentages relative to root
        let rootSize = nodes[rootPath]?.cumulativeSize ?? 0
        if rootSize > 0 {
            let keys = Array(nodes.keys)
            for key in keys {
                if var node = nodes[key] {
                    node.percentageOfRoot = Double(node.cumulativeSize) / Double(rootSize)
                    nodes[key] = node
                }
            }
        }

        return ScanResults(nodes: nodes, children: childrenByParent)
    }

    nonisolated private static func ensureNode(
        path: String,
        nodes: inout [String: FolderNode],
        children: inout [String: [String]]
    ) {
        if nodes[path] == nil {
            nodes[path] = FolderNode(path: path)
        }
        children[path, default: []] = children[path, default: []]
    }

    nonisolated private static func addSize(_ size: Int64, to parent: String, nodes: inout [String: FolderNode]) {
        if nodes[parent] == nil {
            nodes[parent] = FolderNode(path: parent)
        }
        nodes[parent]?.directSize += size
        nodes[parent]?.fileCount += 1
    }
}

struct FolderNode {
    let path: String
    var directSize: Int64 = 0
    var cumulativeSize: Int64 = 0
    var childCount: Int = 0
    var fileCount: Int = 0
    var percentageOfRoot: Double = 0

    var displayName: String {
        URL(fileURLWithPath: path).lastPathComponent
    }

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: cumulativeSize, countStyle: .file)
    }

    var percentageText: String {
        String(format: "%.1f%%", percentageOfRoot * 100)
    }

    var categoryTag: String {
        classify(path: path)
    }

    private func classify(path: String) -> String {
        let lower = path.lowercased()
        if lower.contains("/applications") || lower.hasSuffix(".app") { return "Applications" }
        if lower.contains("/library/developer") || lower.contains("deriveddata") || lower.contains("nodes_modules") || lower.contains(".build") {
            return "Developer"
        }
        if lower.contains("/pictures") || lower.contains("/movies") || lower.contains("/music") { return "Media" }
        if lower.contains("/downloads") || lower.contains("/documents") || lower.contains("/desktop") { return "Documents" }
        if lower.contains("/caches") || lower.contains("/tmp") || lower.contains("mail downloads") { return "Temporary" }
        if lower.contains("/system") || lower.hasPrefix("/usr") || lower.hasPrefix("/bin") { return "System" }
        return "Unknown"
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
    DiskVisualizerView()
        .frame(width: 1000, height: 720)
}
