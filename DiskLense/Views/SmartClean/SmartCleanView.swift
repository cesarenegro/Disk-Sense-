import SwiftUI

struct SmartCleanView: View {
    @EnvironmentObject private var app: AppController

    @StateObject private var analyzer = JunkAnalyzer()
    @StateObject private var flash = FlashCleaner()

    let scanRequestID: UUID

    init(scanRequestID: UUID = UUID(), initialDetailsVisible: Bool = false) {
        self.scanRequestID = scanRequestID
        _showDetailsPage = State(initialValue: initialDetailsVisible)
    }

    @State private var showDetailsPage = false
    @State private var expandedCategories = Set<UUID>()
    @State private var lastCleanedBytes: Int64 = 0
    @State private var showCleanResult = false
    @State private var showCleanConfirm = false

    var body: some View {
        ZStack {
            background

            if showDetailsPage {
                detailsContent
            } else {
                summaryContent
            }
        }
        .sheet(isPresented: $showCleanResult) {
            cleanResultSheet
        }
        .confirmationDialog(
            "Run Smart Clean?",
            isPresented: $showCleanConfirm,
            actions: {
                Button("Cancel", role: .cancel) { }
                Button("Clean Now", role: .destructive) { runCleanSelected() }
            },
            message: {
                Text("This will clean \(analyzer.formattedGB(analyzer.selectedBytes)) from selected categories.")
            }
        )
        .animation(.easeInOut(duration: 0.25), value: analyzer.progress >= 1)
        .onAppear(perform: startScan)
        .onChange(of: scanRequestID) { _, _ in
            startScan()
        }
    }
}

// MARK: - Summary Content
private extension SmartCleanView {

    var background: some View {
        Color(red: 0.06, green: 0.10, blue: 0.18)
            .opacity(0.85)
            .ignoresSafeArea()
    }

    var summaryContent: some View {
        ScrollView {
            VStack(spacing: 22) {
                header

                if analyzer.progress < 1 {
                    scanProgress
                        .transition(.opacity)
                } else if analyzer.progress >= 1 {
                    pieSection
                        .transition(.opacity)
                }

                scanSummary
                    .padding(.horizontal, 32)

                summaryActions

                statusLine

                Spacer(minLength: 30)
            }
            .padding(.bottom, 40)
        }
    }

    var header: some View {
        VStack(spacing: 8) {
            Text("Smart Clean")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)

            Text("Scan key system areas and clean selected items")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.top, 24)
    }

    var scanProgress: some View {
        CustomProgressWheelView(
            progress: analyzer.progress,
            title: "Scanning…",
            subtitle: analyzer.currentPath,
            size: 200
        )
        .frame(width: 240, height: 240)
        .padding(.top, 10)
    }

    var pieSection: some View {
        VStack(spacing: 14) {
            ColumnGraphView(items: columnItems, size: 240)
            categoryLegend
        }
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

    var summaryActions: some View {
        HStack(spacing: 16) {
            SidebarStyleButton(
                title: "Analyze",
                assetIcon: Asset.icSmartClean,
                isEnabled: !flash.isCleaning,
                action: startScan
            )

            SidebarStyleButton(
                title: "Select Clean",
                assetIcon: Asset.icSmartClean,
                isEnabled: analyzer.progress >= 1 && !analyzer.categories.isEmpty,
                action: { showDetailsPage = true }
            )
        }
        .padding(.top, 10)
    }

    var pieLegend: some View { EmptyView() }

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
}

// MARK: - Details Content
private extension SmartCleanView {

    var detailsContent: some View {
        ScrollView {
            VStack(spacing: 22) {
                detailsHeader

                resultsCard
                    .padding(.horizontal, 32)

                detailsActions

                statusLine

                Spacer(minLength: 30)
            }
            .padding(.bottom, 40)
        }
    }

    var detailsHeader: some View {
        VStack(spacing: 8) {
            Text("Select Clean")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Text("Choose categories and files to clean")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.top, 24)
    }

