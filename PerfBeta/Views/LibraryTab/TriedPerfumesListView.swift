import SwiftUI
import Kingfisher
import Sliders

struct TriedPerfumeDisplayItem: Identifiable {
    let id: String
    let record: TriedPerfumeRecord
    let perfume: Perfume
}

struct FilterKeyPair: Identifiable, Hashable {
     let id: String
     let key: String
     let name: String
 }

struct TriedPerfumesListView: View {
    @StateObject var userViewModel = UserViewModel()
    @EnvironmentObject var brandViewModel: BrandViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var familyViewModel: FamilyViewModel
    @Environment(\.dismiss) var dismiss

    let userId: String
    let triedPerfumesInput: [TriedPerfumeRecord]

    @AppStorage("selectedGradientPreset") private var selectedGradientPreset: GradientPreset = .champan

    @State private var searchText = ""
    @State private var isFilterExpanded = false
    @State private var selectedFilters: [String: [String]] = [:]
    @State private var genreExpanded: Bool = false
    @State private var familyExpanded: Bool = false
    @State private var seasonExpanded: Bool = false
    @State private var projectionExpanded: Bool = false
    @State private var durationExpanded: Bool = false
    @State private var priceExpanded: Bool = false
    @State private var popularityExpanded: Bool = false
    @State private var perfumePopularityExpanded: Bool = false

    @State private var ratingRange: ClosedRange<Double> = 0...10
    let ratingSliderRange: ClosedRange<Double> = 0...10
    @State private var perfumePopularityRange: ClosedRange<Double> = 0...10
    let perfumePopularitySliderRange: ClosedRange<Double> = 0...10

    @State private var sortOrder: SortOrder = .ratingDescending

    enum SortOrder: Identifiable {
        case none, ratingAscending, ratingDescending, nameAscending, nameDescending, popularityAscending, popularityDescending
        var id: Self { self }
    }

    @State private var combinedDisplayItems: [TriedPerfumeDisplayItem] = []
    @State private var filteredAndSortedDisplayItems: [TriedPerfumeDisplayItem] = []

