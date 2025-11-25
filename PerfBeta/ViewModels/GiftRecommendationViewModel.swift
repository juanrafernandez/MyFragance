import Foundation
import SwiftUI
import Combine

@MainActor
class GiftRecommendationViewModel: ObservableObject {

    // MARK: - Published Properties

    // Estado de carga
    @Published var isLoading = false
    @Published var isLoadingQuestions = false
    @Published var isLoadingProfiles = false
    @Published var errorMessage: String?

    // Preguntas
    @Published var allQuestions: [GiftQuestion] = []
    @Published var currentQuestions: [GiftQuestion] = []
    @Published var currentQuestionIndex = 0

    // Flujo actual
    @Published var currentFlow: GiftFlowType?
    @Published var responses = GiftResponsesCollection()

    // ✅ Track the last answered question ID for conditional logic
    private var lastAnsweredQuestionId: String?

    // Recomendaciones
    @Published var recommendations: [GiftRecommendation] = []
    @Published var isShowingResults = false

    // Perfiles guardados
    @Published var savedProfiles: [GiftProfile] = []

    // NUEVO: Perfil unificado para sistema nuevo
    @Published var unifiedProfile: UnifiedProfile?

    // MARK: - Autocomplete State (similar a TestViewModel)
    @Published var selectedBrandKeys: [String] = []
    @Published var selectedPerfumeKeys: [String] = []
    @Published var autocompleteSearchText = ""

    // MARK: - Services
    private let questionService: GiftQuestionServiceProtocol
    private let profileService: GiftProfileServiceProtocol
    private let authService: AuthServiceProtocol

    // MARK: - Computed Properties

    var currentQuestion: GiftQuestion? {
        guard currentQuestionIndex < currentQuestions.count else { return nil }
        return currentQuestions[currentQuestionIndex]
    }

    var canGoBack: Bool {
        currentQuestionIndex > 0
    }

    var canContinue: Bool {
        // Verificar si la pregunta actual tiene respuesta válida
        guard let question = currentQuestion else { return false }
        guard let response = responses.getResponse(for: question.id) else { return false }

        // Validar según questionType
        switch question.questionType {
        case "autocomplete_brands", "autocomplete_perfumes":
            let min = question.minSelections ?? 1
            return response.selectedOptions.count >= min

        case "text_input":
            return response.textInput != nil && !response.textInput!.trimmingCharacters(in: .whitespaces).isEmpty

        case "multiple_choice":
            let min = question.minSelections ?? 1
            return response.selectedOptions.count >= min

        default:
            // single_choice, routing
            return !response.selectedOptions.isEmpty
        }
    }

    var isLastQuestion: Bool {
        guard let question = currentQuestion else {
            return true
        }

        #if DEBUG
        print("   🔍 [isLastQuestion] Checking for '\(question.id)'")
        print("      Current index: \(currentQuestionIndex)")
        print("      Total questions: \(currentQuestions.count)")
        print("      Current flow: \(currentFlow?.rawValue ?? "none")")
        #endif

        // ✅ Si la pregunta actual es de control de flujo, NO es la última
        // porque se añadirán más preguntas cuando se responda
        let flowControlCategories = ["knowledge_level", "reference_type"]
        if flowControlCategories.contains(question.category) {
            #if DEBUG
            print("      ⚠️ Is flow control - NOT last")
            #endif
            return false
        }

        // ✅ Verificar si hay más preguntas después de esta posición
        if currentQuestionIndex < currentQuestions.count - 1 {
            #if DEBUG
            let remaining = currentQuestions.count - currentQuestionIndex - 1
            print("      ⚠️ \(remaining) questions remaining - NOT last")
            #endif
            return false
        }

        #if DEBUG
        print("      ✅ This IS the last question")
        #endif
        return true
    }

    var progress: Double {
        guard !currentQuestions.isEmpty else { return 0 }
        return Double(currentQuestionIndex + 1) / Double(currentQuestions.count)
    }

    // MARK: - Initialization

    init(
        questionService: GiftQuestionServiceProtocol = GiftQuestionService.shared,
        profileService: GiftProfileServiceProtocol = GiftProfileService.shared,
        authService: AuthServiceProtocol
    ) {
        self.questionService = questionService
        self.profileService = profileService
        self.authService = authService
    }

    // MARK: - Public Methods

