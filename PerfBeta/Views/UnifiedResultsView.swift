import SwiftUI
import Kingfisher

/// Unified results view that works for both personal test results and gift recommendations
/// Combines the rich perfume list from GiftResultsView with optional profile header information
struct UnifiedResultsView: View {
    // MARK: - Environment
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var brandViewModel: BrandViewModel
    @EnvironmentObject var familyViewModel: FamilyViewModel
    @Environment(\.dismiss) var dismiss

    // MARK: - Configuration
    let mode: ResultsMode
    let onSave: (() -> Void)?
    let onDismiss: (() -> Void)?
    let onRestartTest: (() -> Void)?
    let isStandalone: Bool

    // MARK: - State
    @State private var isLoadingPerfumes = false
    @State private var selectedPerfume: Perfume?
    @State private var hiddenRecommendationIds: Set<String> = []
    @State private var relatedPerfumes: [(perfume: Perfume, score: Double)] = []

    // MARK: - Computed Properties

    /// Recomendaciones visibles (primeras 10 que no están ocultas)
    private var visibleRecommendations: [RecommendationItem] {
        allRecommendations
            .filter { !hiddenRecommendationIds.contains($0.id) }
            .prefix(10)
            .map { $0 }
    }

    /// Todas las recomendaciones (según el modo)
    private var allRecommendations: [RecommendationItem] {
        // Si hay recomendaciones de test olfativo cargadas, usarlas
        if !relatedPerfumes.isEmpty {
            return relatedPerfumes.map { rec in
                RecommendationItem(
                    id: rec.perfume.id,
                    perfumeKey: rec.perfume.key,
                    perfume: rec.perfume,  // Incluir perfume completo
                    score: rec.score,
                    reason: "Coincide con tu perfil olfativo",
                    confidence: scoreToConfidence(rec.score)
                )
            }
        }

        switch mode {
        case .olfactiveProfile(let profile, _):
            // Convertir de OlfactiveProfile a RecommendationItem
            return (profile.recommendedPerfumes ?? []).enumerated().map { index, rec in
                RecommendationItem(
                    id: rec.perfumeId,
                    perfumeKey: rec.perfumeId,
                    perfume: perfumeViewModel.getPerfume(byKey: rec.perfumeId),
                    score: rec.matchPercentage,
                    reason: "Coincide con tu perfil olfativo",
                    confidence: scoreToConfidence(rec.matchPercentage)
                )
            }
        case .giftRecommendations(let recommendations):
            // Convertir de GiftRecommendation a RecommendationItem
            return recommendations.map { rec in
                RecommendationItem(
                    id: rec.id,
                    perfumeKey: rec.perfumeKey,
                    perfume: perfumeViewModel.getPerfume(byKey: rec.perfumeKey),
                    score: rec.score,
                    reason: rec.reason,
                    confidence: rec.confidence
                )
            }
        }
    }

    /// Información del perfil (solo para modo olfactiveProfile)
    private var profileHeaderInfo: ProfileHeaderInfo? {
        switch mode {
        case .olfactiveProfile(let profile, _):
            return ProfileHeaderInfo(
                primaryFamily: profile.families.first?.family ?? "",
                complementaryFamilies: Array(profile.families.dropFirst().prefix(2).map { $0.family }),
                gender: profile.gender,
                description: profile.descriptionProfile,
                intensity: profile.intensity,
                duration: profile.duration,
                experienceLevel: profile.experienceLevel
            )
        case .giftRecommendations:
            return nil
        }
    }

    // MARK: - Initializers

    /// Inicializador para resultados de test olfativo
    init(
        profile: OlfactiveProfile,
        isTestActive: Binding<Bool>,
        onSave: (() -> Void)? = nil,
        onRestartTest: (() -> Void)? = nil,
        isStandalone: Bool = false
    ) {
        self.mode = .olfactiveProfile(profile: profile, isTestActive: isTestActive)
        self.onSave = onSave
        self.onDismiss = nil
        self.onRestartTest = onRestartTest
        self.isStandalone = isStandalone
    }

