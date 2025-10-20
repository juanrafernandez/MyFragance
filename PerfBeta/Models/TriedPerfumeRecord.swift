import Foundation

struct TriedPerfumeRecord: Codable, Identifiable, Equatable {
    var id: String?
    let userId: String
    let perfumeId: String
    let perfumeKey: String
    let brandId: String
    var projection: String
    var duration: String
    var price: String
    var rating: Double?
    var impressions: String?
    var occasions: [String]?
    var seasons: [String]?
    var personalities: [String]?
    var createdAt: Date?
    var updatedAt: Date?
    
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
