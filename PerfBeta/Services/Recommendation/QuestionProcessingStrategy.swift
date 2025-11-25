import Foundation

// MARK: - Question Processing Strategy
/**
 # Sistema de Estrategias de Procesamiento de Preguntas

 Define cómo cada tipo de pregunta contribuye al cálculo del perfil olfativo.
 El algoritmo es único y flexible, adaptándose según los parámetros de cada pregunta.

 ## Tipos de Estrategia (determinados por `dataSource` o `questionType`)

 ### 1. `standard` (default)
 - Usa `option.families` directamente
 - Multiplica puntos por `question.weight`
 - Extrae metadata de `option.metadata`

 ### 2. `perfume_database`
 - Usuario selecciona perfumes de referencia
 - Analiza cada perfume y extrae sus familias
 - Pondera según `question.weight` relativo al resto de preguntas
 - Múltiples perfumes promedian su contribución

 ### 3. `notes_database`
 - Usuario selecciona notas específicas
 - NO suma a familias (weight siempre = 0 efectivo para familias)
 - Guarda notas en metadata para bonus directo en scoring

 ### 4. `brands_database`
 - Usuario selecciona marcas (1-5)
 - NO suma a familias
 - Guarda marcas como FILTRO OBLIGATORIO en recomendaciones

 ### 5. `inherit_from_reference`
 - Valor especial en `option.families`
 - Copia familias del perfume de referencia seleccionado anteriormente
 - El valor numérico indica el factor de herencia (0.8 = 80%)

 ### 6. `routing`
 - `questionType: "routing"`
 - NO contribuye a familias (weight = 0)
 - Solo determina el siguiente flujo via `option.nextFlow`

 ### 7. `metadata_only`
 - Preguntas con `weight: 0` explícito
 - Solo extraen metadata (género, intensidad, familias a evitar)
 - No contribuyen a family_scores
 */

// MARK: - Processing Strategy Enum
/// Estrategia de procesamiento determinada automáticamente
enum QuestionProcessingStrategy: String, Codable {
    /// Usa families directamente con weight
    case standard

    /// Analiza perfumes de referencia
    case perfumeDatabase = "perfume_database"

    /// Guarda notas para bonus (no suma familias)
    case notesDatabase = "notes_database"

    /// Filtro obligatorio de marcas
    case brandsDatabase = "brands_database"

    /// Solo routing, no contribuye
    case routing

    /// Solo extrae metadata
    case metadataOnly = "metadata_only"

    /// Determina la estrategia basándose en los campos de la pregunta
    static func determine(from question: Question) -> QuestionProcessingStrategy {
        // 1. Routing explícito
        if question.questionType == "routing" {
            return .routing
        }

        // 2. DataSource explícito
        if let dataSource = question.dataSource {
            switch dataSource.lowercased() {
            case "perfume_database", "perfumes":
                return .perfumeDatabase
            case "notes_database", "notes":
                return .notesDatabase
            case "brands_database", "brands":
                return .brandsDatabase
            default:
                break
            }
        }

        // 3. Inferir por questionType si no hay dataSource
        let questionTypeLower = question.questionType.lowercased()
        if questionTypeLower.contains("autocomplete_perfume") {
            return .perfumeDatabase
        }
        if questionTypeLower.contains("autocomplete_note") {
            return .notesDatabase
        }
        if questionTypeLower.contains("autocomplete_brand") {
            return .brandsDatabase
        }

        // 4. Metadata only si weight = 0
        if question.weight == 0 {
            return .metadataOnly
        }

        // 5. Default: standard
        return .standard
    }
}

// MARK: - Special Family Values
/// Valores especiales que pueden aparecer en option.families
enum SpecialFamilyValue: String {
    /// Heredar familias del perfume de referencia
    case inheritFromReference = "inherit_from_reference"

    /// Complementar (no duplicar) el perfume de referencia
    case complementReference = "complement_reference"

    /// Detecta si un diccionario de families contiene valores especiales
    static func detect(in families: [String: Int]) -> SpecialFamilyValue? {
        for key in families.keys {
            if let special = SpecialFamilyValue(rawValue: key) {
                return special
            }
        }
        return nil
    }
}

// MARK: - Question Processing Result
/// Resultado del procesamiento de una pregunta
struct QuestionProcessingResult {
    /// Puntos a sumar por familia
    var familyContributions: [String: Double]

