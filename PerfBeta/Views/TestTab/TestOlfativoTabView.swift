import SwiftUI

enum TestTabSection: String, CaseIterable {
    case olfactiveProfiles = "Perfiles Olfativos"
    case giftSearches = "Búsquedas de Regalo"
}

struct TestOlfativoTabView: View {
    @EnvironmentObject var olfactiveProfileViewModel: OlfactiveProfileViewModel
    @EnvironmentObject var familyViewModel: FamilyViewModel
    @EnvironmentObject var giftRecommendationViewModel: GiftRecommendationViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var brandViewModel: BrandViewModel
    @EnvironmentObject var testViewModel: TestViewModel
    @EnvironmentObject var notesViewModel: NotesViewModel

    @State private var selectedTab: TestTabSection = .olfactiveProfiles
    @State private var isPresentingTestView = false
    @State private var isPresentingGiftFlow = false
    @State private var isPresentingGiftResults = false  // ✅ Para mostrar resultados de perfil guardado
    // ✅ ELIMINADO: Sistema de temas personalizable
    @State private var selectedProfileForNavigation: OlfactiveProfile? = nil
    @State private var isPresentingResultAsFullScreenCover = false
    @State private var navigationLinkActive = false  // For olfactive profiles management
    @State private var giftProfileManagementActive = false  // ✅ For gift profiles management
    @State private var maxVisibleGiftProfiles: Int = 6  // ✅ Calculado dinámicamente
    @State private var maxVisibleOlfactiveProfiles: Int = 6  // ✅ Calculado dinámicamente para perfiles olfativos

    // MARK: - NEW: Unified Question Flow
    @State private var isPresentingUnifiedProfileFlow = false
    @State private var isPresentingUnifiedGiftFlow = false
    @State private var profileQuestions: [UnifiedQuestion] = []
    @State private var giftQuestions: [UnifiedQuestion] = []
    @State private var isLoadingQuestions = false
    private let questionsService = QuestionsService()

