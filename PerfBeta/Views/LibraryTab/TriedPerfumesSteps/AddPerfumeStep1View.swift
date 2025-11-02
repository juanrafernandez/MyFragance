import SwiftUI

// MARK: - AddPerfumeStep1View
struct AddPerfumeStep1View: View {
    @Binding var selectedPerfume: Perfume?
    @ObservedObject var perfumeViewModel: PerfumeViewModel
    @ObservedObject var brandViewModel: BrandViewModel
    @Binding var onboardingStep: Int
    var initialSelectedPerfume: Perfume? = nil
    @Binding var isAddingPerfume: Bool
    @Binding var showingEvaluationOnboarding: Bool

    @State private var searchText: String = ""
    @State private var isSearchFocused: Bool = false
    private let itemsPerPage = 20
    private let maxSuggestions = 5

    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.body)

                    TextField("Buscar perfume o marca...", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)

            // Content
            if perfumeViewModel.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Cargando perfumes...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else if searchText.isEmpty {
                // ✅ EmptyState con instrucciones cuando no hay búsqueda
                emptySearchState
            } else if filteredPerfumes().isEmpty {
                // ✅ No results state
                noResultsState
            } else {
                // ✅ Results list con autocomplete visual
                resultsListView
            }
        }
        .onAppear {
            if let initialPerfume = initialSelectedPerfume {
                selectedPerfume = initialPerfume
            }
        }
    }

    // MARK: - Empty Search State
    private var emptySearchState: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Text("Busca tu perfume")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                VStack(spacing: 12) {
                    Text("Escribe el nombre del perfume o la marca en el buscador.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Text("Por ejemplo: \"Sauvage\", \"Dior\", \"Acqua di Gio\"")
                        .font(.callout)
                        .foregroundColor(.secondary.opacity(0.8))
                        .italic()
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 40)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - No Results State
    private var noResultsState: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 16) {
                Text("No encontramos resultados")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text("Intenta con otro nombre o marca")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Results List
    private var resultsListView: some View {
        VStack(spacing: 0) {
            // Autocomplete suggestion header
            if !searchText.isEmpty && filteredPerfumes().count > 1 {
                HStack {
                    Text("\(filteredPerfumes().count) resultados encontrados")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
            }

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredPerfumes(), id: \.id) { perfume in
                        NavigationLink(destination: AddPerfumeStep2View(
                            selectedPerfume: perfume,
                            isAddingPerfume: $isAddingPerfume,
                            showingEvaluationOnboarding: $showingEvaluationOnboarding
                        )) {
                            PerfumeSearchResultRow(
                                perfume: perfume,
                                brandViewModel: brandViewModel,
                                searchText: searchText
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
        }
    }

    private func filteredPerfumes() -> [Perfume] {
        if searchText.isEmpty {
            return []
        } else {
            return perfumeViewModel.perfumes.filter { perfume in
                perfume.name.localizedCaseInsensitiveContains(searchText) ||
                perfume.brand.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

// MARK: - Perfume Search Result Row
struct PerfumeSearchResultRow: View {
    let perfume: Perfume
    @ObservedObject var brandViewModel: BrandViewModel
    let searchText: String

    var body: some View {
        HStack(spacing: 12) {
            // Icono de perfume
            ZStack {
                Circle()
                    .fill(Color("Gold").opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: "drop.fill")
                    .font(.title3)
                    .foregroundColor(Color("Gold"))
            }

            // Info del perfume
            VStack(alignment: .leading, spacing: 4) {
                // Nombre con highlight del texto buscado
                Text(perfume.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(brandViewModel.getBrand(byKey: perfume.brand)?.name ?? perfume.brand)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                if !perfume.family.isEmpty {
                    Text(perfume.family)
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.8))
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.clear)
        .contentShape(Rectangle())
    }
}
