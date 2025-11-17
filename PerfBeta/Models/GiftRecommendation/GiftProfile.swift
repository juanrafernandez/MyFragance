import Foundation
import FirebaseFirestore

// MARK: - Gift Profile
/// Perfil de regalo guardado con recomendaciones
struct GiftProfile: Codable, Identifiable, Equatable {
    var id: String
    var createdAt: Date
    var updatedAt: Date

    // Información del receptor
    var recipientInfo: RecipientInfo

    // Respuestas guardadas
    var responses: GiftResponsesCollection

    // Datos procesados
    var preferredFamilies: [String]
    var preferredPersonalities: [String]
    var preferredOccasions: [String]
    var priceRange: [String]
    var selectedBrands: [String]?
    var referencePerfumeKey: String?
    var referencePerfumeName: String?

    // Resultados y recomendaciones
    var recommendations: [GiftRecommendation]

    // Metadata
    var metadata: ProfileMetadata

    // UI/UX
    var orderIndex: Int

    // MARK: - Initializer
    init(
        id: String = UUID().uuidString,
        nickname: String,
        knowledgeLevel: String,
        responses: GiftResponsesCollection,
        recommendations: [GiftRecommendation] = [],
        orderIndex: Int = 0
    ) {
        self.id = id
        self.createdAt = Date()
        self.updatedAt = Date()
        self.recipientInfo = RecipientInfo(
            nickname: nickname,
            knowledgeLevel: knowledgeLevel
        )
        self.responses = responses
        self.preferredFamilies = []
        self.preferredPersonalities = []
        self.preferredOccasions = []
        self.priceRange = []
        self.selectedBrands = responses.selectedBrands
        self.referencePerfumeKey = nil
        self.referencePerfumeName = nil
        self.recommendations = recommendations
        self.metadata = ProfileMetadata()
        self.orderIndex = orderIndex
    }

    // MARK: - Equatable
    static func == (lhs: GiftProfile, rhs: GiftProfile) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Computed Properties
    var displayName: String {
        recipientInfo.nickname
    }

    var flowType: String {
        responses.flowType ?? "unknown"
    }

    var flowTypeEnum: GiftFlowType? {
        guard let flow = responses.flowType else { return nil }
        return GiftFlowType(rawValue: flow)
    }

    var summary: String {
        guard let flowType = flowTypeEnum else {
            return "Perfil sin completar"
        }

        switch flowType {
        case .main:
            return "Perfil en proceso"
        case .flowA:
            return "Perfil general - \(responses.perfumeType ?? "perfume")"
        case .flowB1:
            if let brands = selectedBrands, !brands.isEmpty {
                return "Marcas: \(brands.prefix(2).joined(separator: ", "))"
            }
            return "Por marcas favoritas"
        case .flowB2:
            if let perfumeName = referencePerfumeName {
                return "Similar a \(perfumeName)"
            }
            return "Similar a perfume conocido"
        case .flowB3:
            if !preferredFamilies.isEmpty {
                return "Aromas: \(preferredFamilies.prefix(2).joined(separator: ", "))"
            }
            return "Por tipo de aromas"
        case .flowB4:
            return "Estilo de vida"
        }
    }

    var hasRecommendations: Bool {
        !recommendations.isEmpty
    }

    var topRecommendations: [GiftRecommendation] {
        Array(recommendations.prefix(3))
    }
}

// MARK: - Recipient Info
struct RecipientInfo: Codable, Equatable {
    var nickname: String
    let knowledgeLevel: String  // "low" o "high"
    var relationship: String?

    var isLowKnowledge: Bool { knowledgeLevel == "low_knowledge" }
    var isHighKnowledge: Bool { knowledgeLevel == "high_knowledge" }
}

// MARK: - Profile Metadata
struct ProfileMetadata: Codable, Equatable {
    var lastUsed: Date
    var timesUsed: Int
    var purchasedPerfumes: [String]  // Keys de perfumes marcados como comprados
    var feedback: String?

