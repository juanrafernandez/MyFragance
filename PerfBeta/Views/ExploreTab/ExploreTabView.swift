import SwiftUI
import Sliders

/// Vista principal de Exploración de perfumes
/// Refactorizada para usar componentes modulares (Search, Filter, Results)
struct ExploreTabView: View {
    // MARK: - State
    @State private var searchText = ""
    @State private var isFilterExpanded = true
    @State private var selectedFilters: [String: [String]] = [:]
    @State private var perfumes: [Perfume] = []
    @State private var selectedPerfume: Perfume? = nil
    @State private var selectedBrandForPerfume: Brand? = nil

    // State para expansión de filtros
    @State private var genreExpanded: Bool = false
    @State private var familyExpanded: Bool = false
    @State private var seasonExpanded: Bool = false
    @State private var projectionExpanded: Bool = false
    @State private var durationExpanded: Bool = false
    @State private var priceExpanded: Bool = false
    @State private var popularityExpanded: Bool = false

    // State para popularidad
    @State private var popularityRange: ClosedRange<Double> = 0...10
    let range: ClosedRange<Double> = 0...10

    // Sorting
    @State private var sortOrder: SortOrder = .none

    // MARK: - Environment Objects
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var familyViewModel: FamilyViewModel
    @EnvironmentObject var brandViewModel: BrandViewModel

    // MARK: - Computed Properties
    /// Mapeo de displayName a key para familias
    private var familyNameToKey: [String: String] {
        Dictionary(uniqueKeysWithValues: familyViewModel.familias.map { ($0.name, $0.key) })
    }

    /// Verifica si hay filtros activos
    private var hasActiveFilters: Bool {
        !searchText.isEmpty || !selectedFilters.isEmpty || popularityRange != 0...10
    }

    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background
                GradientView(preset: .champan)
                    .edgesIgnoringSafeArea(.all)

                // Main content
                VStack(spacing: 0) {
                    headerView

                    ScrollView {
                        VStack {
                            // ✅ Search Section (componente)
                            ExploreTabSearchSection(
                                searchText: $searchText,
                                isFilterExpanded: $isFilterExpanded,
                                hasActiveFilters: hasActiveFilters,
                                onClearFilters: clearFilters,
                                onSearchCommit: filterResults
                            )

                            // ✅ Filter Section (componente)
                            if isFilterExpanded {
                                ExploreTabFilterSection(
                                    selectedFilters: $selectedFilters,
                                    genreExpanded: $genreExpanded,
                                    familyExpanded: $familyExpanded,
                                    seasonExpanded: $seasonExpanded,
                                    projectionExpanded: $projectionExpanded,
                                    durationExpanded: $durationExpanded,
                                    priceExpanded: $priceExpanded,
                                    popularityExpanded: $popularityExpanded,
                                    popularityRange: $popularityRange,
                                    onFilterChange: filterResults
                                )
                            }

                            // ✅ Results Section (componente)
                            ExploreTabResultsSection(
                                perfumes: sortPerfumes(perfumes: perfumes, sortOrder: sortOrder),
                                isLoading: perfumeViewModel.isLoading,
                                hasActiveFilters: hasActiveFilters,
                                onClearFilters: clearFilters,
                                onPerfumeSelect: { perfume in
                                    selectedPerfume = perfume
                                }
                            )
                        }
                        .padding(.horizontal, 25)
                        .padding(.bottom, 70)
                    }
                    .refreshable {
                        await perfumeViewModel.loadMetadataIndex()
                        filterResults()
                    }
                }

