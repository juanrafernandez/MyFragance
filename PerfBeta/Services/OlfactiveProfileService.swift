import Foundation
import FirebaseFirestore
import SwiftData

class OlfactiveProfileService {
    private var db = Firestore.firestore()
    
    func fetchProfiles(completion: @escaping ([OlfactiveProfile]) -> Void) {
        db.collection("olfactiveProfiles").getDocuments { snapshot, error in
            if let error = error {
                print("Error al obtener perfiles: \(error.localizedDescription)")
                completion([])
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion([])
                return
            }
            
            let profiles = documents.compactMap { doc -> OlfactiveProfile? in
                OlfactiveProfile(from: doc.data()) // Inicializador para Firestore
            }
            completion(profiles)
        }
    }
    
    func saveProfile(_ profile: OlfactiveProfile) {
        let profileData = profile.toDictionary()
        db.collection("olfactiveProfiles").document(profile.id).setData(profileData) { error in
            if let error = error {
                print("Error al guardar el perfil: \(error.localizedDescription)")
            } else {
                print("Perfil guardado exitosamente")
            }
        }
    }
    
    func deleteProfile(_ profile: OlfactiveProfile) {
        db.collection("olfactiveProfiles").document(profile.id).delete { error in
            if let error = error {
                print("Error al eliminar el perfil: \(error.localizedDescription)")
            } else {
                print("Perfil eliminado exitosamente")
            }
        }
    }
}
