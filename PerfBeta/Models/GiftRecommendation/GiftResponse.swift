import Foundation

// MARK: - Gift Response
/// Respuesta a una pregunta del flujo de regalo
struct GiftResponse: Codable, Equatable {
    let questionId: String
    let category: String
    let selectedOptions: [String]  // IDs de opciones seleccionadas
    let textInput: String?         // Para búsquedas de texto
    let timestamp: Date

    init(questionId: String, category: String, selectedOptions: [String], textInput: String? = nil) {
        self.questionId = questionId
        self.category = category
        self.selectedOptions = selectedOptions
        self.textInput = textInput
        self.timestamp = Date()
    }

    // Convenience para single selection
    var selectedOption: String? {
        selectedOptions.first
    }
}

// MARK: - Gift Responses Collection
/// Colección de todas las respuestas del flujo
struct GiftResponsesCollection: Codable {
    var responses: [String: GiftResponse]  // [questionId: response]
    var flowType: String?
    var knowledgeLevel: String?
    var perfumeType: String?

    init() {
        self.responses = [:]
        self.flowType = nil
        self.knowledgeLevel = nil
        self.perfumeType = nil
    }

    // MARK: - Convenience Methods

    mutating func addResponse(_ response: GiftResponse) {
        responses[response.questionId] = response

        // Actualizar metadata según la respuesta
        switch response.category {
        case "knowledge_level":
            knowledgeLevel = response.selectedOption
        case "perfume_type":
            perfumeType = response.selectedOption
        case "reference_type":
            // Determinar flowType basado en la respuesta
            if let option = response.selectedOption {
                switch option {
                case "by_brand": flowType = "B1"
                case "by_perfume": flowType = "B2"
                case "by_aroma": flowType = "B3"
                case "no_reference": flowType = "B4"
                default: break
                }
            }
        default:
            break
        }
    }

    func getResponse(for questionId: String) -> GiftResponse? {
        responses[questionId]
    }

    func getResponse(forCategory category: String) -> GiftResponse? {
        responses.values.first { $0.category == category }
    }

    func getValue(for category: String) -> String? {
        getResponse(forCategory: category)?.selectedOption
    }

    func getValues(for category: String) -> [String]? {
        getResponse(forCategory: category)?.selectedOptions
    }

    func getTextInput(for category: String) -> String? {
        getResponse(forCategory: category)?.textInput
    }

    // Computed properties para acceso rápido
    var selectedBrands: [String]? {
        getValues(for: "brand_selection")
    }

    var referencePerfumeSearch: String? {
        getTextInput(for: "perfume_reference")
    }

    var selectedAromas: [String]? {
        getValues(for: "aroma_types")
    }

    var personalityStyle: String? {
        getValue(for: "personality_style")
    }

    var ageRange: String? {
        getValue(for: "age_range")
    }

    var occasion: String? {
        getValue(for: "occasion")
    }

    var intensityPreference: String? {
        getValue(for: "intensity")
    }

    var seasonPreference: String? {
        getValue(for: "season")
    }

    var recommendationStrategy: String? {
        getValue(for: "recommendation_strategy")
    }

    var priority: String? {
        getValue(for: "priority")
    }
}
