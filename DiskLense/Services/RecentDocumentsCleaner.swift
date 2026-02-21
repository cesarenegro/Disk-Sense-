//
//  RecentDocumentsCleaner.swift
//  Swift Cleaner
//
//  Created by APPLE on 12/2/2026.
//


//
//  RecentDocumentsCleaner.swift
//  Swift Cleaner
//
//  Created by APPLE on 12/2/2026.
//

import Foundation
import SwiftUI

@MainActor
class RecentDocumentsCleaner: ObservableObject {
    @Published var recentItems: [RecentItem] = []
    @Published var totalSize: Int64 = 0
    @Published var isScanning = false
    
    struct RecentItem: Identifiable {
        let id = UUID()
        let name: String
        let path: String
        let size: Int64
        let lastOpened: Date
        let application: String
        
        var formattedSize: String {
            ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
        }
        
        var formattedDate: String {
            #if RELEASE_SCREENSHOT
            return ScreenshotMode.formattedDate(lastOpened)
            #else
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return formatter.localizedString(for: lastOpened, relativeTo: Date())
            #endif
        }
    }
    
    func scan() async {
        isScanning = true
        recentItems.removeAll()
        totalSize = 0
        
        // 1. Finder Recent Items
        await scanFinderRecents()
        
        // 2. Application Recent Documents
        await scanApplicationRecents()
        
        // 3. Quick Look Recents
        await scanQuickLookRecents()
        
        isScanning = false
    }
    
    private func scanFinderRecents() async {
        let finderRecentPaths = [
            NSHomeDirectory() + "/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.FavoriteItems.sfl2",
            NSHomeDirectory() + "/Library/Application Support/com.apple.sharedfilelist/com.apple.LSSharedFileList.RecentDocuments.sfl2",
            NSHomeDirectory() + "/Library/Preferences/com.apple.recentitems.plist"
        ]
        
        for path in finderRecentPaths where FileManager.default.fileExists(atPath: path) {
            if let attrs = try? FileManager.default.attributesOfItem(atPath: path),
               let size = attrs[.size] as? Int64 {
                recentItems.append(RecentItem(
                    name: "Finder Recent Documents",
                    path: path,
                    size: size,
                    lastOpened: attrs[.modificationDate] as? Date ?? Date(),
                    application: "Finder"
                ))
                totalSize += size
            }
        }
    }
    
    private func scanApplicationRecents() async {
        let appRecentPatterns = [
            "~/Library/Containers/com.microsoft.Word/Data/Library/Preferences/com.microsoft.Word.securebookmarks.plist",
            "~/Library/Containers/com.microsoft.Excel/Data/Library/Preferences/com.microsoft.Excel.securebookmarks.plist",
            "~/Library/Containers/com.apple.Preview/Data/Library/Preferences/com.apple.Preview.LSSharedFileList.plist",
            "~/Library/Containers/com.apple.TextEdit/Data/Library/Preferences/com.apple.TextEdit.LSSharedFileList.plist"
        ]
        
        for pattern in appRecentPatterns {
            let path = NSString(string: pattern).expandingTildeInPath
            guard FileManager.default.fileExists(atPath: path),
                  let attrs = try? FileManager.default.attributesOfItem(atPath: path),
                  let size = attrs[.size] as? Int64 else { continue }
            
            let appName = path.components(separatedBy: ".com.").last?
                .components(separatedBy: "/").first ?? "Unknown"
            
            recentItems.append(RecentItem(
                name: "\(appName) Recent Documents",
                path: path,
                size: size,
                lastOpened: attrs[.modificationDate] as? Date ?? Date(),
                application: appName
            ))
            totalSize += size
        }
    }
    
    private func scanQuickLookRecents() async {
        let quickLookPath = NSHomeDirectory() + "/Library/Caches/com.apple.helpd/Recents"
        
        guard FileManager.default.fileExists(atPath: quickLookPath),
              let enumerator = FileManager.default.enumerator(atPath: quickLookPath) else { return }
        
        while let file = enumerator.nextObject() as? String {
            let fullPath = (quickLookPath as NSString).appendingPathComponent(file)
            guard let attrs = try? FileManager.default.attributesOfItem(atPath: fullPath),
                  let size = attrs[.size] as? Int64 else { continue }
            
            recentItems.append(RecentItem(
                name: "Quick Look: \(file)",
                path: fullPath,
                size: size,
                lastOpened: attrs[.modificationDate] as? Date ?? Date(),
                application: "Quick Look"
            ))
            totalSize += size
        }
    }
    
    func clearAllRecents() async -> Int64 {
        var cleanedSize: Int64 = 0
        
        for item in recentItems {
            do {
                try FileManager.default.removeItem(atPath: item.path)
                cleanedSize += item.size
            } catch {
                print("Failed to delete: \(item.path)")
            }
        }
        
        // Also clear via AppleScript
        await clearSystemRecents()
        
        recentItems.removeAll()
        totalSize = 0
        AudioManager.shared.play(.whoosh)
        
        return cleanedSize
    }
    
    private func clearSystemRecents() async {
        let script = """
        tell application "System Events"
            tell appearance preferences
                set recent applications limit to 0
                set recent documents limit to 0
                set recent servers limit to 0
            end tell
        end tell
        """
        
        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: script) {
            scriptObject.executeAndReturnError(&error)
        }
    }
    
    func clearItem(_ item: RecentItem) async {
        do {
            try FileManager.default.removeItem(atPath: item.path)
            recentItems.removeAll { $0.id == item.id }
            totalSize -= item.size
            AudioManager.shared.play(.trash)
        } catch {
            AudioManager.shared.play(.error)
        }
    }
}