    /// Iniciar nuevo flujo de regalo
    func startNewFlow() async {
        isLoadingQuestions = true
        errorMessage = nil

        do {
            // Cargar todas las preguntas
            allQuestions = try await questionService.loadQuestions()

            // Empezar solo con preguntas principales (gift_00, gift_01)
            // Las preguntas de flujo (A, B, C, D, E, F) se cargan dinámicamente según routing
            currentQuestions = allQuestions.filter {
                $0.id.starts(with: "gift_00") ||
                $0.id.starts(with: "gift_01")
            }
                .sorted { $0.order < $1.order }

            // Reset estado
            currentQuestionIndex = 0
            responses = GiftResponsesCollection()
            currentFlow = nil
            recommendations = []
            isShowingResults = false
            lastAnsweredQuestionId = nil  // ✅ Reset tracking

            #if DEBUG
            print("✅ [GiftVM] Started new flow with \(currentQuestions.count) control questions (gift_00, gift_01)")
            print("   Total questions loaded: \(allQuestions.count)")
            print("   Flow questions will be loaded dynamically based on user selection")
            #endif
        } catch {
            errorMessage = "Error al cargar preguntas: \(error.localizedDescription)"
            #if DEBUG
            print("❌ [GiftVM] Error loading questions: \(error)")
            #endif
        }

        isLoadingQuestions = false
    }

    /// Responder a la pregunta actual
    func answerQuestion(with optionIds: [String], textInput: String? = nil) {
        guard let question = currentQuestion else { return }

        // ✅ Para autocomplete, los optionIds ya son los valores directos
        let selectedValues: [String]
        if question.questionType == "autocomplete_brands" || question.questionType == "autocomplete_perfumes" {
            selectedValues = optionIds  // ✅ Usar directamente los IDs/keys pasados
        } else {
            // ✅ Extraer los VALUES de las opciones seleccionadas (no solo los IDs)
            selectedValues = optionIds.compactMap { optionId in
                question.options.first(where: { $0.id == optionId })?.value
            }
        }

        let response = GiftResponse(
            questionId: question.id,
            category: question.category,
            selectedOptions: selectedValues,  // ✅ Ahora almacenamos VALUES
            textInput: textInput
        )

        responses.addResponse(response)

        // ✅ Track which question was just answered for conditional logic
        lastAnsweredQuestionId = question.id

        #if DEBUG
        print("📝 [GiftVM] Answered question '\(question.id)'")
        print("   Option IDs: \(optionIds)")
        print("   Values: \(selectedValues)")
        print("   Last answered question set to: \(question.id)")
        #endif

        // Si es una pregunta de control de flujo, actualizar flujo
        handleFlowControl(question: question, selectedOptions: selectedValues)
    }

    /// Avanzar a la siguiente pregunta
    func nextQuestion() async {
        guard canContinue else { return }

        #if DEBUG
        print("🔄 [nextQuestion] Current index: \(currentQuestionIndex)/\(currentQuestions.count-1)")
        print("   isLastQuestion: \(isLastQuestion)")
        print("   currentFlow: \(currentFlow?.rawValue ?? "nil")")
        #endif

        if isLastQuestion {
            #if DEBUG
            print("✅ [nextQuestion] Last question reached, calculating recommendations...")
            #endif
            // Calcular recomendaciones
            await calculateRecommendations()
        } else {
            currentQuestionIndex += 1

            #if DEBUG
            print("➡️ [nextQuestion] Advanced to index \(currentQuestionIndex)")
            #endif

            // Saltar preguntas condicionales que no aplican
            while let question = currentQuestion,
                  !shouldShowQuestion(question) {
                #if DEBUG
                print("⏭️ [nextQuestion] Skipping conditional question '\(question.id)'")
                #endif
                currentQuestionIndex += 1

                if currentQuestionIndex >= currentQuestions.count {
                    #if DEBUG
                    print("✅ [nextQuestion] No more questions, calculating recommendations...")
                    #endif
                    await calculateRecommendations()
                    return
                }
            }

            #if DEBUG
            if let q = currentQuestion {
                print("📋 [nextQuestion] Now showing: '\(q.id)'")
            }
            #endif
        }
    }

