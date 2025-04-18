import Foundation
import SwiftUICore
import FirebaseFirestore

protocol OlfactiveProfileServiceProtocol {
    func fetchProfiles() async throws -> [OlfactiveProfile]
    func listenToProfilesChanges(completion: @escaping (Result<[OlfactiveProfile], Error>) -> Void)
    func addOrUpdateProfile(_ profile: OlfactiveProfile) async throws
    func deleteProfile(_ profile: OlfactiveProfile) async throws
}

class OlfactiveProfileService: OlfactiveProfileServiceProtocol {
    private let db: Firestore
    private let userId: String
    private let language: String

    init(firestore: Firestore = Firestore.firestore(), userId: String = "testUserId", language: String = AppState.shared.language) {
        self.db = firestore
        self.userId = userId
        self.language = language
    }

    private var basePath: String {
        return "users/\(userId)/olfactive_profiles"
    }

    // MARK: - Obtener Perfiles Olfativos desde Firestore
    func fetchProfiles() async throws -> [OlfactiveProfile] {
        let collectionPath = "\(basePath)/\(language)/profiles"
        let snapshot = try await db.collection(collectionPath).getDocuments()

        let profiles = snapshot.documents.compactMap { try? $0.data(as: OlfactiveProfile.self) }
        return profiles
    }

    // MARK: - Escuchar Cambios en Tiempo Real
    func listenToProfilesChanges(completion: @escaping (Result<[OlfactiveProfile], Error>) -> Void) {
        let collectionPath = "\(basePath)/\(language)/profiles"
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

            let profiles = documents.compactMap { try? $0.data(as: OlfactiveProfile.self) }
            completion(.success(profiles))
        }
    }

    // MARK: - Agregar o Actualizar Perfil Olfativo en Firestore
    func addOrUpdateProfile(_ profile: OlfactiveProfile) async throws {
        var profileWithID = profile
        profileWithID.id = profile.id ?? UUID().uuidString

        let documentPath = "\(basePath)/\(language)/profiles/\(profileWithID.id!)"
        let documentRef = db.document(documentPath)

        do {
            try await documentRef.setData(from: profileWithID, merge: true)
            print("Perfil olfativo agregado/actualizado exitosamente.")
        } catch {
            throw NSError(domain: "OlfactiveProfileService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Error al guardar el perfil olfativo: \(error.localizedDescription)"])
        }
    }

    // MARK: - Eliminar Perfil Olfativo en Firestore
    func deleteProfile(_ profile: OlfactiveProfile) async throws {
        guard let id = profile.id else {
            throw NSError(domain: "OlfactiveProfileService", code: 400, userInfo: [NSLocalizedDescriptionKey: "ID del perfil olfativo no válido."])
        }

        let documentPath = "\(basePath)/\(language)/profiles/\(id)"
        let documentRef = db.document(documentPath)

        do {
            try await documentRef.delete()
            print("Perfil olfativo eliminado exitosamente.")
        } catch {
            throw NSError(domain: "OlfactiveProfileService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Error al eliminar el perfil olfativo: \(error.localizedDescription)"])
        }
    }
}
