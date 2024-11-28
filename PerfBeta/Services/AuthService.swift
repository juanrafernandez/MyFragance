import FirebaseAuth
import FirebaseFirestore

class AuthService {
    private let db = Firestore.firestore()
    static let shared = AuthService()
    
    private init() {}
    
    /// Registra un usuario y guarda su información en Firestore
    func registerUser(email: String, password: String, nombre: String, rol: String = "usuario", completion: @escaping (Result<Void, Error>) -> Void) {
        // Registro en Firebase Authentication
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let user = authResult?.user else {
                completion(.failure(NSError(domain: "AuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Usuario no encontrado"])))
                return
            }

            // Guardar información del usuario en Firestore
            let userData: [String: Any] = [
                "uid": user.uid,
                "nombre": nombre,
                "email": user.email ?? "",
                "rol": rol
            ]

            self.db.collection("usuarios").document(user.uid).setData(userData) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    func signInWithEmail(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
