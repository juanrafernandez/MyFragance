import Foundation

enum Personality: String, CaseIterable, Identifiable, SelectableOption {
    case adventurous = "adventurous"
    case dynamic = "dynamic"
    case romantic = "romantic"
    case elegant = "elegant"
    case fun = "fun"
    case confident = "confident"
    case mysterious = "mysterious"
    case passionate = "passionate"
    case creative = "creative"
    case relaxed = "relaxed"
    
    var id: Personality { self }
    
    /// Nombre traducido de la personalidad
    var displayName: String {
        NSLocalizedString("personality.\(rawValue).name", comment: "Display name for personality: \(rawValue)")
    }
    
    /// Descripción traducida de la personalidad
    var description: String {
        NSLocalizedString("personality.\(rawValue).description", comment: "Description for personality: \(rawValue)")
    }
    
    var imageName: String {
        switch self {
        case .adventurous:
            return "personality_adventurous"
        case .dynamic:
            return "personality_dynamic"
        case .romantic:
            return "personality_romantic"
        case .elegant:
            return "personality_elegant"
        case .fun:
            return "personality_fun"
        case .confident:
            return "personality_confident"
        case .mysterious:
            return "personality_mysterious"
        case .passionate:
            return "personality_passionate"
        case .creative:
            return "personality_creative"
        case .relaxed:
            return "personality_relaxed"
        }
    }
}
