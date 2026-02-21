//
//  TrashManager.swift
//  Swift Cleaner
//
//  Created by APPLE on 12/2/2026.
//

import Foundation
import SwiftUI
import AppKit
import UserNotifications

@MainActor
class TrashManager: ObservableObject {
    static let shared = TrashManager()
    
    @Published var trashSize: Int64 = 0
    @Published var isAutoCleanEnabled = false
    @Published var autoCleanDays = 7
    @Published var lowDiskThreshold: Int64 = 5_000_000_000 // 5GB
    @Published var isLowDiskSpace = false
    
    @AppStorage("trashAutoClean") private var autoCleanStorage = false
    @AppStorage("trashCleanDays") private var cleanDaysStorage = 7
    @AppStorage("lowDiskThreshold") private var thresholdStorage: Int = 5_000_000_000 // Store as Int
    @AppStorage("lastTrashCleanDate") private var lastCleanDateStorage: Date?
    @AppStorage("lowDiskAlertShown") private var lowDiskAlertShown = false
    
    private var monitorTimer: Timer?
    
    init() {
        isAutoCleanEnabled = autoCleanStorage
        autoCleanDays = cleanDaysStorage
        // FIXED: Convert Int from storage to Int64
        lowDiskThreshold = Int64(thresholdStorage)
        
        startMonitoring()
    }
    
    func startMonitoring() {
        Task { await updateTrashSize() }
        
        monitorTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            Task { @MainActor in
                await self.updateTrashSize()
                await self.checkDiskSpace()
                await self.checkAutoClean()
            }
        }
    }
    
    func updateTrashSize() async {
        let trashPath = NSHomeDirectory() + "/.Trash"
        var total: Int64 = 0
        
        guard FileManager.default.fileExists(atPath: trashPath),
              let enumerator = FileManager.default.enumerator(atPath: trashPath) else {
            trashSize = 0
            return
        }
        
        while let file = enumerator.nextObject() as? String {
            let fullPath = (trashPath as NSString).appendingPathComponent(file)
            if let attrs = try? FileManager.default.attributesOfItem(atPath: fullPath),
               let size = attrs[.size] as? Int64 {
                total += size
            }
        }
        
        trashSize = total
    }
    
    func emptyTrash() async -> Int64 {
        let sizeBefore = trashSize
        
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", "tell application \"Finder\" to empty trash"]
        
        do {
            try task.run()
            task.waitUntilExit()
            
            trashSize = 0
            lastCleanDateStorage = Date()
            AudioManager.shared.play(.whoosh)
            
            return sizeBefore
        } catch {
            AudioManager.shared.play(.error)
            return 0
        }
    }
    
    func checkDiskSpace() async {
        let fileManager = FileManager.default
        if let attributes = try? fileManager.attributesOfFileSystem(forPath: "/"),
           let free = attributes[.systemFreeSize] as? Int64 {
            
            isLowDiskSpace = free < lowDiskThreshold
            
            if isLowDiskSpace && !lowDiskAlertShown {
                showLowDiskAlert(free: free)
                lowDiskAlertShown = true
            } else if !isLowDiskSpace {
                lowDiskAlertShown = false
            }
        }
    }
    
    private func showLowDiskAlert(free: Int64) {
        // Send notification
        NotificationManager.shared.sendLowDiskSpaceNotification(free: free)
        
        let alert = NSAlert()
        alert.messageText = "⚠️ Low Disk Space"
        alert.informativeText = """
        Your Mac is running low on disk space. 
        Only \(free.formattedSize) available.
        
        Would you like to:
        • Empty Trash (\(trashSize.formattedSize))
        • Run Quick Clean
        """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Empty Trash")
        alert.addButton(withTitle: "Quick Clean")
        alert.addButton(withTitle: "Ignore")
        
        let response = alert.runModal()
        
        switch response {
        case .alertFirstButtonReturn:
            Task { await emptyTrash() }
        case .alertSecondButtonReturn:
            NotificationCenter.default.post(name: NSNotification.Name("PerformQuickClean"), object: nil)
        default:
            break
        }
    }
    
    func checkAutoClean() async {
        guard isAutoCleanEnabled else { return }
        
        if let lastClean = lastCleanDateStorage {
            let daysSinceClean = Calendar.current.dateComponents([.day], from: lastClean, to: Date()).day ?? 0
            if daysSinceClean >= autoCleanDays {
                let cleaned = await emptyTrash()
                if cleaned > 0 {
                    NotificationManager.shared.sendTrashAutoCleanedNotification(size: cleaned)
                }
            }
        }
    }
    
    // MARK: - Settings Methods
    func updateAutoCleanSettings(enabled: Bool, days: Int) {
        isAutoCleanEnabled = enabled
        autoCleanDays = days
        autoCleanStorage = enabled
        cleanDaysStorage = days
    }
    
    func updateLowDiskThreshold(_ threshold: Int64) {
        lowDiskThreshold = threshold
        // FIXED: Convert Int64 to Int for storage
        thresholdStorage = Int(threshold)
    }
    
    // MARK: - Manual Clean with Progress
    func emptyTrashWithProgress(progress: @escaping (Double) -> Void) async -> Int64 {
        progress(0.3)
        let size = await emptyTrash()
        progress(1.0)
        return size
    }
    
    // MARK: - Get Trash Contents
    func getTrashContents() async -> [TrashItem] {
        var items: [TrashItem] = []
        let trashPath = NSHomeDirectory() + "/.Trash"
        
        guard FileManager.default.fileExists(atPath: trashPath),
              let contents = try? FileManager.default.contentsOfDirectory(atPath: trashPath) else {
            return items
        }
        
        for fileName in contents {
            let fullPath = (trashPath as NSString).appendingPathComponent(fileName)
            if let attrs = try? FileManager.default.attributesOfItem(atPath: fullPath),
               let size = attrs[.size] as? Int64,
               let modDate = attrs[.modificationDate] as? Date {
                
                let isDirectory = (attrs[.type] as? FileAttributeType) == .typeDirectory
                
                items.append(TrashItem(
                    name: fileName,
                    path: fullPath,
                    size: size,
                    dateDeleted: modDate,
                    isDirectory: isDirectory
                ))
            }
        }
        
        return items.sorted { $0.dateDeleted > $1.dateDeleted }
    }
}

