import FirebaseFirestore

protocol UserServiceProtocol {
    func fetchUser(by userId: String) async throws -> User
    func fetchWishlist(for userId: String) async throws -> [WishlistItem]
    func fetchTriedPerfumes(for userId: String) async throws -> [TriedPerfumeRecord]
    func addToWishlist(userId: String, wishlistItem: WishlistItem) async throws
    func addTriedPerfume(userId: String, perfumeId: String, perfumeKey: String, brandId: String, projection: String, duration: String, price: String, rating: Double, impressions: String,occasions: [String]?, seasons: [String]?,personalities: [String]?) async throws
    func fetchPerfume(by perfumeId: String, brandId: String, perfumeKey: String) async throws -> Perfume?
    func deleteTriedPerfumeRecord(userId: String, recordId: String) async throws
    func updateTriedPerfumeRecord(record: TriedPerfumeRecord) async throws -> Bool
    func fetchTriedPerfumeRecord(userId: String, recordId: String) async throws -> TriedPerfumeRecord?
    func removeFromWishlist(userId: String, wishlistItem: WishlistItem) async throws
    func updateWishlistOrder(userId: String, orderedItems: [WishlistItem]) async throws
}

final class UserService: UserServiceProtocol {
    private let db: Firestore
    private let usersCollection = "users"
    private let triedPerfumesSubcollection = "triedPerfumes"
    private let wishlistSubcollection = "wishlist"
    private let perfumesCollection = "perfumes"


    init(firestore: Firestore = Firestore.firestore()) {
        self.db = firestore
    }

    func fetchUser(by userId: String) async throws -> User {
        let documentRef = db.collection(usersCollection).document(userId)
        let document = try await documentRef.getDocument()

        guard document.exists, let data = document.data() else {
            print("UserService: No user document found for ID \(userId)")
            throw NSError(domain: "UserService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Usuario no encontrado"])
        }

        let id = document.documentID
        let name = data["name"] as? String ?? data["nombre"] as? String ?? "Nombre no disponible"
        let email = data["email"] as? String ?? ""
        let preferences = data["preferences"] as? [String: String] ?? [:]
        let favoritePerfumes = data["favoritePerfumes"] as? [String] ?? []
        let triedPerfumes = data["triedPerfumes"] as? [String] ?? []
        let wishlistPerfumes = data["wishlistPerfumes"] as? [String] ?? []
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
        let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue()
        let lastLoginAt = (data["lastLoginAt"] as? Timestamp)?.dateValue()

