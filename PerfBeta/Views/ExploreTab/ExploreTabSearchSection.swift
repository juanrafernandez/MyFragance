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
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundColor(AppColor.textSecondary)

            TextField("Escribe una nota, marca o familia olfativa...", text: $searchText, onCommit: onSearchCommit)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(AppColor.textPrimary)

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppColor.textSecondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppColor.textSecondary.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private var filterToggleRow: some View {
        HStack {
            // Toggle button
            Button(action: {
                withAnimation {
                    isFilterExpanded.toggle()
                }
            }) {
                HStack(spacing: 4) {
                    Text(isFilterExpanded ? "Ocultar Filtros" : "Mostrar Filtros")
                        .font(.system(size: 13, weight: .medium))
                    Image(systemName: isFilterExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(AppColor.brandAccent)
            }

            Spacer()

            // Clear filters button (solo si hay filtros activos)
            if hasActiveFilters {
                Button(action: onClearFilters) {
                    Text("Limpiar")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppColor.textSecondary)
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
