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
    let imageURL: String? // ✅ AÑADIDO: URL de imagen para caché

    // Para sync incremental (campo updatedAt en Firestore)
    let updatedAt: Date?

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
        case imageURL
        case updatedAt
    }

    // Inicializador para tests y uso programático
    init(
        id: String? = nil,
        name: String,
        brand: String,
        key: String,
        gender: String,
        family: String,
        subfamilies: [String]? = nil,
        price: String? = nil,
        popularity: Double? = nil,
        year: Int? = nil,
        imageURL: String? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.key = key
        self.gender = gender
        self.family = family
        self.subfamilies = subfamilies
        self.price = price
        self.popularity = popularity
        self.year = year
        self.imageURL = imageURL
        self.updatedAt = updatedAt
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
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)

        // updatedAt puede venir como Timestamp de Firebase
        if let timestamp = try? container.decode(Timestamp.self, forKey: .updatedAt) {
            updatedAt = timestamp.dateValue()
        } else {
            updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        }
    }
}
