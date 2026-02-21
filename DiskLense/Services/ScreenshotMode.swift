import Foundation

enum ScreenshotScene: String {
    case dashboard
    case detail
    case report
    case analytics
}

enum ScreenshotMode {
    #if RELEASE_SCREENSHOT
    static let isEnabled = true
    #else
    static let isEnabled = false
    #endif

    static let scene: ScreenshotScene = {
        guard isEnabled else { return .dashboard }
        let key = "screenshotScene="
        for arg in ProcessInfo.processInfo.arguments {
            if let range = arg.range(of: key) {
                let value = String(arg[range.upperBound...]).lowercased()
                return ScreenshotScene(rawValue: value) ?? .dashboard
            }
            if let range = arg.range(of: "–" + key) {
                let value = String(arg[range.upperBound...]).lowercased()
                return ScreenshotScene(rawValue: value) ?? .dashboard
            }
        }
        return .dashboard
    }()

    #if RELEASE_SCREENSHOT
    static let demoData: ScreenshotDemoData? = ScreenshotDemoData.load()

    static func formattedDate(_ date: Date) -> String {
        return screenshotDateFormatter.string(from: date)
    }

    private static let screenshotDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    #endif
}
