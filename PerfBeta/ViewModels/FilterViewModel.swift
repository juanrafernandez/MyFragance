import SwiftUI
import Combine
import Sliders // Asegúrate de importar Sliders aquí también

// Define los tipos de ordenación disponibles de forma más genérica
// Puedes adaptarlo si las opciones son muy diferentes entre pantallas
enum PerfumeSortOrder: Identifiable {
    case none, // Relevancia o por defecto
         manual, // Específico de Wishlist
         ratingAscending, ratingDescending, // Rating Personal
         popularityAscending, popularityDescending, // Popularidad Perfume
         nameAscending, nameDescending // Nombre Perfume

    var id: Self { self }

    // Podrías añadir una propiedad para obtener el texto descriptivo
    var displayName: String {
        switch self {
        case .none: return "Relevancia"
        case .manual: return "Orden Manual"
        case .ratingAscending: return "Rating Personal (Menor a Mayor)"
        case .ratingDescending: return "Rating Personal (Mayor a Menor)"
        case .popularityAscending: return "Popularidad (Menor a Mayor)"
        case .popularityDescending: return "Popularidad (Mayor a Menor)"
        case .nameAscending: return "Nombre (A - Z)"
        case .nameDescending: return "Nombre (Z - A)"
        }
    }
}

@MainActor
class FilterViewModel<Item: FilterablePerfumeItem>: ObservableObject {
    // --- Configuración ---
    struct Configuration {
        let availableSortOrders: [PerfumeSortOrder]
        let initialSortOrder: PerfumeSortOrder
        let showPersonalRatingFilter: Bool
        let allowManualSort: Bool // Para Wishlist

        // Valores por defecto o inicializadores convenientes
        static func triedPerfumes() -> Configuration {
            Configuration(
                availableSortOrders: [.ratingDescending, .ratingAscending, .nameAscending, .nameDescending],
                initialSortOrder: .ratingDescending,
                showPersonalRatingFilter: true,
                allowManualSort: false
            )
        }
        static func wishlist() -> Configuration {
            Configuration(
                availableSortOrders: [.manual, .popularityDescending, .popularityAscending, .nameAscending, .nameDescending],
                initialSortOrder: .manual,
                showPersonalRatingFilter: false,
                allowManualSort: true
            )
        }
        static func explore() -> Configuration {
            Configuration(
                availableSortOrders: [.none, .popularityDescending, .popularityAscending, .nameAscending, .nameDescending],
                initialSortOrder: .none,
                showPersonalRatingFilter: false,
                allowManualSort: false
            )
        }
    }

    let configuration: Configuration

    // --- Estado Publicado para la UI ---
    @Published var searchText = ""
    @Published var isFilterExpanded = false // O el valor inicial que prefieras
    @Published var selectedFilters: [String: [String]] = [:] // Categoría -> [Opciones seleccionadas]

    // Estados de expansión de acordeones
    @Published var genreExpanded: Bool = false
    @Published var familyExpanded: Bool = false
    @Published var seasonExpanded: Bool = false
    @Published var projectionExpanded: Bool = false
    @Published var durationExpanded: Bool = false
    @Published var priceExpanded: Bool = false
    @Published var personalRatingExpanded: Bool = false // Nuevo para rating
    @Published var perfumePopularityExpanded: Bool = false

    // Rangos de Sliders
    @Published var ratingRange: ClosedRange<Double> = 0...10
    let ratingSliderRange: ClosedRange<Double> = 0...10

    @Published var perfumePopularityRange: ClosedRange<Double> = 0...10
    let perfumePopularitySliderRange: ClosedRange<Double> = 0...10

    // Ordenación
    @Published var sortOrder: PerfumeSortOrder

    // --- Dependencias (inyectadas) ---
    // Necesarios para obtener nombres/opciones de filtros
    private let familyViewModel: FamilyViewModel
    // BrandViewModel podría ser necesario si se busca por marca aquí,
    // pero parece que la búsqueda actual es por texto en nombre de perfume/marca
    // private let brandViewModel: BrandViewModel

    // --- Resultados Filtrados ---
    // La vista padre observará los cambios en los filtros y llamará a `applyFilters`
    // No almacenamos los resultados aquí, solo la lógica para producirlos.