    var resultsCard: some View {
        VStack(spacing: 12) {
            ForEach(analyzer.sortedCategories()) { category in
                CategoryDisclosureCard(
                    analyzer: analyzer,
                    category: category,
                    isExpanded: expandedBinding(for: category.id)
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

            selectionBreakdown

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

    var selectionBreakdown: some View {
        VStack(spacing: 6) {
            ForEach(analyzer.sortedCategories()) { category in
                let selectedSize = category.selectedSize
                if selectedSize > 0 {
                    HStack {
                        Text(category.name)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))

                        Spacer()

                        Text(analyzer.formattedGB(selectedSize))
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.white.opacity(0.75))
                    }
                }
            }
        }
        .padding(.top, 4)
    }

    var detailsActions: some View {
        HStack(spacing: 16) {
            SidebarStyleButton(
                title: "Back",
                assetIcon: Asset.icSmartClean,
                isEnabled: !flash.isCleaning,
                action: { showDetailsPage = false }
            )

            SidebarStyleButton(
                title: "Clean Now",
                assetIcon: Asset.icSmartClean,
                isEnabled: !flash.isCleaning && analyzer.selectedBytes > 0,
                action: { showCleanConfirm = true }
            )
        }
        .padding(.top, 10)
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

    func expandedBinding(for id: UUID) -> Binding<Bool> {
        Binding(
            get: { expandedCategories.contains(id) },
            set: { isExpanded in
                if isExpanded {
                    expandedCategories.insert(id)
                } else {
                    expandedCategories.remove(id)
                }
            }
        )
    }
}

// MARK: - Actions
private extension SmartCleanView {

    func startScan() {
        #if RELEASE_SCREENSHOT
        if ScreenshotMode.isEnabled, let demo = ScreenshotMode.demoData {
            analyzer.applyScreenshotDemoData(demo)
            return
        }
        #endif
        guard analyzer.state != .scanning, !flash.isCleaning else { return }
        showDetailsPage = false
        Task { await analyzer.scan() }
    }

    func runCleanSelected() {
        Task {
            let cleanedBytes = await flash.clean(selected: analyzer.categories)

            let bytesToRecord: Int64 = cleanedBytes > 0
                ? cleanedBytes
                : (analyzer.selectedBytes > 0 ? analyzer.selectedBytes : analyzer.total)

            app.recordClean(bytes: bytesToRecord)
            lastCleanedBytes = bytesToRecord
            showCleanResult = true
        }
    }
}

// MARK: - Category Card
private struct CategoryDisclosureCard: View {
    @ObservedObject var analyzer: JunkAnalyzer
    let category: JunkCategory
    @Binding var isExpanded: Bool

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

                Button {
                    isExpanded.toggle()
                } label: {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(.plain)

                Text(analyzer.formatted(category.size))
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
            }

            if isExpanded {
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

// MARK: - Column Graph
private struct ColumnGraphView: View {
    struct Item: Identifiable {
        let id = UUID()
        let name: String
        let sizeBytes: Int64
        let fraction: Double
    }

    let items: [Item]
    var size: CGFloat = 240

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.03))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 16) {
                    ForEach(items.indices, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Self.columnGradients[index % Self.columnGradients.count])
                            .frame(width: 28, height: max(20, size * CGFloat(items[index].fraction)))
                            .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 24)
            }
        }
        .frame(width: size, height: size)
    }

    static let columnGradients: [LinearGradient] = [
        .init(
            colors: [Color(red: 0.43, green: 0.77, blue: 1.00),
                     Color(red: 0.20, green: 0.58, blue: 0.97)],
            startPoint: .top,
            endPoint: .bottom
        ),
        .init(
            colors: [Color(red: 0.72, green: 0.95, blue: 1.00),
                     Color(red: 0.40, green: 0.84, blue: 0.98)],
            startPoint: .top,
            endPoint: .bottom
        ),
        .init(
            colors: [Color(red: 0.58, green: 0.90, blue: 1.00),
                     Color(red: 0.28, green: 0.73, blue: 0.98)],
            startPoint: .top,
            endPoint: .bottom
        ),
        .init(
            colors: [Color(red: 0.93, green: 0.95, blue: 0.98),
                     Color(red: 0.82, green: 0.86, blue: 0.93)],
            startPoint: .top,
            endPoint: .bottom
        )
    ]
}

// MARK: - Computed Column Data
private extension SmartCleanView {

    var columnItems: [ColumnGraphView.Item] {
        let categories = analyzer.sortedCategories().filter { $0.size > 0 }
        guard let maxSize = categories.map(\.size).max(), maxSize > 0 else {
            return []
        }
        return categories.map {
            ColumnGraphView.Item(
                name: $0.name,
                sizeBytes: $0.size,
                fraction: Double($0.size) / Double(maxSize)
            )
        }
    }
}

private extension SmartCleanView {

    var categoryLegend: some View {
        let categories = analyzer.sortedCategories().filter { $0.size > 0 }
        let total = categories.reduce(0) { $0 + $1.size }

        return VStack(spacing: 8) {
            ForEach(Array(categories.enumerated()), id: \.offset) { index, category in
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(ColumnGraphView.columnGradients[index % ColumnGraphView.columnGradients.count])
                        .frame(width: 12, height: 12)

                    Text(category.name)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(1)

                    Spacer()

                    Text(analyzer.formattedGB(category.size))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.white.opacity(0.75))

                    let percent = total > 0 ? (Double(category.size) / Double(total)) * 100 : 0
                    Text(String(format: "• %.1f%%", percent))
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Sidebar Styled Button
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

// MARK: - Computed Pie Data
private extension SmartCleanView {}
#Preview {
    SmartCleanView()
        .environmentObject(AppController.shared)
        .frame(width: 1000, height: 720)
}
