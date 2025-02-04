import Foundation
import FirebaseFirestore

protocol NotesServiceProtocol {
    func fetchNotes() async throws -> [Notes]
    func listenToNotesChanges(completion: @escaping (Result<[Notes], Error>) -> Void)
}

class NotesService: NotesServiceProtocol {
    private let db: Firestore
    private let language: String

    init(firestore: Firestore = Firestore.firestore(), language: String = AppState.shared.language) {
        self.db = firestore
        self.language = language
    }

    // MARK: - Obtener Notas
    func fetchNotes() async throws -> [Notes] {
        let notesCollection = db.collection("notes/\(language)/notes")
        
        do {
            let snapshot = try await notesCollection.getDocuments()
            return snapshot.documents.compactMap { try? $0.data(as: Notes.self) }
        } catch {
            throw NSError(domain: "FirestoreError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Error al obtener las notas: \(error.localizedDescription)"])
        }
    }

    func listenToNotesChanges(completion: @escaping (Result<[Notes], Error>) -> Void) {
        let notesCollection = db.collection("notes/\(language)/notes")
        
        notesCollection.addSnapshotListener { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let documents = snapshot?.documents else {
                completion(.success([])) // Si no hay documentos, lista vacía
                return
            }

            let notes = documents.compactMap { try? $0.data(as: Notes.self) }
            completion(.success(notes))
        }
    }

}
