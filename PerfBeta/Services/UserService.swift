import FirebaseFirestore
import FirebaseAuth

// MARK: - Protocol

protocol UserServiceProtocol {
    func fetchUser(by userId: String) async throws -> User
    func fetchTriedPerfumes(for userId: String) async throws -> [TriedPerfume]
    func fetchWishlist(for userId: String) async throws -> [WishlistItem]
    func addTriedPerfume(userId: String, perfumeId: String, rating: Double, userProjection: String?, userDuration: String?, userPrice: String?, notes: String?, userSeasons: [String]?, userPersonalities: [String]?) async throws
    func updateTriedPerfume(userId: String, _ triedPerfume: TriedPerfume) async throws
    func removeTriedPerfume(userId: String, perfumeId: String) async throws
    func addToWishlist(userId: String, perfumeId: String, notes: String?, priority: Int?) async throws
    func removeFromWishlist(userId: String, perfumeId: String) async throws
    func updateWishlistItem(userId: String, _ item: WishlistItem) async throws
}

// MARK: - Implementation

/// ✅ REFACTOR: User data service con estructura NESTED y caché permanente
/// - Estructura NESTED: users/{userId} con subcollections
/// - Caché permanente usando CacheManager (no expira)
/// - Auto-crea documento de usuario si no existe
final class UserService: UserServiceProtocol {
    private let db: Firestore

    init(firestore: Firestore = Firestore.firestore()) {
        self.db = firestore
    }

    // MARK: - Fetch User (NESTED)

    /// ✅ OFFLINE-FIRST: Cache first, network fallback, auto-create if missing
    func fetchUser(by userId: String) async throws -> User {
        let startTime = Date()
        let cacheKey = "user-\(userId)"

        print("👤 [UserService] Fetching user: \(userId)")

        // 1. ✅ Try cache first
        if let cached = await CacheManager.shared.load(User.self, for: cacheKey) {
            let duration = Date().timeIntervalSince(startTime)
            print("✅ [UserService] CACHE HIT - User in \(String(format: "%.3f", duration))s")

            // Background sync
            Task.detached { [weak self] in
                _ = try? await self?.fetchUserFromFirestore(userId: userId)
            }

            return cached
        }

        print("⚠️ [UserService] CACHE MISS - Fetching from Firestore")

        // 2. Fetch from Firestore (or create if doesn't exist)
        return try await fetchUserFromFirestore(userId: userId)
    }

    private func fetchUserFromFirestore(userId: String) async throws -> User {
        let docRef = db.collection("users").document(userId)
        let snapshot = try await docRef.getDocument()

        // Si el documento no existe, crearlo con datos del Auth
        guard snapshot.exists else {
            print("⚠️ [UserService] User document doesn't exist, creating...")
            return try await createUserDocument(userId: userId)
        }

        // Usar custom init en vez de Firestore decoder
        let user = try User(from: snapshot)

        // Save to cache (ahora funciona porque User es Codable normal)
        let cacheKey = "user-\(userId)"
        do {
            try await CacheManager.shared.save(user, for: cacheKey)
            await CacheManager.shared.saveLastSyncTimestamp(Date(), for: cacheKey)
            print("💾 [UserService] User cached: \(userId)")
        } catch {
            print("⚠️ [UserService] Error caching user: \(error)")
        }

        return user
    }

    /// Crea documento de usuario si no existe
    private func createUserDocument(userId: String) async throws -> User {
        // Obtener datos del Auth si están disponibles
        let auth = Auth.auth()
        let currentUser = auth.currentUser

        let user = User(
            id: userId,
            email: currentUser?.email ?? "",
            displayName: currentUser?.displayName ?? "Usuario",
            photoURL: currentUser?.photoURL?.absoluteString,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Guardar en Firestore
        let docRef = db.collection("users").document(userId)
        try await docRef.setData([
            "email": user.email,
            "displayName": user.displayName,
            "photoURL": user.photoURL ?? "",
            "createdAt": Timestamp(date: user.createdAt),
            "updatedAt": Timestamp(date: user.updatedAt)
        ])

        print("✅ [UserService] User document created: \(userId)")

        // Cache
        let cacheKey = "user-\(userId)"
        do {
            try await CacheManager.shared.save(user, for: cacheKey)
            await CacheManager.shared.saveLastSyncTimestamp(Date(), for: cacheKey)
        } catch {
            print("⚠️ [UserService] Error caching new user: \(error)")
        }

        return user
    }

    // MARK: - Fetch Tried Perfumes (SUBCOLECCIÓN)

    /// ✅ OFFLINE-FIRST: Cache first, background sync
    /// Path: users/{userId}/tried_perfumes/{perfumeId}
    func fetchTriedPerfumes(for userId: String) async throws -> [TriedPerfume] {
        let startTime = Date()
        let cacheKey = "triedPerfumes-\(userId)"

        print("📥 [UserService] Fetching tried perfumes for user: \(userId)")

        // 1. Try cache first
        if let cached = await CacheManager.shared.load([TriedPerfume].self, for: cacheKey) {
            let duration = Date().timeIntervalSince(startTime)
            print("✅ [UserService] CACHE HIT - Tried perfumes (\(cached.count)) in \(String(format: "%.3f", duration))s")

            // Background sync
            Task.detached { [weak self] in
                _ = try? await self?.fetchTriedPerfumesFromFirestore(userId: userId)
            }

            return cached
        }

        print("⚠️ [UserService] CACHE MISS - Fetching from Firestore")

        // 2. Fetch from Firestore
        return try await fetchTriedPerfumesFromFirestore(userId: userId)
    }

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
            print("💾 [UserService] Tried perfumes cached: \(perfumes.count) items")
        } catch {
            print("⚠️ [UserService] Error caching tried perfumes: \(error)")
        }

