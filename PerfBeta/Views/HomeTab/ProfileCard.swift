import SwiftUI

// MARK: - Tarjeta de Perfil (ProfileCard)
struct ProfileCard: View {
    let profile: OlfactiveProfile
    @ObservedObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var familyViewModel: FamilyViewModel
    @EnvironmentObject var brandViewModel: BrandViewModel
    @Binding var selectedPerfume: Perfume?
    @State private var relatedPerfumes: [(perfume: Perfume, score: Double)] = []
    @State private var isPresentingAllPerfumes = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .center, spacing: 0) {
                    VStack {
                        Text("PERFIL".uppercased())
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(Color("textoSecundario"))

                        Text(profile.name)
                            .font(.system(size: 50, weight: .ultraLight))
                            .foregroundColor(Color("textoPrincipal"))
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 5)
                            .lineLimit(2)

                        Text(profile.families.prefix(3).map { $0.family }.joined(separator: ", ").capitalized)
                            .font(.system(size: 18, weight: .thin))
                            .foregroundColor(Color("textoSecundario"))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 25)  // ✅ Padding para toda la sección del perfil

                    Spacer()

                    VStack(alignment: .center, spacing: 0) {
                        PerfumeHorizontalListView(
                            allPerfumes: relatedPerfumes,
                            onPerfumeTap: { perfume in
                                selectedPerfume = perfume
                            },
                            showAllPerfumesSheet: $isPresentingAllPerfumes
                        )
                        .frame(height: geometry.size.height * 0.38)
                        .padding(.bottom, 1)

                        VStack {
                            HomeDidYouKnowSectionView()
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 25)  // ✅ Padding solo para DidYouKnow
                        .padding(.bottom, 35)
                    }
                }
                .padding(.top, 24)
            }
            .task {
                await loadRelatedPerfumes()
            }
            .background(
                NavigationLink(
                    destination: AllPerfumesView(perfumesWithScores: relatedPerfumes,loadMoreAction: { await self.loadMorePerfumes() },
                                                 hasMoreData: perfumeViewModel.hasMoreData
                                                )
                    .environmentObject(perfumeViewModel)
                    .environmentObject(familyViewModel)
                    .environmentObject(brandViewModel),
                    isActive: $isPresentingAllPerfumes,
                    label: { EmptyView() }
                )
            )
        }
    }
    
    private func loadRelatedPerfumes() async {
        do {
            let perfumes = try await perfumeViewModel.getRelatedPerfumes(
                for: profile,
                from: familyViewModel.familias // Cambiado 'families' por 'from'
            )
            relatedPerfumes = perfumes
        } catch {
            print("Error al cargar perfumes relacionados: \(error)")
        }
    }

    private func loadMorePerfumes() async {
        do {
            let morePerfumes = try await perfumeViewModel.getRelatedPerfumes(
                for: profile,
                from: familyViewModel.familias, // Cambiado 'families' por 'from'
                loadMore: true
            )
            relatedPerfumes.append(contentsOf: morePerfumes)
        } catch {
            print("Error al cargar más perfumes: \(error)")
        }
    }
}
