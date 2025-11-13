import SwiftUI

/// Vista de autocompletar para búsqueda de perfumes
struct PerfumeAutocompleteView: View {
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @Binding var selectedPerfumeKey: String?
    @Binding var searchText: String

    let placeholder: String

    @State private var showingSuggestions = false
    @State private var suggestions: [PerfumeMetadata] = []
    @FocusState private var isFocused: Bool

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
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .onChange(of: searchText) { oldValue, newValue in
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

        let lowercasedQuery = query.lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)

        // Buscar en metadata
        let results = perfumeViewModel.metadataIndex.filter { perfume in
            let name = perfume.name.lowercased()
                .folding(options: .diacriticInsensitive, locale: .current)
            let brand = perfume.brand.lowercased()
                .folding(options: .diacriticInsensitive, locale: .current)

            return name.contains(lowercasedQuery) || brand.contains(lowercasedQuery)
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

            // Prioridad 1: Nombre empieza con query
            let nameStarts1 = name1.hasPrefix(lowercasedQuery)
            let nameStarts2 = name2.hasPrefix(lowercasedQuery)
            if nameStarts1 != nameStarts2 {
                return nameStarts1
            }

            // Prioridad 2: Marca empieza con query
            let brandStarts1 = brand1.hasPrefix(lowercasedQuery)
            let brandStarts2 = brand2.hasPrefix(lowercasedQuery)
            if brandStarts1 != brandStarts2 {
                return brandStarts1
            }

            // Prioridad 3: Popularidad
            return (perfume1.popularity ?? 0) > (perfume2.popularity ?? 0)
        }

        showingSuggestions = !suggestions.isEmpty

        #if DEBUG
        print("🔍 [Autocomplete] Query: '\(query)' (normalized: '\(lowercasedQuery)') → \(suggestions.count) results")
        if !suggestions.isEmpty {
            print("   Top 3 results:")
            for (index, perfume) in suggestions.prefix(3).enumerated() {
                let name = perfume.name.lowercased().folding(options: .diacriticInsensitive, locale: .current)
                let brand = perfume.brand.lowercased().folding(options: .diacriticInsensitive, locale: .current)
                let nameMatch = name.hasPrefix(lowercasedQuery) ? "★ Name" : name.contains(lowercasedQuery) ? "✓ Name" : ""
                let brandMatch = brand.hasPrefix(lowercasedQuery) ? "★ Brand" : brand.contains(lowercasedQuery) ? "✓ Brand" : ""
                print("   \(index + 1). \(perfume.name) - \(perfume.brand) [\(nameMatch)\(nameMatch.isEmpty ? "" : " ")\(brandMatch)] (pop: \(perfume.popularity ?? 0))")
            }
        }
        #endif
    }

    private func selectPerfume(_ perfume: PerfumeMetadata) {
        selectedPerfumeKey = perfume.key
        searchText = "\(perfume.name) - \(perfume.brand)"
        showingSuggestions = false
        isFocused = false

        #if DEBUG
        print("✅ [Autocomplete] Selected: \(perfume.name) (\(perfume.key))")
        #endif
    }

    private func clearSelection() {
        selectedPerfumeKey = nil
        searchText = ""
        suggestions = []
        showingSuggestions = false
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
                placeholder: "Ej: Sauvage Dior"
            )
            .environmentObject(PerfumeViewModel(
                perfumeService: DependencyContainer.shared.perfumeService
            ))
            .padding()
        }
    }
}
