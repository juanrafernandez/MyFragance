import Foundation
import FirebaseAuth
import FirebaseFirestore

enum AuthServiceError: Error {
    case userNotFound
    case coreError(Error)
    case dataSaveError(Error)
    case unknownError
}

protocol AuthServiceProtocol {
    func registerUser(email: String, password: String, nombre: String, rol: String) async throws
    func signInWithEmail(email: String, password: String) async throws
    func signOut() throws
    func getCurrentAuthUser() -> User?
    func checkAndCreateUserProfileIfNeeded(firebaseUser: FirebaseAuth.User, providedName: String?, isLoginAttempt: Bool) async throws // <-- Modificado
    func addAuthStateListener(completion: @escaping (Auth, FirebaseAuth.User?) -> Void) -> AuthStateDidChangeListenerHandle?
}

class AuthService: AuthServiceProtocol {
    private let db: Firestore
    private let usersCollection = "users"

    private var firebaseAuth: Auth {
        return Auth.auth()
    }

    init(firestore: Firestore) {
        self.db = firestore
        print("AuthService Initialized (Explicit Firestore Provided)")
    }

    // TODO: NO CACHE IMPLEMENTATION - creates user in Firebase Auth and Firestore every time
    // ⚠️ PERFORMANCE ISSUE: Blocks UI during registration flow
    func registerUser(email: String, password: String, nombre: String, rol: String = "usuario") async throws {
        let startTime = Date()
        PerformanceLogger.trackFetch("registerUser-\(email)")
        PerformanceLogger.logNetworkStart("registerUser(email: \(email))")

        defer {
            let duration = Date().timeIntervalSince(startTime)
            PerformanceLogger.logNetworkEnd("registerUser(email: \(email))", duration: duration)
        }

        do {
            PerformanceLogger.logFirestoreQuery("firebase-auth", filters: "createUser")
            let authResult = try await firebaseAuth.createUser(withEmail: email, password: password)
            let user = authResult.user
            let userData: [String: Any] = [
                "uid": user.uid,
                "nombre": nombre,
                "email": user.email ?? "",
                "rol": rol,
                "createdAt": FieldValue.serverTimestamp(),
                "lastLoginAt": FieldValue.serverTimestamp(),
                "preferences": [:],
                "favoritePerfumes": [],
                "triedPerfumes": [],
                "wishlistPerfumes": []
            ]

            let firestoreStart = Date()
            PerformanceLogger.logFirestoreQuery("users/\(user.uid)", filters: "setData")
            try await db.collection(self.usersCollection).document(user.uid).setData(userData)
            PerformanceLogger.logFirestoreResult("users/\(user.uid)", count: 1, duration: Date().timeIntervalSince(firestoreStart))

            print("AuthService: User registered and profile created for \(user.uid)")
        } catch let authError as NSError where authError.domain == AuthErrorDomain {
            print("AuthService: Firebase Auth error during registration: \(authError)")
            throw AuthServiceError.coreError(authError)
        } catch let firestoreError {
             print("AuthService: Firestore error saving profile during registration: \(firestoreError)")
            throw AuthServiceError.dataSaveError(firestoreError)
        } catch {
             print("AuthService: Unknown error during registration: \(error)")
            throw AuthServiceError.unknownError
        }
    }

    // TODO: NO CACHE IMPLEMENTATION - authenticates with Firebase Auth and checks Firestore profile every time
    // ⚠️ PERFORMANCE ISSUE: Blocks UI during login flow
    func signInWithEmail(email: String, password: String) async throws {
        let startTime = Date()
        PerformanceLogger.trackFetch("signInWithEmail-\(email)")
        PerformanceLogger.logNetworkStart("signInWithEmail(email: \(email))")

        defer {
            let duration = Date().timeIntervalSince(startTime)
            PerformanceLogger.logNetworkEnd("signInWithEmail(email: \(email))", duration: duration)
        }

        do {
            PerformanceLogger.logFirestoreQuery("firebase-auth", filters: "signIn")
            let authResult = try await firebaseAuth.signIn(withEmail: email, password: password)
            try await checkAndCreateUserProfileIfNeeded(firebaseUser: authResult.user, providedName: nil, isLoginAttempt: true) // Llamada interna es siempre login
            print("AuthService: Email Sign in successful for \(authResult.user.uid)")
        } catch let error as NSError where error.domain == AuthErrorDomain {
            print("AuthService: Firebase Auth error during email sign in: \(error)")
            throw AuthServiceError.coreError(error)
        } catch let profileError as AuthServiceError {
             print("AuthService: Profile check error during email sign in: \(profileError)")
             throw profileError // Relanzar error del check (ej: userNotFound si es inconsistente)
        }
        catch {
             print("AuthService: Unknown error during email sign in: \(error)")
            throw AuthServiceError.unknownError
        }
    }

