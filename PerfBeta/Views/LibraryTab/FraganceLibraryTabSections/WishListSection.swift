import SwiftUI

struct WishListSection<Destination: View>: View {
    let title: String
    let perfumes: [WishlistItem]
    let message: String
    let maxDisplayCount: Int
    let seeMoreDestination: Destination
    @ObservedObject var userViewModel: UserViewModel  // ✅ AÑADIDO

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(Color("textoPrincipal"))
                Spacer()
                if !perfumes.isEmpty {
                    NavigationLink(destination: seeMoreDestination) {
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

            // ✅ LOADING STATE mientras carga
            if userViewModel.isLoading && perfumes.isEmpty {
                LoadingView(message: "Cargando...", style: .inline)
                    .frame(height: 100)
            }
            // ✅ EMPTY STATE compacto
            else if perfumes.isEmpty {
                EmptyStateView(
                    type: .noWishlist,
                    action: {
                        // TODO: Navegar a tab de exploración
                        print("Navigate to explore tab")
                    },
                    compact: true  // ✅ Modo compacto
                )
                .frame(height: 150)  // ✅ Altura fija compacta
            } else {
                VStack(alignment: .leading, spacing: 1) {
                    ForEach(perfumes.prefix(maxDisplayCount), id: \.id) { perfume in
                        WishListRowView(perfume: perfume)
                    }
                }
            }
        }
    }
}

struct WishListRowView: View {
    let perfume: WishlistItem
    @EnvironmentObject var brandViewModel: BrandViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel

    @State private var showingDetailView = false
    @State private var detailedPerfume: Perfume? = nil
    @State private var detailedBrand: Brand? = nil

    var body: some View {
        Button {
            showingDetailView = true
        } label: {
            HStack(spacing: 0) {
                // Imagen
                Image(perfume.imageURL ?? "placeholder")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 2) {
                     if let detailedPerfume = detailedPerfume {
                        Text(detailedPerfume.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color("textoPrincipal"))
                            .lineLimit(2)
                            .truncationMode(.tail)
                    } else {
                        Text(perfume.perfumeKey) // Fallback
                           .font(.system(size: 14, weight: .semibold))
                           .foregroundColor(Color("textoPrincipal"))
                           .lineLimit(2)
                           .truncationMode(.tail)
                    }
                    
                    if let brand = detailedBrand {
                        Text(brand.name)
                           .font(.system(size: 12))
                           .foregroundColor(Color("textoSecundario"))
                           .lineLimit(2)
                           .truncationMode(.tail)
                    } else {
                        Text(perfume.brandKey) // Fallback
                            .font(.system(size: 12))
                            .foregroundColor(Color("textoSecundario"))
                            .lineLimit(2)
                            .truncationMode(.tail)
                    }
                }
                
                Spacer()

                if perfume.rating > 0 {
                    HStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 12))
                        Text(String(format: "%.1f", perfume.rating))
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
            }
            .background(Color.clear)
            .task {
                await loadPerfumeAndBrand()
            }
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showingDetailView) {
            if let perfume = detailedPerfume, let brand = detailedBrand {
                PerfumeDetailView(
                    perfume: perfume,
                    brand: brand,
                    profile: nil
                )
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func loadPerfumeAndBrand() async {
        do {
            if detailedPerfume == nil,
               let fetchedPerfume = try await perfumeViewModel.getPerfume(byKey: perfume.perfumeKey) {
                detailedPerfume = fetchedPerfume
            }
            
            if detailedBrand == nil,
               let fetchedBrand = brandViewModel.getBrand(byKey: perfume.brandKey) {
                detailedBrand = fetchedBrand
            }
        } catch {
            print("Error loading perfume or brand details in WishListRowView: \(error)")
        }
    }
}
