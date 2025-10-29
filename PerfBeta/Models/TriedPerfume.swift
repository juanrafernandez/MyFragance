import Foundation
import FirebaseFirestore

/// ✅ REFACTOR: Modelo simplificado para perfumes probados
/// - Estructura flat: user_tried_perfumes/{userId}_{perfumeId}
/// - Solo guarda opiniones del usuario (no datos del perfume)
/// - Caché permanente para carga instantánea
struct TriedPerfume: Identifiable, Codable, Equatable {
    @DocumentID var id: String?  // userId_perfumeId (solo para Firestore)
    let userId: String
    let perfumeId: String

    // Opiniones del usuario sobre el perfume
    var rating: Double
    var userPersonalities: [String]?  // Sus percepciones de personalidad
    var userSeasons: [String]?        // Cuándo le gusta usarlo
    var userProjection: String?       // Su experiencia de proyección
    var userDuration: String?         // Su experiencia de duración
    var userPrice: String?            // Lo que pagó/cree que vale
    var notes: String?                // Notas personales/impresiones

    // Metadata
    var triedAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case userId, perfumeId
        case rating
        case userPersonalities, userSeasons
        case userProjection, userDuration, userPrice
        case notes
        case triedAt, updatedAt
        // NOTE: 'id' is NOT in CodingKeys - handled by @DocumentID for Firestore only
    }

    static func == (lhs: TriedPerfume, rhs: TriedPerfume) -> Bool {
        return lhs.userId == rhs.userId && lhs.perfumeId == rhs.perfumeId
    }
}
