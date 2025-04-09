import SwiftUI
import Kingfisher
import Sliders
import UIKit // <--- AÑADIDO: Necesario para UIImage, UIActivityViewController, etc.

// --- Estructuras de Datos (sin cambios) ---
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

// --- Vista Principal ---
struct TriedPerfumesListView: View {
    @StateObject var userViewModel = UserViewModel()
    @EnvironmentObject var brandViewModel: BrandViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var familyViewModel: FamilyViewModel
    @Environment(\.dismiss) var dismiss

    let userId: String
    let triedPerfumesInput: [TriedPerfumeRecord]

    @AppStorage("selectedGradientPreset") private var selectedGradientPreset: GradientPreset = .champan

    // --- Estados UI (sin cambios) ---
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

    // --- Cuerpo de la Vista (sin cambios en la estructura general) ---
    var body: some View {
        ZStack(alignment: .top) {
            GradientView(preset: selectedGradientPreset)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                headerView // Header ahora contiene el botón de compartir funcional

                ScrollView {
                    VStack(spacing: 15) {
                        if isFilterExpanded {
                            searchSection
                            filterSection
                        }
                        // Botón Mostrar/Ocultar Filtros (sin cambios)
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

                        // Lista o mensaje vacío (sin cambios)
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
                                Text("No se encontraron perfumes con los filtros seleccionados.") // Caso raro
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
        // --- .onChange (sin cambios) ---
        .onChange(of: triedPerfumesInput) { _ in mapInputToDisplayItems() }
        .onChange(of: sortOrder) { _ in applyFiltersAndSort() }
        .onChange(of: selectedFilters) { _ in applyFiltersAndSort() }
        .onChange(of: ratingRange) { _ in applyFiltersAndSort() }
        .onChange(of: perfumePopularityRange) { _ in applyFiltersAndSort() }
        .onChange(of: searchText) { _ in applyFiltersAndSort() }
    }

    // MARK: - Header con Funcionalidad de Compartir
    private var headerView: some View {
        HStack {
            // Botón Atrás (sin cambios)
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.backward")
                    .foregroundColor(Color("textoPrincipal"))
                    .font(.title2)
            }
            .padding(.trailing, 5)

            // Título (sin cambios)
            Text("Perfumes Probados".uppercased())
                .font(.system(size: 18, weight: .light))
                .foregroundColor(Color("textoPrincipal"))
                .lineLimit(1)

            Spacer()

            // --- BOTÓN COMPARTIR (AHORA FUNCIONAL) ---
            Button {
                // Llama a la función que inicia el proceso de compartir
                shareButtonTapped()
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(Color("textoPrincipal"))
                    .font(.title2)
            }
            .padding(.trailing, 8)

            // Menú Ordenar (sin cambios)
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

    // --- Secciones de Búsqueda y Filtros (sin cambios funcionales) ---
    private var searchSection: some View {
        VStack {
            TextField("Buscar perfume o marca...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.bottom, 8)
    }

    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // ... (todos los filterCategoryAccordion y sliders sin cambios) ...
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

    // --- Vistas de Filtros (sin cambios) ---
    // ... filterCategoryAccordion, filterRatingSliderAccordion, etc. ...
    // ... ratingSlider, perfumePopularitySlider, filterCategoryGrid, FilterButton ...
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

    // Struct FilterButton (sin cambios)
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


    // MARK: - Vistas de Contenido (sin cambios)
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
                    showPopularity: true // O decide si mostrar rating o popularidad aquí
                )
                .onTapGesture {
                    // Lógica de navegación si es necesaria
                    print("Tapped on: \(item.perfume.name)")
                }
            }
        }
    }

    // MARK: - Lógica de Mapeo, Filtros y Ordenación (sin cambios)
    // ... mapInputToDisplayItems, applyFiltersAndSort, clearFilters, toggleFilter, isSelected, sortDisplayItems ...
    private func mapInputToDisplayItems() {
        print("Intentando mapear \(triedPerfumesInput.count) records a display items...")
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

                let matchesSeason = selectedFilters["Temporada Recomendada"]?.isEmpty ?? true || !Set(selectedFilters["Temporada Recomendada"]!).intersection(Set(perfume.recommendedSeason.compactMap { Season(rawValue: $0)?.rawValue })).isEmpty

                let matchesProjection = selectedFilters["Proyección"]?.isEmpty ?? true || selectedFilters["Proyección"]!.contains(perfume.projection)

                let matchesDuration = selectedFilters["Duración"]?.isEmpty ?? true || selectedFilters["Duración"]!.contains(perfume.duration)

                let matchesPrice = selectedFilters["Precio"]?.isEmpty ?? true || selectedFilters["Precio"]!.contains(perfume.price ?? "")

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
            return items.sorted { $0.perfume.name < $1.perfume.name }
        case .nameDescending:
            return items.sorted { $0.perfume.name > $1.perfume.name }
        case .none:
            return items
        }
    }


    // MARK: - FUNCIONALIDAD DE COMPARTIR

    /// Orquesta el proceso de compartir: obtiene datos, genera imagen y texto, y muestra el share sheet.
    private func shareButtonTapped() {
        let topItems = Array(filteredAndSortedDisplayItems.prefix(5))
        
        guard !topItems.isEmpty else {
            print("No hay items para compartir.")
            // Opcional: Mostrar una alerta al usuario indicando que no hay nada que compartir
            return
        }
        
        let imageSize = CGSize(width: 400, height: 600) // Ejemplo: Tamaño moderado
        
        let shareView = TopPerfumesShareView(
            items: topItems,
            selectedFilters: selectedFilters, // Pasa el diccionario de filtros
            ratingRange: ratingRange,         // Pasa el rango de rating
            perfumePopularityRange: perfumePopularityRange, // Pasa el rango de popularidad
            searchText: searchText            // Pasa el texto de búsqueda
        )
            .environmentObject(brandViewModel) // Sigue pasando los env objects necesarios
            .frame(width: imageSize.width, height: imageSize.height)
        
        Task { // Ejecuta la renderización y presentación en una Task asíncrona
            // Renderiza la vista a UIImage
            guard let generatedImage = await renderViewToImage(view: shareView, size: imageSize) else {
                print("Error al generar la imagen para compartir.")
                // Opcional: Mostrar error al usuario
                return
            }
            
            // Genera el texto descriptivo
            let shareText = generateShareText(count: topItems.count)
            
            // Muestra el Share Sheet en el hilo principal
            await MainActor.run {
                showShareSheet(image: generatedImage, text: shareText)
            }
        }
    }
    
    /// Renderiza una vista SwiftUI a un UIImage usando ImageRenderer.
    /// Debe ejecutarse en el hilo principal.
    @MainActor
    private func renderViewToImage(view: some View, size: CGSize) async -> UIImage? {
        let renderer = ImageRenderer(content: view)
        // Configura la escala para la calidad deseada (2.0 o 3.0 para Retina)
        renderer.scale = UIScreen.main.scale
        // El tamaño ya está aplicado a la 'view' a través del .frame() antes de pasarla.
        // renderer.proposedSize = ProposedViewSize(width: size.width, height: size.height) // Redundante si ya tiene frame
        
        // Retorna el UIImage generado
        print("Imagen generada para compartir.")
        return renderer.uiImage
    }
    
    /// Genera un texto descriptivo basado en los filtros activos.
    private func generateShareText(count: Int) -> String {
        var baseText = "¡Mira mis \(count) perfumes probados favoritos!"
        var filterDescriptions: [String] = []
        
        // Añade descripciones basadas en filtros activos
        if let genders = selectedFilters["Género"], !genders.isEmpty {
            // Usar displayName si está disponible en tu enum Gender
            let genderNames = genders.compactMap { Gender(rawValue: $0)?.displayName ?? $0 }
            filterDescriptions.append("de \(genderNames.joined(separator: "/"))")
        }
        if let familiesKeys = selectedFilters["Familia Olfativa"], !familiesKeys.isEmpty {
            // Intenta obtener nombres completos de familias desde el ViewModel
            let familyNames = familiesKeys.compactMap { key in
                familyViewModel.familias.first { $0.key == key }?.name ?? key
            }
            filterDescriptions.append("de la familia \(familyNames.joined(separator: "/"))")
        }
        if let seasons = selectedFilters["Temporada Recomendada"], !seasons.isEmpty {
            let seasonNames = seasons.compactMap { Season(rawValue: $0)?.displayName ?? $0 }
            filterDescriptions.append("para \(seasonNames.joined(separator: "/"))")
        }
        // Puedes añadir más filtros si lo deseas (Proyección, Duración, etc.)
        
        // Une las descripciones
        if !filterDescriptions.isEmpty {
            baseText += " " + filterDescriptions.joined(separator: ", ") + "."
        } else {
            baseText += "." // Si no hay filtros, solo añade el punto final.
        }
        
        // Opcional: Añade un hashtag o enlace a tu app
        // baseText += "\n\n#MisPerfumes #NombreDeTuApp"
        // baseText += "\nDescúbrelos en [Enlace a tu App]"
        
        print("Texto generado para compartir: \(baseText)")
        return baseText
    }
    
    /// Muestra el UIActivityViewController (Share Sheet).
    /// Debe ejecutarse en el hilo principal.
    @MainActor
    private func showShareSheet(image: UIImage, text: String) {
        // Encuentra la escena activa y el view controller raíz
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            print("Error: No se pudo obtener el root view controller para presentar el Share Sheet.")
            return
        }
        
        let activityItems: [Any] = [image, text] // Elementos a compartir
        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        
        // Encuentra el view controller que está presentando actualmente (para modales, sheets, etc.)
        var presentingController = rootViewController
        while let presented = presentingController.presentedViewController {
            presentingController = presented
        }
        
        // Configuración para iPad
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = presentingController.view // Vista origen
            // Presentar desde el centro (o un botón si tuvieras una referencia)
            popoverController.sourceRect = CGRect(x: presentingController.view.bounds.midX, y: presentingController.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = [] // Sin flecha si se presenta centrado
        }
        
        // Presenta el Share Sheet
        print("Presentando Share Sheet...")
        presentingController.present(activityViewController, animated: true, completion: nil)
    }
    
