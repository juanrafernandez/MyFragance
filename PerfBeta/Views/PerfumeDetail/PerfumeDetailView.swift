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

    // Nombre de marca formateado
    private var displayBrandName: String {
        brand?.name ?? perfume.brandName ?? perfume.brand.capitalized
    }

    var body: some View {
        NavigationView {
            ZStack {
                GradientView(preset: .champan)
                    .edgesIgnoringSafeArea(.all)

                ScrollView {
                    VStack(alignment: .center, spacing: 0) {
                        headerSection
                        descriptionSection
                        olfactoryPyramidSection
                        recommendationsSection
                    }
                    .padding(.top, 16)
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
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Header Section (Diseño Editorial)
    private var headerSection: some View {
        VStack(spacing: 24) {
            // Imagen del perfume con contenedor blanco
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .frame(width: 200, height: 200)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)

                KFImage(perfume.imageURL.flatMap { URL(string: $0) })
                    .placeholder {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 40))
                            .foregroundColor(AppColor.textSecondary.opacity(0.3))
                    }
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
            }

            // Nombre y marca con estilo editorial
            VStack(spacing: 8) {
                Text(perfume.name)
                    .font(.custom("Georgia", size: 28))
                    .foregroundColor(AppColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text(displayBrandName.uppercased())
                    .font(.system(size: 12, weight: .medium))
                    .tracking(2)
                    .foregroundColor(AppColor.textSecondary)
            }

            // Separador elegante
            Rectangle()
                .fill(AppColor.textSecondary.opacity(0.2))
                .frame(width: 40, height: 1)
                .padding(.top, 8)
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.bottom, 32)
    }

    // MARK: - Secciones de contenido (Diseño Editorial)

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Título de sección
            Text("DESCRIPCIÓN")
                .font(.system(size: 11, weight: .medium))
                .tracking(2)
                .foregroundColor(AppColor.textSecondary)

            // Texto de descripción
            Text(perfume.description)
                .font(.custom("Georgia", size: 15))
                .foregroundColor(AppColor.textPrimary)
                .lineSpacing(6)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.bottom, 32)
    }

    private var olfactoryPyramidSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Título de sección
            Text("PIRÁMIDE OLFATIVA")
                .font(.system(size: 11, weight: .medium))
                .tracking(2)
                .foregroundColor(AppColor.textSecondary)

            // Notas con diseño editorial
            VStack(spacing: 16) {
                pyramidNoteRow(title: "Salida", notes: perfume.topNotes)
                pyramidNoteRow(title: "Corazón", notes: perfume.heartNotes)
                pyramidNoteRow(title: "Fondo", notes: perfume.baseNotes)
            }
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.bottom, 32)
    }

    private var recommendationsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Título de sección
            Text("CARACTERÍSTICAS")
                .font(.system(size: 11, weight: .medium))
                .tracking(2)
                .foregroundColor(AppColor.textSecondary)

            // Grid de características
            VStack(spacing: 16) {
                // Proyección y Duración
                HStack(spacing: 24) {
                    characteristicItem(
                        title: "Proyección",
                        value: Projection(rawValue: perfume.projection)?.displayName ?? "N/A"
                    )
                    characteristicItem(
                        title: "Duración",
                        value: Duration(rawValue: perfume.duration)?.displayName ?? "N/A"
                    )
                }

                // Separador
                Rectangle()
                    .fill(AppColor.textSecondary.opacity(0.1))
                    .frame(height: 1)

                // Estación
                let seasonNames = perfume.recommendedSeason.compactMap { seasonKey in
                    Season(rawValue: seasonKey)?.displayName
                }
                if !seasonNames.isEmpty {
                    characteristicTagsRow(title: "Estación", values: seasonNames)
                }

                // Ocasión
                let occasionNames = perfume.occasion.compactMap { occasionKey in
                    Occasion(rawValue: occasionKey)?.displayName
                }
                if !occasionNames.isEmpty {
                    characteristicTagsRow(title: "Ocasión", values: occasionNames)
                }
            }
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.bottom, 40)
    }

    // MARK: - Componentes auxiliares del diseño editorial

    private func pyramidNoteRow(title: String, notes: [String]?) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppColor.textPrimary)
                .frame(width: 70, alignment: .leading)

            Text(getNoteNames(from: notes))
                .font(.custom("Georgia", size: 14))
                .foregroundColor(AppColor.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func characteristicItem(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppColor.textSecondary)

            Text(value)
                .font(.custom("Georgia", size: 16))
                .foregroundColor(AppColor.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func characteristicTagsRow(title: String, values: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppColor.textSecondary)

            // Tags en flow layout
            FlowLayout(spacing: 8) {
                ForEach(values, id: \.self) { value in
                    Text(value)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(AppColor.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.5))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppColor.textSecondary.opacity(0.2), lineWidth: 1)
                        )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
            #if DEBUG
            print("🔍 [PerfumeDetail] getNoteNames: keys is nil or empty")
            #endif
            return "N/A"
        }

        #if DEBUG
        print("🔍 [PerfumeDetail] getNoteNames received: \(Array(noteKeys))")
        #endif
        #if DEBUG
        print("🔍 [PerfumeDetail] notesViewModel.notes count: \(notesViewModel.notes.count)")
        #endif

        // ✅ FALLBACK: Si notesViewModel.notes está vacío, asumir que keys son nombres directos
        if notesViewModel.notes.isEmpty {
            #if DEBUG
            print("⚠️ [PerfumeDetail] notesViewModel.notes is empty, using keys as names")
            #endif
            return Array(noteKeys).joined(separator: ", ")
        }

        // Intentar lookup en notesViewModel
        let names = noteKeys.compactMap { key -> String? in
            // Busca la nota en el caché del ViewModel
            let found = notesViewModel.notes.first { $0.key == key }?.name
            if found == nil {
                #if DEBUG
                print("⚠️ [PerfumeDetail] Note not found in notesViewModel: \(key)")
                #endif
            }
            return found
        }

        // Si no se encontraron nombres, usar keys directamente como fallback
        if names.isEmpty {
            #if DEBUG
            print("⚠️ [PerfumeDetail] No names found in lookup, using keys as fallback")
            #endif
            return Array(noteKeys).joined(separator: ", ")
        }

        #if DEBUG
        print("✅ [PerfumeDetail] Found note names: \(names)")
        #endif
        return names.joined(separator: ", ")
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
       // ✅ Use perfume.id (document ID) for consistency with storage
       userViewModel.wishlistPerfumes.contains { $0.perfumeId == perfume.id }
    }
    private func toggleWishlist() {
       Task {
            if isInWishlist {
                showRemoveFromWishlistAlert = true
            } else {
                // ✅ Use perfume.id (document ID) not perfume.key for cache consistency
                await userViewModel.addToWishlist(perfumeId: perfume.id)
            }
        }
    }
    private func removeFromWishlist() {
       Task {
            // ✅ Use perfume.id (document ID) for consistency
            await userViewModel.removeFromWishlist(perfumeId: perfume.id)
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
                .foregroundColor(AppColor.textPrimary)

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
            // ✅ Fix: Don't pass asset name as URL string - let URL(string:) return nil for invalid URLs
            KFImage(perfume.imageURL.flatMap { URL(string: $0) })
                .placeholder {
                    ZStack {
                        Color.gray.opacity(0.2)
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.gray.opacity(0.5))
                    }
                }
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