                // Tab bar spacer (invisible text)
                HStack {
                    Spacer()
                    Text("Explorar")
                        .font(.system(size: 16, weight: .bold))
                        .padding(.bottom)
                        .foregroundColor(.clear)
                    Spacer()
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
                .allowsHitTesting(false)
            }
            .navigationBarHidden(true)
            .task {
                // Load families (necesarias para mostrar filtros)
                await familyViewModel.loadInitialData()

                // ✅ NO cargar perfumes hasta que el usuario busque o filtre
                if hasActiveSearchOrFilters() {
                    if perfumeViewModel.perfumes.isEmpty {
                        #if DEBUG
                        print("🔍 [ExploreTab] Loading perfumes for active search/filters...")
                        #endif
                        await perfumeViewModel.loadInitialData()
                    }
                    filterResults()
                } else {
                    #if DEBUG
                    print("🔍 [ExploreTab] No active search/filters - showing empty state")
                    #endif
                }
            }
            .fullScreenCover(item: $selectedPerfume) { perfume in
                PerfumeDetailView(
                    perfume: perfume,
                    brand: selectedBrandForPerfume,
                    profile: nil
                )
            }
            .onChange(of: selectedPerfume) {
                if let perfume = selectedPerfume {
                    selectedBrandForPerfume = brandViewModel.getBrand(byKey: perfume.brand)
                } else {
                    selectedBrandForPerfume = nil
                }
            }
            .onChange(of: searchText) {
                filterResults()
            }
        }
    }

    // MARK: - Header View
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Encuentra tu Perfume".uppercased())
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(Color("textoPrincipal"))
            }
            Spacer()

            // Sorting Menu
            Menu {
                Picker("Ordenar por", selection: $sortOrder) {
                    Text("Relevancia").tag(SortOrder.none)
                    Divider()
                    Text("Popularidad (Mayor a Menor)").tag(SortOrder.popularityDescending)
                    Text("Popularidad (Menor a Mayor)").tag(SortOrder.popularityAscending)
                    Divider()
                    Text("Nombre (A - Z)").tag(SortOrder.nameAscending)
                    Text("Nombre (Z - A)").tag(SortOrder.nameDescending)
                }
            } label: {
                Image(systemName: "arrow.up.arrow.down.circle.fill")
                    .foregroundColor(Color("textoPrincipal"))
                    .font(.title2)
            }
        }
        .padding(.horizontal, 25)
        .padding(.top, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.clear)
    }

    // MARK: - Clear Filters
    private func clearFilters() {
        searchText = ""
        selectedFilters.removeAll()
        genreExpanded = true
        familyExpanded = false
        seasonExpanded = false
        projectionExpanded = false
        durationExpanded = false
        priceExpanded = false
        popularityExpanded = false
        popularityRange = 0.0...10.0
        sortOrder = .none
        filterResults()
    }

    // MARK: - Helper Functions
    private func hasActiveSearchOrFilters() -> Bool {
        return !searchText.isEmpty ||
               !selectedFilters.isEmpty ||
               popularityRange != 0...10
    }

    // MARK: - Filter Results
    private func filterResults() {
        // ✅ No filtrar si no hay búsqueda ni filtros activos
        guard hasActiveSearchOrFilters() else {
            #if DEBUG
            print("🔍 [ExploreTab] No active search/filters - clearing results")
            #endif
            perfumes = []
            return
        }

        // ✅ Cargar perfumes si aún no están cargados
        if perfumeViewModel.perfumes.isEmpty {
            #if DEBUG
            print("🔍 [ExploreTab] Perfumes not loaded yet, loading now...")
            #endif
            Task {
                await perfumeViewModel.loadInitialData()
                filterResults()
            }
            return
        }

        #if DEBUG
        print("\n🔍 [ExploreTab] Filtrando \(perfumeViewModel.perfumes.count) perfumes")
        print("   - SearchText: '\(searchText)'")
        print("   - Género: \(selectedFilters["Género"] ?? [])")
        print("   - Familias: \(selectedFilters["Familia Olfativa"] ?? [])")
        print("   - Popularidad: \(popularityRange)")
        #endif

        let filteredPerfumes = perfumeViewModel.perfumes.filter { perfume in
            // 1. BÚSQUEDA POR TEXTO (case-insensitive, diacritics-insensitive)
            let matchesSearchText: Bool = {
                if searchText.isEmpty { return true }

                let searchLower = searchText.lowercased()
                    .folding(options: .diacriticInsensitive, locale: .current)

                // Buscar en nombre, brand, family, subfamilies
                let nameMatch = perfume.name.lowercased()
                    .folding(options: .diacriticInsensitive, locale: .current)
                    .contains(searchLower)

                let brandKeyMatch = perfume.brand.lowercased()
                    .folding(options: .diacriticInsensitive, locale: .current)
                    .contains(searchLower)

                let brandNameMatch = brandViewModel.getBrand(byKey: perfume.brand)?.name.lowercased()
                    .folding(options: .diacriticInsensitive, locale: .current)
                    .contains(searchLower) ?? false

                let familyMatch = perfume.family.lowercased()
                    .folding(options: .diacriticInsensitive, locale: .current)
                    .contains(searchLower)

                let subfamilyMatch = perfume.subfamilies.contains { subfamily in
                    subfamily.lowercased()
                        .folding(options: .diacriticInsensitive, locale: .current)
                        .contains(searchLower)
                }

                return nameMatch || brandKeyMatch || brandNameMatch || familyMatch || subfamilyMatch
            }()

            // 2. GÉNERO (case-insensitive)
            let matchesGender = selectedFilters["Género"].map { selectedGenders in
                guard !selectedGenders.isEmpty else { return true }
                let selectedRawGenders = selectedGenders.compactMap { Gender.rawValue(forDisplayName: $0)?.lowercased() }
                return selectedRawGenders.contains(perfume.gender.lowercased())
            } ?? true

            // 3. FAMILIAS OLFATIVAS (OR - case-insensitive)
            let matchesFamily = selectedFilters["Familia Olfativa"].map { selectedFamilies in
                guard !selectedFamilies.isEmpty else { return true }

                let perfumeFamilies = ([perfume.family] + perfume.subfamilies)
                    .map { $0.lowercased().trimmingCharacters(in: .whitespaces) }

                let selectedKeys = selectedFamilies.compactMap { displayName in
                    familyNameToKey[displayName]?.lowercased().trimmingCharacters(in: .whitespaces)
                }

                let selectedLower = selectedKeys.isEmpty
                    ? selectedFamilies.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
                    : selectedKeys

                return perfumeFamilies.contains { perfumeFamily in
                    selectedLower.contains(perfumeFamily)
                }
            } ?? true

            // 4. TEMPORADAS (OR - case-insensitive)
            let matchesSeason = selectedFilters["Temporada Recomendada"].map { selectedSeasons in
                guard !selectedSeasons.isEmpty else { return true }

                let perfumeSeasons = perfume.recommendedSeason
                    .compactMap { Season(rawValue: $0)?.displayName.lowercased() }

                let selectedSeasonsLower = selectedSeasons.map { $0.lowercased() }

                return perfumeSeasons.contains { season in
                    selectedSeasonsLower.contains(season)
                }
            } ?? true

            // 5. PROYECCIÓN (OR - case-insensitive)
            let matchesProjection = selectedFilters["Proyección"].map { selectedProjections in
                guard !selectedProjections.isEmpty else { return true }

                let perfumeProjectionDisplayName = Projection(rawValue: perfume.projection)?.displayName.lowercased() ?? ""
                let selectedProjectionsLower = selectedProjections.map { $0.lowercased() }

                return selectedProjectionsLower.contains(perfumeProjectionDisplayName)
            } ?? true

            // 6. DURACIÓN (OR - case-insensitive)
            let matchesDuration = selectedFilters["Duración"].map { selectedDurations in
                guard !selectedDurations.isEmpty else { return true }

                let perfumeDurationDisplayName = Duration(rawValue: perfume.duration)?.displayName.lowercased() ?? ""
                let selectedDurationsLower = selectedDurations.map { $0.lowercased() }

                return selectedDurationsLower.contains(perfumeDurationDisplayName)
            } ?? true

            // 7. PRECIO (OR - case-insensitive)
            let matchesPrice = selectedFilters["Precio"].map { selectedPrices in
                guard !selectedPrices.isEmpty else { return true }

                let perfumePriceDisplayName = Price(rawValue: perfume.price ?? Price.cheap.displayName)?.displayName.lowercased() ?? ""
                let selectedPricesLower = selectedPrices.map { $0.lowercased() }

                return selectedPricesLower.contains(perfumePriceDisplayName)
            } ?? true

            // 8. POPULARIDAD (range)
            let matchesPopularity = (perfume.popularity ?? 0.0) >= popularityRange.lowerBound &&
                                     (perfume.popularity ?? 0.0) <= popularityRange.upperBound

            // AND logic: perfume must match ALL filter categories
            return matchesSearchText && matchesGender && matchesFamily && matchesSeason &&
                   matchesProjection && matchesDuration && matchesPrice && matchesPopularity
        }

        #if DEBUG
        print("✅ [ExploreTab] Resultado: \(filteredPerfumes.count) perfumes")

        if filteredPerfumes.count > 0 {
            print("📋 [ExploreTab] Primeros 3 resultados:")
            for perfume in filteredPerfumes.prefix(3) {
                print("   - \(perfume.name) | family: \(perfume.family) | subfamilies: \(perfume.subfamilies)")
            }
        }
        #endif

        perfumes = sortPerfumes(perfumes: filteredPerfumes, sortOrder: sortOrder)
    }

    // MARK: - Sorting
    private func sortPerfumes(perfumes: [Perfume], sortOrder: SortOrder) -> [Perfume] {
        switch sortOrder {
        case .popularityAscending:
            return perfumes.sorted { ($0.popularity ?? 0.0) < ($1.popularity ?? 0.0) }
        case .popularityDescending:
            return perfumes.sorted { ($0.popularity ?? 0.0) > ($1.popularity ?? 0.0) }
        case .nameAscending:
            return perfumes.sorted { $0.name < $1.name }
        case .nameDescending:
            return perfumes.sorted { $0.name > $1.name }
        case .none:
            return perfumes
        }
    }

    // MARK: - Sort Order Enum
    enum SortOrder {
        case none, popularityAscending, popularityDescending, nameAscending, nameDescending
    }
}
