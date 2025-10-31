import SwiftUI
import Combine
import Foundation

struct FragranceLibraryTabView: View {
    @State private var isAddingPerfume = false
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var brandViewModel : BrandViewModel
    @EnvironmentObject var familyViewModel: FamilyViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel  // ✅ NUEVO
    @State private var selectedPerfume: Perfume? = nil

    // ✅ FIX: No usar estado local separado, usar directamente userViewModel
    // Esto evita el "flash" de empty state cuando los datos ya están cargados
    private var perfumesToDisplay: [TriedPerfume] {
        userViewModel.triedPerfumes
    }

    private var wishlistPerfumes: [WishlistItem] {
        userViewModel.wishlistPerfumes
    }

    // ✅ ELIMINADO: Sistema de temas personalizable

    var body: some View {
        NavigationView {
            ZStack {
                GradientView(preset: .champan)
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    headerView

                    ScrollView {
                        VStack(alignment: .leading, spacing: 25) {
                            // ✅ CRITICAL FIX: No crear vistas pesadas aquí - lazy loading interno
                            TriedPerfumesSection(
                                title: "Tus Perfumes Probados",
                                triedPerfumes: perfumesToDisplay,
                                maxDisplayCount: 4,
                                addAction: { isAddingPerfume = true },
                                userViewModel: userViewModel
                            )

                            Divider()

                            WishListSection(
                                title: "Tu Lista de Deseos",
                                perfumes: wishlistPerfumes,
                                message: "Busca un perfume y pulsa el botón de carrito para añadirlo a tu lista de deseos.",
                                maxDisplayCount: 3,
                                userViewModel: userViewModel
                            )
                        }
                        .padding(.horizontal,25)
                    }
                }
                .background(Color.clear)

                // ✅ OFFLINE-FIRST: Badges de sync y offline
                VStack {
                    if userViewModel.isSyncingTriedPerfumes || userViewModel.isSyncingWishlist {
                        SyncingBadge()
                    } else if userViewModel.isOffline {
                        OfflineBadge()
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $isAddingPerfume) {
                AddPerfumeInitialStepsView(isAddingPerfume: $isAddingPerfume)
                    .onDisappear {
                        // Recargar después de agregar perfume
                        Task {
                            await brandViewModel.loadInitialData()
                            await userViewModel.loadTriedPerfumes()
                            await userViewModel.loadWishlist()

                            // Cargar perfumes completos
                            let allNeededKeys = Array(Set(
                                userViewModel.triedPerfumes.map { $0.perfumeId } +
                                userViewModel.wishlistPerfumes.map { $0.perfumeId }
                            ))

                            if !allNeededKeys.isEmpty {
                                await perfumeViewModel.loadPerfumesByKeys(allNeededKeys)
                            }
                            // ✅ No necesita actualizar estado local - usa computed properties
                        }
                    }
            }
        }
        .environmentObject(userViewModel)
        .environmentObject(brandViewModel)
        .environmentObject(familyViewModel)
        .onAppear {
            PerformanceLogger.logViewAppear("FragranceLibraryTabView")
            // ✅ Perfumes pre-loaded in MainTabView, no additional loading needed
        }
        .onDisappear {
            PerformanceLogger.logViewDisappear("FragranceLibraryTabView")
        }
    }

    private var headerView: some View {
        HStack {
            Text("Mi Colección".uppercased())
                .font(.system(size: 18, weight: .light))
                .foregroundColor(Color("textoPrincipal"))
            Spacer()
        }
        .padding(.leading, 25)
        .padding(.top, 16)
    }
}
