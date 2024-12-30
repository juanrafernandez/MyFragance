import Firebase
import FirebaseFirestore

class FirestoreService {
    private let db = Firestore.firestore()
    private let collectionName = "perfumes" // Nombre de la colección en Firestore
    
    // Agregar un Perfume
    func addPerfume(perfume: Perfume, completion: @escaping (Result<Void, Error>) -> Void) {
        let perfumeData: [String: Any] = [
            "nombre": perfume.nombre,
            "familia": perfume.familia,
            "popularidad": perfume.popularidad,
            "notas": perfume.notas
        ]
        
        db.collection(collectionName).addDocument(data: perfumeData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // Leer todos los Perfumes
//    func getPerfumes(completion: @escaping (Result<[Perfume], Error>) -> Void) {
//        db.collection(collectionName).getDocuments { snapshot, error in
//            if let error = error {
//                completion(.failure(error))
//            } else if let snapshot = snapshot {
//                let perfumes = snapshot.documents.compactMap { doc -> Perfume? in
//                    let data = doc.data()
//                    guard
//                        let nombre = data["nombre"] as? String,
//                        let familia = data["familia"] as? String,
//                        let popularidad = data["popularidad"] as? Double,
//                        let notas = data["notas"] as? [String]
//                    else { return nil }
//                    
//                    return Perfume(
//                        id: doc.documentID,
//                        nombre: nombre,
//                        familia: familia,
//                        popularidad: popularidad, image_name: "",
//                        notas: "",
//                        fabricante: notas, descripcionOlfativa: ""
//                    )
//                }
//                completion(.success(perfumes))
//            }
//        }
//    }
    
    // Actualizar un Perfume
    func updatePerfume(documentId: String, updatedData: [String: Any], completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection(collectionName).document(documentId).updateData(updatedData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // Eliminar un Perfume
    func deletePerfume(documentId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection(collectionName).document(documentId).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