// MARK: - Trash Item Model
struct TrashItem: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let size: Int64
    let dateDeleted: Date
    let isDirectory: Bool
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: dateDeleted, relativeTo: Date())
    }
    
    var icon: String {
        if isDirectory {
            return "folder"
        } else {
            let ext = (name as NSString).pathExtension.lowercased()
            switch ext {
            case "jpg", "jpeg", "png", "gif", "heic", "webp":
                return "photo"
            case "mp4", "mov", "avi", "mkv", "m4v":
                return "film"
            case "mp3", "wav", "m4a", "flac", "aac":
                return "music.note"
            case "pdf":
                return "doc.richtext"
            case "zip", "rar", "7z", "tar", "gz":
                return "archivebox"
            case "dmg", "pkg", "app":
                return "shippingbox"
            case "doc", "docx", "pages":
                return "doc.text"
            case "xls", "xlsx", "numbers":
                return "tablecells"
            case "ppt", "pptx", "key":
                return "chart.bar"
            default:
                return "doc"
            }
        }
    }
    
    var iconColor: Color {
        if isDirectory {
            return .blue
        } else {
            let ext = (name as NSString).pathExtension.lowercased()
            switch ext {
            case "jpg", "jpeg", "png", "gif", "heic":
                return .green
            case "mp4", "mov", "avi", "mkv":
                return .purple
            case "mp3", "wav", "m4a":
                return .pink
            case "pdf":
                return .red
            case "zip", "rar", "7z", "dmg":
                return .orange
            default:
                return .gray
            }
        }
    }
}

