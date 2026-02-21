import SwiftUI

@main
struct DiskLenseApp: App {

    @StateObject private var app = AppController.shared

    var body: some Scene {
        WindowGroup {
            AppShellView()
                .environmentObject(app)
                #if RELEASE_SCREENSHOT
                .transaction { $0.animation = nil }
                #endif
        }
        .windowStyle(.hiddenTitleBar)
    }
}
