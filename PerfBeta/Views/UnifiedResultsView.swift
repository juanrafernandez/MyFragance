import SwiftUI
import Kingfisher

/// Unified results view that works for both personal test results and gift recommendations
/// Combines the rich perfume list with profile header, test summary accordion, and save functionality
struct UnifiedResultsView: View {
    // MARK: - Environment
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var brandViewModel: BrandViewModel
    @EnvironmentObject var familyViewModel: FamilyViewModel
    @EnvironmentObject var olfactiveProfileViewModel: OlfactiveProfileViewModel
    @EnvironmentObject var testViewModel: TestViewModel
    @EnvironmentObject var giftRecommendationViewModel: GiftRecommendationViewModel
    @Environment(\.dismiss) var dismiss

    // MARK: - Configuration
    let mode: ResultsMode
    let onSave: (() -> Void)?
    let onDismiss: (() -> Void)?
    let onRestartTest: (() -> Void)?
    let isStandalone: Bool
    let isFromTest: Bool  // Si viene de un test nuevo (para mostrar botón guardar)

    // MARK: - State
    @State private var isLoadingPerfumes = false
    @State private var selectedPerfume: Perfume?
    @State private var hiddenRecommendationIds: Set<String> = []
    @State private var relatedPerfumes: [(perfume: Perfume, score: Double)] = []
    @State private var isAccordionExpanded = false
    @State private var isSavePopupVisible = false
    @State private var showExitAlert = false
    @State private var saveName: String = ""

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
                    perfume: rec.perfume,
                    score: rec.score,
                    reason: "Coincide con tu perfil olfativo",
                    confidence: scoreToConfidence(rec.score)
                )
            }
        }

        switch mode {
        case .olfactiveProfile(let profile, _):
            return (profile.recommendedPerfumes ?? []).enumerated().map { _, rec in
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
                experienceLevel: profile.experienceLevel,
                createdAt: profile.createdAt
            )
        case .giftRecommendations:
            return nil
        }
    }

    /// Questions and answers del perfil (para el accordion)
    private var questionsAndAnswers: [QuestionAnswer]? {
        switch mode {
        case .olfactiveProfile(let profile, _):
            return profile.questionsAndAnswers
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
        onDismiss: (() -> Void)? = nil,
        onRestartTest: (() -> Void)? = nil,
        isStandalone: Bool = false,
        isFromTest: Bool = false
    ) {
        self.mode = .olfactiveProfile(profile: profile, isTestActive: isTestActive)
        self.onSave = onSave
        self.onDismiss = onDismiss
        self.onRestartTest = onRestartTest
        self.isStandalone = isStandalone
        self.isFromTest = isFromTest
    }

    /// Inicializador para resultados de regalo
    init(
        giftRecommendations: [GiftRecommendation],
        onSave: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil,
        isStandalone: Bool = false,
        isFromTest: Bool = false
    ) {
        self.mode = .giftRecommendations(recommendations: giftRecommendations)
        self.onSave = onSave
        self.onDismiss = onDismiss
        self.onRestartTest = nil
        self.isStandalone = isStandalone
        self.isFromTest = isFromTest
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

                ScrollViewReader { proxy in
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

                        // Accordion de resumen del test (solo para test olfativo)
                        if let qa = questionsAndAnswers, !qa.isEmpty {
                            Section {
                                testSummaryAccordion(
                                    questionsAndAnswers: qa,
                                    createdAt: profileHeaderInfo?.createdAt,
                                    proxy: proxy
                                )
                                .listRowInsets(EdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0))
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }

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
        }
        .fullScreenCover(item: $selectedPerfume) { perfume in
            let brand = brandViewModel.getBrand(for: perfume.brand)
            let profile = getOlfactiveProfile()

            PerfumeDetailView(
                perfume: perfume,
                brand: brand,
                profile: profile
            )
            .environmentObject(perfumeViewModel)
            .environmentObject(brandViewModel)
        }
        .sheet(isPresented: $isSavePopupVisible) {
            switch mode {
            case .olfactiveProfile(_, let isTestActive):
                if let profile = getOlfactiveProfile() {
                    SaveProfileView(
                        profile: profile,
                        saveName: $saveName,
                        isSavePopupVisible: $isSavePopupVisible,
                        isTestActive: isTestActive,
                        onSaved: {
                            onSave?()
                            dismiss()
                        }
                    )
                    .environmentObject(olfactiveProfileViewModel)
                    .environmentObject(familyViewModel)
                }
            case .giftRecommendations:
                SaveGiftProfileSheet(
                    saveName: $saveName,
                    isSavePopupVisible: $isSavePopupVisible,
                    onSaved: {
                        onSave?()
                        dismiss()
                    }
                )
                .environmentObject(giftRecommendationViewModel)
            }
        }
        .alert("¿Salir sin guardar?", isPresented: $showExitAlert) {
            Button("Salir", role: .destructive) {
                if case .olfactiveProfile(_, let isTestActive) = mode {
                    isTestActive.wrappedValue = false
                }
                onDismiss?()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Los datos no se guardarán si sales.")
        }
        .task {
            await loadRecommendedPerfumes()
        }
    }

    // MARK: - Navigation Bar

    private var navigationBar: some View {
        HStack {
            // Botón izquierdo (X) con estilo editorial
            Button(action: {
                if isFromTest {
                    showExitAlert = true
                } else {
                    if let onDismiss = onDismiss {
                        onDismiss()
                    } else {
                        dismiss()
                    }
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColor.textPrimary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.8))
                            .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                    )
            }

            Spacer()

            // Título (solo si NO viene de test nuevo, para evitar duplicar info)
            if !isFromTest {
                if profileHeaderInfo != nil {
                    Text("Tu Perfil")
                        .font(.custom("Georgia", size: 18))
                        .foregroundColor(AppColor.textPrimary)
                } else {
                    Text("Recomendaciones")
                        .font(.custom("Georgia", size: 18))
                        .foregroundColor(AppColor.textPrimary)
                }
            }

            Spacer()

            // Botón Guardar (solo si viene de test nuevo)
            if isFromTest {
                Button(action: { isSavePopupVisible = true }) {
                    Text("Guardar")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppColor.brandAccent)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(AppColor.brandAccent.opacity(0.12))
                        )
                }
            } else {
                // Espacio para equilibrar
                Color.clear.frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.top, AppSpacing.spacing16)
        .padding(.bottom, 8)
    }

    // MARK: - Profile Header (Estilo Editorial)

    private func profileHeader(headerInfo: ProfileHeaderInfo) -> some View {
        VStack(alignment: .center, spacing: 20) {
            // Separador superior
            Rectangle()
                .fill(AppColor.textSecondary.opacity(0.2))
                .frame(width: 40, height: 1)

            // Nombre del perfil (familia principal) con estilo editorial
            if let primaryFamily = familyViewModel.getFamily(byKey: headerInfo.primaryFamily) {
                VStack(spacing: 8) {
                    Text("TU PERFIL OLFATIVO")
                        .font(.system(size: 11, weight: .medium))
                        .tracking(2)
                        .foregroundColor(AppColor.textSecondary)

                    Text(primaryFamily.name.uppercased())
                        .font(.custom("Georgia", size: 28))
                        .tracking(3)
                        .foregroundColor(AppColor.textPrimary)
                        .multilineTextAlignment(.center)
                }
            }

            // Familias complementarias con bullets
            let complementaryFamilies = headerInfo.complementaryFamilies
                .compactMap { familyViewModel.getFamily(byKey: $0) }

            if !complementaryFamilies.isEmpty {
                Text(complementaryFamilies.map { $0.name }.joined(separator: "  •  "))
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(AppColor.textSecondary)
            }

            // Separador
            Rectangle()
                .fill(AppColor.textSecondary.opacity(0.2))
                .frame(width: 40, height: 1)

            // Características en grid limpio (sin iconos)
            VStack(spacing: 16) {
                // Fila 1: Género + Intensidad
                HStack(spacing: 24) {
                    editorialCharacteristic(title: "Género", value: genderDisplayName(for: headerInfo.gender))
                    editorialCharacteristic(title: "Intensidad", value: intensityDisplayName(for: headerInfo.intensity))
                }

                // Fila 2: Duración + Nivel
                HStack(spacing: 24) {
                    editorialCharacteristic(title: "Duración", value: durationDisplayName(for: headerInfo.duration))
                    if let experienceLevel = headerInfo.experienceLevel {
                        editorialCharacteristic(title: "Nivel", value: experienceLevelDisplayName(for: experienceLevel))
                    }
                }
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.6))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }

    /// Formatea la fecha de creación del perfil
    private func formatProfileDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateFormat = "d 'de' MMMM, yyyy"
        return "Creado el \(formatter.string(from: date))"
    }

    private func editorialCharacteristic(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppColor.textSecondary)
            Text(value)
                .font(.custom("Georgia", size: 15))
                .foregroundColor(AppColor.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func genderDisplayName(for gender: String) -> String {
        switch gender.lowercased() {
        case "male", "masculine", "hombre": return "Masculino"
        case "female", "feminine", "mujer": return "Femenino"
        case "unisex": return "Unisex"
        default: return gender.capitalized
        }
    }

    // MARK: - Gift Header

    private var giftHeader: some View {
        VStack(spacing: 6) {
            Image(systemName: "gift.fill")
                .font(.system(size: 50))
                .foregroundColor(AppColor.brandAccent)
                .padding(.top, 4)

            Text("Recomendaciones de Regalo")
                .font(.custom("Georgia", size: 28))
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

    // MARK: - Test Summary Accordion (Estilo Diálogo Editorial)

    private func testSummaryAccordion(questionsAndAnswers: [QuestionAnswer], createdAt: Date?, proxy: ScrollViewProxy) -> some View {
        VStack(spacing: 0) {
            // Header del accordion
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isAccordionExpanded.toggle()
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TUS RESPUESTAS")
                            .font(.system(size: 11, weight: .medium))
                            .tracking(2)
                            .foregroundColor(AppColor.textSecondary)

                        // Fecha de creación (si existe)
                        if let date = createdAt {
                            Text(formatProfileDate(date))
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(AppColor.textSecondary.opacity(0.6))
                        }
                    }

                    Spacer()

                    Image(systemName: isAccordionExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColor.textSecondary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .buttonStyle(PlainButtonStyle())

            if isAccordionExpanded {
                // Separador
                Rectangle()
                    .fill(AppColor.textSecondary.opacity(0.15))
                    .frame(height: 1)
                    .padding(.horizontal, 20)

                // Contenido con estilo diálogo
                dialogueContent(questionsAndAnswers: questionsAndAnswers)
                    .id("AccordionSection")
                    .padding(.top, 16)
                    .padding(.bottom, 20)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.6))
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
        .onChange(of: isAccordionExpanded) {
            if isAccordionExpanded {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation {
                        proxy.scrollTo("AccordionSection", anchor: .top)
                    }
                }
            }
        }
    }

    /// Contenido de preguntas/respuestas estilo diálogo
    private func dialogueContent(questionsAndAnswers: [QuestionAnswer]) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(Array(questionsAndAnswers.enumerated()), id: \.element.id) { index, qa in
                let texts = testViewModel.findQuestionAndAnswerTexts(
                    for: qa.questionId,
                    answerId: qa.answerId
                )

                if let questionText = texts.question, let answerText = texts.answer {
                    VStack(alignment: .leading, spacing: 12) {
                        // Pregunta (alineada a la izquierda, estilo "pregunta")
                        HStack(alignment: .top, spacing: 10) {
                            Text("P\(index + 1)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(AppColor.brandAccent)
                                .frame(width: 24)

                            Text(questionText)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(AppColor.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        // Respuesta (alineada a la derecha, estilo "respuesta")
                        HStack {
                            Spacer()

                            Text(answerText)
                                .font(.custom("Georgia", size: 15))
                                .foregroundColor(AppColor.textPrimary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(AppColor.brandAccent.opacity(0.1))
                                )
                        }
                        .padding(.leading, 34) // Alineado con el texto de la pregunta
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Save Profile Button

    private var saveProfileButton: some View {
        Button(action: { isSavePopupVisible = true }) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                Text("Guardar Perfil")
                    .font(.system(size: 16, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(AppColor.brandAccent)
            .foregroundColor(.white)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .padding(.horizontal, AppSpacing.screenHorizontal)
        .padding(.bottom, 16)
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
        let fullPerfume = recommendation.perfume
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
            // Ranking badge y chip "Top Match"
            HStack {
                Text("#\(rank)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(rankColor(for: rank)))

                Spacer()

                // Chip "Top Match" para recomendaciones con score >= 80%
                if recommendation.score >= 80 {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                        Text("Top Match")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(AppColor.brandAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(AppColor.brandAccent.opacity(0.15))
                    )
                }
            }

            // Información del perfume
            if let perfume = fullPerfume {
                perfumeInfoView(perfume: perfume, recommendation: recommendation)
            } else if let metadata = perfumeMetadata {
                metadataInfoView(metadata: metadata, recommendation: recommendation)
            } else {
                fallbackInfoView(recommendation: recommendation)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.clear))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(rankColor(for: rank).opacity(0.3), lineWidth: 1)
        )
    }

    private func perfumeInfoView(perfume: Perfume, recommendation: RecommendationItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
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
                    Text(perfume.name)
                        .font(.custom("Georgia", size: 18))
                        .foregroundColor(AppColor.textPrimary)
                        .lineLimit(2)

                    Text(brandViewModel.getBrandName(for: perfume.brand))
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(AppColor.textSecondary)

                    // Stats
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "percent")
                                .font(.system(size: 10))
                                .foregroundColor(AppColor.brandAccent)
                            Text(String(format: "%.0f", recommendation.score))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppColor.brandAccent)
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(Color.orange)
                            Text(String(format: "%.1f", perfume.popularity ?? 0))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppColor.textSecondary)
                        }

                        if let year = perfume.year {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 10))
                                    .foregroundColor(AppColor.textSecondary)
                                Text(String(year))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppColor.textSecondary)
                            }
                        }
                    }
                }

                Spacer()
            }

            if !perfume.description.isEmpty {
                Text(perfume.description)
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(AppColor.textSecondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func metadataInfoView(metadata: PerfumeMetadata, recommendation: RecommendationItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
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
                        .font(.custom("Georgia", size: 18))
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

            Text(recommendation.reason)
                .font(.system(size: 13, weight: .light))
                .foregroundColor(AppColor.textSecondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func fallbackInfoView(recommendation: RecommendationItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(recommendation.perfumeKey)
                .font(.custom("Georgia", size: 18))
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
        guard case .olfactiveProfile(let profile, _) = mode else {
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
        "waveform.path"
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
        "clock"
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
    let createdAt: Date?
}

struct RecommendationItem: Identifiable {
    let id: String
    let perfumeKey: String
    let perfume: Perfume?
    let score: Double
    let reason: String
    let confidence: String
}
