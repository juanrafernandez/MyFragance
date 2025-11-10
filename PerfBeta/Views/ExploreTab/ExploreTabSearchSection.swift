import SwiftUI

/// Sección de búsqueda y control de filtros para ExploreTab
/// Contiene: SearchBar + Toggle filtros + Clear filters button
struct ExploreTabSearchSection: View {
    @Binding var searchText: String
    @Binding var isFilterExpanded: Bool
    let hasActiveFilters: Bool
    let onClearFilters: () -> Void
    let onSearchCommit: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            // MARK: - Search Bar
            searchBar

            // MARK: - Toggle Filtros + Clear Button
            filterToggleRow
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    private var searchBar: some View {
        TextField("Escribe una nota, marca o familia olfativa...", text: $searchText, onCommit: onSearchCommit)
            .textFieldStyle(RoundedBorderTextFieldStyle())
    }

    private var filterToggleRow: some View {
        HStack {
            // Toggle button
            Button(action: {
                withAnimation {
                    isFilterExpanded.toggle()
                }
            }) {
                Text(isFilterExpanded ? "Ocultar Filtros" : "Mostrar Filtros")
                    .font(.system(size: 14, weight: .thin))
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Clear filters button (solo si hay filtros activos)
            if hasActiveFilters {
                Button(action: onClearFilters) {
                    Text("Limpiar Filtros")
                        .font(.system(size: 14, weight: .thin))
                        .foregroundColor(.red)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack {
        ExploreTabSearchSection(
            searchText: .constant("sauvage"),
            isFilterExpanded: .constant(true),
            hasActiveFilters: true,
            onClearFilters: {},
            onSearchCommit: {}
        )
        .padding()

        Divider()

        ExploreTabSearchSection(
            searchText: .constant(""),
            isFilterExpanded: .constant(false),
            hasActiveFilters: false,
            onClearFilters: {},
            onSearchCommit: {}
        )
        .padding()
    }
    .background(Color.gray.opacity(0.1))
}
