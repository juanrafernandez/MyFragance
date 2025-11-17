//
//  PerfumeGridView.swift
//  PerfBeta
//
//  Componente unificado para mostrar grids de perfumes
//  Usado en: AllPerfumesView, ExploreTabResultsSection
//

import SwiftUI

/// Grid adaptativo reutilizable para mostrar perfumes
/// Soporta scores de afinidad, paginación y diferentes empty states
struct PerfumeGridView: View {
    // MARK: - Properties
    let perfumes: [Perfume]
    let scores: [String: Double]? // Optional: scores de afinidad por perfume.id (0-100)
    let showsFamily: Bool
    let emptyStateType: EmptyStateType
    let isLoading: Bool
    let hasActiveFilters: Bool
    let onPerfumeSelect: (Perfume) -> Void
    let onLoadMore: (() async -> Void)? // Optional: paginación
    let hasMoreData: Bool
    let onClearFilters: (() -> Void)? // Optional: limpiar filtros

    // MARK: - Environment
    @EnvironmentObject var brandViewModel: BrandViewModel

    // MARK: - State
    @State private var isLoadingMore = false

    // MARK: - Init
    init(
        perfumes: [Perfume],
        scores: [String: Double]? = nil,
        showsFamily: Bool = true,
        emptyStateType: EmptyStateType = .noSearchResults,
        isLoading: Bool = false,
        hasActiveFilters: Bool = false,
        onPerfumeSelect: @escaping (Perfume) -> Void,
        onLoadMore: (() async -> Void)? = nil,
        hasMoreData: Bool = false,
        onClearFilters: (() -> Void)? = nil
    ) {
        self.perfumes = perfumes
        self.scores = scores
        self.showsFamily = showsFamily
        self.emptyStateType = emptyStateType
        self.isLoading = isLoading
        self.hasActiveFilters = hasActiveFilters
        self.onPerfumeSelect = onPerfumeSelect
        self.onLoadMore = onLoadMore
        self.hasMoreData = hasMoreData
        self.onClearFilters = onClearFilters
    }

    var body: some View {
        VStack {
            // ✅ LOADING STATE
            if isLoading && perfumes.isEmpty {
                loadingView
            }
            // ✅ EMPTY STATE - No search/filters applied (initial state)
            else if !hasActiveFilters && perfumes.isEmpty {
                EmptyStateView(type: .exploreStart)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 60)
            }
            // ✅ EMPTY STATE - Search/filters applied but no results
            else if perfumes.isEmpty {
                EmptyStateView(type: emptyStateType) {
                    onClearFilters?()
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 60)
            }
            // ✅ RESULTS GRID
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
            ForEach(Array(perfumes.enumerated()), id: \.element.id) { index, perfume in
                resultCard(for: perfume)
                    .onAppear {
                        // Trigger load more when reaching near the end
                        if shouldLoadMore(currentIndex: index) {
                            handleLoadMore()
                        }
                    }
            }

            // Loading more indicator
            if isLoadingMore {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .gridCellColumns(2) // Span across columns
            }
        }
    }

    // MARK: - Result Card
    private func resultCard(for perfume: Perfume) -> some View {
        let score = scores?[perfume.id]

        return PerfumeCard(
            perfume: perfume,
            brandName: brandViewModel.getBrand(byKey: perfume.brand)?.name ?? perfume.brand,
            style: .compact,
            size: .medium,
            showsFamily: showsFamily,
            showsRating: score == nil, // Show popularity if no score
            score: score // Show affinity score if available (0-100)
        ) {
            onPerfumeSelect(perfume)
        }
    }

    // MARK: - Pagination
    private func shouldLoadMore(currentIndex: Int) -> Bool {
        guard onLoadMore != nil else { return false }
        return currentIndex >= perfumes.count - 3 &&
               !isLoadingMore &&
               hasMoreData
    }

    private func handleLoadMore() {
        guard let action = onLoadMore, !isLoadingMore else { return }

        isLoadingMore = true

        Task {
            await action()
            await MainActor.run {
                isLoadingMore = false
            }
        }
    }
}

// MARK: - Preview
#Preview("With Scores") {
    let mockPerfumes = [
        Perfume.mock,
        Perfume.mockFavorite,
        Perfume.mockLowRating
    ]

    let mockScores = [
        mockPerfumes[0].id: 87.5,
        mockPerfumes[1].id: 92.0,
        mockPerfumes[2].id: 78.3
    ]

    return ScrollView {
        PerfumeGridView(
            perfumes: mockPerfumes,
            scores: mockScores,
            showsFamily: true,
            isLoading: false,
            hasActiveFilters: true,
            onPerfumeSelect: { _ in }
        )
        .padding()
    }
    .environmentObject(BrandViewModel(brandService: DependencyContainer.shared.brandService))
    .background(AppColor.backgroundPrimary)
}

#Preview("Without Scores") {
    let mockPerfumes = [
        Perfume.mock,
        Perfume.mockFavorite,
        Perfume.mockLowRating
    ]

    return ScrollView {
        PerfumeGridView(
            perfumes: mockPerfumes,
            scores: nil,
            showsFamily: true,
            isLoading: false,
            hasActiveFilters: true,
            onPerfumeSelect: { _ in }
        )
        .padding()
    }
    .environmentObject(BrandViewModel(brandService: DependencyContainer.shared.brandService))
    .background(AppColor.backgroundPrimary)
}

#Preview("Loading") {
    ScrollView {
        PerfumeGridView(
            perfumes: [],
            isLoading: true,
            hasActiveFilters: true,
            onPerfumeSelect: { _ in }
        )
        .padding()
    }
    .environmentObject(BrandViewModel(brandService: DependencyContainer.shared.brandService))
    .background(AppColor.backgroundPrimary)
}

#Preview("Empty State") {
    ScrollView {
        PerfumeGridView(
            perfumes: [],
            emptyStateType: .noFilterResults,
            isLoading: false,
            hasActiveFilters: true,
            onPerfumeSelect: { _ in },
            onClearFilters: { print("Clear filters") }
        )
        .padding()
    }
    .environmentObject(BrandViewModel(brandService: DependencyContainer.shared.brandService))
    .background(AppColor.backgroundPrimary)
}
