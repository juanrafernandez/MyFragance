import Foundation
import FirebaseFirestore

protocol PerfumistServiceProtocol {
    func fetchPerfumists() async throws -> [Perfumist]
    func fetchPerfumistByName(name: String) async throws -> Perfumist?
    func listenToPerfumistsChanges(completion: @escaping (Result<[Perfumist], Error>) -> Void)
}

class PerfumistService: PerfumistServiceProtocol {
    private let db: Firestore
    private let languageProvider: LanguageProvider

    init(firestore: Firestore = Firestore.firestore(), languageProvider: LanguageProvider = AppState.shared) {
        self.db = firestore
        self.languageProvider = languageProvider
    }

    /// Computed property to access current language
    private var language: String {
        languageProvider.language
    }

    // MARK: - Obtener Todos los Perfumistas
    func fetchPerfumists() async throws -> [Perfumist] {
        let collectionPath = "perfumists/\(language)/perfumists"
        let snapshot = try await db.collection(collectionPath).getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Perfumist.self) }
    }

    // MARK: - Agregar o Actualizar un Perfumista
    func addOrUpdatePerfumist(_ perfumist: Perfumist) async throws {
        guard let id = perfumist.id as String? else {
            throw NSError(domain: "FirestoreError", code: 400, userInfo: [NSLocalizedDescriptionKey: "El ID del perfumista no puede ser nil."])
        }
        let collectionPath = "perfumists/\(language)"
        let documentRef = db.collection(collectionPath).document(id)

        do {
            try documentRef.setData(from: perfumist, merge: true)
            #if DEBUG
            print("Perfumista agregado o actualizado exitosamente.")
            #endif
        } catch {
            throw NSError(domain: "FirestoreError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Error al guardar el perfumista: \(error.localizedDescription)"])
        }
    }

    // MARK: - Eliminar Perfumista por ID
    func deletePerfumistById(_ id: String) async throws {
        let collectionPath = "perfumists/\(language)"
        let documentRef = db.collection(collectionPath).document(id)

        do {
            try await documentRef.delete()
            #if DEBUG
            print("Perfumista eliminado exitosamente.")
            #endif
        } catch {
            throw NSError(domain: "FirestoreError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Error al eliminar el perfumista: \(error.localizedDescription)"])
        }
    }

    // MARK: - Buscar Perfumista por Nombre (Opcional)
    func fetchPerfumistByName(name: String) async throws -> Perfumist? {
        let collectionPath = "perfumists/\(language)"
        let querySnapshot = try await db.collection(collectionPath).whereField("name", isEqualTo: name).getDocuments()

        return querySnapshot.documents.compactMap { try? $0.data(as: Perfumist.self) }.first
    }
    
    func listenToPerfumistsChanges(completion: @escaping (Result<[Perfumist], Error>) -> Void) {
        let collectionPath = "perfumists/\(language)/perfumists"
        let collectionRef = db.collection(collectionPath)

        collectionRef.addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let documents = snapshot?.documents else {
                completion(.success([])) // Sin documentos, lista vacía
                return
            }

            let perfumists = documents.compactMap { try? $0.data(as: Perfumist.self) }
            completion(.success(perfumists))
        }
    }
}
