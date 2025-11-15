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

    // Recomendaciones
    @Published var recommendations: [GiftRecommendation] = []
    @Published var isShowingResults = false

    // Perfiles guardados
    @Published var savedProfiles: [GiftProfile] = []

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

        // ✅ Caso especial: brand_search (usa selectedOptions, no textInput)
        if question.uiConfig.textInputType == "brand_search" {
            let min = question.uiConfig.minSelection ?? 1
            return response.selectedOptions.count >= min
        }

        // Validar según tipo de configuración
        if question.uiConfig.isTextInput {
            // Para campos de texto, validar que textInput no esté vacío
            return response.textInput != nil && !response.textInput!.trimmingCharacters(in: .whitespaces).isEmpty
        } else if question.uiConfig.isMultipleSelection {
            let min = question.uiConfig.minSelection ?? 1
            return response.selectedOptions.count >= min
        }

        return !response.selectedOptions.isEmpty
    }

    var isLastQuestion: Bool {
        currentQuestionIndex == currentQuestions.count - 1
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

            // Empezar con preguntas principales
            currentQuestions = allQuestions.filter { $0.flowType == "main" }
                .sorted { $0.order < $1.order }

            // Reset estado
            currentQuestionIndex = 0
            responses = GiftResponsesCollection()
            currentFlow = nil
            recommendations = []
            isShowingResults = false

            #if DEBUG
            print("✅ [GiftVM] Started new flow with \(currentQuestions.count) main questions")
            print("   Total questions loaded: \(allQuestions.count)")
            let b1Count = allQuestions.filter { $0.flowType == "B1" }.count
            print("   B1 questions available: \(b1Count)")
            if b1Count > 0 {
                print("   B1 questions:")
                for q in allQuestions.filter({ $0.flowType == "B1" }).sorted(by: { $0.order < $1.order }) {
                    print("     - \(q.id) (order: \(q.order), conditional: \(q.isConditional))")
                }
            }
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

        // ✅ Para brand_search y search, los optionIds ya son los valores directos
        let selectedValues: [String]
        if question.uiConfig.textInputType == "brand_search" || question.uiConfig.textInputType == "search" {
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

        #if DEBUG
        print("📝 [GiftVM] Answered question '\(question.id)'")
        print("   Option IDs: \(optionIds)")
        print("   Values: \(selectedValues)")
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

        currentQuestionIndex -= 1

        // Saltar preguntas condicionales hacia atrás
        while currentQuestionIndex > 0,
              let question = currentQuestion,
              !shouldShowQuestion(question) {
            currentQuestionIndex -= 1
        }
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
    private let scoringEngine = GiftScoringEngine.shared
    private let metadataManager = MetadataIndexManager.shared

    // MARK: - Private Methods

    private func handleFlowControl(question: GiftQuestion, selectedOptions: [String]) {
        // ✅ selectedOptions ahora contiene VALUES, no IDs

        // Pregunta 1: Nivel de conocimiento
        if question.category == "knowledge_level" {
            guard let selectedValue = selectedOptions.first else { return }

            if selectedValue == "low_knowledge" {
                currentFlow = .flowA
                loadFlowQuestions(flowType: "A")
                #if DEBUG
                print("🔀 [GiftVM] Flow control: low_knowledge → Flow A")
                #endif
            } else if selectedValue == "high_knowledge" {
                // Ir a pregunta de tipo de referencia (pregunta 3B)
                // El flujo B se determina después
                #if DEBUG
                print("🔀 [GiftVM] Flow control: high_knowledge → Continue to reference_type")
                #endif
            }
        }

        // Pregunta 3B: Tipo de referencia
        if question.category == "reference_type" {
            guard let selectedValue = selectedOptions.first else { return }

            switch selectedValue {
            case "by_brand":
                currentFlow = .flowB1
                loadFlowQuestions(flowType: "B1")
            case "by_perfume":
                currentFlow = .flowB2
                loadFlowQuestions(flowType: "B2")
            case "by_aroma":
                currentFlow = .flowB3
                loadFlowQuestions(flowType: "B3")
            case "no_reference":
                currentFlow = .flowB4
                loadFlowQuestions(flowType: "B4")
            default:
                break
            }
        }
    }

    private func loadFlowQuestions(flowType: String) {
        let flowQuestions = allQuestions.filter { $0.flowType == flowType }
            .sorted { $0.order < $1.order }

        #if DEBUG
        print("🔀 [loadFlowQuestions] Flow: '\(flowType)'")
        print("   All questions count: \(allQuestions.count)")
        print("   Filtered for flow '\(flowType)': \(flowQuestions.count)")
        print("   Current questions before: \(currentQuestions.count)")
        if !flowQuestions.isEmpty {
            print("   Flow questions IDs:")
            for q in flowQuestions {
                print("     - \(q.id) (order: \(q.order))")
            }
        }
        #endif

        // Agregar preguntas del flujo a las actuales
        currentQuestions.append(contentsOf: flowQuestions)

        #if DEBUG
        print("   Current questions after: \(currentQuestions.count)")
        print("   Current question index: \(currentQuestionIndex)")
        print("   Is last question: \(isLastQuestion)")
        #endif
    }

    private func shouldShowQuestion(_ question: GiftQuestion) -> Bool {
        // Si no es condicional, siempre mostrar
        guard question.isConditional,
              let rules = question.conditionalRules else {
            #if DEBUG
            print("   ✅ [shouldShow] '\(question.id)' - NOT conditional, showing")
            #endif
            return true
        }

        // Verificar todas las reglas
        for (category, expectedValue) in rules {
            let actualValue = responses.getValue(for: category)

            #if DEBUG
            print("   🔍 [shouldShow] '\(question.id)' - Checking rule:")
            print("      Category: \(category)")
            print("      Expected: \(expectedValue)")
            print("      Actual: \(actualValue ?? "nil")")
            #endif

            if actualValue != expectedValue {
                #if DEBUG
                print("   ❌ [shouldShow] '\(question.id)' - Rule NOT matched, hiding")
                #endif
                return false
            }
        }

        #if DEBUG
        print("   ✅ [shouldShow] '\(question.id)' - All rules matched, showing")
        #endif
        return true
    }

    private func calculateRecommendations() async {
        isLoading = true

        do {
            // 1. Obtener metadata de todos los perfumes
            let allPerfumes = try await metadataManager.getMetadataIndex()

            #if DEBUG
            print("🎯 [GiftVM] Calculating recommendations from \(allPerfumes.count) perfumes")
            print("   Flow type: \(currentFlow?.rawValue ?? "unknown")")
            print("   Responses: \(responses.responses.count)")
            #endif

            // 2. Usar scoring engine para calcular recomendaciones
            // ✅ Cargar 20 recomendaciones (buffer para swipe-to-delete)
            recommendations = await scoringEngine.calculateRecommendations(
                responses: responses,
                allPerfumes: allPerfumes,
                flowType: currentFlow,
                limit: 20
            )

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