    // MARK: - Acción de Borrar (sin cambios)
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
                    // Considera mostrar un error al usuario
                }
                // La actualización de la lista local debería ocurrir a través
                // de la actualización del @Published en UserViewModel si deleteTriedPerfume
                // modifica los datos publicados que se usan como triedPerfumesInput.
            }
        }
    }
}


// MARK: - Vista SwiftUI para la Imagen Compartible
struct TopPerfumesShareView: View {
    let items: [TriedPerfumeDisplayItem]
    // Necesitamos acceso al BrandViewModel para obtener los nombres de las marcas
    let selectedFilters: [String: [String]]
    let ratingRange: ClosedRange<Double>
    let perfumePopularityRange: ClosedRange<Double>
    let searchText: String
    
    // Necesitamos las rangos por defecto para saber si los actuales son diferentes
    private let defaultRatingRange: ClosedRange<Double> = 0...10
    private let defaultPerfumePopularityRange: ClosedRange<Double> = 0...10
    // --- FIN NUEVO ---
    
    @EnvironmentObject var brandViewModel: BrandViewModel
    // @EnvironmentObject var familyViewModel: FamilyViewModel // Necesario si quieres nombres de familias
    
    // --- NUEVO: Computed property para generar el subtítulo ---
    private var subtitleText: String? {
        var descriptions: [String] = []
        
        // 1. Texto de búsqueda
        if !searchText.isEmpty {
            descriptions.append("Buscando \"\(searchText)\"")
        }
        
        // 2. Filtros de categoría
        if let genders = selectedFilters["Género"], !genders.isEmpty {
            let genderNames = genders.compactMap { Gender(rawValue: $0)?.displayName ?? $0 }
            descriptions.append("Género: \(genderNames.joined(separator: "/"))")
        }
        if let familiesKeys = selectedFilters["Familia Olfativa"], !familiesKeys.isEmpty {
            // Para mostrar nombres necesitarías el familyViewModel aquí o pasar los nombres resueltos
            // Simplificación: Solo indica que hay filtro de familia
            descriptions.append("Familia(s): \(familiesKeys.joined(separator: ", "))") // O un texto más genérico
        }
        if let seasons = selectedFilters["Temporada Recomendada"], !seasons.isEmpty {
            let seasonNames = seasons.compactMap { Season(rawValue: $0)?.displayName ?? $0 }
            descriptions.append("Temporada: \(seasonNames.joined(separator: "/"))")
        }
        // Añade aquí Proyección, Duración, Precio si quieres ser exhaustivo
        
        // 3. Filtros de rango
        if ratingRange != defaultRatingRange {
            descriptions.append("Rating: \(Int(ratingRange.lowerBound))-\(Int(ratingRange.upperBound))")
        }
        if perfumePopularityRange != defaultPerfumePopularityRange {
            descriptions.append("Popularidad: \(Int(perfumePopularityRange.lowerBound))-\(Int(perfumePopularityRange.upperBound))")
        }
        
        // 4. Componer el subtítulo final
        if descriptions.isEmpty {
            return nil // No hay filtros activos, no mostrar subtítulo
        } else {
            // Une las descripciones con un separador
            return descriptions.joined(separator: " • ")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) { // Ajusta el espaciado
            // Título de la imagen
            Text("Mis Perfumes Probados Favoritos")
                .font(.system(size: 24, weight: .bold)) // Tamaño de título adecuado
                .padding(.bottom, 8)

            if let subtitle = subtitleText {
                Text(subtitle)
                    .font(.system(size: 14)) // Más pequeño que el título
                    .foregroundColor(.secondary) // Color menos prominente
                    .lineLimit(2) // Limitar a 2 líneas por si es muy largo
                    .padding(.bottom, 8) // Espacio antes de la lista
            }
            
            // Lista de perfumes
            ForEach(items) { item in
                HStack(spacing: 12) { // Espaciado entre imagen y texto
                    // Imagen del perfume (Usando Kingfisher)
                    KFImage(URL(string: item.perfume.imageURL ?? ""))
                         .placeholder { // Placeholder mientras carga o si falla
                             Image(systemName: "photo") // Icono genérico
                                 .resizable()
                                 .scaledToFit()
                                 .frame(width: 50, height: 50)
                                 .foregroundColor(.gray)
                                 .background(Color.gray.opacity(0.1))
                                 .clipShape(RoundedRectangle(cornerRadius: 8))
                         }
                         .resizable()
                         .aspectRatio(contentMode: .fill) // Rellena el espacio
                         .frame(width: 60, height: 60)     // Tamaño de la miniatura
                         .clipShape(RoundedRectangle(cornerRadius: 10)) // Esquinas redondeadas
                         .clipped() // Evita que la imagen se salga del frame

                    // Información del perfume
                    VStack(alignment: .leading, spacing: 2) { // Menor espaciado vertical
                        Text(item.perfume.name)
                            .font(.system(size: 16, weight: .semibold)) // Nombre destacado
                            .lineLimit(1) // Evita múltiples líneas para nombres largos
                        Text(brandViewModel.getBrand(byKey: item.perfume.brand)?.name ?? item.perfume.brand)
                            .font(.system(size: 14)) // Marca un poco más pequeña
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        // Rating personal si existe
                        if let rating = item.record.rating {
                            HStack(spacing: 3) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.orange)
                                    .font(.caption) // Icono pequeño
                                Text("\(rating, specifier: "%.1f") / 10")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.orange)
                            }
                            .padding(.top, 1) // Pequeño espacio antes del rating
                        }
                    }
                    Spacer() // Empuja el contenido a la izquierda
                }
                 // Separador entre items (excepto después del último)
                 if item.id != items.last?.id {
                     Divider().padding(.leading, 72) // Alineado aprox. con el texto (60 + 12)
                 }
            }
            Spacer() // Empuja todo el contenido hacia arriba

            // Opcional: Pie de página o marca de agua
            Text("Compartido desde [Nombre de tu App]")
                .font(.caption2)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 10)

        }
        .padding(20) // Padding generoso alrededor del contenido
        .background(Color(UIColor.systemBackground)) // Fondo sólido (importante para renderizar)
        // El `.frame()` se aplica al instanciar esta vista antes de renderizarla.
    }
}
