import Foundation

struct ScreenshotDemoData: Decodable {
    struct AppStats: Decodable {
        let totalCleaned: Int64
        let lastScanDate: String
        let lastCleanDate: String
        let systemHealthScore: Int
    }

    struct JunkCategory: Decodable {
        let key: String
        let name: String
        let description: String
        let size: Int64
        let isSelected: Bool
        let items: [JunkItem]
    }

    struct JunkItem: Decodable {
        let name: String
        let path: String
        let size: Int64
        let isSelected: Bool
        let isRecommended: Bool
    }

    struct ActionList: Decodable {
        let items: [ActionListItem]
        let logs: [ActionLogEntry]
    }

    struct ActionListItem: Decodable {
        let title: String
        let path: String
        let size: Int64
        let source: String
    }

    struct ActionLogEntry: Decodable {
        let date: String
        let items: [ActionListItem]
    }

    let appStats: AppStats
    let junkCategories: [JunkCategory]
    let actionList: ActionList

    static func load() -> ScreenshotDemoData? {
        guard let url = Bundle.main.url(forResource: "ScreenshotDemo", withExtension: "json") else { return nil }
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(ScreenshotDemoData.self, from: data)
    }

    func parsedDate(_ string: String) -> Date? {
        return Self.dateFormatter.date(from: string)
    }

    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
