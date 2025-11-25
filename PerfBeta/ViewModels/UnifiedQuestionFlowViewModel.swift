import Foundation
import SwiftUI
import Combine

/// ViewModel unificado para gestionar cualquier flujo de preguntas
/// Funciona tanto para test personal como para flujo de regalo
/// Soporta routing dinámico y extracción de families/metadata
@MainActor
final class UnifiedQuestionFlowViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var currentQuestionIndex: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: IdentifiableString?
    @Published var isCompleted: Bool = false

    // MARK: - Private Properties

    private var allQuestions: [UnifiedQuestion] = []  // Todas las preguntas cargadas
    private var currentQuestions: [UnifiedQuestion] = []  // Preguntas activas del flujo actual
    private var responses: [String: UnifiedResponse] = [:]  // questionId -> response
    private var currentFlow: String?  // Flujo actual (flow_A, flow_B, etc.)
    private var navigationHistory: [String] = []  // Historial de IDs de preguntas visitadas (no índices)

    // MARK: - Computed Properties

    var currentQuestion: UnifiedQuestion? {
        guard !currentQuestions.isEmpty, currentQuestionIndex < currentQuestions.count else { return nil }
        return currentQuestions[currentQuestionIndex]
    }

    var progress: Double {
        guard !currentQuestions.isEmpty else { return 0 }
        return Double(currentQuestionIndex + 1) / Double(currentQuestions.count)
    }

    var canGoBack: Bool {
        return !navigationHistory.isEmpty
    }

    var isLastQuestion: Bool {
        guard let question = currentQuestion else { return true }

        // Si es pregunta de routing, NO es la última (se cargarán más)
        if question.isRoutingQuestion {
            return false
        }

        // Si hay más preguntas después, NO es la última
        if currentQuestionIndex < currentQuestions.count - 1 {
            return false
        }

        return true
    }

    var canContinue: Bool {
        guard let question = currentQuestion else { return false }

        // Para autocomplete, permitir continuar incluso sin respuesta si minSelection = 0
        if question.isAutocompleteNotes || question.isAutocompleteBrands || question.isAutocompletePerfumes {
            guard let response = responses[question.id] else {
                // Si no hay respuesta, solo permitir si minSelection es 0
                return question.minSelection == 0
            }

            let count = response.selectedOptionIds.count
            // Permitir "skip" como válido
            if response.selectedOptionIds.contains("skip") {
                return true
            }

            // Si minSelection existe, verificar que se cumple el mínimo
            if let min = question.minSelection {
                return count >= min
            }

            // Si no hay minSelection definido, requiere al menos 1
            return count > 0
        }

        // Para el resto de preguntas, requiere respuesta
        guard let response = responses[question.id] else { return false }

        if question.requiresTextInput {
            return !(response.textInput ?? "").isEmpty
        } else if question.allowsMultipleSelection {
            let count = response.selectedOptionIds.count
            if let min = question.minSelection {
                return count >= min
            }
            return count > 0
        } else {
            return !response.selectedOptionIds.isEmpty
        }
    }

    // MARK: - Initialization

    /// Carga TODAS las preguntas y filtra las iniciales según el prefijo
    /// @param questions: Todas las preguntas del tipo (profile o gift)
    func loadQuestions(_ questions: [UnifiedQuestion]) {
        self.allQuestions = questions
        self.currentQuestionIndex = 0
        self.responses = [:]
        self.isCompleted = false
        self.currentFlow = nil

        // Inferir prefijo desde las preguntas
        let questionPrefix: String
        if let firstId = questions.first?.id {
            if firstId.starts(with: "profile_") {
                questionPrefix = "profile_"
            } else if firstId.starts(with: "gift_") {
                questionPrefix = "gift_"
            } else {
                questionPrefix = ""
            }
        } else {
            questionPrefix = ""
        }

        // Cargar solo las preguntas iniciales de routing (00, 01)
        self.currentQuestions = questions.filter {
            $0.id.starts(with: "\(questionPrefix)00") ||
            $0.id.starts(with: "\(questionPrefix)01")
        }.sorted { $0.order < $1.order }

        #if DEBUG
        print("✅ [UnifiedQuestionFlow] Loaded \(allQuestions.count) total questions")
        print("   Prefix detected: \(questionPrefix)")
        print("   Initial questions: \(currentQuestions.count)")
        print("   Question IDs: \(currentQuestions.map { $0.id })")
        #endif
    }

    // MARK: - Navigation

    func nextQuestion() {
        guard canContinue else {
            #if DEBUG
            print("⚠️ [UnifiedQuestionFlow] No se puede continuar - respuesta incompleta")
            #endif
            return
        }

        // Manejar routing si la pregunta actual lo requiere
        if let question = currentQuestion, question.isRoutingQuestion {
            // Guardar ID de la pregunta de routing en el historial
            navigationHistory.append(question.id)

            #if DEBUG
            print("🔀 [UnifiedQuestionFlow] Routing desde: \(question.id)")
            print("   Historial: \(navigationHistory)")
            #endif

            handleRouting(for: question)
            // Nota: handleRouting() ajusta currentQuestionIndex automáticamente
            return  // No incrementar el índice, ya está en la primera pregunta del nuevo flow
        }

        if isLastQuestion {
            completeFlow()
        } else {
            // Guardar ID de pregunta actual en el historial
            if let question = currentQuestion {
                navigationHistory.append(question.id)
            }

            currentQuestionIndex += 1

            #if DEBUG
            print("➡️ [UnifiedQuestionFlow] Avanzando a pregunta \(currentQuestionIndex + 1)/\(currentQuestions.count)")
            if let nextQ = currentQuestion {
                print("   Siguiente: \(nextQ.id)")
            }
            print("   Historial: \(navigationHistory)")
            #endif
        }
    }

    func previousQuestion() {
        guard canGoBack else { return }

        // Obtener la pregunta anterior del historial
        guard let previousQuestionId = navigationHistory.popLast() else {
            #if DEBUG
            print("⬅️ [UnifiedQuestionFlow] No hay más preguntas en el historial")
            #endif
            return
        }

        // Buscar la pregunta por ID en currentQuestions (siempre debe existir)
        guard let index = currentQuestions.firstIndex(where: { $0.id == previousQuestionId }) else {
            #if DEBUG
            print("❌ [UnifiedQuestionFlow] ERROR: Pregunta \(previousQuestionId) no encontrada en currentQuestions")
            #endif
            return
        }

        currentQuestionIndex = index

        #if DEBUG
        print("⬅️ [UnifiedQuestionFlow] Retrocediendo a pregunta: \(previousQuestionId)")
        print("   Índice: \(currentQuestionIndex)")
        print("   Historial restante: \(navigationHistory)")
        if let prevQ = currentQuestion, let response = responses[prevQ.id] {
            print("   Respuesta guardada: \(response.selectedOptionIds)")
        }
        #endif
    }

    // MARK: - Response Handling

    func selectOption(_ optionId: String) {
        guard let question = currentQuestion else { return }

        var response = responses[question.id] ?? UnifiedResponse(questionId: question.id)
        response.selectedOptionIds = [optionId]
        responses[question.id] = response

        // Forzar actualización de la vista
        objectWillChange.send()

        #if DEBUG
        print("✅ [UnifiedQuestionFlow] Opción seleccionada: \(optionId)")
        #endif
    }

    func selectMultipleOptions(_ optionIds: [String]) {
        guard let question = currentQuestion else { return }

        var response = responses[question.id] ?? UnifiedResponse(questionId: question.id)
        response.selectedOptionIds = optionIds
        responses[question.id] = response

        // Forzar actualización de la vista
        objectWillChange.send()

        #if DEBUG
        print("✅ [UnifiedQuestionFlow] Opciones múltiples: \(optionIds.count) seleccionadas")
        #endif
    }

    func inputText(_ text: String) {
        guard let question = currentQuestion else { return }

        var response = responses[question.id] ?? UnifiedResponse(questionId: question.id)
        response.textInput = text
        responses[question.id] = response

        // Forzar actualización de la vista
        objectWillChange.send()

        #if DEBUG
        print("✅ [UnifiedQuestionFlow] Texto ingresado: \(text.prefix(20))...")
        #endif
    }

    func isOptionSelected(_ optionId: String) -> Bool {
        guard let question = currentQuestion else { return false }
        guard let response = responses[question.id] else { return false }
        return response.selectedOptionIds.contains(optionId)
    }

    func getSelectedOptions() -> [String] {
        guard let question = currentQuestion else { return [] }
        return responses[question.id]?.selectedOptionIds ?? []
    }

    func getTextInput() -> String {
        guard let question = currentQuestion else { return "" }
        return responses[question.id]?.textInput ?? ""
    }

    // MARK: - Completion

    private func completeFlow() {
        isCompleted = true

        #if DEBUG
        print("🎉 [UnifiedQuestionFlow] Flujo completado - \(responses.count) respuestas")
        #endif
    }

    func getAllResponses() -> [String: UnifiedResponse] {
        return responses
    }

    func reset() {
        currentQuestionIndex = 0
        responses = [:]
        isCompleted = false
        currentFlow = nil
        currentQuestions = []
        navigationHistory = []
    }

    // MARK: - Routing Logic

    /// Maneja el routing dinámico cuando se responde a una pregunta de tipo routing
    private func handleRouting(for question: UnifiedQuestion) {
        guard let response = responses[question.id] else { return }
        guard let selectedOptionId = response.selectedOptionIds.first else { return }

        // Buscar la opción seleccionada
        guard let selectedOption = question.options.first(where: { $0.id == selectedOptionId }) else {
            #if DEBUG
            print("⚠️ [UnifiedQuestionFlow] Opción no encontrada: \(selectedOptionId)")
            #endif
            return
        }

        // Intentar usar route explícito, o inferirlo si no existe
        let route: String
        if let explicitRoute = selectedOption.route, !explicitRoute.isEmpty {
            route = explicitRoute
        } else {
            // Inferir route basado en lógica hardcodeada
            let inferredRoute = inferRoute(questionId: question.id, selectedValue: selectedOption.value)

            if inferredRoute.isEmpty {
                #if DEBUG
                print("ℹ️ [UnifiedQuestionFlow] Opción '\(selectedOption.value)' sin route - continuar secuencialmente")
                #endif
                return
            }

            route = inferredRoute

            #if DEBUG
            print("🔍 [UnifiedQuestionFlow] Route inferido para '\(selectedOption.value)' → '\(route)'")
            #endif
        }

        #if DEBUG
        print("🔀 [UnifiedQuestionFlow] Routing: '\(selectedOption.value)' → '\(route)'")
        #endif

        // Cargar preguntas del nuevo flujo (sin eliminar las anteriores)
        loadFlowQuestions(route: route)

        // Actualizar flujo actual
        currentFlow = route

        // ✅ Avanzar al siguiente índice (la siguiente pregunta después de la de routing)
        currentQuestionIndex += 1

        #if DEBUG
        print("📍 [UnifiedQuestionFlow] Routing completado - avanzando a índice \(currentQuestionIndex)")
        if let currentQ = currentQuestion {
            print("   Ahora en: \(currentQ.id)")
        }
        #endif
    }

    /// Inferir route cuando no hay route explícito en la opción
    private func inferRoute(questionId: String, selectedValue: String) -> String {
        // gift_01_knowledge_level routing
        if questionId == "gift_01_knowledge_level" {
            if selectedValue == "low_knowledge" {
                return "flow_A"
            } else if selectedValue == "high_knowledge" {
                return "flow_B"
            }
        }

        // gift_B1_reference_type routing (dentro de conocimiento alto)
        if questionId == "gift_B1_reference_type" {
            switch selectedValue {
            case "by_brands":
                return "flow_C"
            case "by_perfume":
                return "flow_D"
            case "by_aromas":
                return "flow_E"
            case "no_reference":
                return "flow_F"
            default:
                break
            }
        }

        // profile routing (si es necesario en el futuro)
        // ...

        return ""
    }

    /// Carga las preguntas de un flujo específico según el route
    /// @param route: El route seleccionado (ej: "flow_A", "gift_C", etc.)
    private func loadFlowQuestions(route: String) {
        // Convertir route a prefijo de preguntas
        // Soporta dos formatos:
        // - "flow_A" → "profile_A" o "gift_A"
        // - "gift_C" → "gift_C" (ya incluye el prefijo completo)

        let prefix: String

        // Si el route ya incluye "profile_" o "gift_", usarlo directamente
        if route.starts(with: "profile_") || route.starts(with: "gift_") {
            prefix = route
        } else {
            // Caso "flow_X" → extraer la letra y agregar prefijo base
            let flowLetter = route.replacingOccurrences(of: "flow_", with: "")
            let basePrefix = currentQuestions.first?.id.starts(with: "profile_") == true ? "profile_" : "gift_"
            prefix = "\(basePrefix)\(flowLetter)"
        }

        let flowQuestions = allQuestions.filter { $0.id.starts(with: prefix) }
            .sorted { $0.order < $1.order }

        #if DEBUG
        print("🔀 [UnifiedQuestionFlow] Loading flow '\(route)' → Prefix: '\(prefix)'")
        print("   Found \(flowQuestions.count) questions")
        #endif

        // Verificar que no estén ya añadidas
        let currentQuestionIds = Set(currentQuestions.map { $0.id })
        let newQuestions = flowQuestions.filter { !currentQuestionIds.contains($0.id) }

        if newQuestions.isEmpty {
            #if DEBUG
            print("   ⚠️ Questions already loaded")
            #endif
            return
        }

        // Insertar las nuevas preguntas DESPUÉS de la pregunta actual (routing)
        let insertIndex = currentQuestionIndex + 1
        currentQuestions.insert(contentsOf: newQuestions, at: insertIndex)

        #if DEBUG
        print("   ✅ Inserted \(newQuestions.count) new questions at index \(insertIndex)")
        print("   Total questions now: \(currentQuestions.count)")
        #endif
    }

    // MARK: - Data Extraction (delegated to ProfileCalculationEngine)

    private let calculationEngine = ProfileCalculationEngine.shared

    /// Extrae las familias olfativas con sus puntuaciones de las respuestas
    func extractFamilyScores() -> [String: Double] {
        let unifiedQuestions = allQuestions
        return calculationEngine.extractFamilyScores(from: responses, questions: unifiedQuestions)
    }

    /// Extrae metadata unificado de las respuestas
    func extractMetadata() -> UnifiedProfileMetadata {
        let unifiedQuestions = allQuestions
        return calculationEngine.extractMetadata(from: responses, questions: unifiedQuestions)
    }

    /// Extrae el género preferido de las respuestas
    func extractGenderPreference() -> String {
        let unifiedQuestions = allQuestions
        return calculationEngine.extractGenderPreference(from: responses, questions: unifiedQuestions)
    }

    /// Genera el UnifiedProfile completo desde las respuestas
    func generateProfile(name: String, profileType: ProfileType) -> UnifiedProfile {
        let unifiedQuestions = allQuestions
        return calculationEngine.generateProfile(
            name: name,
            profileType: profileType,
            responses: responses,
            questions: unifiedQuestions,
            currentFlow: currentFlow
        )
    }
}