// MARK: - Trash Detail View
struct TrashDetailView: View {
    @StateObject private var trashManager = TrashManager.shared
    @State private var items: [TrashItem] = []
    @State private var isLoading = true
    @State private var selectedItems = Set<UUID>()
    @State private var showRestoreConfirmation = false
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Trash")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(items.count) items • \(trashManager.trashSize.formattedSize)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    Task {
                        isLoading = true
                        items = await trashManager.getTrashContents()
                        isLoading = false
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")
                
                Button {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .help("Empty Trash")
                .disabled(items.isEmpty)
                .confirmationDialog(
                    "Empty Trash?",
                    isPresented: $showDeleteConfirmation,
                    actions: {
                        Button("Cancel", role: .cancel) { }
                        Button("Empty Trash", role: .destructive) {
                            Task {
                                _ = await trashManager.emptyTrash()
                                items = await trashManager.getTrashContents()
                            }
                        }
                    },
                    message: {
                        Text("This will permanently delete \(items.count) items. You cannot undo this action.")
                    }
                )
            }
            .padding(.horizontal)
            .padding(.top, 16)
            
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading Trash contents...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.top, 40)
            } else if items.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "trash.slash")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                        .opacity(0.7)
                    
                    Text("Trash is Empty")
                        .font(.headline)
                    
                    Text("Deleted files will appear here")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 60)
            } else {
                // Item list
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(items) { item in
                            TrashItemRow(item: item)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
        }
    }
}

struct TrashItemRow: View {
    let item: TrashItem
    @State private var isHovered = false
    @State private var showDeleteConfirmation = false
    @State private var showRestoreConfirmation = false
    
    var body: some View {
        HStack {
            Image(systemName: item.icon)
                .foregroundColor(item.iconColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 4) {
                    Text(item.formattedSize)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(item.formattedDate)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button {
                    showRestoreConfirmation = true
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .foregroundColor(.blue.opacity(isHovered ? 1 : 0.7))
                }
                .buttonStyle(.plain)
                .help("Restore")
                .confirmationDialog(
                    "Restore \"\(item.name)\"?",
                    isPresented: $showRestoreConfirmation,
                    actions: {
                        Button("Cancel", role: .cancel) { }
                        Button("Restore") {
                            restoreItem(item)
                        }
                    },
                    message: {
                        Text("This will move the item back to its original location.")
                    }
                )
                
                Button {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red.opacity(isHovered ? 1 : 0.7))
                }
                .buttonStyle(.plain)
                .help("Delete Permanently")
                .confirmationDialog(
                    "Delete \"\(item.name)\" permanently?",
                    isPresented: $showDeleteConfirmation,
                    actions: {
                        Button("Cancel", role: .cancel) { }
                        Button("Delete", role: .destructive) {
                            permanentlyDeleteItem(item)
                        }
                    },
                    message: {
                        Text("This action cannot be undone.")
                    }
                )
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.gray.opacity(0.1) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
    
    private func restoreItem(_ item: TrashItem) {
        let fileManager = FileManager.default
        let originalPath = (item.path as NSString).deletingLastPathComponent
            .replacingOccurrences(of: "/.Trash", with: "")
        let destinationPath = (originalPath as NSString).appendingPathComponent(item.name)
        
        do {
            try fileManager.moveItem(atPath: item.path, toPath: destinationPath)
            AudioManager.shared.play(.whoosh)
            
            // Refresh trash
            Task {
                await TrashManager.shared.updateTrashSize()
            }
        } catch {
            print("Failed to restore: \(error)")
            AudioManager.shared.play(.error)
        }
    }
    
    private func permanentlyDeleteItem(_ item: TrashItem) {
        do {
            try FileManager.default.removeItem(atPath: item.path)
            AudioManager.shared.play(.trash)
            
            // Refresh trash
            Task {
                await TrashManager.shared.updateTrashSize()
            }
        } catch {
            print("Failed to delete: \(error)")
            AudioManager.shared.play(.error)
        }
    }
}

#Preview {
    TrashDetailView()
        .frame(width: 500, height: 400)
}
