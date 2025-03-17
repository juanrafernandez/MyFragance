import SwiftUI
import Kingfisher

struct PerfumeDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var familiaOlfativaViewModel: FamilyViewModel
    @EnvironmentObject var brandViewModel: BrandViewModel
    @EnvironmentObject var userViewModel: UserViewModel

    let perfume: Perfume
    let relatedPerfumes: [Perfume]
    let brand: Brand?

    @State private var showRemoveFromWishlistAlert = false
    @AppStorage("selectedGradientPreset") private var selectedGradientPreset: GradientPreset = .champan

    var body: some View {
        NavigationView {
            ZStack {
                GradientView(preset: selectedGradientPreset)
                    .edgesIgnoringSafeArea(.all)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        headerSection
                        descriptionSection
                        olfactoryPyramidSection
                        recommendationsSection
                        relatedProductsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical)
                }
            }
            .navigationTitle("Ficha")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    closeButton
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    wishlistButton
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .center) {
            // Perfume Image
            KFImage(URL(string: perfume.imageURL ?? "givenchy_gentleman_Intense"))
                .placeholder { Image("givenchy_gentleman_Intense").resizable().scaledToFit() }
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: 160) // Adjust height as needed
                .cornerRadius(12)
                .shadow(radius: 1)
                .padding(.bottom, 10)

            // Perfume Name and Brand
            HStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(perfume.name)
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    Text(brand?.name ?? perfume.brand)
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if let brandLogoURL = brand?.imagenURL, let url = URL(string: brandLogoURL) {
                    KFImage(url)
                        .placeholder { Image("brand_placeholder").resizable().scaledToFit() }
                        .resizable()
                        .scaledToFit()
                        .frame(width: 45, height: 45) // Adjust size as needed
                        .cornerRadius(22.5)
                        .shadow(radius: 1)
                } else {
                    Image("brand_placeholder")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 45, height: 45) // Adjust size as needed
                        .cornerRadius(22.5)
                        .shadow(radius: 1)
                }
            }
            .padding(.bottom, 6)

            Divider().opacity(0.3)
        }
        .padding(.horizontal)
        .padding(.bottom, 15)
    }

    // MARK: - Description Section (No Changes)
    private var descriptionSection: some View {
        SectionView(title: "Descripción") {
            Text(perfume.description)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Olfactory Pyramid Section (No Changes)
    private var olfactoryPyramidSection: some View {
        SectionView(title: "Pirámide Olfativa") {
            VStack(alignment: .leading, spacing: 8) {
                pyramidNoteView(title: "Salida", notes: perfume.topNotes)
                pyramidNoteView(title: "Corazón", notes: perfume.heartNotes)
                pyramidNoteView(title: "Fondo", notes: perfume.baseNotes)
            }
        }
    }

    private func pyramidNoteView(title: String, notes: [String]?) -> some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            Text(notes?.prefix(3).joined(separator: ", ") ?? "N/A")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Recommendations Section (No Changes)
    private var recommendationsSection: some View {
        SectionView(title: "Recomendaciones") {
            VStack(alignment: .leading, spacing: 8) {
                recommendationRow(title: "Proyección", value: perfume.projection.capitalized)
                recommendationRow(title: "Duración", value: perfume.duration.capitalized)
                recommendationRow(title: "Estación", value: perfume.recommendedSeason.joined(separator: ", "))
                recommendationRow(title: "Ocasión", value: perfume.occasion.joined(separator: ", "))
            }
        }
    }

    private func recommendationRow(title: String, value: String) -> some View {
        HStack {
            Text(title + ":")
                .font(.headline)
                .foregroundColor(.primary)
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Related Products Section (No Changes)
    private var relatedProductsSection: some View {
        if !relatedPerfumes.isEmpty {
            return AnyView(
                SectionView(title: "Productos Relacionados") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(relatedPerfumes) { relatedPerfume in
                                // **Pass brand to RelatedPerfumeCard here**
                                RelatedPerfumeCard(perfume: relatedPerfume, brand: brandViewModel.getBrand(byKey: relatedPerfume.brand))
                            }
                        }
                    }
                }
            )
        } else {
            return AnyView(EmptyView())
        }
    }

    // MARK: - Close Button (No Changes)
    private var closeButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            Image(systemName: "chevron.down")
                .font(.title3)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Wishlist Button - UPDATED to use UserViewModel for adding/removing
    private var wishlistButton: some View {
        Button(action: {
            Task {
                let wishlistItem = WishlistItem(perfumeKey: perfume.key, brandKey: perfume.brand, imageURL: perfume.imageURL, rating: perfume.popularity)
                if isPerfumeInWishlist() {
                    showRemoveFromWishlistAlert = true
                } else {
                    await userViewModel.addToWishlist(userId: "testUserId", wishlistItem: wishlistItem) // Use WishlistItem for adding
                }
            }
        }) {
            Image(systemName: isPerfumeInWishlist() ? "heart.fill" : "heart")
                .font(.title3)
                .foregroundColor(isPerfumeInWishlist() ? .red : .secondary)
        }
        .alert(isPresented: $showRemoveFromWishlistAlert) {
            Alert(
                title: Text("Eliminar de Lista de Deseos"),
                message: Text("¿Estás seguro de que deseas eliminar este perfume de tu lista de deseos?"),
                primaryButton: .destructive(Text("Eliminar")) {
                    Task {
                        let wishlistItem = WishlistItem(perfumeKey: perfume.key, brandKey: perfume.brand, imageURL: perfume.imageURL, rating: perfume.popularity)
                        await userViewModel.removeFromWishlist(userId: "testUserId", wishlistItem: wishlistItem) // Use WishlistItem for removing
                    }
                },
                secondaryButton: .cancel()
            )
        }
    }

    // Helper function to check if perfume is in wishlist using UserViewModel - UPDATED for WishlistItem comparison
    private func isPerfumeInWishlist() -> Bool {
        return userViewModel.wishlistPerfumes.contains { wishlistItem in
            return wishlistItem == WishlistItem(perfumeKey: perfume.key, brandKey: perfume.brand, imageURL: perfume.imageURL, rating: perfume.popularity) // Compare WishlistItem
        }
    }
}

// MARK: - Reusable Section View for Styling (No Changes)
struct SectionView<Content: View>: View {
    let title: String
    let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.bottom, 5)
                .padding(.horizontal, 20)
            content()
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(10)
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Related Perfume Card (No Changes)
struct RelatedPerfumeCard: View {
    let perfume: Perfume
    let brand: Brand?

    var body: some View {
        VStack {
            KFImage(URL(string: perfume.imageURL ?? "montblanc_legend_blue"))
                .placeholder { Image("montblanc_legend_blue").resizable().scaledToFit() }
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .cornerRadius(10)
                .padding(.bottom, 4)

            Text(perfume.name)
                .font(.subheadline)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            if let brandName = brand?.name {
                Text(brandName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            } else {
                Text(perfume.brand)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
        }
        .frame(width: 100)
    }
}
