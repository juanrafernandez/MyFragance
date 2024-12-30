import Foundation

struct Option: Codable, Identifiable {
    let id = UUID() // Genera un ID único automáticamente
    let label: String
    let value: String
    let description: String
    let imageAsset: String
    let familiasAsociadas: [String: Int]?
    let nivelDetalle: Int? // Nuevo campo opcional para nivel de detalle

    enum CodingKeys: String, CodingKey {
        case label
        case value
        case description
        case imageAsset = "image_asset" // Mapear desde el JSON
        case familiasAsociadas
        case nivelDetalle = "nivel_detalle" // Mapear nivelDetalle correctamente
    }

    // Propiedad calculada para obtener la familia complementaria
    var complementaryValue: String? {
        guard let familias = familiasAsociadas else { return nil }
        return familias.max { $0.value < $1.value }?.key
    }
}