    init() {
        self.lastUsed = Date()
        self.timesUsed = 1
        self.purchasedPerfumes = []
        self.feedback = nil
    }

    mutating func incrementUsage() {
        timesUsed += 1
        lastUsed = Date()
    }

    mutating func markAsPurchased(_ perfumeKey: String) {
        if !purchasedPerfumes.contains(perfumeKey) {
            purchasedPerfumes.append(perfumeKey)
        }
    }
}

// MARK: - Gift Recommendation
/// Resultado de recomendación con score y explicación
struct GiftRecommendation: Codable, Identifiable, Equatable {
    let id: String
    let perfumeKey: String
    let score: Double
    let reason: String
    let matchFactors: [MatchFactor]
    let confidence: String  // "high", "medium", "low"

    init(
        perfumeKey: String,
        score: Double,
        reason: String,
        matchFactors: [MatchFactor] = [],
        confidence: String = "medium"
    ) {
        self.id = UUID().uuidString
        self.perfumeKey = perfumeKey
        self.score = score
        self.reason = reason
        self.matchFactors = matchFactors
        self.confidence = confidence
    }

    static func == (lhs: GiftRecommendation, rhs: GiftRecommendation) -> Bool {
        lhs.perfumeKey == rhs.perfumeKey && lhs.score == rhs.score
    }

    var confidenceLevel: ConfidenceLevel {
        ConfidenceLevel(rawValue: confidence) ?? .medium
    }
}

// MARK: - Match Factor
struct MatchFactor: Codable, Equatable {
    let factor: String
    let description: String
    let weight: Double

    static func == (lhs: MatchFactor, rhs: MatchFactor) -> Bool {
        lhs.factor == rhs.factor
    }
}

// MARK: - Confidence Level
enum ConfidenceLevel: String, Codable {
    case high = "high"
    case medium = "medium"
    case low = "low"

    var displayName: String {
        switch self {
        case .high: return "Alta confianza"
        case .medium: return "Confianza media"
        case .low: return "Baja confianza"
        }
    }

    var icon: String {
        switch self {
        case .high: return "checkmark.seal.fill"
        case .medium: return "checkmark.circle.fill"
        case .low: return "questionmark.circle.fill"
        }
    }
}

