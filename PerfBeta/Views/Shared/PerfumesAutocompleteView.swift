import SwiftUI

/// Vista de autocompletar para búsqueda de perfumes con selección múltiple
struct PerfumesAutocompleteView: View {
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @Binding var selectedPerfumeKeys: [String]
    @Binding var searchText: String

    let placeholder: String
    let maxSelection: Int
    let showSkipOption: Bool
    let skipOptionLabel: String
    @Binding var didSkip: Bool

    @State private var showingSuggestions = false
    @State private var suggestions: [PerfumeMetadata] = []
    @FocusState private var isFocused: Bool

    init(
        selectedPerfumeKeys: Binding<[String]>,
        searchText: Binding<String>,
        didSkip: Binding<Bool>,
        placeholder: String,
        maxSelection: Int,
        showSkipOption: Bool,
        skipOptionLabel: String
    ) {
        self._selectedPerfumeKeys = selectedPerfumeKeys
        self._searchText = searchText
        self._didSkip = didSkip
        self.placeholder = placeholder
        self.maxSelection = maxSelection
        self.showSkipOption = showSkipOption
        self.skipOptionLabel = skipOptionLabel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            searchField
            selectionCounter

            if showSkipOption {
                skipButton
            }

            suggestionsView
            selectedPerfumesView
        }
        .onAppear {
            // PerfumeViewModel ya está cargado desde MainTabView
        }
    }

    // MARK: - Subviews

    private var searchField: some View {
        ZStack(alignment: .leading) {
            if searchText.isEmpty {
                Text(placeholder)
                    .foregroundColor(AppColor.textSecondary.opacity(0.5))
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
                        .stroke(AppColor.brandAccent.opacity(0.3), lineWidth: 1.5)
                )
                .onChange(of: searchText) { oldValue, newValue in
                    performSearch(query: newValue)
                }
        }
    }

    @ViewBuilder
    private var selectionCounter: some View {
        if !selectedPerfumeKeys.isEmpty && !didSkip {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(AppColor.brandAccent)

                Text("\(selectedPerfumeKeys.count)/\(maxSelection) perfumes seleccionados")
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(AppColor.textSecondary)

                Spacer()
            }
        }
    }

    @ViewBuilder
    private var skipButton: some View {
        Button(action: {
            didSkip.toggle()
            if didSkip {
                selectedPerfumeKeys.removeAll()
                searchText = ""
                showingSuggestions = false
            }
        }) {
            HStack {
                Image(systemName: didSkip ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(didSkip ? AppColor.brandAccent : AppColor.textSecondary)

                Text(skipOptionLabel)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(didSkip ? AppColor.brandAccent : AppColor.textPrimary)

                Spacer()
            }
            .padding(12)
            .background(
                didSkip
                    ? AppColor.brandAccent.opacity(0.1)
                    : Color.white.opacity(0.05)
            )
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }

    @ViewBuilder
    private var suggestionsView: some View {
        if showingSuggestions && !suggestions.isEmpty && !didSkip {
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(suggestions.prefix(15)) { perfume in
                            perfumeSuggestionRow(perfume)
                        }
                    }
                    .padding(8)
                }
                .frame(maxHeight: 300)

                if suggestions.count > 15 {
                    HStack {
                        Spacer()
                        Text("+ \(suggestions.count - 15) más")
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(AppColor.textSecondary)
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

    private func perfumeSuggestionRow(_ perfume: PerfumeMetadata) -> some View {
        let isSelected = selectedPerfumeKeys.contains(perfume.key)
        let canSelect = !isSelected && selectedPerfumeKeys.count < maxSelection

        return Button(action: {
            if isSelected {
                deselectPerfume(perfume)
            } else if canSelect {
                selectPerfume(perfume)
            }
        }) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(perfume.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(isSelected ? AppColor.brandAccent : AppColor.textPrimary)

                    Text(perfume.brand)
                        .font(.system(size: 12, weight: .light))
                        .foregroundColor(AppColor.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColor.brandAccent)
                } else if !canSelect {
                    Image(systemName: "lock.circle.fill")
                        .foregroundColor(AppColor.textSecondary.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                isSelected
                    ? AppColor.brandAccent.opacity(0.1)
                    : Color.white.opacity(0.05)
            )
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isSelected && !canSelect)
    }

    @ViewBuilder
    private var selectedPerfumesView: some View {
        if !selectedPerfumeKeys.isEmpty && !didSkip {
            VStack(alignment: .leading, spacing: 8) {
                Text("Perfumes seleccionados:")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppColor.textPrimary)

                ForEach(selectedPerfumeKeys, id: \.self) { key in
                    if let perfume = perfumeViewModel.metadataIndex.first(where: { $0.key == key }) {
                        selectedPerfumeRow(perfume)
                    }
                }
            }
            .padding(.top, 8)
        }
    }

    private func selectedPerfumeRow(_ perfume: PerfumeMetadata) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(perfume.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColor.brandAccent)

                Text(perfume.brand)
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(AppColor.textSecondary)
            }

            Spacer()

            Button(action: {
                deselectPerfume(perfume)
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(AppColor.textSecondary)
            }
        }
        .padding(12)
        .background(AppColor.brandAccent.opacity(0.1))
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

        // Buscar perfumes que coincidan en nombre o marca
        let results = perfumeViewModel.metadataIndex.filter { perfume in
            let name = perfume.name
                .lowercased()
                .folding(options: .diacriticInsensitive, locale: .current)

            let brand = perfume.brand
                .lowercased()
                .folding(options: .diacriticInsensitive, locale: .current)

            return name.contains(normalizedQuery) || brand.contains(normalizedQuery)
        }

        // Ordenar por relevancia
        suggestions = results.sorted { perfume1, perfume2 in
            let name1 = perfume1.name
                .lowercased()
                .folding(options: .diacriticInsensitive, locale: .current)
            let name2 = perfume2.name
                .lowercased()
                .folding(options: .diacriticInsensitive, locale: .current)

            // Prioridad 1: Empieza con el query
            let starts1 = name1.hasPrefix(normalizedQuery)
            let starts2 = name2.hasPrefix(normalizedQuery)
            if starts1 != starts2 {
                return starts1
            }

            // Prioridad 2: Popularidad
            let pop1 = perfume1.popularity ?? 0
            let pop2 = perfume2.popularity ?? 0
            if pop1 != pop2 {
                return pop1 > pop2
            }

            // Prioridad 3: Orden alfabético
            return name1 < name2
        }

        showingSuggestions = !suggestions.isEmpty

        #if DEBUG
        print("🔍 [PerfumesAutocomplete] Query: '\(query)' → \(suggestions.count) results")
        if !suggestions.isEmpty {
            print("   Top 5: \(suggestions.prefix(5).map { "\($0.name) (\($0.brand))" }.joined(separator: ", "))")
        }
        #endif
    }

    private func selectPerfume(_ perfume: PerfumeMetadata) {
        guard selectedPerfumeKeys.count < maxSelection else {
            #if DEBUG
            print("⚠️ [PerfumesAutocomplete] Max selection reached (\(maxSelection))")
            #endif
            return
        }

        guard !selectedPerfumeKeys.contains(perfume.key) else {
            #if DEBUG
            print("⚠️ [PerfumesAutocomplete] Perfume already selected: \(perfume.name)")
            #endif
            return
        }

        selectedPerfumeKeys.append(perfume.key)
        searchText = ""
        showingSuggestions = false
        isFocused = false

        #if DEBUG
        print("✅ [PerfumesAutocomplete] Selected: \(perfume.name) (\(selectedPerfumeKeys.count)/\(maxSelection))")
        #endif
    }

    private func deselectPerfume(_ perfume: PerfumeMetadata) {
        selectedPerfumeKeys.removeAll { $0 == perfume.key }

        #if DEBUG
        print("❌ [PerfumesAutocomplete] Deselected: \(perfume.name) (\(selectedPerfumeKeys.count)/\(maxSelection))")
        #endif
    }
}

// MARK: - Preview
// Preview temporalmente deshabilitado
