//
//  NotificationManager.swift
//  Swift Cleaner
//
//  Created by APPLE on 12/2/2026.
//


//
//  NotificationManager.swift
//  Swift Cleaner
//
//  Created by APPLE on 12/2/2026.
//

import Foundation
import UserNotifications
import AppKit

@MainActor
class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    override private init() {
        super.init()
        notificationCenter.delegate = self
    }
    
    func requestAuthorization() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    func sendCleanCompleteNotification(size: Int64, type: String) {
        let content = UNMutableNotificationContent()
        content.title = "\(type) Complete! 🎉"
        content.body = "Freed up \(size.formattedSize)"
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Deliver immediately
        )
        
        notificationCenter.add(request)
    }
    
    func sendLowDiskSpaceNotification(free: Int64) {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Low Disk Space"
        content.body = "Only \(free.formattedSize) available. Run a clean to free up space."
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(
            identifier: "low-disk-space-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request)
    }
    
    func sendTrashAutoCleanedNotification(size: Int64) {
        let content = UNMutableNotificationContent()
        content.title = "Trash Auto-Cleaned"
        content.body = "\(size.formattedSize) was automatically emptied"
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(
            identifier: "trash-cleaned-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request)
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }
}