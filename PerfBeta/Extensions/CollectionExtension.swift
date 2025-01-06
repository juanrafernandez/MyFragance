import Foundation

// Extensión para evitar índices fuera de rango
extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
