import Foundation
import FirebaseFirestore

/// Metadata ligero de perfumes para index rápido
/// Solo contiene campos necesarios para búsqueda/filtrado
struct PerfumeMetadata: Codable, Identifiable {
    var id: String?

    let name: String
    let brand: String
    let key: String
    let gender: String
    let family: String
    let subfamilies: [String]?
    let price: String?
    let popularity: Double?
    let year: Int?

    // Para sync incremental
    let syncedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case brand
        case key
        case gender
        case family
        case subfamilies
        case price
        case popularity
        case year
        case syncedAt
    }

    // Custom decoder para manejar campos opcionales
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        brand = try container.decode(String.self, forKey: .brand)
        key = try container.decode(String.self, forKey: .key)
        gender = try container.decode(String.self, forKey: .gender)
        family = try container.decode(String.self, forKey: .family)
        subfamilies = try container.decodeIfPresent([String].self, forKey: .subfamilies)
        price = try container.decodeIfPresent(String.self, forKey: .price)
        popularity = try container.decodeIfPresent(Double.self, forKey: .popularity)
        year = try container.decodeIfPresent(Int.self, forKey: .year)

        // syncedAt puede venir como Timestamp de Firebase
        if let timestamp = try? container.decode(Timestamp.self, forKey: .syncedAt) {
            syncedAt = timestamp.dateValue()
        } else {
            syncedAt = try container.decodeIfPresent(Date.self, forKey: .syncedAt)
        }
    }
}