    /// Retroceder a la pregunta anterior
    func previousQuestion() {
        guard canGoBack else { return }

        #if DEBUG
        print("⬅️ [previousQuestion] Going back from index \(currentQuestionIndex)")
        if let current = currentQuestion {
            print("   Current question: '\(current.id)'")
        }
        #endif

        currentQuestionIndex -= 1

        #if DEBUG
        print("   New index after -1: \(currentQuestionIndex)")
        if let newCurrent = currentQuestion {
            print("   Question at new index: '\(newCurrent.id)'")
        }
        #endif

        // ✅ Al retroceder, NO saltar preguntas condicionales
        // El usuario ya navegó por ellas, simplemente volver a la anterior
        // Solo saltar si la pregunta NO TIENE respuesta guardada
        while currentQuestionIndex > 0,
              let question = currentQuestion,
              responses.getResponse(for: question.id) == nil {
            #if DEBUG
            print("   ⏭️ Skipping unanswered question '\(question.id)'")
            #endif
            currentQuestionIndex -= 1
        }

        // ✅ Actualizar lastAnsweredQuestionId a la pregunta anterior a la actual
        if currentQuestionIndex > 0 {
            let previousIndex = currentQuestionIndex - 1
            if previousIndex >= 0 && previousIndex < currentQuestions.count {
                lastAnsweredQuestionId = currentQuestions[previousIndex].id
                #if DEBUG
                print("   Updated lastAnsweredQuestionId to: '\(lastAnsweredQuestionId ?? "nil")'")
                #endif
            }
        } else {
            lastAnsweredQuestionId = nil
            #if DEBUG
            print("   Reset lastAnsweredQuestionId to nil (at first question)")
            #endif
        }

        #if DEBUG
        if let final = currentQuestion {
            print("   ✅ Final question after going back: '\(final.id)' at index \(currentQuestionIndex)")
        }
        #endif
    }

    /// Guardar perfil de regalo
    func saveProfile(nickname: String) async {
        guard let userId = authService.getCurrentAuthUser()?.id else {
            errorMessage = "Usuario no autenticado"
            return
        }

        isLoading = true

        do {
            var profile = GiftProfile(
                nickname: nickname,
                knowledgeLevel: responses.knowledgeLevel ?? "unknown",
                responses: responses,
                recommendations: recommendations
            )

            // Extraer datos procesados
            profile.preferredFamilies = extractPreferredFamilies()
            profile.preferredPersonalities = extractPreferredPersonalities()
            profile.preferredOccasions = extractPreferredOccasions()
            profile.priceRange = extractPriceRange()

            // ✅ Guardar el perfume de referencia si existe (flujo B2)
            if let refKey = responses.referencePerfumeSearch {
                profile.referencePerfumeKey = refKey

                #if DEBUG
                print("💾 [GiftVM] Saving reference perfume key: \(refKey)")
                #endif
            }

            try await profileService.saveProfile(profile, userId: userId)

            // Recargar perfiles
            await loadProfiles()

            #if DEBUG
            print("✅ [GiftVM] Profile saved: \(profile.displayName)")
            #endif
        } catch {
            errorMessage = "Error al guardar perfil: \(error.localizedDescription)"
            #if DEBUG
            print("❌ [GiftVM] Error saving profile: \(error)")
            #endif
        }

        isLoading = false
    }

    /// Cargar perfiles guardados
    func loadProfiles() async {
        guard let userId = authService.getCurrentAuthUser()?.id else { return }

        isLoadingProfiles = true

        do {
            savedProfiles = try await profileService.loadProfiles(userId: userId)

            #if DEBUG
            print("✅ [GiftVM] Loaded \(savedProfiles.count) saved profiles")
            #endif
        } catch {
            errorMessage = "Error al cargar perfiles: \(error.localizedDescription)"
            #if DEBUG
            print("❌ [GiftVM] Error loading profiles: \(error)")
            #endif
        }

        isLoadingProfiles = false
    }

    /// Cargar perfil existente
    func loadProfile(_ profile: GiftProfile) {
        responses = profile.responses
        currentFlow = profile.flowTypeEnum
        recommendations = profile.recommendations
        isShowingResults = true

        #if DEBUG
        print("✅ [GiftVM] Loaded profile: \(profile.displayName)")
        #endif
    }

