import SwiftUI
import AppKit

struct AppShellView: View {
    @EnvironmentObject private var app: AppController
    @State private var route: Route = .home

    @StateObject private var analyzer = JunkAnalyzer()
    @StateObject private var flash = FlashCleaner()
    @StateObject private var dup = DuplicateFinder()
    @StateObject private var large = LargeFilesFinder()
    @StateObject private var startup = StartupManager()

    @State private var flashScanRequestID: UUID = UUID()
    @State private var smartCleanScanRequestID: UUID = UUID()
    @State private var didConfigureWindow = false

    init() {
        #if RELEASE_SCREENSHOT
        _route = State(initialValue: Self.initialRouteForScreenshot())
        #endif
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: AppTheme.sidebarWidth)

            Divider().opacity(0.25)

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.windowCornerRadius, style: .continuous))
        #if RELEASE_SCREENSHOT
        .background(screenshotWindowAccessor)
        .onAppear {
            if let demo = ScreenshotMode.demoData {
                ActionListManager.shared.applyScreenshotDemoData(demo)
            }
        }
        #endif
    }
}

// MARK: - Sidebar
private extension AppShellView {

    var sidebar: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.sidebarTop, AppTheme.sidebarBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 14) {

                // Top Nav
                VStack(spacing: 10) {
                    SidebarNavItem(title: "Home", assetIcon: Asset.icHome, isSelected: route == .home) {
                        route = .home
                    }
                    SidebarNavItem(title: "Smart Clean", assetIcon: Asset.icSmartClean, isSelected: route == .smartClean) {
                        smartCleanScanRequestID = UUID()
                        route = .smartClean
                    }
                    SidebarNavItem(
                        title: "Intelligence Tool",
                        assetIcon: Asset.icFlash,
                        isSelected: route == .intelligenceTool,
                        accentColor: AppTheme.intelligenceAccent,
                        inactiveColor: AppTheme.intelligenceInactive
                    ) {
                        route = .intelligenceTool
                    }
                }
                .padding(.top, 18)
                .padding(.horizontal, 14)

                // ✅ Stats Card (LIVE values + mockup-like icons)
                statsCard
                    .padding(.horizontal, 14)

                // Main Nav
                VStack(spacing: 10) {
                    SidebarNavItem(title: "App Uninstall", assetIcon: Asset.icUninstall, isSelected: route == .appUninstall) {
                        route = .appUninstall
                    }
                    SidebarNavItem(title: "Duplicates", assetIcon: Asset.icDuplicates, isSelected: route == .duplicates) {
                        route = .duplicates
                    }
                    SidebarNavItem(title: "Large Files", assetIcon: Asset.icLargeFiles, isSelected: route == .largeFiles) {
                        route = .largeFiles
                    }
                    SidebarNavItem(title: "Startup Items", assetIcon: Asset.icStartup, isSelected: route == .startup) {
                        route = .startup
                    }
                }
                .padding(.horizontal, 14)

                Spacer()

                bottomIcons
                    .padding(.horizontal, 18)
                    .padding(.bottom, 16)
            }
        }
    }

    var statsCard: some View {
        VStack(alignment: .leading, spacing: 14) {

            StatLine(systemIcon: "sparkles",
                     title: "Total Cleaned",
                     value: app.totalCleanedText)

            StatLine(systemIcon: "clock",
                     title: "Last Scan",
                     value: app.lastScanText)

            StatLine(systemIcon: "heart.fill",
                     title: "System Health",
                     value: app.healthText)
        }
        .padding(14)
        .background(AppTheme.cardFill)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cardRadius, style: .continuous)
                .stroke(AppTheme.cardStroke, lineWidth: 1)
        )
        .cornerRadius(AppTheme.cardRadius)
    }

    var bottomIcons: some View {
        HStack(spacing: 16) {
            SidebarIconButton(asset: Asset.icSettings) { route = .settings }
            SidebarIconButton(asset: Asset.icHelp) { route = .help }
            Spacer()
            SidebarIconButton(asset: Asset.icPower) { NSApplication.shared.terminate(nil) }
        }
    }
}

// MARK: - Content
private extension AppShellView {

    @ViewBuilder
    var content: some View {
        #if RELEASE_SCREENSHOT
        switch ScreenshotMode.scene {
        case .dashboard:
            HomeView(onScan: nil)
        case .detail:
            SmartCleanView(scanRequestID: smartCleanScanRequestID, initialDetailsVisible: true)
        case .report:
            ReviewDecisionPanelView()
        case .analytics:
            IntelligenceToolView()
        }
        #else
        switch route {

        case .home:
            HomeView(onScan: {
                flashScanRequestID = UUID()
                route = .flashClean
            })

        case .smartClean:
            SmartCleanView(scanRequestID: smartCleanScanRequestID)

        case .intelligenceTool:
            IntelligenceToolView()

        case .flashClean:
            FlashCleanView(analyzer: analyzer, flash: flash, scanRequestID: flashScanRequestID)

        case .duplicates:
            DuplicatesView(dup: dup)

        case .largeFiles:
            LargeFilesView(finder: large)

        case .startup:
            StartupView(manager: startup)

        case .appUninstall:
            ModernAppUninstallerView()

        case .settings:
            SettingsView()

        case .help:
            HelpView()
        }
        #endif
    }

    // MARK: - Helpers

    private struct StatLine: View {
        let systemIcon: String
        let title: String
        let value: String

        var body: some View {
            HStack(spacing: 10) {
                Image(systemName: systemIcon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                    .frame(width: 22)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.75))
                    Text(value)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }

                Spacer()
            }
        }
    }

    private struct SidebarIconButton: View {
        let asset: String
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                Image(asset)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .padding(10)
                    .background(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Route
    enum Route: Equatable {
        case home
        case smartClean
        case intelligenceTool
        case flashClean
        case appUninstall
        case duplicates
        case largeFiles
        case startup
        case settings
        case help
    }
}

#if RELEASE_SCREENSHOT
private extension AppShellView {
    static func initialRouteForScreenshot() -> Route {
        switch ScreenshotMode.scene {
        case .dashboard:
            return .home
        case .detail:
            return .smartClean
        case .report:
            return .intelligenceTool
        case .analytics:
            return .intelligenceTool
        }
    }

    var screenshotWindowAccessor: some View {
        WindowAccessor { window in
            guard !didConfigureWindow else { return }
            didConfigureWindow = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                let targetSize = CGSize(width: 1440, height: 900)
                window.setContentSize(targetSize)
                window.contentMinSize = targetSize
                window.contentMaxSize = targetSize
                window.center()
                window.isRestorable = false
                window.setFrameAutosaveName("")
                window.tabbingMode = .disallowed
                NSAnimationContext.current.duration = 0
                NSAnimationContext.current.allowsImplicitAnimation = false
            }
        }
    }
}
#endif
