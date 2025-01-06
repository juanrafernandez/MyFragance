import Foundation

enum Gender: String {
    case masculino = "MASCULINO"
    case femenino = "FEMENINO"
    case unisex = "UNISEX"

    static let allValues = [masculino, femenino, unisex]

    // Opcional: Agregar propiedades adicionales
    var description: String {
        switch self {
        case .masculino: return "Perfume masculino"
        case .femenino: return "Perfume femenino"
        case .unisex: return "Perfume unisex"
        }
    }
}