    /// Metadata extraída
    var metadata: ExtractedMetadata

    /// Filtros a aplicar en recomendaciones
    var filters: ProfileFilters

    /// Perfumes de referencia (para inherit)
    var referencePerfumeIds: [String]

    init() {
        self.familyContributions = [:]
        self.metadata = ExtractedMetadata()
        self.filters = ProfileFilters()
        self.referencePerfumeIds = []
    }
}

// MARK: - Extracted Metadata
/// Metadata extraída de las respuestas
struct ExtractedMetadata {
    var gender: String?
    var preferredOccasions: [String] = []
    var preferredSeasons: [String] = []
    var personalityTraits: [String] = []
    var intensityPreference: String?
    var intensityMax: String?
    var durationPreference: String?
    var projectionPreference: String?
    var avoidFamilies: [String] = []
    var preferredNotes: [String] = []
    var mustContainNotes: [String] = []
    var heartNotesBonus: [String] = []
    var baseNotesBonus: [String] = []
    var phasePreference: String?
    var discoveryMode: String?
    var referencePerfumes: [String] = []

    /// Merge con otra metadata
    mutating func merge(with other: ExtractedMetadata) {
        if other.gender != nil { gender = other.gender }
        preferredOccasions.append(contentsOf: other.preferredOccasions)
        preferredSeasons.append(contentsOf: other.preferredSeasons)
        personalityTraits.append(contentsOf: other.personalityTraits)
        if other.intensityPreference != nil { intensityPreference = other.intensityPreference }
        if other.intensityMax != nil { intensityMax = other.intensityMax }
        if other.durationPreference != nil { durationPreference = other.durationPreference }
        if other.projectionPreference != nil { projectionPreference = other.projectionPreference }
        avoidFamilies.append(contentsOf: other.avoidFamilies)
        preferredNotes.append(contentsOf: other.preferredNotes)
        mustContainNotes.append(contentsOf: other.mustContainNotes)
        heartNotesBonus.append(contentsOf: other.heartNotesBonus)
        baseNotesBonus.append(contentsOf: other.baseNotesBonus)
        if other.phasePreference != nil { phasePreference = other.phasePreference }
        if other.discoveryMode != nil { discoveryMode = other.discoveryMode }
        referencePerfumes.append(contentsOf: other.referencePerfumes)
    }
}

// MARK: - Profile Filters
/// Filtros obligatorios extraídos del test para recomendaciones
struct ProfileFilters {
    /// Marcas permitidas (si no está vacío, es filtro obligatorio)
    var allowedBrands: [String] = []

    /// Género requerido
    var requiredGender: String?

    /// Precio máximo
    var maxPrice: String?

    /// Intensidad máxima
    var maxIntensity: String?

    /// Si hay filtros activos
    var hasActiveFilters: Bool {
        !allowedBrands.isEmpty || requiredGender != nil || maxPrice != nil || maxIntensity != nil
    }

    /// Merge con otros filtros
    mutating func merge(with other: ProfileFilters) {
        allowedBrands.append(contentsOf: other.allowedBrands)
        if other.requiredGender != nil { requiredGender = other.requiredGender }
        if other.maxPrice != nil { maxPrice = other.maxPrice }
        if other.maxIntensity != nil { maxIntensity = other.maxIntensity }
    }
}

// MARK: - Perfume Reference Data
/// Datos extraídos de un perfume de referencia
struct PerfumeReferenceData {
    let perfumeId: String
    let perfumeKey: String
    let name: String
    let brand: String
    let family: String
    let subfamilies: [String]
    let intensity: String
    let price: String?
    let gender: String

    /// Convierte a contribuciones de familia con un factor de herencia
    func toFamilyContributions(factor: Double = 1.0, basePoints: Double = 10.0) -> [String: Double] {
        var contributions: [String: Double] = [:]

        // Familia principal: puntos base completos
        contributions[family] = basePoints * factor

        // Subfamilias: puntos proporcionales
        for (index, subfamily) in subfamilies.prefix(3).enumerated() {
            let subfamilyPoints = basePoints * 0.5 * (1.0 - Double(index) * 0.2) // 50%, 40%, 30%
            contributions[subfamily] = subfamilyPoints * factor
        }

        return contributions
    }
}
