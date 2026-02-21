import SwiftUI

struct SettingsView: View {
    @StateObject private var protectedPaths = ProtectedPaths()
    @StateObject private var history = CleanupHistoryManager.shared
    @StateObject private var actionList = ActionListManager.shared

    @State private var showProtectedPaths = false
    @State private var showClearHistoryConfirm = false
    @State private var showClearLogsConfirm = false

    @AppStorage("settings.includeDownloads") private var includeDownloads = true
    @AppStorage("settings.includeDocuments") private var includeDocuments = true
    @AppStorage("settings.includeDesktop") private var includeDesktop = true
    @AppStorage("settings.includeMediaFolders") private var includeMediaFolders = true
    @AppStorage("settings.includeHiddenFiles") private var includeHiddenFiles = false

    @AppStorage("settings.treatPackagesAsFolders") private var treatPackagesAsFolders = false

    @AppStorage("settings.duplicateMinSizeMB") private var duplicateMinSizeMB = 10.0
    @AppStorage("settings.hashConcurrency") private var hashConcurrency = 2

    @AppStorage("settings.oldFilesAgeFilter") private var oldFilesAgeFilter = OldFilesAgeFilterSetting.days90.rawValue

    @AppStorage("settings.downloadsSuggestInstallers") private var downloadsSuggestInstallers = true
    @AppStorage("settings.downloadsSuggestArchives") private var downloadsSuggestArchives = true
    @AppStorage("settings.downloadsSuggestMedia") private var downloadsSuggestMedia = true

    @AppStorage("settings.junkXcode") private var junkXcode = true
    @AppStorage("settings.junkNode") private var junkNode = true
    @AppStorage("settings.junkAdobe") private var junkAdobe = true
    @AppStorage("settings.junkOtherApps") private var junkOtherApps = true

    @AppStorage("settings.confirmBeforeTrash") private var confirmBeforeTrash = true
    @AppStorage("settings.backgroundScanning") private var backgroundScanning = false
    @AppStorage("settings.maxScanMinutes") private var maxScanMinutes = 15

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.contentTop, AppTheme.contentBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    sectionCard(title: "Scan Scope") {
                        Toggle("Downloads folder", isOn: $includeDownloads)
                        Toggle("Documents folder", isOn: $includeDocuments)
                        Toggle("Desktop folder", isOn: $includeDesktop)
                        Toggle("Media folders (Pictures, Movies, Music)", isOn: $includeMediaFolders)
                        Toggle("Include hidden files", isOn: $includeHiddenFiles)
                    }

                    sectionCard(title: "Package Handling") {
                        Toggle("Treat .app/.photoslibrary as folders", isOn: $treatPackagesAsFolders)
                    }

                    sectionCard(title: "Duplicate Scan") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Minimum file size: \(Int(duplicateMinSizeMB)) MB")
                                .font(.subheadline)
                            Slider(value: $duplicateMinSizeMB, in: 1...500, step: 1)
                        }

                        Stepper("Hash concurrency: \(hashConcurrency)", value: $hashConcurrency, in: 1...4)
                    }

                    sectionCard(title: "Old Files Analyzer") {
                        Picker("Default age filter", selection: $oldFilesAgeFilter) {
                            ForEach(OldFilesAgeFilterSetting.allCases, id: \.rawValue) { filter in
                                Text(filter.title).tag(filter.rawValue)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    sectionCard(title: "Downloads Intelligence") {
                        Toggle("Suggest installers", isOn: $downloadsSuggestInstallers)
                        Toggle("Suggest archives", isOn: $downloadsSuggestArchives)
                        Toggle("Suggest images/videos/audio", isOn: $downloadsSuggestMedia)
                    }

                    sectionCard(title: "Project Junk Detector") {
                        Toggle("Xcode caches", isOn: $junkXcode)
                        Toggle("Node / Web caches", isOn: $junkNode)
                        Toggle("Adobe / Creative caches", isOn: $junkAdobe)
                        Toggle("Other apps", isOn: $junkOtherApps)
                    }

                    sectionCard(title: "Safety") {
                        Toggle("Confirm before moving to Trash", isOn: $confirmBeforeTrash)

                        Button("View protected paths") {
                            protectedPaths.loadProtectedPaths()
                            showProtectedPaths = true
                        }
                        .buttonStyle(.bordered)
                    }

                    sectionCard(title: "Performance") {
                        Toggle("Background scanning", isOn: $backgroundScanning)
                        Stepper("Max scan time: \(maxScanMinutes) minutes", value: $maxScanMinutes, in: 5...60, step: 5)
                    }

                    sectionCard(title: "Privacy") {
                        Button("Clear scan history") {
                            showClearHistoryConfirm = true
                        }
                        .buttonStyle(.bordered)

                        Button("Clear action logs") {
                            showClearLogsConfirm = true
                        }
                        .buttonStyle(.bordered)
                    }

                    sectionCard(title: "About") {
                        HStack {
                            Text("App Version")
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                                .foregroundColor(.white.opacity(0.7))
                        }

                        HStack {
                            Text("Build")
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
        }
        .sheet(isPresented: $showProtectedPaths) {
            ProtectedPathsSheet(paths: protectedPaths.paths)
        }
        .confirmationDialog("Clear scan history?", isPresented: $showClearHistoryConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                history.clearHistory()
            }
        } message: {
            Text("This will remove past scan history and totals.")
        }
        .confirmationDialog("Clear action logs?", isPresented: $showClearLogsConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                actionList.clearLogs()
            }
        } message: {
            Text("This will remove the Action List history.")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Settings")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Text("Customize scanning, safety, and performance")
                .foregroundColor(.white.opacity(0.75))
        }
    }

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)

            content()
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .cornerRadius(12)
        .foregroundColor(.white.opacity(0.9))
    }
}

private struct ProtectedPathsSheet: View {
    let paths: [ProtectedPath]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Protected Paths")
                .font(.title2)
                .fontWeight(.bold)

            Text("These locations are excluded from scans and deletions.")
                .foregroundColor(.secondary)

            List(paths) { item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.path)
                        .font(.body)
                    Text(item.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            .frame(minHeight: 240)

            Spacer()
        }
        .padding(20)
        .frame(width: 520, height: 420)
    }
}

private enum OldFilesAgeFilterSetting: String, CaseIterable {
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
}

#Preview {
    SettingsView()
        .frame(width: 1000, height: 720)
}
