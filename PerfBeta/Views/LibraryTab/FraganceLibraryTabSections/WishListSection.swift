import SwiftUI

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

/// ✅ REFACTOR: Vista de fila simplificada
struct WishListRowView: View {
    let wishlistItem: WishlistItem
    @EnvironmentObject var brandViewModel: BrandViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel

    @State private var showingDetailView = false
    @State private var perfume: Perfume? = nil

    var body: some View {
        Button {
            if perfume != nil {
                showingDetailView = true
            }
        } label: {
            HStack(spacing: 15) {
                // Placeholder image
                Image(systemName: "photo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.gray.opacity(0.3))

                VStack(alignment: .leading, spacing: 4) {
                    if let perfume = perfume {
                        Text(perfume.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color("textoPrincipal"))
                            .lineLimit(2)

                        Text(perfume.brand)
                            .font(.system(size: 12))
                            .foregroundColor(Color("textoSecundario"))
                            .lineLimit(1)
                    } else {
                        Text("Cargando...")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color("textoPrincipal"))
                    }
                }

                Spacer()
            }
            .padding(.vertical, 8)
            .background(Color.clear)
        }
        .buttonStyle(.plain)
        .task {
            // Cargar perfume completo usando perfumeId
            await loadPerfume()
        }
        .fullScreenCover(isPresented: $showingDetailView) {
            if let perfume = perfume,
               let brand = brandViewModel.getBrand(byKey: perfume.brand) {
                PerfumeDetailView(
                    perfume: perfume,
                    brand: brand,
                    profile: nil
                )
            }
        }
    }

    private func loadPerfume() async {
        do {
            perfume = try await perfumeViewModel.fetchPerfume(byKey: wishlistItem.perfumeId)
        } catch {
            print("❌ Error loading perfume \(wishlistItem.perfumeId): \(error)")
        }
    }
}
