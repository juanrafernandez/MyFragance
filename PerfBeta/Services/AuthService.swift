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
    func checkAndCreateUserProfileIfNeeded(firebaseUser: FirebaseAuth.User, providedName: String?, isLoginAttempt: Bool) async throws
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
        AppLogger.info("AuthService initialized", category: .auth)
    }

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

            AppLogger.info("User registered and profile created for \(user.uid)", category: .auth)
        } catch let authError as NSError where authError.domain == AuthErrorDomain {
            AppLogger.error("Firebase Auth error during registration: \(authError)", category: .auth)
            throw AuthServiceError.coreError(authError)
        } catch let firestoreError {
            AppLogger.error("Firestore error saving profile during registration: \(firestoreError)", category: .auth)
            throw AuthServiceError.dataSaveError(firestoreError)
        } catch {
            AppLogger.error("Unknown error during registration: \(error)", category: .auth)
            throw AuthServiceError.unknownError
        }
    }

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
            try await checkAndCreateUserProfileIfNeeded(firebaseUser: authResult.user, providedName: nil, isLoginAttempt: true)
            AppLogger.info("Email Sign in successful for \(authResult.user.uid)", category: .auth)
        } catch let error as NSError where error.domain == AuthErrorDomain {
            AppLogger.error("Firebase Auth error during email sign in: \(error)", category: .auth)
            throw AuthServiceError.coreError(error)
        } catch let profileError as AuthServiceError {
            AppLogger.error("Profile check error during email sign in: \(profileError)", category: .auth)
            throw profileError
        } catch {
            AppLogger.error("Unknown error during email sign in: \(error)", category: .auth)
            throw AuthServiceError.unknownError
        }
    }

    private func updateUserLastLoginTimestamp(userId: String) async throws {
        let userRef = db.collection(usersCollection).document(userId)
        do {
            try await userRef.updateData(["lastLoginAt": FieldValue.serverTimestamp()])
            AppLogger.debug("Updated lastLoginAt for \(userId)", category: .auth)
        } catch {
            AppLogger.warning("Firestore error updating lastLoginAt for user \(userId): \(error.localizedDescription)", category: .auth)
            // No relanzamos, es un fallo menor
        }
    }

    func signOut() throws {
        do {
            try firebaseAuth.signOut()
            AppLogger.info("User signed out", category: .auth)
        } catch let error {
            AppLogger.error("Error signing out: \(error)", category: .auth)
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
        AppLogger.debug("Checking profile for \(userId). Is Login Attempt: \(isLoginAttempt)", category: .auth)

        do {
            PerformanceLogger.logFirestoreQuery("users/\(userId)", filters: "getDocument")
            let documentSnapshot = try await userRef.getDocument()

            if documentSnapshot.exists {
                AppLogger.debug("Profile found for \(userId)", category: .auth)
                if isLoginAttempt {
                    try await updateUserLastLoginTimestamp(userId: userId)
                    AppLogger.info("Login successful, timestamp updated", category: .auth)
                } else {
                    AppLogger.warning("Profile already exists for \(userId) during registration attempt", category: .auth)
                    throw AuthServiceError.coreError(NSError(domain: AuthErrorDomain, code: AuthErrorCode.emailAlreadyInUse.rawValue, userInfo: [NSLocalizedDescriptionKey: "Account already exists."]))
                }
            } else {
                AppLogger.debug("Profile NOT found for \(userId)", category: .auth)
                if isLoginAttempt {
                    AppLogger.warning("Profile not found for \(userId) during login attempt", category: .auth)
                    throw AuthServiceError.userNotFound
                } else {
                    AppLogger.info("Creating new profile for \(userId) during registration", category: .auth)
                    var nameToSave = providedName ?? firebaseUser.displayName ?? ""
                    if nameToSave.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        nameToSave = firebaseUser.email?.components(separatedBy: "@").first ?? "Usuario \(userId.prefix(4))"
                        AppLogger.debug("No provided/display name, using generated name: \(nameToSave)", category: .auth)
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

                    AppLogger.info("Successfully created new profile for \(userId)", category: .auth)
                }
            }
        } catch let specificError as AuthServiceError {
            AppLogger.debug("Specific AuthServiceError caught: \(specificError)", category: .auth)
            throw specificError
        } catch let firestoreError {
            AppLogger.error("Firestore error during profile check/create for \(userId): \(firestoreError)", category: .auth)
            throw AuthServiceError.dataSaveError(firestoreError)
        } catch {
            AppLogger.error("Unknown error during profile check/create for \(userId): \(error)", category: .auth)
            throw AuthServiceError.unknownError
        }
    }

    func addAuthStateListener(completion: @escaping (Auth, FirebaseAuth.User?) -> Void) -> AuthStateDidChangeListenerHandle? {
        return firebaseAuth.addStateDidChangeListener(completion)
    }
}
