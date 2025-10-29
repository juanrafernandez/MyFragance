import FirebaseFirestore
import FirebaseAuth

// MARK: - Protocol

protocol UserServiceProtocol {
    func fetchUser(by userId: String) async throws -> User
    func fetchTriedPerfumes(for userId: String) async throws -> [TriedPerfume]
    func fetchWishlist(for userId: String) async throws -> [WishlistItem]
    func addTriedPerfume(userId: String, perfumeId: String, rating: Double, userProjection: String?, userDuration: String?, userPrice: String?, notes: String?, userSeasons: [String]?, userPersonalities: [String]?) async throws
    func updateTriedPerfume(_ triedPerfume: TriedPerfume) async throws
    func removeTriedPerfume(userId: String, perfumeId: String) async throws
    func addToWishlist(userId: String, perfumeId: String, notes: String?, priority: Int?) async throws
    func removeFromWishlist(userId: String, perfumeId: String) async throws
    func updateWishlistItem(_ item: WishlistItem) async throws
}

// MARK: - Implementation

/// ✅ REFACTOR: User data service con estructura flat y caché permanente
/// - Colecciones flat: user_tried_perfumes, user_wishlist
/// - Caché permanente usando CacheManager (no expira)
/// - Logs con emojis + performance tracking
final class UserService: UserServiceProtocol {
    private let db: Firestore

    // ✅ NEW: Flat collections
    private let triedPerfumesCollection = "user_tried_perfumes"
    private let wishlistCollection = "user_wishlist"
    private let usersCollection = "users"

    // ✅ NEW: Permanent cache keys
    private func triedPerfumesCacheKey(userId: String) -> String {
        "triedPerfumes-\(userId)"
    }

    private func wishlistCacheKey(userId: String) -> String {
        "wishlist-\(userId)"
    }

    init(firestore: Firestore = Firestore.firestore()) {
        self.db = firestore
    }

    // MARK: - Fetch User (OFFLINE-FIRST)

