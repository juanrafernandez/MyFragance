import Foundation

// MARK: - Unified Profile
/// Nuevo modelo unificado de perfil que reemplaza OlfactiveProfile y GiftProfile
/// Compatible con flujos personales (A/B/C) y flujos de regalo
struct UnifiedProfile: Identifiable, Codable, Equatable, Hashable {

    // MARK: - Identificación
    var id: String?
    var name: String
    var profileType: ProfileType
    var createdDate: Date
    var updatedDate: Date
    var experienceLevel: ExperienceLevel
    var flowType: String?  // Tipo de flujo usado ("flowA", "flowB", etc.)

    // MARK: - Core Olfativo (siempre presente)
    var primaryFamily: String
    var subfamilies: [String]
    var familyScores: [String: Double]  // Normalizado a 0-100

    // MARK: - Filtros Principales
    var genderPreference: String  // "male", "female", "unisex"

    // MARK: - Metadata de Preferencias
    var metadata: UnifiedProfileMetadata

    // MARK: - Sistema de Confianza
    var confidenceScore: Double      // 0.0 - 1.0
    var answerCompleteness: Double   // 0.0 - 1.0

    // MARK: - Perfumes Recomendados
    var recommendedPerfumes: [RecommendedPerfume]?

    // MARK: - Metadata de uso (tracking)
    var usageMetadata: ProfileUsageMetadata?

    // MARK: - Legacy (para compatibilidad con sistema anterior)
    var orderIndex: Int
    var descriptionProfile: String?
    var icon: String?
    var questionsAndAnswers: [QuestionAnswer]?

    init(
        id: String? = nil,
        name: String,
        profileType: ProfileType = .personal,
        createdDate: Date = Date(),
        updatedDate: Date = Date(),
        experienceLevel: ExperienceLevel = .beginner,
        flowType: String? = nil,
        primaryFamily: String,
        subfamilies: [String] = [],
        familyScores: [String: Double] = [:],
        genderPreference: String = "unisex",
        metadata: UnifiedProfileMetadata = UnifiedProfileMetadata(),
        confidenceScore: Double = 0.0,
        answerCompleteness: Double = 0.0,
        recommendedPerfumes: [RecommendedPerfume]? = nil,
        usageMetadata: ProfileUsageMetadata? = nil,
        orderIndex: Int = 0,
        descriptionProfile: String? = nil,
        icon: String? = nil,
        questionsAndAnswers: [QuestionAnswer]? = nil
    ) {
        self.id = id
        self.name = name
        self.profileType = profileType
        self.createdDate = createdDate
        self.updatedDate = updatedDate
        self.experienceLevel = experienceLevel
        self.flowType = flowType
        self.primaryFamily = primaryFamily
        self.subfamilies = subfamilies
        self.familyScores = familyScores
        self.genderPreference = genderPreference
        self.metadata = metadata
        self.confidenceScore = confidenceScore
        self.answerCompleteness = answerCompleteness
        self.recommendedPerfumes = recommendedPerfumes
        self.usageMetadata = usageMetadata
        self.orderIndex = orderIndex
        self.descriptionProfile = descriptionProfile
        self.icon = icon
        self.questionsAndAnswers = questionsAndAnswers
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
    }

    static func == (lhs: UnifiedProfile, rhs: UnifiedProfile) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name
    }
}

// MARK: - Profile Type
enum ProfileType: String, Codable {
    case personal = "personal"
    case gift = "gift"
}

// MARK: - Experience Level
enum ExperienceLevel: String, Codable {
    case beginner = "beginner"       // Flujo A
    case intermediate = "intermediate" // Flujo B
    case expert = "expert"            // Flujo C
}

// MARK: - Profile Metadata
struct UnifiedProfileMetadata: Codable, Equatable {
    // Notas (opcionales)
    var preferredNotes: [String]?
    var avoidFamilies: [String]?

    // Referencias (opcional)
    var referencePerfumes: [String]?

