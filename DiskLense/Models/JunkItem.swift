import Foundation

// Unico punto in cui esiste JunkItem (niente duplicati altrove)
struct JunkItem: Identifiable, Hashable {
    let id: UUID
    let name: String
    let path: String
    let size: Int64
    var isSelected: Bool
    let isRecommended: Bool

    init(
        id: UUID = UUID(),
        name: String,
        path: String,
        size: Int64,
        isSelected: Bool = false,
        isRecommended: Bool = false
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.size = size
        self.isSelected = isSelected
        self.isRecommended = isRecommended
    }
}

