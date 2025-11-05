import Foundation

/// Tipos de pasos disponibles en el onboarding
enum OnboardingStepType: String, CaseIterable {
    case duration = "duration"
    case projection = "projection"
    case price = "price"
    case occasions = "occasions"
    case personalities = "personalities"
    case seasons = "seasons"
    case impressionsAndRating = "impressionsAndRating"

    /// Número de paso interno usado en el código legacy
    var legacyStepNumber: Int {
        switch self {
        case .duration: return 3
        case .projection: return 4
        case .price: return 5
        case .occasions: return 6
        case .personalities: return 7
        case .seasons: return 8
        case .impressionsAndRating: return 9
        }
    }

    /// Título de navegación para cada paso
    var navigationTitle: String {
        switch self {
        case .duration: return "Duración"
        case .projection: return "Proyección"
        case .price: return "Precio"
        case .occasions: return "Ocasión"
        case .personalities: return "Personalidad"
        case .seasons: return "Estación"
        case .impressionsAndRating: return "Impresiones y Valoración"
        }
    }
}

/// Contexto en el que se usa el onboarding
enum OnboardingContext {
    case triedPerfumeOpinion   // Para "Mi Opinión" - 4 preguntas
    case fullEvaluation        // Evaluación completa - 7 preguntas
    case olfactiveProfile      // Para perfil olfativo (futuro)

    /// Pasos a mostrar según el contexto
    var steps: [OnboardingStepType] {
        switch self {
        case .triedPerfumeOpinion:
            // Solo 4 preguntas esenciales para "Mi Opinión"
            return [
                .duration,
                .projection,
                .price,
                .impressionsAndRating
            ]
        case .fullEvaluation:
            // Todas las 7 preguntas
            return [
                .duration,
                .projection,
                .price,
                .occasions,
                .personalities,
                .seasons,
                .impressionsAndRating
            ]
        case .olfactiveProfile:
            // Placeholder para futuro uso en perfil olfativo
            // Se puede configurar con preguntas diferentes
            return [
                .duration,
                .projection,
                .price,
                .impressionsAndRating
            ]
        }
    }
}

/// Configuración para el onboarding reutilizable
struct OnboardingConfiguration {
    let context: OnboardingContext
    let steps: [OnboardingStepType]

    /// Inicializa con un contexto predefinido
    init(context: OnboardingContext) {
        self.context = context
        self.steps = context.steps
    }

    /// Inicializa con pasos personalizados
    init(customSteps: [OnboardingStepType]) {
        self.context = .fullEvaluation  // Default context
        self.steps = customSteps
    }

    /// Número total de pasos
    var totalSteps: Int {
        return steps.count
    }

    /// Verifica si un paso debe mostrarse
    func shouldShow(stepType: OnboardingStepType) -> Bool {
        return steps.contains(stepType)
    }

    /// Obtiene el índice (1-based) de un paso en la secuencia
    func stepIndex(for stepType: OnboardingStepType) -> Int? {
        guard let index = steps.firstIndex(of: stepType) else {
            return nil
        }
        return index + 1  // 1-based index for UI
    }

    /// Obtiene el tipo de paso siguiente
    func nextStep(after currentStep: OnboardingStepType) -> OnboardingStepType? {
        guard let currentIndex = steps.firstIndex(of: currentStep) else {
            return nil
        }
        let nextIndex = currentIndex + 1
        return nextIndex < steps.count ? steps[nextIndex] : nil
    }

    /// Verifica si es el último paso
    func isLastStep(_ stepType: OnboardingStepType) -> Bool {
        return steps.last == stepType
    }
}
