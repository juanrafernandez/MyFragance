import SwiftUI
import Combine

class FavoritesManager: ObservableObject {
    @Published var favoritePerfumes: [Perfume] = [] // Lista de perfumes favoritos

    // Función para agregar un perfume a favoritos
    func addToFavorites(_ perfume: Perfume) {
        if !favoritePerfumes.contains(where: { $0.id == perfume.id }) {
            favoritePerfumes.append(perfume)
        }
    }

    // Función para eliminar un perfume de favoritos
    func removeFromFavorites(_ perfume: Perfume) {
        favoritePerfumes.removeAll(where: { $0.id == perfume.id })
    }

    // Función para verificar si un perfume ya está en favoritos
    func isFavorite(_ perfume: Perfume) -> Bool {
        favoritePerfumes.contains(where: { $0.id == perfume.id })
    }
}
