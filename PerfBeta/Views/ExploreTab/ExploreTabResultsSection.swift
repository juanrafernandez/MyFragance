import SwiftUI

/// Sección de resultados para ExploreTab
/// Ahora usa el componente unificado PerfumeGridView
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
        // ✅ Usar el componente unificado PerfumeGridView
        PerfumeGridView(
            perfumes: perfumes,
            scores: nil, // ExploreTab no usa scores de afinidad
            showsFamily: true,
            emptyStateType: .noSearchResults,
            isLoading: isLoading,
            hasActiveFilters: hasActiveFilters,
            onPerfumeSelect: onPerfumeSelect,
            onClearFilters: onClearFilters
        )
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
