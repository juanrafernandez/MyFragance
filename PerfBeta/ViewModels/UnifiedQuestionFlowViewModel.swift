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
        return currentQuestionIndex > 0
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
        guard let response = responses[question.id] else { return false }

        // Validar según el tipo de pregunta
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
            handleRouting(for: question)
        }

        if isLastQuestion {
            completeFlow()
        } else {
            currentQuestionIndex += 1

            #if DEBUG
            print("➡️ [UnifiedQuestionFlow] Avanzando a pregunta \(currentQuestionIndex + 1)/\(currentQuestions.count)")
            if let nextQ = currentQuestion {
                print("   Siguiente: \(nextQ.id)")
            }
            #endif
        }
    }

    func previousQuestion() {
        guard canGoBack else { return }
        currentQuestionIndex -= 1

        #if DEBUG
        print("⬅️ [UnifiedQuestionFlow] Retrocediendo a pregunta \(currentQuestionIndex + 1)/\(currentQuestions.count)")
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

        // Verificar si la opción tiene un route
        guard let route = selectedOption.route, !route.isEmpty else {
            #if DEBUG
            print("ℹ️ [UnifiedQuestionFlow] Opción '\(selectedOption.value)' sin route - continuar secuencialmente")
            #endif
            return
        }

        #if DEBUG
        print("🔀 [UnifiedQuestionFlow] Routing: '\(selectedOption.value)' → '\(route)'")
        #endif

        // Limpiar preguntas de flujo anterior
        removeFlowQuestions()

        // Cargar preguntas del nuevo flujo
        loadFlowQuestions(route: route)

        // Actualizar flujo actual
        currentFlow = route
    }

    /// Elimina las preguntas de flujos específicos, dejando solo las principales (00, 01)
    private func removeFlowQuestions() {
        let previousCount = currentQuestions.count

        // Determinar el prefijo (profile_ o gift_)
        let prefix = currentQuestions.first?.id.starts(with: "profile_") == true ? "profile_" : "gift_"

        currentQuestions = currentQuestions.filter { question in
            question.id.starts(with: "\(prefix)00") ||
            question.id.starts(with: "\(prefix)01")
        }

        #if DEBUG
        let removedCount = previousCount - currentQuestions.count
        if removedCount > 0 {
            print("🧹 [UnifiedQuestionFlow] Removed \(removedCount) flow questions")
        }
        #endif
    }

    /// Carga las preguntas de un flujo específico según el route
    /// @param route: El route seleccionado (ej: "flow_A", "gift_C", etc.)
    private func loadFlowQuestions(route: String) {
        // Convertir route a prefijo de preguntas
        // Ejemplos:
        // - "flow_A" → "profile_A" o "gift_A"
        // - "gift_C" → "gift_C"
        let flowLetter = route.replacingOccurrences(of: "flow_", with: "")

        // Determinar el prefijo base (profile_ o gift_)
        let basePrefix = currentQuestions.first?.id.starts(with: "profile_") == true ? "profile_" : "gift_"

        let prefix = "\(basePrefix)\(flowLetter)"

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

        // Añadir nuevas preguntas
        currentQuestions.append(contentsOf: newQuestions)

        #if DEBUG
        print("   ✅ Added \(newQuestions.count) new questions")
        print("   Total questions now: \(currentQuestions.count)")
        #endif
    }

    // MARK: - Data Extraction

    /// Extrae las familias olfativas con sus puntuaciones de las respuestas
    func extractFamilyScores() -> [String: Double] {
        var familyScores: [String: Double] = [:]

        for (questionId, response) in responses {
            // Buscar la pregunta en allQuestions
            guard let question = allQuestions.first(where: { $0.id == questionId }) else { continue }

            // Para cada opción seleccionada
            for optionId in response.selectedOptionIds {
                guard let option = question.options.first(where: { $0.id == optionId }) else { continue }

                // Sumar las puntuaciones de families
                for (family, score) in option.families {
                    familyScores[family, default: 0] += Double(score)
                }
            }
        }

        #if DEBUG
        print("📊 [UnifiedQuestionFlow] Extracted family scores:")
        for (family, score) in familyScores.sorted(by: { $0.value > $1.value }) {
            print("   \(family): \(score)")
        }
        #endif

        return familyScores
    }

    /// Extrae metadata unificado de las respuestas
    func extractMetadata() -> UnifiedProfileMetadata {
        var metadata = UnifiedProfileMetadata()

        var allPersonalities: [String] = []
        var allOccasions: [String] = []
        var allSeasons: [String] = []
        var allAvoidFamilies: [String] = []
        var allPreferredNotes: [String] = []
        var allMustContainNotes: [String] = []
        var allHeartNotesBonus: [String] = []
        var allBaseNotesBonus: [String] = []

        // Variables para valores únicos (último gana)
        var lastIntensity: String?
        var lastIntensityMax: String?
        var lastDuration: String?
        var lastProjection: String?
        var lastDiscoveryMode: String?
        var lastStructurePreference: String?
        var lastPhasePreference: String?
        var lastConcentration: String?

        for (questionId, response) in responses {
            guard let question = allQuestions.first(where: { $0.id == questionId }) else { continue }

            for optionId in response.selectedOptionIds {
                guard let option = question.options.first(where: { $0.id == optionId }) else { continue }
                guard let optionMetadata = option.metadata else { continue }

                // Acumular listas
                if let personalities = optionMetadata.personality {
                    allPersonalities.append(contentsOf: personalities)
                }
                if let occasions = optionMetadata.occasion {
                    allOccasions.append(contentsOf: occasions)
                }
                if let seasons = optionMetadata.season {
                    allSeasons.append(contentsOf: seasons)
                }
                if let avoidFamilies = optionMetadata.avoidFamilies {
                    allAvoidFamilies.append(contentsOf: avoidFamilies)
                }
                if let mustContain = optionMetadata.mustContainNotes {
                    allMustContainNotes.append(contentsOf: mustContain)
                }
                if let heartBonus = optionMetadata.heartNotesBonus {
                    allHeartNotesBonus.append(contentsOf: heartBonus)
                }
                if let baseBonus = optionMetadata.baseNotesBonus {
                    allBaseNotesBonus.append(contentsOf: baseBonus)
                }

                // Últimos valores ganan
                if let intensity = optionMetadata.intensity {
                    lastIntensity = intensity
                }
                if let intensityMax = optionMetadata.intensityMax {
                    lastIntensityMax = intensityMax
                }
                if let duration = optionMetadata.duration {
                    lastDuration = duration
                }
                if let projection = optionMetadata.projection {
                    lastProjection = projection
                }
                if let discoveryMode = optionMetadata.discoveryMode {
                    lastDiscoveryMode = discoveryMode
                }
                if let structure = optionMetadata.phasePreference {
                    lastStructurePreference = structure
                }
                if let phase = optionMetadata.phasePreference {
                    lastPhasePreference = phase
                }
            }
        }

        // Asignar a metadata (eliminando duplicados en arrays)
        metadata.personalityTraits = Array(Set(allPersonalities))
        metadata.preferredOccasions = Array(Set(allOccasions))
        metadata.preferredSeasons = Array(Set(allSeasons))
        metadata.avoidFamilies = allAvoidFamilies.isEmpty ? nil : Array(Set(allAvoidFamilies))
        metadata.mustContainNotes = allMustContainNotes.isEmpty ? nil : Array(Set(allMustContainNotes))
        metadata.heartNotesBonus = allHeartNotesBonus.isEmpty ? nil : Array(Set(allHeartNotesBonus))
        metadata.baseNotesBonus = allBaseNotesBonus.isEmpty ? nil : Array(Set(allBaseNotesBonus))

        metadata.intensityPreference = lastIntensity
        metadata.intensityMax = lastIntensityMax
        metadata.durationPreference = lastDuration
        metadata.projectionPreference = lastProjection
        metadata.discoveryMode = lastDiscoveryMode
        metadata.structurePreference = lastStructurePreference
        metadata.phasePreference = lastPhasePreference

        #if DEBUG
        print("🏷️ [UnifiedQuestionFlow] Extracted metadata:")
        if let personalities = metadata.personalityTraits, !personalities.isEmpty {
            print("   Personalities: \(personalities.joined(separator: ", "))")
        }
        if let occasions = metadata.preferredOccasions, !occasions.isEmpty {
            print("   Occasions: \(occasions.joined(separator: ", "))")
        }
        if let seasons = metadata.preferredSeasons, !seasons.isEmpty {
            print("   Seasons: \(seasons.joined(separator: ", "))")
        }
        if let intensity = metadata.intensityPreference {
            print("   Intensity: \(intensity)")
        }
        #endif

        return metadata
    }

    /// Extrae el género preferido de las respuestas
    func extractGenderPreference() -> String {
        // Buscar respuestas que contengan metadata con gender_type
        for (questionId, response) in responses {
            guard let question = allQuestions.first(where: { $0.id == questionId }) else { continue }

            for optionId in response.selectedOptionIds {
                guard let option = question.options.first(where: { $0.id == optionId }) else { continue }
                guard let optionMetadata = option.metadata else { continue }

                if let genderType = optionMetadata.genderType {
                    // Mapear gender_type a valores estándar
                    switch genderType {
                    case "masculine": return "male"
                    case "feminine": return "female"
                    case "unisex": return "unisex"
                    case "all": return "any"
                    default: return genderType
                    }
                }
            }
        }

        return "unisex"  // Default
    }

    /// Genera el UnifiedProfile completo desde las respuestas
    func generateProfile(name: String, profileType: ProfileType) -> UnifiedProfile {
        let familyScores = extractFamilyScores()
        let metadata = extractMetadata()
        let genderPreference = extractGenderPreference()

        // Determinar familia principal (mayor puntuación)
        let primaryFamily = familyScores.max(by: { $0.value < $1.value })?.key ?? "unknown"

        // Subfamilias (top 3 excluyendo la principal)
        let subfamilies = familyScores
            .filter { $0.key != primaryFamily }
            .sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }

        // Normalizar scores a 0-100
        var normalizedScores = familyScores
        if let maxScore = familyScores.values.max(), maxScore > 0 {
            let factor = 100.0 / maxScore
            normalizedScores = familyScores.mapValues { $0 * factor }
        }

        // Calcular confianza basada en completitud de respuestas
        let answerCompleteness = Double(responses.count) / Double(max(allQuestions.count, 1))
        let confidenceScore = min(answerCompleteness * 1.2, 1.0)

        let profile = UnifiedProfile(
            name: name,
            profileType: profileType,
            experienceLevel: determineExperienceLevel(),
            primaryFamily: primaryFamily,
            subfamilies: Array(subfamilies),
            familyScores: normalizedScores,
            genderPreference: genderPreference,
            metadata: metadata,
            confidenceScore: confidenceScore,
            answerCompleteness: answerCompleteness,
            orderIndex: 0
        )

        #if DEBUG
        print("✅ [UnifiedQuestionFlow] Generated UnifiedProfile:")
        print("   Name: \(profile.name)")
        print("   Type: \(profile.profileType.rawValue)")
        print("   Primary Family: \(profile.primaryFamily)")
        print("   Subfamilies: \(profile.subfamilies.joined(separator: ", "))")
        print("   Gender: \(profile.genderPreference)")
        print("   Confidence: \(String(format: "%.2f", profile.confidenceScore))")
        #endif

        return profile
    }

    /// Determina el nivel de experiencia basado en el flujo actual
    private func determineExperienceLevel() -> ExperienceLevel {
        guard let flow = currentFlow else { return .beginner }

        if flow.contains("_A") || flow == "flow_A" {
            return .beginner
        } else if flow.contains("_B") || flow == "flow_B" {
            return .intermediate
        } else if flow.contains("_C") || flow == "flow_C" {
            return .expert
        }

        return .beginner
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

    // Computed properties
    var isRoutingQuestion: Bool {
        return questionType == "routing"
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
        UnifiedQuestion(
            id: id,
            text: text,
            subtitle: helperText,
            category: category,
            questionType: questionType,
            options: options.map { $0.toUnified() },
            allowsMultipleSelection: multiSelect ?? false,
            requiresTextInput: dataSource != nil,
            textInputPlaceholder: placeholder,
            minSelection: minSelections,
            maxSelection: maxSelections,
            showDescriptions: true,
            order: order,
            conditionalRules: nil,
            isConditional: false
        )
    }
}

