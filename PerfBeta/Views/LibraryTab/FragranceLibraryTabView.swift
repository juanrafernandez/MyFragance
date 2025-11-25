import SwiftUI
import Combine
import Foundation

struct FragranceLibraryTabView: View {
    @State private var isAddingPerfume = false
    @State private var showingTriedList = false  // ✅ NEW: For navigation to full tried list
    @State private var showingWishlist = false   // ✅ NEW: For navigation to full wishlist
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var brandViewModel : BrandViewModel
    @EnvironmentObject var familyViewModel: FamilyViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @State private var selectedPerfume: Perfume? = nil

    // ✅ NUEVO: Estructura para perfumes con rating opcional
    private struct PerfumeWithRating: Identifiable {
        let id: String
        let perfume: Perfume
        let rating: Double?

        init(perfume: Perfume, rating: Double? = nil) {
            self.id = perfume.id
            self.perfume = perfume
            self.rating = rating
        }
    }

    // ✅ NUEVO: Obtener perfumes probados completos con ratings
    private var triedPerfumesWithRatings: [PerfumeWithRating] {
        let sorted = userViewModel.sortTriedPerfumes(userViewModel.triedPerfumes) { perfumeId in
            perfumeViewModel.getPerfumeFromIndex(byId: perfumeId)?.name
        }
        return sorted.map { tried -> PerfumeWithRating in
            // Try to find the perfume in the metadata index
            if let perfume = perfumeViewModel.getPerfumeFromIndex(byId: tried.perfumeId) {
                return PerfumeWithRating(perfume: perfume, rating: tried.rating)
            } else {
                // ⚠️ FALLBACK: Perfume no encontrado en metadata index - Crear placeholder
                #if DEBUG
                print("⚠️ [FragranceLibrary] Perfume probado '\(tried.perfumeId)' no encontrado - creando placeholder")
                #endif
                let placeholderPerfume = Perfume(
                    id: tried.perfumeId,
                    name: tried.perfumeId.replacingOccurrences(of: "_", with: " ").capitalized,
                    brand: "Desconocido",
                    key: tried.perfumeId,
                    family: "Desconocido",
                    subfamilies: [],
                    topNotes: [],
                    heartNotes: [],
                    baseNotes: [],
                    projection: "Desconocido",
                    intensity: "Desconocido",
                    duration: "Desconocido",
                    recommendedSeason: [],
                    associatedPersonalities: [],
                    occasion: [],
                    popularity: 0,
                    year: 0,
                    perfumist: nil,
                    imageURL: "",
                    description: "Perfume no disponible en la base de datos",
                    gender: "Desconocido",
                    price: nil,
                    createdAt: nil,
                    updatedAt: nil
                )
                return PerfumeWithRating(perfume: placeholderPerfume, rating: tried.rating)
            }
        }
    }

    // ✅ NUEVO: Obtener perfumes de wishlist completos (sin rating), ordenados por popularidad descendente
    private var wishlistPerfumesWithRatings: [PerfumeWithRating] {
        userViewModel.wishlistPerfumes.map { item -> PerfumeWithRating in
            // Try to find the perfume in the metadata index
            if let perfume = perfumeViewModel.getPerfumeFromIndex(byId: item.perfumeId) {
                return PerfumeWithRating(perfume: perfume, rating: nil)
            } else {
                // ⚠️ FALLBACK: Perfume no encontrado en metadata index - Crear placeholder
                #if DEBUG
                print("⚠️ [FragranceLibrary] Perfume '\(item.perfumeId)' no encontrado - creando placeholder")
                #endif
                let placeholderPerfume = Perfume(
                    id: item.perfumeId,
                    name: item.perfumeId.replacingOccurrences(of: "_", with: " ").capitalized,
                    brand: "Desconocido",
                    key: item.perfumeId,
                    family: "Desconocido",
                    subfamilies: [],
                    topNotes: [],
                    heartNotes: [],
                    baseNotes: [],
                    projection: "Desconocido",
                    intensity: "Desconocido",
                    duration: "Desconocido",
                    recommendedSeason: [],
                    associatedPersonalities: [],
                    occasion: [],
                    popularity: 0,
                    year: 0,
                    perfumist: nil,
                    imageURL: "",
                    description: "Perfume no disponible en la base de datos",
                    gender: "Desconocido",
                    price: nil,
                    createdAt: nil,
                    updatedAt: nil
                )
                return PerfumeWithRating(perfume: placeholderPerfume, rating: nil)
            }
        }
        .sorted { ($0.perfume.popularity ?? 0) > ($1.perfume.popularity ?? 0) }
    }

