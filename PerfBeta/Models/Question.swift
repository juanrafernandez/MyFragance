import Foundation

// MARK: - Question
/// Modelo unificado para preguntas de test olfativo y recomendaciones de regalo
struct Question: Identifiable, Codable, Equatable {
    var id: String
    var key: String?
    var questionType: String
    var order: Int
    var category: String
    var text: String

    // UI & Display
    var subtitle: String?           // También conocido como description/helperText
    var stepType: String?           // Para identificar tipo de evaluación (duration, projection, price, etc.)
    var placeholder: String?        // Placeholder para autocomplete

    // Selection Configuration
    var multiSelect: Bool?          // Indica si permite selección múltiple
    var minSelections: Int?         // Mínimo de selecciones
    var maxSelections: Int?         // Máximo de selecciones
    var weight: Int?                // Peso de la pregunta (0-3) para el algoritmo

    // Autocomplete Configuration
    var dataSource: String?         // Fuente de datos para autocomplete (notes_database, perfume_database)
    var skipOption: SkipOption?     // Opción de saltar pregunta (autocomplete)

    // Gift Question Fields
    var flow: String?               // "main", "flow_A", "flow_B", etc. - identifica el flujo actual
    var flowType: String?           // DEPRECATED - usar 'flow' en su lugar
    var isConditional: Bool?        // Para gift questions condicionales
    var conditionalRules: [String: String]?  // Reglas condicionales para gift
    var uiConfig: UIConfig?         // Configuración de UI avanzada (gift questions)

    // Options
    var options: [Option]

