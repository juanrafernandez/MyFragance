import SwiftUI
import Kingfisher

/// ✅ REFACTOR: WishListSection con nuevos modelos
/// - WishlistItem solo contiene perfumeId
/// - Usa PerfumeViewModel para obtener datos completos del perfume
struct WishListSection: View {
    let title: String
    let perfumes: [WishlistItem]
    let message: String
    let maxDisplayCount: Int
    @ObservedObject var userViewModel: UserViewModel
    @EnvironmentObject var familyViewModel: FamilyViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel

    var body: some View {
        let _ = {
            #if DEBUG
            print("📋 [WishListSection] Rendering with \(perfumes.count) perfumes, isLoading: \(userViewModel.isLoadingWishlist)")
            #endif
        }()

        VStack(alignment: .leading) {
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(Color("textoPrincipal"))
                Spacer()
                if !perfumes.isEmpty {
                    // ✅ CRITICAL FIX: Lazy loading - la vista se crea SOLO al navegar
                    NavigationLink {
                        WishlistListView(
                            wishlistItemsInput: .constant(perfumes),
                            familyViewModel: familyViewModel
                        )
                    } label: {
                        Text("Ver más")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color("textoPrincipal"))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color("champan").opacity(0.1))
                            )
                    }
                }
            }
            .padding(.bottom, 5)

            // ✅ SIMPLIFICADO: Usar solo isLoadingWishlist
            if userViewModel.isLoadingWishlist {
                LoadingView(message: "Cargando lista...", style: .inline)
                    .frame(height: 100)
            }
            else if perfumes.isEmpty {
                EmptyStateView(
                    type: .noWishlist,
                    action: nil,
                    compact: true
                )
                .frame(height: 150)
            } else {
                VStack(alignment: .leading, spacing: 1) {
                    ForEach(perfumes.prefix(maxDisplayCount), id: \.id) { item in
                        WishListRowView(wishlistItem: item)
                    }
                }
            }
        }
    }
}

/// ✅ REFACTOR: Vista de fila usando índice de perfumeViewModel
struct WishListRowView: View {
    let wishlistItem: WishlistItem
    @EnvironmentObject var brandViewModel: BrandViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel

    @State private var showingDetailView = false

    // ✅ Perfume lookup: por ID (datos nuevos) o por key (datos legacy) + fuzzy match
    private var perfume: Perfume? {
        #if DEBUG
        print("🔍 [WishListRow] Looking for perfume: '\(wishlistItem.perfumeId)'")
        print("   - Metadata index: \(perfumeViewModel.metadataIndex.count) perfumes")
        print("   - Perfumes array: \(perfumeViewModel.perfumes.count) perfumes")
        print("   - Perfume index: \(perfumeViewModel.perfumeIndex.count) items")
        #endif

        // 1. Intentar búsqueda exacta por ID
        if let perfume = perfumeViewModel.getPerfumeFromIndex(byId: wishlistItem.perfumeId) {
            #if DEBUG
            print("✅ [WishListRow] Found '\(wishlistItem.perfumeId)' in metadata index (exact match)")
            #endif
            return perfume
        }

        // 2. Fallback: buscar por key (datos legacy antes del fix)
        if let perfume = perfumeViewModel.perfumes.first(where: { $0.key == wishlistItem.perfumeId }) {
            #if DEBUG
            print("✅ [WishListRow] Found '\(wishlistItem.perfumeId)' in perfumes array (exact match)")
            #endif
            return perfume
        }

        // 3. ✅ FUZZY MATCH: Intentar sin el prefijo de marca
        // Ejemplo: "lattafa_khamrah" → "khamrah"
        if let underscoreIndex = wishlistItem.perfumeId.firstIndex(of: "_") {
            let keyWithoutBrand = String(wishlistItem.perfumeId[wishlistItem.perfumeId.index(after: underscoreIndex)...])

            #if DEBUG
            print("🔍 [WishListRow] Trying fuzzy match: '\(wishlistItem.perfumeId)' → '\(keyWithoutBrand)'")
            #endif

            // Buscar en metadata index
            if let perfume = perfumeViewModel.getPerfumeFromIndex(byId: keyWithoutBrand) {
                #if DEBUG
                print("✅ [WishListRow] Found '\(wishlistItem.perfumeId)' using fuzzy match: '\(keyWithoutBrand)' (metadata)")
                #endif
                return perfume
            }

            // Buscar en perfumes array
            if let perfume = perfumeViewModel.perfumes.first(where: { $0.key == keyWithoutBrand }) {
                #if DEBUG
                print("✅ [WishListRow] Found '\(wishlistItem.perfumeId)' using fuzzy match: '\(keyWithoutBrand)' (array)")
                #endif
                return perfume
            }
        }

        #if DEBUG
        print("❌ [WishListRow] Perfume '\(wishlistItem.perfumeId)' NOT FOUND")
        // Sample some keys from metadata to help debug
        let sampleKeys = perfumeViewModel.metadataIndex.prefix(5).map { $0.key }
        print("   Sample metadata keys: \(sampleKeys)")
        #endif

        return nil
    }

    var body: some View {
        Button {
            if perfume != nil {
                showingDetailView = true
            }
        } label: {
            HStack(spacing: 15) {
                // ✅ Imagen del perfume
                if let perfume = perfume {
                    KFImage(perfume.imageURL.flatMap { URL(string: $0) })
                        .placeholder {
                            ZStack {
                                Color.gray.opacity(0.2)
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 25, height: 25)
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                        }
                        .cacheMemoryOnly(false)
                        .diskCacheExpiration(.never)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .cornerRadius(8)
                } else {
                    ZStack {
                        Color.gray.opacity(0.2)
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 25, height: 25)
                            .foregroundColor(.gray.opacity(0.5))
                    }
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)
                }

                VStack(alignment: .leading, spacing: 4) {
                    if let perfume = perfume {
                        Text(perfume.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color("textoPrincipal"))
                            .lineLimit(2)

                        Text(brandViewModel.getBrand(byKey: perfume.brand)?.name ?? perfume.brand)
                            .font(.system(size: 12))
                            .foregroundColor(Color("textoSecundario"))
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Mostrar Popularidad con icono de estrella
                if let perfume = perfume, let popularity = perfume.popularity {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 12))
                        Text(String(format: "%.1f", popularity / 10.0))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color("textoSecundario"))
                    }
                }
            }
            .padding(.vertical, 8)
            .background(Color.clear)
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showingDetailView) {
            if let perfume = perfume {
                let brand = brandViewModel.getBrand(byKey: perfume.brand)
                PerfumeDetailView(
                    perfume: perfume,
                    brand: brand,
                    profile: nil
                )
            }
        }
    }
}
