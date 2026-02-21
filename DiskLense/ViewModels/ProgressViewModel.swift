import Foundation
import SwiftUI

@MainActor
class ProgressViewModel: ObservableObject {
    @Published var progress: Double = 0
    @Published var status: String = "Ready"
    @Published var isRunning = false
    
    func startOperation(totalSteps: Int) {
        isRunning = true
        progress = 0
        status = "Starting..."
    }
    
    func updateProgress(step: Int, total: Int, message: String) {
        progress = Double(step) / Double(total)
        status = message
    }
    
    func completeOperation(success: Bool) {
        isRunning = false
        progress = success ? 1.0 : 0
        status = success ? "Completed" : "Failed"
    }
}