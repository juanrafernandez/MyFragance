import FirebaseFirestore
import FirebaseAuth

// MARK: - Protocol

protocol UserProfileServiceProtocol {
    func fetchUser(by userId: String) async throws -> User
}

// MARK: - Implementation

/// Service responsible for user profile management
/// Handles user document creation and retrieval from Firestore
final class UserProfileService: UserProfileServiceProtocol {
    private let db: Firestore

    init(firestore: Firestore = Firestore.firestore()) {
        self.db = firestore
    }

    // MARK: - Fetch User

    /// ✅ OFFLINE-FIRST: Cache first, network fallback, auto-create if missing
    func fetchUser(by userId: String) async throws -> User {
        let startTime = Date()
        let cacheKey = "user-\(userId)"

        print("👤 [UserProfileService] Fetching user: \(userId)")

        // 1. ✅ Try cache first
        if let cached = await CacheManager.shared.load(User.self, for: cacheKey) {
            let duration = Date().timeIntervalSince(startTime)
            print("✅ [UserProfileService] CACHE HIT - User in \(String(format: "%.3f", duration))s")

            // Background sync
            Task.detached { [weak self] in
                _ = try? await self?.fetchUserFromFirestore(userId: userId)
            }

            return cached
        }

        print("⚠️ [UserProfileService] CACHE MISS - Fetching from Firestore")

        // 2. Fetch from Firestore (or create if doesn't exist)
        return try await fetchUserFromFirestore(userId: userId)
    }

    // MARK: - Private Methods

    private func fetchUserFromFirestore(userId: String) async throws -> User {
        let docRef = db.collection("users").document(userId)
        let snapshot = try await docRef.getDocument()

        // Si el documento no existe, crearlo con datos del Auth
        guard snapshot.exists else {
            print("⚠️ [UserProfileService] User document doesn't exist, creating...")
            return try await createUserDocument(userId: userId)
        }

        // Usar custom init en vez de Firestore decoder
        let user = try User(from: snapshot)

        // Save to cache
        let cacheKey = "user-\(userId)"
        do {
            try await CacheManager.shared.save(user, for: cacheKey)
            await CacheManager.shared.saveLastSyncTimestamp(Date(), for: cacheKey)
            print("💾 [UserProfileService] User cached: \(userId)")
        } catch {
            print("⚠️ [UserProfileService] Error caching user: \(error)")
        }

        return user
    }

    /// Creates user document if it doesn't exist
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

        print("✅ [UserProfileService] User document created: \(userId)")

        // Cache
        let cacheKey = "user-\(userId)"
        do {
            try await CacheManager.shared.save(user, for: cacheKey)
            await CacheManager.shared.saveLastSyncTimestamp(Date(), for: cacheKey)
        } catch {
            print("⚠️ [UserProfileService] Error caching new user: \(error)")
        }

        return user
    }
}