// MARK: - Firestore Coding
extension GiftProfile {
    /// Convertir a diccionario para Firestore
    func toFirestore() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt),
            "recipientInfo": [
                "nickname": recipientInfo.nickname,
                "knowledgeLevel": recipientInfo.knowledgeLevel,
                "relationship": recipientInfo.relationship as Any
            ],
            "preferredFamilies": preferredFamilies,
            "preferredPersonalities": preferredPersonalities,
            "preferredOccasions": preferredOccasions,
            "priceRange": priceRange,
            "orderIndex": orderIndex,
            "metadata": [
                "lastUsed": Timestamp(date: metadata.lastUsed),
                "timesUsed": metadata.timesUsed,
                "purchasedPerfumes": metadata.purchasedPerfumes,
                "feedback": metadata.feedback as Any
            ]
        ]

        if let brands = selectedBrands {
            dict["selectedBrands"] = brands
        }

        if let refKey = referencePerfumeKey {
            dict["referencePerfumeKey"] = refKey
        }

        if let refName = referencePerfumeName {
            dict["referencePerfumeName"] = refName
        }

        // Guardar responses como JSON
        if let responsesData = try? JSONEncoder().encode(responses),
           let responsesDict = try? JSONSerialization.jsonObject(with: responsesData) as? [String: Any] {
            dict["responses"] = responsesDict
        }

        // Guardar recommendations
        let recsData = recommendations.map { rec -> [String: Any] in
            [
                "id": rec.id,
                "perfumeKey": rec.perfumeKey,
                "score": rec.score,
                "reason": rec.reason,
                "confidence": rec.confidence,
                "matchFactors": rec.matchFactors.map { factor in
                    [
                        "factor": factor.factor,
                        "description": factor.description,
                        "weight": factor.weight
                    ]
                }
            ]
        }
        dict["recommendations"] = recsData

        return dict
    }

    /// Crear desde documento de Firestore
    static func fromFirestore(_ document: [String: Any]) -> GiftProfile? {
        guard let id = document["id"] as? String,
              let createdAtTimestamp = document["createdAt"] as? Timestamp,
              let updatedAtTimestamp = document["updatedAt"] as? Timestamp,
              let recipientInfoDict = document["recipientInfo"] as? [String: Any],
              let nickname = recipientInfoDict["nickname"] as? String,
              let knowledgeLevel = recipientInfoDict["knowledgeLevel"] as? String
        else {
            return nil
        }

        // Decodificar responses
        var responses = GiftResponsesCollection()
        if let responsesDict = document["responses"] as? [String: Any],
           let responsesData = try? JSONSerialization.data(withJSONObject: responsesDict),
           let decodedResponses = try? JSONDecoder().decode(GiftResponsesCollection.self, from: responsesData) {
            responses = decodedResponses
        }

        var profile = GiftProfile(
            id: id,
            nickname: nickname,
            knowledgeLevel: knowledgeLevel,
            responses: responses
        )

        profile.createdAt = createdAtTimestamp.dateValue()
        profile.updatedAt = updatedAtTimestamp.dateValue()
        profile.recipientInfo.relationship = recipientInfoDict["relationship"] as? String

        profile.preferredFamilies = document["preferredFamilies"] as? [String] ?? []
        profile.preferredPersonalities = document["preferredPersonalities"] as? [String] ?? []
        profile.preferredOccasions = document["preferredOccasions"] as? [String] ?? []
        profile.priceRange = document["priceRange"] as? [String] ?? []
        profile.selectedBrands = document["selectedBrands"] as? [String]
        profile.referencePerfumeKey = document["referencePerfumeKey"] as? String
        profile.referencePerfumeName = document["referencePerfumeName"] as? String
        profile.orderIndex = document["orderIndex"] as? Int ?? 0

        #if DEBUG
        if let refKey = profile.referencePerfumeKey {
            print("📖 [GiftProfile.fromFirestore] Loaded reference perfume:")
            print("   Key: \(refKey)")
            print("   Name: \(profile.referencePerfumeName ?? "nil")")
        }
        #endif

        // Decodificar metadata
        if let metadataDict = document["metadata"] as? [String: Any] {
            if let lastUsedTimestamp = metadataDict["lastUsed"] as? Timestamp {
                profile.metadata.lastUsed = lastUsedTimestamp.dateValue()
            }
            profile.metadata.timesUsed = metadataDict["timesUsed"] as? Int ?? 1
            profile.metadata.purchasedPerfumes = metadataDict["purchasedPerfumes"] as? [String] ?? []
            profile.metadata.feedback = metadataDict["feedback"] as? String
        }

        // Decodificar recommendations
        if let recsArray = document["recommendations"] as? [[String: Any]] {
            profile.recommendations = recsArray.compactMap { recDict in
                guard let perfumeKey = recDict["perfumeKey"] as? String,
                      let score = recDict["score"] as? Double,
                      let reason = recDict["reason"] as? String
                else {
                    return nil
                }

                let matchFactors = (recDict["matchFactors"] as? [[String: Any]] ?? []).compactMap { factorDict -> MatchFactor? in
                    guard let factor = factorDict["factor"] as? String,
                          let description = factorDict["description"] as? String,
                          let weight = factorDict["weight"] as? Double
                    else {
                        return nil
                    }
                    return MatchFactor(factor: factor, description: description, weight: weight)
                }

                return GiftRecommendation(
                    perfumeKey: perfumeKey,
                    score: score,
                    reason: reason,
                    matchFactors: matchFactors,
                    confidence: recDict["confidence"] as? String ?? "medium"
                )
            }
        }

        return profile
    }
}