        return User(
            id: id,
            name: name,
            email: email,
            preferences: preferences,
            favoritePerfumes: favoritePerfumes,
            triedPerfumes: triedPerfumes,
            wishlistPerfumes: wishlistPerfumes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            lastLoginAt: lastLoginAt
        )
    }

    func fetchTriedPerfumes(for userId: String) async throws -> [TriedPerfumeRecord] {
        let snapshot = try await db.collection(usersCollection).document(userId).collection(triedPerfumesSubcollection).getDocuments()

        let triedPerfumes = snapshot.documents.compactMap { document -> TriedPerfumeRecord? in
            do {
                var triedPerfume = try document.data(as: TriedPerfumeRecord.self)
                triedPerfume.id = document.documentID
                return triedPerfume
            } catch {
                print("Error decoding TriedPerfumeRecord document \(document.documentID): \(error)")
                return nil
            }
        }

        let sortedPerfumes = triedPerfumes.sorted { record1, record2 in
            let rating1 = record1.rating ?? -Double.infinity
            let rating2 = record2.rating ?? -Double.infinity
            return rating1 > rating2
        }

        return sortedPerfumes
    }


    func fetchTriedPerfumeRecord(userId: String, recordId: String) async throws -> TriedPerfumeRecord? {
        let documentRef = db.collection(usersCollection).document(userId).collection(triedPerfumesSubcollection).document(recordId)
        do {
            let documentSnapshot = try await documentRef.getDocument()

            guard documentSnapshot.exists else {
                print("TriedPerfumeRecord \(recordId) not found for user \(userId).")
                return nil
            }

            var record = try documentSnapshot.data(as: TriedPerfumeRecord.self)
            record.id = documentSnapshot.documentID
            return record
        } catch let error as NSError where error.code == 5 {
            print("TriedPerfumeRecord \(recordId) not found for user \(userId) (Caught gRPC error 5).")
            return nil
        } catch {
            print("Error fetching TriedPerfumeRecord \(recordId) for user \(userId): \(error)")
            throw error
        }
    }

    func deleteTriedPerfumeRecord(userId: String, recordId: String) async throws {
        let documentRef = db.collection(usersCollection).document(userId).collection(triedPerfumesSubcollection).document(recordId)
        do {
            try await documentRef.delete()
            print("Deleted TriedPerfumeRecord \(recordId) for user \(userId).")
        } catch {
            print("Error deleting tried perfume record \(recordId) for user \(userId): \(error)")
            throw error
        }
    }

    func addTriedPerfume(userId: String, perfumeId: String, perfumeKey: String, brandId: String, projection: String, duration: String, price: String, rating: Double, impressions: String, occasions: [String]?, seasons: [String]?, personalities: [String]?) async throws {
        let triedPerfumesCollection = db.collection(usersCollection).document(userId).collection(triedPerfumesSubcollection)

        let triedPerfumeRecord = TriedPerfumeRecord(
            userId: userId,
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
            createdAt: Date(),
            updatedAt: Date()
        )

         let _ = try triedPerfumesCollection.addDocument(from: triedPerfumeRecord)
         print("Successfully added TriedPerfumeRecord for user \(userId)")
    }

    func fetchPerfume(by perfumeId: String, brandId: String, perfumeKey: String) async throws -> Perfume? {
        let documentRef = db.collection(perfumesCollection).document("es").collection(brandId).document(perfumeKey)
        do {
            let document = try await documentRef.getDocument()
            guard document.exists else {
                 print("Perfume not found at path: \(documentRef.path)")
                 return nil
            }
            var perfume = try document.data(as: Perfume.self)
            perfume.id = document.documentID
            return perfume
        } catch let error as NSError where error.code == 5 {
            print("Perfume not found (gRPC error 5) at path: \(documentRef.path)")
            return nil
        } catch {
            print("Error fetching perfume at path \(documentRef.path): \(error)")
            throw error
        }
    }

    func updateTriedPerfumeRecord(record: TriedPerfumeRecord) async throws -> Bool {
        guard let recordId = record.id else {
            print("Error: TriedPerfumeRecord has no ID for update.")
            throw NSError(domain: "UserService", code: 400, userInfo: [NSLocalizedDescriptionKey: "ID de registro faltante para actualizar"])
        }

        guard !record.userId.isEmpty else {
             print("Error: TriedPerfumeRecord has no userId for update.")
             throw NSError(domain: "UserService", code: 400, userInfo: [NSLocalizedDescriptionKey: "ID de usuario faltante en el registro para actualizar"])
        }

        let documentRef = db.collection(usersCollection).document(record.userId).collection(triedPerfumesSubcollection).document(recordId)
        do {
            var recordToUpdate = record
            recordToUpdate.updatedAt = Date()

            try documentRef.setData(from: recordToUpdate, merge: true)
            print("TriedPerfumeRecord updated successfully in Firestore for ID: \(recordId)")
            return true
        } catch {
            print("Error updating tried perfume record \(recordId) for user \(record.userId): \(error)")
            throw error
        }
    }

    func fetchWishlist(for userId: String) async throws -> [WishlistItem] {
        let snapshot = try await db.collection(usersCollection).document(userId).collection(wishlistSubcollection)
            .order(by: "orderIndex", descending: false)
            .getDocuments()
        return snapshot.documents.compactMap { document in
            do {
                var wishlistItem = try document.data(as: WishlistItem.self)
                wishlistItem.id = document.documentID
                return wishlistItem
            } catch {
                print("Error decoding WishlistItem document \(document.documentID): \(error)")
                return nil
            }
        }
    }

    func addToWishlist(userId: String, wishlistItem: WishlistItem) async throws {
        let wishlistCollection = db.collection(usersCollection).document(userId).collection(wishlistSubcollection)
        let documentID = "\(wishlistItem.brandKey)_\(wishlistItem.perfumeKey)"
        let docRef = wishlistCollection.document(documentID)

        let countQuery = wishlistCollection.count
        let countSnapshot: AggregateQuerySnapshot
        do {
            countSnapshot = try await countQuery.getAggregation(source: .server)
        } catch {
            print("Error fetching wishlist count for user \(userId): \(error)")
            throw error
        }
        let nextOrderIndex = Int(truncating: countSnapshot.count)
        print("Pre-transaction count: \(nextOrderIndex). Attempting to add item \(documentID).")


        try await db.runTransaction { (transaction, errorPointer) -> Any? in
            var itemData: [String: Any]
            do {
                itemData = try Firestore.Encoder().encode(wishlistItem)
            } catch let encodeError as NSError {
                errorPointer?.pointee = encodeError
                return nil
            }
            itemData["orderIndex"] = nextOrderIndex
            itemData["id"] = documentID

            transaction.setData(itemData, forDocument: docRef)
            print("Transaction: Setting data for item \(documentID) with orderIndex: \(nextOrderIndex)")
            return nil
        }
        print("Successfully added/updated item \(documentID) in wishlist (using pre-calculated index).")
    }


    func updateWishlistOrder(userId: String, orderedItems: [WishlistItem]) async throws {
        guard !orderedItems.isEmpty else {
            print("No items provided to update wishlist order.")
            return
        }
        print("Iniciando actualización de orden en Firestore para \(orderedItems.count) items.")
        let batch = db.batch()
        let wishlistCollection = db.collection(usersCollection).document(userId).collection(wishlistSubcollection)

        for (index, item) in orderedItems.enumerated() {
            guard !item.brandKey.isEmpty, !item.perfumeKey.isEmpty else {
                print("Skipping item with empty brandKey or perfumeKey at index \(index)")
                continue
            }
            let documentID = "\(item.brandKey)_\(item.perfumeKey)"
            let docRef = wishlistCollection.document(documentID)
            print("Batch: Updating doc \(documentID) to orderIndex \(index)")
            batch.updateData(["orderIndex": index], forDocument: docRef)
        }

        try await batch.commit()
        print("Batch commit exitoso. Orden actualizado en Firestore.")
    }

    func removeFromWishlist(userId: String, wishlistItem: WishlistItem) async throws {
        let wishlistCollection = db.collection(usersCollection).document(userId).collection(wishlistSubcollection)
        guard !wishlistItem.brandKey.isEmpty, !wishlistItem.perfumeKey.isEmpty else {
             print("Error: Cannot remove wishlist item with empty brandKey or perfumeKey.")
             throw NSError(domain: "UserService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Datos de item inválidos para eliminar de wishlist."])
        }
        let documentID = "\(wishlistItem.brandKey)_\(wishlistItem.perfumeKey)"
        let docRef = wishlistCollection.document(documentID)

        // 1. Ejecutar transacción y obtener el resultado como Any?
        let transactionResult: Any? = try await db.runTransaction { (transaction, errorPointer) -> Any? in // Closure devuelve Any?
            let docToDeleteSnapshot: DocumentSnapshot
            do {
                docToDeleteSnapshot = try transaction.getDocument(docRef)
            } catch let fetchError as NSError {
                if fetchError.code == 5 { // Not Found
                     print("Item \(documentID) not found in wishlist, removal considered complete.")
                     return nil // Devuelve nil (como Any?)
                }
                errorPointer?.pointee = fetchError
                return nil // Devuelve nil (como Any?)
            }

            // Extraer el índice ANTES de eliminar
            let index = docToDeleteSnapshot.data()?["orderIndex"] as? Int // index es Int?

            // Eliminar
            transaction.deleteDocument(docRef)
            print("Transaction: Deleting item \(documentID).")

            // Devolver el índice (que es Int?) casteado a Any? para que coincida con la firma del closure
            return index as Any? // <-- Castear a Any? aquí dentro
        } // Fin de la transacción

        // 2. Castear el resultado Any? a Int? DESPUÉS de la transacción
        let deletedOrderIndex = transactionResult as? Int // <-- Castear Any? a Int?

        // El resto de la lógica sigue igual...
        guard let validDeletedIndex = deletedOrderIndex else {
            print("Successfully removed item \(documentID) (or it didn't exist / had no index). No reordering needed.")
            return
        }

        print("Successfully removed item \(documentID) with orderIndex \(validDeletedIndex). Now attempting reorder.")

        // 3. Obtener documentos a reordenar (fuera de transacción)
        let itemsToUpdateQuery = wishlistCollection
            .whereField("orderIndex", isGreaterThan: validDeletedIndex)

        let itemsToUpdateSnapshot: QuerySnapshot
        do {
            itemsToUpdateSnapshot = try await itemsToUpdateQuery.getDocuments()
        } catch {
            print("Error fetching documents to reorder AFTER deletion: \(error). Order might be inconsistent.")
            throw error
        }

        // 4. Usar WriteBatch para reordenar
        if !itemsToUpdateSnapshot.isEmpty {
            print("Found \(itemsToUpdateSnapshot.count) items to reorder.")
            let batch = db.batch()
            for document in itemsToUpdateSnapshot.documents {
                if let currentOrderIndex = document.data()["orderIndex"] as? Int {
                    let itemRef = wishlistCollection.document(document.documentID)
                    batch.updateData(["orderIndex": currentOrderIndex - 1], forDocument: itemRef)
                    print("Batch: Updating \(document.documentID) from index \(currentOrderIndex) to \(currentOrderIndex - 1)")
                } else {
                    print("Warning: Item \(document.documentID) found during reorder but missing orderIndex.")
                }
            }
            do {
                try await batch.commit()
                print("Batch commit successful. Reordering complete.")
            } catch {
                print("Error committing reorder batch: \(error). Order might be inconsistent.")
                throw error
            }
        } else {
            print("No items found needing reorder.")
        }
        print("removeFromWishlist completed for \(documentID).")
    }
}
