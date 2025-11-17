import Foundation
import FirebaseFirestore

// Simular decodificación de flowB3_02_intensity

let jsonString = """
{
    "id": "flowB3_02_intensity",
    "order": 2,
    "flowType": "B3",
    "category": "intensity",
    "question": "¿Cómo le gustan los perfumes?",
    "description": "Define la intensidad y proyección preferida",
    "isConditional": true,
    "conditionalRules": {
        "previousQuestion": "flowB3_01_aromas"
    },
    "options": [
        {
            "id": "1",
            "text": "Ligeros y sutiles",
            "value": "light_subtle",
            "filters": {
                "intensity": ["low"],
                "projection": ["low", "moderate"]
            }
        }
    ],
    "uiConfig": {
        "displayType": "single_choice",
        "isMultipleSelection": false,
        "isTextInput": false,
        "showDescriptions": true
    }
}
"""

struct GiftQuestion: Codable {
    let id: String
    let order: Int
    let flowType: String
    let category: String
    let isConditional: Bool
    let conditionalRules: [String: String]?
    let text: String
    let subtitle: String?
    let options: [GiftQuestionOption]
    let uiConfig: UIConfig

    enum CodingKeys: String, CodingKey {
        case id, order, flowType, category, isConditional, conditionalRules
        case text = "question"
        case subtitle = "description"
        case options, uiConfig
    }
}

struct GiftQuestionOption: Codable {
    let id: String
    let label: String
    let value: String
    let filters: [String: AnyCodable]?

    enum CodingKeys: String, CodingKey {
        case id
        case label = "text"
        case value
        case filters
    }
}

struct UIConfig: Codable {
    let displayType: String?
    let isMultipleSelection: Bool
    let isTextInput: Bool
    let showDescriptions: Bool?
}

struct AnyCodable: Codable {
    let value: Any

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map { AnyCodable(value: $0) })
        case let dictValue as [String: Any]:
            try container.encode(dictValue.mapValues { AnyCodable(value: $0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: [], debugDescription: "Unsupported type"))
        }
    }

    init(value: Any) {
        self.value = value
    }
}

// Test
let data = jsonString.data(using: .utf8)!
do {
    let question = try JSONDecoder().decode(GiftQuestion.self, from: data)
    print("✅ Decodificación exitosa:")
    print("  - ID: \(question.id)")
    print("  - Order: \(question.order)")
    print("  - Options: \(question.options.count)")
} catch {
    print("❌ Error de decodificación: \(error)")
}
