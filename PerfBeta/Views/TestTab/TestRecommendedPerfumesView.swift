import SwiftUI

struct TestRecommendedPerfumesView: View {
    let profile: OlfactiveProfile
    @Binding var selectedPerfume: Perfume?
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var familyViewModel: FamilyViewModel
    
    // Estados para manejar async
    @State private var recommendedPerfumes: [Perfume] = []
    @State private var isLoading = false
    @State private var errorMessage: IdentifiableString?
    
    // Paginación
    @State private var currentPage: Int = 0
    private let perfumesPerPage: Int = 10
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Perfumes Recomendados")
                .font(.headline)
                .foregroundColor(Color(hex: "#2D3748"))
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else if !recommendedPerfumes.isEmpty {
                perfumeScrollView
            } else if errorMessage != nil {
                errorView
            }
        }
        .padding(.horizontal)
        .task {
            await loadPerfumes()
        }
    }
    
    private var perfumeScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(recommendedPerfumes, id: \.id) { perfume in
                    Button(action: { selectedPerfume = perfume }) {
                        TestPerfumeCardView(perfume: perfume)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                if hasMorePerfumes() {
                    loadMoreButton
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var loadMoreButton: some View {
        Button(action: {
            currentPage += 1
            Task { await loadPerfumes() }
        }) {
            Text("Cargar más")
                .font(.subheadline)
                .foregroundColor(.blue)
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
        }
    }
    
    private var errorView: some View {
        VStack {
            Text("Error cargando perfumes")
                .foregroundColor(.red)
            Button("Reintentar") {
                Task { await loadPerfumes() }
            }
        }
    }
    
    // MARK: - Lógica Async
    private func loadPerfumes() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Convertir OlfactiveProfile a UnifiedProfile
            let unifiedProfile = UnifiedProfile.fromLegacyProfile(profile)

            let newPerfumes = await UnifiedRecommendationEngine.shared.getRecommendations(
                for: unifiedProfile,
                from: perfumeViewModel.perfumes,
                limit: perfumesPerPage
            )
            
            let converted = newPerfumes.compactMap { recommended in
                perfumeViewModel.perfumes.first { $0.id == recommended.perfumeId }
            }
            
            if currentPage == 0 {
                recommendedPerfumes = converted
            } else {
                recommendedPerfumes.append(contentsOf: converted)
            }
        } catch {
            errorMessage = IdentifiableString(value: error.localizedDescription)
            recommendedPerfumes = []
        }
        
        isLoading = false
    }
    
    private func hasMorePerfumes() -> Bool {
        let total = (currentPage + 1) * perfumesPerPage
        return recommendedPerfumes.count >= total
    }
}
