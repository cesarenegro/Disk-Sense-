import Foundation

@MainActor
class CacheCleaner: ObservableObject {
    @Published var cleanedSize: Int64 = 0
    @Published var isCleaning = false
    
    func cleanSystemCache() async -> Int64 {
        isCleaning = true
        #if RELEASE_SCREENSHOT
        let cleaned: Int64 = 1_250_000_000
        cleanedSize += cleaned
        isCleaning = false
        return cleaned
        #else
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        let cleaned = Int64.random(in: 500_000_000...2_000_000_000)
        cleanedSize += cleaned
        isCleaning = false
        return cleaned
        #endif
    }
    
    func cleanUserCache() async -> Int64 {
        isCleaning = true
        #if RELEASE_SCREENSHOT
        let cleaned: Int64 = 620_000_000
        cleanedSize += cleaned
        isCleaning = false
        return cleaned
        #else
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        let cleaned = Int64.random(in: 200_000_000...1_000_000_000)
        cleanedSize += cleaned
        isCleaning = false
        return cleaned
        #endif
    }
}