    /// ✅ OFFLINE-FIRST: Cache first, network fallback
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
                await self?.syncUserInBackground(userId: userId, cacheKey: cacheKey)
            }

            return cached
        }

        print("⚠️ [UserService] CACHE MISS - Fetching from Firestore")

        // 2. Cache miss - try Firestore
        do {
            let documentRef = db.collection(usersCollection).document(userId)
            let document = try await documentRef.getDocument()

            guard document.exists, let data = document.data() else {
                print("❌ [UserService] User not found: \(userId)")
                throw NSError(domain: "UserService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Usuario no encontrado"])
            }

            let user = User(
                id: document.documentID,
                name: data["name"] as? String ?? data["nombre"] as? String ?? "Nombre no disponible",
                email: data["email"] as? String ?? "",
                preferences: data["preferences"] as? [String: String] ?? [:],
                favoritePerfumes: data["favoritePerfumes"] as? [String] ?? [],
                triedPerfumes: data["triedPerfumes"] as? [String] ?? [],
                wishlistPerfumes: data["wishlistPerfumes"] as? [String] ?? [],
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue(),
                updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue(),
                lastLoginAt: (data["lastLoginAt"] as? Timestamp)?.dateValue()
            )

            // Save to cache
            do {
                try await CacheManager.shared.save(user, for: cacheKey)
            } catch {
                print("⚠️ [UserService] Error saving user to cache: \(error)")
            }

            let duration = Date().timeIntervalSince(startTime)
            print("✅ [UserService] User fetched in \(String(format: "%.3f", duration))s")

            return user

        } catch {
            // 3. ✅ Network failed - try stale cache as last resort
            if let cached = await CacheManager.shared.load(User.self, for: cacheKey) {
                print("⚠️ [UserService] Network failed, using stale cache")
                return cached
            }

            // 4. ✅ No cache - create placeholder from Auth to avoid crashes
            print("⚠️ [UserService] No cache, creating placeholder from Auth")

            // Get info from authenticated user
            guard let currentUser = Auth.auth().currentUser else {
                print("🔴 [UserService] No Auth user available")
                throw error
            }

            let placeholderUser = User(
                id: userId,
                name: currentUser.displayName ?? "Usuario",
                email: currentUser.email ?? "usuario@email.com",
                preferences: [:],
                favoritePerfumes: [],
                triedPerfumes: [],
                wishlistPerfumes: [],
                createdAt: Date(),
                updatedAt: Date(),
                lastLoginAt: Date()
            )

            // Save placeholder to cache for next launch
            do {
                try await CacheManager.shared.save(placeholderUser, for: cacheKey)
                print("💾 [UserService] Placeholder user cached")
            } catch {
                print("⚠️ [UserService] Could not cache placeholder: \(error)")
            }

            return placeholderUser
        }
    }

    private func syncUserInBackground(userId: String, cacheKey: String) async {
        print("🔄 [UserService] Background sync user...")

        do {
            let documentRef = db.collection(usersCollection).document(userId)
            let document = try await documentRef.getDocument()

            guard document.exists, let data = document.data() else { return }

            let user = User(
                id: document.documentID,
                name: data["name"] as? String ?? data["nombre"] as? String ?? "Nombre no disponible",
                email: data["email"] as? String ?? "",
                preferences: data["preferences"] as? [String: String] ?? [:],
                favoritePerfumes: data["favoritePerfumes"] as? [String] ?? [],
                triedPerfumes: data["triedPerfumes"] as? [String] ?? [],
                wishlistPerfumes: data["wishlistPerfumes"] as? [String] ?? [],
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue(),
                updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue(),
                lastLoginAt: (data["lastLoginAt"] as? Timestamp)?.dateValue()
            )

            try await CacheManager.shared.save(user, for: cacheKey)
            print("✅ [UserService] Background sync user completed")
        } catch {
            print("⚠️ [UserService] Background sync user failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Tried Perfumes (OFFLINE-FIRST)

    /// ✅ OFFLINE-FIRST: Cache first, background sync, network fallback
    func fetchTriedPerfumes(for userId: String) async throws -> [TriedPerfume] {
        let startTime = Date()
        let cacheKey = triedPerfumesCacheKey(userId: userId)

        print("📥 [UserService] Fetching tried perfumes for user: \(userId)")

        // 1. ✅ Try cache first
        if let cached = await CacheManager.shared.load([TriedPerfume].self, for: cacheKey) {
            let duration = Date().timeIntervalSince(startTime)
            print("✅ [UserService] CACHE HIT - Tried perfumes (\(cached.count) items) in \(String(format: "%.3f", duration))s")

            // Background sync (non-blocking)
            Task.detached { [weak self] in
                await self?.syncTriedPerfumesInBackground(userId: userId, cacheKey: cacheKey)
            }

            return cached
        }

        print("⚠️ [UserService] CACHE MISS - Fetching from Firestore")

        // 2. Cache miss - try Firestore
        do {
            let query = db.collection(triedPerfumesCollection)
                .whereField("userId", isEqualTo: userId)
                .order(by: "triedAt", descending: true)

            let snapshot = try await query.getDocuments()

            let triedPerfumes = snapshot.documents.compactMap { doc -> TriedPerfume? in
                do {
                    var item = try doc.data(as: TriedPerfume.self)
                    item.id = doc.documentID
                    return item
                } catch {
                    print("❌ [UserService] Error decoding TriedPerfume \(doc.documentID): \(error)")
                    return nil
                }
            }

            // Save to cache
            do {
                try await CacheManager.shared.save(triedPerfumes, for: cacheKey)
            } catch {
                print("⚠️ [UserService] Error saving to cache: \(error)")
            }

            let duration = Date().timeIntervalSince(startTime)
            print("✅ [UserService] Tried perfumes fetched: \(triedPerfumes.count) items in \(String(format: "%.3f", duration))s")

            return triedPerfumes

        } catch {
            // 3. ✅ Network failed - try stale cache as last resort
            if let cached = await CacheManager.shared.load([TriedPerfume].self, for: cacheKey) {
                print("⚠️ [UserService] Network failed, using stale cache (\(cached.count) items)")
                return cached
            }

            // 4. No cache and network failed - propagate error
            print("🔴 [UserService] No cache and network failed")
            throw error
        }
    }

    private func syncTriedPerfumesInBackground(userId: String, cacheKey: String) async {
        print("🔄 [UserService] Background sync tried perfumes...")

        do {
            let query = db.collection(triedPerfumesCollection)
                .whereField("userId", isEqualTo: userId)
                .order(by: "triedAt", descending: true)

            let snapshot = try await query.getDocuments()

            let triedPerfumes = snapshot.documents.compactMap { doc -> TriedPerfume? in
                do {
                    var item = try doc.data(as: TriedPerfume.self)
                    item.id = doc.documentID
                    return item
                } catch {
                    return nil
                }
            }

            try await CacheManager.shared.save(triedPerfumes, for: cacheKey)
            print("✅ [UserService] Background sync tried perfumes completed: \(triedPerfumes.count) items")
        } catch {
            print("⚠️ [UserService] Background sync tried perfumes failed: \(error.localizedDescription)")
        }
    }

    /// ✅ NUEVO: Añadir perfume probado a estructura flat
    func addTriedPerfume(userId: String, perfumeId: String, rating: Double, userProjection: String?, userDuration: String?, userPrice: String?, notes: String?, userSeasons: [String]?, userPersonalities: [String]?) async throws {
        let startTime = Date()
        print("➕ [UserService] Adding tried perfume: \(perfumeId) for user: \(userId)")

        let documentId = "\(userId)_\(perfumeId)"
        let now = Date()

        let triedPerfume = TriedPerfume(
            id: nil,  // ✅ Always nil - ID is set when saving to Firestore
            userId: userId,
            perfumeId: perfumeId,
            rating: rating,
            userPersonalities: userPersonalities,
            userSeasons: userSeasons,
            userProjection: userProjection,
            userDuration: userDuration,
            userPrice: userPrice,
            notes: notes,
            triedAt: now,
            updatedAt: now
        )

        let docRef = db.collection(triedPerfumesCollection).document(documentId)

        do {
            try docRef.setData(from: triedPerfume)

            // ✅ Invalidar caché para forzar recarga
            await invalidateTriedPerfumesCache(userId: userId)

            let duration = Date().timeIntervalSince(startTime)
            print("✅ [UserService] Tried perfume added in \(String(format: "%.3f", duration))s")
        } catch {
            print("❌ [UserService] Error adding tried perfume: \(error)")
            throw error
        }
    }

    /// ✅ NUEVO: Actualizar perfume probado
    func updateTriedPerfume(_ triedPerfume: TriedPerfume) async throws {
        let startTime = Date()
        print("🔄 [UserService] Updating tried perfume: \(triedPerfume.perfumeId)")

        guard let documentId = triedPerfume.id else {
            throw NSError(domain: "UserService", code: 400, userInfo: [NSLocalizedDescriptionKey: "ID faltante"])
        }

        var updated = triedPerfume
        updated.updatedAt = Date()

        let docRef = db.collection(triedPerfumesCollection).document(documentId)

        do {
            try docRef.setData(from: updated, merge: true)

            // ✅ Invalidar caché
            await invalidateTriedPerfumesCache(userId: triedPerfume.userId)

            let duration = Date().timeIntervalSince(startTime)
            print("✅ [UserService] Tried perfume updated in \(String(format: "%.3f", duration))s")
        } catch {
            print("❌ [UserService] Error updating tried perfume: \(error)")
            throw error
        }
    }

    /// ✅ NUEVO: Eliminar perfume probado
    func removeTriedPerfume(userId: String, perfumeId: String) async throws {
        let startTime = Date()
        print("🗑️ [UserService] Removing tried perfume: \(perfumeId)")

        let documentId = "\(userId)_\(perfumeId)"
        let docRef = db.collection(triedPerfumesCollection).document(documentId)

        do {
            try await docRef.delete()

            // ✅ Invalidar caché
            await invalidateTriedPerfumesCache(userId: userId)

            let duration = Date().timeIntervalSince(startTime)
            print("✅ [UserService] Tried perfume removed in \(String(format: "%.3f", duration))s")
        } catch {
            print("❌ [UserService] Error removing tried perfume: \(error)")
            throw error
        }
    }

    // MARK: - Wishlist (OFFLINE-FIRST)

    /// ✅ OFFLINE-FIRST: Cache first, background sync, network fallback
    func fetchWishlist(for userId: String) async throws -> [WishlistItem] {
        let startTime = Date()
        let cacheKey = wishlistCacheKey(userId: userId)

        print("📥 [UserService] Fetching wishlist for user: \(userId)")

        // 1. ✅ Try cache first
        if let cached = await CacheManager.shared.load([WishlistItem].self, for: cacheKey) {
            let duration = Date().timeIntervalSince(startTime)
            print("✅ [UserService] CACHE HIT - Wishlist (\(cached.count) items) in \(String(format: "%.3f", duration))s")

            // Background sync (non-blocking)
            Task.detached { [weak self] in
                await self?.syncWishlistInBackground(userId: userId, cacheKey: cacheKey)
            }

            return cached
        }

        print("⚠️ [UserService] CACHE MISS - Fetching from Firestore")

        // 2. Cache miss - try Firestore
        do {
            let query = db.collection(wishlistCollection)
                .whereField("userId", isEqualTo: userId)
                .order(by: "addedAt", descending: false)

            let snapshot = try await query.getDocuments()

            let wishlistItems = snapshot.documents.compactMap { doc -> WishlistItem? in
                do {
                    var item = try doc.data(as: WishlistItem.self)
                    item.id = doc.documentID
                    return item
                } catch {
                    print("❌ [UserService] Error decoding WishlistItem \(doc.documentID): \(error)")
                    return nil
                }
            }

            // Save to cache
            do {
                try await CacheManager.shared.save(wishlistItems, for: cacheKey)
            } catch {
                print("⚠️ [UserService] Error saving to cache: \(error)")
            }

            let duration = Date().timeIntervalSince(startTime)
            print("✅ [UserService] Wishlist fetched: \(wishlistItems.count) items in \(String(format: "%.3f", duration))s")

            return wishlistItems

        } catch {
            // 3. ✅ Network failed - try stale cache as last resort
            if let cached = await CacheManager.shared.load([WishlistItem].self, for: cacheKey) {
                print("⚠️ [UserService] Network failed, using stale cache (\(cached.count) items)")
                return cached
            }

            // 4. No cache and network failed - propagate error
            print("🔴 [UserService] No cache and network failed")
            throw error
        }
    }

    private func syncWishlistInBackground(userId: String, cacheKey: String) async {
        print("🔄 [UserService] Background sync wishlist...")

        do {
            let query = db.collection(wishlistCollection)
                .whereField("userId", isEqualTo: userId)
                .order(by: "addedAt", descending: false)

            let snapshot = try await query.getDocuments()

            let wishlistItems = snapshot.documents.compactMap { doc -> WishlistItem? in
                do {
                    var item = try doc.data(as: WishlistItem.self)
                    item.id = doc.documentID
                    return item
                } catch {
                    return nil
                }
            }

            try await CacheManager.shared.save(wishlistItems, for: cacheKey)
            print("✅ [UserService] Background sync wishlist completed: \(wishlistItems.count) items")
        } catch {
            print("⚠️ [UserService] Background sync wishlist failed: \(error.localizedDescription)")
        }
    }

    /// ✅ NUEVO: Añadir a wishlist
    func addToWishlist(userId: String, perfumeId: String, notes: String?, priority: Int?) async throws {
        let startTime = Date()
        print("➕ [UserService] Adding to wishlist: \(perfumeId)")

        let documentId = "\(userId)_\(perfumeId)"
        let now = Date()

        let wishlistItem = WishlistItem(
            id: nil,  // ✅ Always nil - ID is set when saving to Firestore
            userId: userId,
            perfumeId: perfumeId,
            notes: notes,
            priority: priority,
            addedAt: now,
            updatedAt: now
        )

        let docRef = db.collection(wishlistCollection).document(documentId)

        do {
            try docRef.setData(from: wishlistItem)

            // ✅ Invalidar caché
            await invalidateWishlistCache(userId: userId)

            let duration = Date().timeIntervalSince(startTime)
            print("✅ [UserService] Added to wishlist in \(String(format: "%.3f", duration))s")
        } catch {
            print("❌ [UserService] Error adding to wishlist: \(error)")
            throw error
        }
    }

    /// ✅ NUEVO: Eliminar de wishlist
    func removeFromWishlist(userId: String, perfumeId: String) async throws {
        let startTime = Date()
        print("🗑️ [UserService] Removing from wishlist: \(perfumeId)")

        let documentId = "\(userId)_\(perfumeId)"
        let docRef = db.collection(wishlistCollection).document(documentId)

        do {
            try await docRef.delete()

            // ✅ Invalidar caché
            await invalidateWishlistCache(userId: userId)

            let duration = Date().timeIntervalSince(startTime)
            print("✅ [UserService] Removed from wishlist in \(String(format: "%.3f", duration))s")
        } catch {
            print("❌ [UserService] Error removing from wishlist: \(error)")
            throw error
        }
    }

    /// ✅ NUEVO: Actualizar item de wishlist
    func updateWishlistItem(_ item: WishlistItem) async throws {
        let startTime = Date()
        print("🔄 [UserService] Updating wishlist item: \(item.perfumeId)")

        guard let documentId = item.id else {
            throw NSError(domain: "UserService", code: 400, userInfo: [NSLocalizedDescriptionKey: "ID faltante"])
        }

        var updated = item
        updated.updatedAt = Date()

        let docRef = db.collection(wishlistCollection).document(documentId)

        do {
            try docRef.setData(from: updated, merge: true)

            // ✅ Invalidar caché
            await invalidateWishlistCache(userId: item.userId)

            let duration = Date().timeIntervalSince(startTime)
            print("✅ [UserService] Wishlist item updated in \(String(format: "%.3f", duration))s")
        } catch {
            print("❌ [UserService] Error updating wishlist item: \(error)")
            throw error
        }
    }

    // MARK: - Cache Invalidation

    private func invalidateTriedPerfumesCache(userId: String) async {
        let cacheKey = triedPerfumesCacheKey(userId: userId)
        await CacheManager.shared.clearCache(for: cacheKey)
        print("🗑️ [UserService] Tried perfumes cache invalidated for user: \(userId)")
    }

    private func invalidateWishlistCache(userId: String) async {
        let cacheKey = wishlistCacheKey(userId: userId)
        await CacheManager.shared.clearCache(for: cacheKey)
        print("🗑️ [UserService] Wishlist cache invalidated for user: \(userId)")
    }
}
