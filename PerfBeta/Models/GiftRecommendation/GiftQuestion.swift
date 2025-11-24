import Foundation

// MARK: - Gift Question
/// Pregunta del flujo de recomendación de perfumes para regalo
struct GiftQuestion: Codable, Identifiable, Equatable {
    let id: String
    let order: Int
    let flowType: String  // "main", "A", "B1", "B2", "B3", "B4"
    let category: String  // "knowledge_level", "brand_selection", etc.
    let isConditional: Bool
    let conditionalRules: [String: String]?
    let text: String
    let subtitle: String?
    let options: [GiftQuestionOption]
    let uiConfig: UIConfig

    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case order
        case flowType
        case category
        case isConditional
        case conditionalRules
        case text = "question"  // Firebase usa "question"
        case subtitle = "description"  // Firebase usa "description"
        case options
        case uiConfig
    }

    // MARK: - Equatable
    static func == (lhs: GiftQuestion, rhs: GiftQuestion) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Computed Properties
    var isMainFlow: Bool { flowType == "main" }
    var isFlowA: Bool { flowType == "A" }
    var isFlowB: Bool { flowType.starts(with: "B") }

    // MARK: - Compatibility Properties (para GiftRecommendationViewModel legacy)
    var questionType: String {
        return flowType == "main" ? "routing" : "single_choice"
    }

    var minSelections: Int? { uiConfig.minSelection }
    var maxSelections: Int? { uiConfig.maxSelection }
    var isMultipleChoice: Bool { uiConfig.isMultipleSelection }
    var helperText: String? { subtitle }
    var placeholder: String? { uiConfig.placeholder }
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

    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case label = "text"  // Firebase usa "text"
        case description
        case value
        case imageAsset = "imageUrl"  // Firebase usa "imageUrl"
        case nextFlow
        case filters
        case weights
        case families
        case personalities
        case occasions
        case seasons
        case intensity
        case projection
        case priceRange
    }

    static func == (lhs: GiftQuestionOption, rhs: GiftQuestionOption) -> Bool {
        lhs.id == rhs.id && lhs.value == rhs.value
    }

    // MARK: - Compatibility Properties
    var route: String? { nextFlow }  // Alias para compatibilidad
}

// MARK: - UI Config
struct UIConfig: Codable, Equatable {
    let displayType: String?
    let isMultipleSelection: Bool
    let isTextInput: Bool
    let minSelection: Int?
    let maxSelection: Int?
    let showImages: Bool?
    let showDescriptions: Bool?
    let searchEnabled: Bool?
    let placeholder: String?
    let textInputType: String?

    // MARK: - Computed Properties
    var isSingleSelection: Bool { !isMultipleSelection && !isTextInput }
    var isSearchEnabled: Bool { searchEnabled == true || textInputType == "search" }

    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case displayType
        case isMultipleSelection
        case isTextInput
        case minSelection
        case maxSelection
        case showImages
        case showDescriptions
        case searchEnabled
        case placeholder
        case textInputType
    }

    // MARK: - Custom Decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        displayType = try container.decodeIfPresent(String.self, forKey: .displayType)
        isMultipleSelection = try container.decodeIfPresent(Bool.self, forKey: .isMultipleSelection) ?? false
        isTextInput = try container.decodeIfPresent(Bool.self, forKey: .isTextInput) ?? false
        minSelection = try container.decodeIfPresent(Int.self, forKey: .minSelection)
        maxSelection = try container.decodeIfPresent(Int.self, forKey: .maxSelection)
        showImages = try container.decodeIfPresent(Bool.self, forKey: .showImages)
        showDescriptions = try container.decodeIfPresent(Bool.self, forKey: .showDescriptions)
        searchEnabled = try container.decodeIfPresent(Bool.self, forKey: .searchEnabled)
        placeholder = try container.decodeIfPresent(String.self, forKey: .placeholder)
        textInputType = try container.decodeIfPresent(String.self, forKey: .textInputType)
    }
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

    // Aliases para compatibilidad (gift_C, gift_D, gift_E, gift_F)
    case flowB = "flow_B"      // Alias genérico
    case flowC = "gift_C"      // Por marcas (equivalente a B1)
    case flowD = "gift_D"      // Por perfume (equivalente a B2)
    case flowE = "gift_E"      // Por aromas (equivalente a B3)
    case flowF = "gift_F"      // Sin referencias (equivalente a B4)

    var displayName: String {
        switch self {
        case .main: return "Principal"
        case .flowA: return "Conocimiento Bajo"
        case .flowB: return "Conocimiento Alto"
        case .flowB1, .flowC: return "Por Marcas"
        case .flowB2, .flowD: return "Por Perfume"
        case .flowB3, .flowE: return "Por Aromas"
        case .flowB4, .flowF: return "Sin Referencias"
        }
    }
}