        print("✅ [UserService] Tried perfumes fetched: \(perfumes.count) items")
        return perfumes
    }

    // MARK: - Fetch Wishlist (SUBCOLECCIÓN)

    /// ✅ OFFLINE-FIRST: Cache first, background sync
    /// Path: users/{userId}/wishlist/{perfumeId}
    func fetchWishlist(for userId: String) async throws -> [WishlistItem] {
        let startTime = Date()
        let cacheKey = "wishlist-\(userId)"

        print("📥 [UserService] Fetching wishlist for user: \(userId)")

        // 1. Try cache first
        if let cached = await CacheManager.shared.load([WishlistItem].self, for: cacheKey) {
            let duration = Date().timeIntervalSince(startTime)
            print("✅ [UserService] CACHE HIT - Wishlist (\(cached.count)) in \(String(format: "%.3f", duration))s")

            // Background sync
            Task.detached { [weak self] in
                _ = try? await self?.fetchWishlistFromFirestore(userId: userId)
            }

            return cached
        }

        print("⚠️ [UserService] CACHE MISS - Fetching from Firestore")

        // 2. Fetch from Firestore
        return try await fetchWishlistFromFirestore(userId: userId)
    }

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
            print("💾 [UserService] Wishlist cached: \(items.count) items")
        } catch {
            print("⚠️ [UserService] Error caching wishlist: \(error)")
        }

        print("✅ [UserService] Wishlist fetched: \(items.count) items")
        return items
    }

    // MARK: - Add/Remove Tried Perfume (SUBCOLECCIÓN)

    func addTriedPerfume(userId: String, perfumeId: String, rating: Double, userProjection: String?, userDuration: String?, userPrice: String?, notes: String?, userSeasons: [String]?, userPersonalities: [String]?) async throws {
        print("➕ [UserService] Adding tried perfume: \(perfumeId)")

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

        print("✅ [UserService] Tried perfume added")
    }

    func updateTriedPerfume(userId: String, _ triedPerfume: TriedPerfume) async throws {
        print("🔄 [UserService] Updating tried perfume: \(triedPerfume.perfumeId)")

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

        print("✅ [UserService] Tried perfume updated")
    }

    func removeTriedPerfume(userId: String, perfumeId: String) async throws {
        print("➖ [UserService] Removing tried perfume: \(perfumeId)")

        let docRef = db.collection("users")
            .document(userId)
            .collection("tried_perfumes")
            .document(perfumeId)

        try await docRef.delete()

        // Invalidar caché
        let cacheKey = "triedPerfumes-\(userId)"
        await CacheManager.shared.clearCache(for: cacheKey)

        print("✅ [UserService] Tried perfume removed")
    }

    // MARK: - Add/Remove Wishlist (SUBCOLECCIÓN)

    func addToWishlist(userId: String, perfumeId: String, notes: String?, priority: Int?) async throws {
        print("➕ [UserService] Adding to wishlist: \(perfumeId)")

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

        print("✅ [UserService] Added to wishlist")
    }

    func removeFromWishlist(userId: String, perfumeId: String) async throws {
        print("➖ [UserService] Removing from wishlist: \(perfumeId)")

        let docRef = db.collection("users")
            .document(userId)
            .collection("wishlist")
            .document(perfumeId)

        try await docRef.delete()

        // Invalidar caché
        let cacheKey = "wishlist-\(userId)"
        await CacheManager.shared.clearCache(for: cacheKey)

        print("✅ [UserService] Removed from wishlist")
    }

    func updateWishlistItem(userId: String, _ item: WishlistItem) async throws {
        print("🔄 [UserService] Updating wishlist item: \(item.perfumeId)")

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

        print("✅ [UserService] Wishlist item updated")
    }
}
