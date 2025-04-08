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
    func updateWishlistOrder(userId: String, orderedItems: [WishlistItem]) async throws
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
    
    func fetchTriedPerfumes(for userId: String) async throws -> [TriedPerfumeRecord] {
        let snapshot = try await db.collection("users/\(userId)/triedPerfumes").getDocuments()
        
        // 1. Decodifica los documentos, asigna el ID y filtra los nulos
        let triedPerfumes = snapshot.documents.compactMap { document -> TriedPerfumeRecord? in
            var triedPerfume = try? document.data(as: TriedPerfumeRecord.self)
            triedPerfume?.id = document.documentID // Asigna el ID del documento
            return triedPerfume
        }
        
        // 2. Ordena el array resultante por 'rating' descendente (mayor a menor)
        //    Trata los 'nil' como el valor más bajo posible para que queden al final.
        let sortedPerfumes = triedPerfumes.sorted { record1, record2 in
            // Usa nil-coalescing para asignar un valor muy bajo a los ratings nulos
            // -Double.infinity asegura que cualquier número sea mayor que nil
            let rating1 = record1.rating ?? -Double.infinity
            let rating2 = record2.rating ?? -Double.infinity
            
            // Compara para orden descendente (el mayor primero)
            return rating1 > rating2
        }
        
        // 3. Devuelve el array ordenado
        return sortedPerfumes
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
    
    func fetchOlfactiveProfiles(for userId: String) async throws -> [OlfactiveProfile] {
        let snapshot = try await db.collection("users/\(userId)/olfactiveProfiles").getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: OlfactiveProfile.self) }
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
    
    func fetchWishlist(for userId: String) async throws -> [WishlistItem] {
        let snapshot = try await db.collection("users/\(userId)/wishlist")
        // Añade el ordenamiento por 'orderIndex' aquí al obtener los datos
            .order(by: "orderIndex", descending: false)
            .getDocuments()
        return snapshot.documents.compactMap { document in
            // Intenta decodificar, asegurándote de incluir orderIndex
            var wishlistItem = try? document.data(as: WishlistItem.self)
            wishlistItem?.id = document.documentID // Asigna el ID del documento
            return wishlistItem
        }
    }
    
    func addToWishlist(userId: String, wishlistItem: WishlistItem) async throws {
        let wishlistCollection = db.collection("users").document(userId).collection("wishlist")
        let documentID = "\(wishlistItem.brandKey)_\(wishlistItem.perfumeKey)"
        
        // Obtener el siguiente orderIndex disponible
        // Cuenta cuántos documentos hay para determinar el índice del nuevo item (será count)
        let countSnapshot = try await wishlistCollection.count.getAggregation(source: .server)
        let nextOrderIndex = Int(truncating: countSnapshot.count) // El nuevo item irá al final
        
        var itemData = try Firestore.Encoder().encode(wishlistItem) // Codifica el item completo
        itemData["orderIndex"] = nextOrderIndex // Establece/Sobrescribe el orderIndex calculado
        itemData["id"] = documentID // Asegura que el id esté en los datos
        
        // Usa los datos codificados para crear/sobrescribir el documento
        try await wishlistCollection.document(documentID).setData(itemData)
        
        print("Item añadido a wishlist con orderIndex: \(nextOrderIndex)")
    }
    
    // VERSIÓN QUE ASIGNA ÍNDICES BASÁNDOSE EN LA POSICIÓN EN ESTE ARRAY
    func updateWishlistOrder(userId: String, orderedItems: [WishlistItem]) async throws {
        print("Iniciando actualización de orden en Firestore para \(orderedItems.count) items.")
        let batch = db.batch()
        let wishlistCollection = db.collection("users").document(userId).collection("wishlist")

        // Usamos enumerated() para obtener el índice (posición) de cada item en el array
        for (index, item) in orderedItems.enumerated() { // <--- Cambio clave: (index, item) y .enumerated()
            let documentID = "\(item.brandKey)_\(item.perfumeKey)"
            let docRef = wishlistCollection.document(documentID)

            // AHORA USAMOS EL 'index' DEL BUCLE, NO el 'item.orderIndex' original
            print("Actualizando doc \(documentID) a orderIndex \(index)") // <--- Usamos index
            batch.updateData(["orderIndex": index], forDocument: docRef) // <--- Usamos index
        }

        try await batch.commit()
        print("Batch commit exitoso. Orden actualizado en Firestore.")
    }
    
    // NEW: removeFromWishlist function to use WishlistItem
    func removeFromWishlist(userId: String, wishlistItem: WishlistItem) async throws {
        let wishlistCollection = db.collection("users").document(userId).collection("wishlist")
        let documentID = "\(wishlistItem.brandKey)_\(wishlistItem.perfumeKey)"
        
        // Antes de eliminar, guarda el orderIndex del item que se va
        let docToDeleteSnapshot = try? await wishlistCollection.document(documentID).getDocument()
        let deletedOrderIndex = docToDeleteSnapshot?.data()?["orderIndex"] as? Int
        
        // Elimina el documento
        try await wishlistCollection.document(documentID).delete()
        print("Item eliminado de wishlist con ID: \(documentID)")
        
        // Ahora, reajusta los orderIndex de los items restantes si es necesario
        if let deletedIndex = deletedOrderIndex {
            // Obtén todos los documentos cuyo orderIndex sea MAYOR que el eliminado
            let itemsToUpdateSnapshot = try await wishlistCollection
                .whereField("orderIndex", isGreaterThan: deletedIndex)
                .getDocuments()
            
            // Si hay items que reajustar, usa un batch
            if !itemsToUpdateSnapshot.isEmpty {
                let batch = db.batch()
                for document in itemsToUpdateSnapshot.documents {
                    let currentOrderIndex = document.data()["orderIndex"] as? Int ?? 0
                    let docRef = wishlistCollection.document(document.documentID)
                    // Decrementa el índice en 1
                    batch.updateData(["orderIndex": currentOrderIndex - 1], forDocument: docRef)
                }
                try await batch.commit()
                print("OrderIndex reajustado para \(itemsToUpdateSnapshot.count) items después de la eliminación.")
            }
        }
    }
}
