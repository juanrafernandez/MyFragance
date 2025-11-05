import FirebaseFirestore

// MARK: - Protocol

protocol TriedPerfumeServiceProtocol {
    func fetchTriedPerfumes(for userId: String) async throws -> [TriedPerfume]
    func addTriedPerfume(userId: String, perfumeId: String, rating: Double, userProjection: String?, userDuration: String?, userPrice: String?, notes: String?, userSeasons: [String]?, userPersonalities: [String]?) async throws
    func updateTriedPerfume(userId: String, _ triedPerfume: TriedPerfume) async throws
    func removeTriedPerfume(userId: String, perfumeId: String) async throws
}

// MARK: - Implementation

/// Service responsible for managing user's tried perfumes
/// Handles CRUD operations for tried_perfumes subcollection
final class TriedPerfumeService: TriedPerfumeServiceProtocol {
    private let db: Firestore

    init(firestore: Firestore = Firestore.firestore()) {
        self.db = firestore
    }

    // MARK: - Fetch Tried Perfumes

    /// ✅ OFFLINE-FIRST: Cache first, background sync
    /// Path: users/{userId}/tried_perfumes/{perfumeId}
    func fetchTriedPerfumes(for userId: String) async throws -> [TriedPerfume] {
        let startTime = Date()
        let cacheKey = "triedPerfumes-\(userId)"

        print("📥 [TriedPerfumeService] Fetching tried perfumes for user: \(userId)")

        // 1. Try cache first
        if let cached = await CacheManager.shared.load([TriedPerfume].self, for: cacheKey) {
            let duration = Date().timeIntervalSince(startTime)
            print("✅ [TriedPerfumeService] CACHE HIT - Tried perfumes (\(cached.count)) in \(String(format: "%.3f", duration))s")

            // Background sync
            Task.detached { [weak self] in
                _ = try? await self?.fetchTriedPerfumesFromFirestore(userId: userId)
            }

            return cached
        }

        print("⚠️ [TriedPerfumeService] CACHE MISS - Fetching from Firestore")

        // 2. Fetch from Firestore
        return try await fetchTriedPerfumesFromFirestore(userId: userId)
    }

    // MARK: - Add Tried Perfume

    func addTriedPerfume(userId: String, perfumeId: String, rating: Double, userProjection: String?, userDuration: String?, userPrice: String?, notes: String?, userSeasons: [String]?, userPersonalities: [String]?) async throws {
        print("➕ [TriedPerfumeService] Adding tried perfume: \(perfumeId)")

        let docRef = db.collection("users")
            .document(userId)
            .collection("tried_perfumes")
            .document(perfumeId) // perfumeId como ID del documento

        try await docRef.setData([
            "perfumeId": perfumeId,
            "rating": rating,
            "notes": notes ?? "",
            "triedAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date()),
            "userPersonalities": userPersonalities ?? [],
            "userPrice": userPrice ?? "",
            "userSeasons": userSeasons ?? [],
            "userProjection": userProjection ?? "",
            "userDuration": userDuration ?? ""
        ])

        // Invalidar caché
        let cacheKey = "triedPerfumes-\(userId)"
        await CacheManager.shared.clearCache(for: cacheKey)

        print("✅ [TriedPerfumeService] Tried perfume added")
    }

    // MARK: - Update Tried Perfume

    func updateTriedPerfume(userId: String, _ triedPerfume: TriedPerfume) async throws {
        print("🔄 [TriedPerfumeService] Updating tried perfume: \(triedPerfume.perfumeId)")

        let docRef = db.collection("users")
            .document(userId)
            .collection("tried_perfumes")
            .document(triedPerfume.perfumeId)

        try await docRef.setData([
            "perfumeId": triedPerfume.perfumeId,
            "rating": triedPerfume.rating,
            "notes": triedPerfume.notes,
            "updatedAt": Timestamp(date: Date()),
            "userPersonalities": triedPerfume.userPersonalities,
            "userPrice": triedPerfume.userPrice,
            "userSeasons": triedPerfume.userSeasons,
            "userProjection": triedPerfume.userProjection ?? "",
            "userDuration": triedPerfume.userDuration ?? ""
        ], merge: true)

        // Invalidar caché
        let cacheKey = "triedPerfumes-\(userId)"
        await CacheManager.shared.clearCache(for: cacheKey)

        print("✅ [TriedPerfumeService] Tried perfume updated")
    }

    // MARK: - Remove Tried Perfume

    func removeTriedPerfume(userId: String, perfumeId: String) async throws {
        print("➖ [TriedPerfumeService] Removing tried perfume: \(perfumeId)")

        let docRef = db.collection("users")
            .document(userId)
            .collection("tried_perfumes")
            .document(perfumeId)

        try await docRef.delete()

        // Invalidar caché
        let cacheKey = "triedPerfumes-\(userId)"
        await CacheManager.shared.clearCache(for: cacheKey)

        print("✅ [TriedPerfumeService] Tried perfume removed")
    }

    // MARK: - Private Methods

    private func fetchTriedPerfumesFromFirestore(userId: String) async throws -> [TriedPerfume] {
        // CRÍTICO: Path de subcolección
        let collectionRef = db.collection("users")
            .document(userId)
            .collection("tried_perfumes")

        let snapshot = try await collectionRef.getDocuments()

        let perfumes = snapshot.documents.compactMap { doc -> TriedPerfume? in
            guard var perfume = try? doc.data(as: TriedPerfume.self) else {
                return nil
            }
            // ✅ Assign document ID manually (compatible with JSONEncoder cache)
            perfume.id = doc.documentID
            return perfume
        }

        // Save to cache
        let cacheKey = "triedPerfumes-\(userId)"
        do {
            try await CacheManager.shared.save(perfumes, for: cacheKey)
            await CacheManager.shared.saveLastSyncTimestamp(Date(), for: cacheKey)
            print("💾 [TriedPerfumeService] Tried perfumes cached: \(perfumes.count) items")
        } catch {
            print("⚠️ [TriedPerfumeService] Error caching tried perfumes: \(error)")
        }

        print("✅ [TriedPerfumeService] Tried perfumes fetched: \(perfumes.count) items")
        return perfumes
    }
}
