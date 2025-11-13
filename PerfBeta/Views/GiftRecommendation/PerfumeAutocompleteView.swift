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
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(suggestions.prefix(5)) { perfume in
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
                }
                .frame(maxHeight: 250)
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

        // Ordenar por relevancia (nombre exacto primero, luego popularidad)
        suggestions = results.sorted { perfume1, perfume2 in
            let name1 = perfume1.name.lowercased()
            let name2 = perfume2.name.lowercased()

            // Coincidencia exacta al inicio tiene prioridad
            let starts1 = name1.hasPrefix(lowercasedQuery)
            let starts2 = name2.hasPrefix(lowercasedQuery)

            if starts1 != starts2 {
                return starts1
            }

            // Si ambos coinciden igual, ordenar por popularidad
            return (perfume1.popularity ?? 0) > (perfume2.popularity ?? 0)
        }

        showingSuggestions = !suggestions.isEmpty

        #if DEBUG
        print("🔍 [Autocomplete] Query: '\(query)' → \(suggestions.count) results")
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
                perfumeService: DependencyContainer.shared.perfumeService,
                authService: DependencyContainer.shared.authService
            ))
            .padding()
        }
    }
}
