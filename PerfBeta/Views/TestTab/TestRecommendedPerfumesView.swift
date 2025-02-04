import SwiftUI

struct TestRecommendedPerfumesView: View {
    let profile: OlfactiveProfile
    @Binding var selectedPerfume: Perfume?
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    
    // Paginación
    @State private var currentPage: Int = 0
    private let perfumesPerPage: Int = 10
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Perfumes Recomendados")
                .font(.headline)
                .foregroundColor(Color(hex: "#2D3748"))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(getPaginatedRelatedPerfumes(), id: \.id) { perfume in
                        Button(action: {
                            selectedPerfume = perfume
                        }) {
                            TestPerfumeCardView(perfume: perfume)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Botón para cargar más perfumes
                    if hasMorePerfumes() {
                        Button(action: {
                            currentPage += 1
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
                }
                .padding(.horizontal)
            }
        }
        .padding(.horizontal)
    }

    /// Obtiene perfumes relacionados con paginación
    private func getPaginatedRelatedPerfumes() -> [Perfume] {
        let relatedPerfumes = OlfactiveProfileHelper.suggestPerfumes(
            perfil: profile,
            baseDeDatos: perfumeViewModel.perfumes,
            page: currentPage,
            limit: perfumesPerPage
        )
        return relatedPerfumes
    }

    /// Verifica si hay más perfumes para cargar
    private func hasMorePerfumes() -> Bool {
        let totalPerfumes = OlfactiveProfileHelper.suggestPerfumes(
            perfil: profile,
            baseDeDatos: perfumeViewModel.perfumes
        ).count
        
        return currentPage * perfumesPerPage < totalPerfumes
    }
}
