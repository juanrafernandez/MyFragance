import FirebaseFirestore

// El protocolo necesita reflejar que userId/language se pasan a los métodos
protocol OlfactiveProfileServiceProtocol {
    func fetchProfiles(userId: String, language: String) async throws -> [OlfactiveProfile]
    func listenToProfilesChanges(userId: String, language: String, completion: @escaping (Result<[OlfactiveProfile], Error>) -> Void) -> ListenerRegistration?
    func addProfile(userId: String, language: String, profile: OlfactiveProfile) async throws
    func updateProfile(userId: String, language: String, profile: OlfactiveProfile) async throws
    func deleteProfile(userId: String, language: String, profile: OlfactiveProfile) async throws
    func updateProfilesOrder(userId: String, language: String, orderedProfiles: [OlfactiveProfile]) async throws
    // Ya no necesitamos getServiceUserId() aquí
}

// La clase AHORA es stateless
class OlfactiveProfileService: OlfactiveProfileServiceProtocol {
    private let db: Firestore
    // Ya NO almacenamos userId ni language

    private let usersCollection = "users"
    private let olfactiveProfilesBasePath = "olfactive_profiles"
    private let profilesSubcollection = "profiles"

    // Init SIMPLE
    init(firestore: Firestore = Firestore.firestore()) {
        self.db = firestore
        print("OlfactiveProfileService initialized (stateless).")
    }

    // Helper ACEPTA userId y language
    private func profilesCollectionRef(userId: String, language: String) -> CollectionReference {
        guard !userId.isEmpty else {
            print("Error: Attempted to get collection ref with empty userId.")
            return db.collection("____INVALID____") // Ruta inválida para error
        }
        // Construye la ruta usando los parámetros
        return db.collection(usersCollection)
                 .document(userId)
                 .collection(olfactiveProfilesBasePath)
                 .document(language)
                 .collection(profilesSubcollection)
    }

    // --- Implementación de Métodos (RECIBEN userId/language) ---

    func fetchProfiles(userId: String, language: String) async throws -> [OlfactiveProfile] {
        let collectionRef = self.profilesCollectionRef(userId: userId, language: language) // Pasa parámetros
        print("Fetching profiles from: \(collectionRef.path)")
        let snapshot = try await collectionRef
            .order(by: "orderIndex", descending: false)
            .getDocuments()

        print("Fetched \(snapshot.documents.count) profile documents for user \(userId).")
         let profiles = snapshot.documents.compactMap { document -> OlfactiveProfile? in
             do {
                 var profile = try document.data(as: OlfactiveProfile.self)
                 profile.id = document.documentID
                 return profile
             } catch { return nil }
        }
        return profiles
    }

    func listenToProfilesChanges(userId: String, language: String, completion: @escaping (Result<[OlfactiveProfile], Error>) -> Void) -> ListenerRegistration? {
        let collectionRef = self.profilesCollectionRef(userId: userId, language: language) // Pasa parámetros
        print("Starting listener on: \(collectionRef.path)")
        let listener = collectionRef
            .order(by: "orderIndex", descending: false)
            .addSnapshotListener { snapshot, error in
                 if let error = error { completion(.failure(error)); return }
                 guard let documents = snapshot?.documents else { completion(.success([])); return }
                 print("Listener received \(documents.count) profile documents for user \(userId).")
                 let profiles = documents.compactMap { document -> OlfactiveProfile? in
                      do {
                           var profile = try document.data(as: OlfactiveProfile.self)
                           profile.id = document.documentID
                           return profile
                      } catch { return nil }
                  }
                 completion(.success(profiles))
            }
        return listener
    }

