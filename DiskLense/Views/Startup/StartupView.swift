import SwiftUI

struct StartupView: View {
    @ObservedObject var manager: StartupManager

    // Standardized init to match AppShellView: StartupView(manager: startup)
    init(manager: StartupManager) {
        self.manager = manager
    }

    @State private var expandedFolders: Set<UUID> = []
    @State private var showRemoveAlert: Bool = false
    @State private var pendingRemove: StartupItem?

    var body: some View {
        ZStack {
            LinearGradient(colors: [AppTheme.contentTop, AppTheme.contentBottom],
                           startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()

            VStack(spacing: 0) {

                header

                searchBar
                    .padding(.horizontal, 32)
                    .padding(.bottom, 12)

                statsBar
                    .padding(.horizontal, 32)
                    .padding(.bottom, 10)

                Divider().opacity(0.25)

                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                footer
            }
        }
        .onAppear {
            if manager.folders.isEmpty { manager.load() }
        }
        .alert("Remove Startup Item?", isPresented: $showRemoveAlert) {
            Button("Cancel", role: .cancel) { pendingRemove = nil }
            Button("Remove", role: .destructive) {
                if let item = pendingRemove {
                    manager.remove(item)
                    pendingRemove = nil
                }
            }
        } message: {
            Text("This will remove the item (and delete it when possible).")
        }
    }
}

private extension StartupView {

    var header: some View {
        VStack(spacing: 8) {
            Text("Startup Items")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)

            Text("Manage apps and services that launch automatically")
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

            TextField("Search startup items…", text: $manager.searchText)
                .textFieldStyle(.plain)
                .foregroundColor(.white)

            if !manager.searchText.isEmpty {
                Button { manager.searchText = "" } label: {
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

    var statsBar: some View {
        let folders = manager.filteredFolders
        let total = folders.reduce(0) { $0 + $1.totalCount }
        let enabled = folders.reduce(0) { $0 + $1.enabledCount }
        let disabled = folders.reduce(0) { $0 + $1.disabledCount }

        return HStack(spacing: 10) {
            Text("\(total) items")
                .font(.caption)
                .foregroundColor(.white.opacity(0.75))

            Text("•").foregroundColor(.white.opacity(0.6))

            Text("\(enabled) enabled")
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))

            Text("•").foregroundColor(.white.opacity(0.6))

            Text("\(disabled) disabled")
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))

            Spacer()

            Button {
                manager.load()
            } label: {
                Image(systemName: "arrow.clockwise")
                Text("Refresh")
            }
            .font(.caption)
            .buttonStyle(.bordered)
            .tint(.white.opacity(0.25))
        }
    }

    @ViewBuilder
    var content: some View {
        if manager.isLoading {
            VStack(spacing: 14) {
                ProgressView().scaleEffect(1.3)
                Text("Loading startup items…")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.75))
            }
        } else if manager.filteredFolders.isEmpty {
            CustomEmptyStateView(
                title: "No Startup Items",
                message: "Nothing found, or permissions are limited.",
                icon: "power",
                actionTitle: "Refresh",
                action: { manager.load() }
            )
            .padding(.horizontal, 32)
        } else {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(manager.filteredFolders) { folder in
                        folderCard(folder)
                    }
                }
                .padding(16)
                .padding(.horizontal, 16)
            }
        }
    }

    func folderCard(_ folder: StartupFolder) -> some View {
        let expanded = expandedFolders.contains(folder.id)

        return VStack(spacing: 10) {
            Button {
                if expanded { expandedFolders.remove(folder.id) }
                else { expandedFolders.insert(folder.id) }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: folder.icon)
                        .foregroundColor(.white.opacity(0.9))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(folder.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                        Text(folder.description)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    Spacer()

                    Text("\(folder.totalCount)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.75))

                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white.opacity(0.75))
                }
            }
            .buttonStyle(.plain)

            if expanded {
                Divider().opacity(0.25)

                VStack(spacing: 8) {
                    ForEach(folder.items) { item in
                        itemRow(item)
                    }
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .cornerRadius(14)
    }

    func itemRow(_ item: StartupItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.type.icon)
                .foregroundColor(.white.opacity(0.85))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .semibold))

                Text(item.path)
                    .foregroundColor(.white.opacity(0.65))
                    .font(.caption)
                    .lineLimit(1)
            }

            Spacer()

            // Toggle enabled/disabled (UI-level toggleStatus)
            Toggle("", isOn: Binding(
                get: { item.status == .enabled },
                set: { _ in manager.toggleStatus(item) }
            ))
            .labelsHidden()

            Button {
                pendingRemove = item
                showRemoveAlert = true
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.white.opacity(0.85))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
    }

    var footer: some View {
        HStack {
            Spacer()
        }
        .padding(.vertical, 10)
    }
}

