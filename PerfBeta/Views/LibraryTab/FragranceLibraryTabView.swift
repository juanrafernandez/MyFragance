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
    // ✅ ORDENACIÓN: Primero con rating (mayor a menor), luego alfabéticamente
    private var perfumesToDisplay: [TriedPerfume] {
        userViewModel.sortTriedPerfumes(userViewModel.triedPerfumes) { perfumeId in
            perfumeViewModel.getPerfumeFromIndex(byId: perfumeId)?.name
        }
    }

    private var wishlistPerfumes: [WishlistItem] {
        #if DEBUG
        print("📋 [FragranceLibraryTabView] wishlistPerfumes computed: \(userViewModel.wishlistPerfumes.count) items")
        #endif
        return userViewModel.wishlistPerfumes
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
                        // ✅ FIX: No recargar aquí - addTriedPerfume() ya actualiza la lista local
                        // Recargar aquí causa loading screens innecesarios
                        // La actualización es automática a través de @Published properties

                        // Solo cargar perfumes completos si es necesario (en background sin loading UI)
                        Task {
                            let allNeededKeys = Array(Set(
                                userViewModel.triedPerfumes.map { $0.perfumeId } +
                                userViewModel.wishlistPerfumes.map { $0.perfumeId }
                            ))

                            if !allNeededKeys.isEmpty {
                                await perfumeViewModel.loadPerfumesByKeys(allNeededKeys)
                            }
                        }
                    }
            }
        }
        .environmentObject(userViewModel)
        .environmentObject(brandViewModel)
        .environmentObject(familyViewModel)
        .onAppear {
            PerformanceLogger.logViewAppear("FragranceLibraryTabView")
            // ✅ Load metadata index if not already loaded
            Task {
                await loadMetadataIfNeeded()
            }
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

    // ✅ Cargar metadata index si no está cargado (patrón de WishlistListView)
    private func loadMetadataIfNeeded() async {
        // 1. Cargar metadata index si está vacío
        if perfumeViewModel.metadataIndex.isEmpty {
            #if DEBUG
            print("⚠️ [FragranceLibraryTabView] Metadata index vacío, cargando...")
            #endif
            await perfumeViewModel.loadMetadataIndex()
        }

        // 2. Cargar brands si está vacío
        if brandViewModel.brands.isEmpty {
            #if DEBUG
            print("⚠️ [FragranceLibraryTabView] Brands vacíos, cargando...")
            #endif
            await brandViewModel.loadInitialData()
        }

        // 3. ✅ CRITICAL FIX: Cargar perfumes completos para wishlist y tried perfumes
        // Sin esto, WishListRowView no puede encontrar los perfumes en perfumeIndex
        let allNeededKeys = Array(Set(
            userViewModel.triedPerfumes.map { $0.perfumeId } +
            userViewModel.wishlistPerfumes.map { $0.perfumeId }
        ))

        if !allNeededKeys.isEmpty {
            #if DEBUG
            print("📥 [FragranceLibraryTabView] Cargando \(allNeededKeys.count) perfumes necesarios para biblioteca...")
            #endif
            await perfumeViewModel.loadPerfumesByKeys(allNeededKeys)
            #if DEBUG
            print("✅ [FragranceLibraryTabView] Perfumes cargados. perfumeIndex: \(perfumeViewModel.perfumeIndex.count) items")
            #endif
        }
    }
}
