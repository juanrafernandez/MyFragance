import Foundation
import FirebaseFirestore

// MARK: - Unified Profile Service Protocol
// Protocolo simplificado - ya no requiere language para personal profiles (ruta simplificada)
protocol UnifiedProfileServiceProtocol {
    // Personal profiles (olfactive) - ruta simplificada: users/{userId}/olfactive_profiles/{profileId}
    func fetchPersonalProfiles(userId: String) async throws -> [UnifiedProfile]
    func savePersonalProfile(_ profile: UnifiedProfile, userId: String) async throws
    func updatePersonalProfile(_ profile: UnifiedProfile, userId: String) async throws
    func deletePersonalProfile(_ profile: UnifiedProfile, userId: String) async throws
    func updatePersonalProfilesOrder(_ profiles: [UnifiedProfile], userId: String) async throws

    // Gift profiles - ruta: users/{userId}/giftProfiles/{profileId}
    func fetchGiftProfiles(userId: String) async throws -> [UnifiedProfile]
    func saveGiftProfile(_ profile: UnifiedProfile, userId: String) async throws
    func updateGiftProfile(_ profile: UnifiedProfile, userId: String) async throws
    func deleteGiftProfile(id: String, userId: String) async throws
    func updateGiftProfilesOrder(_ profiles: [UnifiedProfile], userId: String) async throws
}

