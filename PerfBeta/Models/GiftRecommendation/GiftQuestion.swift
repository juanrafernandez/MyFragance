import Foundation

// MARK: - Gift Question
/// Pregunta del flujo de recomendación de perfumes para regalo
struct GiftQuestion: Codable, Identifiable, Equatable {
    let id: String
    let order: Int
    let flowType: String  // "main", "A", "B1", "B2", "B3", "B4" - inferido del ID si no existe
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

    // MARK: - Custom Decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        order = try container.decode(Int.self, forKey: .order)
        category = try container.decode(String.self, forKey: .category)
        isConditional = try container.decodeIfPresent(Bool.self, forKey: .isConditional) ?? false
        conditionalRules = try container.decodeIfPresent([String: String].self, forKey: .conditionalRules)
        text = try container.decodeIfPresent(String.self, forKey: .text) ?? "Pregunta sin título"
        subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
        options = try container.decode([GiftQuestionOption].self, forKey: .options)

        // uiConfig puede no existir en algunas preguntas - crear uno por defecto
        if let config = try container.decodeIfPresent(UIConfig.self, forKey: .uiConfig) {
            uiConfig = config
        } else {
            // Crear UIConfig por defecto basado en las opciones
            uiConfig = UIConfig(
                displayType: "single_choice",
                isMultipleSelection: false,
                isTextInput: false,
                minSelection: nil,
                maxSelection: nil,
                showImages: false,
                showDescriptions: true,
                searchEnabled: false,
                placeholder: nil,
                textInputType: nil
            )
        }

        // Intentar decodificar flowType, si no existe, inferirlo del ID
        if let explicitFlowType = try container.decodeIfPresent(String.self, forKey: .flowType) {
            flowType = explicitFlowType
        } else {
            // Inferir flowType desde el ID del documento
            // gift_00_gender, gift_01_knowledge_level -> "main"
            // gift_A1_personality -> "A"
            // gift_C1_brands -> "C"
            flowType = Self.inferFlowType(from: id)
        }
    }

    // MARK: - Custom Encoder
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(order, forKey: .order)
        try container.encode(flowType, forKey: .flowType)
        try container.encode(category, forKey: .category)
        try container.encode(isConditional, forKey: .isConditional)
        try container.encodeIfPresent(conditionalRules, forKey: .conditionalRules)
        try container.encode(text, forKey: .text)
        try container.encodeIfPresent(subtitle, forKey: .subtitle)
        try container.encode(options, forKey: .options)
        try container.encode(uiConfig, forKey: .uiConfig)
    }

    // MARK: - Flow Type Inference
    private static func inferFlowType(from id: String) -> String {
        // Formato esperado: gift_XX_name o gift_X_name
        let components = id.split(separator: "_")
        guard components.count >= 2 else { return "main" }

        let flowPart = String(components[1])  // "00", "A1", "C1", etc.

        // Extraer la letra del flow (primera letra no numérica)
        if let firstLetter = flowPart.first(where: { !$0.isNumber }) {
            return String(firstLetter)  // "A", "C", "D", etc.
        }

        // Si es todo números (00, 01), es flujo main
        return "main"
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
        case label
        case text  // Firebase puede usar "text" o "label"
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

    // MARK: - Custom Decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)

        // Intentar decodificar "label" primero, si no existe intentar "text"
        if let labelValue = try container.decodeIfPresent(String.self, forKey: .label) {
            label = labelValue
        } else if let textValue = try container.decodeIfPresent(String.self, forKey: .text) {
            label = textValue
        } else {
            throw DecodingError.keyNotFound(
                CodingKeys.label,
                DecodingError.Context(
                    codingPath: container.codingPath,
                    debugDescription: "Neither 'label' nor 'text' found"
                )
            )
        }

        description = try container.decodeIfPresent(String.self, forKey: .description)
        value = try container.decode(String.self, forKey: .value)
        imageAsset = try container.decodeIfPresent(String.self, forKey: .imageAsset)
        nextFlow = try container.decodeIfPresent(String.self, forKey: .nextFlow)
        filters = try container.decodeIfPresent([String: AnyCodable].self, forKey: .filters)
        weights = try container.decodeIfPresent([String: Double].self, forKey: .weights)
        families = try container.decodeIfPresent([String: Int].self, forKey: .families)
        personalities = try container.decodeIfPresent([String].self, forKey: .personalities)
        occasions = try container.decodeIfPresent([String].self, forKey: .occasions)
        seasons = try container.decodeIfPresent([String].self, forKey: .seasons)
        intensity = try container.decodeIfPresent([String].self, forKey: .intensity)
        projection = try container.decodeIfPresent([String].self, forKey: .projection)
        priceRange = try container.decodeIfPresent([String].self, forKey: .priceRange)
    }

    // MARK: - Custom Encoder
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(label, forKey: .label)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(value, forKey: .value)
        try container.encodeIfPresent(imageAsset, forKey: .imageAsset)
        try container.encodeIfPresent(nextFlow, forKey: .nextFlow)
        try container.encodeIfPresent(filters, forKey: .filters)
        try container.encodeIfPresent(weights, forKey: .weights)
        try container.encodeIfPresent(families, forKey: .families)
        try container.encodeIfPresent(personalities, forKey: .personalities)
        try container.encodeIfPresent(occasions, forKey: .occasions)
        try container.encodeIfPresent(seasons, forKey: .seasons)
        try container.encodeIfPresent(intensity, forKey: .intensity)
        try container.encodeIfPresent(projection, forKey: .projection)
        try container.encodeIfPresent(priceRange, forKey: .priceRange)
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

    // MARK: - Memberwise Initializer
    init(
        displayType: String?,
        isMultipleSelection: Bool,
        isTextInput: Bool,
        minSelection: Int?,
        maxSelection: Int?,
        showImages: Bool?,
        showDescriptions: Bool?,
        searchEnabled: Bool?,
        placeholder: String?,
        textInputType: String?
    ) {
        self.displayType = displayType
        self.isMultipleSelection = isMultipleSelection
        self.isTextInput = isTextInput
        self.minSelection = minSelection
        self.maxSelection = maxSelection
        self.showImages = showImages
        self.showDescriptions = showDescriptions
        self.searchEnabled = searchEnabled
        self.placeholder = placeholder
        self.textInputType = textInputType
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
