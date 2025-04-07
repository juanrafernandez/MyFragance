import SwiftUI
import Kingfisher
import Sliders

// --- Estructura Combinada ---
struct TriedPerfumeDisplayItem: Identifiable {
    let id: String // Usamos el id del record como identificador principal
    let record: TriedPerfumeRecord
    let perfume: Perfume
    // Podríamos añadir el Brand aquí también si se necesita frecuentemente
}

struct FilterKeyPair: Identifiable, Hashable {
     let id: String // Usamos la key como ID (Identifiable)
     let key: String // La key para lógica
     let name: String // El nombre para mostrar
 }

struct TriedPerfumesListView: View {
    // --- ViewModels y Environment ---
    @StateObject var userViewModel = UserViewModel()
    @EnvironmentObject var brandViewModel: BrandViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel // <-- AÑADIDO
    @EnvironmentObject var familyViewModel: FamilyViewModel   // <-- AÑADIDO (descomentado)
    @Environment(\.dismiss) var dismiss // <-- AÑADIDO para botón atrás

    // Datos de entrada
    let userId: String
    let triedPerfumesInput: [TriedPerfumeRecord] // Mantenemos el nombre original

    // Estado UI General
    @AppStorage("selectedGradientPreset") private var selectedGradientPreset: GradientPreset = .champan

    // --- Estado Filtros/Ordenación (como antes) ---
    @State private var searchText = ""
    @State private var isFilterExpanded = false
    @State private var selectedFilters: [String: [String]] = [:]
    @State private var genreExpanded: Bool = false
    @State private var familyExpanded: Bool = false
    @State private var seasonExpanded: Bool = false
    @State private var projectionExpanded: Bool = false
    @State private var durationExpanded: Bool = false
    @State private var priceExpanded: Bool = false
    @State private var popularityExpanded: Bool = false // Para rating personal
    @State private var perfumePopularityExpanded: Bool = false // NUEVO: Para popularidad del perfume

    @State private var ratingRange: ClosedRange<Double> = 0...10 // Para rating personal
    let ratingSliderRange: ClosedRange<Double> = 0...10
    @State private var perfumePopularityRange: ClosedRange<Double> = 0...10 // NUEVO: Para popularidad perfume
    let perfumePopularitySliderRange: ClosedRange<Double> = 0...10

    @State private var sortOrder: SortOrder = .ratingDescending

    // Enum de Ordenación (Añadido dateAdded y popularity)
    enum SortOrder: Identifiable {
        case none, ratingAscending, ratingDescending, nameAscending, nameDescending, popularityAscending, popularityDescending
        var id: Self { self } // Conformar a Identifiable para Picker
    }

    // --- Estado Interno ---
    @State private var combinedDisplayItems: [TriedPerfumeDisplayItem] = [] // Estado para datos combinados
    @State private var filteredAndSortedDisplayItems: [TriedPerfumeDisplayItem] = [] // Estado para la lista final

