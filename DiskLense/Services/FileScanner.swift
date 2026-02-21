import Foundation

@MainActor
class FileScanner: ObservableObject {
    @Published var isScanning = false
    @Published var progress: Double = 0
    
    func scanDirectory(at url: URL) async -> [URL] {
        isScanning = true
        progress = 0
        
        var files: [URL] = []
        
        do {
            let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil)
            while let fileURL = enumerator?.nextObject() as? URL {
                files.append(fileURL)
                progress = Double(files.count).truncatingRemainder(dividingBy: 100) / 100
            }
        }
        
        isScanning = false
        return files
    }
}