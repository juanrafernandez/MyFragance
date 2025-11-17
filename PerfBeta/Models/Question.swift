import Foundation

struct Question: Identifiable, Codable {
    var id: String
    var key: String
    var questionType: String
    var order: Int
    var category: String
    var text: String
    var stepType: String?        // Para identificar tipo de evaluación (duration, projection, price, etc.)
    var multiSelect: Bool?       // Indica si permite selección múltiple
    var weight: Int?             // NEW: Peso de la pregunta (0-3) para el algoritmo
    var helperText: String?      // NEW: Texto de ayuda para autocomplete
    var placeholder: String?     // NEW: Placeholder para autocomplete
    var dataSource: String?      // NEW: Fuente de datos para autocomplete (notes_database, perfume_database)
    var maxSelections: Int?      // NEW: Máximo de selecciones para autocomplete
    var minSelections: Int?      // NEW: Mínimo de selecciones para autocomplete
    var skipOption: SkipOption?  // NEW: Opción de saltar pregunta (autocomplete)
    var options: [Option]
    var createdAt: Date?
    var updatedAt: Date?

    /// Helper computed property para acceder al tipo como enum
    var type: QuestionType? {
        QuestionType(rawValue: questionType)
    }

    init(
        id: String,
        key: String,
        questionType: String,
        order: Int,
        category: String,
        text: String,
        stepType: String? = nil,
        multiSelect: Bool? = nil,
        weight: Int? = nil,
        helperText: String? = nil,
        placeholder: String? = nil,
        dataSource: String? = nil,
        maxSelections: Int? = nil,
        minSelections: Int? = nil,
        skipOption: SkipOption? = nil,
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
        self.stepType = stepType
        self.multiSelect = multiSelect
        self.weight = weight
        self.helperText = helperText
        self.placeholder = placeholder
        self.dataSource = dataSource
        self.maxSelections = maxSelections
        self.minSelections = minSelections
        self.skipOption = skipOption
        self.options = options
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// NEW: Opción de saltar para preguntas autocomplete
struct SkipOption: Codable, Equatable {
    var label: String
    var value: String
}

struct Option: Codable, Equatable {
    var id: String
    var label: String
    var value: String
    var description: String
    var image_asset: String
    var families: [String: Int]
    var metadata: OptionMetadata?  // NEW: Metadata adicional para contexto
    var route: String?  // NEW: Flow routing (e.g., "flow_A", "flow_B", "flow_C")

    init(
        id: String,
        label: String,
        value: String,
        description: String,
        image_asset: String,
        families: [String: Int],
        metadata: OptionMetadata? = nil,
        route: String? = nil
    ) {
        self.id = id
        self.label = label
        self.value = value
        self.description = description
        self.image_asset = image_asset
        self.families = families
        self.metadata = metadata
        self.route = route
    }
}

// NEW: Metadata para opciones
struct OptionMetadata: Codable, Equatable {
    // Contexto de uso
    var gender: String?
    var occasion: [String]?
    var season: [String]?
    var personality: [String]?

    // Performance
    var intensity: String?
    var duration: String?
    var projection: String?

    // Familias a evitar (negativo)
    var avoidFamilies: [String]?

    // Preferencias de estructura (flujo C)
    var phasePreference: String?
    var discoveryMode: String?

    // Codificar solo los campos que tienen valor
    enum CodingKeys: String, CodingKey {
        case gender
        case occasion
        case season
        case personality
        case intensity
        case duration
        case projection
        case avoidFamilies = "avoid_families"
        case phasePreference = "phase_preference"
        case discoveryMode = "discovery_mode"
    }
}
