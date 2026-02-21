import Foundation
import SwiftUI

struct StartupItem: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let type: StartupType
    let status: StartupStatus
    
    enum StartupType {
        case launchAgent, launchDaemon, loginItem
        
        var icon: String {
            switch self {
            case .launchAgent: return "person.fill"
            case .launchDaemon: return "lock.shield"
            case .loginItem: return "power"
            }
        }
        
        var color: Color {
            switch self {
            case .launchAgent: return .blue
            case .launchDaemon: return .purple
            case .loginItem: return .orange
            }
        }
        
        var folderName: String {
            switch self {
            case .launchAgent: return "Launch Agents"
            case .launchDaemon: return "Launch Daemons"
            case .loginItem: return "Login Items"
            }
        }
        
        var description: String {
            switch self {
            case .launchAgent: return "Run when you log in"
            case .launchDaemon: return "System-wide background services"
            case .loginItem: return "Applications that launch at login"
            }
        }
    }
    
    enum StartupStatus {
        case enabled, disabled, unknown
        
        var icon: String {
            switch self {
            case .enabled: return "checkmark.circle.fill"
            case .disabled: return "xmark.circle.fill"
            case .unknown: return "questionmark.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .enabled: return .green
            case .disabled: return .red
            case .unknown: return .gray
            }
        }
    }
}

// MARK: - Startup Folder Group
struct StartupFolder: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let description: String
    var items: [StartupItem]
    
    var totalCount: Int {
        items.count
    }
    
    var enabledCount: Int {
        items.filter { $0.status == .enabled }.count
    }
    
    var disabledCount: Int {
        items.filter { $0.status == .disabled }.count
    }
}

@MainActor
class StartupManager: ObservableObject {
    @Published var folders: [StartupFolder] = []
    @Published var isLoading = false
    @Published var searchText = ""
    
    var filteredFolders: [StartupFolder] {
        guard !searchText.isEmpty else { return folders }
        
        return folders.map { folder in
            let filteredItems = folder.items.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.path.localizedCaseInsensitiveContains(searchText)
            }
            return StartupFolder(
                name: folder.name,
                icon: folder.icon,
                color: folder.color,
                description: folder.description,
                items: filteredItems
            )
        }.filter { !$0.items.isEmpty }
    }
    
    func load() {
        isLoading = true
        folders = []
        
        Task {
            let items = await loadStartupItems()
            await MainActor.run {
                self.folders = self.organizeIntoFolders(items)
                self.isLoading = false
            }
        }
    }
    
    private func organizeIntoFolders(_ items: [StartupItem]) -> [StartupFolder] {
        let launchAgents = items.filter { $0.type == .launchAgent }
        let launchDaemons = items.filter { $0.type == .launchDaemon }
        let loginItems = items.filter { $0.type == .loginItem }
        
        var folders: [StartupFolder] = []
        
        if !launchAgents.isEmpty {
            folders.append(StartupFolder(
                name: StartupItem.StartupType.launchAgent.folderName,
                icon: "person.fill",
                color: .blue,
                description: StartupItem.StartupType.launchAgent.description,
                items: launchAgents.sorted { $0.name < $1.name }
            ))
        }
        
        if !launchDaemons.isEmpty {
            folders.append(StartupFolder(
                name: StartupItem.StartupType.launchDaemon.folderName,
                icon: "lock.shield",
                color: .purple,
                description: StartupItem.StartupType.launchDaemon.description,
                items: launchDaemons.sorted { $0.name < $1.name }
            ))
        }
        
        if !loginItems.isEmpty {
            folders.append(StartupFolder(
                name: StartupItem.StartupType.loginItem.folderName,
                icon: "power",
                color: .orange,
                description: StartupItem.StartupType.loginItem.description,
                items: loginItems.sorted { $0.name < $1.name }
            ))
        }
        
        return folders
    }
    
    private func loadStartupItems() async -> [StartupItem] {
        var allItems: [StartupItem] = []
        
        // Load Launch Agents (User)
        let userLibraryPaths = [
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/LaunchAgents").path,
            "/Library/LaunchAgents"
        ]
        
        for path in userLibraryPaths {
            allItems.append(contentsOf: loadItemsFromDirectory(path: path, type: .launchAgent))
        }
        
        // Load Launch Daemons (System)
        allItems.append(contentsOf: loadItemsFromDirectory(path: "/Library/LaunchDaemons", type: .launchDaemon))
        
        // Load Login Items
        await allItems.append(contentsOf: loadLoginItems())
        
        return allItems
    }
    
    private func loadItemsFromDirectory(path: String, type: StartupItem.StartupType) -> [StartupItem] {
        var items: [StartupItem] = []
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: path),
              let files = try? fileManager.contentsOfDirectory(atPath: path) else {
            return items
        }
        
        for file in files where file.hasSuffix(".plist") {
            let fullPath = (path as NSString).appendingPathComponent(file)
            let name = (file as NSString).deletingPathExtension
                .replacingOccurrences(of: ".", with: " ")
                .capitalized
            
            // Check if enabled/disabled (simplified - check if file exists and is loadable)
            let status: StartupItem.StartupStatus = fileManager.isReadableFile(atPath: fullPath) ? .enabled : .unknown
            
            items.append(StartupItem(
                name: name,
                path: fullPath,
                type: type,
                status: status
            ))
        }
        
        return items
    }
    
    private func loadLoginItems() async -> [StartupItem] {
        var items: [StartupItem] = []
        
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", "tell application \"System Events\" to get the name of every login item"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let names = output.components(separatedBy: ", ")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                
                for name in names {
                    items.append(StartupItem(
                        name: name,
                        path: "Login Item: \(name)",
                        type: .loginItem,
                        status: .enabled
                    ))
                }
            }
        } catch {
            print("Failed to load login items: \(error)")
        }
        
        return items
    }
    
    func remove(_ item: StartupItem) {
        // Remove from UI
        for i in 0..<folders.count {
            folders[i].items.removeAll { $0.id == item.id }
        }
        // Remove empty folders
        folders.removeAll { $0.items.isEmpty }
        
        // Actually remove the file or login item
        Task {
            await removeItem(item)
        }
    }
    
    private func removeItem(_ item: StartupItem) async {
        switch item.type {
        case .launchAgent, .launchDaemon:
            try? FileManager.default.removeItem(atPath: item.path)
        case .loginItem:
            await removeLoginItem(name: item.name)
        }
    }
    
    private func removeLoginItem(name: String) async {
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", "tell application \"System Events\" to delete login item \"\(name)\""]
        
        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            print("Failed to remove login item: \(error)")
        }
    }
    
    func toggleStatus(_ item: StartupItem) {
        // In a real app, you would enable/disable the launch agent/daemon
        // For now, just update UI
        for i in 0..<folders.count {
            if let j = folders[i].items.firstIndex(where: { $0.id == item.id }) {
                let newStatus: StartupItem.StartupStatus = folders[i].items[j].status == .enabled ? .disabled : .enabled
                folders[i].items[j] = StartupItem(
                    name: item.name,
                    path: item.path,
                    type: item.type,
                    status: newStatus
                )
                break
            }
        }
    }
}
