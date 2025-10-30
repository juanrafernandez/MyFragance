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

    // ✅ FIX: Usar índice directamente en lugar de @State async
    private var perfume: Perfume? {
        perfumeViewModel.getPerfumeFromIndex(byKey: wishlistItem.perfumeId)
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

                        // ✅ Nombre de marca bonito
                        Text(brandViewModel.getBrand(byKey: perfume.brand)?.name ?? perfume.brand)
                            .font(.system(size: 12))
                            .foregroundColor(Color("textoSecundario"))
                            .lineLimit(1)
                    } else {
                        // ⚠️ Solo si perfume no está en índice (no debería pasar)
                        Text(wishlistItem.perfumeId)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color("textoSecundario"))
                            .lineLimit(2)
                            .onAppear {
                                print("⚠️ [WishListRowView] Perfume '\(wishlistItem.perfumeId)' no encontrado en índice")
                            }
                    }
                }

                Spacer()
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
