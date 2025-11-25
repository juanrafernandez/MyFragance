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
                    .foregroundColor(AppColor.textPrimary)
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
                            .foregroundColor(AppColor.textPrimary)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(AppColor.brandAccent.opacity(0.1))
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

        // 3. ✅ FUZZY MATCH: Intentar todas las variantes sin prefijos
        // Ejemplo: "le_labo_santal_33" → ["labo_santal_33", "santal_33"]
        let components = wishlistItem.perfumeId.split(separator: "_")

        // Intentar todas las posibles combinaciones quitando prefijos progresivamente
        for startIndex in 1..<components.count {
            let keyVariant = components[startIndex...].joined(separator: "_")

            #if DEBUG
            print("🔍 [WishListRow] Trying fuzzy match: '\(wishlistItem.perfumeId)' → '\(keyVariant)'")
            #endif

            // ✅ BUSCAR EN perfumeIndex primero (perfumes completos ya cargados)
            if let perfume = perfumeViewModel.getPerfumeFromIndex(byId: keyVariant) {
                #if DEBUG
                print("✅ [WishListRow] Found '\(wishlistItem.perfumeId)' in perfumeIndex: '\(keyVariant)'")
                #endif
                return perfume
            }

            // ✅ BUSCAR EN perfumes array (fallback)
            if let perfume = perfumeViewModel.perfumes.first(where: { $0.key == keyVariant }) {
                #if DEBUG
                print("✅ [WishListRow] Found '\(wishlistItem.perfumeId)' in perfumes array: '\(keyVariant)'")
                #endif
                return perfume
            }

            // ✅ CRITICAL FIX: BUSCAR EN metadataIndex (5587 perfumes)
            if let metadata = perfumeViewModel.metadataIndex.first(where: { $0.key == keyVariant }) {
                #if DEBUG
                print("✅ [WishListRow] Found '\(wishlistItem.perfumeId)' in metadataIndex: '\(keyVariant)'")
                print("   - Metadata: name=\(metadata.name), brand=\(metadata.brand), key=\(metadata.key)")
                #endif

                // ✅ UNIFIED CRITERION: Construir key en formato "marca_nombre"
                let normalizedBrand = metadata.brand
                    .lowercased()
                    .replacingOccurrences(of: " ", with: "_")
                    .folding(options: .diacriticInsensitive, locale: .current)
                let normalizedName = metadata.name
                    .lowercased()
                    .replacingOccurrences(of: " ", with: "_")
                    .folding(options: .diacriticInsensitive, locale: .current)
                let unifiedKey = "\(normalizedBrand)_\(normalizedName)"

                // Crear perfume temporal desde metadata
                let perfume = Perfume(
                    id: metadata.id,
                    name: metadata.name,
                    brand: metadata.brand,
                    brandName: nil,
                    key: unifiedKey,  // ✅ UNIFIED CRITERION: "marca_nombre"
                    family: metadata.family,
                    subfamilies: metadata.subfamilies ?? [],
                    topNotes: [],
                    heartNotes: [],
                    baseNotes: [],
                    projection: "",
                    intensity: "",
                    duration: "",
                    recommendedSeason: [],
                    associatedPersonalities: [],
                    occasion: [],
                    popularity: metadata.popularity,
                    year: metadata.year,
                    perfumist: nil,
                    imageURL: metadata.imageURL ?? "",
                    description: "",
                    gender: metadata.gender,
                    price: metadata.price,
                    searchTerms: nil,
                    createdAt: nil,
                    updatedAt: nil
                )
                return perfume
            }
        }

        #if DEBUG
        print("❌ [WishListRow] Perfume '\(wishlistItem.perfumeId)' NOT FOUND in any source")
        // Sample some keys from metadata to help debug
        let sampleKeys = perfumeViewModel.metadataIndex.prefix(10).map { $0.key }
        print("   Sample metadata keys (first 10): \(sampleKeys)")

        // Search explicitly for the variants we tried
        for startIndex in 1..<components.count {
            let keyVariant = components[startIndex...].joined(separator: "_")
            let exists = perfumeViewModel.metadataIndex.contains(where: { $0.key == keyVariant })
            print("   - '\(keyVariant)' exists in metadata: \(exists)")
        }
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
                            .foregroundColor(AppColor.textPrimary)
                            .lineLimit(2)

                        Text(brandViewModel.getBrand(byKey: perfume.brand)?.name ?? perfume.brand)
                            .font(.system(size: 12))
                            .foregroundColor(AppColor.textSecondary)
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
                            .foregroundColor(AppColor.textSecondary)
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
