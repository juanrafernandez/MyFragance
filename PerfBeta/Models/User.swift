import Foundation
import FirebaseFirestore

/// ✅ REFACTOR: Modelo de usuario con estructura NESTED
/// - Documento principal: users/{userId}
/// - Subcolecciones: tried_perfumes, wishlist, olfactive_profiles
/// - Sin @DocumentID para poder cachear con CacheManager
struct User: Identifiable, Codable, Equatable {
    var id: String  // NO @DocumentID para poder cachear
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
        id: String,
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

    /// Custom decoder para Firestore
    init(from document: DocumentSnapshot) throws {
        let data = document.data() ?? [:]

        self.id = document.documentID
        self.email = data["email"] as? String ?? ""
        self.displayName = data["displayName"] as? String ?? ""
        self.photoURL = data["photoURL"] as? String

        if let timestamp = data["createdAt"] as? Timestamp {
            self.createdAt = timestamp.dateValue()
        } else {
            self.createdAt = Date()
        }

        if let timestamp = data["updatedAt"] as? Timestamp {
            self.updatedAt = timestamp.dateValue()
        } else {
            self.updatedAt = Date()
        }
    }
}
