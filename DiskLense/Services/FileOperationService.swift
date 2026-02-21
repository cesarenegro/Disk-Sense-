import Foundation

@MainActor
class FileOperationService: ObservableObject {
    @Published var isDeleting = false
    @Published var progress: Double = 0
    
    func deleteFile(at url: URL) async throws {
        isDeleting = true
        progress = 0.5
        try FileManager.default.removeItem(at: url)
        progress = 1.0
        try await Task.sleep(nanoseconds: 300_000_000)
        isDeleting = false
    }
    
    func moveFile(from: URL, to: URL) async throws {
        isDeleting = true
        progress = 0.3
        try FileManager.default.moveItem(at: from, to: to)
        progress = 1.0
        try await Task.sleep(nanoseconds: 300_000_000)
        isDeleting = false
    }
}