extension Option {
    func toUnified() -> UnifiedOption {
        UnifiedOption(
            id: id,
            label: label,
            value: value,
            description: description.isEmpty ? nil : description,
            route: route,
            families: families,
            metadata: metadata
        )
    }
}

extension GiftQuestion {
    func toUnified() -> UnifiedQuestion {
        UnifiedQuestion(
            id: id,
            text: text,
            subtitle: subtitle,
            category: category,
            questionType: flowType == "main" ? "routing" : "single_choice",  // Inferir tipo
            options: options.map { $0.toUnified() },
            allowsMultipleSelection: uiConfig.isMultipleSelection,
            requiresTextInput: uiConfig.isTextInput,
            textInputPlaceholder: uiConfig.placeholder,
            minSelection: uiConfig.minSelection,
            maxSelection: uiConfig.maxSelection,
            showDescriptions: uiConfig.showDescriptions ?? true,
            order: order,
            conditionalRules: conditionalRules,
            isConditional: isConditional
        )
    }
}

extension GiftQuestionOption {
    func toUnified() -> UnifiedOption {
        // Convertir GiftQuestionOption metadata a OptionMetadata estándar
        var optionMetadata: OptionMetadata? = nil

        if personalities != nil || occasions != nil || seasons != nil || intensity != nil || projection != nil {
            optionMetadata = OptionMetadata(
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
            description: description,
            route: nextFlow,  // GiftQuestion usa 'nextFlow' para routing
            families: families ?? [:],
            metadata: optionMetadata
        )
    }
}