    // Timestamps
    var createdAt: Date?
    var updatedAt: Date?

    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id, key, questionType, order, category
        case text = "question"      // Firebase puede usar "question" o "text"
        case subtitle = "description"  // Firebase puede usar "description"
        case stepType, placeholder
        case multiSelect, minSelections, maxSelections, weight
        case dataSource, skipOption
        case flow, flowType, isConditional, conditionalRules, uiConfig
        case options
        case createdAt, updatedAt
    }

    // MARK: - Custom Decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        key = try container.decodeIfPresent(String.self, forKey: .key)
        questionType = try container.decodeIfPresent(String.self, forKey: .questionType) ?? "single_choice"
        order = try container.decode(Int.self, forKey: .order)
        category = try container.decode(String.self, forKey: .category)

        // text puede venir como "question" o "text" en Firebase
        text = try container.decodeIfPresent(String.self, forKey: .text) ?? "Pregunta sin título"
        subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
        stepType = try container.decodeIfPresent(String.self, forKey: .stepType)
        placeholder = try container.decodeIfPresent(String.self, forKey: .placeholder)

        multiSelect = try container.decodeIfPresent(Bool.self, forKey: .multiSelect)
        minSelections = try container.decodeIfPresent(Int.self, forKey: .minSelections)
        maxSelections = try container.decodeIfPresent(Int.self, forKey: .maxSelections)
        weight = try container.decodeIfPresent(Int.self, forKey: .weight)

        dataSource = try container.decodeIfPresent(String.self, forKey: .dataSource)
        skipOption = try container.decodeIfPresent(SkipOption.self, forKey: .skipOption)

        isConditional = try container.decodeIfPresent(Bool.self, forKey: .isConditional)
        conditionalRules = try container.decodeIfPresent([String: String].self, forKey: .conditionalRules)

        // flow - campo principal
        flow = try container.decodeIfPresent(String.self, forKey: .flow)

        // flowType - mantener por compatibilidad, pero DEPRECATED
        if let explicitFlowType = try container.decodeIfPresent(String.self, forKey: .flowType) {
            flowType = explicitFlowType
            // Si no hay flow pero sí flowType, usar flowType como fallback
            if flow == nil {
                flow = explicitFlowType
            }
        } else if id.starts(with: "gift_") {
            // Inferir flowType desde el ID del documento para gift questions antiguas
            flowType = Self.inferFlowType(from: id)
            if flow == nil {
                flow = flowType
            }
        }

        // uiConfig - crear por defecto si no existe
        if let config = try container.decodeIfPresent(UIConfig.self, forKey: .uiConfig) {
            uiConfig = config
        } else if flowType != nil {
            // Si es gift question sin uiConfig, crear uno por defecto
            uiConfig = UIConfig(
                displayType: "single_choice",
                isMultipleSelection: multiSelect ?? false,
                isTextInput: false,
                minSelection: minSelections,
                maxSelection: maxSelections,
                showImages: false,
                showDescriptions: true,
                searchEnabled: false,
                placeholder: placeholder,
                textInputType: nil
            )
        }

        options = try container.decode([Option].self, forKey: .options)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
    }

    // MARK: - Memberwise Initializer
    init(
        id: String,
        key: String? = nil,
        questionType: String,
        order: Int,
        category: String,
        text: String,
        subtitle: String? = nil,
        stepType: String? = nil,
        placeholder: String? = nil,
        multiSelect: Bool? = nil,
        minSelections: Int? = nil,
        maxSelections: Int? = nil,
        weight: Int? = nil,
        dataSource: String? = nil,
        skipOption: SkipOption? = nil,
        flow: String? = nil,
        flowType: String? = nil,
        isConditional: Bool? = nil,
        conditionalRules: [String: String]? = nil,
        uiConfig: UIConfig? = nil,
        options: [Option],
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.key = key
        self.questionType = questionType
        self.order = order
        self.category = category
        self.text = text
        self.subtitle = subtitle
        self.stepType = stepType
        self.placeholder = placeholder
        self.multiSelect = multiSelect
        self.minSelections = minSelections
        self.maxSelections = maxSelections
        self.weight = weight
        self.dataSource = dataSource
        self.skipOption = skipOption
        self.flow = flow
        self.flowType = flowType
        self.isConditional = isConditional
        self.conditionalRules = conditionalRules
        self.uiConfig = uiConfig
        self.options = options
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Flow Type Inference (for gift questions)
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

    // MARK: - Computed Properties
    /// Helper computed property para acceder al tipo como enum
    var type: QuestionType? {
        QuestionType(rawValue: questionType)
    }

    /// Compatibilidad con GiftQuestion
    var isMainFlow: Bool { flowType == "main" }
    var isFlowA: Bool { flowType == "A" }
    var isFlowB: Bool { flowType?.starts(with: "B") ?? false }
    var isMultipleChoice: Bool { uiConfig?.isMultipleSelection ?? multiSelect ?? false }
    var helperText: String? { subtitle }

    // MARK: - Equatable
    static func == (lhs: Question, rhs: Question) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Option
/// Opción de respuesta para una pregunta
struct Option: Identifiable, Codable, Equatable {
    var id: String
    var label: String
    var value: String
    var description: String
    var image_asset: String

    // Scoring Data (for olfactive test)
    var families: [String: Int]
    var metadata: OptionMetadata?

    // Gift Question Fields
    var nextFlow: String?           // Flow routing para gift questions
    var filters: [String: AnyCodable]?  // Filtros dinámicos para gift questions
    var weights: [String: Double]?  // Pesos para scoring de gift questions
    var personalities: [String]?    // Personalidades para gift questions
    var occasions: [String]?        // Ocasiones para gift questions
    var seasons: [String]?          // Temporadas para gift questions
    var intensity: [String]?        // Intensidades para gift questions
    var projection: [String]?       // Proyecciones para gift questions
    var priceRange: [String]?       // Rangos de precio para gift questions

    // MARK: - Coding Keys
    enum CodingKeys: String, CodingKey {
        case id
        case label
        case text           // Firebase puede usar "text" en lugar de "label"
        case value
        case description
        case image_asset
        case imageAsset = "imageUrl"  // Firebase usa "imageUrl" en gift questions
        case families
        case metadata
        case nextFlow
        case route          // Alias de nextFlow
        case filters, weights
        case personalities, occasions, seasons
        case intensity, projection, priceRange
    }

    // MARK: - Custom Decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)

        // label puede venir como "label" o "text"
        if let labelValue = try container.decodeIfPresent(String.self, forKey: .label) {
            label = labelValue
        } else if let textValue = try container.decodeIfPresent(String.self, forKey: .text) {
            label = textValue
        } else {
            label = try container.decode(String.self, forKey: .value)  // Fallback al value
        }

        value = try container.decode(String.self, forKey: .value)
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""

        // image_asset puede venir como "image_asset" o "imageUrl"
        if let imageAssetValue = try container.decodeIfPresent(String.self, forKey: .image_asset) {
            image_asset = imageAssetValue
        } else if let imageUrlValue = try container.decodeIfPresent(String.self, forKey: .imageAsset) {
            image_asset = imageUrlValue
        } else {
            image_asset = ""
        }

        families = try container.decodeIfPresent([String: Int].self, forKey: .families) ?? [:]
        metadata = try container.decodeIfPresent(OptionMetadata.self, forKey: .metadata)

        // nextFlow puede venir como "nextFlow" o "route"
        if let nextFlowValue = try container.decodeIfPresent(String.self, forKey: .nextFlow) {
            nextFlow = nextFlowValue
        } else {
            nextFlow = try container.decodeIfPresent(String.self, forKey: .route)
        }

        filters = try container.decodeIfPresent([String: AnyCodable].self, forKey: .filters)
        weights = try container.decodeIfPresent([String: Double].self, forKey: .weights)
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
        try container.encode(value, forKey: .value)
        try container.encode(description, forKey: .description)
        try container.encode(image_asset, forKey: .image_asset)
        try container.encode(families, forKey: .families)
        try container.encodeIfPresent(metadata, forKey: .metadata)
        try container.encodeIfPresent(nextFlow, forKey: .nextFlow)
        try container.encodeIfPresent(filters, forKey: .filters)
        try container.encodeIfPresent(weights, forKey: .weights)
        try container.encodeIfPresent(personalities, forKey: .personalities)
        try container.encodeIfPresent(occasions, forKey: .occasions)
        try container.encodeIfPresent(seasons, forKey: .seasons)
        try container.encodeIfPresent(intensity, forKey: .intensity)
        try container.encodeIfPresent(projection, forKey: .projection)
        try container.encodeIfPresent(priceRange, forKey: .priceRange)
    }

    // MARK: - Memberwise Initializer
    init(
        id: String,
        label: String,
        value: String,
        description: String,
        image_asset: String,
        families: [String: Int] = [:],
        metadata: OptionMetadata? = nil,
        nextFlow: String? = nil,
        filters: [String: AnyCodable]? = nil,
        weights: [String: Double]? = nil,
        personalities: [String]? = nil,
        occasions: [String]? = nil,
        seasons: [String]? = nil,
        intensity: [String]? = nil,
        projection: [String]? = nil,
        priceRange: [String]? = nil
    ) {
        self.id = id
        self.label = label
        self.value = value
        self.description = description
        self.image_asset = image_asset
        self.families = families
        self.metadata = metadata
        self.nextFlow = nextFlow
        self.filters = filters
        self.weights = weights
        self.personalities = personalities
        self.occasions = occasions
        self.seasons = seasons
        self.intensity = intensity
        self.projection = projection
        self.priceRange = priceRange
    }

    // MARK: - Computed Properties
    /// Alias para compatibilidad con gift questions
    var route: String? { nextFlow }
    var imageAsset: String? { image_asset.isEmpty ? nil : image_asset }
}