    // --- Inicializador ---
    init(configuration: Configuration, familyViewModel: FamilyViewModel) {
        self.configuration = configuration
        self.sortOrder = configuration.initialSortOrder
        self.familyViewModel = familyViewModel
        // Inicializar rangos a los valores por defecto/completos
        self.ratingRange = ratingSliderRange
        self.perfumePopularityRange = perfumePopularitySliderRange
    }

    // --- Lógica de Filtros ---

    var hasActiveFilters: Bool {
        !searchText.isEmpty ||
        !selectedFilters.isEmpty ||
        (configuration.showPersonalRatingFilter && ratingRange != ratingSliderRange) ||
        perfumePopularityRange != perfumePopularitySliderRange
    }

    func toggleFilter(category: String, optionKey: String) {
        // Mapear display name a key si es necesario (ej. Familia)
        // Esta lógica podría necesitar ajustes dependiendo de cómo obtienes las opciones
        let keyToToggle = optionKey // Asume que optionKey es la clave correcta para el filtro

        if selectedFilters[category]?.contains(keyToToggle) == true {
            selectedFilters[category]?.removeAll { $0 == keyToToggle }
            if selectedFilters[category]?.isEmpty == true {
                selectedFilters.removeValue(forKey: category)
            }
        } else {
            selectedFilters[category, default: []].append(keyToToggle)
        }
        // La vista reaccionará a @Published y volverá a filtrar
    }

    func isSelected(category: String, optionKey: String) -> Bool {
         // Mapear display name a key si es necesario
         let keyToCheck = optionKey
         return selectedFilters[category]?.contains(keyToCheck) == true
    }

    func clearFilters() {
        searchText = ""
        selectedFilters.removeAll()
        genreExpanded = false; familyExpanded = false; seasonExpanded = false;
        projectionExpanded = false; durationExpanded = false; priceExpanded = false;
        personalRatingExpanded = false; perfumePopularityExpanded = false;
        ratingRange = ratingSliderRange
        perfumePopularityRange = perfumePopularitySliderRange
        sortOrder = configuration.initialSortOrder
        // La vista reaccionará a @Published y volverá a filtrar
    }

    // --- Lógica de Aplicación de Filtros y Ordenación ---

    func applyFiltersAndSort(items: [Item], brandViewModel: BrandViewModel) -> [Item] {
        var workingList = items
        let currentSortOrder = self.sortOrder // Captura el valor actual

        // 1. Filtrado por Texto
        if !searchText.isEmpty {
            let lowercasedSearch = searchText.lowercased()
            workingList = workingList.filter { item in
                item.perfume.name.lowercased().contains(lowercasedSearch) ||
                (brandViewModel.getBrand(byKey: item.perfume.brand)?.name ?? item.perfume.brand).lowercased().contains(lowercasedSearch)
            }
        }

        // 2. Filtrado por Rating Personal (si aplica)
        if configuration.showPersonalRatingFilter {
            workingList = workingList.filter { item in
                let rating = item.personalRating ?? 0 // Usa el rating del protocolo
                return rating >= ratingRange.lowerBound && rating <= ratingRange.upperBound
            }
        }

        // 3. Filtrado por Popularidad del Perfume
        workingList = workingList.filter { item in
            let popularityScore = (item.perfume.popularity ?? 0.0) / 10.0 // Asume escala 0-100 -> 0-10
            return popularityScore >= perfumePopularityRange.lowerBound && popularityScore <= perfumePopularityRange.upperBound
        }

        // 4. Filtrado por Categorías (selectedFilters)
        if !selectedFilters.isEmpty {
            workingList = workingList.filter { item in
                let perfume = item.perfume // Accede al perfume a través del protocolo

                // Adaptar claves usadas en selectedFilters a las propiedades del perfume
                // ¡IMPORTANTE!: Asegúrate que las claves en `selectedFilters` coincidan con lo esperado
                // (e.g., rawValue para enums, keys para familias)

                let matchesGender = selectedFilters["Género"]?.isEmpty ?? true ||
                                    selectedFilters["Género"]!.contains(perfume.gender) // Asume que "Género" usa rawValue

                let matchesFamily = selectedFilters["Familia Olfativa"]?.isEmpty ?? true ||
                                    selectedFilters["Familia Olfativa"]!.contains(perfume.family) // Asume que "Familia Olfativa" usa la key

                let matchesSeason = selectedFilters["Temporada Recomendada"]?.isEmpty ?? true ||
                                    !Set(selectedFilters["Temporada Recomendada"]!) // Asume rawValues
                                        .intersection(Set(perfume.recommendedSeason.compactMap { Season(rawValue: $0)?.rawValue }))
                                        .isEmpty

                let matchesProjection = selectedFilters["Proyección"]?.isEmpty ?? true ||
                                        selectedFilters["Proyección"]!.contains(perfume.projection) // Asume rawValue

                let matchesDuration = selectedFilters["Duración"]?.isEmpty ?? true ||
                                      selectedFilters["Duración"]!.contains(perfume.duration) // Asume rawValue

                let matchesPrice = selectedFilters["Precio"]?.isEmpty ?? true ||
                                   selectedFilters["Precio"]!.contains(perfume.price ?? "") // Asume rawValue

                return matchesGender && matchesFamily && matchesSeason && matchesProjection && matchesDuration && matchesPrice
            }
        }

        // 5. Ordenación (si no es manual)
        if currentSortOrder != .manual || !configuration.allowManualSort {
            workingList = sortItems(items: workingList, sortOrder: currentSortOrder)
        }
        // Si es .manual y allowManualSort es true, la lista ya debería estar en el orden correcto
        // (el orden original de 'items' que pasó la vista padre) antes del filtrado.
        // El filtrado mantiene el orden relativo.

        return workingList
    }

