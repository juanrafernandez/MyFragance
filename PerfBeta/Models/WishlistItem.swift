import Foundation
import FirebaseFirestore

/// ✅ REFACTOR: Modelo simplificado para wishlist
/// - Estructura flat: user_wishlist/{userId}_{perfumeId}
/// - Solo guarda referencia al perfume + metadata del usuario
/// - Caché permanente para carga instantánea
struct WishlistItem: Identifiable, Codable, Equatable, Hashable {
    @DocumentID var id: String?  // userId_perfumeId (solo para Firestore)
    let userId: String
    let perfumeId: String

    var notes: String?
    var priority: Int?  // 1=alta, 2=media, 3=baja
    var addedAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case userId, perfumeId
        case notes, priority
        case addedAt, updatedAt
        // NOTE: 'id' is NOT in CodingKeys - handled by @DocumentID for Firestore only
    }

    static func == (lhs: WishlistItem, rhs: WishlistItem) -> Bool {
        return lhs.userId == rhs.userId && lhs.perfumeId == rhs.perfumeId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(userId)
        hasher.combine(perfumeId)
    }
}