    var body: some View {
        NavigationView {
            ZStack {
                GradientView(preset: .champan)
                    .edgesIgnoringSafeArea(.all)

                VStack {
                    headerView

                    ScrollView {
                        VStack(alignment: .leading, spacing: 30) {
                            // ✅ NUEVO: Scroll horizontal de perfumes probados
                            HorizontalPerfumeSectionView(
                                title: "Tus Perfumes Probados",
                                perfumesWithRatings: triedPerfumesWithRatings,
                                emptyMessage: "Aún no has probado ningún perfume.\n¡Añade tu primer perfume probado!",
                                showPersonalRatings: true,  // ✅ Mostrar ratings en probados
                                onViewAll: {
                                    showingTriedList = true
                                },
                                onPerfumeSelect: { perfume in
                                    selectedPerfume = perfume
                                }
                            )

                            // Botón añadir perfume probado
                            addPerfumeButton

                            Divider()
                                .padding(.vertical, 5)

                            // ✅ NUEVO: Scroll horizontal de lista de deseos
                            HorizontalPerfumeSectionView(
                                title: "Tu Lista de Deseos",
                                perfumesWithRatings: wishlistPerfumesWithRatings,
                                emptyMessage: "Tu lista de deseos está vacía.\nBusca un perfume y pulsa el botón de carrito para añadirlo.",
                                showPersonalRatings: false,  // ✅ NO mostrar ratings en wishlist
                                onViewAll: {
                                    showingWishlist = true
                                },
                                onPerfumeSelect: { perfume in
                                    selectedPerfume = perfume
                                }
                            )
                        }
                        .padding(.horizontal, AppSpacing.screenHorizontal)
                        .padding(.top, 25)
                        .padding(.bottom, AppSpacing.sectionSpacing)
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
            // ✅ Navigation Links (hidden)
            .background(
                Group {
                    NavigationLink(
                        destination: TriedPerfumesListView(
                            familyViewModel: familyViewModel
                        )
                            .environmentObject(userViewModel)
                            .environmentObject(brandViewModel)
                            .environmentObject(perfumeViewModel)
                            .environmentObject(familyViewModel),
                        isActive: $showingTriedList
                    ) { EmptyView() }

                    NavigationLink(
                        destination: WishlistListView(
                            wishlistItemsInput: $userViewModel.wishlistPerfumes,
                            familyViewModel: familyViewModel
                        )
                            .environmentObject(userViewModel)
                            .environmentObject(brandViewModel)
                            .environmentObject(perfumeViewModel)
                            .environmentObject(familyViewModel),
                        isActive: $showingWishlist
                    ) { EmptyView() }
                }
            )
            // ✅ Perfume Detail Modal
            .fullScreenCover(item: $selectedPerfume) { perfume in
                PerfumeDetailView(
                    perfume: perfume,
                    brand: brandViewModel.getBrand(byKey: perfume.brand),
                    profile: nil
                )
            }
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
                .foregroundColor(AppColor.textPrimary)
            Spacer()
        }
        .padding(.leading, 25)
        .padding(.top, AppSpacing.spacing16)
    }

    // ✅ Botón para añadir perfume probado
    private var addPerfumeButton: some View {
        Button(action: {
            isAddingPerfume = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16))
                Text("Añadir Perfume Probado")
                    .font(.system(size: 15, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppColor.brandAccent)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }

    // MARK: - Horizontal Perfume Section (Inline Component)

    /// Sección genérica con scroll horizontal de perfumes (máximo 5)
    private struct HorizontalPerfumeSectionView: View {
        let title: String
        let perfumesWithRatings: [PerfumeWithRating]
        let maxDisplay: Int = 5
        let emptyMessage: String
        let showPersonalRatings: Bool  // ✅ NEW: Control para mostrar ratings personales
        let onViewAll: () -> Void
        let onPerfumeSelect: (Perfume) -> Void

        @EnvironmentObject var brandViewModel: BrandViewModel

        private var displayPerfumes: [PerfumeWithRating] {
            Array(perfumesWithRatings.prefix(maxDisplay))
        }

        private var hasMore: Bool {
            perfumesWithRatings.count > maxDisplay
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                // Header con título y botón "Ver todos"
                HStack {
                    Text(title.uppercased())
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColor.textPrimary)

                    Spacer()

                    if !perfumesWithRatings.isEmpty {
                        Button(action: onViewAll) {
                            HStack(spacing: 4) {
                                Text("Ver todos")
                                    .font(.system(size: 13, weight: .medium))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundColor(AppColor.brandAccent)
                        }
                    }
                }

                // Contenido: Scroll horizontal o empty state
                if perfumesWithRatings.isEmpty {
                    emptyStateView
                } else {
                    scrollContent
                }
            }
        }

        private var scrollContent: some View {
            VStack(alignment: .leading, spacing: 12) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(displayPerfumes) { item in
                            let personalRatingValue = showPersonalRatings ? item.rating : nil
                            let _ = {
                                #if DEBUG
                                print("🎯 [HorizontalSection] Perfume: \(item.perfume.name), showPersonalRatings: \(showPersonalRatings), item.rating: \(String(describing: item.rating)), personalRatingValue: \(String(describing: personalRatingValue))")
                                #endif
                            }()

                            PerfumeCard(
                                perfume: item.perfume,
                                brandName: brandViewModel.getBrand(byKey: item.perfume.brand)?.name ?? item.perfume.brand,
                                style: .compact,
                                size: .small,
                                showsFamily: true,
                                showsRating: true,
                                personalRating: personalRatingValue
                            ) {
                                onPerfumeSelect(item.perfume)
                            }
                            .frame(width: 120)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Botón "Ver más" si hay más de 5 perfumes
                if hasMore {
                    viewMoreButton
                }
            }
        }

        private var emptyStateView: some View {
            VStack(spacing: 8) {
                Text(emptyMessage)
                    .font(.system(size: 14, weight: .light))
                    .foregroundColor(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 20)
            }
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
        }

        private var viewMoreButton: some View {
            Button(action: onViewAll) {
                HStack {
                    Spacer()
                    Text("Ver más")
                        .font(.system(size: 14, weight: .medium))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                    Spacer()
                }
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppColor.brandAccent.opacity(0.1))
                )
                .foregroundColor(AppColor.brandAccent)
            }
        }
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
