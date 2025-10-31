import Foundation
import FirebaseFirestore

/// ✅ REFACTOR: Modelo para wishlist (estructura NESTED)
/// - Path: users/{userId}/wishlist/{perfumeId}
/// - userId ya NO necesita guardarse (está en el path)
struct WishlistItem: Identifiable, Equatable, Hashable {
    @DocumentID var id: String? // Será el perfumeId
    var perfumeId: String
    var notes: String?
    var priority: Int? // 1=alta, 2=media, 3=baja
    var addedAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        // Note: 'id' is excluded because @DocumentID is not JSON-encodable
        case perfumeId
        case notes
        case priority
        case addedAt
        case updatedAt
    }

    init(
        id: String? = nil,
        perfumeId: String,
        notes: String? = nil,
        priority: Int? = nil,
        addedAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.perfumeId = perfumeId
        self.notes = notes
        self.priority = priority
        self.addedAt = addedAt
        self.updatedAt = updatedAt
    }

    static func == (lhs: WishlistItem, rhs: WishlistItem) -> Bool {
        return lhs.perfumeId == rhs.perfumeId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(perfumeId)
    }
}

// MARK: - Codable Implementation
extension WishlistItem: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // @DocumentID is handled by Firestore, not included in JSON
        self.id = nil
        self.perfumeId = try container.decode(String.self, forKey: .perfumeId)
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes)
        self.priority = try container.decodeIfPresent(Int.self, forKey: .priority)
        self.addedAt = try container.decode(Date.self, forKey: .addedAt)
        self.updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        // @DocumentID is excluded from encoding (Firebase manages it)
        try container.encode(perfumeId, forKey: .perfumeId)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(priority, forKey: .priority)
        try container.encode(addedAt, forKey: .addedAt)
        try container.encode(updatedAt, forKey: .updatedAt)
    }
}
