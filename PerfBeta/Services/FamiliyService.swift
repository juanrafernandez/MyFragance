import Foundation
import FirebaseFirestore

protocol FamilyServiceProtocol {
    func fetchFamilias() async throws -> [Family]
    func listenToFamiliasChanges(completion: @escaping (Result<[Family], Error>) -> Void)
}

class FamilyService: FamilyServiceProtocol {
    private let db: Firestore
    private let language: String

    init(firestore: Firestore = Firestore.firestore(), language: String = AppState.shared.language) {
        self.db = firestore
        self.language = language
    }

    // MARK: - Obtener Familias desde Firestore
    func fetchFamilias() async throws -> [Family] {
        let familiesCollection = db.collection("families/\(language)/families")
        
        do {
            let snapshot = try await familiesCollection.getDocuments()
            return snapshot.documents.compactMap { document in
                do {
                    return try document.data(as: Family.self)
                } catch {
                    print("Error al convertir documento en FamiliaOlfativaRemote: \(error.localizedDescription)")
                    return nil
                }
            }
        } catch {
            throw NSError(domain: "FirestoreError", code: 500, userInfo: [
                NSLocalizedDescriptionKey: "Error al obtener familias: \(error.localizedDescription)"
            ])
        }
    }

    func listenToFamiliasChanges(completion: @escaping (Result<[Family], Error>) -> Void) {
        let familiesCollection = db.collection("families/\(language)/families")
        
        familiesCollection.addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let documents = snapshot?.documents else {
                completion(.success([])) // Si no hay documentos, retorna una lista vacía
                return
            }

            let familias = documents.compactMap { document in
                try? document.data(as: Family.self)
            }
            completion(.success(familias))
        }
    }
}