// MARK: - Unified Question Model

/// Modelo unificado de pregunta que abstrae Question y GiftQuestion
struct UnifiedQuestion: Identifiable {
    let id: String
    let text: String
    let subtitle: String?
    let category: String
    let questionType: String  // Para detectar routing
    let options: [UnifiedOption]
    let allowsMultipleSelection: Bool
    let requiresTextInput: Bool
    let textInputPlaceholder: String?
    let minSelection: Int?
    let maxSelection: Int?
    let showDescriptions: Bool
    let order: Int

    // Metadata para lógica condicional (opcional)
    let conditionalRules: [String: String]?
    let isConditional: Bool

    // Autocomplete fields
    let dataSource: String?
    let skipOption: (label: String, value: String)?

    // Computed properties
    var isRoutingQuestion: Bool {
        return questionType == "routing"
    }

    var isAutocompleteNotes: Bool {
        return questionType == "autocomplete_notes" || dataSource == "notes_database"
    }

    var isAutocompleteBrands: Bool {
        return questionType == "autocomplete_brands" || dataSource == "brands_database"
    }

    var isAutocompletePerfumes: Bool {
        return questionType == "autocomplete_perfumes" || dataSource == "perfumes_database"
    }
}

// MARK: - Unified Option Model

/// Modelo unificado de opción que abstrae Option y GiftQuestionOption
struct UnifiedOption: Identifiable {
    let id: String
    let label: String
    let value: String
    let description: String?
    let route: String?  // Para routing dinámico
    let families: [String: Int]  // Puntuaciones de familias
    let metadata: OptionMetadata?  // Metadata completo
}

