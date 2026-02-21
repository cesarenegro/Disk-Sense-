//
//  CleanupHistoryManager.swift
//  Swift Cleaner
//
//  Created by APPLE on 12/2/2026.
//

import Foundation
import SwiftUI

@MainActor
class CleanupHistoryManager: ObservableObject {
    static let shared = CleanupHistoryManager()
    
    @Published var sessions: [CleanupSession] = []
    @Published var totalSpaceSaved: Int64 = 0
    @Published var averagePerSession: Int64 = 0
    
    struct CleanupSession: Identifiable, Codable {
        let id: UUID  // FIXED: No default value for Codable
        let date: Date
        let type: CleanupType
        let size: Int64
        let itemCount: Int
        let details: [String]
        
        init(id: UUID = UUID(), date: Date, type: CleanupType, size: Int64, itemCount: Int, details: [String]) {
            self.id = id
            self.date = date
            self.type = type
            self.size = size
            self.itemCount = itemCount
            self.details = details
        }
        
        enum CleanupType: String, Codable, CaseIterable {
            case quick = "Quick Clean"
            case smart = "Smart Clean"
            case trash = "Empty Trash"
            case duplicates = "Duplicates"
            case largeFiles = "Large Files"
            case apps = "App Uninstall"
            case recentDocs = "Recent Documents"
            
            var icon: String {
                switch self {
                case .quick: return "sparkles"
                case .smart: return "wand.and.stars"
                case .trash: return "trash"
                case .duplicates: return "doc.on.doc"
                case .largeFiles: return "archivebox"
                case .apps: return "app.badge"
                case .recentDocs: return "clock.arrow.circlepath"
                }
            }
            
            var color: Color {
                switch self {
                case .quick: return .blue
                case .smart: return .purple
                case .trash: return .gray
                case .duplicates: return .indigo
                case .largeFiles: return .green
                case .apps: return .orange
                case .recentDocs: return .pink
                }
            }
        }
    }
    
    private let saveKey = "cleanupHistory"
    private let maxSessions = 100
    
    init() {
        loadHistory()
    }
    
    func addSession(type: CleanupSession.CleanupType, size: Int64, itemCount: Int, details: [String] = []) {
        let session = CleanupSession(
            date: Date(),
            type: type,
            size: size,
            itemCount: itemCount,
            details: details
        )
        
        sessions.insert(session, at: 0)
        
        if sessions.count > maxSessions {
            sessions = Array(sessions.prefix(maxSessions))
        }
        
        totalSpaceSaved = sessions.reduce(0) { $0 + $1.size }
        averagePerSession = sessions.isEmpty ? 0 : totalSpaceSaved / Int64(sessions.count)
        
        saveHistory()
    }
    
    func clearHistory() {
        sessions.removeAll()
        totalSpaceSaved = 0
        averagePerSession = 0
        saveHistory()
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
        UserDefaults.standard.set(Int(totalSpaceSaved), forKey: "totalSpaceCleaned")
    }
    
    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: saveKey),
              let decoded = try? JSONDecoder().decode([CleanupSession].self, from: data) else {
            addSampleData()
            return
        }
        
        sessions = decoded
        totalSpaceSaved = sessions.reduce(0) { $0 + $1.size }
        averagePerSession = sessions.isEmpty ? 0 : totalSpaceSaved / Int64(sessions.count)
    }
    
    private func addSampleData() {
        addSession(type: .smart, size: 4_500_000_000, itemCount: 128,
                  details: ["System Cache: 2.1 GB", "Duplicates: 1.8 GB"])
        addSession(type: .quick, size: 850_000_000, itemCount: 342,
                  details: ["Caches: 520 MB", "Logs: 210 MB"])
        addSession(type: .trash, size: 1_200_000_000, itemCount: 47,
                  details: ["Empty Trash"])
    }
    
    func getSessions(in days: Int) -> [CleanupSession] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return sessions.filter { $0.date >= cutoffDate }
    }
}