    /// Eliminar perfil
    func deleteProfile(_ profile: GiftProfile) async {
        guard let userId = authService.getCurrentAuthUser()?.id else { return }

        do {
            try await profileService.deleteProfile(id: profile.id, userId: userId)
            await loadProfiles()

            #if DEBUG
            print("✅ [GiftVM] Profile deleted: \(profile.id)")
            #endif
        } catch {
            errorMessage = "Error al eliminar perfil: \(error.localizedDescription)"
            #if DEBUG
            print("❌ [GiftVM] Error deleting profile: \(error)")
            #endif
        }
    }

    /// Actualizar orden de perfiles
    func updateOrder(newOrderedProfiles: [GiftProfile]) async {
        guard let userId = authService.getCurrentAuthUser()?.id else { return }

        // Actualizar localmente primero (optimistic update)
        savedProfiles = newOrderedProfiles

        do {
            try await profileService.updateOrderIndices(newOrderedProfiles, userId: userId)

            #if DEBUG
            print("✅ [GiftVM] Profile order updated")
            #endif
        } catch {
            errorMessage = "Error al actualizar orden: \(error.localizedDescription)"
            #if DEBUG
            print("❌ [GiftVM] Error updating order: \(error)")
            #endif
            // Recargar para revertir cambio optimista
            await loadProfiles()
        }
    }

    // MARK: - Dependencies
    private let metadataManager = MetadataIndexManager.shared

    // Sistema unificado activo (legacy eliminado)
    private let useUnifiedEngine: Bool = true

    // MARK: - Private Methods

    private func handleFlowControl(question: GiftQuestion, selectedOptions: [String]) {
        // Solo procesar si la pregunta es de tipo routing
        guard question.questionType == "routing" else { return }
        guard let selectedValue = selectedOptions.first else { return }

        // Buscar la opción seleccionada por su value
        guard let selectedOption = question.options.first(where: { $0.value == selectedValue }) else {
            #if DEBUG
            print("⚠️ [GiftVM] handleFlowControl: No se encontró opción para value '\(selectedValue)'")
            #endif
            return
        }

        // ✅ Intentar leer el campo `route` de la opción, si no existe usar lógica hardcodeada
        let route: String
        if let explicitRoute = selectedOption.route {
            route = explicitRoute
        } else {
            // ✅ Lógica hardcodeada basada en el ID de la pregunta y el valor seleccionado
            route = inferRoute(questionId: question.id, selectedValue: selectedValue)

            #if DEBUG
            print("ℹ️ [GiftVM] handleFlowControl: Opción '\(selectedValue)' sin route, usando inferencia → '\(route)'")
            #endif
        }

        #if DEBUG
        print("🔀 [GiftVM] Flow control: '\(selectedValue)' → '\(route)'")
        #endif

        // Limpiar preguntas de flujo anterior
        removeFlowQuestions()

        // Cargar preguntas del nuevo flujo
        loadFlowQuestions(route: route)

        // Actualizar currentFlow según el route
        switch route {
        case "flow_A":
            currentFlow = .flowA
        case "flow_B":
            currentFlow = .flowB
        case "flow_C":
            currentFlow = .flowC
        case "flow_D":
            currentFlow = .flowD
        case "flow_E":
            currentFlow = .flowE
        case "flow_F":
            currentFlow = .flowF
        default:
            break
        }
    }

    /// Inferir route basado en lógica hardcodeada cuando no hay nextFlow en Firebase
    private func inferRoute(questionId: String, selectedValue: String) -> String {
        // gift_01_knowledge_level routing
        if questionId == "gift_01_knowledge_level" {
            if selectedValue == "low_knowledge" {
                return "flow_A"  // Flujo para conocimiento bajo
            } else if selectedValue == "high_knowledge" {
                // Necesitamos la siguiente pregunta de control para decidir B1/B2/B3/B4
                // Por ahora, retornar "flow_B" genérico y manejar sub-flujos después
                return "flow_B"
            }
        }

        // gift_B1_reference_type routing (dentro de conocimiento alto)
        if questionId == "gift_B1_reference_type" {
            switch selectedValue {
            case "by_brands":
                return "flow_C"  // Por marcas
            case "by_perfume":
                return "flow_D"  // Por perfume conocido
            case "by_aromas":
                return "flow_E"  // Por aromas
            case "no_reference":
                return "flow_F"  // Sin referencias
            default:
                break
            }
        }

        // Default: continuar secuencialmente
        return ""
    }

