import Foundation

enum Personality: String, CaseIterable, Identifiable {
    case energetic = "energetic"
    case adventurous = "adventurous"
    case dynamic = "dynamic"
    case romantic = "romantic"
    case elegant = "elegant"
    case dreamer = "dreamer"
    case young = "young"
    case fun = "fun"
    case spontaneous = "spontaneous"
    case formal = "formal"
    case confident = "confident"
    case sensual = "sensual"
    case mysterious = "mysterious"
    case passionate = "passionate"
    case bold = "bold"
    case creative = "creative"
    case relaxed = "relaxed"
    case natural = "natural"
    case warm = "warm"
    case friendly = "friendly"
    case sweet = "sweet"

    var id: String { rawValue }

    /// Nombre traducido de la personalidad
    var displayName: String {
        NSLocalizedString("personality.\(rawValue).name", comment: "Display name for personality: \(rawValue)")
    }

    /// Descripción traducida de la personalidad
    var description: String {
        NSLocalizedString("personality.\(rawValue).description", comment: "Description for personality: \(rawValue)")
    }
}