    /// Inicializador para resultados de regalo
    init(
        giftRecommendations: [GiftRecommendation],
        onSave: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil,
        isStandalone: Bool = false
    ) {
        self.mode = .giftRecommendations(recommendations: giftRecommendations)
        self.onSave = onSave
        self.onDismiss = onDismiss
        self.onRestartTest = nil
        self.isStandalone = isStandalone
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            // Fondo con gradiente (siempre visible)
            GradientView(preset: .champan)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 0) {
                // Barra de navegación cuando se muestra standalone
                if isStandalone {
                    navigationBar
                }

                List {
                    // Header del perfil (solo para test olfativo)
                    if let headerInfo = profileHeaderInfo {
                        Section {
                            profileHeader(headerInfo: headerInfo)
                                .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        // Header genérico para regalo
                        Section {
                            giftHeader
                                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0))
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }

                    // Recomendaciones
                    Section {
                        if isLoadingPerfumes {
                            loadingView
                        } else {
                            ForEach(Array(visibleRecommendations.enumerated()), id: \.element.id) { index, recommendation in
                                recommendationCard(recommendation: recommendation, rank: index + 1)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            hiddenRecommendationIds.insert(recommendation.id)
                                        } label: {
                                            Label("Ocultar", systemImage: "eye.slash")
                                        }
                                    }
                            }
                        }
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                    // Botón de reiniciar test (solo si se proporciona onRestartTest)
                    if let onRestartTest = onRestartTest {
                        Section {
                            restartTestButton(action: onRestartTest)
                                .listRowInsets(EdgeInsets(top: 20, leading: 0, bottom: 30, trailing: 0))
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, AppSpacing.screenHorizontal)
            }
        }
        .fullScreenCover(item: $selectedPerfume) { perfume in
            let brand = brandViewModel.getBrand(for: perfume.brand)
            let profile = profileHeaderInfo != nil ? getOlfactiveProfile() : nil

            PerfumeDetailView(
                perfume: perfume,
                brand: brand,
                profile: profile
            )
            .environmentObject(perfumeViewModel)
            .environmentObject(brandViewModel)
        }
        .task {
            await loadRecommendedPerfumes()
        }
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack {
            Spacer()
            Button(action: {
                onDismiss?()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppColor.textPrimary)
            }
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.top, AppSpacing.spacing16)
        .padding(.bottom, 8)
    }

    // MARK: - Profile Header

    private func profileHeader(headerInfo: ProfileHeaderInfo) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            // Título con icono de perfil
            HStack(spacing: 12) {
                // Icono de perfil circular
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppColor.brandAccent.opacity(0.3), AppColor.brandAccent.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)

                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(AppColor.brandAccent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Tu Perfil Olfativo")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColor.textSecondary)

                    if let primaryFamily = familyViewModel.getFamily(byKey: headerInfo.primaryFamily) {
                        Text(primaryFamily.name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppColor.textPrimary)
                    }
                }
            }

            // Familias complementarias
            let complementaryFamilies = headerInfo.complementaryFamilies
                .compactMap { familyViewModel.getFamily(byKey: $0) }

            if !complementaryFamilies.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundColor(AppColor.brandAccent)

                    Text("Complementarias:")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppColor.textSecondary)

                    Text(complementaryFamilies.map { $0.name }.joined(separator: ", "))
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(AppColor.textPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.1))
                )
            }

            // Nivel de experiencia
            if let experienceLevel = headerInfo.experienceLevel {
                HStack(spacing: 8) {
                    Image(systemName: experienceLevelIcon(for: experienceLevel))
                        .font(.system(size: 12))
                        .foregroundColor(AppColor.brandAccent)

                    Text("Nivel de Experiencia:")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppColor.textSecondary)

                    Text(experienceLevelDisplayName(for: experienceLevel))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppColor.textPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppColor.brandAccent.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(AppColor.brandAccent.opacity(0.3), lineWidth: 1)
                        )
                )
            }

            Divider()
                .background(Color.white.opacity(0.2))

            // Características en grid
            VStack(spacing: 12) {
                // Fila 1: Género + Intensidad
                HStack(spacing: 12) {
                    // Género
                    HStack(spacing: 8) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 14))
                            .foregroundColor(AppColor.brandAccent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Género")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(AppColor.textSecondary)
                            Text(headerInfo.gender.capitalized)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColor.textPrimary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.08))
                    )

                    // Intensidad
                    HStack(spacing: 8) {
                        Image(systemName: intensityIcon(for: headerInfo.intensity))
                            .font(.system(size: 14))
                            .foregroundColor(AppColor.brandAccent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Intensidad")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(AppColor.textSecondary)
                            Text(intensityDisplayName(for: headerInfo.intensity))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColor.textPrimary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.08))
                    )
                }

                // Fila 2: Duración (ocupa todo el ancho)
                HStack(spacing: 8) {
                    Image(systemName: durationIcon(for: headerInfo.duration))
                        .font(.system(size: 14))
                        .foregroundColor(AppColor.brandAccent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Duración")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppColor.textSecondary)
                        Text(durationDisplayName(for: headerInfo.duration))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColor.textPrimary)
                    }
                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.08))
                )
            }

            // Descripción
            if let description = headerInfo.description {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "quote.opening")
                            .font(.system(size: 12))
                            .foregroundColor(AppColor.brandAccent)
                        Text("Descripción")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColor.textPrimary)
                    }

                    Text(description)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(4)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.06))
                )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Gift Header

    private var giftHeader: some View {
        VStack(spacing: 6) {
            Image(systemName: "gift.fill")
                .font(.system(size: 50))
                .foregroundColor(AppColor.brandAccent)
                .padding(.top, 4)

            Text("Recomendaciones de Regalo")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppColor.textPrimary)
                .multilineTextAlignment(.center)

            Text("Hemos encontrado \(visibleRecommendations.count) perfumes perfectos")
                .font(.system(size: 15, weight: .light))
                .foregroundColor(AppColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 5)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppColor.brandAccent))
                .scaleEffect(1.5)
            Spacer()
        }
        .padding(.top, AppSpacing.screenTopInset)
        .listRowInsets(EdgeInsets())
    }

    // MARK: - Recommendation Card

    private func recommendationCard(recommendation: RecommendationItem, rank: Int) -> some View {
        // Usar el perfume que ya tenemos en el recommendation
        let fullPerfume = recommendation.perfume

        // Si no tenemos el perfume completo, buscar en metadata
        let perfumeMetadata = fullPerfume != nil ? nil : perfumeViewModel.metadataIndex.first(where: { $0.key == recommendation.perfumeKey })

        return Button(action: {
            if let perfume = fullPerfume {
                selectedPerfume = perfume
            }
        }) {
            recommendationCardContent(
                recommendation: recommendation,
                perfumeMetadata: perfumeMetadata,
                fullPerfume: fullPerfume,
                rank: rank
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func recommendationCardContent(
        recommendation: RecommendationItem,
        perfumeMetadata: PerfumeMetadata?,
        fullPerfume: Perfume?,
        rank: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Ranking badge y confianza
            HStack {
                Text("#\(rank)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(rankColor(for: rank)))

                Spacer()

                // Confianza condicional según score
                if recommendation.score >= 75 {
                    confidenceBadge(ConfidenceLevel(rawValue: recommendation.confidence) ?? .medium)
                }
            }

            // Información del perfume - priorizar fullPerfume
            if let perfume = fullPerfume {
                HStack(spacing: 12) {
                    // Imagen
                    if let imageURL = perfume.imageURL, !imageURL.isEmpty {
                        KFImage(URL(string: imageURL))
                            .placeholder {
                                ZStack {
                                    Color.gray.opacity(0.2)
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                }
                            }
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 80)
                            .background(Color.black.opacity(0.1))
                            .cornerRadius(8)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        // Nombre
                        Text(perfume.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppColor.textPrimary)
                            .lineLimit(2)

                        // Marca
                        Text(brandViewModel.getBrandName(for: perfume.brand))
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(AppColor.textSecondary)

                        // Stats
                        HStack(spacing: 12) {
                            // Porcentaje de acierto
                            HStack(spacing: 4) {
                                Image(systemName: "percent")
                                    .font(.system(size: 10))
                                    .foregroundColor(AppColor.brandAccent)
                                Text(String(format: "%.0f", recommendation.score))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppColor.brandAccent)
                            }

                            // Popularidad
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(Color.orange)
                                Text(String(format: "%.1f", perfume.popularity ?? 0))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppColor.textSecondary)
                            }

                            // Año
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 10))
                                    .foregroundColor(AppColor.textSecondary)
                                Text(String(perfume.year ?? 0))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppColor.textSecondary)
                            }
                        }

                        // Versatilidad
                        if !perfume.subfamilies.isEmpty {
                            let versatilityScore = min(perfume.subfamilies.count, 5)
                            HStack(spacing: 4) {
                                Text("Versatilidad:")
                                    .font(.system(size: 11, weight: .light))
                                    .foregroundColor(AppColor.textSecondary)
                                ForEach(0..<versatilityScore, id: \.self) { _ in
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 6))
                                        .foregroundColor(AppColor.brandAccent)
                                }
                            }
                        }
                    }

                    Spacer()
                }

                // Descripción del perfume completo
                if !perfume.description.isEmpty {
                    Text(perfume.description)
                        .font(.system(size: 13, weight: .light))
                        .foregroundColor(AppColor.textSecondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else if let metadata = perfumeMetadata {
                // Fallback a metadata si no hay perfume completo
                HStack(spacing: 12) {
                    // Imagen
                    if let imageURL = metadata.imageURL, !imageURL.isEmpty {
                        KFImage(URL(string: imageURL))
                            .placeholder {
                                ZStack {
                                    Color.gray.opacity(0.2)
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                }
                            }
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 80)
                            .background(Color.black.opacity(0.1))
                            .cornerRadius(8)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(metadata.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppColor.textPrimary)
                            .lineLimit(2)

                        Text(brandViewModel.getBrandName(for: metadata.brand))
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(AppColor.textSecondary)

                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "percent")
                                    .font(.system(size: 10))
                                    .foregroundColor(AppColor.brandAccent)
                                Text(String(format: "%.0f", recommendation.score))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppColor.brandAccent)
                            }

                            if let popularity = metadata.popularity {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(Color.orange)
                                    Text(String(format: "%.1f", popularity))
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(AppColor.textSecondary)
                                }
                            }
                        }
                    }

                    Spacer()
                }

                // Razón de recomendación
                Text(recommendation.reason)
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(AppColor.textSecondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                // Fallback final si no hay nada
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.perfumeKey)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppColor.textPrimary)

                    HStack(spacing: 4) {
                        Image(systemName: "percent")
                            .font(.system(size: 10))
                            .foregroundColor(AppColor.brandAccent)
                        Text(String(format: "%.0f", recommendation.score))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppColor.brandAccent)
                    }
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.clear))
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

    // MARK: - Restart Test Button

    private func restartTestButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 16, weight: .bold))
                Text("Volver a hacer el test")
                    .font(.system(size: 16, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .foregroundColor(AppColor.textPrimary)
        }
    }

    // MARK: - Load Perfumes

    private func loadRecommendedPerfumes() async {
        // Solo cargar si es modo test olfativo
        guard case .olfactiveProfile(let profile, _) = mode else {
            // Para gift recommendations, ya están cargadas
            return
        }

        isLoadingPerfumes = true

        #if DEBUG
        print("📥 [UnifiedResults] Loading recommendations for profile: \(profile.name)")
        #endif

        do {
            relatedPerfumes = try await perfumeViewModel.getRelatedPerfumes(
                for: profile,
                from: familyViewModel.familias
            )

            #if DEBUG
            print("✅ [UnifiedResults] Loaded \(relatedPerfumes.count) recommended perfumes")
            print("   Visible recommendations: \(visibleRecommendations.count)")
            #endif
        } catch {
            #if DEBUG
            print("❌ [UnifiedResults] Error loading perfumes: \(error.localizedDescription)")
            #endif
            relatedPerfumes = []
        }

        isLoadingPerfumes = false
    }

    // MARK: - Helper Methods

    private func rankColor(for rank: Int) -> Color {
        switch rank {
        case 1: return AppColor.brandAccent
        case 2: return Color.blue.opacity(0.8)
        case 3: return Color.green.opacity(0.8)
        default: return Color.gray
        }
    }

    private func confidenceColor(_ level: ConfidenceLevel) -> Color {
        switch level {
        case .high: return Color.green
        case .medium: return Color.orange
        case .low: return Color.red
        }
    }

    private func scoreToConfidence(_ score: Double) -> String {
        if score >= 80 { return "high" }
        if score >= 60 { return "medium" }
        return "low"
    }

    private func intensityIcon(for intensity: String) -> String {
        switch intensity.lowercased() {
        case "low": return "waveform.path"
        case "medium": return "waveform.path"
        case "high": return "waveform.path"
        case "very_high": return "waveform.path"
        default: return "waveform.path"
        }
    }

    private func intensityDisplayName(for intensity: String) -> String {
        switch intensity.lowercased() {
        case "low": return "Suave"
        case "medium": return "Moderada"
        case "high": return "Intensa"
        case "very_high": return "Muy Intensa"
        default: return intensity.capitalized
        }
    }

    private func durationIcon(for duration: String) -> String {
        switch duration.lowercased() {
        case "short": return "clock"
        case "moderate": return "clock"
        case "long": return "clock"
        case "very_long": return "clock"
        default: return "clock"
        }
    }

    private func durationDisplayName(for duration: String) -> String {
        switch duration.lowercased() {
        case "short": return "Corta"
        case "moderate": return "Moderada"
        case "long": return "Larga"
        case "very_long": return "Muy Larga"
        default: return duration.capitalized
        }
    }

    private func experienceLevelDisplayName(for level: String?) -> String {
        guard let level = level else { return "Principiante" }
        switch level.lowercased() {
        case "beginner": return "Principiante"
        case "intermediate": return "Intermedio"
        case "expert": return "Experto"
        default: return level.capitalized
        }
    }

    private func experienceLevelIcon(for level: String?) -> String {
        guard let level = level else { return "star" }
        switch level.lowercased() {
        case "beginner": return "star"
        case "intermediate": return "star.leadinghalf.filled"
        case "expert": return "star.fill"
        default: return "star"
        }
    }

    private func getOlfactiveProfile() -> OlfactiveProfile? {
        switch mode {
        case .olfactiveProfile(let profile, _):
            return profile
        case .giftRecommendations:
            return nil
        }
    }
}

// MARK: - Supporting Types

enum ResultsMode {
    case olfactiveProfile(profile: OlfactiveProfile, isTestActive: Binding<Bool>)
    case giftRecommendations(recommendations: [GiftRecommendation])
}

struct ProfileHeaderInfo {
    let primaryFamily: String
    let complementaryFamilies: [String]
    let gender: String
    let description: String?
    let intensity: String
    let duration: String
    let experienceLevel: String?
}

struct RecommendationItem: Identifiable {
    let id: String
    let perfumeKey: String
    let perfume: Perfume?  // Perfume completo
    let score: Double
    let reason: String
    let confidence: String
}
