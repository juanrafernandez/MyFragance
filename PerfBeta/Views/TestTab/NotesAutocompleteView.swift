import SwiftUI

/// Vista de autocompletar para búsqueda de notas olfativas con selección múltiple
struct NotesAutocompleteView: View {
    @EnvironmentObject var notesViewModel: NotesViewModel
    @Binding var selectedNoteKeys: [String]
    @Binding var searchText: String

    let placeholder: String
    let maxSelection: Int
    let showSkipOption: Bool
    let skipOptionLabel: String
    @Binding var didSkip: Bool

    @State private var showingSuggestions = false
    @State private var suggestions: [Notes] = []
    @FocusState private var isFocused: Bool

    init(
        selectedNoteKeys: Binding<[String]>,
        searchText: Binding<String>,
        didSkip: Binding<Bool>,
        placeholder: String,
        maxSelection: Int,
        showSkipOption: Bool,
        skipOptionLabel: String
    ) {
        self._selectedNoteKeys = selectedNoteKeys
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
            selectedNotesView
        }
        .onAppear {
            Task {
                if notesViewModel.notes.isEmpty {
                    await notesViewModel.loadInitialData()
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
        if !selectedNoteKeys.isEmpty && !didSkip {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color("champan"))

                Text("\(selectedNoteKeys.count)/\(maxSelection) notas seleccionadas")
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(Color("textoSecundario"))

                Spacer()
            }
        }
    }

    @ViewBuilder
    private var skipButton: some View {
        Button(action: {
            didSkip.toggle()
            if didSkip {
                selectedNoteKeys.removeAll()
                searchText = ""
                showingSuggestions = false
            }
        }) {
            HStack {
                Image(systemName: didSkip ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(didSkip ? Color("champan") : Color("textoSecundario"))

                Text(skipOptionLabel)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(didSkip ? Color("champan") : Color("textoPrincipal"))

                Spacer()
            }
            .padding(12)
            .background(
                didSkip
                    ? Color("champan").opacity(0.1)
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
                        ForEach(suggestions.prefix(15)) { note in
                            noteSuggestionRow(note)
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

    private func noteSuggestionRow(_ note: Notes) -> some View {
        let isSelected = selectedNoteKeys.contains(note.key)
        let canSelect = !isSelected && selectedNoteKeys.count < maxSelection

        return Button(action: {
            if isSelected {
                deselectNote(note)
            } else if canSelect {
                selectNote(note)
            }
        }) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(note.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(isSelected ? Color("champan") : Color("textoPrincipal"))

                    if let description = note.descriptionNote, !description.isEmpty {
                        Text(description)
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(Color("textoSecundario"))
                            .lineLimit(1)
                    }
                }

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
    private var selectedNotesView: some View {
        if !selectedNoteKeys.isEmpty && !didSkip {
            VStack(alignment: .leading, spacing: 8) {
                Text("Notas seleccionadas:")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color("textoPrincipal"))

                ForEach(selectedNoteKeys, id: \.self) { key in
                    if let note = notesViewModel.notes.first(where: { $0.key == key }) {
                        selectedNoteRow(note)
                    }
                }
            }
            .padding(.top, 8)
        }
    }

    private func selectedNoteRow(_ note: Notes) -> some View {
        HStack {
            Text(note.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color("champan"))

            Spacer()

            Button(action: {
                deselectNote(note)
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

        // Buscar notas que coincidan
        let results = notesViewModel.notes.filter { note in
            let name = note.name
                .lowercased()
                .folding(options: .diacriticInsensitive, locale: .current)

            return name.contains(normalizedQuery)
        }

        // Ordenar por relevancia
        suggestions = results.sorted { note1, note2 in
            let name1 = note1.name
                .lowercased()
                .folding(options: .diacriticInsensitive, locale: .current)
            let name2 = note2.name
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
        print("🔍 [NotesAutocomplete] Query: '\(query)' → \(suggestions.count) results")
        if !suggestions.isEmpty {
            print("   Top 5: \(suggestions.prefix(5).map { $0.name }.joined(separator: ", "))")
        }
        #endif
    }

    private func selectNote(_ note: Notes) {
        guard selectedNoteKeys.count < maxSelection else {
            #if DEBUG
            print("⚠️ [NotesAutocomplete] Max selection reached (\(maxSelection))")
            #endif
            return
        }

        guard !selectedNoteKeys.contains(note.key) else {
            #if DEBUG
            print("⚠️ [NotesAutocomplete] Note already selected: \(note.name)")
            #endif
            return
        }

        selectedNoteKeys.append(note.key)
        searchText = ""
        showingSuggestions = false
        isFocused = false

        #if DEBUG
        print("✅ [NotesAutocomplete] Selected: \(note.name) (\(selectedNoteKeys.count)/\(maxSelection))")
        #endif
    }

    private func deselectNote(_ note: Notes) {
        selectedNoteKeys.removeAll { $0 == note.key }

        #if DEBUG
        print("❌ [NotesAutocomplete] Deselected: \(note.name) (\(selectedNoteKeys.count)/\(maxSelection))")
        #endif
    }
}

// MARK: - Preview
// Preview temporalmente deshabilitado
