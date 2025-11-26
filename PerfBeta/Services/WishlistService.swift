import FirebaseFirestore

// MARK: - Protocol

protocol WishlistServiceProtocol {
    func fetchWishlist(for userId: String) async throws -> [WishlistItem]
    func addToWishlist(userId: String, perfumeId: String, notes: String?, priority: Int?) async throws
    func removeFromWishlist(userId: String, perfumeId: String) async throws
    func updateWishlistItem(userId: String, _ item: WishlistItem) async throws
}

// MARK: - Implementation

/// Service responsible for managing user's wishlist
/// Handles CRUD operations for wishlist subcollection
final class WishlistService: WishlistServiceProtocol {
    private let db: Firestore

    init(firestore: Firestore = Firestore.firestore()) {
        self.db = firestore
    }

    // MARK: - Fetch Wishlist

    /// ✅ OFFLINE-FIRST: Cache first, background sync
    /// Path: users/{userId}/wishlist/{perfumeId}
    func fetchWishlist(for userId: String) async throws -> [WishlistItem] {
        let startTime = Date()
        let cacheKey = "wishlist-\(userId)"

        AppLogger.debug("Fetching wishlist for user: \(userId)", category: .userLibrary)

        // 1. Try cache first
        if let cached = await CacheManager.shared.load([WishlistItem].self, for: cacheKey) {
            let duration = Date().timeIntervalSince(startTime)
            AppLogger.debug("CACHE HIT - Wishlist (\(cached.count)) in \(String(format: "%.3f", duration))s", category: .userLibrary)

            // Background sync
            Task.detached { [weak self] in
                _ = try? await self?.fetchWishlistFromFirestore(userId: userId)
            }

            return cached
        }

        AppLogger.debug("CACHE MISS - Fetching wishlist from Firestore", category: .userLibrary)

        // 2. Fetch from Firestore
        return try await fetchWishlistFromFirestore(userId: userId)
    }

    // MARK: - Add to Wishlist

    func addToWishlist(userId: String, perfumeId: String, notes: String?, priority: Int?) async throws {
        AppLogger.debug("Adding to wishlist: \(perfumeId)", category: .userLibrary)

        let docRef = db.collection("users")
            .document(userId)
            .collection("wishlist")
            .document(perfumeId) // perfumeId como ID del documento

        try await docRef.setData([
            "perfumeId": perfumeId,
            "notes": notes ?? "",
            "priority": priority ?? 2,
            "addedAt": Timestamp(date: Date()),
            "updatedAt": Timestamp(date: Date())
        ])

        // Invalidar caché
        let cacheKey = "wishlist-\(userId)"
        await CacheManager.shared.clearCache(for: cacheKey)

        AppLogger.info("Added to wishlist: \(perfumeId)", category: .userLibrary)
    }

    // MARK: - Remove from Wishlist

    func removeFromWishlist(userId: String, perfumeId: String) async throws {
        AppLogger.debug("Removing from wishlist: \(perfumeId)", category: .userLibrary)

        let docRef = db.collection("users")
            .document(userId)
            .collection("wishlist")
            .document(perfumeId)

        try await docRef.delete()

        // Invalidar caché
        let cacheKey = "wishlist-\(userId)"
        await CacheManager.shared.clearCache(for: cacheKey)

        AppLogger.info("Removed from wishlist: \(perfumeId)", category: .userLibrary)
    }

    // MARK: - Update Wishlist Item

    func updateWishlistItem(userId: String, _ item: WishlistItem) async throws {
        AppLogger.debug("Updating wishlist item: \(item.perfumeId)", category: .userLibrary)

        let docRef = db.collection("users")
            .document(userId)
            .collection("wishlist")
            .document(item.perfumeId)

        try await docRef.setData([
            "perfumeId": item.perfumeId,
            "notes": item.notes ?? "",
            "priority": item.priority ?? 2,
            "updatedAt": Timestamp(date: Date())
        ], merge: true)

        // Invalidar caché
        let cacheKey = "wishlist-\(userId)"
        await CacheManager.shared.clearCache(for: cacheKey)

        AppLogger.info("Wishlist item updated: \(item.perfumeId)", category: .userLibrary)
    }

    // MARK: - Private Methods

    private func fetchWishlistFromFirestore(userId: String) async throws -> [WishlistItem] {
        // CRÍTICO: Path de subcolección
        let collectionRef = db.collection("users")
            .document(userId)
            .collection("wishlist")

        let snapshot = try await collectionRef.getDocuments()

        let items = snapshot.documents.compactMap { doc -> WishlistItem? in
            try? doc.data(as: WishlistItem.self)
        }

        // Save to cache
        let cacheKey = "wishlist-\(userId)"
        do {
            try await CacheManager.shared.save(items, for: cacheKey)
            await CacheManager.shared.saveLastSyncTimestamp(Date(), for: cacheKey)
            AppLogger.debug("Wishlist cached: \(items.count) items", category: .userLibrary)
        } catch {
            AppLogger.warning("Error caching wishlist: \(error)", category: .userLibrary)
        }

        AppLogger.info("Wishlist fetched: \(items.count) items", category: .userLibrary)
        return items
    }
}
