import Foundation

struct TriedPerfumeRecord: Codable, Identifiable, Equatable {
    var id: String?
    let userId: String
    let perfumeId: String
    let perfumeKey: String
    let brandId: String
    let projection: String
    let duration: String
    let price: String
    let rating: Double?
    let impressions: String?
    let occasions: [String]?
    let seasons: [String]?
    let personalities: [String]?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case perfumeId
        case perfumeKey
        case brandId
        case projection
        case duration
        case price
        case rating
        case impressions
        case occasions
        case seasons
        case personalities
        case createdAt
        case updatedAt
    }
}
