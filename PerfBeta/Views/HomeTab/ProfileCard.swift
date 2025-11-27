import SwiftUI
import Kingfisher

// MARK: - Tarjeta de Perfil (ProfileCard) - Diseño Editorial
struct ProfileCard: View {
    let profile: OlfactiveProfile
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var familyViewModel: FamilyViewModel
    @EnvironmentObject var brandViewModel: BrandViewModel
    @Binding var selectedPerfume: Perfume?
    @State private var relatedPerfumes: [(perfume: Perfume, score: Double)] = []
    @State private var isPresentingAllPerfumes = false

    // Obtener nombres de familias desde el ViewModel
    private var familyNames: [String] {
        profile.families.prefix(3).compactMap { familyPuntuation in
            familyViewModel.getFamily(byKey: familyPuntuation.family)?.name
        }
    }

    // MARK: - Constantes de Layout
    private enum LayoutConstants {
        static let headerHeight: CGFloat = 150      // Header del perfil (nombre, familias, separadores)
        static let sectionTitleHeight: CGFloat = 40 // "RECOMENDADOS" + padding
        static let perfumeItemHeight: CGFloat = 92  // Cada item de perfume (60px imagen + 32px padding)
        static let separatorHeight: CGFloat = 1     // Separador entre items
        static let viewAllButtonHeight: CGFloat = 60 // Botón "Ver todos"
        static let topPadding: CGFloat = 24         // Padding superior
        static let bottomSafeArea: CGFloat = 34     // Safe area inferior aproximada
    }

    // Calcula cuántos perfumes caben en pantalla sin scroll
    private func calculateVisiblePerfumes(for screenHeight: CGFloat) -> Int {
        let availableHeight = screenHeight
            - LayoutConstants.headerHeight
            - LayoutConstants.sectionTitleHeight
            - LayoutConstants.viewAllButtonHeight
            - LayoutConstants.topPadding
            - LayoutConstants.bottomSafeArea

        // Cada perfume ocupa su altura más el separador
        let itemTotalHeight = LayoutConstants.perfumeItemHeight + LayoutConstants.separatorHeight

        let count = Int(availableHeight / itemTotalHeight)

        // Mínimo 2, máximo 6
        return max(2, min(count, 6))
    }

    var body: some View {
        GeometryReader { geometry in
            let visibleCount = calculateVisiblePerfumes(for: geometry.size.height)
            let perfumesToShow = Array(relatedPerfumes.prefix(visibleCount))

            ScrollView {
                VStack(alignment: .center, spacing: 0) {
                    // MARK: - Header del Perfil (Estilo Editorial)
                    VStack(spacing: 16) {
                        // Separador superior elegante
                        Rectangle()
                            .fill(AppColor.textSecondary.opacity(0.2))
                            .frame(width: 40, height: 1)
                            .padding(.top, 8)

                        // Nombre del perfil con letter-spacing
                        Text(profile.name.uppercased())
                            .font(.custom("Georgia", size: 32))
                            .tracking(6)
                            .foregroundColor(AppColor.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)

                        // Familias con separador bullet
                        if !familyNames.isEmpty {
                            Text(familyNames.joined(separator: "  •  "))
                                .font(.system(size: 14, weight: .light))
                                .foregroundColor(AppColor.textSecondary)
                                .multilineTextAlignment(.center)
                        }

                        // Separador inferior
                        Rectangle()
                            .fill(AppColor.textSecondary.opacity(0.2))
                            .frame(width: 40, height: 1)
                    }
                    .padding(.horizontal, AppSpacing.screenHorizontal)
                    .padding(.bottom, 32)

                    // MARK: - Lista de Perfumes Recomendados
                    VStack(alignment: .leading, spacing: 0) {
                        // Título de sección
                        Text("RECOMENDADOS")
                            .font(.system(size: 11, weight: .medium))
                            .tracking(2)
                            .foregroundColor(AppColor.textSecondary)
                            .padding(.horizontal, AppSpacing.screenHorizontal)
                            .padding(.bottom, 16)

                        // Lista vertical de perfumes (cantidad dinámica)
                        VStack(spacing: 0) {
                            ForEach(perfumesToShow, id: \.perfume.id) { item in
                                PerfumeListItemView(
                                    perfume: item.perfume,
                                    score: item.score,
                                    onTap: {
                                        selectedPerfume = item.perfume
                                    }
                                )

                                // Separador entre items (excepto el último)
                                if item.perfume.id != perfumesToShow.last?.perfume.id {
                                    Rectangle()
                                        .fill(AppColor.textSecondary.opacity(0.1))
                                        .frame(height: 1)
                                        .padding(.horizontal, AppSpacing.screenHorizontal)
                                }
                            }
                        }

                        // Botón "Ver todos" (siempre visible si hay más perfumes)
                        if relatedPerfumes.count > visibleCount {
                            Button(action: {
                                isPresentingAllPerfumes = true
                            }) {
                                HStack {
                                    Spacer()
                                    Text("Ver todos")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppColor.textSecondary)
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(AppColor.textSecondary)
                                    Spacer()
                                }
                                .padding(.vertical, 20)
                            }
                        }
                    }
                }
                .padding(.top, 24)
            }
            .task {
                await loadRelatedPerfumes()
            }
            .background(
                NavigationLink(
                    destination: AllPerfumesView(perfumesWithScores: relatedPerfumes, loadMoreAction: { await self.loadMorePerfumes() },
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
            #if DEBUG
            print("Error al cargar perfumes relacionados: \(error)")
            #endif
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
            #if DEBUG
            print("Error al cargar más perfumes: \(error)")
            #endif
        }
    }
}
