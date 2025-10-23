import SwiftUI
import Sliders

struct ExploreTabView: View {
    @State private var searchText = ""
    @State private var isFilterExpanded = true  // ✅ true por defecto para mostrar filtros al inicio
    @State private var selectedFilters: [String: [String]] = [:]
    @State private var perfumes: [Perfume] = []
    @State private var selectedPerfume: Perfume? = nil
    @State private var isShowingDetail = false
    @State private var selectedBrandForPerfume: Brand? = nil // NEW: State to hold the Brand for selected perfume

    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var familyViewModel: FamilyViewModel
    @EnvironmentObject var brandViewModel: BrandViewModel

    // Mapeo de displayName a key para familias
    private var familyNameToKey: [String: String] {
        Dictionary(uniqueKeysWithValues: familyViewModel.familias.map { ($0.name, $0.key) })
    }

    // State para controlar el estado de expansión de cada categoría de filtro
    @State private var genreExpanded: Bool = false
    @State private var familyExpanded: Bool = false
    @State private var seasonExpanded: Bool = false
    @State private var projectionExpanded: Bool = false
    @State private var durationExpanded: Bool = false
    @State private var priceExpanded: Bool = false
    @State private var popularityExpanded: Bool = false

    // State para el slider de popularidad
    @State private var popularityStartValue: Double = 0.0
    @State private var popularityRange: ClosedRange<Double> = 0...10
    @State private var popularityEndValue: Double = 10.0
    let range: ClosedRange<Double> = 0...10
    // ✅ ELIMINADO: Sistema de temas personalizable

    // **Sorting Option State**
    @State private var sortOrder: SortOrder = .none // Default sort order is none

    // **Sorting Enum**
    enum SortOrder {
        case none, popularityAscending, popularityDescending, nameAscending, nameDescending
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background
                GradientView(preset: .champan)
                    .edgesIgnoringSafeArea(.all)

                // Contenido principal con ScrollView
                VStack(spacing: 0) {
                    headerView // HeaderView fijo

                    ScrollView { // ScrollView para el resto del contenido
                        VStack {
                            if isFilterExpanded {
                                searchSection
                                filterSection
                            }
                            Button(action: {
                                withAnimation {
                                    isFilterExpanded.toggle()
                                }
                            }) {
                                HStack {
                                    Text(isFilterExpanded ? "Ocultar Filtros" : "Mostrar Filtros")
                                        .font(.system(size: 14, weight: .thin))
                                        .foregroundColor(.blue)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    if !selectedFilters.isEmpty || !searchText.isEmpty || popularityRange != 0...10 {
                                        Button(action: clearFilters) {
                                            Text("Limpiar Filtros")
                                                .font(.system(size: 14, weight: .thin))
                                                .foregroundColor(.red)
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                            resultsSection
                        }
                        .padding(.horizontal, 25)
                        .padding(.bottom, 70) // Ajusta el tamaño de este padding
                    }
                    .refreshable {
                        // Pull-to-refresh: reload metadata index
                        await perfumeViewModel.loadMetadataIndex()
                        filterResults()
                    }
                }

                HStack{ //CREA HSTACK
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
                // Load families
                await familyViewModel.loadInitialData()

                // ✅ ExploreTab necesita perfumes completos (para filtrar por projection, duration, price, etc.)
                // Cargar solo si no están ya cargados
                if perfumeViewModel.perfumes.isEmpty {
                    print("🔍 [ExploreTab] Loading full perfumes for filtering...")
                    await perfumeViewModel.loadInitialData()
                }

                filterResults() // Initial filter to populate perfumes array
            }
            .fullScreenCover(item: $selectedPerfume) { perfume in
                if let brand = selectedBrandForPerfume { // Check if brand is available
                    PerfumeDetailView(
                        perfume: perfume,
                        brand: brand,
                        profile: nil
                    )
                } else {
                    Text("Error loading perfume details: Brand not found") // Handle error if brand is missing
                }
            }
            .onChange(of: selectedPerfume) { newPerfume in // Listen for changes in selectedPerfume
                if let perfume = newPerfume {
                    // Fetch the brand using BrandViewModel when a perfume is selected
                    selectedBrandForPerfume = brandViewModel.getBrand(byKey: perfume.brand)
                } else {
                    selectedBrandForPerfume = nil // Clear the brand if selectedPerfume becomes nil
                }
            }
        }
    }

    // MARK: - Encabezado
    private var headerView: some View {
        HStack { // **HStack for title and sort button**
            VStack(alignment: .leading, spacing: 4) {
                Text("Encuentra tu Perfume".uppercased())
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(Color("textoPrincipal"))
            }
            Spacer() // Push title to the left and button to the right
            // **Sorting Button Menu**
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
                Image(systemName: "arrow.up.arrow.down.circle.fill") // Sort icon
                    .foregroundColor(Color("textoPrincipal"))
                    .font(.title2)
            }
        }
        .padding(.horizontal, 25) // PADDING ORIGINALMENTE EN EL ZSTACK
        .padding(.top, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.clear) // Fondo transparente
    }


    // MARK: - Barra de Búsqueda
    private var searchSection: some View {
        VStack {
            TextField("Escribe una nota, marca o familia olfativa...", text: $searchText, onCommit: filterResults)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.top, 12)  // ✅ Añadido espacio arriba
        .padding(.bottom, 8)
    }

    // MARK: - Filtros en Acordeón
    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            filterCategoryAccordion(title: "Género", options: Gender.allCases.map { $0.displayName }, expanded: $genreExpanded)
            filterCategoryAccordion(title: "Familia Olfativa", options: familyViewModel.familias.map { $0.name }, expanded: $familyExpanded)
            filterCategoryAccordion(title: "Temporada Recomendada", options: Season.allCases.map { $0.displayName }, expanded: $seasonExpanded)
            filterCategoryAccordion(title: "Proyección", options: Projection.allCases.map { $0.displayName }, expanded: $projectionExpanded)
            filterCategoryAccordion(title: "Duración", options: Duration.allCases.map { $0.displayName }, expanded: $durationExpanded)
            filterCategoryAccordion(title: "Precio", options: Price.allCases.map { $0.displayName }, expanded: $priceExpanded)
            filterPopularitySliderAccordion() // Popularidad con Slider
        }
        .padding(.vertical, 8)
    }

