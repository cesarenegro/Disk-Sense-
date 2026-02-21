import SwiftUI

struct ModernAppUninstallerView: View {
    @StateObject private var uninstaller = AppUninstaller()
    @State private var selectedFilter = "All Applications"
    @State private var showDeleteConfirmation = false
    @State private var appToDelete: InstalledApp?
    @State private var isMultipleDelete = false

    let filters = ["All Applications", "Leftovers", "Selected", "Large and Old", "Sources", "Vendors"]

    var filteredApps: [InstalledApp] {
        switch selectedFilter {
        case "All Applications": return uninstaller.apps
        case "Selected":         return uninstaller.apps.filter { uninstaller.selectedApps.contains($0.id) }
        case "Large and Old":    return uninstaller.apps.filter { $0.size > 1_000_000_000 }
        default:                 return uninstaller.apps
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(colors: [AppTheme.contentTop, AppTheme.contentBottom],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.top, 24)
                    .padding(.bottom, 16)

                filterBar
                    .padding(.horizontal, 32)
                    .padding(.bottom, 12)

                Divider().opacity(0.25)

                appContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider().opacity(0.25)

                footer
            }
        }
        .onAppear { uninstaller.loadApps() }
        .alert("Delete?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { appToDelete = nil }
            Button("Delete", role: .destructive) {
                if isMultipleDelete {
                    let toDelete = uninstaller.apps.filter { uninstaller.selectedApps.contains($0.id) }
                    for a in toDelete { uninstaller.remove(a) }
                } else if let a = appToDelete {
                    uninstaller.remove(a)
                }
                appToDelete = nil
            }
        } message: {
            if isMultipleDelete {
                Text("Move \(uninstaller.selectedApps.count) apps to Trash?")
            } else {
                Text("Move \"\(appToDelete?.name ?? "App")\" to Trash?")
            }
        }
    }
}

// MARK: - Subviews
private extension ModernAppUninstallerView {

    var header: some View {
        VStack(spacing: 8) {
            Text("App Uninstall")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)

            Text("Find and completely remove applications")
                .font(.body)
                .foregroundColor(.white.opacity(0.75))
        }
    }

    var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(filters, id: \.self) { filter in
                    Button {
                        withAnimation { selectedFilter = filter }
                    } label: {
                        Text(filter)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(selectedFilter == filter
                                          ? AppTheme.accent
                                          : Color.white.opacity(0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.white.opacity(selectedFilter == filter ? 0.25 : 0.12),
                                            lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Button {
                    uninstaller.forceReload()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.white.opacity(0.85))
                }
                .buttonStyle(.plain)
                .help("Reload applications")
            }
        }
    }

    @ViewBuilder
    var appContent: some View {
        if uninstaller.isLoading {
            VStack(spacing: 14) {
                ProgressView()
                    .scaleEffect(1.3)
                    .tint(.white)

                Text("Scanning Applications…")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.75))

                if uninstaller.apps.isEmpty {
                    Text("Looking in /Applications…")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                } else {
                    Text("Found \(uninstaller.apps.count) apps so far…")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        } else if filteredApps.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "app.dashed")
                    .font(.system(size: 48))
                    .foregroundColor(.white.opacity(0.4))

                Text("No Applications Found")
                    .font(.title3.weight(.medium))
                    .foregroundColor(.white)

                Text("No apps match the '\(selectedFilter)' filter.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.65))

                Button { selectedFilter = "All Applications" } label: {
                    Text("View All")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color.white.opacity(0.12))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(Color.white.opacity(0.18), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(filteredApps) { app in
                        DarkAppRow(
                            app: app,
                            uninstaller: uninstaller,
                            onDelete: { target in
                                appToDelete = target
                                isMultipleDelete = false
                                showDeleteConfirmation = true
                            }
                        )
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)
                .padding(.bottom, 60)
            }
        }
    }

    var footer: some View {
        HStack(spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.white.opacity(0.7))
                Text("Selected: \(fmt(uninstaller.totalSelectedSize))")
                    .foregroundColor(.white.opacity(0.85))
            }
            .font(.subheadline)

            Text("•").foregroundColor(.white.opacity(0.4))

            HStack(spacing: 6) {
                Image(systemName: "internaldrive")
                    .foregroundColor(.white.opacity(0.5))
                Text("\(filteredApps.count) apps")
                    .foregroundColor(.white.opacity(0.65))
            }
            .font(.subheadline)

            Spacer()

            Button(role: .destructive) {
                if uninstaller.selectedApps.count == 1,
                   let first = uninstaller.apps.first(where: { uninstaller.selectedApps.contains($0.id) }) {
                    appToDelete = first
                    isMultipleDelete = false
                } else {
                    isMultipleDelete = true
                }
                showDeleteConfirmation = true
            } label: {
                Label("Remove", systemImage: "trash")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(uninstaller.selectedApps.isEmpty
                          ? Color.white.opacity(0.08)
                          : Color.red.opacity(0.75))
            )
            .disabled(uninstaller.selectedApps.isEmpty)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 12)
    }

    func fmt(_ size: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

// MARK: - Dark-themed App Row
private struct DarkAppRow: View {
    let app: InstalledApp
    @ObservedObject var uninstaller: AppUninstaller
    let onDelete: (InstalledApp) -> Void
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            mainRow
            if isExpanded, let subApps = app.subApps {
                ForEach(subApps) { sub in subRow(sub) }
            }
        }
    }

    private var mainRow: some View {
        HStack(spacing: 12) {
            SelectionCheckbox(isSelected: Binding(
                get: { uninstaller.selectedApps.contains(app.id) },
                set: { isOn in
                    if isOn != uninstaller.selectedApps.contains(app.id) {
                        uninstaller.toggleSelection(for: app)
                    }
                }
            ))

            Image(systemName: app.icon)
                .frame(width: 24)
                .foregroundColor(.white.opacity(0.75))

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                if let v = app.version {
                    Text("Version \(v)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.55))
                }
            }

            Spacer()

            Text(ByteCountFormatter.string(fromByteCount: app.size, countStyle: .file))
                .foregroundColor(.white.opacity(0.75))
                .font(.system(.body, design: .monospaced))

            Button { onDelete(app) } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red.opacity(0.8))
            }
            .buttonStyle(.plain)
            .padding(.leading, 6)

            if uninstaller.canLoadSubApps(for: app) {
                Button {
                    if !isExpanded {
                        uninstaller.loadSubAppsIfNeeded(for: app)
                    }
                    withAnimation { isExpanded.toggle() }
                } label: {
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
                .padding(.leading, 4)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .cornerRadius(12)
    }

    private func subRow(_ sub: InstalledApp) -> some View {
        HStack(spacing: 12) {
            SelectionCheckbox(isSelected: Binding(
                get: { uninstaller.selectedApps.contains(sub.id) },
                set: { isOn in
                    if isOn != uninstaller.selectedApps.contains(sub.id) {
                        uninstaller.toggleSelection(for: sub)
                    }
                }
            ))
            .padding(.leading, 32)

            Image(systemName: sub.icon)
                .frame(width: 24)
                .foregroundColor(.white.opacity(0.55))

            Text(sub.name)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.85))

            Spacer()

            Text(ByteCountFormatter.string(fromByteCount: sub.size, countStyle: .file))
                .foregroundColor(.white.opacity(0.6))
                .font(.system(.subheadline, design: .monospaced))

            Button { onDelete(sub) } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red.opacity(0.6))
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .padding(.leading, 6)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .padding(.leading, 16)
        .background(Color.white.opacity(0.03))
    }
}
