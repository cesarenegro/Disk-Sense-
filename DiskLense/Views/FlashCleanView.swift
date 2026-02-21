import SwiftUI

/// Flash Clean screen:
/// - Reads scan results from `JunkAnalyzer`
/// - Performs cleaning through `FlashCleaner.clean(selected:)`
///
/// Architecture standard:
/// UI owns state + selection (via `JunkAnalyzer`).
/// Services (`FlashCleaner`) expose explicit async APIs (no dynamic member lookup / bindings).
struct FlashCleanView: View {
    @EnvironmentObject private var app: AppController

    @ObservedObject var analyzer: JunkAnalyzer
    @ObservedObject var flash: FlashCleaner

    /// When this UUID changes, the view triggers a scan (used by Home -> FlashClean deep-link).
    let scanRequestID: UUID

    @State private var lastCleanedBytes: Int64 = 0
    @State private var showCleanResult = false
    @State private var showCleanConfirm = false

    var body: some View {
        ZStack {
            background

            ScrollView {
                VStack(spacing: 22) {
                    header

                    if analyzer.progress > 0 {
                        scanProgress
                    }

                    scanSummary
                        .padding(.horizontal, 32)

                    resultsSection
                        .padding(.horizontal, 32)

                    actions

                    statusLine

                    Spacer(minLength: 30)
                }
                .padding(.bottom, 40)
            }
        }
        .onChange(of: scanRequestID) { _, _ in
            startScan()
        }
        .sheet(isPresented: $showCleanResult) {
            cleanResultSheet
        }
        .confirmationDialog(
            "Clean selected files?",
            isPresented: $showCleanConfirm,
            actions: {
                Button("Cancel", role: .cancel) { }
                Button("Clean Now", role: .destructive) { runCleanSelected() }
            },
            message: {
                Text("This will remove \(analyzer.formattedGB(analyzer.selectedBytes)) of selected junk.")
            }
        )
    }
}

// MARK: - Subviews (split to keep Swift type-checking fast)
private extension FlashCleanView {

    var background: some View {
        Color(red: 0.06, green: 0.10, blue: 0.18)
            .opacity(0.85)
            .ignoresSafeArea()
    }

