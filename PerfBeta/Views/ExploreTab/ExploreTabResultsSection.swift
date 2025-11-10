import SwiftUI

/// Sección de resultados para ExploreTab
/// Maneja: Loading states, Empty states, Results grid
struct ExploreTabResultsSection: View {
    // MARK: - Properties
    let perfumes: [Perfume]
    let isLoading: Bool
    let hasActiveFilters: Bool
    let onClearFilters: () -> Void
    let onPerfumeSelect: (Perfume) -> Void

    // MARK: - Environment Objects
    @EnvironmentObject var brandViewModel: BrandViewModel

    var body: some View {
        VStack {
            // ✅ LOADING STATE
            if isLoading && perfumes.isEmpty {
                loadingView
            }
            // ✅ EMPTY STATE - No filters applied
            else if !hasActiveFilters {
                EmptyStateView(type: .noSearchResults)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 60)
            }
            // ✅ EMPTY STATE - Filters applied but no results
            else if perfumes.isEmpty {
                EmptyStateView(type: .noFilterResults) {
                    onClearFilters()
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 60)
            }
            // ✅ RESULTS
            else {
                resultsGrid
            }
        }
    }

    // MARK: - Loading View
    private var loadingView: some View {
        LoadingView(message: "Cargando perfumes...", style: .fullScreen)
            .frame(maxWidth: .infinity)
            .frame(height: 400)
    }

    // MARK: - Results Grid
    private var resultsGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 16)], spacing: 16) {
            ForEach(perfumes) { perfume in
                resultCard(for: perfume)
            }
        }
    }

    // MARK: - Result Card
    private func resultCard(for perfume: Perfume) -> some View {
        PerfumeCard(
            perfume: perfume,
            brandName: brandViewModel.getBrand(byKey: perfume.brand)?.name ?? perfume.brand,
            style: .compact,
            size: .medium,
            showsFamily: true,
            showsRating: true
        ) {
            onPerfumeSelect(perfume)
        }
    }
}

// MARK: - Preview
#Preview {
    let mockPerfumes = [
        Perfume(
            id: "1",
            name: "Sauvage",
            brand: "dior",
            key: "sauvage",
            family: "woody",
            subfamilies: ["spicy"],
            topNotes: [],
            heartNotes: [],
            baseNotes: [],
            projection: "strong",
            intensity: "strong",
            duration: "long",
            recommendedSeason: ["spring"],
            associatedPersonalities: [],
            occasion: [],
            popularity: 9.5,
            year: 2015,
            perfumist: nil,
            imageURL: "",
            description: "Test perfume",
            gender: "masculine",
            price: "premium",
            createdAt: nil,
            updatedAt: nil
        ),
        Perfume(
            id: "2",
            name: "Aventus",
            brand: "creed",
            key: "aventus",
            family: "fruity",
            subfamilies: ["woody"],
            topNotes: [],
            heartNotes: [],
            baseNotes: [],
            projection: "strong",
            intensity: "strong",
            duration: "long",
            recommendedSeason: ["summer"],
            associatedPersonalities: [],
            occasion: [],
            popularity: 9.8,
            year: 2010,
            perfumist: nil,
            imageURL: "",
            description: "Test perfume 2",
            gender: "masculine",
            price: "luxury",
            createdAt: nil,
            updatedAt: nil
        )
    ]

    VStack(spacing: 20) {
        // Results state
        ExploreTabResultsSection(
            perfumes: mockPerfumes,
            isLoading: false,
            hasActiveFilters: true,
            onClearFilters: {},
            onPerfumeSelect: { _ in }
        )
        .environmentObject(BrandViewModel(brandService: DependencyContainer.shared.brandService))
        .frame(height: 300)

        Divider()

        // Loading state
        ExploreTabResultsSection(
            perfumes: [],
            isLoading: true,
            hasActiveFilters: true,
            onClearFilters: {},
            onPerfumeSelect: { _ in }
        )
        .environmentObject(BrandViewModel(brandService: DependencyContainer.shared.brandService))
        .frame(height: 300)

        Divider()

        // Empty state
        ExploreTabResultsSection(
            perfumes: [],
            isLoading: false,
            hasActiveFilters: false,
            onClearFilters: {},
            onPerfumeSelect: { _ in }
        )
        .environmentObject(BrandViewModel(brandService: DependencyContainer.shared.brandService))
        .frame(height: 300)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
