import Foundation
import SwiftUI

struct EnhancedAppInfo: Identifiable {
    let id = UUID()
    let name: String
    let version: String
    let size: Int64
    let path: String
    let bundleIdentifier: String
    let isSystemApp: Bool
    let lastUsed: Date?
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var formattedLastUsed: String {
        guard let lastUsed = lastUsed else { return "Never" }
        #if RELEASE_SCREENSHOT
        return ScreenshotMode.formattedDate(lastUsed)
        #else
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastUsed, relativeTo: Date())
        #endif
    }
}
