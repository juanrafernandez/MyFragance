import FirebaseFirestore

// Protocolo simplificado - ya no necesita language (ruta simplificada)
protocol OlfactiveProfileServiceProtocol {
    func fetchProfiles(userId: String) async throws -> [OlfactiveProfile]
    func listenToProfilesChanges(userId: String, completion: @escaping (Result<[OlfactiveProfile], Error>) -> Void) -> ListenerRegistration?
    func addProfile(userId: String, profile: OlfactiveProfile) async throws
    func updateProfile(userId: String, profile: OlfactiveProfile) async throws
    func deleteProfile(userId: String, profile: OlfactiveProfile) async throws
    func updateProfilesOrder(userId: String, orderedProfiles: [OlfactiveProfile]) async throws
}

// La clase AHORA es stateless con ruta simplificada
// Ruta nueva: users/{userId}/olfactive_profiles/{profileId}
// Ruta legacy: users/{userId}/olfactive_profiles/es/profiles/{profileId}
class OlfactiveProfileService: OlfactiveProfileServiceProtocol {
    private let db: Firestore

    private let usersCollection = "users"
    private let olfactiveProfilesCollection = "olfactive_profiles"

    // Legacy path components (para migración)
    private let legacyLanguageDocument = "es"
    private let legacyProfilesSubcollection = "profiles"

    // Init SIMPLE
    init(firestore: Firestore = Firestore.firestore()) {
        self.db = firestore
        #if DEBUG
        print("OlfactiveProfileService initialized (stateless, simplified path).")
        #endif
    }

    // MARK: - Path Helpers

    // Nueva ruta simplificada: users/{userId}/olfactive_profiles
    private func profilesCollectionRef(userId: String) -> CollectionReference {
        guard !userId.isEmpty else {
            #if DEBUG
            print("Error: Attempted to get collection ref with empty userId.")
            #endif
            return db.collection("____INVALID____")
        }
        return db.collection(usersCollection)
                 .document(userId)
                 .collection(olfactiveProfilesCollection)
    }

    // Ruta legacy: users/{userId}/olfactive_profiles/es/profiles
    private func legacyProfilesCollectionRef(userId: String) -> CollectionReference {
        return db.collection(usersCollection)
                 .document(userId)
                 .collection(olfactiveProfilesCollection)
                 .document(legacyLanguageDocument)
                 .collection(legacyProfilesSubcollection)
    }

    // --- Implementación de Métodos (Ruta simplificada con migración automática) ---

    func fetchProfiles(userId: String) async throws -> [OlfactiveProfile] {
        let collectionRef = self.profilesCollectionRef(userId: userId)
        #if DEBUG
        print("Fetching profiles from: \(collectionRef.path)")
        #endif

        // Primero intentar la nueva ruta
        let snapshot = try await collectionRef
            .order(by: "orderIndex", descending: false)
            .getDocuments()

        if !snapshot.documents.isEmpty {
            #if DEBUG
            print("Fetched \(snapshot.documents.count) profile documents from new path for user \(userId).")
            #endif
            return snapshot.documents.compactMap { document -> OlfactiveProfile? in
                do {
                    var profile = try document.data(as: OlfactiveProfile.self)
                    profile.id = document.documentID
                    return profile
                } catch { return nil }
            }
        }

        // Si no hay datos en nueva ruta, intentar migrar de la ruta legacy
        let legacyCollectionRef = self.legacyProfilesCollectionRef(userId: userId)
        #if DEBUG
        print("No profiles in new path, checking legacy path: \(legacyCollectionRef.path)")
        #endif

        let legacySnapshot = try await legacyCollectionRef
            .order(by: "orderIndex", descending: false)
            .getDocuments()

        if !legacySnapshot.documents.isEmpty {
            #if DEBUG
            print("Found \(legacySnapshot.documents.count) profiles in legacy path, migrating...")
            #endif

            // Migrar perfiles de la ruta legacy a la nueva
            var migratedProfiles: [OlfactiveProfile] = []
            let batch = db.batch()

            for document in legacySnapshot.documents {
                do {
                    var profile = try document.data(as: OlfactiveProfile.self)
                    profile.id = document.documentID

                    // Guardar en la nueva ruta
                    let newDocRef = collectionRef.document(document.documentID)
                    try batch.setData(from: profile, forDocument: newDocRef)

                    migratedProfiles.append(profile)
                } catch {
                    #if DEBUG
                    print("Error migrating profile \(document.documentID): \(error)")
                    #endif
                }
            }

            try await batch.commit()
            #if DEBUG
            print("✅ Migration completed: \(migratedProfiles.count) profiles migrated to new path")
            #endif

            return migratedProfiles
        }

        #if DEBUG
        print("No profiles found for user \(userId) in either path.")
        #endif
        return []
    }