    var header: some View {
        VStack(spacing: 8) {
            Text("Flash Clean")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)

            Text("Quickly scan and clean junk files from your system")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.top, 24)
    }

    var scanProgress: some View {
        CustomProgressWheelView(
            progress: analyzer.progress,
            title: "Scanning Junk \(analyzer.formatted(analyzer.total))",
            subtitle: analyzer.currentPath,
            color: .blue,
            size: 200,
            lineWidth: 26
        )
        .frame(width: 240, height: 240)
        .padding(.top, 10)
    }

    var scanSummary: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Scanned")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))

                Spacer()

                Text(analyzer.formattedGB(analyzer.total))
                    .font(.system(.headline, design: .monospaced))
                    .foregroundColor(.white)
            }

            HStack {
                Text("Selected")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                Text(analyzer.formattedGB(analyzer.selectedBytes))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .cornerRadius(12)
        .opacity(analyzer.progress > 0 ? 1 : 0)
    }

    var resultsSection: some View {
        VStack(spacing: 14) {
            resultsHeader

            if analyzer.categories.isEmpty {
                emptyState
            } else {
                resultsCard
            }
        }
    }

    var resultsHeader: some View {
        HStack {
            Text("Scan Results")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Spacer()

            Menu {
                Button("Sort by Size") { analyzer.sortMode = .sizeDesc }
                Button("Sort by Name") { analyzer.sortMode = .nameAsc }
            } label: {
                Text(analyzer.sortMode.rawValue)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }

    var emptyState: some View {
        CustomEmptyStateView(
            title: "No Scan Results",
            message: "Click 'Analyze' to scan for junk files on your system.",
            icon: "magnifyingglass",
            actionTitle: "Analyze Now",
            action: { startScan() }
        )
        .frame(height: 280)
    }

    var resultsCard: some View {
        VStack(spacing: 12) {
            ForEach(analyzer.sortedCategories()) { category in
                CategorySelectionCard(
                    analyzer: analyzer,
                    category: category
                )
            }

            Divider().opacity(0.2).padding(.vertical, 6)

            HStack {
                Text("Selected")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))

                Spacer()

                Text(analyzer.formattedGB(analyzer.selectedBytes))
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }

            HStack {
                Text("Total Found")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                Text(analyzer.formattedGB(analyzer.total))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .cornerRadius(12)
    }

    var actions: some View {
        HStack(spacing: 16) {
            SidebarStyleButton(
                title: "Analyze",
                assetIcon: Asset.icFlash,
                isEnabled: !flash.isCleaning,
                action: startScan
            )

            SidebarStyleButton(
                title: "Clean Now",
                assetIcon: Asset.icSmartClean,
                isEnabled: !flash.isCleaning && !analyzer.categories.isEmpty && analyzer.selectedBytes > 0,
                action: { showCleanConfirm = true }
            )
        }
        .padding(.top, 10)
    }

    @ViewBuilder
    var statusLine: some View {
        if flash.isCleaning {
            VStack(spacing: 8) {
                ProgressView(value: flash.progress)
                    .frame(width: 320)
                Text(flash.current)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(.top, 6)
        } else if !flash.current.isEmpty {
            Text(flash.current)
                .font(.caption)
                .foregroundColor(.green)
                .padding(.top, 6)
        }
    }

    var cleanResultSheet: some View {
        VStack(spacing: 16) {
            Text("Clean Complete")
                .font(.title2)
                .fontWeight(.bold)

            Text("Cleaned \(lastCleanedBytes.formattedSize)")
                .font(.headline)
                .foregroundColor(.green)

            Button("Done") {
                showCleanResult = false
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(width: 360)
    }
}

// MARK: - Actions
private extension FlashCleanView {

    func startScan() {
        app.recordScanStarted()
        Task { await analyzer.scan() }
    }

    func runCleanSelected() {
        Task {
            // Standardized: FlashCleaner exposes explicit API `clean(selected:)`
            let cleanedBytes = await flash.clean(selected: analyzer.categories)

            // Record what we actually cleaned (fallback to selected/total if the service returns 0 for some reason)
            let bytesToRecord: Int64 = cleanedBytes > 0
                ? cleanedBytes
                : (analyzer.selectedBytes > 0 ? analyzer.selectedBytes : analyzer.total)

            app.recordClean(bytes: bytesToRecord)
            lastCleanedBytes = bytesToRecord
            showCleanResult = true
        }
    }
}

/// Light row view to keep the main body simple (helps Swift compiler).
private struct CategorySelectionCard: View {
    @ObservedObject var analyzer: JunkAnalyzer
    let category: JunkCategory

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top) {
                SelectionCheckbox(isSelected: categoryToggleBinding)

                VStack(alignment: .leading, spacing: 3) {
                    Text(category.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)

                    Text(category.description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.65))
                        .lineLimit(1)
                }

                Spacer()

                Text(analyzer.formatted(category.size))
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
            }

            if !category.items.isEmpty {
                Divider().opacity(0.15)

                VStack(spacing: 6) {
                    ForEach(category.items) { item in
                        JunkItemRow(
                            analyzer: analyzer,
                            categoryID: category.id,
                            item: item
                        )
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .cornerRadius(10)
    }

    private var categoryToggleBinding: Binding<Bool> {
        Binding(
            get: { category.isSelected },
            set: { analyzer.toggleCategory(category.id, to: $0) }
        )
    }
}

private struct JunkItemRow: View {
    @ObservedObject var analyzer: JunkAnalyzer
    let categoryID: UUID
    let item: JunkItem

    var body: some View {
        HStack(alignment: .center) {
            SelectionCheckbox(isSelected: itemToggleBinding)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))

                Text(item.path)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.55))
                    .lineLimit(1)
            }

            Spacer()

            Text(analyzer.formatted(item.size))
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.04))
        .cornerRadius(8)
    }

    private var itemToggleBinding: Binding<Bool> {
        Binding(
            get: { item.isSelected },
            set: { analyzer.toggleItem(categoryID: categoryID, itemID: item.id, to: $0) }
        )
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