    // Performance
    var intensityPreference: String?      // "low", "medium", "high", "very_high"
    var intensityMax: String?             // NEW (Profile B): Límite máximo de intensidad
    var durationPreference: String?       // "short", "moderate", "long", "very_long"
    var projectionPreference: String?     // "low", "moderate", "high", "explosive"
    var concentrationPreference: String?  // "edt", "edp", "parfum", "oil", "varies"

    // Notas específicas (Profile B - Intermediate)
    var mustContainNotes: [String]?       // NEW: Notas que DEBEN estar presentes
    var heartNotesBonus: [String]?        // NEW: Bonus si están en heartNotes
    var baseNotesBonus: [String]?         // NEW: Bonus si están en baseNotes

    // Contexto
    var preferredSeasons: [String]?       // ["autumn", "winter"]
    var preferredOccasions: [String]?     // ["office", "daily_use", "nights"]
    var personalityTraits: [String]?      // ["elegant", "confident", "mysterious"]

    // Estructura (solo flujo C)
    var structurePreference: String?      // "linear", "pyramid", "top_heavy", "base_forward", "radial"
    var phasePreference: String?          // "top", "heart", "base", "all"

    // Regalo específico (solo gift flows)
    var recipientInfo: UnifiedRecipientInfo?

    // Discovery
    var discoveryMode: String?            // "safe", "moderate", "adventurous"

    // Filtros obligatorios (para gift flow con marcas específicas)
    var allowedBrands: [String]?          // Si no vacío, SOLO recomendar de estas marcas

    // Precio (para gift flow)
    var priceRange: [String]?             // ["low", "medium", "high"]

    // Perfume de referencia (para gift flow D)
    var referencePerfumeKey: String?
    var referencePerfumeName: String?

    init(
        preferredNotes: [String]? = nil,
        avoidFamilies: [String]? = nil,
        referencePerfumes: [String]? = nil,
        intensityPreference: String? = nil,
        intensityMax: String? = nil,
        durationPreference: String? = nil,
        projectionPreference: String? = nil,
        concentrationPreference: String? = nil,
        mustContainNotes: [String]? = nil,
        heartNotesBonus: [String]? = nil,
        baseNotesBonus: [String]? = nil,
        preferredSeasons: [String]? = nil,
        preferredOccasions: [String]? = nil,
        personalityTraits: [String]? = nil,
        structurePreference: String? = nil,
        phasePreference: String? = nil,
        recipientInfo: UnifiedRecipientInfo? = nil,
        discoveryMode: String? = nil,
        allowedBrands: [String]? = nil,
        priceRange: [String]? = nil,
        referencePerfumeKey: String? = nil,
        referencePerfumeName: String? = nil
    ) {
        self.preferredNotes = preferredNotes
        self.avoidFamilies = avoidFamilies
        self.referencePerfumes = referencePerfumes
        self.intensityPreference = intensityPreference
        self.intensityMax = intensityMax
        self.durationPreference = durationPreference
        self.projectionPreference = projectionPreference
        self.concentrationPreference = concentrationPreference
        self.mustContainNotes = mustContainNotes
        self.heartNotesBonus = heartNotesBonus
        self.baseNotesBonus = baseNotesBonus
        self.preferredSeasons = preferredSeasons
        self.preferredOccasions = preferredOccasions
        self.personalityTraits = personalityTraits
        self.structurePreference = structurePreference
        self.phasePreference = phasePreference
        self.recipientInfo = recipientInfo
        self.discoveryMode = discoveryMode
        self.allowedBrands = allowedBrands
        self.priceRange = priceRange
        self.referencePerfumeKey = referencePerfumeKey
        self.referencePerfumeName = referencePerfumeName
    }
}

// MARK: - Recipient Info (for gift profiles)
struct UnifiedRecipientInfo: Codable, Equatable {
    var nickname: String?       // Nombre/apodo del receptor
    var knowledgeLevel: String? // "low_knowledge", "high_knowledge"
    var ageRange: String?       // "young", "adult", "mature", "senior"
    var lifestyle: String?      // "professional", "creative", "active", "social"
    var relationship: String?   // "partner", "friend", "family", "colleague"