    private func updateUserLastLoginTimestamp(userId: String) async throws {
        let userRef = db.collection(usersCollection).document(userId)
        do {
            try await userRef.updateData(["lastLoginAt": FieldValue.serverTimestamp()])
            print("AuthService: Updated lastLoginAt for \(userId)")
        } catch {
            print("❌ AuthService: Firestore Error updating lastLoginAt for user \(userId): \(error.localizedDescription)")
            // No relanzamos, es un fallo menor
        }
    }

    func signOut() throws {
        do {
            try firebaseAuth.signOut()
            print("AuthService: User signed out.")
        } catch let error {
             print("❌ AuthService: Error signing out: \(error)")
            throw AuthServiceError.coreError(error)
        }
    }

    func getCurrentAuthUser() -> User? {
        guard let firebaseUser = firebaseAuth.currentUser else { return nil }
        return User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? "",
            displayName: firebaseUser.displayName ?? "Usuario",
            photoURL: firebaseUser.photoURL?.absoluteString,
            createdAt: firebaseUser.metadata.creationDate ?? Date(),
            updatedAt: Date()
        )
    }

    // TODO: NO CACHE IMPLEMENTATION - checks/creates user profile in Firestore every time
    // ⚠️ PERFORMANCE ISSUE: Called on every login/registration, no cache of user profile
    func checkAndCreateUserProfileIfNeeded(firebaseUser: FirebaseAuth.User, providedName: String?, isLoginAttempt: Bool) async throws {
        let userId = firebaseUser.uid
        let startTime = Date()
        PerformanceLogger.trackFetch("checkAndCreateUserProfile-\(userId)")
        PerformanceLogger.logNetworkStart("checkAndCreateUserProfile(userId: \(userId), isLogin: \(isLoginAttempt))")

        defer {
            let duration = Date().timeIntervalSince(startTime)
            PerformanceLogger.logNetworkEnd("checkAndCreateUserProfile(userId: \(userId))", duration: duration)
        }

        let userRef = db.collection(self.usersCollection).document(userId)
        print("AuthService: Checking profile for \(userId). Is Login Attempt: \(isLoginAttempt)")

        do {
            PerformanceLogger.logFirestoreQuery("users/\(userId)", filters: "getDocument")
            let documentSnapshot = try await userRef.getDocument()

            if documentSnapshot.exists {
                print("AuthService: Profile found for \(userId).")
                if isLoginAttempt {
                    try await updateUserLastLoginTimestamp(userId: userId)
                    print("AuthService: Login successful, timestamp updated.")
                } else {
                    print("AuthService: Profile already exists for \(userId) during registration attempt. Throwing error.")
                    throw AuthServiceError.coreError(NSError(domain: AuthErrorDomain, code: AuthErrorCode.emailAlreadyInUse.rawValue, userInfo: [NSLocalizedDescriptionKey: "Account already exists."]))
                }
            } else {
                 print("AuthService: Profile NOT found for \(userId).")
                if isLoginAttempt {
                     print("AuthService: Profile not found for \(userId) during login attempt. Throwing error.")
                     throw AuthServiceError.userNotFound
                } else {
                    print("AuthService: Creating new profile for \(userId) during registration.")
                    var nameToSave = providedName ?? firebaseUser.displayName ?? ""
                    if nameToSave.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        nameToSave = firebaseUser.email?.components(separatedBy: "@").first ?? "Usuario \(userId.prefix(4))"
                        print("AuthService: No provided/display name, using generated name: \(nameToSave)")
                    }

                    let newUserData: [String: Any] = [
                        "uid": userId,
                        "nombre": nameToSave,
                        "email": firebaseUser.email ?? "",
                        "rol": "usuario",
                        "createdAt": FieldValue.serverTimestamp(),
                        "lastLoginAt": FieldValue.serverTimestamp(),
                        "preferences": [:],
                        "favoritePerfumes": [],
                        "triedPerfumes": [],
                        "wishlistPerfumes": []
                    ]

                    let createStart = Date()
                    PerformanceLogger.logFirestoreQuery("users/\(userId)", filters: "setData(newProfile)")
                    try await userRef.setData(newUserData)
                    PerformanceLogger.logFirestoreResult("users/\(userId)", count: 1, duration: Date().timeIntervalSince(createStart))

                    print("AuthService: Successfully created new profile for \(userId).")
                }
            }
        } catch let specificError as AuthServiceError {
             print("AuthService: Specific AuthServiceError caught: \(specificError)")
             throw specificError
        }
        catch let firestoreError {
            print("❌ AuthService: Firestore error during profile check/create for \(userId): \(firestoreError)")
            throw AuthServiceError.dataSaveError(firestoreError)
        }
        catch {
             print("❌ AuthService: Unknown error during profile check/create for \(userId): \(error)")
            throw AuthServiceError.unknownError
        }
    }

    func addAuthStateListener(completion: @escaping (Auth, FirebaseAuth.User?) -> Void) -> AuthStateDidChangeListenerHandle? {
        return firebaseAuth.addStateDidChangeListener(completion)
    }
}
