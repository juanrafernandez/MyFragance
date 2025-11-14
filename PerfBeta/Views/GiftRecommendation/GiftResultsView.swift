import SwiftUI

struct GiftResultsView: View {
    @EnvironmentObject var giftRecommendationViewModel: GiftRecommendationViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var brandViewModel: BrandViewModel
    @Environment(\.dismiss) var dismiss

    @State private var showingSaveDialog = false
    @State private var profileNickname = ""
    @State private var isLoadingPerfumes = false
    @State private var selectedPerfume: Perfume? = nil  // ✅ Para navegación
    @State private var hiddenRecommendationIds: Set<String> = []  // ✅ Para swipe-to-delete

    // ✅ Recomendaciones visibles: primeras 10 que no están ocultas
    private var visibleRecommendations: [GiftRecommendation] {
        giftRecommendationViewModel.recommendations
            .filter { !hiddenRecommendationIds.contains($0.id) }
            .prefix(10)
            .map { $0 }
    }

    var body: some View {
        List {
            // Header Section
            Section {
                headerSection
                    .listRowInsets(EdgeInsets(top: 20, leading: 0, bottom: 10, trailing: 0))
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            // Recomendaciones Section
            Section {
                if isLoadingPerfumes {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding(.top, 50)
                    .listRowInsets(EdgeInsets())
                } else {
                    ForEach(Array(visibleRecommendations.enumerated()), id: \.element.id) { index, recommendation in
                        recommendationCard(recommendation: recommendation, rank: index + 1)
                            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    hiddenRecommendationIds.insert(recommendation.id)
                                    #if DEBUG
                                    print("🗑️ [GiftResults] Hidden recommendation: \(recommendation.perfumeKey)")
                                    print("   Visible count: \(visibleRecommendations.count)")
                                    #endif
                                } label: {
                                    Label("Ocultar", systemImage: "eye.slash")
                                }
                            }
                    }
                }
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            // Botones Section
            Section {
                saveProfileButton
                    .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 8, trailing: 0))

                newSearchButton
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 30, trailing: 0))
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .padding(.horizontal, 25)
        .sheet(isPresented: $showingSaveDialog) {
            saveProfileDialog
        }
        .fullScreenCover(item: $selectedPerfume) { perfume in
            // ✅ Obtener brand para el detalle
            let brand = brandViewModel.getBrand(for: perfume.brand)

            PerfumeDetailView(
                perfume: perfume,
                brand: brand,
                profile: nil  // No hay perfil olfativo en contexto de regalo
            )
            .environmentObject(perfumeViewModel)
            .environmentObject(brandViewModel)
        }
        .task {
            await loadRecommendedPerfumes()
        }
    }

    // MARK: - Load Perfumes

    private func loadRecommendedPerfumes() async {
        isLoadingPerfumes = true

        // ✅ Obtener TODAS las keys (incluye buffer de 20 perfumes para swipe-to-delete)
        let perfumeKeys = giftRecommendationViewModel.recommendations.map { $0.perfumeKey }

        #if DEBUG
        print("📥 [GiftResults] Loading \(perfumeKeys.count) perfumes (includes buffer): \(perfumeKeys)")
        #endif

        // Cargar los perfumes completos
        await perfumeViewModel.loadPerfumesByKeys(perfumeKeys)

        #if DEBUG
        print("✅ [GiftResults] Loaded perfumes count: \(perfumeViewModel.perfumes.count)")
        print("   Visible recommendations: \(visibleRecommendations.count)")
        // Verificar si los perfumes tienen descripción (solo los primeros 5 para no llenar logs)
        for key in perfumeKeys.prefix(5) {
            if let perfume = perfumeViewModel.getPerfume(byKey: key) {
                let hasDescription = !perfume.description.isEmpty
                let descPreview = perfume.description.isEmpty ? "empty" : String(perfume.description.prefix(50))
                print("   - \(perfume.name): description=\(hasDescription ? "✓" : "✗") (\(descPreview))")
            } else {
                print("   - \(key): NOT FOUND")
            }
        }
        if perfumeKeys.count > 5 {
            print("   ... and \(perfumeKeys.count - 5) more perfumes")
        }
        #endif

        isLoadingPerfumes = false
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "gift.fill")
                .font(.system(size: 50))
                .foregroundColor(Color("champan"))

            Text("Recomendaciones de Regalo")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color("textoPrincipal"))
                .multilineTextAlignment(.center)

            Text("Hemos encontrado \(visibleRecommendations.count) perfumes perfectos")
                .font(.system(size: 15, weight: .light))
                .foregroundColor(Color("textoSecundario"))
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 10)
    }

    // MARK: - Recommendation Card

    private func recommendationCard(recommendation: GiftRecommendation, rank: Int) -> some View {
        // ✅ Buscar metadata del perfume
        let perfumeMetadata = perfumeViewModel.metadataIndex.first(where: { $0.key == recommendation.perfumeKey })
        // ✅ Buscar perfume completo para obtener descripción (usando método optimizado)
        let fullPerfume = perfumeViewModel.getPerfume(byKey: recommendation.perfumeKey)

        return Button(action: {
            // ✅ Establecer perfume seleccionado para navegación
            if let perfume = fullPerfume {
                selectedPerfume = perfume
                #if DEBUG
                print("🎯 [GiftResults] Selected perfume: \(perfume.name)")
                #endif
            }
        }) {
            recommendationCardContent(
                recommendation: recommendation,
                perfume: perfumeMetadata,
                fullPerfume: fullPerfume,
                rank: rank
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func recommendationCardContent(recommendation: GiftRecommendation, perfume: PerfumeMetadata?, fullPerfume: Perfume?, rank: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
                // Ranking badge y confianza condicional
                HStack {
                    Text("#\(rank)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(rankColor(for: rank))
                        )

                    Spacer()

                    // ✅ Confianza condicional según score
                    if recommendation.score >= 75 {
                        confidenceBadge(recommendation.confidenceLevel)
                    }
                }

                // Perfume info
                if let perfume = perfume {
                    HStack(spacing: 12) {
                        // Imagen del perfume
                        if let imageURL = perfume.imageURL, !imageURL.isEmpty {
                            AsyncImage(url: URL(string: imageURL)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                case .failure(_), .empty:
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .overlay(
                                            Image(systemName: "photo")
                                                .foregroundColor(.gray)
                                        )
                                @unknown default:
                                    ProgressView()
                                }
                            }
                            .frame(width: 60, height: 80)
                            .background(Color.black.opacity(0.1))
                            .cornerRadius(8)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            // Nombre del perfume
                            Text(perfume.name)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color("textoPrincipal"))
                                .lineLimit(2)

                            // Marca (obtener nombre completo desde BrandViewModel)
                            Text(brandViewModel.getBrandName(for: perfume.brand))
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color("textoSecundario"))

                            // Stats en una línea
                            HStack(spacing: 12) {
                                // Porcentaje de acierto
                                HStack(spacing: 4) {
                                    Image(systemName: "percent")
                                        .font(.system(size: 10))
                                        .foregroundColor(Color("champan"))
                                    Text(String(format: "%.0f", recommendation.score))
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Color("champan"))
                                }

                                // Popularidad
                                if let popularity = perfume.popularity {
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(Color.orange)
                                        Text(String(format: "%.1f", popularity))
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(Color("textoSecundario"))
                                    }
                                }

                                // Año
                                if let year = perfume.year {
                                    HStack(spacing: 4) {
                                        Image(systemName: "calendar")
                                            .font(.system(size: 10))
                                            .foregroundColor(Color("textoSecundario"))
                                        Text(String(year))
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(Color("textoSecundario"))
                                    }
                                }
                            }

                            // Versatilidad (basado en subfamilias)
                            if let subfamilies = perfume.subfamilies, !subfamilies.isEmpty {
                                let versatilityScore = min(subfamilies.count, 5)
                                HStack(spacing: 4) {
                                    Text("Versatilidad:")
                                        .font(.system(size: 11, weight: .light))
                                        .foregroundColor(Color("textoSecundario"))
                                    ForEach(0..<versatilityScore, id: \.self) { _ in
                                        Image(systemName: "circle.fill")
                                            .font(.system(size: 6))
                                            .foregroundColor(Color("champan"))
                                    }
                                }
                            }
                        }

                        Spacer()
                    }
                } else {
                    // Fallback si no se encuentra el perfume
                    VStack(alignment: .leading, spacing: 4) {
                        Text(recommendation.perfumeKey)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color("textoPrincipal"))

                        HStack(spacing: 4) {
                            Image(systemName: "percent")
                                .font(.system(size: 10))
                                .foregroundColor(Color("champan"))
                            Text(String(format: "%.0f", recommendation.score))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color("champan"))
                        }
                    }
                }

                // Descripción del perfume
                if let perfume = fullPerfume, !perfume.description.isEmpty {
                    Text(perfume.description)
                        .font(.system(size: 13, weight: .light))
                        .foregroundColor(Color("textoSecundario"))
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    // Fallback a la razón de recomendación si no hay descripción
                    Text(recommendation.reason)
                        .font(.system(size: 13, weight: .light))
                        .foregroundColor(Color("textoSecundario"))
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.clear)  // ✅ Sin fondo blanquecino
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(rankColor(for: rank).opacity(0.3), lineWidth: 1)
            )
    }

    // MARK: - Confidence Badge

    private func confidenceBadge(_ level: ConfidenceLevel) -> some View {
        HStack(spacing: 4) {
            Image(systemName: level.icon)
                .font(.system(size: 10))
            Text(level.displayName)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(confidenceColor(level))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(confidenceColor(level).opacity(0.15))
        )
    }

    // MARK: - Save Profile Button

    private var saveProfileButton: some View {
        Button(action: {
            showingSaveDialog = true
        }) {
            HStack {
                Image(systemName: "square.and.arrow.down")
                Text("Guardar Perfil de Regalo")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color("champan"))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding(.top, 10)
    }

    // MARK: - New Search Button

    private var newSearchButton: some View {
        Button(action: {
            Task {
                await giftRecommendationViewModel.startNewFlow()
            }
        }) {
            HStack {
                Image(systemName: "arrow.clockwise")
                Text("Nueva Búsqueda")
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white.opacity(0.1))
            .foregroundColor(Color("textoPrincipal"))
            .cornerRadius(12)
        }
    }

    // MARK: - Save Profile Dialog

    private var saveProfileDialog: some View {
        NavigationView {
            ZStack {
                GradientView(preset: .champan)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 20) {
                    Text("Guardar Perfil")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color("textoPrincipal"))

                    Text("Dale un nombre a este perfil para encontrarlo fácilmente después")
                        .font(.system(size: 15, weight: .light))
                        .foregroundColor(Color("textoSecundario"))
                        .multilineTextAlignment(.center)

                    TextField("Ej: Mamá, Mejor amigo, Compañero trabajo...", text: $profileNickname)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.vertical, 8)

                    Button(action: {
                        Task {
                            await giftRecommendationViewModel.saveProfile(nickname: profileNickname)
                            showingSaveDialog = false
                            profileNickname = ""
                        }
                    }) {
                        Text("Guardar")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                profileNickname.isEmpty
                                    ? Color.gray.opacity(0.3)
                                    : Color("champan")
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(profileNickname.isEmpty)

                    Spacer()
                }
                .padding(.horizontal, 25)
                .padding(.top, 40)
            }
            .navigationBarItems(
                trailing: Button("Cancelar") {
                    showingSaveDialog = false
                    profileNickname = ""
                }
                .foregroundColor(Color("textoPrincipal"))
            )
        }
        .presentationDetents([.medium])
    }

    // MARK: - Modernity Helpers

    private func modernityLabel(for year: Int) -> String {
        let currentYear = Calendar.current.component(.year, from: Date())
        let age = currentYear - year

        if age <= 3 {
            return "Nuevo"
        } else if age <= 7 {
            return "Moderno"
        } else if age <= 15 {
            return "Contemporáneo"
        } else {
            return "Clásico"
        }
    }

    private func modernityColor(for year: Int) -> Color {
        let currentYear = Calendar.current.component(.year, from: Date())
        let age = currentYear - year

        if age <= 3 {
            return Color.green
        } else if age <= 7 {
            return Color.blue
        } else if age <= 15 {
            return Color.purple
        } else {
            return Color.orange
        }
    }

    // MARK: - Helper Methods

    private func rankColor(for rank: Int) -> Color {
        switch rank {
        case 1:
            return Color("champan")
        case 2:
            return Color.blue.opacity(0.8)
        case 3:
            return Color.green.opacity(0.8)
        default:
            return Color.gray
        }
    }

    private func confidenceColor(_ level: ConfidenceLevel) -> Color {
        switch level {
        case .high:
            return Color.green
        case .medium:
            return Color.orange
        case .low:
            return Color.red
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        GiftResultsView()
            .environmentObject(GiftRecommendationViewModel(
                authService: DependencyContainer.shared.authService
            ))
            .environmentObject(PerfumeViewModel(
                perfumeService: DependencyContainer.shared.perfumeService
            ))
            .environmentObject(BrandViewModel(
                brandService: DependencyContainer.shared.brandService
            ))
    }
}