    private func filterCategoryAccordion(title: String, options: [String], expanded: Binding<Bool>) -> some View {
        DisclosureGroup(
            isExpanded: expanded,
            content: {
                filterCategoryGrid(title: title, options: options)
            },
            label: {
                Text(title)
                    .font(.system(size: 16, weight: .thin))
                    .foregroundColor(Color("textoSecundario"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        )
        .accentColor(Color("textoSecundario"))
        .onPreferenceChange(FilterSelectedPreferenceKey.self) { filterSelectedInCategory in
            if filterSelectedInCategory == title && !expanded.wrappedValue {
                expanded.wrappedValue = true
            }
        }
    }

    private func filterPopularitySliderAccordion() -> some View {
        DisclosureGroup(
            isExpanded: $popularityExpanded,
            content: {
                popularitySlider()
            },
            label: {
                Text("Popularidad")
                    .font(.system(size: 16, weight: .thin))
                    .foregroundColor(Color("textoSecundario"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        )
        .accentColor(Color("textoSecundario"))
    }

    private func popularitySlider() -> some View {
        VStack(alignment: .leading) {
            ItsukiSlider(value: $popularityRange, in:range, step: 1)
                .frame(height: 12)
                .onChange(of: popularityRange) { newValue in
                    if newValue.lowerBound == range.upperBound {
                        let adjustedLowerBound = newValue.lowerBound - 1
                        popularityRange = (adjustedLowerBound >= 0 ? adjustedLowerBound : 0)...newValue.upperBound
                    } else if newValue.upperBound == range.lowerBound {
                        let adjustedUpperBound = newValue.upperBound + 1
                        popularityRange = newValue.lowerBound...(adjustedUpperBound > 10 ? 10 : adjustedUpperBound)
                    } else {
                        popularityRange = newValue
                    }
                    filterResults()
                }
                .padding(.top, 10)
                .padding(.horizontal, 15)
            HStack {
                Spacer()
                Text("Popularidad Seleccionada: \(Int(popularityRange.lowerBound)) - \(Int(popularityRange.upperBound))").font(.system(size: 14, weight: .light))
                Spacer()
            }
            .padding(.top, 5)
        }
        .padding(.top, 8)
    }

    private func filterCategoryGrid(title: String, options: [String]) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
            ForEach(options, id: \.self) { option in
                FilterButton(category: title, option: option, isSelected: isSelected(category: title, option: option)) { cat, opt in
                    toggleFilter(category: cat, option: opt)
                }
            }
        }
        .padding(.top, 8)
    }

    struct FilterButton: View {
        let category: String
        let option: String
        let isSelected: Bool
        let action: (String, String) -> Void

        var body: some View {
            Button(action: {
                action(category, option)
            }) {
                Text(option)
                    .font(.system(size: 14))
                    .frame(minWidth: 90, minHeight: 30)
                    .foregroundColor(isSelected ? .white : Color("textoPrincipal"))
                    .padding(.horizontal, 8)
                    .background(isSelected ? Color("champan") : Color("grisSuave"))
                    .cornerRadius(12)
            }
        }
    }

    private func toggleFilter(category: String, option: String) {
        if selectedFilters[category]?.contains(option) == true {
            selectedFilters[category]?.removeAll(where: { $0 == option })
            if selectedFilters[category]?.isEmpty == true {
                selectedFilters.removeValue(forKey: category)
            }
        } else {
            if selectedFilters[category] == nil {
                selectedFilters[category] = []
            }
            selectedFilters[category]?.append(option)
        }
        filterResults()
    }

    private func isSelected(category: String, option: String) -> Bool {
        return selectedFilters[category]?.contains(option) == true
    }

    // MARK: - Resultados
    private var resultsSection: some View {
        VStack { // Wrap in VStack to manage conditional content
            // ✅ LOADING STATE
            if perfumeViewModel.isLoading && perfumes.isEmpty {
                LoadingView(message: "Cargando perfumes...", style: .fullScreen)
                    .frame(maxWidth: .infinity)
                    .frame(height: 400)
            }
            // ✅ EMPTY STATE - No filters applied
            else if searchText.isEmpty && selectedFilters.isEmpty && popularityRange == range {
                EmptyStateView(type: .noSearchResults)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 60)  // ✅ Padding para no cortar con tabBar
            }
            // ✅ EMPTY STATE - Filters applied but no results
            else if perfumes.isEmpty {
                EmptyStateView(type: .noFilterResults) {
                    clearFilters()
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 60)  // ✅ Padding para no cortar con tabBar
            }
            // ✅ RESULTS
            else {
                // **Sorted Perfume Array**
                let sortedPerfumes = sortPerfumes(perfumes: perfumes, sortOrder: sortOrder)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
                    ForEach(sortedPerfumes) { perfume in
                        resultCard(for: perfume)
                    }
                }
            }
        }
    }

    private func resultCard(for perfume: Perfume) -> some View {
        PerfumeCard(
            perfume: perfume,
            brandName: brandViewModel.getBrand(byKey: perfume.brand)?.name ?? perfume.brand,
            style: .compact,
            size: .medium,
            showsFamily: true,
            showsRating: true
        ) {
            selectedPerfume = perfume
        }
    }

    // MARK: - Limpiar Filtros
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
        popularityStartValue = 0.0 // Reset popularityStartValue
        popularityEndValue = 10.0
        popularityRange = 0.0...10.0 // Reset popularityRange
        sortOrder = .none // **Reset sort order to none**
        filterResults()
    }

    // MARK: - Filtrar Resultados
    private func filterResults() {
        print("\n🔍 [ExploreTab] Filtrando \(perfumeViewModel.perfumes.count) perfumes")
        print("   - SearchText: '\(searchText)'")
        print("   - Género: \(selectedFilters["Género"] ?? [])")
        print("   - Familias: \(selectedFilters["Familia Olfativa"] ?? [])")
        print("   - Temporadas: \(selectedFilters["Temporada Recomendada"] ?? [])")
        print("   - Proyección: \(selectedFilters["Proyección"] ?? [])")
        print("   - Duración: \(selectedFilters["Duración"] ?? [])")
        print("   - Precio: \(selectedFilters["Precio"] ?? [])")
        print("   - Popularidad: \(popularityRange)")

        // 🔬 DEBUG: Verificación manual de 5 perfumes random
        print("\n🔬 [DEBUG] Verificación manual de 5 perfumes random:")
        for perfume in perfumeViewModel.perfumes.shuffled().prefix(5) {
            print("📦 \(perfume.name)")
            print("   family type: \(type(of: perfume.family))")
            print("   family value: '\(perfume.family)'")
            print("   family isEmpty: \(perfume.family.isEmpty)")
            print("   subfamilies: \(perfume.subfamilies)")
            print("   ---")
        }
        print("\n")

        let filteredPerfumes = perfumeViewModel.perfumes.filter { perfume in
            // 1. BÚSQUEDA POR TEXTO (case-insensitive, diacritics-insensitive)
            let matchesSearchText: Bool = {
                if searchText.isEmpty { return true }

                let searchLower = searchText.lowercased()
                    .folding(options: .diacriticInsensitive, locale: .current)

                // Buscar en nombre del perfume
                let nameMatch = perfume.name.lowercased()
                    .folding(options: .diacriticInsensitive, locale: .current)
                    .contains(searchLower)

                // Buscar en brand key
                let brandKeyMatch = perfume.brand.lowercased()
                    .folding(options: .diacriticInsensitive, locale: .current)
                    .contains(searchLower)

                // Buscar en brand name (si existe)
                let brandNameMatch = brandViewModel.getBrand(byKey: perfume.brand)?.name.lowercased()
                    .folding(options: .diacriticInsensitive, locale: .current)
                    .contains(searchLower) ?? false

                // Buscar en family
                let familyMatch = perfume.family.lowercased()
                    .folding(options: .diacriticInsensitive, locale: .current)
                    .contains(searchLower)

                // Buscar en subfamilies
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
                // Use rawValue conversion and case-insensitive comparison
                let selectedRawGenders = selectedGenders.compactMap { Gender.rawValue(forDisplayName: $0)?.lowercased() }
                return selectedRawGenders.contains(perfume.gender.lowercased())
            } ?? true

            // 3. FAMILIAS OLFATIVAS (OR - case-insensitive, trim whitespace) - DEBUG MODE
            let matchesFamily = selectedFilters["Familia Olfativa"].map { selectedFamilies in
                guard !selectedFamilies.isEmpty else { return true }

                // Obtener todas las familias del perfume (family + subfamilies)
                let perfumeFamilies = ([perfume.family] + perfume.subfamilies)
                    .map { $0.lowercased().trimmingCharacters(in: .whitespaces) }

                // Convertir displayNames seleccionados a keys (ej: "Amaderados" -> "woody")
                let selectedKeys = selectedFamilies.compactMap { displayName in
                    familyNameToKey[displayName]?.lowercased().trimmingCharacters(in: .whitespaces)
                }

                // Si no hay keys válidas, intentar usar los valores directamente (fallback)
                let selectedLower = selectedKeys.isEmpty
                    ? selectedFamilies.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
                    : selectedKeys

                // Verificar si alguna familia del perfume coincide con alguna seleccionada (OR logic)
                let hasMatchingFamily = perfumeFamilies.contains { perfumeFamily in
                    selectedLower.contains(perfumeFamily)
                }

                return hasMatchingFamily
            } ?? true

            // 4. TEMPORADAS (OR - case-insensitive)
            let matchesSeason = selectedFilters["Temporada Recomendada"].map { selectedSeasons in
                guard !selectedSeasons.isEmpty else { return true }

                // Get perfume seasons and convert to display names
                let perfumeSeasons = perfume.recommendedSeason
                    .compactMap { Season(rawValue: $0)?.displayName.lowercased() }

                let selectedSeasonsLower = selectedSeasons.map { $0.lowercased() }

                // OR logic: perfume matches if it has ANY of the selected seasons
                let hasMatchingSeason = perfumeSeasons.contains { season in
                    selectedSeasonsLower.contains(season)
                }

                return hasMatchingSeason
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
            let matchesPopularity = (perfume.popularity ?? 0.0) >= popularityRange.lowerBound && (perfume.popularity ?? 0.0) <= popularityRange.upperBound

            // AND logic: perfume must match ALL filter categories
            return matchesSearchText && matchesGender && matchesFamily && matchesSeason && matchesProjection && matchesDuration && matchesPrice && matchesPopularity
        }

        print("✅ [ExploreTab] Resultado: \(filteredPerfumes.count) perfumes")

        // Debug: Show first 3 results
        if filteredPerfumes.count > 0 {
            print("📋 [ExploreTab] Primeros 3 resultados:")
            for perfume in filteredPerfumes.prefix(3) {
                print("   - \(perfume.name) | family: \(perfume.family) | subfamilies: \(perfume.subfamilies)")
            }
        }

        // 🔬 DEBUG: Análisis detallado de familia si hay filtro activo
        if let selectedFamilies = selectedFilters["Familia Olfativa"], !selectedFamilies.isEmpty {
            print("\n🔬 [DEBUG FAMILIAS] Análisis detallado de primeros 5 perfumes evaluados:")

            // Mostrar conversión de displayName a key
            let selectedKeys = selectedFamilies.compactMap { displayName in
                familyNameToKey[displayName]?.lowercased().trimmingCharacters(in: .whitespaces)
            }
            let selectedLower = selectedKeys.isEmpty
                ? selectedFamilies.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
                : selectedKeys

            print("   🔄 Conversión de filtros:")
            for (index, displayName) in selectedFamilies.enumerated() {
                let key = familyNameToKey[displayName] ?? "NO_KEY"
                let finalKey = index < selectedLower.count ? selectedLower[index] : "ERROR"
                print("      '\(displayName)' -> '\(key)' -> '\(finalKey)'")
            }
            print("")

            for perfume in perfumeViewModel.perfumes.prefix(5) {
                let perfumeFamilies = ([perfume.family] + perfume.subfamilies)
                    .map { $0.lowercased().trimmingCharacters(in: .whitespaces) }

                let hasMatch = perfumeFamilies.contains { perfumeFamily in
                    selectedLower.contains(perfumeFamily)
                }

                print("📦 \(perfume.name)")
                print("   - Raw family: '\(perfume.family)'")
                print("   - Raw subfamilies: \(perfume.subfamilies)")
                print("   - Processed perfume families: \(perfumeFamilies)")
                print("   - Selected filter keys: \(selectedLower)")
                print("   - Match: \(hasMatch ? "✅" : "❌")")
                print("   ---")
            }
            print("\n")
        }

        // 🔬 DEBUG: Si no hay resultados y hay filtros de familia aplicados
        if filteredPerfumes.isEmpty, let selectedFamilies = selectedFilters["Familia Olfativa"], !selectedFamilies.isEmpty {
            print("\n⚠️ [DEBUG] NO HAY RESULTADOS. Verificando problema...")
            print("   Familias seleccionadas: \(selectedFamilies)")

            // Contar cuántos perfumes tienen cada familia
            for selectedFamily in selectedFamilies {
                let count = perfumeViewModel.perfumes.filter { perfume in
                    let perfumeFamilies = ([perfume.family] + perfume.subfamilies)
                        .map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
                    return perfumeFamilies.contains(selectedFamily.lowercased())
                }.count

                print("   - Perfumes con familia '\(selectedFamily)': \(count)")
            }

            // Mostrar 3 perfumes que SÍ tienen la primera familia seleccionada
            if let firstFamily = selectedFamilies.first {
                print("\n   Ejemplos de perfumes con familia '\(firstFamily)':")
                let examples = perfumeViewModel.perfumes.filter { perfume in
                    let perfumeFamilies = ([perfume.family] + perfume.subfamilies)
                        .map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
                    return perfumeFamilies.contains(firstFamily.lowercased())
                }.prefix(3)

                for example in examples {
                    print("   📦 \(example.name) | family: '\(example.family)' | sub: \(example.subfamilies)")
                }
            }
            print("\n")
        }

        perfumes = sortPerfumes(perfumes: filteredPerfumes, sortOrder: sortOrder) // **Apply sorting after filtering**
    }

    // **Sorting function**
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
}

struct FilterSelectedPreferenceKey: PreferenceKey {
    static var defaultValue: String? = nil
    static func reduce(value: inout String?, nextValue: () -> String?) {
        value = nextValue() ?? value
    }
}