    /// Elimina todas las preguntas de flujos (A, B, C, D, E, F) dejando solo las main
    private func removeFlowQuestions() {
        let previousCount = currentQuestions.count

        // Filtrar solo preguntas principales (gift_00, gift_01)
        // Las preguntas de flujo (incluyendo gift_B0) se eliminan
        currentQuestions = currentQuestions.filter { question in
            question.id.starts(with: "gift_00") ||
            question.id.starts(with: "gift_01")
        }

        #if DEBUG
        let removedCount = previousCount - currentQuestions.count
        if removedCount > 0 {
            print("🧹 [removeFlowQuestions] Removed \(removedCount) flow questions")
            print("   Questions remaining: \(currentQuestions.count)")
        }
        #endif
    }

    private func loadFlowQuestions(route: String) {
        // Convertir route "flow_A" → prefijo "gift_A"
        // flow_A → gift_A, flow_B → gift_B, flow_C → gift_C, etc.
        let flowLetter = route.replacingOccurrences(of: "flow_", with: "")
        let prefix = "gift_\(flowLetter)"

        let flowQuestions = allQuestions.filter { $0.id.starts(with: prefix) }
            .sorted { $0.order < $1.order }

        #if DEBUG
        print("🔀 [loadFlowQuestions] Route: '\(route)' → Prefix: '\(prefix)'")
        print("   All questions count: \(allQuestions.count)")
        print("   Filtered for prefix '\(prefix)': \(flowQuestions.count)")
        print("   Current questions before: \(currentQuestions.count)")
        if !flowQuestions.isEmpty {
            print("   Flow questions IDs:")
            for q in flowQuestions {
                print("     - \(q.id) (order: \(q.order))")
            }
        }
        #endif

        // ✅ Verificar si las preguntas del flujo ya están añadidas
        let currentQuestionIds = Set(currentQuestions.map { $0.id })
        let newQuestions = flowQuestions.filter { !currentQuestionIds.contains($0.id) }

        if newQuestions.isEmpty {
            #if DEBUG
            print("   ⚠️ Flow questions already loaded, skipping append")
            #endif
            return
        }

        #if DEBUG
        print("   Adding \(newQuestions.count) new questions (skipping \(flowQuestions.count - newQuestions.count) already present)")
        #endif

        // Agregar solo las preguntas que no están ya presentes
        currentQuestions.append(contentsOf: newQuestions)

        #if DEBUG
        print("   Current questions after: \(currentQuestions.count)")
        print("   Current question index: \(currentQuestionIndex)")
        print("   Is last question: \(isLastQuestion)")
        #endif
    }

    private func shouldShowQuestion(_ question: GiftQuestion) -> Bool {
        // ✅ All questions are shown - routing is handled via route field in options
        #if DEBUG
        print("   ✅ [shouldShow] '\(question.id)' - showing (data-driven routing)")
        #endif
        return true
    }