    init(
        nickname: String? = nil,
        knowledgeLevel: String? = nil,
        ageRange: String? = nil,
        lifestyle: String? = nil,
        relationship: String? = nil
    ) {
        self.nickname = nickname
        self.knowledgeLevel = knowledgeLevel
        self.ageRange = ageRange
        self.lifestyle = lifestyle
        self.relationship = relationship
    }

    var isLowKnowledge: Bool { knowledgeLevel == "low_knowledge" }
    var isHighKnowledge: Bool { knowledgeLevel == "high_knowledge" }
}

// MARK: - Profile Usage Metadata
/// Metadata de uso para tracking y estadísticas
struct ProfileUsageMetadata: Codable, Equatable {
    var lastUsed: Date
    var timesUsed: Int
    var purchasedPerfumes: [String]  // Keys de perfumes marcados como comprados
    var feedback: String?

    init(
        lastUsed: Date = Date(),
        timesUsed: Int = 1,
        purchasedPerfumes: [String] = [],
        feedback: String? = nil
    ) {
        self.lastUsed = lastUsed
        self.timesUsed = timesUsed
        self.purchasedPerfumes = purchasedPerfumes
        self.feedback = feedback
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

// MARK: - Extensions for Legacy Compatibility

extension UnifiedProfile {
    /// Convierte UnifiedProfile a OlfactiveProfile (legacy)
    func toLegacyProfile() -> OlfactiveProfile {
        let families = familyScores.map { key, value in
            FamilyPuntuation(family: key, puntuation: Int(value))
        }.sorted { $0.puntuation > $1.puntuation }

        return OlfactiveProfile(
            id: id,
            name: name,
            gender: genderPreference,
            families: families,
            intensity: metadata.intensityPreference ?? "medium",
            duration: metadata.durationPreference ?? "moderate",
            descriptionProfile: descriptionProfile,
            icon: icon,
            questionsAndAnswers: questionsAndAnswers,
            experienceLevel: experienceLevel.rawValue,
            recommendedPerfumes: recommendedPerfumes,
            orderIndex: orderIndex
        )
    }

    /// Crea UnifiedProfile desde OlfactiveProfile (legacy)
    static func fromLegacyProfile(_ legacy: OlfactiveProfile) -> UnifiedProfile {
        var familyScores: [String: Double] = [:]
        for family in legacy.families {
            familyScores[family.family] = Double(family.puntuation)
        }

        // Normalizar scores a 100
        if let maxScore = familyScores.values.max(), maxScore > 0 {
            let normalizationFactor = 100.0 / maxScore
            familyScores = familyScores.mapValues { $0 * normalizationFactor }
        }

        let primaryFamily = legacy.families.first?.family ?? "unknown"
        let subfamilies = legacy.families.dropFirst().map { $0.family }

        var metadata = UnifiedProfileMetadata()
        metadata.intensityPreference = legacy.intensity.lowercased()
        metadata.durationPreference = legacy.duration.lowercased()

        return UnifiedProfile(
            id: legacy.id,
            name: legacy.name,
            profileType: .personal,
            createdDate: Date(),
            experienceLevel: .beginner,
            primaryFamily: primaryFamily,
            subfamilies: Array(subfamilies),
            familyScores: familyScores,
            genderPreference: legacy.gender.lowercased(),
            metadata: metadata,
            confidenceScore: 0.7,  // Default
            answerCompleteness: 1.0,
            recommendedPerfumes: legacy.recommendedPerfumes,
            orderIndex: legacy.orderIndex,
            descriptionProfile: legacy.descriptionProfile,
            icon: legacy.icon,
            questionsAndAnswers: legacy.questionsAndAnswers
        )
    }
}

// MARK: - Gift Profile Computed Properties

extension UnifiedProfile {
    /// Nombre para mostrar (nickname del receptor o nombre del perfil)
    var displayName: String {
        metadata.recipientInfo?.nickname ?? name
    }

    /// Resumen descriptivo del perfil
    var summary: String {
        guard let flowType = flowType else {
            if profileType == .personal {
                return "Perfil \(experienceLevel.rawValue)"
            }
            return "Perfil sin completar"
        }

        switch flowType {
        case "flowA":
            return "Perfil general"
        case "flowB":
            return "Perfil personalizado"
        case "flowC":
            if let brands = metadata.allowedBrands, !brands.isEmpty {
                return "Marcas: \(brands.prefix(2).joined(separator: ", "))"
            }
            return "Por marcas favoritas"
        case "flowD":
            if let perfumeName = metadata.referencePerfumeName {
                return "Similar a \(perfumeName)"
            }
            return "Similar a perfume conocido"
        case "flowE":
            if !subfamilies.isEmpty {
                return "Aromas: \(subfamilies.prefix(2).joined(separator: ", "))"
            }
            return "Por tipo de aromas"
        case "flowF":
            return "Estilo de vida"
        default:
            return "Perfil \(profileType.rawValue)"
        }
    }

    /// Si tiene recomendaciones
    var hasRecommendations: Bool {
        guard let recs = recommendedPerfumes else { return false }
        return !recs.isEmpty
    }

    /// Top 3 recomendaciones
    var topRecommendations: [RecommendedPerfume] {
        Array((recommendedPerfumes ?? []).prefix(3))
    }
}

// MARK: - Firestore Serialization

import FirebaseFirestore

extension UnifiedProfile {
    /// Convertir a diccionario para Firestore
    func toFirestore() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id ?? UUID().uuidString,
            "name": name,
            "profileType": profileType.rawValue,
            "createdDate": Timestamp(date: createdDate),
            "updatedDate": Timestamp(date: updatedDate),
            "experienceLevel": experienceLevel.rawValue,
            "primaryFamily": primaryFamily,
            "subfamilies": subfamilies,
            "familyScores": familyScores,
            "genderPreference": genderPreference,
            "confidenceScore": confidenceScore,
            "answerCompleteness": answerCompleteness,
            "orderIndex": orderIndex
        ]

        // Opcionales
        if let flowType = flowType { dict["flowType"] = flowType }
        if let desc = descriptionProfile { dict["descriptionProfile"] = desc }
        if let icon = icon { dict["icon"] = icon }

        // Metadata de preferencias
        var metadataDict: [String: Any] = [:]
        if let notes = metadata.preferredNotes { metadataDict["preferredNotes"] = notes }
        if let avoid = metadata.avoidFamilies { metadataDict["avoidFamilies"] = avoid }
        if let refs = metadata.referencePerfumes { metadataDict["referencePerfumes"] = refs }
        if let intensity = metadata.intensityPreference { metadataDict["intensityPreference"] = intensity }
        if let intensityMax = metadata.intensityMax { metadataDict["intensityMax"] = intensityMax }
        if let duration = metadata.durationPreference { metadataDict["durationPreference"] = duration }
        if let projection = metadata.projectionPreference { metadataDict["projectionPreference"] = projection }
        if let concentration = metadata.concentrationPreference { metadataDict["concentrationPreference"] = concentration }
        if let must = metadata.mustContainNotes { metadataDict["mustContainNotes"] = must }
        if let heart = metadata.heartNotesBonus { metadataDict["heartNotesBonus"] = heart }
        if let base = metadata.baseNotesBonus { metadataDict["baseNotesBonus"] = base }
        if let seasons = metadata.preferredSeasons { metadataDict["preferredSeasons"] = seasons }
        if let occasions = metadata.preferredOccasions { metadataDict["preferredOccasions"] = occasions }
        if let personality = metadata.personalityTraits { metadataDict["personalityTraits"] = personality }
        if let structure = metadata.structurePreference { metadataDict["structurePreference"] = structure }
        if let phase = metadata.phasePreference { metadataDict["phasePreference"] = phase }
        if let discovery = metadata.discoveryMode { metadataDict["discoveryMode"] = discovery }
        if let brands = metadata.allowedBrands { metadataDict["allowedBrands"] = brands }
        if let price = metadata.priceRange { metadataDict["priceRange"] = price }
        if let refKey = metadata.referencePerfumeKey { metadataDict["referencePerfumeKey"] = refKey }
        if let refName = metadata.referencePerfumeName { metadataDict["referencePerfumeName"] = refName }

        // Recipient info
        if let recipient = metadata.recipientInfo {
            var recipientDict: [String: Any] = [:]
            if let nickname = recipient.nickname { recipientDict["nickname"] = nickname }
            if let knowledge = recipient.knowledgeLevel { recipientDict["knowledgeLevel"] = knowledge }
            if let age = recipient.ageRange { recipientDict["ageRange"] = age }
            if let lifestyle = recipient.lifestyle { recipientDict["lifestyle"] = lifestyle }
            if let relationship = recipient.relationship { recipientDict["relationship"] = relationship }
            metadataDict["recipientInfo"] = recipientDict
        }

        dict["metadata"] = metadataDict

        // Usage metadata
        if let usage = usageMetadata {
            dict["usageMetadata"] = [
                "lastUsed": Timestamp(date: usage.lastUsed),
                "timesUsed": usage.timesUsed,
                "purchasedPerfumes": usage.purchasedPerfumes,
                "feedback": usage.feedback as Any
            ]
        }

        // Recommendations
        if let recs = recommendedPerfumes {
            dict["recommendedPerfumes"] = recs.map { rec in
                [
                    "perfumeId": rec.perfumeId,
                    "matchPercentage": rec.matchPercentage
                ]
            }
        }

        // Questions and answers
        if let qas = questionsAndAnswers {
            dict["questionsAndAnswers"] = qas.map { qa in
                [
                    "questionId": qa.questionId,
                    "answerId": qa.answerId
                ]
            }
        }

        return dict
    }

