import SwiftUI

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
    @State private var isLoading = false
    @State private var perfumeParaDetalle: Perfume? = nil
    
    // ✅ ELIMINADO: Sistema de temas personalizable
    
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
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                    ForEach(displayedPerfumes.indices, id: \.self) { index in
                        let item = displayedPerfumes[index]

                        PerfumeCardView(
                            perfume: item.perfume,
                            brandName: brandViewModel.getBrand(byKey: item.perfume.brand)?.name ?? item.perfume.brand,
                            family: item.perfume.family,
                            score: item.score
                        )
                        .onTapGesture {
                            perfumeParaDetalle = item.perfume
                        }
                        .onAppear {
                            if shouldLoadMoreData(currentIndex: index) {
                                handleLoadMore()
                            }
                        }
                    }
                }
                .padding(.horizontal) // Keep horizontal padding for grid content
                .padding(.top)      // Add top padding if needed

                if isLoading {
                    ProgressView()
                        .padding()
                }
                
                // Add bottom padding inside ScrollView to push content up from the tab bar area
                Spacer().frame(height: 5) // Or use .padding(.bottom, 5) on the LazyVGrid or the element above this line
                
            }
            // Apply bottom padding to the ScrollView itself
            .padding(.bottom, 5)
        }
        .navigationBarTitle("Perfumes Relacionados", displayMode: .inline)
        .fullScreenCover(item: $perfumeParaDetalle) { perfume in
            if let brand = brandViewModel.getBrand(byKey: perfume.brand),
               let profile = olfactiveProfileViewModel.profiles.first {
                 PerfumeDetailView(
                    perfume: perfume,
                    brand: brand,
                    profile: profile
                 )
                 .environmentObject(perfumeViewModel)
                 .environmentObject(brandViewModel)
                 .environmentObject(familyViewModel)
                 .environmentObject(olfactiveProfileViewModel)
            } else {
                 errorView
            }
        }
        // If using onChange to update displayedPerfumes based on ViewModel changes:
        // .onChange(of: perfumeViewModel.somePublishedListOfPerfumesWithScores) { newItems in
        //      self.displayedPerfumes = newItems
        // }
    }

    private func shouldLoadMoreData(currentIndex: Int) -> Bool {
        currentIndex >= displayedPerfumes.count - 3 &&
        !isLoading &&
        hasMoreData &&
        loadMoreAction != nil
    }

    private func handleLoadMore() {
        guard !isLoading, let action = loadMoreAction else { return }

        isLoading = true

        Task {
            await action()
            await MainActor.run {
                isLoading = false
                // Potentially update displayedPerfumes here if needed,
                // depending on how loadMoreAction signals data updates.
            }
        }
    }

    private var errorView: some View {
         VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.yellow)

            Text("Información incompleta")
                .font(.headline)

            Text("No se encontraron todos los datos necesarios para mostrar este perfume.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Cerrar") {
                perfumeParaDetalle = nil
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .edgesIgnoringSafeArea(.all)
    }
}