    func calculateRecommendations() async {
        isLoading = true

        // Calcular perfil con UnifiedEngine (sistema único)
        await calculateWithUnifiedEngine()

        do {
            // 1. Obtener metadata de todos los perfumes
            let allPerfumes = try await metadataManager.getMetadataIndex()

            #if DEBUG
            print("🎯 [GiftVM] Calculating recommendations from \(allPerfumes.count) perfumes")
            print("   Flow type: \(currentFlow?.rawValue ?? "unknown")")
            print("   Responses: \(responses.responses.count)")
            #endif

            // 2. Generar recomendaciones basadas en el perfil unificado
            if let profile = unifiedProfile {
                #if DEBUG
                print("   Profile generated: \(profile.name)")
                print("   Primary family: \(profile.primaryFamily)")
                print("   Gender preference: \(profile.genderPreference)")
                print("   Calculating recommendations using UnifiedEngine...")
                #endif

                // ✅ Convertir metadata a "fake" perfumes para cálculo
                let fakePerfumes: [Perfume] = allPerfumes.map { meta in
                    Perfume(
                        id: meta.id,
                        name: meta.name,
                        brand: meta.brand,
                        key: meta.key,
                        family: meta.family,
                        subfamilies: meta.subfamilies ?? [],
                        topNotes: [],
                        heartNotes: [],
                        baseNotes: [],
                        projection: "media",
                        intensity: "media",
                        duration: "media",
                        recommendedSeason: [],
                        associatedPersonalities: [],
                        occasion: [],
                        popularity: meta.popularity,
                        year: meta.year,
                        perfumist: nil,
                        imageURL: "",
                        description: "",
                        gender: meta.gender,
                        price: meta.price,
                        createdAt: nil,
                        updatedAt: nil
                    )
                }

                // ✅ Usar UnifiedEngine para calcular recomendaciones CON filtro de género
                let recommendedPerfumes = await UnifiedRecommendationEngine.shared.getRecommendations(
                    for: profile,
                    from: fakePerfumes,
                    limit: 10
                )

                // ✅ Convertir a GiftRecommendation
                recommendations = recommendedPerfumes.map { recommended in
                    // Buscar el perfume en fakePerfumes para obtener info adicional
                    let perfume = fakePerfumes.first { $0.id == recommended.perfumeId }
                    let score = recommended.matchPercentage

                    return GiftRecommendation(
                        perfumeKey: perfume?.key ?? recommended.perfumeId,
                        score: score,
                        reason: "Coincidencia \(Int(score))% con el perfil",
                        matchFactors: [
                            MatchFactor(
                                factor: "Familia",
                                description: perfume?.family ?? "N/A",
                                weight: 1.0
                            )
                        ],
                        confidence: score > 80 ? "high" : score > 60 ? "medium" : "low"
                    )
                }
            } else {
                // Fallback: recomendaciones por popularidad (solo si no hay perfil)
                recommendations = await generateFallbackRecommendations(allPerfumes: allPerfumes)
            }

            #if DEBUG
            print("✅ [GiftVM] Generated \(recommendations.count) recommendations")
            if let top = recommendations.first {
                print("   Top: \(top.perfumeKey) - Score: \(String(format: "%.1f", top.score))")
            }
            #endif

            // Validación: si no hay suficientes recomendaciones, generar fallback
            if recommendations.count < 3 {
                #if DEBUG
                print("⚠️ [GiftVM] Insufficient recommendations (\(recommendations.count)), generating fallback...")
                #endif

                // Fallback: recomendar perfumes populares
                recommendations = await generateFallbackRecommendations(allPerfumes: allPerfumes)
            }

        } catch {
            errorMessage = "Error al calcular recomendaciones: \(error.localizedDescription)"
            #if DEBUG
            print("❌ [GiftVM] Error calculating recommendations: \(error)")
            #endif

            // Fallback en caso de error
            recommendations = []
        }

        isShowingResults = true
        isLoading = false
    }

    // MARK: - Unified Engine Integration

    /// Convierte las respuestas de Gift al formato del UnifiedRecommendationEngine
    private func convertToUnifiedFormat() -> [String: (question: Question, option: Option)]? {
        #if DEBUG
        print("🔄 [GiftVM] Converting Gift responses to Unified format...")
        #endif

        var unifiedAnswers: [String: (question: Question, option: Option)] = [:]

        // Iterar sobre todas las preguntas respondidas
        for (questionId, giftResponse) in responses.responses {
            // Buscar la pregunta correspondiente
            guard let giftQuestion = allQuestions.first(where: { $0.id == questionId }) else {
                #if DEBUG
                print("⚠️ [GiftVM] Question not found for ID: \(questionId)")
                #endif
                continue
            }

            // Procesar cada opción seleccionada
            for selectedOptionId in giftResponse.selectedOptions {
                // Buscar la opción seleccionada
                guard let giftOption = giftQuestion.options.first(where: { $0.id == selectedOptionId }) else {
                    #if DEBUG
                    print("⚠️ [GiftVM] Option not found: \(selectedOptionId) in question \(questionId)")
                    #endif
                    continue
                }

                // Convertir GiftQuestion a Question
                let question = Question(
                    id: giftQuestion.id,
                    key: giftQuestion.category,  // Usar category como key
                    questionType: "gift_flow",
                    order: giftQuestion.order,
                    category: giftQuestion.category,
                    text: giftQuestion.text,
                    stepType: nil,
                    multiSelect: giftQuestion.isMultipleChoice,
                    weight: 0,  // Por defecto 0, solo metadata
                    helperText: giftQuestion.helperText,
                    placeholder: giftQuestion.placeholder,
                    dataSource: nil,
                    maxSelections: giftQuestion.maxSelections,
                    minSelections: giftQuestion.minSelections,
                    skipOption: nil,
                    options: []  // No necesitamos todas las opciones, solo la seleccionada
                )

                // Convertir GiftQuestionOption a Option con metadata
                var metadata: OptionMetadata? = nil

                // Extraer metadata de la opción de gift
                if let personalities = giftOption.personalities {
                    metadata = OptionMetadata(
                        occasion: giftOption.occasions,
                        season: giftOption.seasons,
                        personality: personalities,
                        intensity: giftOption.intensity?.first,
                        projection: giftOption.projection?.first
                    )
                } else if giftOption.occasions != nil || giftOption.seasons != nil {
                    metadata = OptionMetadata(
                        occasion: giftOption.occasions,
                        season: giftOption.seasons,
                        intensity: giftOption.intensity?.first,
                        projection: giftOption.projection?.first
                    )
                }

                let option = Option(
                    id: giftOption.id,
                    label: giftOption.label,
                    value: giftOption.value,
                    description: giftOption.description ?? "",
                    image_asset: giftOption.imageAsset ?? "",
                    families: giftOption.families ?? [:],
                    metadata: metadata
                )

                // Guardar en el formato unificado (usar questionId como key única)
                let uniqueKey = "\(questionId)_\(selectedOptionId)"
                unifiedAnswers[uniqueKey] = (question, option)

                #if DEBUG
                print("   ✅ Mapped: \(giftQuestion.category) -> \(giftOption.value)")
                #endif
            }
        }

        #if DEBUG
        print("✅ [GiftVM] Converted \(unifiedAnswers.count) answers to Unified format")
        #endif

        return unifiedAnswers.isEmpty ? nil : unifiedAnswers
    }

