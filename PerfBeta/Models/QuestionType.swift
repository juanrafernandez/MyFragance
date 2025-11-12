import Foundation

/// Tipos de cuestionarios disponibles en la aplicación
enum QuestionType: String, Codable {
    // Cuestionarios de perfil de usuario
    case perfilOlfativo = "perfil_olfativo"
    case ocasion = "ocasion"
    case personalidad = "personalidad"
    case estiloVida = "estilo_vida"
    case preferenciasMarca = "preferencias_marca"

    // Cuestionarios de evaluación de perfumes
    case evaluacionCompleta = "evaluacion_completa"  // 7 preguntas completas
    case miOpinion = "mi_opinion"                    // 4 preguntas esenciales

    /// Descripción legible del tipo de cuestionario
    var displayName: String {
        switch self {
        case .perfilOlfativo:
            return "Perfil Olfativo"
        case .ocasion:
            return "Ocasión"
        case .personalidad:
            return "Personalidad"
        case .estiloVida:
            return "Estilo de Vida"
        case .preferenciasMarca:
            return "Preferencias de Marca"
        case .evaluacionCompleta:
            return "Evaluación Completa"
        case .miOpinion:
            return "Mi Opinión"
        }
    }
}
