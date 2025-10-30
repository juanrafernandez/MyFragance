import Foundation
import FirebaseFirestore

/// ✅ REFACTOR: Modelo de usuario con estructura NESTED
/// - Documento principal: users/{userId}
/// - Subcolecciones: tried_perfumes, wishlist, olfactive_profiles
struct User: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    var email: String
    var displayName: String
    var photoURL: String?
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case displayName
        case photoURL
        case createdAt
        case updatedAt
    }

    init(
        id: String? = nil,
        email: String,
        displayName: String,
        photoURL: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
