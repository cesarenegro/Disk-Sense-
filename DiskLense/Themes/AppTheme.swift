import SwiftUI

enum AppTheme {
    // MARK: - Core palette (match screenshot)
    static let sidebarTop = Color(red: 0.10, green: 0.15, blue: 0.34)
    static let sidebarBottom = Color(red: 0.06, green: 0.10, blue: 0.26)

    static let contentTop = Color(red: 0.14, green: 0.12, blue: 0.38)
    static let contentBottom = Color(red: 0.96, green: 0.96, blue: 0.98)

    static let accent = Color(red: 0.12, green: 0.45, blue: 0.74)   // blue button
    static let accent2 = Color(red: 0.16, green: 0.56, blue: 0.82)  // lighter blue
    static let intelligenceAccent = Color(red: 0.12, green: 0.78, blue: 0.70)
    static let intelligenceInactive = Color(red: 0.90, green: 0.83, blue: 0.74)

    static let textOnDark = Color.white
    static let textOnDarkMuted = Color.white.opacity(0.70)
    static let textOnLight = Color.black.opacity(0.90)
    static let textOnLightMuted = Color.black.opacity(0.55)

    static let cardFill = Color.white.opacity(0.10)
    static let cardStroke = Color.white.opacity(0.18)

    // MARK: - Layout
    static let sidebarWidth: CGFloat = 260
    static let windowCornerRadius: CGFloat = 18
    static let pillRadius: CGFloat = 12
    static let cardRadius: CGFloat = 14
    static let contentMaxWidth: CGFloat = 860
}

// Centralized asset names (edit ONLY here if needed)
enum Asset {
    // Sidebar icons (xcassets)
    static let icHome = "ic_home"
    static let icSmartClean = "ic_smart_clean"
    static let icFlash = "ic_flash_clean"
    static let icUninstall = "ic_app_uninstall"
    static let icDuplicates = "ic_duplicates"
    static let icLargeFiles = "ic_large_files"
    static let icStartup = "ic_startup_items"
    static let icSettings = "ic_settings"
    static let icHelp = "ic_help"
    static let icPower = "ic_power"

    // Hero image (xcassets)
    static let hero = "hero_home"     // <-- rename to your actual hero name in xcassets
}