// MARK: - Unified Profile Service
/// Servicio unificado para gestionar perfiles personales (olfativos) y de regalo
/// Ruta simplificada: users/{userId}/olfactive_profiles/{profileId}
/// (Antes: users/{userId}/olfactive_profiles/es/profiles/{profileId})
actor UnifiedProfileService: UnifiedProfileServiceProtocol {

    static let shared = UnifiedProfileService()

    private let db: Firestore
    private let cacheManager = CacheManager.shared

    // Collection paths
    private let usersCollection = "users"
    private let personalProfilesPath = "olfactive_profiles"
    private let giftProfilesPath = "giftProfiles"

    // Legacy path components (para migración)
    private let legacyLanguageDocument = "es"
    private let legacyProfilesSubcollection = "profiles"

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    // MARK: - Personal Profiles (Olfactive)

    // Nueva ruta simplificada: users/{userId}/olfactive_profiles
    private func personalProfilesRef(userId: String) -> CollectionReference {
        return db.collection(usersCollection)
            .document(userId)
            .collection(personalProfilesPath)
    }

    // Ruta legacy: users/{userId}/olfactive_profiles/es/profiles
    private func legacyPersonalProfilesRef(userId: String) -> CollectionReference {
        return db.collection(usersCollection)
            .document(userId)
            .collection(personalProfilesPath)
            .document(legacyLanguageDocument)
            .collection(legacyProfilesSubcollection)
    }

    func fetchPersonalProfiles(userId: String) async throws -> [UnifiedProfile] {
        let cacheKey = "unified_personal_profiles_\(userId)"

        // Check cache first
        if let cached = await cacheManager.load([UnifiedProfile].self, for: cacheKey) {
            #if DEBUG
            print("✅ [UnifiedProfileService] Personal profiles loaded from cache: \(cached.count)")
            #endif
            return cached.sorted { $0.orderIndex < $1.orderIndex }
        }

        let collectionRef = personalProfilesRef(userId: userId)

        #if DEBUG
        print("📥 [UnifiedProfileService] Fetching personal profiles from: \(collectionRef.path)")
        #endif

        // Primero intentar la nueva ruta simplificada
        let snapshot = try await collectionRef
            .order(by: "orderIndex", descending: false)
            .getDocuments()

        var profiles: [UnifiedProfile] = []

        if !snapshot.documents.isEmpty {
            // Hay datos en la nueva ruta
            for document in snapshot.documents {
                let data = document.data()

                // Check if it's already a UnifiedProfile (has profileType)
                if data["profileType"] != nil {
                    if var profile = UnifiedProfile.fromFirestore(data) {
                        profile.id = document.documentID
                        profiles.append(profile)
                    }
                } else {
                    // Legacy OlfactiveProfile format - convert
                    if let legacy = try? document.data(as: OlfactiveProfile.self) {
                        var converted = UnifiedProfile.fromLegacyProfile(legacy)
                        converted.id = document.documentID
                        profiles.append(converted)
                    }
                }
            }

            #if DEBUG
            print("✅ [UnifiedProfileService] Personal profiles loaded from new path: \(profiles.count)")
            #endif
        } else {
            // Si la nueva ruta está vacía, verificar la ruta legacy y migrar
            let legacyCollectionRef = legacyPersonalProfilesRef(userId: userId)

            #if DEBUG
            print("📥 [UnifiedProfileService] No profiles in new path, checking legacy path: \(legacyCollectionRef.path)")
            #endif

            let legacySnapshot = try await legacyCollectionRef
                .order(by: "orderIndex", descending: false)
                .getDocuments()

            if !legacySnapshot.documents.isEmpty {
                #if DEBUG
                print("🔄 [UnifiedProfileService] Found \(legacySnapshot.documents.count) profiles in legacy path, migrating...")
                #endif

                let batch = db.batch()

                for document in legacySnapshot.documents {
                    let data = document.data()
                    var profile: UnifiedProfile?

                    if data["profileType"] != nil {
                        profile = UnifiedProfile.fromFirestore(data)
                    } else {
                        if let legacy = try? document.data(as: OlfactiveProfile.self) {
                            profile = UnifiedProfile.fromLegacyProfile(legacy)
                        }
                    }

                    if var validProfile = profile {
                        validProfile.id = document.documentID

                        // Guardar en la nueva ruta
                        let newDocRef = collectionRef.document(document.documentID)
                        let profileData = validProfile.toFirestore()
                        batch.setData(profileData, forDocument: newDocRef)

                        profiles.append(validProfile)
                    }
                }

                try await batch.commit()

                #if DEBUG
                print("✅ [UnifiedProfileService] Migration completed: \(profiles.count) profiles migrated to new path")
                #endif
            }
        }

        // Save to cache
        try? await cacheManager.save(profiles, for: cacheKey)

        return profiles
    }

    func savePersonalProfile(_ profile: UnifiedProfile, userId: String) async throws {
        var newProfile = profile
        newProfile.profileType = .personal

        let collectionRef = personalProfilesRef(userId: userId)

        // Generate ID if needed
        if newProfile.id == nil || newProfile.id!.isEmpty {
            newProfile.id = collectionRef.document().documentID
        }

        // Get next order index
        let countSnapshot = try await collectionRef.count.getAggregation(source: .server)
        newProfile.orderIndex = Int(truncating: countSnapshot.count)

        // Save
        let profileData = newProfile.toFirestore()
        try await collectionRef.document(newProfile.id!).setData(profileData)

        #if DEBUG
        print("✅ [UnifiedProfileService] Personal profile saved: \(newProfile.id!) with orderIndex: \(newProfile.orderIndex)")
        print("   Path: users/\(userId)/olfactive_profiles/\(newProfile.id!)")
        #endif

        await invalidatePersonalProfilesCache(userId: userId)
    }

    func updatePersonalProfile(_ profile: UnifiedProfile, userId: String) async throws {
        guard let profileId = profile.id, !profileId.isEmpty else {
            throw NSError(domain: "UnifiedProfileService", code: 400,
                         userInfo: [NSLocalizedDescriptionKey: "Profile ID cannot be nil or empty"])
        }

        var updatedProfile = profile
        updatedProfile.updatedDate = Date()

        let profileData = updatedProfile.toFirestore()
        try await personalProfilesRef(userId: userId)
            .document(profileId)
            .updateData(profileData)

        #if DEBUG
        print("✅ [UnifiedProfileService] Personal profile updated: \(profileId)")
        #endif

        await invalidatePersonalProfilesCache(userId: userId)
    }

    func deletePersonalProfile(_ profile: UnifiedProfile, userId: String) async throws {
        guard let profileId = profile.id, !profileId.isEmpty else {
            throw NSError(domain: "UnifiedProfileService", code: 400,
                         userInfo: [NSLocalizedDescriptionKey: "Profile ID cannot be nil or empty"])
        }

        let collectionRef = personalProfilesRef(userId: userId)
        let documentRef = collectionRef.document(profileId)

        // Get deleted profile's orderIndex
        let documentSnapshot = try await documentRef.getDocument()
        let deletedOrderIndex = documentSnapshot.data()?["orderIndex"] as? Int

        // Delete the document
        try await documentRef.delete()

        #if DEBUG
        print("✅ [UnifiedProfileService] Personal profile deleted: \(profileId)")
        #endif

        // Reorder remaining profiles
        if let deletedIndex = deletedOrderIndex {
            let profilesToUpdate = try await collectionRef
                .whereField("orderIndex", isGreaterThan: deletedIndex)
                .getDocuments()

            if !profilesToUpdate.isEmpty {
                let batch = db.batch()
                for document in profilesToUpdate.documents {
                    if let currentIndex = document.data()["orderIndex"] as? Int {
                        batch.updateData(["orderIndex": currentIndex - 1], forDocument: document.reference)
                    }
                }
                try await batch.commit()
            }
        }

        await invalidatePersonalProfilesCache(userId: userId)
    }

    func updatePersonalProfilesOrder(_ profiles: [UnifiedProfile], userId: String) async throws {
        guard !profiles.isEmpty else { return }

        let batch = db.batch()
        let collectionRef = personalProfilesRef(userId: userId)

        for (index, profile) in profiles.enumerated() {
            guard let profileId = profile.id, !profileId.isEmpty else { continue }
            let docRef = collectionRef.document(profileId)
            batch.updateData([
                "orderIndex": index,
                "updatedDate": Timestamp(date: Date())
            ], forDocument: docRef)
        }

        try await batch.commit()

        #if DEBUG
        print("✅ [UnifiedProfileService] Personal profiles order updated for \(profiles.count) profiles")
        #endif

        await invalidatePersonalProfilesCache(userId: userId)
    }

    private func invalidatePersonalProfilesCache(userId: String) async {
        let cacheKey = "unified_personal_profiles_\(userId)"
        await cacheManager.clearCache(for: cacheKey)
    }

    // MARK: - Gift Profiles

    private func giftProfilesRef(userId: String) -> CollectionReference {
        return db.collection(usersCollection)
            .document(userId)
            .collection(giftProfilesPath)
    }

    func fetchGiftProfiles(userId: String) async throws -> [UnifiedProfile] {
        let cacheKey = "unified_gift_profiles_\(userId)"

        // Check cache first
        if let cached = await cacheManager.load([UnifiedProfile].self, for: cacheKey) {
            #if DEBUG
            print("✅ [UnifiedProfileService] Gift profiles loaded from cache: \(cached.count)")
            #endif
            return cached.sorted { $0.orderIndex < $1.orderIndex }
        }

        let collectionRef = giftProfilesRef(userId: userId)

        #if DEBUG
        print("📥 [UnifiedProfileService] Fetching gift profiles from: \(collectionRef.path)")
        #endif

        let snapshot = try await collectionRef
            .order(by: "orderIndex")
            .getDocuments()

        // Try to decode as UnifiedProfile first, then fall back to GiftProfile
        var profiles: [UnifiedProfile] = []
        for document in snapshot.documents {
            let data = document.data()

            // Check if it's already a UnifiedProfile (has profileType)
            if data["profileType"] != nil {
                if let profile = UnifiedProfile.fromFirestore(data) {
                    profiles.append(profile)
                }
            } else {
                // Legacy GiftProfile - convert
                if let legacy = GiftProfile.fromFirestore(data) {
                    let converted = UnifiedProfile.fromGiftProfile(legacy)
                    profiles.append(converted)
                }
            }
        }

        #if DEBUG
        print("✅ [UnifiedProfileService] Gift profiles loaded from Firebase: \(profiles.count)")
        #endif

        // Save to cache
        try? await cacheManager.save(profiles, for: cacheKey)

        return profiles
    }

    func saveGiftProfile(_ profile: UnifiedProfile, userId: String) async throws {
        var newProfile = profile
        newProfile.profileType = .gift

        let collectionRef = giftProfilesRef(userId: userId)

        // Generate ID if needed
        if newProfile.id == nil || newProfile.id!.isEmpty {
            newProfile.id = UUID().uuidString
        }

        // Save
        let profileData = newProfile.toFirestore()
        try await collectionRef.document(newProfile.id!).setData(profileData)

        #if DEBUG
        print("✅ [UnifiedProfileService] Gift profile saved: \(newProfile.id!)")
        #endif

        await invalidateGiftProfilesCache(userId: userId)
    }

    func updateGiftProfile(_ profile: UnifiedProfile, userId: String) async throws {
        guard let profileId = profile.id, !profileId.isEmpty else {
            throw NSError(domain: "UnifiedProfileService", code: 400,
                         userInfo: [NSLocalizedDescriptionKey: "Profile ID cannot be nil or empty"])
        }

        var updatedProfile = profile
        updatedProfile.updatedDate = Date()

        let profileData = updatedProfile.toFirestore()
        try await giftProfilesRef(userId: userId)
            .document(profileId)
            .updateData(profileData)

        #if DEBUG
        print("✅ [UnifiedProfileService] Gift profile updated: \(profileId)")
        #endif

        await invalidateGiftProfilesCache(userId: userId)
    }

    func deleteGiftProfile(id: String, userId: String) async throws {
        try await giftProfilesRef(userId: userId)
            .document(id)
            .delete()

        #if DEBUG
        print("✅ [UnifiedProfileService] Gift profile deleted: \(id)")
        #endif

        await invalidateGiftProfilesCache(userId: userId)
    }

    func updateGiftProfilesOrder(_ profiles: [UnifiedProfile], userId: String) async throws {
        guard !profiles.isEmpty else { return }

        let batch = db.batch()
        let collectionRef = giftProfilesRef(userId: userId)

        for (index, profile) in profiles.enumerated() {
            guard let profileId = profile.id, !profileId.isEmpty else { continue }
            let docRef = collectionRef.document(profileId)
            batch.updateData([
                "orderIndex": index,
                "updatedDate": Timestamp(date: Date())
            ], forDocument: docRef)
        }

        try await batch.commit()

        #if DEBUG
        print("✅ [UnifiedProfileService] Gift profiles order updated for \(profiles.count) profiles")
        #endif

        await invalidateGiftProfilesCache(userId: userId)
    }

    private func invalidateGiftProfilesCache(userId: String) async {
        let cacheKey = "unified_gift_profiles_\(userId)"
        await cacheManager.clearCache(for: cacheKey)
    }
}