    var body: some View {
        NavigationView {
            ZStack {
                GradientView(preset: .champan)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) {
                    headerView

                    // Tab Picker
                    Picker("", selection: $selectedTab) {
                        ForEach(TestTabSection.allCases, id: \.self) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 25)
                    .padding(.top, 12)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 25) {
                            if selectedTab == .olfactiveProfiles {
                                olfactiveProfilesContent
                            } else {
                                giftSearchesContent
                            }
                        }
                        .padding(.horizontal, 25)
                    }
                }
            }
            .navigationBarHidden(true)
            .background(
                Group {
                    NavigationLink(
                        destination: ProfileManagementView()
                            .environmentObject(olfactiveProfileViewModel),
                        isActive: $navigationLinkActive,
                        label: { EmptyView() }
                    )

                    NavigationLink(
                        destination: GiftProfileManagementView()
                            .environmentObject(giftRecommendationViewModel)
                            .environmentObject(perfumeViewModel)
                            .environmentObject(brandViewModel),
                        isActive: $giftProfileManagementActive,
                        label: { EmptyView() }
                    )
                }
            )
            .fullScreenCover(isPresented: $isPresentingTestView) {
                TestView(isTestActive: $isPresentingTestView)
            }
            .fullScreenCover(isPresented: $isPresentingGiftFlow) {
                GiftFlowView(onDismiss: {
                    isPresentingGiftFlow = false
                })
                    .environmentObject(giftRecommendationViewModel)
                    .environmentObject(perfumeViewModel)
                    .environmentObject(brandViewModel)  // ✅ Ya está pasando brandViewModel
            }
            .fullScreenCover(isPresented: $isPresentingUnifiedProfileFlow) {
                UnifiedQuestionFlowView(
                    title: "Test Olfativo Personal",
                    questions: profileQuestions,
                    navigationProfile: $selectedProfileForNavigation,
                    showResults: true,
                    onComplete: { responses in
                        handleProfileCompletion(responses: responses)
                    },
                    onDismiss: {
                        isPresentingUnifiedProfileFlow = false
                        selectedProfileForNavigation = nil
                    }
                )
                .environmentObject(notesViewModel)
                .environmentObject(brandViewModel)
                .environmentObject(perfumeViewModel)
                .environmentObject(familyViewModel)
                .environmentObject(olfactiveProfileViewModel)
                .environmentObject(testViewModel)
            }
            .fullScreenCover(isPresented: $isPresentingUnifiedGiftFlow) {
                UnifiedQuestionFlowView(
                    title: "Búsqueda de Regalo",
                    questions: giftQuestions,
                    onComplete: { responses in
                        handleGiftCompletion(responses: responses)
                    },
                    onDismiss: {
                        isPresentingUnifiedGiftFlow = false
                    }
                )
            }
            .fullScreenCover(isPresented: $isPresentingGiftResults) {
                GiftResultsView(
                    onDismiss: {
                        isPresentingGiftResults = false
                    },
                    isStandalone: true  // ✅ Mostrar con fondo y botón X
                )
                    .environmentObject(giftRecommendationViewModel)
                    .environmentObject(perfumeViewModel)
                    .environmentObject(brandViewModel)
            }
            .fullScreenCover(isPresented: $isPresentingResultAsFullScreenCover) {
                if let profileToDisplay = selectedProfileForNavigation {
                    TestResultNavigationView(profile: profileToDisplay, isTestActive: $isPresentingResultAsFullScreenCover)
                        .environmentObject(olfactiveProfileViewModel)
                        .environmentObject(perfumeViewModel)
                        .environmentObject(testViewModel)
                        .environmentObject(brandViewModel)
                        .environmentObject(familyViewModel)
                } else {
                    Text("Error: No se pudo cargar el perfil guardado.")
                }
            }
            .onChange(of: selectedProfileForNavigation) {
                #if DEBUG
                print("Selected profile changed: \(String(describing: selectedProfileForNavigation?.name))")
                #endif
            }
            .onAppear {
                PerformanceLogger.logViewAppear("TestOlfativoTabView")

                // ✅ Calcular perfiles visibles basado en altura real de pantalla
                calculateMaxVisibleProfiles(screenHeight: UIScreen.main.bounds.height)

                // ✅ Lazy load: Cargar families solo cuando se necesitan
                Task {
                    if familyViewModel.familias.isEmpty {
                        await familyViewModel.loadInitialData()
                        #if DEBUG
                        print("✅ [TestTab] Families loaded on-demand")
                        #endif
                    }

                    // ℹ️ Los perfiles olfativos se cargan automáticamente en OlfactiveProfileViewModel

                    // ✅ Cargar perfiles de regalo guardados
                    await giftRecommendationViewModel.loadProfiles()
                    #if DEBUG
                    print("✅ [TestTab] Gift profiles loaded: \(giftRecommendationViewModel.savedProfiles.count)")
                    print("✅ [TestTab] Olfactive profiles count: \(olfactiveProfileViewModel.profiles.count)")
                    #endif
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var headerView: some View {
        HStack {
            Text("Descubre tu fragancia ideal".uppercased())
                .font(.system(size: 18, weight: .light))
                .foregroundColor(Color("textoPrincipal"))
            Spacer()
        }
        .padding(.leading, 25)
        .padding(.top, 16)
    }

    // MARK: - Tab Content Views

    private var olfactiveProfilesContent: some View {
        VStack(alignment: .leading, spacing: 25) {
            Text("Crea un nuevo perfil olfativo o consulta tus perfiles guardados.")
                .font(.system(size: 15, weight: .thin))
                .foregroundColor(Color("textoSecundario"))
                .padding(.top, 15)

            savedProfilesSection
            startTestButton
        }
    }

    private var giftSearchesContent: some View {
        VStack(alignment: .leading, spacing: 25) {
            Text("Encuentra el perfume perfecto para regalar. Guarda tus búsquedas para consultarlas después.")
                .font(.system(size: 15, weight: .thin))
                .foregroundColor(Color("textoSecundario"))
                .padding(.top, 15)

            savedGiftProfilesSection
            startGiftSearchButton
        }
    }

    // MARK: - Deprecated (keeping for reference)
    private var introText: some View {
        Text("Crea un nuevo perfil, consulta tus perfiles guardados o explora tus búsquedas de regalos.")
            .font(.system(size: 15, weight: .thin))
            .foregroundColor(Color("textoSecundario"))
    }

    private var savedProfilesSection: some View {
        let totalProfiles = olfactiveProfileViewModel.profiles.count
        let visibleProfiles = Array(olfactiveProfileViewModel.profiles.prefix(maxVisibleOlfactiveProfiles))

        return sectionWithCards(
            title: "Perfiles Guardados",
            subtitle: totalProfiles > maxVisibleOlfactiveProfiles ? "Mostrando \(maxVisibleOlfactiveProfiles) de \(totalProfiles) perfiles" : nil,
            items: visibleProfiles,
            totalCount: totalProfiles,
            showFadeOnLast: totalProfiles > maxVisibleOlfactiveProfiles,
            onViewAll: {
                navigationLinkActive = true
            }
        ) { profile in
            Button(action: {
                navigateToTestResult(profile: profile, isFromTest: false)
            }) {
                let familySelected = familyViewModel.getFamily(byKey: profile.families.first?.family ?? "")

                ProfileCardView(
                    title: profile.name,
                    description: familySelected?.familyDescription ?? "",
                    familyColors: profile.families.prefix(3).map { $0.family }
                )
                .environmentObject(familyViewModel)
            }
            .buttonStyle(.plain)
        }
    }

    private var savedGiftProfilesSection: some View {
        let totalProfiles = giftRecommendationViewModel.savedProfiles.count
        let visibleProfiles = Array(giftRecommendationViewModel.savedProfiles.prefix(maxVisibleGiftProfiles))

        return sectionWithCards(
            title: "Perfiles de Regalo Guardados",
            subtitle: totalProfiles > maxVisibleGiftProfiles ? "Mostrando \(maxVisibleGiftProfiles) de \(totalProfiles) perfiles" : nil,
            items: visibleProfiles,
            totalCount: totalProfiles,
            showFadeOnLast: totalProfiles > maxVisibleGiftProfiles,
            onViewAll: {
                giftProfileManagementActive = true
            }
        ) { profile in
            Button(action: {
                // ✅ Cargar perfil y mostrar resultados
                giftRecommendationViewModel.loadProfile(profile)
                isPresentingGiftResults = true
            }) {
                ProfileCardView(
                    title: profile.displayName,
                    description: profile.summary,
                    familyColors: Array(profile.preferredFamilies.prefix(3))
                )
                .environmentObject(familyViewModel)
            }
            .buttonStyle(.plain)
        }
    }

    private var giftSearchesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("BÚSQUEDAS DE REGALOS".uppercased())
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(Color("textoPrincipal"))
                Spacer()
                Button("Ver todos") {
                    navigationLinkActive = true
                }
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(Color("textoPrincipal"))
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color("champan").opacity(0.1))
                )
                .cornerRadius(8)
            }

            if giftRecommendationViewModel.savedProfiles.isEmpty {
                Text("Aún no has guardado búsquedas de regalos. ¡Pulsa el botón 'Buscar un Regalo' para empezar y guarda tus búsquedas aquí!")
                    .font(.system(size: 13, weight: .thin, design: .default))
                    .foregroundColor(Color("textoSecundario"))
                    .padding(.vertical, 8)
            } else {
                Text("No hay búsquedas de regalos guardadas aún.")
                    .font(.system(size: 13, weight: .thin, design: .default))
                    .foregroundColor(.gray)
                    .padding(.vertical, 8)
            }
        }
        .padding(.top, 5)
    }

    private var startTestButton: some View {
        Button(action: {
            Task {
                await loadProfileQuestions()
            }
        }) {
            HStack {
                if isLoadingQuestions {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "magnifyingglass")
                    Text("Iniciar Test Olfativo")
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color("champan"))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(isLoadingQuestions)
        .padding(.vertical, 8)
    }

    private var startGiftSearchButton: some View {
        Button(action: {
            isPresentingGiftFlow = true
        }) {
            HStack {
                Image(systemName: "gift")
                Text("Buscar un Regalo")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color("champan"))
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding(.vertical, 8)
    }

    private func navigateToTestResult(profile: OlfactiveProfile, isFromTest: Bool) {
        selectedProfileForNavigation = profile
        DispatchQueue.main.async {
            self.isPresentingTestView = false
            self.isPresentingResultAsFullScreenCover = true
        }
    }

    private func sectionWithCards<Item: Identifiable, Content: View>(
        title: String,
        subtitle: String? = nil,
        items: [Item],
        totalCount: Int? = nil,
        showFadeOnLast: Bool = false,
        onViewAll: @escaping () -> Void = {},
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header con título y botón "Ver todos"
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 12, weight: .light))
                    .foregroundColor(Color("textoPrincipal"))
                Spacer()
                if items.count > 0 {
                    Button(action: onViewAll) {
                        HStack(spacing: 4) {
                            Text("Ver todos")
                                .font(.system(size: 13, weight: .medium))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(Color("champan"))
                    }
                }
            }

            // Subtítulo descriptivo (si existe)
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 12, weight: .thin))
                    .foregroundColor(Color("textoSecundario"))
                    .padding(.top, 2)
            }

            // Cards
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                let isLastItem = index == items.count - 1

                content(item)
                    .overlay(
                        // Fade effect en el último item si hay más perfiles
                        Group {
                            if showFadeOnLast && isLastItem {
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.clear,
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.6)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                                .allowsHitTesting(false)
                            }
                        }
                    )
            }
        }
        .padding(.top, 5)
    }

    // MARK: - Helper Functions

    /// Calcula dinámicamente cuántos perfiles mostrar según el espacio disponible
    /// Aplica tanto a perfiles olfativos como a perfiles de regalo
    private func calculateMaxVisibleProfiles(screenHeight: CGFloat) {
        // Referencia: iPhone 17 Pro (874pt altura según logs) debe mostrar 6 perfiles
        // Con 6 perfiles y cardHeight=70: 6 * 70 = 420pt disponibles → fixed=454pt

        // Constantes de espacio ocupado (medidas reales del layout)
        let safeAreaTop: CGFloat = 59       // Safe area superior (Dynamic Island/Notch)
        let headerHeight: CGFloat = 50      // "Descubre tu fragancia ideal" + padding
        let tabPickerHeight: CGFloat = 44   // Segmented control + padding top
        let introTextHeight: CGFloat = 60   // Texto descriptivo + padding
        let sectionHeaderHeight: CGFloat = 53  // Título "PERFILES..." + subtítulo "Mostrando X de Y"
        let buttonHeight: CGFloat = 68      // Botón "Buscar un Regalo" o "Iniciar Test" + padding vertical
        let tabBarHeight: CGFloat = 83      // TabBar inferior
        let scrollViewMargins: CGFloat = 35 // Márgenes superior e inferior del ScrollView

        // Espacio total ocupado por elementos fijos
        let fixedSpace = safeAreaTop + headerHeight + tabPickerHeight + introTextHeight +
                        sectionHeaderHeight + buttonHeight + tabBarHeight + scrollViewMargins

        // Espacio disponible para las cards de perfiles
        let availableSpace = screenHeight - fixedSpace

        // Altura de cada ProfileCardView + spacing entre cards
        let cardHeight: CGFloat = 70  // Card real + spacing (calibrado: 874pt → 6 perfiles)

        // Calcular cuántos perfiles caben
        let calculatedMax = Int(availableSpace / cardHeight)

        // Limitar entre 4 y 10 perfiles
        let newMax = min(max(calculatedMax, 4), 10)

        // Actualizar ambos valores (olfativos y regalo) ya que usan el mismo layout
        if newMax != maxVisibleGiftProfiles || newMax != maxVisibleOlfactiveProfiles {
            maxVisibleGiftProfiles = newMax
            maxVisibleOlfactiveProfiles = newMax

            #if DEBUG
            print("📐 [TestTab] Screen height: \(screenHeight)pt")
            print("   Safe area top: \(safeAreaTop)pt")
            print("   Fixed space total: \(fixedSpace)pt")
            print("   Available for cards: \(availableSpace)pt")
            print("   Card height (with spacing): \(cardHeight)pt")
            print("   Calculated profiles: \(availableSpace / cardHeight) → \(calculatedMax)")
            print("   ✅ Max visible profiles (both tabs): \(newMax)")
            #endif
        }
    }

    // MARK: - NEW: Question Loading Functions

    @MainActor
    private func loadProfileQuestions() async {
        isLoadingQuestions = true

        do {
            #if DEBUG
            print("📥 [TestOlfativoTab] Cargando preguntas de Profile...")
            #endif

            let questions = try await questionsService.fetchAllProfileQuestions()
            profileQuestions = questions.map { $0.toUnified() }

            #if DEBUG
            print("✅ [TestOlfativoTab] Cargadas \(profileQuestions.count) preguntas de Profile")
            #endif

            isLoadingQuestions = false
            isPresentingUnifiedProfileFlow = true

        } catch {
            #if DEBUG
            print("❌ [TestOlfativoTab] Error cargando preguntas de Profile: \(error)")
            #endif
            isLoadingQuestions = false
        }
    }

    @MainActor
    private func loadGiftQuestions() async {
        isLoadingQuestions = true

        do {
            #if DEBUG
            print("📥 [TestOlfativoTab] Cargando preguntas de Gift...")
            #endif

            let questions = try await questionsService.fetchAllGiftQuestions()
            giftQuestions = questions.map { $0.toUnified() }

            #if DEBUG
            print("✅ [TestOlfativoTab] Cargadas \(giftQuestions.count) preguntas de Gift")
            #endif

            isLoadingQuestions = false
            isPresentingUnifiedGiftFlow = true

        } catch {
            #if DEBUG
            print("❌ [TestOlfativoTab] Error cargando preguntas de Gift: \(error)")
            #endif
            isLoadingQuestions = false
        }
    }

    // MARK: - NEW: Completion Handlers

    private func handleProfileCompletion(responses: [String: UnifiedResponse]) {
        // Calcular scores de familias (rápido)
        var familyScores: [String: Double] = [:]
        for (questionId, response) in responses {
            guard let question = profileQuestions.first(where: { $0.id == questionId }) else { continue }
            for optionId in response.selectedOptionIds {
                guard let option = question.options.first(where: { $0.id == optionId }) else { continue }
                for (family, score) in option.families {
                    familyScores[family, default: 0] += Double(score)
                }
            }
        }

        let total = familyScores.values.reduce(0, +)
        let normalizedScores = familyScores.mapValues { total > 0 ? $0 / total : 0 }
        let primaryFamily = normalizedScores.max(by: { $0.value < $1.value })?.key ?? "amaderados"

        // Crear perfil básico sin recomendaciones (para mostrar UI rápido)
        let basicProfile = OlfactiveProfile(
            id: UUID().uuidString,
            name: "Mi Perfil",
            gender: "unisex",
            families: normalizedScores.map { FamilyPuntuation(family: $0.key, puntuation: Int($0.value * 100)) }
                .sorted { $0.puntuation > $1.puntuation },
            intensity: "media",
            duration: "media",
            descriptionProfile: nil,
            icon: nil,
            questionsAndAnswers: [],
            experienceLevel: "beginner",
            recommendedPerfumes: [],  // Vacío por ahora
            orderIndex: 0
        )

        // Navegar inmediatamente con perfil básico
        selectedProfileForNavigation = basicProfile

        // Calcular recomendaciones en segundo plano
        Task {
            var profile = UnifiedProfile(
                name: "Mi Perfil",
                profileType: .personal,
                experienceLevel: .beginner,
                primaryFamily: primaryFamily,
                subfamilies: [],
                familyScores: normalizedScores,
                genderPreference: "unisex",
                metadata: UnifiedProfileMetadata(),
                confidenceScore: 0.8,
                answerCompleteness: 1.0,
                orderIndex: 0
            )

            if perfumeViewModel.metadataIndex.isEmpty {
                await perfumeViewModel.loadMetadataIndex()
            }

            let perfumesForScoring: [Perfume] = perfumeViewModel.metadataIndex.map { meta in
                Perfume(id: meta.id, name: meta.name, brand: meta.brand, key: meta.key, family: meta.family, subfamilies: meta.subfamilies ?? [], topNotes: [], heartNotes: [], baseNotes: [], projection: "media", intensity: "media", duration: "media", recommendedSeason: [], associatedPersonalities: [], occasion: [], popularity: meta.popularity, year: meta.year, perfumist: nil, imageURL: "", description: "", gender: meta.gender, price: meta.price, createdAt: nil, updatedAt: nil)
            }

            let recommendations = await UnifiedRecommendationEngine.shared.getRecommendations(for: profile, from: perfumesForScoring, limit: 10)
            profile.recommendedPerfumes = recommendations

            let legacyProfile = profile.toLegacyProfile()

            await MainActor.run {
                testViewModel.unifiedProfile = profile
                // Actualizar el perfil mostrado con las recomendaciones
                selectedProfileForNavigation = legacyProfile
            }
        }
    }

    private func handleGiftCompletion(responses: [String: UnifiedResponse]) {
        #if DEBUG
        print("✅ [TestOlfativoTab] Búsqueda de Regalo completada con \(responses.count) respuestas")
        #endif

        // TODO: Generar perfil de regalo, guardarlo y mostrar resultados
        // Por ahora solo cerramos el flujo
        isPresentingUnifiedGiftFlow = false

        // Ejemplo de cómo generar el perfil:
        // let viewModel = UnifiedQuestionFlowViewModel()
        // let profile = viewModel.generateProfile(name: "Regalo", profileType: .gift)
        // Guardar en Firebase y navegar a resultados
    }
}
