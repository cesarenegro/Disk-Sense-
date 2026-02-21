import Foundation
import OSLog

class AppLogger {
    static let shared = AppLogger()
    private let logger = Logger(subsystem: "com.swiftcleaner", category: "main")
    
    func log(_ message: String) {
        logger.log("\(message)")
    }
    
    func error(_ message: String) {
        logger.error("\(message)")
    }
}
