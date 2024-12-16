import Foundation

struct Option: Codable, Identifiable {
    let id = UUID() // Genera un ID único automáticamente
    let label: String
    let value: String
    let description: String
    let imageAsset: String
    let familiasAsociadas: [String: Int]

    enum CodingKeys: String, CodingKey {
        case label
        case value
        case description
        case imageAsset = "image_asset" // Mapear desde el JSON
        case familiasAsociadas
    }
}
