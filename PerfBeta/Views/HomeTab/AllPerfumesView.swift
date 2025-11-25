import SwiftUI

/// Vista para mostrar todos los perfumes recomendados de un perfil
/// Ahora usa el componente unificado PerfumeGridView
struct AllPerfumesView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var familyViewModel: FamilyViewModel
    @EnvironmentObject var brandViewModel: BrandViewModel
    @EnvironmentObject var olfactiveProfileViewModel: OlfactiveProfileViewModel

    let initialPerfumes: [(perfume: Perfume, score: Double)]
    let loadMoreAction: (() async -> Void)?
    let hasMoreData: Bool

    @State private var displayedPerfumes: [(perfume: Perfume, score: Double)]
    @State private var perfumeParaDetalle: Perfume? = nil

    init(perfumesWithScores: [(perfume: Perfume, score: Double)],
         loadMoreAction: (() async -> Void)? = nil,
         hasMoreData: Bool = false) {
        self.initialPerfumes = perfumesWithScores
        self.loadMoreAction = loadMoreAction
        self.hasMoreData = hasMoreData
        self._displayedPerfumes = State(initialValue: perfumesWithScores)
    }

    var body: some View {
        ZStack {
            GradientView(preset: .champan)
                .edgesIgnoringSafeArea(.all)

            ScrollView {
                // ✅ Usar el componente unificado PerfumeGridView
                PerfumeGridView(
                    perfumes: displayedPerfumes.map { $0.perfume },
                    scores: scoresDict,
                    showsFamily: true,
                    emptyStateType: .noRecommendations,
                    isLoading: false,
                    hasActiveFilters: true,
                    onPerfumeSelect: { perfume in
                        perfumeParaDetalle = perfume
                    },
                    onLoadMore: loadMoreAction,
                    hasMoreData: hasMoreData
                )
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.top)
                .padding(.bottom, 5)
            }
        }
        .navigationBarTitle("Perfumes Relacionados", displayMode: .inline)
        .fullScreenCover(item: $perfumeParaDetalle) { perfume in
            let brand = brandViewModel.getBrand(byKey: perfume.brand)
            let profile = olfactiveProfileViewModel.profiles.first

            PerfumeDetailView(
                perfume: perfume,
                brand: brand,
                profile: profile
            )
            .environmentObject(perfumeViewModel)
            .environmentObject(brandViewModel)
            .environmentObject(familyViewModel)
            .environmentObject(olfactiveProfileViewModel)
        }
    }

    // MARK: - Helpers

    /// Convierte el array de tuplas en un diccionario [perfumeId: score]
    private var scoresDict: [String: Double] {
        Dictionary(uniqueKeysWithValues: displayedPerfumes.map { ($0.perfume.id, $0.score) })
    }
}