    func listenToProfilesChanges(userId: String, completion: @escaping (Result<[OlfactiveProfile], Error>) -> Void) -> ListenerRegistration? {
        let collectionRef = self.profilesCollectionRef(userId: userId)
        #if DEBUG
        print("Starting listener on: \(collectionRef.path)")
        #endif

        // Listener en la nueva ruta
        let listener = collectionRef
            .order(by: "orderIndex", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }

                // Si hay documentos en la nueva ruta, usarlos
                if !documents.isEmpty {
                    #if DEBUG
                    print("Listener received \(documents.count) profile documents for user \(userId).")
                    #endif
                    let profiles = documents.compactMap { document -> OlfactiveProfile? in
                        do {
                            var profile = try document.data(as: OlfactiveProfile.self)
                            profile.id = document.documentID
                            return profile
                        } catch { return nil }
                    }
                    completion(.success(profiles))
                } else {
                    // Si la nueva ruta está vacía, verificar legacy path y migrar
                    Task {
                        do {
                            let profiles = try await self.fetchProfiles(userId: userId)
                            await MainActor.run {
                                completion(.success(profiles))
                            }
                        } catch {
                            await MainActor.run {
                                completion(.failure(error))
                            }
                        }
                    }
                }
            }
        return listener
    }

    func addProfile(userId: String, profile: OlfactiveProfile) async throws {
        var newProfile = profile
        let collectionRef = self.profilesCollectionRef(userId: userId)

        if newProfile.id == nil || newProfile.id!.isEmpty {
            newProfile.id = collectionRef.document().documentID
        }
        let docRef = collectionRef.document(newProfile.id!)

        let countQuery = collectionRef.count
        let countSnapshot = try await countQuery.getAggregation(source: .server)
        let nextOrderIndex = Int(truncating: countSnapshot.count)
        newProfile.orderIndex = nextOrderIndex

        // Añadir fecha de creación si no existe
        if newProfile.createdAt == nil {
            newProfile.createdAt = Date()
        }

        try docRef.setData(from: newProfile)
        #if DEBUG
        print("Olfactive profile added for user \(userId) with ID: \(newProfile.id!) and orderIndex: \(nextOrderIndex)")
        print("   Path: \(docRef.path)")
        #endif
    }

    func updateProfile(userId: String, profile: OlfactiveProfile) async throws {
        guard let profileId = profile.id, !profileId.isEmpty else {
            throw NSError(domain: "OlfactiveProfileService", code: 400, userInfo: [NSLocalizedDescriptionKey: "ID del perfil no puede ser nil o vacío para actualizar."])
        }
        let docRef = self.profilesCollectionRef(userId: userId).document(profileId)

        var dataToUpdate = try Firestore.Encoder().encode(profile)
        dataToUpdate["id"] = nil
        dataToUpdate["orderIndex"] = nil

        guard !dataToUpdate.isEmpty else { return }
        try await docRef.updateData(dataToUpdate)
        #if DEBUG
        print("Olfactive profile updated for user \(userId) (order unchanged): \(profileId)")
        #endif
    }

    func updateProfilesOrder(userId: String, orderedProfiles: [OlfactiveProfile]) async throws {
        guard !orderedProfiles.isEmpty else { return }
        #if DEBUG
        print("Updating order in Firestore for \(orderedProfiles.count) olfactive profiles for user \(userId).")
        #endif
        let batch = db.batch()
        let collectionRef = self.profilesCollectionRef(userId: userId)

        for (index, profile) in orderedProfiles.enumerated() {
            guard let profileId = profile.id, !profileId.isEmpty else { continue }
            let docRef = collectionRef.document(profileId)
            batch.updateData(["orderIndex": index], forDocument: docRef)
        }

        try await batch.commit()
        #if DEBUG
        print("Olfactive profiles order updated successfully in Firestore for user \(userId).")
        #endif
    }

    func deleteProfile(userId: String, profile: OlfactiveProfile) async throws {
        guard let id = profile.id, !id.isEmpty else {
            throw NSError(domain: "OlfactiveProfileService", code: 400, userInfo: [NSLocalizedDescriptionKey: "ID del perfil olfativo inválido para eliminar."])
        }
        let collectionRef = self.profilesCollectionRef(userId: userId)
        let documentRef = collectionRef.document(id)
        var deletedOrderIndex: Int? = nil

        let documentSnapshot = try await documentRef.getDocument()
        if documentSnapshot.exists {
            deletedOrderIndex = documentSnapshot.data()?["orderIndex"] as? Int
        } else { return }

        try await documentRef.delete()
        #if DEBUG
        print("Olfactive profile deleted for user \(userId) (ID: \(id)).")
        #endif

        guard let validDeletedIndex = deletedOrderIndex else { return }

        let profilesToUpdateQuery = collectionRef
            .whereField("orderIndex", isGreaterThan: validDeletedIndex)
        let profilesToUpdateSnapshot = try await profilesToUpdateQuery.getDocuments()

        if !profilesToUpdateSnapshot.isEmpty {
            #if DEBUG
            print("Reordering \(profilesToUpdateSnapshot.count) profiles for user \(userId)...")
            #endif
            let batch = db.batch()
            for document in profilesToUpdateSnapshot.documents {
                if let currentOrderIndex = document.data()["orderIndex"] as? Int {
                    let docRefToUpdate = collectionRef.document(document.documentID)
                    batch.updateData(["orderIndex": currentOrderIndex - 1], forDocument: docRefToUpdate)
                }
            }
            try await batch.commit()
        }
        #if DEBUG
        print("deleteProfile completed for user \(userId), ID: \(id).")
        #endif
    }
}
