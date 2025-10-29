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

struct TriedPerfumeDisplayItem: Identifiable, FilterablePerfumeItem { // <<<----- AÑADE FilterablePerfumeItem AQUÍ
    let id: String
    let record: TriedPerfume  // ✅ REFACTOR: Nuevo modelo
    let perfume: Perfume

    // La propiedad computada para cumplir el protocolo va DENTRO de la struct
    var personalRating: Double? {
        return record.rating
    }

    // El resto de tu struct si tiene más cosas...
}

struct WishlistItemDisplayData: Identifiable, FilterablePerfumeItem { // Añade conformidad
    let id: String
    let wishlistItem: WishlistItem
    let perfume: Perfume

    // Conformidad con FilterablePerfumeItem
    // id y perfume ya existen y cumplen.
    var personalRating: Double? {
        // Wishlist no tiene un rating personal directo en este modelo.
        // Si WishlistItem tuviera un campo de "interés" o similar, podrías mapearlo aquí.
        return nil
    }
}

// Para ExploreTabView, podemos hacer que Perfume conforme directamente
// o crear un wrapper si necesitamos añadir propiedades extra.
// Opción A: Conformidad directa (si no necesitas más propiedades)
extension Perfume: FilterablePerfumeItem {
     //var id: String { key } // Asume que 'key' es el identificador único
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
