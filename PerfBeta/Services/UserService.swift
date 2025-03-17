import FirebaseFirestore

protocol UserServiceProtocol {
    func fetchUser(by userId: String) async throws -> User
    func fetchWishlist(for userId: String) async throws -> [WishlistItem] // MODIFIED: Return [WishlistItem]
    func fetchTriedPerfumes(for userId: String) async throws -> [TriedPerfumeRecord]
    func fetchOlfactiveProfiles(for userId: String) async throws -> [OlfactiveProfile]

    func addToWishlist(userId: String, wishlistItem: WishlistItem) async throws // MODIFIED: Accept WishlistItem
    func addTriedPerfume(userId: String, perfumeId: String, perfumeKey: String, brandId: String, projection: String, duration: String, price: String, rating: Double, impressions: String,occasions: [String]?, seasons: [String]?,personalities: [String]?) async throws
    func fetchPerfume(by perfumeId: String, brandId: String, perfumeKey: String) async throws -> Perfume?
    func deleteTriedPerfumeRecord(recordId: String) async throws
    func updateTriedPerfumeRecord(record: TriedPerfumeRecord) async throws -> Bool
    func fetchTriedPerfumeRecord(recordId: String) async throws -> TriedPerfumeRecord?
    func removeFromWishlist(userId: String, wishlistItem: WishlistItem) async throws // NEW: removeFromWishlist with WishlistItem
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

    func fetchWishlist(for userId: String) async throws -> [WishlistItem] { // MODIFIED: Return [WishlistItem]
        let snapshot = try await db.collection("users/\(userId)/wishlist").getDocuments()
        return snapshot.documents.compactMap { document in
            var wishlistItem = try? document.data(as: WishlistItem.self)
            wishlistItem?.id = document.documentID // Set document ID to WishlistItem.id if needed
            return wishlistItem
        }.compactMap { $0 }
    }

    func fetchTriedPerfumes(for userId: String) async throws -> [TriedPerfumeRecord] {
        let snapshot = try await db.collection("users/\(userId)/triedPerfumes").getDocuments()
        return snapshot.documents.compactMap { document in
            var triedPerfume = try? document.data(as: TriedPerfumeRecord.self)
            triedPerfume?.id = document.documentID // Set document ID to TriedPerfumeRecord.id
            return triedPerfume
        }.compactMap { $0 } // Remove nil values after setting document ID
    }

    func fetchOlfactiveProfiles(for userId: String) async throws -> [OlfactiveProfile] {
        let snapshot = try await db.collection("users/\(userId)/olfactiveProfiles").getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: OlfactiveProfile.self) }
    }

    // MARK: - Functions to add implementations

    func addToWishlist(userId: String, wishlistItem: WishlistItem) async throws { // MODIFIED: Accept WishlistItem
        let wishlistCollection = db.collection("users").document(userId).collection("wishlist")

        // Use composite document ID: "brandKey_perfumeKey" for WishlistItem
        let documentID = "\(wishlistItem.brandKey)_\(wishlistItem.perfumeKey)"

        // Store the WishlistItem data
        try await wishlistCollection.document(documentID).setData([
            "perfumeKey": wishlistItem.perfumeKey,
            "brandKey": wishlistItem.brandKey,
            "imageURL": wishlistItem.imageURL as Any, // Store imageURL, use `as Any` to handle optional String
            "rating": wishlistItem.rating,
            "id": documentID // Store composite ID as 'id' field as well for easier retrieval
        ])
    }


    func addTriedPerfume(userId: String, perfumeId: String, perfumeKey: String, brandId: String, projection: String, duration: String, price: String, rating: Double, impressions: String, occasions: [String]?, seasons: [String]?, personalities: [String]?) throws {
        let triedPerfumesCollection = db.collection("users").document(userId).collection("triedPerfumes")

        let triedPerfumeRecord = TriedPerfumeRecord(
            id: perfumeKey, // Let Firestore generate the ID
            userId: userId, // Pass userId here
            perfumeId: perfumeId,
            perfumeKey: perfumeKey,
            brandId: brandId,
            projection: projection,
            duration: duration,
            price: price,
            rating: rating,
            impressions: impressions,
            occasions: occasions,
            seasons: seasons,
            personalities: personalities,
            createdAt: nil, // Let Firestore handle timestamp
            updatedAt: nil  // Let Firestore handle timestamp
        )

        // Add the new tried perfume record to the collection
        try triedPerfumesCollection.addDocument(from: triedPerfumeRecord)
    }

    // MARK: - NEW: fetchPerfume by perfumeId (No Changes)
    func fetchPerfume(by perfumeId: String, brandId: String, perfumeKey: String) async throws -> Perfume? {
        do {
            let document = try await db.collection("perfumes").document("es").collection(brandId).document(perfumeKey).getDocument()
            return try document.data(as: Perfume.self)
        } catch {
            throw error
        }
    }

    // MARK: - NEW: deleteTriedPerfumeRecord (No Changes)
    func deleteTriedPerfumeRecord(recordId: String) async throws { // MODIFIED: Removed userId parameter
        let documentRef = db.collection("users").document("testUserId").collection("triedPerfumes").document(recordId) // MODIFIED: Removed userId parameter
        do {
            try await documentRef.delete()
        } catch {
            print("Error deleting tried perfume record from Firestore: \(error)")
            throw error // Re-throw the error to be handled by the caller
        }
    }

    // MARK: - NEW: updateTriedPerfumeRecord - Implementation for UserService (No Changes)
    func updateTriedPerfumeRecord(record: TriedPerfumeRecord) async throws -> Bool {
        guard let recordId = record.id else {
            print("Error: TriedPerfumeRecord has no ID for update.")
            return false // Indicate failure if record has no ID
        }

        let documentRef = db.collection("users").document(record.userId).collection("triedPerfumes").document(recordId) // Assuming userId is in record
        do {
            // Use Firestore's `setData(from: record, merge: true)` to update the document
            try documentRef.setData(from: record, merge: true)
            print("TriedPerfumeRecord updated successfully in Firestore for ID: \(recordId)")
            return true // Indicate successful update
        } catch {
            print("Error updating tried perfume record in Firestore: \(error)")
            return false // Indicate update failure
        }
    }

    // MARK: - NEW: fetchTriedPerfumeRecord by recordId (No Changes)
    func fetchTriedPerfumeRecord(recordId: String) async throws -> TriedPerfumeRecord? {
        let documentRef = db.collection("users").document("testUserId").collection("triedPerfumes").document(recordId) // Replace "testUserId" if needed, or pass userId as argument if necessary
        do {
            let documentSnapshot = try await documentRef.getDocument()
            return try documentSnapshot.data(as: TriedPerfumeRecord.self)
        } catch {
            print("Error fetching TriedPerfumeRecord from Firestore: \(error)")
            throw error
        }
    }

    // NEW: removeFromWishlist function to use WishlistItem
    func removeFromWishlist(userId: String, wishlistItem: WishlistItem) async throws {
        let wishlistCollection = db.collection("users").document(userId).collection("wishlist")

        // Construct the document ID based on perfumeKey and brandKey (same as in addToWishlist)
        let documentID = "\(wishlistItem.brandKey)_\(wishlistItem.perfumeKey)"

        try await wishlistCollection.document(documentID).delete()
    }
}
