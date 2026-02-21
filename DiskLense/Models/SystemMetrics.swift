import Foundation

// MARK: - Disk

struct DiskInfo: Equatable {
    let totalBytes: Int64
    let freeBytes: Int64
    let usedBytes: Int64

    var usedPercentage: Double {
        guard totalBytes > 0 else { return 0 }
        return min(max(Double(usedBytes) / Double(totalBytes), 0), 1)
    }

    var formattedTotal: String { ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file) }
    var formattedFree: String  { ByteCountFormatter.string(fromByteCount: freeBytes,  countStyle: .file) }
    var formattedUsed: String  { ByteCountFormatter.string(fromByteCount: usedBytes,  countStyle: .file) }

    static func getCurrent(path: String = "/") -> DiskInfo {
        // Metodo robusto e compatibile: File System attributes
        let attrs = (try? FileManager.default.attributesOfFileSystem(forPath: path)) ?? [:]

        let total = (attrs[.systemSize] as? NSNumber)?.int64Value ?? 0
        let free  = (attrs[.systemFreeSize] as? NSNumber)?.int64Value ?? 0
        let used  = max(total - free, 0)

        return DiskInfo(totalBytes: total, freeBytes: free, usedBytes: used)
    }
}

// MARK: - Memory

struct MemoryInfo: Equatable {
    let totalBytes: Int64
    let usedBytes: Int64
    let freeBytes: Int64

    var usedPercentage: Double {
        guard totalBytes > 0 else { return 0 }
        return min(max(Double(usedBytes) / Double(totalBytes), 0), 1)
    }

    var formattedTotal: String { ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .memory) }
    var formattedUsed: String  { ByteCountFormatter.string(fromByteCount: usedBytes,  countStyle: .memory) }
    var formattedFree: String  { ByteCountFormatter.string(fromByteCount: freeBytes,  countStyle: .memory) }

    static func getCurrent() -> MemoryInfo {
        let total = Int64(ProcessInfo.processInfo.physicalMemory)

        // Placeholder semplice (stabile): finché non implementiamo RAM pressure reale
        let used = Int64(Double(total) * 0.65)
        let free = max(total - used, 0)

        return MemoryInfo(totalBytes: total, usedBytes: used, freeBytes: free)
    }
}

