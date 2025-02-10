import SwiftUI

struct PerfumeDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var wishlistManager: WishlistManager
    @EnvironmentObject var familiaOlfativaViewModel: FamilyViewModel

    let perfume: Perfume
    let relatedPerfumes: [Perfume]

    @State private var showRemoveFromFavoritesAlert = false
    @State private var showRemoveFromWishlistAlert = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    perfumeHeaderView()
                    perfumeDescriptionView()
                    olfactoryPyramidView()
                    recommendationsView()
                    relatedProductsView()
                }
            }
            .navigationTitle("Ficha")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: closeButton,
                trailing: actionButtons
            )
        }
    }

    // MARK: - Header View
    private func perfumeHeaderView() -> some View {
        HStack(spacing: 16) {
            Image(perfume.imageURL ?? "placeholder")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .cornerRadius(12)

            VStack(alignment: .leading, spacing: 8) {
                Text(perfume.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(Color("textoPrincipal"))

                Text(perfume.brand)
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Text(perfume.family.capitalized)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal)
    }

    // MARK: - Description View
    private func perfumeDescriptionView() -> some View {
        Text(perfume.description)
            .font(.subheadline)
            .foregroundColor(Color("textoSecundario"))
            .padding(.horizontal)
    }

    // MARK: - Olfactory Pyramid View
    private func olfactoryPyramidView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pirámide Olfativa")
                .font(.headline)
                .foregroundColor(Color("textoPrincipal"))

            Text("Salida: \(perfume.topNotes?.prefix(2).joined(separator: ", ") ?? "N/A")")
                .font(.subheadline)
                .foregroundColor(Color("textoSecundario"))

            Text("Corazón: \(perfume.heartNotes?.dropFirst(2).prefix(2).joined(separator: ", ") ?? "N/A")")
                .font(.subheadline)
                .foregroundColor(Color("textoSecundario"))

            Text("Fondo: \(perfume.baseNotes?.suffix(2).joined(separator: ", ") ?? "N/A")")
                .font(.subheadline)
                .foregroundColor(Color("textoSecundario"))
        }
        .padding(.horizontal)
    }

    // MARK: - Recommendations View
    private func recommendationsView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Intensidad y Ocasión")
                .font(.headline)
                .foregroundColor(Color("textoPrincipal"))

            Text("Proyección: \(perfume.projection.capitalized)")
                .font(.subheadline)
                .foregroundColor(Color("textoSecundario"))

            Text("Duración: \(perfume.duration.capitalized)")
                .font(.subheadline)
                .foregroundColor(Color("textoSecundario"))

            let season = familiaOlfativaViewModel.getRecommendedSeason(byID: perfume.family)?.joined(separator: ", ") ?? "No disponible"
            Text("Estación: \(season)")
                .font(.subheadline)
                .foregroundColor(season == "No disponible" ? .red : Color("textoSecundario"))

            let occasion = familiaOlfativaViewModel.getOcasion(byID: perfume.family)?.joined(separator: ", ") ?? "No disponible"
            Text("Ocasión: \(occasion)")
                .font(.subheadline)
                .foregroundColor(occasion == "No disponible" ? .red : Color("textoSecundario"))
        }
        .padding(.horizontal)
    }

    // MARK: - Related Products View
    private func relatedProductsView() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if relatedPerfumes.isEmpty {
                Text("No hay productos relacionados.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                Text("Productos Relacionados")
                    .font(.headline)
                    .foregroundColor(Color("textoPrincipal"))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(relatedPerfumes) { relatedPerfume in
                            VStack {
                                Image(relatedPerfume.imageURL ?? "placeholder")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                    .cornerRadius(8)

                                Text(relatedPerfume.name)
                                    .font(.caption)
                                    .foregroundColor(Color("textoPrincipal"))
                                    .lineLimit(1)
                            }
                            .frame(width: 100)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Close Button
    private var closeButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "xmark")
                .foregroundColor(Color("textoPrincipal"))
        }
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 16) {
            wishlistButton
        }
    }

    private var wishlistButton: some View {
        Button(action: {
            if wishlistManager.isInWishlist(perfume) {
                showRemoveFromWishlistAlert = true
            } else {
                wishlistManager.addToWishlist(perfume)
            }
        }) {
            Image(systemName: wishlistManager.isInWishlist(perfume) ? "cart.fill" : "cart")
                .foregroundColor(wishlistManager.isInWishlist(perfume) ? .blue : .gray)
        }
        .alert(isPresented: $showRemoveFromWishlistAlert) {
            Alert(
                title: Text("Eliminar de Lista de Deseos"),
                message: Text("¿Estás seguro de que deseas eliminar este perfume de tu lista de deseos?"),
                primaryButton: .destructive(Text("Eliminar")) {
                    wishlistManager.removeFromWishlist(perfume)
                },
                secondaryButton: .cancel()
            )
        }
    }
}