// MARK: - SkipOption
/// Opción de saltar para preguntas autocomplete
struct SkipOption: Codable, Equatable {
    var label: String
    var value: String
}

// MARK: - OptionMetadata
/// Metadata para opciones de test olfativo
struct OptionMetadata: Codable, Equatable {
    // Contexto de uso
    var gender: String?
    var genderType: String?
    var occasion: [String]?
    var season: [String]?
    var personality: [String]?

    // Performance
    var intensity: String?
    var intensityMax: String?
    var duration: String?
    var projection: String?

    // Familias a evitar (negativo)
    var avoidFamilies: [String]?

    // Notas específicas (Flow B - Intermediate)
    var mustContainNotes: [String]?
    var heartNotesBonus: [String]?
    var baseNotesBonus: [String]?

    // Preferencias de estructura (flujo C)
    var phasePreference: String?
    var discoveryMode: String?

    // Codificar solo los campos que tienen valor
    enum CodingKeys: String, CodingKey {
        case gender
        case genderType = "gender_type"
        case occasion
        case season
        case personality
        case intensity
        case intensityMax = "intensity_max"
        case duration
        case projection
        case avoidFamilies = "avoid_families"
        case mustContainNotes = "must_contain_notes"
        case heartNotesBonus = "heartNotes_bonus"
        case baseNotesBonus = "baseNotes_bonus"
        case phasePreference = "phase_preference"
        case discoveryMode = "discovery_mode"
    }
}

// MARK: - UIConfig
/// Configuración de UI para gift questions
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

// MARK: - AnyCodable
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
        String(describing: lhs.value) == String(describing: rhs.value)
    }
}
// MARK: - Gift Flow Types
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
