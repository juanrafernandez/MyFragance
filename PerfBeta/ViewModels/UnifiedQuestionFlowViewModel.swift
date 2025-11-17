import Foundation
import SwiftUI
import Combine

/// ViewModel unificado para gestionar cualquier flujo de preguntas
/// Funciona tanto para test personal como para flujo de regalo
@MainActor
final class UnifiedQuestionFlowViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var currentQuestionIndex: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: IdentifiableString?
    @Published var isCompleted: Bool = false

    // MARK: - Private Properties

    private var questions: [UnifiedQuestion] = []
    private var responses: [String: UnifiedResponse] = [:]  // questionId -> response

    // MARK: - Computed Properties

    var currentQuestion: UnifiedQuestion? {
        guard !questions.isEmpty, currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }

    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentQuestionIndex + 1) / Double(questions.count)
    }

    var canGoBack: Bool {
        return currentQuestionIndex > 0
    }

    var isLastQuestion: Bool {
        return currentQuestionIndex == questions.count - 1
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

    func loadQuestions(_ questions: [UnifiedQuestion]) {
        self.questions = questions
        self.currentQuestionIndex = 0
        self.responses = [:]
        self.isCompleted = false
    }

    // MARK: - Navigation

    func nextQuestion() {
        guard canContinue else {
            #if DEBUG
            print("⚠️ [UnifiedQuestionFlow] No se puede continuar - respuesta incompleta")
            #endif
            return
        }

        if isLastQuestion {
            completeFlow()
        } else {
            currentQuestionIndex += 1

            #if DEBUG
            print("➡️ [UnifiedQuestionFlow] Avanzando a pregunta \(currentQuestionIndex + 1)/\(questions.count)")
            #endif
        }
    }

    func previousQuestion() {
        guard canGoBack else { return }
        currentQuestionIndex -= 1

        #if DEBUG
        print("⬅️ [UnifiedQuestionFlow] Retrocediendo a pregunta \(currentQuestionIndex + 1)/\(questions.count)")
        #endif
    }

    // MARK: - Response Handling

    func selectOption(_ optionId: String) {
        guard let question = currentQuestion else { return }

        var response = responses[question.id] ?? UnifiedResponse(questionId: question.id)
        response.selectedOptionIds = [optionId]
        responses[question.id] = response

        #if DEBUG
        print("✅ [UnifiedQuestionFlow] Opción seleccionada: \(optionId)")
        #endif
    }

    func selectMultipleOptions(_ optionIds: [String]) {
        guard let question = currentQuestion else { return }

        var response = responses[question.id] ?? UnifiedResponse(questionId: question.id)
        response.selectedOptionIds = optionIds
        responses[question.id] = response

        #if DEBUG
        print("✅ [UnifiedQuestionFlow] Opciones múltiples: \(optionIds.count) seleccionadas")
        #endif
    }

    func inputText(_ text: String) {
        guard let question = currentQuestion else { return }

        var response = responses[question.id] ?? UnifiedResponse(questionId: question.id)
        response.textInput = text
        responses[question.id] = response

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
    }
}

// MARK: - Unified Question Model

/// Modelo unificado de pregunta que abstrae Question y GiftQuestion
struct UnifiedQuestion: Identifiable {
    let id: String
    let text: String
    let subtitle: String?
    let category: String
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
}

// MARK: - Unified Option Model

/// Modelo unificado de opción que abstrae Option y GiftQuestionOption
struct UnifiedOption: Identifiable {
    let id: String
    let label: String
    let value: String
    let description: String?
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
            description: description.isEmpty ? nil : description
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
        UnifiedOption(
            id: id,
            label: label,
            value: value,
            description: description
        )
    }
}
