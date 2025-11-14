import SwiftUI

/// Vista de autocompletar para búsqueda de marcas con selección múltiple
struct BrandAutocompleteView: View {
    @EnvironmentObject var brandViewModel: BrandViewModel
    @Binding var selectedBrandKeys: [String]
    @Binding var searchText: String

    let placeholder: String
    let maxSelection: Int

    @State private var showingSuggestions = false
    @State private var suggestions: [Brand] = []
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            searchField
            selectionCounter
            suggestionsView
            selectedBrandsView
        }
        .onAppear {
            Task {
                if brandViewModel.brands.isEmpty {
                    await brandViewModel.loadInitialData()
                }
            }
        }
    }

    // MARK: - Subviews

    private var searchField: some View {
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
                        .stroke(Color("champan").opacity(0.3), lineWidth: 1.5)
                )
                .onChange(of: searchText) { oldValue, newValue in
                    performSearch(query: newValue)
                }
        }
    }

    @ViewBuilder
    private var selectionCounter: some View {
        if !selectedBrandKeys.isEmpty {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color("champan"))

                Text("\(selectedBrandKeys.count)/\(maxSelection) marcas seleccionadas")
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(Color("textoSecundario"))

                Spacer()
            }
        }
    }

    @ViewBuilder
    private var suggestionsView: some View {
        if showingSuggestions && !suggestions.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(suggestions.prefix(10)) { brand in
                            brandSuggestionRow(brand)
                        }
                    }
                    .padding(8)
                }
                .frame(maxHeight: 300)

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
    }

    private func brandSuggestionRow(_ brand: Brand) -> some View {
        let isSelected = selectedBrandKeys.contains(brand.key)
        let canSelect = !isSelected && selectedBrandKeys.count < maxSelection

        return Button(action: {
            if isSelected {
                deselectBrand(brand)
            } else if canSelect {
                selectBrand(brand)
            }
        }) {
            HStack(spacing: 12) {
                Text(brand.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(isSelected ? Color("champan") : Color("textoPrincipal"))

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color("champan"))
                } else if !canSelect {
                    Image(systemName: "lock.circle.fill")
                        .foregroundColor(Color("textoSecundario").opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                isSelected
                    ? Color("champan").opacity(0.1)
                    : Color.white.opacity(0.05)
            )
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isSelected && !canSelect)
    }

    @ViewBuilder
    private var selectedBrandsView: some View {
        if !selectedBrandKeys.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Marcas seleccionadas:")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color("textoPrincipal"))

                ForEach(selectedBrandKeys, id: \.self) { key in
                    if let brand = brandViewModel.brands.first(where: { $0.key == key }) {
                        selectedBrandRow(brand)
                    }
                }
            }
            .padding(.top, 8)
        }
    }

    private func selectedBrandRow(_ brand: Brand) -> some View {
        HStack {
            Text(brand.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color("champan"))

            Spacer()

            Button(action: {
                deselectBrand(brand)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(Color("textoSecundario"))
            }
        }
        .padding(12)
        .background(Color("champan").opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Methods

    private func performSearch(query: String) {
        guard !query.isEmpty else {
            suggestions = []
            showingSuggestions = false
            return
        }

        // Normalizar query
        let normalizedQuery = query
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .trimmingCharacters(in: .whitespaces)

        // Buscar marcas que coincidan
        let results = brandViewModel.brands.filter { brand in
            let name = brand.name
                .lowercased()
                .folding(options: .diacriticInsensitive, locale: .current)

            return name.contains(normalizedQuery)
        }

        // Ordenar por relevancia
        suggestions = results.sorted { brand1, brand2 in
            let name1 = brand1.name
                .lowercased()
                .folding(options: .diacriticInsensitive, locale: .current)
            let name2 = brand2.name
                .lowercased()
                .folding(options: .diacriticInsensitive, locale: .current)

            // Prioridad 1: Empieza con el query
            let starts1 = name1.hasPrefix(normalizedQuery)
            let starts2 = name2.hasPrefix(normalizedQuery)
            if starts1 != starts2 {
                return starts1
            }

            // Prioridad 2: Orden alfabético
            return name1 < name2
        }

        showingSuggestions = !suggestions.isEmpty

        #if DEBUG
        print("🔍 [BrandAutocomplete] Query: '\(query)' → \(suggestions.count) results")
        if !suggestions.isEmpty {
            print("   Top 5: \(suggestions.prefix(5).map { $0.name }.joined(separator: ", "))")
        }
        #endif
    }

    private func selectBrand(_ brand: Brand) {
        guard selectedBrandKeys.count < maxSelection else {
            #if DEBUG
            print("⚠️ [BrandAutocomplete] Max selection reached (\(maxSelection))")
            #endif
            return
        }

        guard !selectedBrandKeys.contains(brand.key) else {
            #if DEBUG
            print("⚠️ [BrandAutocomplete] Brand already selected: \(brand.name)")
            #endif
            return
        }

        selectedBrandKeys.append(brand.key)
        searchText = ""
        showingSuggestions = false
        isFocused = false

        #if DEBUG
        print("✅ [BrandAutocomplete] Selected: \(brand.name) (\(selectedBrandKeys.count)/\(maxSelection))")
        #endif
    }

    private func deselectBrand(_ brand: Brand) {
        selectedBrandKeys.removeAll { $0 == brand.key }

        #if DEBUG
        print("❌ [BrandAutocomplete] Deselected: \(brand.name) (\(selectedBrandKeys.count)/\(maxSelection))")
        #endif
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        GradientView(preset: .champan)
            .edgesIgnoringSafeArea(.all)

        VStack {
            BrandAutocompleteView(
                selectedBrandKeys: .constant([]),
                searchText: .constant(""),
                placeholder: "Ej: Dior, Chanel, Guerlain...",
                maxSelection: 5
            )
            .environmentObject(BrandViewModel(
                brandService: DependencyContainer.shared.brandService
            ))
            .padding()
        }
    }
}