    func addProfile(userId: String, language: String, profile: OlfactiveProfile) async throws {
        var newProfile = profile
        let collectionRef = self.profilesCollectionRef(userId: userId, language: language) // Pasa parámetros

        if newProfile.id == nil || newProfile.id!.isEmpty {
            newProfile.id = collectionRef.document().documentID
        }
        let docRef = collectionRef.document(newProfile.id!)

        let countQuery = collectionRef.count
        let countSnapshot = try await countQuery.getAggregation(source: .server)
        let nextOrderIndex = Int(truncating: countSnapshot.count)
        newProfile.orderIndex = nextOrderIndex

        try docRef.setData(from: newProfile)
        print("Olfactive profile added for user \(userId) with ID: \(newProfile.id!) and orderIndex: \(nextOrderIndex)")
    }

    func updateProfile(userId: String, language: String, profile: OlfactiveProfile) async throws {
         guard let profileId = profile.id, !profileId.isEmpty else {
            throw NSError(domain: "OlfactiveProfileService", code: 400, userInfo: [NSLocalizedDescriptionKey: "ID del perfil no puede ser nil o vacío para actualizar."])
        }
        let docRef = self.profilesCollectionRef(userId: userId, language: language).document(profileId) // Pasa parámetros

        var dataToUpdate = try Firestore.Encoder().encode(profile)
        dataToUpdate["id"] = nil
        dataToUpdate["orderIndex"] = nil

        guard !dataToUpdate.isEmpty else { return }
        try await docRef.updateData(dataToUpdate)
        print("Olfactive profile updated for user \(userId) (order unchanged): \(profileId)")
    }

    func updateProfilesOrder(userId: String, language: String, orderedProfiles: [OlfactiveProfile]) async throws {
        guard !orderedProfiles.isEmpty else { return }
        print("Updating order in Firestore for \(orderedProfiles.count) olfactive profiles for user \(userId).")
        let batch = db.batch()
        let collectionRef = self.profilesCollectionRef(userId: userId, language: language) // Pasa parámetros

        for (index, profile) in orderedProfiles.enumerated() {
            guard let profileId = profile.id, !profileId.isEmpty else { continue }
            let docRef = collectionRef.document(profileId)
            batch.updateData(["orderIndex": index], forDocument: docRef)
        }

        try await batch.commit()
        print("Olfactive profiles order updated successfully in Firestore for user \(userId).")
    }

     func deleteProfile(userId: String, language: String, profile: OlfactiveProfile) async throws {
         guard let id = profile.id, !id.isEmpty else {
             throw NSError(domain: "OlfactiveProfileService", code: 400, userInfo: [NSLocalizedDescriptionKey: "ID del perfil olfativo inválido para eliminar."])
         }
         let collectionRef = self.profilesCollectionRef(userId: userId, language: language) // Pasa parámetros
         let documentRef = collectionRef.document(id)
         var deletedOrderIndex: Int? = nil

         let documentSnapshot = try await documentRef.getDocument()
         if documentSnapshot.exists {
             deletedOrderIndex = documentSnapshot.data()?["orderIndex"] as? Int
         } else { return }

         try await documentRef.delete()
         print("Olfactive profile deleted for user \(userId) (ID: \(id)).")

         guard let validDeletedIndex = deletedOrderIndex else { return }

         let profilesToUpdateQuery = collectionRef
             .whereField("orderIndex", isGreaterThan: validDeletedIndex)
         let profilesToUpdateSnapshot = try await profilesToUpdateQuery.getDocuments()

         if !profilesToUpdateSnapshot.isEmpty {
             print("Reordering \(profilesToUpdateSnapshot.count) profiles for user \(userId)...")
             let batch = db.batch()
             for document in profilesToUpdateSnapshot.documents {
                 if let currentOrderIndex = document.data()["orderIndex"] as? Int {
                     let docRefToUpdate = collectionRef.document(document.documentID)
                     batch.updateData(["orderIndex": currentOrderIndex - 1], forDocument: docRefToUpdate)
                 }
             }
             try await batch.commit()
         }
          print("deleteProfile completed for user \(userId), ID: \(id).")
     }
}
