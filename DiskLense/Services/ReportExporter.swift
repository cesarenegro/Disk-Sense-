import Foundation
import AppKit

@MainActor
class ReportExporter: ObservableObject {
    @Published var isExporting = false
    
    func exportReport(data: String, filename: String) {
        isExporting = true
        
        let savePanel = NSSavePanel()
        savePanel.title = "Export Report"
        savePanel.nameFieldStringValue = filename
        savePanel.allowedContentTypes = [.plainText, .pdf, .commaSeparatedText]
        
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try data.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    print("Failed to save report: \(error)")
                }
            }
            self.isExporting = false
        }
    }
    
    func generateCleanupReport(cleanedSize: Int64, fileCount: Int) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        
        return """
        DiskLense Report
        Date: \(dateFormatter.string(from: Date()))
        
        Cleanup Summary:
        - Total space freed: \(ByteCountFormatter.string(fromByteCount: cleanedSize, countStyle: .file))
        - Files removed: \(fileCount)
        
        System Status: Healthy
        """
    }
}