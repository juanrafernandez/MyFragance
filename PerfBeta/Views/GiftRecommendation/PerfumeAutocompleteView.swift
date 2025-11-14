import SwiftUI

/// Vista de autocompletar para búsqueda de perfumes
struct PerfumeAutocompleteView: View {
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @Binding var selectedPerfumeKey: String?
    @Binding var searchText: String

    let placeholder: String
    let filterGender: String?  // ✅ Filtro de género

    @State private var showingSuggestions = false
    @State private var suggestions: [PerfumeMetadata] = []
    @FocusState private var isFocused: Bool
    @State private var isProgrammaticUpdate = false  // ✅ Flag para evitar limpiar en selección programática

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Campo de búsqueda
            ZStack(alignment: .leading) {
                if searchText.isEmpty {
                    Text(placeholder)
                        .foregroundColor(Color("textoSecundario").opacity(0.5))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                }

                TextField("", text: $searchText)
                    .focused($isFocused)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color("champan").opacity(0.3), lineWidth: 1.5)  // ✅ Borde champán visible
                    )
                    .onChange(of: searchText) { oldValue, newValue in
                        // ✅ No limpiar si es actualización programática (cuando se selecciona un perfume)
                        guard !isProgrammaticUpdate else {
                            performSearch(query: newValue)
                            return
                        }

                        // Si el usuario modifica el texto manualmente, limpiar selección
                        if selectedPerfumeKey != nil {
                            selectedPerfumeKey = nil
                        }
                        performSearch(query: newValue)
                    }
            }

            // Lista de sugerencias
            if showingSuggestions && !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(suggestions.prefix(10)) { perfume in
                                Button(action: {
                                    selectPerfume(perfume)
                                }) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(perfume.name)
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(Color("textoPrincipal"))

                                        Text(perfume.brand)
                                            .font(.system(size: 13, weight: .light))
                                            .foregroundColor(Color("textoSecundario"))
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(Color.white.opacity(0.05))
                                    .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(8)
                    }
                    .frame(maxHeight: 300)

                    // Indicador de más resultados
                    if suggestions.count > 10 {
                        HStack {
                            Spacer()
                            Text("+ \(suggestions.count - 10) más")
                                .font(.system(size: 12, weight: .light))
                                .foregroundColor(Color("textoSecundario"))
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.05))
                    }
                }
                .background(Color.black.opacity(0.3))
                .cornerRadius(8)
                .padding(.top, 4)
            }

            // Perfume seleccionado
            if let key = selectedPerfumeKey,
               let perfume = suggestions.first(where: { $0.key == key }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("✓ Seleccionado:")
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(Color("textoSecundario"))

                        Text("\(perfume.name) - \(perfume.brand)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color("champan"))
                    }

                    Spacer()

                    Button(action: {
                        clearSelection()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color("textoSecundario"))
                    }
                }
                .padding(12)
                .background(Color("champan").opacity(0.1))
                .cornerRadius(8)
                .padding(.top, 8)
            }
        }
        .onAppear {
            // Cargar metadata si no está cargada
            Task {
                if perfumeViewModel.metadataIndex.isEmpty {
                    await perfumeViewModel.loadMetadataIndex()
                }
            }
        }
    }

    // MARK: - Methods

    private func performSearch(query: String) {
        guard !query.isEmpty else {
            suggestions = []
            showingSuggestions = false
            selectedPerfumeKey = nil
            return
        }

        // Dividir query en palabras y normalizar cada una
        let queryWords = query
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .split(separator: " ")
            .map { String($0) }
            .filter { !$0.isEmpty }

        guard !queryWords.isEmpty else {
            suggestions = []
            showingSuggestions = false
            return
        }

        // Buscar en metadata - cada palabra debe aparecer en nombre O marca
        let results = perfumeViewModel.metadataIndex.filter { perfume in
            let name = perfume.name.lowercased()
                .folding(options: .diacriticInsensitive, locale: .current)
            let brand = perfume.brand.lowercased()
                .folding(options: .diacriticInsensitive, locale: .current)

            // ✅ Filtrar por género si está especificado
            if let gender = filterGender {
                let perfumeGender = perfume.gender.lowercased()
                let targetGender = gender.lowercased()

                // Permitir perfumes del género seleccionado O unisex
                let genderMatch = perfumeGender == targetGender || perfumeGender == "unisex"
                if !genderMatch {
                    return false
                }
            }

            // Todas las palabras deben aparecer (en nombre o marca)
            return queryWords.allSatisfy { word in
                name.contains(word) || brand.contains(word)
            }
        }

        // Ordenar por relevancia mejorada
        suggestions = results.sorted { perfume1, perfume2 in
            let name1 = perfume1.name.lowercased()
                .folding(options: .diacriticInsensitive, locale: .current)
            let name2 = perfume2.name.lowercased()
                .folding(options: .diacriticInsensitive, locale: .current)
            let brand1 = perfume1.brand.lowercased()
                .folding(options: .diacriticInsensitive, locale: .current)
            let brand2 = perfume2.brand.lowercased()
                .folding(options: .diacriticInsensitive, locale: .current)

            // Prioridad 1: Alguna palabra del query empieza el nombre
            let nameStarts1 = queryWords.contains { name1.hasPrefix($0) }
            let nameStarts2 = queryWords.contains { name2.hasPrefix($0) }
            if nameStarts1 != nameStarts2 {
                return nameStarts1
            }

            // Prioridad 2: Alguna palabra del query empieza la marca
            let brandStarts1 = queryWords.contains { brand1.hasPrefix($0) }
            let brandStarts2 = queryWords.contains { brand2.hasPrefix($0) }
            if brandStarts1 != brandStarts2 {
                return brandStarts1
            }

            // Prioridad 3: Popularidad
            return (perfume1.popularity ?? 0) > (perfume2.popularity ?? 0)
        }

        showingSuggestions = !suggestions.isEmpty

        #if DEBUG
        let genderInfo = filterGender != nil ? " | Gender filter: \(filterGender!)" : ""
        print("🔍 [Autocomplete] Query: '\(query)' → Words: \(queryWords)\(genderInfo) → \(suggestions.count) results")
        if !suggestions.isEmpty {
            print("   Top 3 results:")
            for (index, perfume) in suggestions.prefix(3).enumerated() {
                let name = perfume.name.lowercased().folding(options: .diacriticInsensitive, locale: .current)
                let brand = perfume.brand.lowercased().folding(options: .diacriticInsensitive, locale: .current)

                // Verificar qué palabras coinciden
                var nameMatches: [String] = []
                var brandMatches: [String] = []
                for word in queryWords {
                    if name.hasPrefix(word) {
                        nameMatches.append("★\(word)")
                    } else if name.contains(word) {
                        nameMatches.append("✓\(word)")
                    }
                    if brand.hasPrefix(word) {
                        brandMatches.append("★\(word)")
                    } else if brand.contains(word) {
                        brandMatches.append("✓\(word)")
                    }
                }

                let nameStr = nameMatches.isEmpty ? "" : "Name[\(nameMatches.joined(separator: ","))]"
                let brandStr = brandMatches.isEmpty ? "" : "Brand[\(brandMatches.joined(separator: ","))]"
                print("   \(index + 1). \(perfume.name) - \(perfume.brand) [\(nameStr) \(brandStr)] (pop: \(String(format: "%.1f", perfume.popularity ?? 0)))")
            }
        }
        #endif
    }

    private func selectPerfume(_ perfume: PerfumeMetadata) {
        // ✅ Establecer flag antes de cambiar searchText para evitar limpiar la selección
        isProgrammaticUpdate = true

        selectedPerfumeKey = perfume.key
        searchText = "\(perfume.name) - \(perfume.brand)"
        showingSuggestions = false
        isFocused = false

        #if DEBUG
        print("✅ [Autocomplete] Selected: \(perfume.name) (\(perfume.key))")
        #endif

        // ✅ Resetear flag después de un breve delay para asegurar que onChange se procese
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isProgrammaticUpdate = false
        }
    }

    private func clearSelection() {
        isProgrammaticUpdate = true
        selectedPerfumeKey = nil
        searchText = ""
        suggestions = []
        showingSuggestions = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isProgrammaticUpdate = false
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        GradientView(preset: .champan)
            .edgesIgnoringSafeArea(.all)

        VStack {
            PerfumeAutocompleteView(
                selectedPerfumeKey: .constant(nil),
                searchText: .constant(""),
                placeholder: "Ej: Sauvage Dior",
                filterGender: nil
            )
            .environmentObject(PerfumeViewModel(
                perfumeService: DependencyContainer.shared.perfumeService
            ))
            .padding()
        }
    }
}
