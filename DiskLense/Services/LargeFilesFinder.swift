import Foundation
import SwiftUI

@MainActor
final class LargeFilesFinder: ObservableObject {
    @Published var files: [LargeFile] = []
    @Published var progress: Double = 0
    @Published var isLoading: Bool = false

    /// Minimum file size to report (default 100 MB)
    var thresholdBytes: Int64 = 100_000_000

    func formatted(_ size: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    // MARK: - Real Scan

    func scan() async {
        isLoading = true
        progress = 0
        files = []

        let home = FileManager.default.homeDirectoryForCurrentUser
        let threshold = thresholdBytes

        // Scan common user directories (avoids system dirs that need permissions)
        let scanRoots: [URL] = [
            home.appendingPathComponent("Downloads"),
            home.appendingPathComponent("Documents"),
            home.appendingPathComponent("Desktop"),
            home.appendingPathComponent("Movies"),
            home.appendingPathComponent("Music"),
            home.appendingPathComponent("Pictures"),
            home.appendingPathComponent("Library"),
            home.appendingPathComponent("Developer")
        ]

        let totalRoots = scanRoots.count
        var found: [LargeFile] = []

        for (idx, root) in scanRoots.enumerated() {
            progress = Double(idx) / Double(totalRoots)

            let result = await Task.detached(priority: .utility) {
                Self.findLargeFiles(in: root, threshold: threshold)
            }.value

            found.append(contentsOf: result)

            // Progressive update: show files as we find them
            files = found.sorted { $0.size > $1.size }

            try? await Task.sleep(nanoseconds: 30_000_000)
        }

        files = found.sorted { $0.size > $1.size }
        isLoading = false
        progress = 0
    }

    // MARK: - Delete (move to Trash)

    func delete(file: LargeFile) async {
        await delete(filesWithIDs: [file.id])
    }

    func delete(filesWithIDs ids: Set<UUID>) async {
        for id in ids {
            guard let file = files.first(where: { $0.id == id }) else { continue }
            do {
                try FileManager.default.trashItem(at: file.url, resultingItemURL: nil)
            } catch {
                print("Failed to trash \(file.url.path): \(error.localizedDescription)")
            }
        }
        files.removeAll { ids.contains($0.id) }
    }

    // MARK: - Background scan (off main thread)

    nonisolated private static func findLargeFiles(in root: URL, threshold: Int64) -> [LargeFile] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: root.path) else { return [] }

        var results: [LargeFile] = []

        guard let enumerator = fm.enumerator(
            at: root,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants],
            errorHandler: { _, _ in true }
        ) else { return [] }

        for case let fileURL as URL in enumerator {
            do {
                let values = try fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
                if values.isRegularFile == true,
                   let size = values.fileSize,
                   Int64(size) >= threshold {
                    results.append(LargeFile(url: fileURL, size: Int64(size)))
                }
            } catch {
                continue
            }
        }
        return results
    }
}
