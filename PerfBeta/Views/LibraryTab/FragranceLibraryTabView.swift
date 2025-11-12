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
    @State private var availableHeight: CGFloat = 0  // ✅ NEW: Track available screen height

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

    // ✅ NEW: Dynamic balancing algorithm
    private var displayCounts: (tried: Int, wishlist: Int) {
        let triedCount = perfumesToDisplay.count
        let wishlistCount = wishlistPerfumes.count

        // Row height estimation: Be more conservative - 50px image + 16px padding + 4px spacing between rows
        let estimatedRowHeight: CGFloat = 70

        // Reserved space breakdown:
        // - Main header "MI COLECCIÓN": ~40px
        // - Section title "TUS PERFUMES PROBADOS": ~30px
        // - "Añadir Perfume" button: ~60px
        // - Spacing after tried section: ~25px
        // - Divider: ~20px
        // - Section title "TU LISTA DE DESEOS": ~30px
        // - Bottom padding and safety margin: ~55px
        // Total: Optimized for exactly 6 rows on standard iPhone screens
        let reservedHeight: CGFloat = 260
        let availableForRows = max(availableHeight - reservedHeight, 0)

        // Calculate max rows that fit on screen (be conservative, round down)
        let maxRowsThatFit = max(Int(floor(availableForRows / estimatedRowHeight)), 1)

        #if DEBUG
        print("📐 [BalancingAlgorithm] Available height: \(availableHeight)px")
        print("   - Available for rows: \(availableForRows)px")
        print("   - Max rows that fit: \(maxRowsThatFit)")
        print("   - Tried count: \(triedCount), Wishlist count: \(wishlistCount)")
        #endif

        // If both lists can fit entirely, show all
        if triedCount + wishlistCount <= maxRowsThatFit {
            #if DEBUG
            print("✅ [BalancingAlgorithm] Showing all: tried=\(triedCount), wishlist=\(wishlistCount)")
            #endif
            return (triedCount, wishlistCount)
        }

        // Need to balance - implement user's algorithm
        let half = maxRowsThatFit / 2

        if triedCount <= half {
            // Tried has fewer than half, show all tried + remaining for wishlist
            let wishlistMax = min(wishlistCount, maxRowsThatFit - triedCount)
            #if DEBUG
            print("✅ [BalancingAlgorithm] Tried < half: tried=\(triedCount), wishlist=\(wishlistMax)")
            #endif
            return (triedCount, wishlistMax)
        } else if wishlistCount <= half {
            // Wishlist has fewer than half, show all wishlist + remaining for tried
            let triedMax = min(triedCount, maxRowsThatFit - wishlistCount)
            #if DEBUG
            print("✅ [BalancingAlgorithm] Wishlist < half: tried=\(triedMax), wishlist=\(wishlistCount)")
            #endif
            return (triedMax, wishlistCount)
        } else {
            // Both have more than half, split equally
            #if DEBUG
            print("✅ [BalancingAlgorithm] Balanced split: tried=\(half), wishlist=\(half)")
            #endif
            return (half, half)
        }
    }

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    GradientView(preset: .champan)
                        .edgesIgnoringSafeArea(.all)

                    VStack {
                        headerView

                        ScrollView {
                            VStack(alignment: .leading, spacing: 25) {
                                // ✅ CRITICAL FIX: No crear vistas pesadas aquí - lazy loading interno
                                // ✅ NEW: Using dynamic balancing algorithm
                                TriedPerfumesSection(
                                    title: "Tus Perfumes Probados",
                                    triedPerfumes: perfumesToDisplay,
                                    maxDisplayCount: displayCounts.tried,
                                    addAction: { isAddingPerfume = true },
                                    userViewModel: userViewModel
                                )

                                Divider()

                                WishListSection(
                                    title: "Tu Lista de Deseos",
                                    perfumes: wishlistPerfumes,
                                    message: "Busca un perfume y pulsa el botón de carrito para añadirlo a tu lista de deseos.",
                                    maxDisplayCount: displayCounts.wishlist,
                                    userViewModel: userViewModel
                                )
                            }
                            .padding(.horizontal,25)
                        }
                    }
                    .background(Color.clear)
                    .onAppear {
                        availableHeight = geometry.size.height
                        #if DEBUG
                        print("📐 [FragranceLibraryTabView] Screen height: \(geometry.size.height)px")
                        #endif
                    }
                    .onChange(of: geometry.size) { _, newSize in
                        availableHeight = newSize.height
                    }

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
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $isAddingPerfume) {
                AddPerfumeInitialStepsView(isAddingPerfume: $isAddingPerfume)
                    .onDisappear {
                        // ✅ CRITICAL FIX: Recargar tried perfumes cuando se cierra el modal
                        // Esto garantiza que la UI se actualice con los cambios realizados
                        Task {
                            #if DEBUG
                            print("🔄 [FragranceLibraryTabView] Recargando tried perfumes después de cerrar modal...")
                            #endif
                            await userViewModel.loadTriedPerfumes()

                            // Cargar perfumes completos si es necesario (en background sin loading UI)
                            let allNeededKeys = Array(Set(
                                userViewModel.triedPerfumes.map { $0.perfumeId } +
                                userViewModel.wishlistPerfumes.map { $0.perfumeId }
                            ))

                            if !allNeededKeys.isEmpty {
                                await perfumeViewModel.loadPerfumesByKeys(allNeededKeys)
                            }

                            #if DEBUG
                            print("✅ [FragranceLibraryTabView] Tried perfumes recargados: \(userViewModel.triedPerfumes.count) items")
                            #endif
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
