import Foundation
import FirebaseFirestore

/// ✅ REFACTOR: Modelo para wishlist (estructura NESTED)
/// - Path: users/{userId}/wishlist/{perfumeId}
/// - userId ya NO necesita guardarse (está en el path)
struct WishlistItem: Identifiable, Codable, Equatable, Hashable {
    @DocumentID var id: String? // Será el perfumeId
    var perfumeId: String
    var notes: String?
    var priority: Int? // 1=alta, 2=media, 3=baja
    var addedAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
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
