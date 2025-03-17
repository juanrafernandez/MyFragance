import Foundation

struct WishlistItem: Identifiable, Codable, Equatable, Hashable {
    var id: String? // Optional ID, consistent with TriedPerfumeRecord
    let perfumeKey: String
    let brandKey: String
    var imageURL: String? // Added imageURL, made optional
    var rating: Double // Added popularity

    // Codable conformance using CodingKeys
    enum CodingKeys: String, CodingKey {
        case id
        case perfumeKey
        case brandKey
        case imageURL
        case rating
    }

    static func == (lhs: WishlistItem, rhs: WishlistItem) -> Bool {
        return lhs.perfumeKey == rhs.perfumeKey && lhs.brandKey == rhs.brandKey
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(perfumeKey)
        hasher.combine(brandKey)
    }
}