    /// Calcula perfil usando el nuevo UnifiedRecommendationEngine
    private func calculateWithUnifiedEngine() async {
        #if DEBUG
        print("🧮 [GiftVM] Calculating profile with UnifiedRecommendationEngine...")
        #endif

        // 1. Convertir respuestas al formato unificado
        guard let unifiedAnswers = convertToUnifiedFormat() else {
            #if DEBUG
            print("❌ [GiftVM] Failed to convert responses to unified format")
            #endif
            return
        }

        // 2. Determinar nombre del perfil
        let recipientName = responses.getTextInput(for: "recipient_name") ?? "Regalo"
        let profileName = "Regalo para \(recipientName)"

        // 3. Calcular perfil con UnifiedRecommendationEngine
        let profile = await UnifiedRecommendationEngine.shared.calculateProfile(
            from: unifiedAnswers,
            profileName: profileName,
            profileType: .gift  // ← Importante: usar pesos de regalo
        )

        // 4. Guardar perfil unificado
        self.unifiedProfile = profile

        #if DEBUG
        print("✅ [GiftVM] Unified profile calculated:")
        print("   Primary family: \(profile.primaryFamily)")
        print("   Subfamilies: \(profile.subfamilies.joined(separator: ", "))")
        print("   Confidence: \(String(format: "%.2f", profile.confidenceScore))")
        print("   Gender preference: \(profile.genderPreference)")
        #endif
    }

    /// Generar recomendaciones de fallback basadas en popularidad
    private func generateFallbackRecommendations(allPerfumes: [PerfumeMetadata]) async -> [GiftRecommendation] {
        let topPopular = allPerfumes
            .filter { $0.popularity != nil }
            .sorted { ($0.popularity ?? 0) > ($1.popularity ?? 0) }
            .prefix(10)

        return topPopular.map { perfume in
            let popularity = perfume.popularity ?? 0
            return GiftRecommendation(
                perfumeKey: perfume.key,
                score: popularity * 10,
                reason: "Perfume muy popular y versátil",
                matchFactors: [
                    MatchFactor(
                        factor: "Popularidad",
                        description: "Puntuación \(String(format: "%.1f", popularity))/10",
                        weight: 1.0
                    )
                ],
                confidence: "medium"
            )
        }
    }

    private func extractPreferredFamilies() -> [String] {
        // TODO: Extraer de las respuestas
        return []
    }

    private func extractPreferredPersonalities() -> [String] {
        // TODO: Extraer de las respuestas
        return []
    }

    private func extractPreferredOccasions() -> [String] {
        // TODO: Extraer de las respuestas
        return []
    }

    private func extractPriceRange() -> [String] {
        // TODO: Extraer de las respuestas
        return []
    }
}
