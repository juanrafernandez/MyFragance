import Foundation

// MARK: - Gift Question
/// Pregunta del flujo de recomendación de perfumes para regalo
struct GiftQuestion: Codable, Identifiable, Equatable {
    let id: String
    let order: Int
    let flowType: String  // "main", "A", "B1", "B2", "B3", "B4"
    let category: String  // "knowledge_level", "brand_selection", etc.
    let questionType: String
    let isConditional: Bool
    let conditionalRules: [String: String]?
    let text: String
    let subtitle: String?
    let options: [GiftQuestionOption]
    let uiConfig: UIConfig

    // MARK: - Equatable
    static func == (lhs: GiftQuestion, rhs: GiftQuestion) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Computed Properties
    var isMainFlow: Bool { flowType == "main" }
    var isFlowA: Bool { flowType == "A" }
    var isFlowB: Bool { flowType.starts(with: "B") }
}

// MARK: - Gift Question Option
struct GiftQuestionOption: Codable, Identifiable, Equatable {
    let id: String
    let label: String
    let description: String?
    let value: String
    let imageAsset: String?

    // Datos para navegación
    let nextFlow: String?

    // Datos para el algoritmo de scoring
    let filters: [String: AnyCodable]?
    let weights: [String: Double]?
    let families: [String: Int]?
    let personalities: [String]?
    let occasions: [String]?
    let seasons: [String]?
    let intensity: [String]?
    let projection: [String]?
    let priceRange: [String]?

    static func == (lhs: GiftQuestionOption, rhs: GiftQuestionOption) -> Bool {
        lhs.id == rhs.id && lhs.value == rhs.value
    }
}

// MARK: - UI Config
struct UIConfig: Codable, Equatable {
    let selectionType: String  // "single", "multiple", "text_input", "brand_search"
    let minSelection: Int?
    let maxSelection: Int?
    let showImages: Bool?
    let showDescriptions: Bool?
    let searchEnabled: Bool?
    let placeholder: String?

    var isSingleSelection: Bool { selectionType == "single" }
    var isMultipleSelection: Bool { selectionType == "multiple" }
    var isTextInput: Bool { selectionType == "text_input" }
    var isSearchEnabled: Bool { selectionType == "brand_search" || searchEnabled == true }
}

// MARK: - AnyCodable Helper
/// Helper para encodear/decodear valores dinámicos en filters
struct AnyCodable: Codable, Equatable {
    let value: Any

    init(_ value: Any) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dict = try? container.decode([String: AnyCodable].self) {
            value = dict.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode AnyCodable"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let string as String:
            try container.encode(string)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let bool as Bool:
            try container.encode(bool)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dict as [String: Any]:
            try container.encode(dict.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Cannot encode AnyCodable"
                )
            )
        }
    }

    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        // Simplificado: comparar strings de descripción
        String(describing: lhs.value) == String(describing: rhs.value)
    }
}

// MARK: - Question Categories
enum GiftQuestionCategory: String {
    // Control de flujo
    case knowledgeLevel = "knowledge_level"
    case perfumeType = "perfume_type"
    case referenceType = "reference_type"

    // Selección simple
    case personalityStyle = "personality_style"
    case ageRange = "age_range"
    case occasion = "occasion"
    case intensity = "intensity"
    case season = "season"
    case lifestyle = "lifestyle"

    // Selección múltiple
    case brandSelection = "brand_selection"
    case aromaTypes = "aroma_types"
    case personalityTraits = "personality_traits"

    // Entrada de texto
    case perfumeReference = "perfume_reference"

    // Estrategia
    case recommendationStrategy = "recommendation_strategy"
    case giftStrategy = "gift_strategy"
    case priority = "priority"
}

// MARK: - Flow Types
enum GiftFlowType: String {
    case main = "main"
    case flowA = "A"           // Conocimiento bajo
    case flowB1 = "B1"         // Por marcas
    case flowB2 = "B2"         // Por perfume conocido
    case flowB3 = "B3"         // Por aromas
    case flowB4 = "B4"         // Sin referencias

    var displayName: String {
        switch self {
        case .main: return "Principal"
        case .flowA: return "Conocimiento Bajo"
        case .flowB1: return "Por Marcas"
        case .flowB2: return "Por Perfume"
        case .flowB3: return "Por Aromas"
        case .flowB4: return "Sin Referencias"
        }
    }
}
