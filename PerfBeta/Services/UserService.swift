import FirebaseFirestore

protocol UserServiceProtocol {
    func fetchUser(by userId: String) async throws -> User
    func fetchWishlist(for userId: String) async throws -> [Perfume]
    func fetchTriedPerfumes(for userId: String) async throws -> [Perfume]
    func fetchOlfactiveProfiles(for userId: String) async throws -> [OlfactiveProfile]
}

final class UserService: UserServiceProtocol {
    private let db: Firestore
    
    init(firestore: Firestore = Firestore.firestore()) {
        self.db = firestore
    }

    func fetchUser(by userId: String) async throws -> User {
        let documentRef = db.collection("users").document(userId)
        let document = try await documentRef.getDocument()
        
        guard let data = document.data() else {
            throw NSError(domain: "UserService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Usuario no encontrado"])
        }

        return User(
            id: data["id"] as? String ?? document.documentID,
            name: data["name"] as? String ?? "Desconocido",
            email: data["email"] as? String ?? "",
            preferences: data["preferences"] as? [String: String] ?? [:],
            favoritePerfumes: data["favoritePerfumes"] as? [String] ?? [],
            triedPerfumes: data["triedPerfumes"] as? [String] ?? [],
            wishlistPerfumes: data["wishlistPerfumes"] as? [String] ?? [],
            createdAt: (data["createdAt"] as? Timestamp)?.dateValue(),
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue()
        )
    }

    func fetchWishlist(for userId: String) async throws -> [Perfume] {
        let snapshot = try await db.collection("users/\(userId)/wishlist").getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Perfume.self) }
    }

    func fetchTriedPerfumes(for userId: String) async throws -> [Perfume] {
        let snapshot = try await db.collection("users/\(userId)/triedPerfumes").getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Perfume.self) }
    }

    func fetchOlfactiveProfiles(for userId: String) async throws -> [OlfactiveProfile] {
        let snapshot = try await db.collection("users/\(userId)/olfactiveProfiles").getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: OlfactiveProfile.self) }
    }
}