// MARK: - Unified Response Model

/// Respuesta unificada que captura la selección del usuario
struct UnifiedResponse {
    let questionId: String
    var selectedOptionIds: [String] = []
    var textInput: String?
}

// MARK: - Conversion Extensions

extension Question {
    func toUnified() -> UnifiedQuestion {
        let skipOptionTuple: (label: String, value: String)? = {
            if let skip = skipOption {
                return (label: skip.label, value: skip.value)
            }
            return nil
        }()

        // Determine if this is a gift question or olfactive question
        let isGiftQuestion = flowType != nil || uiConfig != nil

        // For gift questions, use uiConfig and subtitle; for olfactive, use legacy fields
        let allowsMultiple = isGiftQuestion ? (uiConfig?.isMultipleSelection ?? false) : (multiSelect ?? false)
        let requiresText = isGiftQuestion ? (uiConfig?.isTextInput ?? false) : (dataSource != nil)
        let textPlaceholder = isGiftQuestion ? (uiConfig?.placeholder ?? placeholder) : placeholder
        let minSel = isGiftQuestion ? uiConfig?.minSelection : minSelections
        let maxSel = isGiftQuestion ? uiConfig?.maxSelection : maxSelections
        let showDesc = isGiftQuestion ? (uiConfig?.showDescriptions ?? true) : true
        let sub = isGiftQuestion ? subtitle : helperText

        return UnifiedQuestion(
            id: id,
            text: text,
            subtitle: sub,
            category: category,
            questionType: questionType,
            options: options.map { $0.toUnified() },
            allowsMultipleSelection: allowsMultiple,
            requiresTextInput: requiresText,
            textInputPlaceholder: textPlaceholder,
            minSelection: minSel,
            maxSelection: maxSel,
            showDescriptions: showDesc,
            order: order,
            conditionalRules: conditionalRules,
            isConditional: isConditional ?? false,
            dataSource: dataSource,
            skipOption: skipOptionTuple
        )
    }
}

extension Option {
    func toUnified() -> UnifiedOption {
        // If metadata already exists (olfactive questions), use it
        // Otherwise, build it from gift question fields if present
        var finalMetadata = metadata

        if finalMetadata == nil && (personalities != nil || occasions != nil || seasons != nil || intensity != nil || projection != nil) {
            finalMetadata = OptionMetadata(
                occasion: occasions,
                season: seasons,
                personality: personalities,
                intensity: intensity?.first,
                projection: projection?.first
            )
        }

        return UnifiedOption(
            id: id,
            label: label,
            value: value,
            description: description.isEmpty ? nil : description,
            route: route,
            families: families,
            metadata: finalMetadata
        )
    }
}