// MARK: - UnifiedProfile Extension for GiftProfile Conversion

extension UnifiedProfile {
    /// Crea UnifiedProfile desde GiftProfile (legacy)
    static func fromGiftProfile(_ legacy: GiftProfile) -> UnifiedProfile {
        var metadata = UnifiedProfileMetadata()

        // Recipient info
        metadata.recipientInfo = UnifiedRecipientInfo(
            nickname: legacy.recipientInfo.nickname,
            knowledgeLevel: legacy.recipientInfo.knowledgeLevel,
            relationship: legacy.recipientInfo.relationship
        )

        // Preferences
        metadata.preferredOccasions = legacy.preferredOccasions.isEmpty ? nil : legacy.preferredOccasions
        metadata.personalityTraits = legacy.preferredPersonalities.isEmpty ? nil : legacy.preferredPersonalities
        metadata.allowedBrands = legacy.selectedBrands
        metadata.priceRange = legacy.priceRange.isEmpty ? nil : legacy.priceRange
        metadata.referencePerfumeKey = legacy.referencePerfumeKey
        metadata.referencePerfumeName = legacy.referencePerfumeName

        // Family scores from preferredFamilies
        var familyScores: [String: Double] = [:]
        for (index, family) in legacy.preferredFamilies.enumerated() {
            familyScores[family] = 100.0 - Double(index * 20)  // Decreasing scores
        }

        let primaryFamily = legacy.preferredFamilies.first ?? "unknown"
        let subfamilies = Array(legacy.preferredFamilies.dropFirst())

        // Usage metadata
        let usageMetadata = ProfileUsageMetadata(
            lastUsed: legacy.metadata.lastUsed,
            timesUsed: legacy.metadata.timesUsed,
            purchasedPerfumes: legacy.metadata.purchasedPerfumes,
            feedback: legacy.metadata.feedback
        )

        // Convert recommendations
        let recommendedPerfumes = legacy.recommendations.map { rec in
            RecommendedPerfume(perfumeId: rec.perfumeKey, matchPercentage: rec.score)
        }

        return UnifiedProfile(
            id: legacy.id,
            name: legacy.recipientInfo.nickname,
            profileType: .gift,
            createdDate: legacy.createdAt,
            updatedDate: legacy.updatedAt,
            experienceLevel: legacy.recipientInfo.isHighKnowledge ? .expert : .beginner,
            flowType: legacy.flowType,
            primaryFamily: primaryFamily,
            subfamilies: subfamilies,
            familyScores: familyScores,
            genderPreference: "unisex",  // Gift profiles typically don't have gender preference
            metadata: metadata,
            confidenceScore: 0.7,
            answerCompleteness: 1.0,
            recommendedPerfumes: recommendedPerfumes.isEmpty ? nil : recommendedPerfumes,
            usageMetadata: usageMetadata,
            orderIndex: legacy.orderIndex
        )
    }
}