    var body: some View {
        ZStack(alignment: .top) {
            GradientView(preset: selectedGradientPreset)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) { // Reducir spacing si es necesario
                headerView // Header con botón atrás y ordenar

                ScrollView {
                    VStack(spacing: 15) { // Ajustar spacing
                        if isFilterExpanded {
                            searchSection
                            filterSection // Filtros ahora habilitados
                        }
                        // Botones Mostrar/Ocultar y Limpiar (como antes)
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

                        // Vista de la lista o mensaje vacío
                        if filteredAndSortedDisplayItems.isEmpty {
                            // Mensaje si no hay resultados *después* de filtrar o si la lista original está vacía
                            if !searchText.isEmpty || !selectedFilters.isEmpty || ratingRange != ratingSliderRange || perfumePopularityRange != perfumePopularitySliderRange {
                                Text("No se encontraron perfumes con los filtros seleccionados.")
                                    .foregroundColor(.secondary)
                                    .padding()
                                    .frame(maxWidth: .infinity) // Ocupar ancho
                                    .frame(minHeight: 200) // Darle altura
                            } else if combinedDisplayItems.isEmpty {
                                // Mostrar solo si la lista original (sin filtros) está vacía
                                emptyListView
                            } else {
                                // Caso raro: filtros activos pero no vacían la lista completamente,
                                // pero el resultado *sí* es vacío. Mostrar mensaje de filtros.
                                Text("No se encontraron perfumes con los filtros seleccionados.")
                                    .foregroundColor(.secondary)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .frame(minHeight: 200)
                            }
                        } else {
                            // Si hay items para mostrar, usa la LazyVGrid
                            perfumeListView // <--- Aquí se inserta la LazyVGrid
                        }
                    }
                    .padding(.horizontal, 25)
                }
            }
        }
        .padding(.bottom, 5)
        .navigationBarHidden(true) // Mantenemos barra oculta por el header personalizado
        .onAppear {
            mapInputToDisplayItems() // Mapear datos al aparecer
            // applyFiltersAndSort() se llama dentro de mapInputToDisplayItems o .onChange
        }
        // Re-mapear si los datos de entrada cambian
        .onChange(of: triedPerfumesInput) { _ in mapInputToDisplayItems() }
        // Re-aplicar filtros/ordenación cuando cambian los criterios
        .onChange(of: sortOrder) { _ in applyFiltersAndSort() }
        .onChange(of: selectedFilters) { _ in applyFiltersAndSort() }
        .onChange(of: ratingRange) { _ in applyFiltersAndSort() }
        .onChange(of: perfumePopularityRange) { _ in applyFiltersAndSort() }
        .onChange(of: searchText) { _ in applyFiltersAndSort() }
    }

    // MARK: - Header con Botón Atrás y Ordenación
    private var headerView: some View {
        HStack {
            // --- Botón Atrás ---
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.backward")
                    .foregroundColor(Color("textoPrincipal"))
                    .font(.title2) // Ajustar tamaño si es necesario
            }
            .padding(.trailing, 5) // Espacio entre botón y título

            // Título
            Text("Perfumes Probados".uppercased())
                .font(.system(size: 18, weight: .light))
                .foregroundColor(Color("textoPrincipal"))
                .lineLimit(1) // Asegurar una línea

            Spacer() // Empuja título a la izq y menú a la der

            // Menú Ordenar
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
        .padding(.vertical, 10) // Ajustar padding vertical
        .frame(maxWidth: .infinity, minHeight: 44) // Altura mínima consistente
        .background(Color.clear)
    }

    // MARK: - Búsqueda
    private var searchSection: some View {
        VStack {
            TextField("Buscar perfume o marca...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.bottom, 8)
    }

    // MARK: - Filtros (AHORA FUNCIONALES)
    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Descomentados y funcionales
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
            
            // Filtro de Rating Personal
            filterRatingSliderAccordion() // Renombrado para claridad

             // NUEVO: Filtro de Popularidad del Perfume
            filterPerfumePopularitySliderAccordion()
        }
        .padding(.vertical, 8)
    }

    private func filterCategoryAccordion(title: String, options: [FilterKeyPair], expanded: Binding<Bool>) -> some View {
        Group {
            if options.isEmpty {
                Text("\(title): (Cargando...)") // Mensaje de carga
                    .font(.system(size: 16, weight: .thin))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 5)
            } else {
                DisclosureGroup(isExpanded: expanded) {
                    // Llama a la grid que también acepta [FilterKeyPair]
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

    private func filterRatingSliderAccordion() -> some View { // Renombrado
        DisclosureGroup(isExpanded: $popularityExpanded) { // Sigue usando popularityExpanded
            ratingSlider() // Renombrado
        } label: {
            Text("Rating Personal")
                .font(.system(size: 16, weight: .thin))
                .foregroundColor(Color("textoSecundario"))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accentColor(Color("textoSecundario"))
    }

     private func filterPerfumePopularitySliderAccordion() -> some View { // NUEVO
        DisclosureGroup(isExpanded: $perfumePopularityExpanded) {
            perfumePopularitySlider() // NUEVO
        } label: {
            Text("Popularidad Perfume")
                .font(.system(size: 16, weight: .thin))
                .foregroundColor(Color("textoSecundario"))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accentColor(Color("textoSecundario"))
    }

    private func ratingSlider() -> some View { // Renombrado
        VStack(alignment: .leading) {
             ItsukiSlider(value: $ratingRange, in: ratingSliderRange, step: 1) // Usa ratingRange
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

     private func perfumePopularitySlider() -> some View { // NUEVO
        VStack(alignment: .leading) {
             ItsukiSlider(value: $perfumePopularityRange, in: perfumePopularitySliderRange, step: 1) // Usa perfumePopularityRange
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
            ForEach(options) { optionPair in // Itera sobre FilterKeyPair directamente
                FilterButton(
                    category: title,               // Título de la categoría
                    optionKey: optionPair.key,     // Pasa la KEY para la lógica
                    displayText: optionPair.name,  // Pasa el NAME para mostrar
                    isSelected: isSelected(category: title, option: optionPair.key) // Comprueba usando la KEY
                ) { cat, optKey in
                    toggleFilter(category: cat, option: optKey) // Llama a toggle con la KEY
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

    // MARK: - Vistas de Contenido
    private var emptyListView: some View {
        VStack {
            Spacer() // Empuja el texto hacia el centro verticalmente si es posible
            Text("No has probado ningún perfume todavía.")
                .font(.title3)
                .foregroundColor(Color.gray)
                .multilineTextAlignment(.center)
                .padding()
            Spacer() // Empuja el texto hacia el centro verticalmente si es posible
        }
        // Dale un frame para que ocupe espacio si no hay otros elementos en el ScrollView
        .frame(maxWidth: .infinity)
        .frame(minHeight: 200) // Altura mínima para que sea visible
    }

    private var perfumeListView: some View {
        LazyVGrid(
            // Define las columnas como en ExploreTabView
            // Ajusta 'minimum' si el ancho de tu PerfumeCardView es diferente a 150
            columns: [GridItem(.adaptive(minimum: 145), spacing: 16)],
            spacing: 16 // Espaciado vertical entre filas de la grid
        ) {
            ForEach(filteredAndSortedDisplayItems) { item in // item es TriedPerfumeDisplayItem
                // --- Llamada directa a PerfumeCardView ---
                PerfumeCardView(
                    perfume: item.perfume,             // Pasa el objeto Perfume del item
                    brandViewModel: brandViewModel,    // Pasa el EnvironmentObject BrandViewModel
                    score: item.record.rating,         // Usa el rating personal del record como 'score'
                    showPopularity: false              // No mostrar popularidad si mostramos score personal
                )
                // Añade aquí el onTapGesture si quieres navegar al detalle
                .onTapGesture {
                    // Aquí necesitarías una variable @State para el perfume seleccionado
                    // y lógica de navegación (como un .sheet o NavigationLink si estás en NavigationView)
                    // Ejemplo: selectedPerfumeForDetail = item.perfume
                    print("Tapped on: \(item.perfume.name)")
                }
            }
        }
    }

    // MARK: - Lógica de Mapeo, Filtros y Ordenación (MODIFICADA)

    // Función para mapear Records a DisplayItems usando PerfumeViewModel
    private func mapInputToDisplayItems() {
        print("Intentando mapear \(triedPerfumesInput.count) records a display items...")
        // Usar un diccionario para búsqueda rápida de perfumes
        let perfumeDict = Dictionary(uniqueKeysWithValues: perfumeViewModel.perfumes.map { ($0.key, $0) })
        print("Diccionario de perfumes creado con \(perfumeDict.count) entradas.")

        combinedDisplayItems = triedPerfumesInput.compactMap { record -> TriedPerfumeDisplayItem? in
            guard let recordId = record.id else {
                print("Saltando record sin ID: \(record.perfumeKey)")
                return nil // Necesitamos ID para Identifiable
            }
            // Buscar el perfume usando la clave del record
            if let perfume = perfumeDict[record.perfumeKey] {
                return TriedPerfumeDisplayItem(id: recordId, record: record, perfume: perfume)
            } else {
                print("Perfume no encontrado en ViewModel para key: \(record.perfumeKey)")
                // Opcionalmente: Crear un item con datos parciales o excluirlo
                return nil // Excluir si no se encuentra el perfume completo
            }
        }
        print("Mapeo completado. \(combinedDisplayItems.count) display items creados.")
        // Aplicar filtros y ordenación inicial después de mapear
        applyFiltersAndSort()
    }

    // Función principal que aplica filtros y ordenación a los DisplayItems
    private func applyFiltersAndSort() {
        print("Aplicando filtros y ordenación...")
        var workingList = combinedDisplayItems

        // 1. Filtrar por Texto de Búsqueda (sobre nombre de perfume y marca)
        if !searchText.isEmpty {
            let lowercasedSearch = searchText.lowercased()
            workingList = workingList.filter { item in
                item.perfume.name.lowercased().contains(lowercasedSearch) ||
                (brandViewModel.getBrand(byKey: item.perfume.brand)?.name ?? item.perfume.brand).lowercased().contains(lowercasedSearch)
            }
        }

        // 2. Filtrar por Rating Personal (de TriedPerfumeRecord)
        workingList = workingList.filter { item in
            let rating = item.record.rating ?? 0
            return rating >= ratingRange.lowerBound && rating <= ratingRange.upperBound
        }

        // 3. Filtrar por Popularidad del Perfume (de Perfume)
         workingList = workingList.filter { item in
             // Asumiendo que popularity en Perfume es 0-100, lo escalamos a 0-10
             let popularityScore = item.perfume.popularity / 10.0
             return popularityScore >= perfumePopularityRange.lowerBound && popularityScore <= perfumePopularityRange.upperBound
        }

        // 4. Filtrar por Categorías (selectedFilters) - AHORA FUNCIONAL
        if !selectedFilters.isEmpty {
            workingList = workingList.filter { item in
                let perfume = item.perfume // Acceder al objeto Perfume

                // Lógica de filtro copiada y adaptada de ExploreTabView
                let matchesGender = selectedFilters["Género"]?.isEmpty ?? true || selectedFilters["Género"]!.contains(perfume.gender)

                let matchesFamily = selectedFilters["Familia Olfativa"]?.isEmpty ?? true || selectedFilters["Familia Olfativa"]!.contains(perfume.family)

                let matchesSeason = selectedFilters["Temporada Recomendada"]?.isEmpty ?? true || !Set(selectedFilters["Temporada Recomendada"]!).intersection(Set(perfume.recommendedSeason.compactMap { Season(rawValue: $0)?.displayName })).isEmpty

                let matchesProjection = selectedFilters["Proyección"]?.isEmpty ?? true || selectedFilters["Proyección"]!.contains(Projection(rawValue: perfume.projection)?.displayName ?? "---")

                let matchesDuration = selectedFilters["Duración"]?.isEmpty ?? true || selectedFilters["Duración"]!.contains(Duration(rawValue: perfume.duration)?.displayName ?? "---")

                let matchesPrice = selectedFilters["Precio"]?.isEmpty ?? true || selectedFilters["Precio"]!.contains(Price(rawValue: perfume.price ?? "")?.displayName ?? "---") // Asume perfume.price es String?

                return matchesGender && matchesFamily && matchesSeason && matchesProjection && matchesDuration && matchesPrice
            }
        }

        // 5. Ordenar
        workingList = sortDisplayItems(items: workingList, sortOrder: sortOrder)

        // 6. Actualizar el estado final
        filteredAndSortedDisplayItems = workingList
        print("Filtros y ordenación aplicados. Mostrando \(filteredAndSortedDisplayItems.count) items.")
    }

    // Limpiar filtros (adaptado para nuevos sliders)
    private func clearFilters() {
        searchText = ""
        selectedFilters.removeAll()
        genreExpanded = false; familyExpanded = false; seasonExpanded = false;
        projectionExpanded = false; durationExpanded = false; priceExpanded = false;
        popularityExpanded = false; perfumePopularityExpanded = false; // Resetear expansión
        ratingRange = ratingSliderRange // Resetear rangos
        perfumePopularityRange = perfumePopularitySliderRange
        sortOrder = .ratingDescending // Resetear orden al default
        applyFiltersAndSort()
    }

    // Toggle filter (AHORA FUNCIONAL para todas las categorías)
    private func toggleFilter(category: String, option: String) {
        // Ya no necesita la guarda
        if selectedFilters[category]?.contains(option) == true {
            selectedFilters[category]?.removeAll { $0 == option }
            if selectedFilters[category]?.isEmpty == true {
                selectedFilters.removeValue(forKey: category)
            }
        } else {
            selectedFilters[category, default: []].append(option)
        }
        // applyFiltersAndSort se llama desde .onChange(of: selectedFilters)
    }

    // isSelected (sin cambios)
    private func isSelected(category: String, option: String) -> Bool {
        selectedFilters[category]?.contains(option) == true
    }

    // Función de ordenación (Adaptada para TriedPerfumeDisplayItem)
    private func sortDisplayItems(items: [TriedPerfumeDisplayItem], sortOrder: SortOrder) -> [TriedPerfumeDisplayItem] {
        switch sortOrder {
        case .ratingAscending:
            return items.sorted { ($0.record.rating ?? 0) < ($1.record.rating ?? 0) }
        case .ratingDescending:
            return items.sorted { ($0.record.rating ?? 0) > ($1.record.rating ?? 0) }
        case .popularityAscending: // Popularidad del Perfume
             return items.sorted { $0.perfume.popularity < $1.perfume.popularity }
        case .popularityDescending: // Popularidad del Perfume
             return items.sorted { $0.perfume.popularity > $1.perfume.popularity }
        case .nameAscending:
            return items.sorted { $0.perfume.name < $1.perfume.name } // Usar nombre del perfume
        case .nameDescending:
            return items.sorted { $0.perfume.name > $1.perfume.name } // Usar nombre del perfume
        case .none:
            return items
        }
    }

    // MARK: - Acciones
    private func deletePerfume(at offsets: IndexSet) {
        let itemsToDelete = offsets.map { filteredAndSortedDisplayItems[$0] }

        for itemToDelete in itemsToDelete {
            // Usar el ID del record para la eliminación
            guard let recordId = itemToDelete.record.id else {
                print("Error: record.id is nil para item: \(itemToDelete.perfume.name)")
                continue
            }
            Task {
                let success = await userViewModel.deleteTriedPerfume(userId: userId, recordId: recordId)
                if !success {
                    print("Error al eliminar el registro con ID: \(recordId)")
                    // Podrías mostrar una alerta al usuario aquí
                }
                // IMPORTANTE: La lista se actualizará automáticamente si `triedPerfumesInput`
                // se modifica externamente y `.onChange(of: triedPerfumesInput)` se dispara.
                // Si no, necesitas un mecanismo para refrescar `triedPerfumesInput` o
                // eliminar el item de `combinedDisplayItems` y llamar `applyFiltersAndSort`.
            }
        }
    }
}
