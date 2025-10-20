import SwiftUI
import Kingfisher

struct PerfumeDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var familyViewModel: FamilyViewModel
    @EnvironmentObject var brandViewModel: BrandViewModel
    @EnvironmentObject var userViewModel: UserViewModel
    @EnvironmentObject var notesViewModel: NotesViewModel

    let perfume: Perfume
    let brand: Brand?
    let profile: OlfactiveProfile?

    @State private var relatedPerfumes: [Perfume] = []
    @State private var isLoadingRelated = false
    @State private var errorMessage: IdentifiableString?
    @State private var showRemoveFromWishlistAlert = false
    @AppStorage("selectedGradientPreset") private var selectedGradientPreset: GradientPreset = .champan

    var body: some View {
        NavigationView {
            ZStack {
                GradientView(preset: selectedGradientPreset)
                    .edgesIgnoringSafeArea(.all)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        headerSection.padding(.horizontal, 20)
                        descriptionSection
                        olfactoryPyramidSection
                        recommendationsSection
                        // relatedProductsSection
                    }
                    .padding(.vertical)
                }

                if isLoadingRelated {
                    ProgressView().scaleEffect(1.5)
                }
            }
            .navigationTitle("Ficha")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { closeButton }
                ToolbarItem(placement: .navigationBarTrailing) { wishlistButton }
            }
            //.task { await loadRelatedPerfumes(with: profile) }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Header Section
    private var headerSection: some View {
         VStack(alignment: .center) {
            KFImage(URL(string: perfume.imageURL ?? "givenchy_gentleman_Intense"))
                .placeholder { Image("givenchy_gentleman_Intense").resizable().scaledToFit() }
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .cornerRadius(12)
                .shadow(radius: 1)
                .padding(.bottom, 10)

            HStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(perfume.name)
                        .font(.system(size: 30, weight: .light))
                        .foregroundColor(Color("textoPrincipal"))
                        .lineLimit(2)

                    Text(brand?.name ?? perfume.brand)
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(Color("textoSecundario"))
                }
                Spacer()

                if let brandLogoURL = brand?.imagenURL, let url = URL(string: brandLogoURL) {
                    KFImage(url)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 45, height: 45)
                        .cornerRadius(22.5)
                        .shadow(radius: 1)
                } else {
                    Image("brand_placeholder")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 45, height: 45)
                        .cornerRadius(22.5)
                        .shadow(radius: 1)
                }
            }
            .padding(.bottom, 6)
            Divider().opacity(0.3)
        }
    }

    // MARK: - Secciones de contenido
    private var descriptionSection: some View {
        SectionView(title: "Descripción") {
            Text(perfume.description)
                .font(.system(size: 15, weight: .thin))
                .foregroundColor(Color("textoSecundario"))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var olfactoryPyramidSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Pirámide Olfativa".uppercased())
                .font(.system(size: 15, weight: .light))
                .foregroundColor(Color("textoPrincipal"))
                .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 8) {
                pyramidNoteView(title: "Salida", notes: perfume.topNotes)
                pyramidNoteView(title: "Corazón", notes: perfume.heartNotes)
                pyramidNoteView(title: "Fondo", notes: perfume.baseNotes)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .cornerRadius(10)
        }
    }

    private var recommendationsSection: some View {
        SectionView(title: "Recomendaciones") {
            VStack(alignment: .leading, spacing: 8) {
                // --- CAMBIO 1: Usar displayName para Projection ---
                DetailRow(
                    title: "Proyección",
                    // Intenta crear el enum desde el rawValue, obtén su displayName, o usa "N/A"
                    value: Projection(rawValue: perfume.projection)?.displayName ?? "N/A"
                )

                // --- CAMBIO 2: Usar displayName para Duration ---
                DetailRow(
                    title: "Duración",
                    value: Duration(rawValue: perfume.duration)?.displayName ?? "N/A"
                )

                // --- CAMBIO 3: Usar displayName para Season (mapeando el array) ---
                let seasonNames = perfume.recommendedSeason.compactMap { seasonKey in
                    Season(rawValue: seasonKey)?.displayName
                }.joined(separator: ", ") // Une los nombres encontrados
                DetailRow(
                    title: "Estación",
                    // Muestra los nombres unidos o "N/A" si no se encontró ninguno
                    value: seasonNames.isEmpty ? "N/A" : seasonNames
                )

                // --- CAMBIO 4: Usar displayName para Occasion (mapeando el array) ---
                let occasionNames = perfume.occasion.compactMap { occasionKey in
                    Occasion(rawValue: occasionKey)?.displayName
                }.joined(separator: ", ") // Une los nombres encontrados
                DetailRow(
                    title: "Ocasión",
                    value: occasionNames.isEmpty ? "N/A" : occasionNames
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var relatedProductsSection: some View {
        // ... (código como antes) ...
         Group {
            if let error = errorMessage {
                RelatedProductsErrorView(error: error) {
                    Task { await loadRelatedPerfumes(with: profile) }
                }
                .padding(.horizontal, 20)
            } else if !relatedPerfumes.isEmpty {
                SectionView(title: "Productos Relacionados") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(relatedPerfumes) { perfume in
                                RelatedPerfumeCard(
                                    perfume: perfume,
                                    brand: brandViewModel.getBrand(byKey: perfume.brand)
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Funciones auxiliares

    // --- CAMBIO 2: Función auxiliar para obtener nombres de notas ---
    private func getNoteNames(from keys: [String]?) -> String {
        guard let noteKeys = keys?.prefix(3), !noteKeys.isEmpty else {
            return "N/A"
        }

        let names = noteKeys.compactMap { key -> String? in
            // Busca la nota en el caché del ViewModel
            // Asume que tu struct 'Notes' tiene 'key: String' y 'name: String'
            notesViewModel.notes.first { $0.key == key }?.name
        }

        return names.isEmpty ? "N/A" : names.joined(separator: ", ")
    }

    // --- CAMBIO 3: pyramidNoteView usa getNoteNames ---
    private func pyramidNoteView(title: String, notes: [String]?) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title + ":")
                .font(.system(size: 15, weight: .light))
                .foregroundColor(Color("textoPrincipal"))
                .frame(minWidth: 70, alignment: .leading)

            // Llama a la función auxiliar para obtener los nombres
            Text(getNoteNames(from: notes))
                .font(.system(size: 15, weight: .thin))
                .foregroundColor(Color("textoSecundario"))

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // Renombrada: DetailRow (antes recommendationRow)
    private func DetailRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title + ":")
                .font(.system(size: 15, weight: .light))
                .foregroundColor(Color("textoPrincipal"))
                .frame(minWidth: 70, alignment: .leading)

            Text(value)
                .font(.system(size: 15, weight: .thin))
                .foregroundColor(Color("textoSecundario"))

            Spacer()
        }
    }


    // MARK: - Botones Toolbar
     private var closeButton: some View {
          Button(action: { presentationMode.wrappedValue.dismiss() }) {
            Image(systemName: "chevron.down")
                .font(.title3)
                .foregroundColor(.secondary)
        }
     }
     private var wishlistButton: some View {
          Button(action: toggleWishlist) {
            Image(systemName: isInWishlist ? "heart.fill" : "heart")
                .font(.title3)
                .foregroundColor(isInWishlist ? .red : .secondary)
        }
        .alert(isPresented: $showRemoveFromWishlistAlert) {
            Alert(
                title: Text("Eliminar de Lista de Deseos"),
                message: Text("¿Estás seguro de que deseas eliminar este perfume de tu lista de deseos?"),
                primaryButton: .destructive(Text("Eliminar"), action: removeFromWishlist),
                secondaryButton: .cancel()
            )
        }
     }

    // MARK: - Lógica Wishlist
    private var isInWishlist: Bool {
       userViewModel.wishlistPerfumes.contains { $0.perfumeKey == perfume.key }
    }
    private func toggleWishlist() {
       Task {
            let item = WishlistItem(
                perfumeKey: perfume.key,
                brandKey: perfume.brand,
                imageURL: perfume.imageURL,
                rating: perfume.popularity,
                orderIndex: -1
            )

            if isInWishlist {
                showRemoveFromWishlistAlert = true
            } else {
                await userViewModel.addToWishlist(wishlistItem: item)
            }
        }
    }
    private func removeFromWishlist() {
       Task {
            let item = WishlistItem(
                perfumeKey: perfume.key,
                brandKey: perfume.brand,
                imageURL: perfume.imageURL,
                rating: perfume.popularity,
                orderIndex: -1
            )
            await userViewModel.removeFromWishlist(wishlistItem: item)
        }
    }

    // MARK: - Carga de datos
    private func loadRelatedPerfumes(with profile: OlfactiveProfile?) async {
         guard let profile = profile else {
            isLoadingRelated = false
            return
        }

        isLoadingRelated = true
        errorMessage = nil

        do {
            // let recommended = try await OlfactiveProfileHelper.suggestPerfumes(...)
             let recommended: [(perfumeId: String, score: Double)] = [] // Placeholder

            relatedPerfumes = recommended.compactMap { recommendation in
                perfumeViewModel.perfumes.first { $0.id == recommendation.perfumeId }
            }
        } catch {
            errorMessage = IdentifiableString(value: "Error simulado al cargar relacionados.")
            relatedPerfumes = []
        }

        isLoadingRelated = false
    }
}

// MARK: - Vistas auxiliares
private struct RelatedProductsErrorView: View {
    let error: IdentifiableString
    let retryAction: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
            Text("Error al cargar productos relacionados")
                .font(.headline)
            Text(error.value)
                .font(.subheadline)
                .multilineTextAlignment(.center)
            Button("Reintentar", action: retryAction)
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(15)
    }
}

// SectionView ahora NO aplica fondo
struct SectionView<Content: View>: View {
    let title: String
    let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title.uppercased())
                .font(.system(size: 15, weight: .light))
                .foregroundColor(Color("textoPrincipal"))

            content()
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .cornerRadius(10)
        }
        .padding(.horizontal, 20)
    }
}

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
