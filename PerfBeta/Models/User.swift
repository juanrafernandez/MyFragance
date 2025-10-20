import Foundation

struct User: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var email: String
    var preferences: [String: String]
    var favoritePerfumes: [String]
    var triedPerfumes: [String]
    var wishlistPerfumes: [String]
    var createdAt: Date?
    var updatedAt: Date?
    var lastLoginAt: Date?

    init(id: String, name: String, email: String, preferences: [String: String], favoritePerfumes: [String], triedPerfumes: [String], wishlistPerfumes: [String], createdAt: Date?, updatedAt: Date?, lastLoginAt: Date?) {
        self.id = id
        self.name = name
        self.email = email
        self.preferences = preferences
        self.favoritePerfumes = favoritePerfumes
        self.triedPerfumes = triedPerfumes
        self.wishlistPerfumes = wishlistPerfumes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastLoginAt = lastLoginAt
    }
}
