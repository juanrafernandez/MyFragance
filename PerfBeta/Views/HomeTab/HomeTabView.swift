import SwiftUI
import Combine

// MARK: - HomeTab State

/// Estados posibles de HomeTab durante la carga de perfiles
enum HomeTabLoadingState: Equatable {
    /// Cargando perfiles por primera vez
    case loading

    /// Perfiles cargados (puede haber content o empty state)
    case loaded

    /// Error al cargar perfiles
    case error(String)
}

struct HomeTabView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var familiaOlfativaViewModel: FamilyViewModel
    @EnvironmentObject var olfactiveProfileViewModel: OlfactiveProfileViewModel
    @EnvironmentObject var perfumeViewModel: PerfumeViewModel
    @EnvironmentObject var brandViewModel: BrandViewModel
    @EnvironmentObject var authViewModel: AuthViewModel // Necesario para el nombre
    @EnvironmentObject var notesViewModel: NotesViewModel
    @EnvironmentObject var testViewModel: TestViewModel
    @EnvironmentObject var giftRecommendationViewModel: GiftRecommendationViewModel

    @State private var selectedTabIndex = 0
    @State private var selectedPerfume: Perfume? = nil
    @State private var homeTabState: HomeTabLoadingState = .loading

    // MARK: - Unified Question Flow
    @State private var isPresentingUnifiedProfileFlow = false
    @State private var profileQuestions: [UnifiedQuestion] = []
    @State private var isLoadingQuestions = false
    @State private var selectedProfileForNavigation: OlfactiveProfile? = nil
    private let questionsService = QuestionsService()

    init() {
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(AppColor.textPrimary)
        UIPageControl.appearance().pageIndicatorTintColor = UIColor(AppColor.textSecondary.opacity(0.2))
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                GradientView(preset: .champan)
                    .edgesIgnoringSafeArea(.all)

                // ✅ ENUM-BASED STATE MACHINE: Clear state transitions
                VStack(spacing: 0) {
                    switch homeTabState {
                    case .loading:
                        // Estado 1: Cargando perfiles - Mostrar skeleton
                        profilesLoadingSkeleton

                    case .loaded:
                        // Estado 2: Perfiles cargados - Mostrar content o empty state
                        if !olfactiveProfileViewModel.profiles.isEmpty {
                            // Content - Mostrar perfiles
                            loadedContentView
                        } else {
                            // Empty State - No hay perfiles
                            introductionSection
                        }

                    case .error(let message):
                        // Estado 3: Error al cargar
                        errorView(message: message)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                PerformanceLogger.logViewAppear("HomeTabView")
                updateHomeTabState()
            }
            .onDisappear {
                PerformanceLogger.logViewDisappear("HomeTabView")
            }
            .onChange(of: olfactiveProfileViewModel.hasAttemptedLoad) { _, _ in
                updateHomeTabState()
            }
            .onChange(of: olfactiveProfileViewModel.isLoading) { _, _ in
                updateHomeTabState()
            }
            .onChange(of: olfactiveProfileViewModel.errorMessage) { _, _ in
                updateHomeTabState()
            }
            .fullScreenCover(item: $selectedPerfume) { perfume in
                // Obtener brand y profile, pero no bloquear si no existen
                let brand = brandViewModel.getBrand(byKey: perfume.brand)
                let profile = olfactiveProfileViewModel.profiles.indices.contains(selectedTabIndex) ? olfactiveProfileViewModel.profiles[selectedTabIndex] : olfactiveProfileViewModel.profiles.first

                PerfumeDetailView(
                    perfume: perfume,
                    brand: brand, // nil si no se encuentra
                    profile: profile // nil si no hay profiles
                )
            }
            .fullScreenCover(isPresented: $isPresentingUnifiedProfileFlow) {
                UnifiedQuestionFlowView(
                    title: "Test Olfativo Personal",
                    questions: profileQuestions,
                    navigationProfile: $selectedProfileForNavigation,
                    showResults: true,
                    isGiftFlow: false,
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
                .environmentObject(familiaOlfativaViewModel)
                .environmentObject(olfactiveProfileViewModel)
                .environmentObject(testViewModel)
                .environmentObject(giftRecommendationViewModel)
            }
            .environmentObject(familiaOlfativaViewModel)
            .environmentObject(olfactiveProfileViewModel)
            .environmentObject(perfumeViewModel)
            .environmentObject(brandViewModel)
        }
    }

    private var introductionSection: some View {
        VStack(spacing: 24) {
            Image("home_empty")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 180)
                .cornerRadius(12)
                .padding(.horizontal, AppSpacing.screenHorizontal)

            Text("Bienvenido a tu Perfumería Personal")
                .font(.custom("Georgia", size: 24))
                .foregroundColor(AppColor.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.screenHorizontal)

            Text("""
            Aquí podrás descubrir recomendaciones de fragancias personalizadas según tu perfil olfativo.
            Crea tu primer perfil para recibir sugerencias y explorar perfumes ideales para ti.
            """)
                .font(.system(size: 16, weight: .light))
                .foregroundColor(AppColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.screenHorizontal)

            Button(action: {
                Task {
                    await loadProfileQuestions()
                }
            }) {
                if isLoadingQuestions {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColor.brandAccent)
                        .cornerRadius(12)
                } else {
                    Text("Crear mi Perfil Olfativo")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColor.brandAccent)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .disabled(isLoadingQuestions)
            .padding(.horizontal, AppSpacing.screenHorizontal)

            Spacer()
        }
        .padding(.top, AppSpacing.screenTopInset)
    }

    private var profileTabView: some View {
        TabView(selection: $selectedTabIndex) {
            ForEach(Array(olfactiveProfileViewModel.profiles.enumerated()), id: \.element.id) { index, profile in
                ProfileCard(profile: profile, selectedPerfume: $selectedPerfume)
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
    }

    // MARK: - State Management

    /// Actualiza el estado de HomeTab basado en el estado del ViewModel
    private func updateHomeTabState() {
        let newState: HomeTabLoadingState

        if let errorMessage = olfactiveProfileViewModel.errorMessage, !errorMessage.isEmpty {
            newState = .error(errorMessage)
        } else if olfactiveProfileViewModel.isLoading {
            // Priorizar isLoading sobre hasAttemptedLoad para evitar flash de empty state
            newState = .loading
        } else if olfactiveProfileViewModel.hasAttemptedLoad {
            newState = .loaded
        } else {
            newState = .loading
        }

        // Solo actualizar si cambió para evitar re-renders innecesarios
        if homeTabState != newState {
            homeTabState = newState
        }
    }

    // MARK: - Views

    /// Vista de contenido cuando los perfiles están cargados
    private var loadedContentView: some View {
        VStack(spacing: 0) {
            GreetingSection(userName: authViewModel.currentUser?.displayName ?? "Usuario")
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.top, AppSpacing.spacing16)
            profileTabView
        }
    }

    // ✅ SKELETON LOADER: Evita flash de empty state durante carga de caché
    private var profilesLoadingSkeleton: some View {
        VStack(spacing: 16) {
            // Skeleton para greeting
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 180, height: 24)

                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 140, height: 20)
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.top, AppSpacing.spacing16)

            // Skeleton para profile card
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.6))
                .frame(height: 500)
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .overlay(
                    VStack(spacing: 20) {
                        // Icon placeholder
                        Circle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(width: 80, height: 80)

                        // Title placeholders
                        VStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 200, height: 28)

                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 250, height: 20)
                        }

                        Spacer()

                        // Button placeholder
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 50)
                            .padding(.horizontal, AppSpacing.screenHorizontal)
                    }
                    .padding(.vertical, 40)
                )

            Spacer()
        }
        .transition(.opacity)
    }

    // MARK: - Load Profile Questions

    @MainActor
    private func loadProfileQuestions() async {
        isLoadingQuestions = true

        do {
            #if DEBUG
            print("📥 [HomeTab] Cargando preguntas de Profile...")
            #endif

            let questions = try await questionsService.fetchAllProfileQuestions()
            profileQuestions = questions.map { $0.toUnified() }

            #if DEBUG
            print("✅ [HomeTab] Cargadas \(profileQuestions.count) preguntas de Profile")
            #endif

            isLoadingQuestions = false
            isPresentingUnifiedProfileFlow = true

        } catch {
            #if DEBUG
            print("❌ [HomeTab] Error cargando preguntas de Profile: \(error)")
            #endif
            isLoadingQuestions = false
        }
    }

    // MARK: - Handle Profile Completion

    private func handleProfileCompletion(responses: [String: UnifiedResponse]) {
        #if DEBUG
        print("✅ [HomeTab] Profile test completed with \(responses.count) responses")
        #endif

        // Calcular scores de familias (rápido)
        var familyScores: [String: Double] = [:]
        var extractedGender: String = "unisex"  // Default

        for (questionId, response) in responses {
            guard let question = profileQuestions.first(where: { $0.id == questionId }) else { continue }
            for optionId in response.selectedOptionIds {
                guard let option = question.options.first(where: { $0.id == optionId }) else { continue }

                // Extraer género de las respuestas
                if let genderType = option.metadata?.genderType {
                    extractedGender = genderType
                    #if DEBUG
                    print("👤 [HomeTab GENDER] Género extraído de metadata.genderType: '\(genderType)'")
                    #endif
                } else if let gender = option.metadata?.gender {
                    extractedGender = gender
                    #if DEBUG
                    print("👤 [HomeTab GENDER] Género extraído de metadata.gender: '\(gender)'")
                    #endif
                } else if question.id.contains("gender") || question.category.lowercased().contains("gender") || questionId.contains("gender") {
                    // Fallback: usar option.value si es pregunta de género
                    extractedGender = option.value
                    #if DEBUG
                    print("👤 [HomeTab GENDER] Género extraído de option.value (pregunta de género): '\(option.value)'")
                    #endif
                }

                for (family, score) in option.families {
                    familyScores[family, default: 0] += Double(score)
                }
            }
        }

        #if DEBUG
        print("👤👤👤 [HomeTab GENDER] GÉNERO FINAL PARA PERFIL: '\(extractedGender)' 👤👤👤")
        #endif

        let total = familyScores.values.reduce(0, +)
        let normalizedScores = familyScores.mapValues { total > 0 ? $0 / total : 0 }
        let primaryFamily = normalizedScores.max(by: { $0.value < $1.value })?.key ?? "amaderados"

        // Crear perfil básico sin recomendaciones (para mostrar UI rápido)
        let basicProfile = OlfactiveProfile(
            id: UUID().uuidString,
            name: "Mi Perfil",
            gender: extractedGender,
            families: normalizedScores.map { FamilyPuntuation(family: $0.key, puntuation: Int($0.value * 100)) }
                .sorted { $0.puntuation > $1.puntuation },
            intensity: "media",
            duration: "media",
            descriptionProfile: nil,
            icon: nil,
            questionsAndAnswers: [],
            orderIndex: olfactiveProfileViewModel.profiles.count,
            createdAt: Date(),
            experienceLevel: "beginner",
            recommendedPerfumes: []
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
                genderPreference: extractedGender,
                metadata: UnifiedProfileMetadata(),
                confidenceScore: 0.8,
                answerCompleteness: 1.0,
                orderIndex: olfactiveProfileViewModel.profiles.count
            )

            if perfumeViewModel.metadataIndex.isEmpty {
                await perfumeViewModel.loadMetadataIndex()
            }

            let perfumesForScoring: [Perfume] = perfumeViewModel.metadataIndex.map { meta in
                Perfume(
                    id: meta.id, name: meta.name, brand: meta.brand, key: meta.key,
                    family: meta.family, subfamilies: meta.subfamilies ?? [],
                    topNotes: [], heartNotes: [], baseNotes: [],
                    projection: "media", intensity: "media", duration: "media",
                    recommendedSeason: [], associatedPersonalities: [], occasion: [],
                    popularity: meta.popularity, year: meta.year, perfumist: nil,
                    imageURL: "", description: "", gender: meta.gender, price: meta.price,
                    createdAt: nil, updatedAt: nil
                )
            }

            let recommendations = await UnifiedRecommendationEngine.shared.getRecommendations(
                for: profile,
                from: perfumesForScoring,
                limit: 10
            )
            profile.recommendedPerfumes = recommendations

            let legacyProfile = profile.toLegacyProfile()

            await MainActor.run {
                // Actualizar el perfil mostrado con las recomendaciones
                selectedProfileForNavigation = legacyProfile
                #if DEBUG
                print("✅ [HomeTab] Perfil actualizado con \(recommendations.count) recomendaciones")
                #endif
            }
        }
    }

    /// Vista de error cuando falla la carga de perfiles
    private func errorView(message: String) -> some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(AppColor.textSecondary)

            Text("Error al cargar perfiles")
                .font(.custom("Georgia", size: 20))
                .foregroundColor(AppColor.textPrimary)

            Text(message)
                .font(.system(size: 16))
                .foregroundColor(AppColor.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()
        }
        .padding(.top, AppSpacing.screenTopInset)
    }
}
