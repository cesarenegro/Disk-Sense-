import SwiftUI
import AppKit

struct DuplicatesView: View {
    @ObservedObject var dup: DuplicateFinder

    @State private var selectedFiles = Set<URL>()
    @State private var scanFolders: [URL] = []

    private let bookmarkKey = "duplicateScanBookmarks"

    init(dup: DuplicateFinder) {
        self.dup = dup
    }


    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.contentTop, AppTheme.contentBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Text("Duplicate Files")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)

                    Text("Find and remove duplicate files to free up space")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.75))
                }
                .padding(.top, 24)
                .padding(.bottom, 16)

                // Progress / Status
                if dup.isLoading {
                    VStack(spacing: 10) {
                        ProgressView(value: dup.progress)
                            .progressViewStyle(.linear)
                            .tint(.white)
                            .frame(width: 320)

                        Text(dup.statusText)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .padding(.bottom, 16)
                } else if !dup.statusText.isEmpty {
                    Text(dup.statusText)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.65))
                        .padding(.bottom, 12)
                }

                Divider().opacity(0.25)

                // Content
                if dup.duplicates.isEmpty && !dup.isLoading {
                    CustomEmptyStateView(
                        title: "No Duplicates Found",
                        message: "Click 'Scan Duplicates' to search for duplicate files.",
                        icon: "doc.on.doc",
                        actionTitle: "Scan Duplicates",
                        action: { runScan() }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 32)
                } else if !dup.duplicates.isEmpty {
                    ScrollView {
                        VStack(spacing: 12) {
                            // Summary
                            HStack {
                                Text("Found \(dup.duplicates.count) duplicate groups")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(dup.duplicates.flatMap { $0 }.count) total files")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.65))
                            }
                            .padding(.horizontal, 32)

                            ForEach(Array(dup.duplicates.enumerated()), id: \.offset) { index, group in
                                DuplicateGroupItemView(
                                    index: index,
                                    group: group,
                                    dup: dup,
                                    selectedFiles: $selectedFiles
                                )
                                .padding(.horizontal, 32)
                            }
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 60)
                    }
                } else {
                    // Loading state — just show spinner (progress is above)
                    Spacer()
                }

                // Footer
                HStack(spacing: 16) {
                    FooterActionButton(
                        title: "Scan for Duplicates",
                        systemIcon: "doc.on.doc",
                        fill: Color("ButtonScan"),
                        isEnabled: !dup.isLoading,
                        action: { runScan() }
                    )

                    FooterActionButton(
                        title: "Re-select",
                        systemIcon: "folder.badge.plus",
                        fill: Color("ButtonScan"),
                        isEnabled: !dup.isLoading,
                        action: { reselectFolders() }
                    )

                    FooterActionButton(
                        title: "Scan all Disk",
                        systemIcon: "internaldrive",
                        fill: Color("ButtonScan"),
                        isEnabled: !dup.isLoading,
                        action: { scanAllDisk() }
                    )

                    FooterActionButton(
                        title: "Delete Selected",
                        systemIcon: "trash",
                        fill: Color(red: 0.06, green: 0.20, blue: 0.36),
                        isEnabled: !dup.isLoading && !selectedFiles.isEmpty,
                        action: { deleteSelected() }
                    )
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
        }
        .onAppear {
            if scanFolders.isEmpty {
                scanFolders = restoreBookmarks()
            }
        }
        .onChange(of: dup.duplicates) { _, _ in
            let allFiles = Set(dup.duplicates.flatMap { $0 })
            selectedFiles = selectedFiles.intersection(allFiles)
        }
    }

    private func runScan() {
        Task {
            let folders = await resolveScanFolders()
            guard !folders.isEmpty else { return }
            await withSecurityScopedAccess(folders) {
                await dup.scan(at: folders)
            }
        }
    }

    @MainActor
    private func reselectFolders() {
        let chosen = pickFolders()
        guard !chosen.isEmpty else { return }
        scanFolders = chosen
        saveBookmarks(for: chosen)
    }

    @MainActor
    private func scanAllDisk() {
        let chosen = pickRootDisk()
        guard !chosen.isEmpty else { return }
        scanFolders = chosen
        saveBookmarks(for: chosen)
    }

    private func deleteSelected() {
        let files = Array(selectedFiles)
        selectedFiles.removeAll()
        dup.remove(files: files)
    }

    @MainActor
    private func resolveScanFolders() async -> [URL] {
        if scanFolders.isEmpty {
            let chosen = pickFolders()
            if !chosen.isEmpty {
                scanFolders = chosen
                saveBookmarks(for: chosen)
            }
        }
        return scanFolders
    }

    @MainActor
    private func pickFolders() -> [URL] {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = true
        panel.prompt = "Choose"

        let response = panel.runModal()
        return response == .OK ? panel.urls : []
    }

    @MainActor
    private func pickRootDisk() -> [URL] {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: "/")
        panel.prompt = "Select Disk"
        panel.title = "Select a disk to scan"
        panel.message = "Choose your main disk (for example, Macintosh HD) to scan all folders you have access to."

        let response = panel.runModal()
        return response == .OK ? panel.urls : []
    }

    private func saveBookmarks(for urls: [URL]) {
        let data = urls.compactMap { url in
            try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
        }
        UserDefaults.standard.set(data, forKey: bookmarkKey)
    }

    private func restoreBookmarks() -> [URL] {
        guard let data = UserDefaults.standard.array(forKey: bookmarkKey) as? [Data] else { return [] }
        var urls: [URL] = []
        var updatedData: [Data] = []

        for item in data {
            var stale = false
            if let url = try? URL(resolvingBookmarkData: item, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &stale) {
                urls.append(url)
                if stale, let newData = try? url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil) {
                    updatedData.append(newData)
                } else {
                    updatedData.append(item)
                }
            }
        }

        if !updatedData.isEmpty {
            UserDefaults.standard.set(updatedData, forKey: bookmarkKey)
        }
        return urls
    }

    private func withSecurityScopedAccess(_ urls: [URL], operation: () async -> Void) async {
        var accessed: [URL] = []
        for url in urls {
            if url.startAccessingSecurityScopedResource() {
                accessed.append(url)
            }
        }
        defer {
            for url in accessed {
                url.stopAccessingSecurityScopedResource()
            }
        }
        await operation()
    }
}

private struct FooterActionButton: View {
    let title: String
    let systemIcon: String
    let fill: Color
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemIcon)
                Text(title)
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isEnabled ? fill : Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(isEnabled ? 0.22 : 0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}
