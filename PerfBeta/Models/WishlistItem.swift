import Foundation

struct WishlistItem: Identifiable, Codable, Equatable, Hashable {
    var id: String?
    let perfumeKey: String
    let brandKey: String
    var imageURL: String?
    var rating: Double
    var orderIndex: Int
    
    // Codable conformance using CodingKeys
    enum CodingKeys: String, CodingKey {
        case id
        case perfumeKey
        case brandKey
        case imageURL
        case rating
        case orderIndex
    }

    static func == (lhs: WishlistItem, rhs: WishlistItem) -> Bool {
        return lhs.perfumeKey == rhs.perfumeKey && lhs.brandKey == rhs.brandKey
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(perfumeKey)
        hasher.combine(brandKey)
    }
}
