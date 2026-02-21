import Foundation

struct AppInfo: Identifiable {
    let id = UUID()
    let name: String
    let version: String
    let size: Int64
    let path: String
    let bundleIdentifier: String
}