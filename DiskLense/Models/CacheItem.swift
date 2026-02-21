import Foundation

struct CacheItem: Identifiable {
    let id = UUID()
    let name: String
    let size: Int64
    let path: String
}