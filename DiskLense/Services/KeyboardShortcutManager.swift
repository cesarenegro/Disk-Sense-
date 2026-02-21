//
//  KeyboardShortcutManager.swift
//  Swift Cleaner
//
//  Created by APPLE on 12/2/2026.
//


//
//  KeyboardShortcutManager.swift
//  Swift Cleaner
//
//  Created by APPLE on 12/2/2026.
//

import SwiftUI
import AppKit

@MainActor
class KeyboardShortcutManager: ObservableObject {
    static let shared = KeyboardShortcutManager()
    
    private var monitor: Any?
    
    func registerGlobalShortcuts() {
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            self.handleKeyEvent(event)
            return event
        }
    }
    
    func unregisterGlobalShortcuts() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) {
        guard event.modifierFlags.contains(.command) else { return }
        
        switch event.charactersIgnoringModifiers {
        // Navigation - 1 through 6
        case "1":
            NotificationCenter.default.post(name: NSNotification.Name("NavigateToHome"), object: nil)
        case "2":
            NotificationCenter.default.post(name: NSNotification.Name("NavigateToFlashClean"), object: nil)
        case "3":
            NotificationCenter.default.post(name: NSNotification.Name("NavigateToApps"), object: nil)
        case "4":
            NotificationCenter.default.post(name: NSNotification.Name("NavigateToDuplicates"), object: nil)
        case "5":
            NotificationCenter.default.post(name: NSNotification.Name("NavigateToLargeFiles"), object: nil)
        case "6":
            NotificationCenter.default.post(name: NSNotification.Name("NavigateToStartup"), object: nil)
            
        // Actions
        case "c":
            NotificationCenter.default.post(name: NSNotification.Name("PerformQuickClean"), object: nil)
        case "s":
            NotificationCenter.default.post(name: NSNotification.Name("PerformSmartClean"), object: nil)
        case "r":
            NotificationCenter.default.post(name: NSNotification.Name("RefreshCurrentTab"), object: nil)
        case ",":
            NotificationCenter.default.post(name: NSNotification.Name("OpenSettings"), object: nil)
        case "?":
            NotificationCenter.default.post(name: NSNotification.Name("OpenHelp"), object: nil)
            
        // History
        case "h":
            NotificationCenter.default.post(name: NSNotification.Name("NavigateToHistory"), object: nil)
            
        // Recent Documents
        case "r" where event.modifierFlags.contains(.shift):
            NotificationCenter.default.post(name: NSNotification.Name("NavigateToRecentDocs"), object: nil)
            
        default:
            break
        }
    }
    
    static let shortcutDescriptions: [(key: String, modifiers: [String], description: String)] = [
        ("1", ["⌘"], "Home"),
        ("2", ["⌘"], "Flash Clean"),
        ("3", ["⌘"], "App Uninstall"),
        ("4", ["⌘"], "Duplicates"),
        ("5", ["⌘"], "Large Files"),
        ("6", ["⌘"], "Startup Items"),
        ("H", ["⌘"], "Cleanup History"),
        ("R", ["⇧", "⌘"], "Recent Documents"),
        ("C", ["⌘"], "One-Click Clean"),
        ("S", ["⌘"], "Smart Clean"),
        ("R", ["⌘"], "Refresh"),
        (",", ["⌘"], "Settings"),
        ("?", ["⌘"], "Help")
    ]
}