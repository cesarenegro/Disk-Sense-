import SwiftUI
import AppKit
import Foundation

@MainActor
final class AppController: ObservableObject {
    static let shared = AppController()

    // MARK: - Persist keys
    private enum K {
        static let totalCleaned = "sc.totalCleaned"
        static let lastScanDate = "sc.lastScanDate"
        static let lastCleanDate = "sc.lastCleanDate"
        static let systemHealthScore = "sc.systemHealthScore"
    }

    // MARK: - KPI (source of truth)
    @Published var totalCleaned: Int64 = 0 { didSet { persist() } }
    @Published var lastScanDate: Date? = nil { didSet { persist() } }
    @Published var lastCleanDate: Date? = nil { didSet { persist() } }

    // System health (placeholder for now)
    @Published var systemHealthScore: Int = 82 { didSet { persist() } }

    // Toggle demo seed (only used when no persisted data exists)
    private let seedDemoIfEmpty = true

    private init() {
        DispatchQueue.main.async {
            NSApplication.shared.setActivationPolicy(.regular)
        }

        #if RELEASE_SCREENSHOT
        if ScreenshotMode.isEnabled, let demo = ScreenshotMode.demoData {
            applyScreenshotDemoData(demo)
            return
        }
        #endif

        // Load persisted values first
        restore()

        // If nothing persisted yet, seed demo so sidebar shows something immediately
        if seedDemoIfEmpty, totalCleaned == 0, lastScanDate == nil {
            totalCleaned = 3_080_000_000                  // ~3.08 GB
            lastScanDate = Date().addingTimeInterval(-19) // 19 sec ago
            lastCleanDate = lastScanDate
            systemHealthScore = 92
        }
    }

    // MARK: - Persistence
    private func persist() {
        #if RELEASE_SCREENSHOT
        return
        #endif
        let d = UserDefaults.standard
        d.set(totalCleaned, forKey: K.totalCleaned)
        d.set(systemHealthScore, forKey: K.systemHealthScore)

        if let lastScanDate {
            d.set(lastScanDate.timeIntervalSince1970, forKey: K.lastScanDate)
        } else {
            d.removeObject(forKey: K.lastScanDate)
        }

        if let lastCleanDate {
            d.set(lastCleanDate.timeIntervalSince1970, forKey: K.lastCleanDate)
        } else {
            d.removeObject(forKey: K.lastCleanDate)
        }
    }

    private func restore() {
        #if RELEASE_SCREENSHOT
        return
        #endif
        let d = UserDefaults.standard

        if d.object(forKey: K.totalCleaned) != nil {
            totalCleaned = Int64(d.integer(forKey: K.totalCleaned))
        }

        if d.object(forKey: K.systemHealthScore) != nil {
            systemHealthScore = d.integer(forKey: K.systemHealthScore)
        }

        if d.object(forKey: K.lastScanDate) != nil {
            let t = d.double(forKey: K.lastScanDate)
            if t > 0 { lastScanDate = Date(timeIntervalSince1970: t) }
        }

        if d.object(forKey: K.lastCleanDate) != nil {
            let t = d.double(forKey: K.lastCleanDate)
            if t > 0 { lastCleanDate = Date(timeIntervalSince1970: t) }
        }
    }

    // MARK: - Formatting helpers

    func formattedBytes(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    func relativeLastScanText() -> String {
        guard let d = lastScanDate else { return "Never" }
        #if RELEASE_SCREENSHOT
        return ScreenshotMode.formattedDate(d)
        #else
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f.localizedString(for: d, relativeTo: Date())
        #endif
    }

    func relativeLastCleanText() -> String {
        guard let d = lastCleanDate else { return "Never" }
        #if RELEASE_SCREENSHOT
        return ScreenshotMode.formattedDate(d)
        #else
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f.localizedString(for: d, relativeTo: Date())
        #endif
    }

    // MARK: - UI-friendly accessors (for sidebar)
    var totalCleanedText: String { formattedBytes(totalCleaned) }
    var lastScanText: String { relativeLastScanText() }

    /// Mockup-style label (excellent/good/needs cleaning)
    var healthText: String {
        let s = max(0, min(systemHealthScore, 100))
        switch s {
        case 85...100: return "excellent"
        case 65...84:  return "good"
        default:       return "needs cleaning"
        }
    }

    func requestQuit() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Tracking (call these from scan/clean)
    func recordScanStarted() {
        #if RELEASE_SCREENSHOT
        return
        #else
        lastScanDate = Date()
        #endif
    }

    func recordClean(bytes: Int64) {
        #if RELEASE_SCREENSHOT
        return
        #else
        totalCleaned += max(bytes, 0)
        lastCleanDate = Date()
        lastScanDate = Date()
        systemHealthScore = max(0, min(100, systemHealthScore + 1))
        #endif
    }

    #if RELEASE_SCREENSHOT
    private func applyScreenshotDemoData(_ demo: ScreenshotDemoData) {
        totalCleaned = demo.appStats.totalCleaned
        lastScanDate = demo.parsedDate(demo.appStats.lastScanDate)
        lastCleanDate = demo.parsedDate(demo.appStats.lastCleanDate)
        systemHealthScore = demo.appStats.systemHealthScore
    }
    #endif
}