    private func sortItems(items: [Item], sortOrder: PerfumeSortOrder) -> [Item] {
        switch sortOrder {
        case .ratingAscending:
            return items.sorted { ($0.personalRating ?? 0) < ($1.personalRating ?? 0) }
        case .ratingDescending:
            return items.sorted { ($0.personalRating ?? 0) > ($1.personalRating ?? 0) }
        case .popularityAscending:
            return items.sorted { ($0.perfume.popularity ?? 0.0) < ($1.perfume.popularity ?? 0.0) }
        case .popularityDescending:
            return items.sorted { ($0.perfume.popularity ?? 0.0) > ($1.perfume.popularity ?? 0.0) }
        case .nameAscending:
            return items.sorted { $0.perfume.name.localizedCaseInsensitiveCompare($1.perfume.name) == .orderedAscending }
        case .nameDescending:
            return items.sorted { $0.perfume.name.localizedCaseInsensitiveCompare($1.perfume.name) == .orderedDescending }
        case .none, .manual:
            return items // Sin ordenación o se mantiene el orden manual/original
        }
    }

    // --- Funciones para obtener opciones de filtros (usadas por PerfumeFilterView) ---
     // Necesitamos pasar FamilyViewModel a PerfumeFilterView o exponer estas opciones desde aquí.
     // Exponerlas desde aquí es más limpio.

     var genderOptions: [FilterKeyPair] {
         Gender.allCases.map { FilterKeyPair(id: $0.rawValue, key: $0.rawValue, name: $0.displayName) }
     }

     var familyOptions: [FilterKeyPair] {
         familyViewModel.familias.map { FilterKeyPair(id: $0.key, key: $0.key, name: $0.name) }.sorted { $0.name < $1.name }
     }

     var seasonOptions: [FilterKeyPair] {
         Season.allCases.map { FilterKeyPair(id: $0.rawValue, key: $0.rawValue, name: $0.displayName) }
     }

     var projectionOptions: [FilterKeyPair] {
         Projection.allCases.map { FilterKeyPair(id: $0.rawValue, key: $0.rawValue, name: $0.displayName) }
     }

     var durationOptions: [FilterKeyPair] {
         Duration.allCases.map { FilterKeyPair(id: $0.rawValue, key: $0.rawValue, name: $0.displayName) }
     }

     var priceOptions: [FilterKeyPair] {
         Price.allCases.map { FilterKeyPair(id: $0.rawValue, key: $0.rawValue, name: $0.displayName) }
     }
}

// Helper struct para las opciones de filtro
struct FilterKeyPair: Identifiable, Hashable {
    let id: String
    let key: String // La clave usada para filtrar (e.g., rawValue, familyKey)
    let name: String // El texto a mostrar en el botón
}
