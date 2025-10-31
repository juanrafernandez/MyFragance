import FirebaseFirestore

protocol BrandServiceProtocol {
    func fetchBrands() async throws -> [Brand]
    func fetchBrandKeysWithPerfumes() async throws -> [String] // Método añadido
    func listenToBrands(completion: @escaping (Result<[Brand], Error>) -> Void)
}

class BrandService: BrandServiceProtocol {
    private let db: Firestore
    private let language: String

    init(firestore: Firestore = Firestore.firestore(), language: String = AppState.shared.language) {
        self.db = firestore
        self.language = language
    }

    // MARK: - Fetch Brands
    func fetchBrands() async throws -> [Brand] {
        let collectionPath = "brands_\(language)"
        let snapshot = try await db.collection(collectionPath).getDocuments()
        
        return snapshot.documents.compactMap { document in
            let data = document.data()
            return Brand(
                id: data["id"] as? String ?? document.documentID,
                key: data["key"] as? String ?? "",
                name: data["name"] as? String ?? "",
                imageURL: data["imagenURL"] as? String ?? "",
                origin: data["origin"] as? String ?? "",
                descriptionBrand: data["descriptionBrand"] as? String ?? "",
                perfumist: data["perfumist"] as? [String] ?? [],
                createdAt: (data["createdAt"] as? Timestamp)?.dateValue(),
                updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue()
            )
        }
    }

    // MARK: - Fetch Brands with Associated Perfumes
    func fetchBrandKeysWithPerfumes() async throws -> [String] {
            let collectionPath = "brands_\(language)"
            let snapshot = try await db.collection(collectionPath).getDocuments()

            // Extraer keys de las marcas
            let brandKeys = snapshot.documents.compactMap { $0.data()["key"] as? String }

            if brandKeys.isEmpty {
                print("⚠️ No se encontraron marcas en Firestore.")
                return []
            }

            var brandKeysWithPerfumes: [String] = []

            // Concurrently check if each brand has perfumes associated
            try await withThrowingTaskGroup(of: (String, Bool).self) { group in
                for brandKey in brandKeys {
                    group.addTask {
                        let collectionPath = "perfumes/\(self.language)/\(brandKey)"
                        let perfumesSnapshot = try await self.db.collection(collectionPath).getDocuments()
                        return (brandKey, !perfumesSnapshot.documents.isEmpty)
                    }
                }

                // Collect results from all tasks
                for try await (brandKey, hasPerfumes) in group {
                    if hasPerfumes {
                        brandKeysWithPerfumes.append(brandKey)
                    }
                }
            }

            return brandKeysWithPerfumes
        }

    // MARK: - Listen to Brands Changes
    func listenToBrands(completion: @escaping (Result<[Brand], Error>) -> Void) {
        let collectionPath = "brands_\(language)"
        let collectionRef = db.collection(collectionPath)

        // Agregar listener para detectar cambios en la colección de marcas
        collectionRef.addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let documents = snapshot?.documents else {
                completion(.success([])) // No hay marcas
                return
            }

            // Convertir documentos a BrandRemote
            let brands = documents.compactMap { document in
                let data = document.data()
                return Brand(
                    id: data["id"] as? String ?? document.documentID,
                    key: data["key"] as? String ?? "",
                    name: data["name"] as? String ?? "",
                    imageURL: data["imagenURL"] as? String ?? "",
                    origin: data["origin"] as? String ?? "",
                    descriptionBrand: data["descriptionBrand"] as? String ?? "",
                    perfumist: data["perfumist"] as? [String] ?? [],
                    createdAt: (data["createdAt"] as? Timestamp)?.dateValue(),
                    updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue()
                )
            }

            completion(.success(brands))
        }
    }
}
