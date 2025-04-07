import SwiftUI

// MARK: - Compact Section con mensaje para listas vacías (CORREGIDO)
struct WishListSection<Destination: View>: View {
    let title: String
    let perfumes: [WishlistItem]
    let message: String
    let maxDisplayCount: Int
    let seeMoreDestination: Destination

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

            if perfumes.isEmpty {
                // Mostrar mensaje si la lista está vacía
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(Color("textoSecundario"))
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 10)
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
            HStack(spacing: 15) {
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
                        Text(perfume.perfumeKey)
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
                        Text(perfume.brandKey)
                            .font(.system(size: 12))
                            .foregroundColor(Color("textoSecundario"))
                            .lineLimit(2)
                            .truncationMode(.tail)
                    }
                }
                
                Spacer()

                // Display Rating if available
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
            .padding(.vertical, 5)
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
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity) // Asegura que ocupe el ancho disponible
    }
    
    private func loadPerfumeAndBrand() async {
        do {
            // Fetch Perfume
            if let perfume = try await perfumeViewModel.getPerfume(byKey: perfume.perfumeKey) {
                detailedPerfume = perfume
            }
            
            // Fetch Brand
            if let brand = brandViewModel.getBrand(byKey: perfume.brandKey) {
                detailedBrand = brand
            }
        } catch {
            print("Error loading perfume or brand: \(error)")
        }
    }
}