    /// Crear desde documento de Firestore
    static func fromFirestore(_ document: [String: Any]) -> UnifiedProfile? {
        guard let id = document["id"] as? String,
              let name = document["name"] as? String,
              let profileTypeStr = document["profileType"] as? String,
              let profileType = ProfileType(rawValue: profileTypeStr),
              let createdTimestamp = document["createdDate"] as? Timestamp,
              let primaryFamily = document["primaryFamily"] as? String
        else {
            return nil
        }

        let updatedTimestamp = document["updatedDate"] as? Timestamp ?? createdTimestamp
        let experienceLevelStr = document["experienceLevel"] as? String ?? "beginner"
        let experienceLevel = ExperienceLevel(rawValue: experienceLevelStr) ?? .beginner

        // Decodificar metadata
        var metadata = UnifiedProfileMetadata()
        if let metadataDict = document["metadata"] as? [String: Any] {
            metadata.preferredNotes = metadataDict["preferredNotes"] as? [String]
            metadata.avoidFamilies = metadataDict["avoidFamilies"] as? [String]
            metadata.referencePerfumes = metadataDict["referencePerfumes"] as? [String]
            metadata.intensityPreference = metadataDict["intensityPreference"] as? String
            metadata.intensityMax = metadataDict["intensityMax"] as? String
            metadata.durationPreference = metadataDict["durationPreference"] as? String
            metadata.projectionPreference = metadataDict["projectionPreference"] as? String
            metadata.concentrationPreference = metadataDict["concentrationPreference"] as? String
            metadata.mustContainNotes = metadataDict["mustContainNotes"] as? [String]
            metadata.heartNotesBonus = metadataDict["heartNotesBonus"] as? [String]
            metadata.baseNotesBonus = metadataDict["baseNotesBonus"] as? [String]
            metadata.preferredSeasons = metadataDict["preferredSeasons"] as? [String]
            metadata.preferredOccasions = metadataDict["preferredOccasions"] as? [String]
            metadata.personalityTraits = metadataDict["personalityTraits"] as? [String]
            metadata.structurePreference = metadataDict["structurePreference"] as? String
            metadata.phasePreference = metadataDict["phasePreference"] as? String
            metadata.discoveryMode = metadataDict["discoveryMode"] as? String
            metadata.allowedBrands = metadataDict["allowedBrands"] as? [String]
            metadata.priceRange = metadataDict["priceRange"] as? [String]
            metadata.referencePerfumeKey = metadataDict["referencePerfumeKey"] as? String
            metadata.referencePerfumeName = metadataDict["referencePerfumeName"] as? String

            // Recipient info
            if let recipientDict = metadataDict["recipientInfo"] as? [String: Any] {
                metadata.recipientInfo = UnifiedRecipientInfo(
                    nickname: recipientDict["nickname"] as? String,
                    knowledgeLevel: recipientDict["knowledgeLevel"] as? String,
                    ageRange: recipientDict["ageRange"] as? String,
                    lifestyle: recipientDict["lifestyle"] as? String,
                    relationship: recipientDict["relationship"] as? String
                )
            }
        }

        // Usage metadata
        var usageMetadata: ProfileUsageMetadata?
        if let usageDict = document["usageMetadata"] as? [String: Any] {
            let lastUsed = (usageDict["lastUsed"] as? Timestamp)?.dateValue() ?? Date()
            let timesUsed = usageDict["timesUsed"] as? Int ?? 1
            let purchased = usageDict["purchasedPerfumes"] as? [String] ?? []
            let feedback = usageDict["feedback"] as? String
            usageMetadata = ProfileUsageMetadata(
                lastUsed: lastUsed,
                timesUsed: timesUsed,
                purchasedPerfumes: purchased,
                feedback: feedback
            )
        }

        // Recommendations
        var recommendedPerfumes: [RecommendedPerfume]?
        if let recsArray = document["recommendedPerfumes"] as? [[String: Any]] {
            recommendedPerfumes = recsArray.compactMap { recDict in
                guard let perfumeId = recDict["perfumeId"] as? String,
                      let matchPercentage = recDict["matchPercentage"] as? Double
                else { return nil }
                return RecommendedPerfume(perfumeId: perfumeId, matchPercentage: matchPercentage)
            }
        }

        // Questions and answers
        var questionsAndAnswers: [QuestionAnswer]?
        if let qasArray = document["questionsAndAnswers"] as? [[String: Any]] {
            questionsAndAnswers = qasArray.compactMap { qaDict in
                guard let questionId = qaDict["questionId"] as? String,
                      let answerId = qaDict["answerId"] as? String
                else { return nil }
                return QuestionAnswer(questionId: questionId, answerId: answerId)
            }
        }

        return UnifiedProfile(
            id: id,
            name: name,
            profileType: profileType,
            createdDate: createdTimestamp.dateValue(),
            updatedDate: updatedTimestamp.dateValue(),
            experienceLevel: experienceLevel,
            flowType: document["flowType"] as? String,
            primaryFamily: primaryFamily,
            subfamilies: document["subfamilies"] as? [String] ?? [],
            familyScores: document["familyScores"] as? [String: Double] ?? [:],
            genderPreference: document["genderPreference"] as? String ?? "unisex",
            metadata: metadata,
            confidenceScore: document["confidenceScore"] as? Double ?? 0.0,
            answerCompleteness: document["answerCompleteness"] as? Double ?? 0.0,
            recommendedPerfumes: recommendedPerfumes,
            usageMetadata: usageMetadata,
            orderIndex: document["orderIndex"] as? Int ?? 0,
            descriptionProfile: document["descriptionProfile"] as? String,
            icon: document["icon"] as? String,
            questionsAndAnswers: questionsAndAnswers
        )
    }
}