    var body: some View {
        ZStack(alignment: .top) {
            GradientView(preset: selectedGradientPreset)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                headerView

                ScrollView {
                    VStack(spacing: 15) {
                        if isFilterExpanded {
                            searchSection
                            filterSection
                        }
                        Button(action: { withAnimation { isFilterExpanded.toggle() } }) {
                             HStack {
                                Text(isFilterExpanded ? "Ocultar Filtros" : "Mostrar Filtros")
                                    .font(.system(size: 14, weight: .thin)).foregroundColor(.blue)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                if !selectedFilters.isEmpty || !searchText.isEmpty || ratingRange != ratingSliderRange || perfumePopularityRange != perfumePopularitySliderRange {
                                    Button(action: clearFilters) {
                                        Text("Limpiar Filtros").font(.system(size: 14, weight: .thin)).foregroundColor(.red)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }

                        if filteredAndSortedDisplayItems.isEmpty {
                            if !searchText.isEmpty || !selectedFilters.isEmpty || ratingRange != ratingSliderRange || perfumePopularityRange != perfumePopularitySliderRange {
                                Text("No se encontraron perfumes con los filtros seleccionados.")
                                    .foregroundColor(.secondary)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .frame(minHeight: 200)
                            } else if combinedDisplayItems.isEmpty {
                                emptyListView
                            } else {
                                Text("No se encontraron perfumes con los filtros seleccionados.")
                                    .foregroundColor(.secondary)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .frame(minHeight: 200)
                            }
                        } else {
                            perfumeListView
                        }
                    }
                    .padding(.horizontal, 25)
                }
            }
        }
        .padding(.bottom, 5)
        .navigationBarHidden(true)
        .onAppear {
            mapInputToDisplayItems()
        }
        .onChange(of: triedPerfumesInput) { _ in mapInputToDisplayItems() }
        .onChange(of: sortOrder) { _ in applyFiltersAndSort() }
        .onChange(of: selectedFilters) { _ in applyFiltersAndSort() }
        .onChange(of: ratingRange) { _ in applyFiltersAndSort() }
        .onChange(of: perfumePopularityRange) { _ in applyFiltersAndSort() }
        .onChange(of: searchText) { _ in applyFiltersAndSort() }
    }

    private var headerView: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.backward")
                    .foregroundColor(Color("textoPrincipal"))
                    .font(.title2)
            }
            .padding(.trailing, 5)

            Text("Perfumes Probados".uppercased())
                .font(.system(size: 18, weight: .light))
                .foregroundColor(Color("textoPrincipal"))
                .lineLimit(1)

            Spacer()

            // --- NUEVO BOTÓN COMPARTIR ---
            Button {
                shareButtonTapped() // Acción placeholder
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(Color("textoPrincipal"))
                    .font(.title2)
            }
            .padding(.trailing, 8) // Espacio entre compartir y ordenar

            // Menú Ordenar (existente)
            Menu {
                Picker("Ordenar por", selection: $sortOrder) {
                    Text("Rating Personal (Mayor a Menor)").tag(SortOrder.ratingDescending)
                    Text("Rating Personal (Menor a Mayor)").tag(SortOrder.ratingAscending)
                    Divider()
                    Text("Popularidad Perfume (Mayor a Menor)").tag(SortOrder.popularityDescending)
                    Text("Popularidad Perfume (Menor a Mayor)").tag(SortOrder.popularityAscending)
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
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, minHeight: 44)
        .background(Color.clear)
    }

    private var searchSection: some View {
        VStack {
            TextField("Buscar perfume o marca...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.bottom, 8)
    }

    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            filterCategoryAccordion(title: "Género",
                                    options: Gender.allCases.map { FilterKeyPair(id: $0.rawValue, key: $0.rawValue, name: $0.displayName) },
                                    expanded: $genreExpanded)
            filterCategoryAccordion(title: "Familia Olfativa",
                                    options: familyViewModel.familias.map { FilterKeyPair(id: $0.key, key: $0.key, name: $0.name) },
                                    expanded: $familyExpanded)
            filterCategoryAccordion(title: "Temporada Recomendada",
                                    options: Season.allCases.map { FilterKeyPair(id: $0.rawValue, key: $0.rawValue, name: $0.displayName) },
                                    expanded: $seasonExpanded)
            filterCategoryAccordion(title: "Proyección",
                                    options: Projection.allCases.map { FilterKeyPair(id: $0.rawValue, key: $0.rawValue, name: $0.displayName) },
                                    expanded: $projectionExpanded)
            filterCategoryAccordion(title: "Duración",
                                    options: Duration.allCases.map { FilterKeyPair(id: $0.rawValue, key: $0.rawValue, name: $0.displayName) },
                                    expanded: $durationExpanded)
            filterCategoryAccordion(title: "Precio",
                                    options: Price.allCases.map { FilterKeyPair(id: $0.rawValue, key: $0.rawValue, name: $0.displayName) },
                                    expanded: $priceExpanded)

            filterRatingSliderAccordion()
            filterPerfumePopularitySliderAccordion()
        }
        .padding(.vertical, 8)
    }

    private func filterCategoryAccordion(title: String, options: [FilterKeyPair], expanded: Binding<Bool>) -> some View {
        Group {
            if options.isEmpty {
                Text("\(title): (Cargando...)")
                    .font(.system(size: 16, weight: .thin))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 5)
            } else {
                DisclosureGroup(isExpanded: expanded) {
                    filterCategoryGrid(title: title, options: options)
                } label: {
                    Text(title)
                        .font(.system(size: 16, weight: .thin))
                        .foregroundColor(Color("textoSecundario"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accentColor(Color("textoSecundario"))
            }
        }
    }

    private func filterRatingSliderAccordion() -> some View {
        DisclosureGroup(isExpanded: $popularityExpanded) {
            ratingSlider()
        } label: {
            Text("Rating Personal")
                .font(.system(size: 16, weight: .thin))
                .foregroundColor(Color("textoSecundario"))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accentColor(Color("textoSecundario"))
    }

     private func filterPerfumePopularitySliderAccordion() -> some View {
        DisclosureGroup(isExpanded: $perfumePopularityExpanded) {
            perfumePopularitySlider()
        } label: {
            Text("Popularidad Perfume")
                .font(.system(size: 16, weight: .thin))
                .foregroundColor(Color("textoSecundario"))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accentColor(Color("textoSecundario"))
    }

    private func ratingSlider() -> some View {
        VStack(alignment: .leading) {
             ItsukiSlider(value: $ratingRange, in: ratingSliderRange, step: 1)
                .frame(height: 12)
                .padding(.top, 10).padding(.horizontal, 15)

            HStack {
                Spacer()
                Text("Rating: \(Int(ratingRange.lowerBound)) - \(Int(ratingRange.upperBound))")
                    .font(.system(size: 14, weight: .light))
                Spacer()
            }.padding(.top, 5)
        }.padding(.top, 8)
    }

     private func perfumePopularitySlider() -> some View {
        VStack(alignment: .leading) {
             ItsukiSlider(value: $perfumePopularityRange, in: perfumePopularitySliderRange, step: 1)
                .frame(height: 12)
                .padding(.top, 10).padding(.horizontal, 15)

            HStack {
                Spacer()
                Text("Popularidad: \(Int(perfumePopularityRange.lowerBound)) - \(Int(perfumePopularityRange.upperBound))")
                    .font(.system(size: 14, weight: .light))
                Spacer()
            }.padding(.top, 5)
        }.padding(.top, 8)
    }

    private func filterCategoryGrid(title: String, options: [FilterKeyPair]) -> some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
            ForEach(options) { optionPair in
                FilterButton(
                    category: title,
                    optionKey: optionPair.key,
                    displayText: optionPair.name,
                    isSelected: isSelected(category: title, option: optionPair.key)
                ) { cat, optKey in
                    toggleFilter(category: cat, option: optKey)
                }
            }
        }
        .padding(.top, 8)
    }

    struct FilterButton: View {
        let category: String
        let optionKey: String
        let displayText: String
        let isSelected: Bool
        let action: (String, String) -> Void

        var body: some View {
            Button(action: { action(category, optionKey) }) {
                Text(displayText)
                    .font(.system(size: 14))
                    .frame(minWidth: 90, minHeight: 30)
                    .foregroundColor(isSelected ? .white : Color("textoPrincipal"))
                    .padding(.horizontal, 8)
                    .background(isSelected ? Color("champan") : Color("grisSuave"))
                    .cornerRadius(12)
            }
        }
    }

    private var emptyListView: some View {
        VStack {
            Spacer()
            Text("No has probado ningún perfume todavía.")
                .font(.title3)
                .foregroundColor(Color.gray)
                .multilineTextAlignment(.center)
                .padding()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 200)
    }

    private var perfumeListView: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 145), spacing: 16)],
            spacing: 16
        ) {
            ForEach(filteredAndSortedDisplayItems) { item in
                PerfumeCardView(
                    perfume: item.perfume,
                    brandViewModel: brandViewModel,
                    score: item.record.rating,
                    showPopularity: true
                )
                .onTapGesture {
                    print("Tapped on: \(item.perfume.name)")
                }
            }
        }
    }

    private func mapInputToDisplayItems() {
        print("Intentando mapear \(triedPerfumesInput.count) records a display items...")
        let perfumeDict = Dictionary(uniqueKeysWithValues: perfumeViewModel.perfumes.map { ($0.key, $0) })
        print("Diccionario de perfumes creado con \(perfumeDict.count) entradas.")

        combinedDisplayItems = triedPerfumesInput.compactMap { record -> TriedPerfumeDisplayItem? in
            guard let recordId = record.id else {
                print("Saltando record sin ID: \(record.perfumeKey)")
                return nil
            }
            if let perfume = perfumeDict[record.perfumeKey] {
                return TriedPerfumeDisplayItem(id: recordId, record: record, perfume: perfume)
            } else {
                print("Perfume no encontrado en ViewModel para key: \(record.perfumeKey)")
                return nil
            }
        }
        print("Mapeo completado. \(combinedDisplayItems.count) display items creados.")
        applyFiltersAndSort()
    }

    private func applyFiltersAndSort() {
        print("Aplicando filtros y ordenación...")
        var workingList = combinedDisplayItems

        if !searchText.isEmpty {
            let lowercasedSearch = searchText.lowercased()
            workingList = workingList.filter { item in
                item.perfume.name.lowercased().contains(lowercasedSearch) ||
                (brandViewModel.getBrand(byKey: item.perfume.brand)?.name ?? item.perfume.brand).lowercased().contains(lowercasedSearch)
            }
        }

        workingList = workingList.filter { item in
            let rating = item.record.rating ?? 0
            return rating >= ratingRange.lowerBound && rating <= ratingRange.upperBound
        }

         workingList = workingList.filter { item in
             let popularityScore = item.perfume.popularity / 10.0
             return popularityScore >= perfumePopularityRange.lowerBound && popularityScore <= perfumePopularityRange.upperBound
        }

        if !selectedFilters.isEmpty {
            workingList = workingList.filter { item in
                let perfume = item.perfume

                let matchesGender = selectedFilters["Género"]?.isEmpty ?? true || selectedFilters["Género"]!.contains(perfume.gender)
                let matchesFamily = selectedFilters["Familia Olfativa"]?.isEmpty ?? true || selectedFilters["Familia Olfativa"]!.contains(perfume.family)
                let matchesSeason = selectedFilters["Temporada Recomendada"]?.isEmpty ?? true || !Set(selectedFilters["Temporada Recomendada"]!).intersection(Set(perfume.recommendedSeason.compactMap { Season(rawValue: $0)?.rawValue })).isEmpty
                let matchesProjection = selectedFilters["Proyección"]?.isEmpty ?? true || selectedFilters["Proyección"]!.contains(perfume.projection)
                let matchesDuration = selectedFilters["Duración"]?.isEmpty ?? true || selectedFilters["Duración"]!.contains(perfume.duration)
                let matchesPrice = selectedFilters["Precio"]?.isEmpty ?? true || selectedFilters["Precio"]!.contains(perfume.price ?? "")

                return matchesGender && matchesFamily && matchesSeason && matchesProjection && matchesDuration && matchesPrice
            }
        }

        workingList = sortDisplayItems(items: workingList, sortOrder: sortOrder)

        filteredAndSortedDisplayItems = workingList
        print("Filtros y ordenación aplicados. Mostrando \(filteredAndSortedDisplayItems.count) items.")
    }

    private func clearFilters() {
        searchText = ""
        selectedFilters.removeAll()
        genreExpanded = false; familyExpanded = false; seasonExpanded = false;
        projectionExpanded = false; durationExpanded = false; priceExpanded = false;
        popularityExpanded = false; perfumePopularityExpanded = false;
        ratingRange = ratingSliderRange
        perfumePopularityRange = perfumePopularitySliderRange
        sortOrder = .ratingDescending
        applyFiltersAndSort()
    }

    private func toggleFilter(category: String, option: String) {
        if selectedFilters[category]?.contains(option) == true {
            selectedFilters[category]?.removeAll { $0 == option }
            if selectedFilters[category]?.isEmpty == true {
                selectedFilters.removeValue(forKey: category)
            }
        } else {
            selectedFilters[category, default: []].append(option)
        }
    }

    private func isSelected(category: String, option: String) -> Bool {
        selectedFilters[category]?.contains(option) == true
    }

    private func sortDisplayItems(items: [TriedPerfumeDisplayItem], sortOrder: SortOrder) -> [TriedPerfumeDisplayItem] {
        switch sortOrder {
        case .ratingAscending:
            return items.sorted { ($0.record.rating ?? 0) < ($1.record.rating ?? 0) }
        case .ratingDescending:
            return items.sorted { ($0.record.rating ?? 0) > ($1.record.rating ?? 0) }
        case .popularityAscending:
             return items.sorted { $0.perfume.popularity < $1.perfume.popularity }
        case .popularityDescending:
             return items.sorted { $0.perfume.popularity > $1.perfume.popularity }
        case .nameAscending:
            return items.sorted { $0.perfume.name < $1.perfume.name }
        case .nameDescending:
            return items.sorted { $0.perfume.name > $1.perfume.name }
        case .none:
            return items
        }
    }

    // --- NUEVA FUNCIÓN PLACEHOLDER ---
    private func shareButtonTapped() {
        print("Botón Compartir presionado. Lógica de compartir irá aquí.")
        // Aquí implementarás la lógica para mostrar el Share Sheet (UIActivityViewController)
        // Necesitarás crear el contenido a compartir (texto, URL, imagen, etc.)
    }

    private func deletePerfume(at offsets: IndexSet) {
        let itemsToDelete = offsets.map { filteredAndSortedDisplayItems[$0] }

        for itemToDelete in itemsToDelete {
            guard let recordId = itemToDelete.record.id else {
                print("Error: record.id is nil para item: \(itemToDelete.perfume.name)")
                continue
            }
            Task {
                let success = await userViewModel.deleteTriedPerfume(userId: userId, recordId: recordId)
                if !success {
                    print("Error al eliminar el registro con ID: \(recordId)")
                }
            }
        }
    }
}
