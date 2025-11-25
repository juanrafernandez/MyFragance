import Foundation
import FirebaseFirestore

/// ✅ REFACTOR: Modelo para perfumes probados (estructura NESTED)
/// - Path: users/{userId}/tried_perfumes/{perfumeId}
/// - userId ya NO necesita guardarse (está en el path)
/// - Solo guarda opiniones del usuario
/// ✅ CACHE-COMPATIBLE: No usa @DocumentID para ser compatible con JSONEncoder
struct TriedPerfume: Identifiable, Codable, Equatable {
    var id: String? // Document ID - asignado manualmente desde Firestore
    var perfumeId: String
    var rating: Double
    var notes: String
    var triedAt: Date
    var updatedAt: Date
    var userPersonalities: [String]
    var userPrice: String
    var userSeasons: [String]
    var userProjection: String?
    var userDuration: String?

    enum CodingKeys: String, CodingKey {
        case id
        case perfumeId
        case rating
        case notes
        case triedAt
        case updatedAt
        case userPersonalities
        case userPrice
        case userSeasons
        case userProjection
        case userDuration
    }

    init(
        id: String? = nil,
        perfumeId: String,
        rating: Double = 0,
        notes: String = "",
        triedAt: Date = Date(),
        updatedAt: Date = Date(),
        userPersonalities: [String] = [],
        userPrice: String = "",
        userSeasons: [String] = [],
        userProjection: String? = nil,
        userDuration: String? = nil
    ) {
        self.id = id
        self.perfumeId = perfumeId
        self.rating = rating
        self.notes = notes
        self.triedAt = triedAt
        self.updatedAt = updatedAt
        self.userPersonalities = userPersonalities
        self.userPrice = userPrice
        self.userSeasons = userSeasons
        self.userProjection = userProjection
        self.userDuration = userDuration
    }

    static func == (lhs: TriedPerfume, rhs: TriedPerfume) -> Bool {
        return lhs.perfumeId == rhs.perfumeId
    }
}
