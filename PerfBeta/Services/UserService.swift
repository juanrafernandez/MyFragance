import FirebaseFirestore
import FirebaseAuth

// MARK: - Protocol

protocol UserServiceProtocol {
    func fetchUser(by userId: String) async throws -> User
    func fetchTriedPerfumes(for userId: String) async throws -> [TriedPerfume]
    func fetchWishlist(for userId: String) async throws -> [WishlistItem]
    func addTriedPerfume(userId: String, perfumeId: String, rating: Double, userProjection: String?, userDuration: String?, userPrice: String?, notes: String?, userSeasons: [String]?, userPersonalities: [String]?) async throws
    func updateTriedPerfume(userId: String, _ triedPerfume: TriedPerfume) async throws
    func removeTriedPerfume(userId: String, perfumeId: String) async throws
    func addToWishlist(userId: String, perfumeId: String, notes: String?, priority: Int?) async throws
    func removeFromWishlist(userId: String, perfumeId: String) async throws
    func updateWishlistItem(userId: String, _ item: WishlistItem) async throws
}

// MARK: - Implementation

/// ✅ REFACTORED: UserService now acts as a Facade delegating to specialized services
/// This maintains backward compatibility while following Single Responsibility Principle
///
/// Delegates to:
/// - UserProfileService: User profile management
/// - TriedPerfumeService: Tried perfumes CRUD
/// - WishlistService: Wishlist CRUD
final class UserService: UserServiceProtocol {
    private let userProfileService: UserProfileServiceProtocol
    private let triedPerfumeService: TriedPerfumeServiceProtocol
    private let wishlistService: WishlistServiceProtocol

    init(
        userProfileService: UserProfileServiceProtocol = UserProfileService(),
        triedPerfumeService: TriedPerfumeServiceProtocol = TriedPerfumeService(),
        wishlistService: WishlistServiceProtocol = WishlistService()
    ) {
        self.userProfileService = userProfileService
        self.triedPerfumeService = triedPerfumeService
        self.wishlistService = wishlistService
    }

    // MARK: - User Profile Delegation

    func fetchUser(by userId: String) async throws -> User {
        try await userProfileService.fetchUser(by: userId)
    }

    // MARK: - Tried Perfumes Delegation

    func fetchTriedPerfumes(for userId: String) async throws -> [TriedPerfume] {
        try await triedPerfumeService.fetchTriedPerfumes(for: userId)
    }

    func addTriedPerfume(userId: String, perfumeId: String, rating: Double, userProjection: String?, userDuration: String?, userPrice: String?, notes: String?, userSeasons: [String]?, userPersonalities: [String]?) async throws {
        try await triedPerfumeService.addTriedPerfume(
            userId: userId,
            perfumeId: perfumeId,
            rating: rating,
            userProjection: userProjection,
            userDuration: userDuration,
            userPrice: userPrice,
            notes: notes,
            userSeasons: userSeasons,
            userPersonalities: userPersonalities
        )
    }

    func updateTriedPerfume(userId: String, _ triedPerfume: TriedPerfume) async throws {
        try await triedPerfumeService.updateTriedPerfume(userId: userId, triedPerfume)
    }

    func removeTriedPerfume(userId: String, perfumeId: String) async throws {
        try await triedPerfumeService.removeTriedPerfume(userId: userId, perfumeId: perfumeId)
    }

    // MARK: - Wishlist Delegation

    func fetchWishlist(for userId: String) async throws -> [WishlistItem] {
        try await wishlistService.fetchWishlist(for: userId)
    }

    func addToWishlist(userId: String, perfumeId: String, notes: String?, priority: Int?) async throws {
        try await wishlistService.addToWishlist(
            userId: userId,
            perfumeId: perfumeId,
            notes: notes,
            priority: priority
        )
    }

    func removeFromWishlist(userId: String, perfumeId: String) async throws {
        try await wishlistService.removeFromWishlist(userId: userId, perfumeId: perfumeId)
    }

    func updateWishlistItem(userId: String, _ item: WishlistItem) async throws {
        try await wishlistService.updateWishlistItem(userId: userId, item)
    }
}
