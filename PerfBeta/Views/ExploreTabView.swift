import SwiftUI

struct ExploreTabView: View {
    @State private var searchText = ""
    @State private var isFilterExpanded = false // La sección de filtros comienza contraída
    @State private var selectedFilters: [String: [String]] = [:] // Almacena los filtros seleccionados
    @State private var perfumes = PerfumeManager().getAllPerfumes() // Resultados filtrados
    @State private var selectedPerfume: Perfume? = nil // Perfume seleccionado
    @State private var isShowingDetail = false // Controla si se muestra la ficha del perfume

    var body: some View {
        NavigationView {
            VStack {
                // Encabezado
                headerView
                
                // Ocultar barra de búsqueda y filtros si están contraídos
                if isFilterExpanded {
                    searchSection
                    filterSection
                }
                
                // Botón para contraer/expandir filtros
                Button(action: {
                    withAnimation {
                        isFilterExpanded.toggle()
                    }
                }) {
                    Text(isFilterExpanded ? "Ocultar Filtros" : "Mostrar Filtros")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()

                    // Mostrar "Limpiar Filtros" solo si hay filtros seleccionados o texto en la búsqueda
                    if !selectedFilters.isEmpty || !searchText.isEmpty {
                        Button(action: clearFilters) {
                            Text("Limpiar Filtros")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding(.vertical, 8)
                
                // Resultados
                resultsSection
            }
            .padding(.horizontal) // Padding global respetando Safe Area
            .navigationBarTitleDisplayMode(.inline)
            .background(Color("fondoClaro").edgesIgnoringSafeArea(.all))
            .fullScreenCover(item: $selectedPerfume) { perfume in
                PerfumeDetailView(
                    perfume: perfume,
                    relatedPerfumes: PerfumeManager().getAllPerfumes().filter { $0.id != perfume.id } // Perfumes relacionados
                )
            }
        }
    }
    
    // MARK: - Encabezado
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Encuentra tu Perfume Ideal")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color("textoPrincipal"))
        }
        .padding(.top, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Barra de Búsqueda
    private var searchSection: some View {
        VStack {
            TextField("Escribe una nota, marca o familia olfativa...", text: $searchText, onCommit: filterResults)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Filtros
    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            filterCategory(title: "Género", options: ["Masculino", "Femenino", "Unisex"])
            filterCategory(title: "Familia Olfativa", options: ["Amaderados", "Florales", "Cítricos", "Orientales", "Verdes"])
            filterCategory(title: "Ingredientes", options: ["Vainilla", "Sándalo", "Cacao", "Limón", "Rosa", "Incienso"])
        }
        .padding(.vertical, 8)
    }
    
    private func filterCategory(title: String, options: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color("textoSecundario"))
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(options, id: \.self) { option in
                    Button(action: {
                        toggleFilter(category: title, option: option)
                    }) {
                        Text(option)
                            .font(.system(size: 14))
                            .frame(minWidth: 120, minHeight: 30)
                            .foregroundColor(isSelected(category: title, option: option) ? .white : Color("textoPrincipal"))
                            .background(isSelected(category: title, option: option) ? Color("champan") : Color("grisSuave"))
                            .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    private func toggleFilter(category: String, option: String) {
        if selectedFilters[category]?.contains(option) == true {
            // Si ya está seleccionado, lo eliminamos
            selectedFilters[category]?.removeAll(where: { $0 == option })
            if selectedFilters[category]?.isEmpty == true {
                selectedFilters.removeValue(forKey: category)
            }
        } else {
            // Si no está seleccionado, lo agregamos
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
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
                ForEach(perfumes) { perfume in
                    resultCard(for: perfume)
                        .onTapGesture {
                            selectedPerfume = perfume // Abrir ficha del perfume
                        }
                }
            }
        }
    }
    
    private func resultCard(for perfume: Perfume) -> some View {
        VStack {
            Image(perfume.imagenURL)
                .resizable()
                .scaledToFit()
                .frame(height: 120)
                .cornerRadius(8)
            
            Text(perfume.nombre)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color("textoPrincipal"))
                .lineLimit(1)
            
            Text(perfume.familia.capitalized)
                .font(.system(size: 12))
                .foregroundColor(Color("textoSecundario"))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Limpiar Filtros
    private func clearFilters() {
        searchText = ""
        selectedFilters.removeAll()
        filterResults()
    }
    
    // MARK: - Filtrar Resultados
    // Filtrar resultados basados en los filtros seleccionados y el texto de búsqueda
    private func filterResults() {
        // Forzar el tipo explícito
        let allPerfumes = PerfumeManager().getAllPerfumes()
        perfumes = allPerfumes.filter { perfume in
            var matches = true
            
            // Filtrar por Género
            if let genders = selectedFilters["Género"], !genders.isEmpty {
                matches = matches && genders.contains(perfume.genero.capitalized)
            }
            
            // Filtrar por Familia Olfativa
            if let families = selectedFilters["Familia Olfativa"], !families.isEmpty {
                matches = matches && families.contains(perfume.familia.capitalized)
            }
            
            // Filtrar por Ingredientes
            if let ingredients = selectedFilters["Ingredientes"], !ingredients.isEmpty {
                let selectedSet = Set(ingredients.map { $0.lowercased() })
                let notesSet = Set(perfume.notasSalida.map { $0.lowercased() } +
                                   perfume.notasCorazon.map { $0.lowercased() } +
                                   perfume.notasFondo.map { $0.lowercased() })
                matches = matches && !selectedSet.intersection(notesSet).isEmpty
            }
            
            // Filtrar por texto de búsqueda
            if !searchText.isEmpty {
                matches = matches && perfume.nombre.lowercased().contains(searchText.lowercased())
            }
            
            return matches
        }
    }



}
