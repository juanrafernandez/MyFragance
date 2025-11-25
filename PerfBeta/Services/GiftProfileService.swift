import Foundation
import FirebaseFirestore

// MARK: - Gift Profile Service Protocol
protocol GiftProfileServiceProtocol {
    func saveProfile(_ profile: GiftProfile, userId: String) async throws
    func loadProfiles(userId: String) async throws -> [GiftProfile]
    func loadProfile(id: String, userId: String) async throws -> GiftProfile?
    func updateProfile(_ profile: GiftProfile, userId: String) async throws
    func deleteProfile(id: String, userId: String) async throws
    func updateOrderIndices(_ profiles: [GiftProfile], userId: String) async throws
}

// MARK: - Gift Profile Service
/// Servicio para gestionar perfiles de regalo guardados
actor GiftProfileService: GiftProfileServiceProtocol {

    static let shared = GiftProfileService()

    private let db: Firestore
    private let cacheManager = CacheManager.shared

    init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    // MARK: - Public Methods

    func saveProfile(_ profile: GiftProfile, userId: String) async throws {
        let profileData = profile.toFirestore()

        try await db.collection("users")
            .document(userId)
            .collection("giftProfiles")
            .document(profile.id)
            .setData(profileData)

        #if DEBUG
        print("✅ [GiftProfileService] Profile saved: \(profile.id)")
        #endif

        // Invalidar cache de perfiles
        await invalidateProfilesCache(userId: userId)
    }

    func loadProfiles(userId: String) async throws -> [GiftProfile] {
        // Check cache primero
        // v2: Added orderIndex field for custom ordering
        let cacheKey = "gift_profiles_v2_\(userId)"
        if let cached = await cacheManager.load([GiftProfile].self, for: cacheKey) {
            #if DEBUG
            print("✅ [GiftProfileService] Profiles loaded from cache: \(cached.count)")
            #endif
            // Ordenar por orderIndex
            return cached.sorted { $0.orderIndex < $1.orderIndex }
        }

        // Download desde Firebase
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("giftProfiles")
            .order(by: "orderIndex")
            .getDocuments()

        let profiles = snapshot.documents.compactMap { doc -> GiftProfile? in
            GiftProfile.fromFirestore(doc.data())
        }

        #if DEBUG
        print("✅ [GiftProfileService] Profiles loaded from Firebase: \(profiles.count)")
        #endif

        // Guardar en cache
        try? await cacheManager.save(profiles, for: cacheKey)

        return profiles
    }

    func loadProfile(id: String, userId: String) async throws -> GiftProfile? {
        let doc = try await db.collection("users")
            .document(userId)
            .collection("giftProfiles")
            .document(id)
            .getDocument()

        guard doc.exists, let data = doc.data() else {
            return nil
        }

        return GiftProfile.fromFirestore(data)
    }

    func updateProfile(_ profile: GiftProfile, userId: String) async throws {
        var updatedProfile = profile
        updatedProfile.updatedAt = Date()

        let profileData = updatedProfile.toFirestore()

        try await db.collection("users")
            .document(userId)
            .collection("giftProfiles")
            .document(profile.id)
            .updateData(profileData)

        #if DEBUG
        print("✅ [GiftProfileService] Profile updated: \(profile.id)")
        #endif

        await invalidateProfilesCache(userId: userId)
    }

    func deleteProfile(id: String, userId: String) async throws {
        try await db.collection("users")
            .document(userId)
            .collection("giftProfiles")
            .document(id)
            .delete()

        #if DEBUG
        print("✅ [GiftProfileService] Profile deleted: \(id)")
        #endif

        await invalidateProfilesCache(userId: userId)
    }

    func updateOrderIndices(_ profiles: [GiftProfile], userId: String) async throws {
        // Batch update para eficiencia
        let batch = db.batch()

        for (index, profile) in profiles.enumerated() {
            var updatedProfile = profile
            updatedProfile.orderIndex = index
            updatedProfile.updatedAt = Date()

            let ref = db.collection("users")
                .document(userId)
                .collection("giftProfiles")
                .document(profile.id)

            batch.updateData(["orderIndex": index, "updatedAt": Timestamp(date: Date())], forDocument: ref)
        }

        try await batch.commit()

        #if DEBUG
        print("✅ [GiftProfileService] Order indices updated for \(profiles.count) profiles")
        #endif

        await invalidateProfilesCache(userId: userId)
    }

    // MARK: - Private Methods

    private func invalidateProfilesCache(userId: String) async {
        // v2: Added orderIndex field for custom ordering
        let cacheKey = "gift_profiles_v2_\(userId)"
        await cacheManager.clearCache(for: cacheKey)
        #if DEBUG
        print("🗑️ [GiftProfileService] Cache invalidated for user: \(userId)")
        #endif
    }
}
