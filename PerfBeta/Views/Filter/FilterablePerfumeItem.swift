import Foundation

// Protocolo que define las propiedades necesarias para filtrar y ordenar
protocol FilterablePerfumeItem: Identifiable {
    var id: String { get }
    var perfume: Perfume { get } // Necesitamos acceso al objeto Perfume subyacente
    var personalRating: Double? { get } // Rating específico del usuario (puede ser nil)
    // Añade cualquier otra propiedad necesaria para ordenar/filtrar que NO esté en Perfume
    // var dateAdded: Date? { get } // Ejemplo
}

// --- Conformidad para tus tipos existentes ---

extension TriedPerfumeDisplayItem: FilterablePerfumeItem {
    // 'id' y 'perfume' ya existen.
    var personalRating: Double? { record.rating }
}

extension WishlistItemDisplayData: FilterablePerfumeItem {
    // 'id' y 'perfume' ya existen.
    var personalRating: Double? { nil } // Wishlist no tiene rating personal directo en este modelo
    // Si WishlistItem tuviera una fecha, la añadirías aquí.
}

// Para ExploreTabView, podemos hacer que Perfume conforme directamente
// o crear un wrapper si necesitamos añadir propiedades extra.
// Opción A: Conformidad directa (si no necesitas más propiedades)
extension Perfume: FilterablePerfumeItem {
     var id: String { key } // Asume que 'key' es el identificador único
     var perfume: Perfume { self }
     var personalRating: Double? { nil }
}

// Opción B: Wrapper (si necesitas añadir algo más para filtrar/ordenar en Explore)
// struct ExplorePerfumeDisplayItem: FilterablePerfumeItem {
//     let id: String
//     let perfume: Perfume
//     var personalRating: Double? { nil }
//     // otras propiedades...
//
//     init(perfume: Perfume) {
//         self.id = perfume.key
//         self.perfume = perfume
//     }
// }