import FirebaseFirestore
import UIKit

protocol PerfumeServiceProtocol {
    func fetchAllPerfumesOnce() async throws -> [Perfume]
}

class PerfumeService: PerfumeServiceProtocol {
    // Propiedades
    private let db: Firestore
    private let brandService: BrandServiceProtocol
    private let language: String

    init(
        firestore: Firestore = Firestore.firestore(),
        brandService: BrandServiceProtocol = DependencyContainer.shared.brandService,
        language: String = AppState.shared.language
    ) {
        self.db = firestore
        self.brandService = brandService
        self.language = language
    }

    // MARK: - Obtener todos los perfumes una vez
    func fetchAllPerfumesOnce() async throws -> [Perfume] {
        // 1. Obtener las brandKeys de marcas con perfumes asociados
        let brandKeys = try await brandService.fetchBrandKeysWithPerfumes()

        if brandKeys.isEmpty {
            return [] // No hay marcas con perfumes asociados
        }

        var allPerfumes: [Perfume] = []

        // 2. Obtener los perfumes para cada brandKey
        for brandKey in brandKeys {
            let collectionPath = "perfumes/\(language)/\(brandKey)"
            let snapshot = try await db.collection(collectionPath).getDocuments()

            let perfumes = snapshot.documents.compactMap { document -> Perfume? in
                do {
                    var perfume = try document.data(as: Perfume.self)
                    perfume.id = document.documentID
                    perfume.brand = brandKey
                    return perfume
                } catch {
                    print("Error decoding perfume \(document.documentID): \(error)")
                    return nil
                }
            }
            allPerfumes.append(contentsOf: perfumes)
        }

        return allPerfumes
    }
}
