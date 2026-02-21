import SwiftUI

struct LargeFilesView: View {
    @ObservedObject var finder: LargeFilesFinder

    init(finder: LargeFilesFinder) {
        self.finder = finder
    }

    @State private var searchText: String = ""
    @State private var selectedFiles: Set<UUID> = []
    @State private var showDeleteAlert: Bool = false

    var filteredFiles: [LargeFile] {
        if searchText.isEmpty { return finder.files }
        return finder.files.filter {
            $0.url.lastPathComponent.localizedCaseInsensitiveContains(searchText)
        }
    }

    var totalSelectedSize: Int64 {
        finder.files
            .filter { selectedFiles.contains($0.id) }
            .reduce(0) { $0 + $1.size }
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [AppTheme.contentTop, AppTheme.contentBottom], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                searchBar
                    .padding(.horizontal, 32)
                    .padding(.bottom, 12)

                Divider().opacity(0.25)

                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                footer
            }
        }
        .alert("Delete selected files?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await finder.delete(filesWithIDs: selectedFiles)
                    selectedFiles.removeAll()
                }
            }
        } message: {
            Text("This will move \(selectedFiles.count) file(s) to Trash.")
        }
    }
}

private extension LargeFilesView {

    var header: some View {
        VStack(spacing: 8) {
            Text("Large Files")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)

            Text("Find and manage large files taking up space")
                .font(.body)
                .foregroundColor(.white.opacity(0.75))
        }
        .padding(.top, 24)
        .padding(.bottom, 16)
    }

    var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.7))

            TextField("Search files…", text: $searchText)
                .textFieldStyle(.plain)
                .foregroundColor(.white)

            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.08))
        .cornerRadius(10)
    }

    @ViewBuilder
    var content: some View {
        if finder.isLoading {
            VStack(spacing: 14) {
                ProgressView(value: finder.progress)
                    .frame(width: 320)

                Text("Scanning… \(Int(finder.progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.75))
            }
        } else if filteredFiles.isEmpty {
            CustomEmptyStateView(
                title: "No Large Files",
                message: "Click 'Scan Large Files' to search for big files on your system.",
                icon: "externaldrive",
                actionTitle: "Scan Large Files",
                action: { runScan() }
            )
            .padding(.horizontal, 32)
        } else {
            ScrollView {
                VStack(spacing: 10) {
                    ForEach(filteredFiles) { file in
                        LargeFileRow(
                            file: file,
                            isSelected: selectedFiles.contains(file.id),
                            onToggle: { toggle(file.id) }
                        )
                    }
                }
                .padding(16)
                .padding(.horizontal, 16)
            }
        }
    }

    var footer: some View {
        HStack(spacing: 12) {
            LargeFilesFooterButton(
                title: "Scan Large Files",
                systemIcon: "magnifyingglass",
                fill: Color("ButtonScan"),
                isEnabled: !finder.isLoading,
                action: { runScan() }
            )

            Spacer()

            if !selectedFiles.isEmpty {
                Text("Selected: \(ByteCountFormatter.string(fromByteCount: totalSelectedSize, countStyle: .file))")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))

                LargeFilesFooterButton(
                    title: "Delete Selected",
                    systemIcon: "trash",
                    fill: Color("ButtonScan"),
                    isEnabled: true,
                    action: { showDeleteAlert = true }
                )
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 14)
    }

    func toggle(_ id: UUID) {
        if selectedFiles.contains(id) { selectedFiles.remove(id) }
        else { selectedFiles.insert(id) }
    }

    func runScan() {
        selectedFiles.removeAll()
        Task { await finder.scan() }
    }
}

private struct LargeFilesFooterButton: View {
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
            .padding(.vertical, 10)
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(fill)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .opacity(isEnabled ? 1 : 0.45)
        .disabled(!isEnabled)
    }
}

private struct LargeFileRow: View {
    let file: LargeFile
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            SelectionCheckbox(isSelected: Binding(get: { isSelected }, set: { _ in onToggle() }))

            VStack(alignment: .leading, spacing: 2) {
                Text(file.url.lastPathComponent)
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .semibold))

                Text(file.url.deletingLastPathComponent().path)
                    .foregroundColor(.white.opacity(0.65))
                    .font(.caption)
                    .lineLimit(1)
            }

            Spacer()

            Text(ByteCountFormatter.string(fromByteCount: file.size, countStyle: .file))
                .foregroundColor(.white.opacity(0.85))
                .font(.system(.body, design: .monospaced))
        }
        .padding(12)
        .background(Color.white.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

