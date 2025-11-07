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
        #if DEBUG
        print("AuthService Initialized (Explicit Firestore Provided)")
        #endif
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

            #if DEBUG
            print("AuthService: User registered and profile created for \(user.uid)")
            #endif
        } catch let authError as NSError where authError.domain == AuthErrorDomain {
            #if DEBUG
            print("AuthService: Firebase Auth error during registration: \(authError)")
            #endif
            throw AuthServiceError.coreError(authError)
        } catch let firestoreError {
            #if DEBUG
            print("AuthService: Firestore error saving profile during registration: \(firestoreError)")
            #endif
            throw AuthServiceError.dataSaveError(firestoreError)
        } catch {
            #if DEBUG
            print("AuthService: Unknown error during registration: \(error)")
            #endif
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
            #if DEBUG
            print("AuthService: Email Sign in successful for \(authResult.user.uid)")
            #endif
        } catch let error as NSError where error.domain == AuthErrorDomain {
            #if DEBUG
            print("AuthService: Firebase Auth error during email sign in: \(error)")
            #endif
            throw AuthServiceError.coreError(error)
        } catch let profileError as AuthServiceError {
            #if DEBUG
            print("AuthService: Profile check error during email sign in: \(profileError)")
            #endif
            throw profileError // Relanzar error del check (ej: userNotFound si es inconsistente)
        }
        catch {
            #if DEBUG
            print("AuthService: Unknown error during email sign in: \(error)")
            #endif
            throw AuthServiceError.unknownError
        }
    }

    private func updateUserLastLoginTimestamp(userId: String) async throws {
        let userRef = db.collection(usersCollection).document(userId)
        do {
            try await userRef.updateData(["lastLoginAt": FieldValue.serverTimestamp()])
            #if DEBUG
            print("AuthService: Updated lastLoginAt for \(userId)")
            #endif
        } catch {
            #if DEBUG
            print("❌ AuthService: Firestore Error updating lastLoginAt for user \(userId): \(error.localizedDescription)")
            #endif
            // No relanzamos, es un fallo menor
        }
    }

    func signOut() throws {
        do {
            try firebaseAuth.signOut()
            #if DEBUG
            print("AuthService: User signed out.")
            #endif
        } catch let error {
            #if DEBUG
            print("❌ AuthService: Error signing out: \(error)")
            #endif
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
        #if DEBUG
        print("AuthService: Checking profile for \(userId). Is Login Attempt: \(isLoginAttempt)")
        #endif

        do {
            PerformanceLogger.logFirestoreQuery("users/\(userId)", filters: "getDocument")
            let documentSnapshot = try await userRef.getDocument()

            if documentSnapshot.exists {
                #if DEBUG
                print("AuthService: Profile found for \(userId).")
                #endif
                if isLoginAttempt {
                    try await updateUserLastLoginTimestamp(userId: userId)
                    #if DEBUG
                    print("AuthService: Login successful, timestamp updated.")
                    #endif
                } else {
                    #if DEBUG
                    print("AuthService: Profile already exists for \(userId) during registration attempt. Throwing error.")
                    #endif
                    throw AuthServiceError.coreError(NSError(domain: AuthErrorDomain, code: AuthErrorCode.emailAlreadyInUse.rawValue, userInfo: [NSLocalizedDescriptionKey: "Account already exists."]))
                }
            } else {
                #if DEBUG
                print("AuthService: Profile NOT found for \(userId).")
                #endif
                if isLoginAttempt {
                    #if DEBUG
                    print("AuthService: Profile not found for \(userId) during login attempt. Throwing error.")
                    #endif
                    throw AuthServiceError.userNotFound
                } else {
                    #if DEBUG
                    print("AuthService: Creating new profile for \(userId) during registration.")
                    #endif
                    var nameToSave = providedName ?? firebaseUser.displayName ?? ""
                    if nameToSave.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        nameToSave = firebaseUser.email?.components(separatedBy: "@").first ?? "Usuario \(userId.prefix(4))"
                        #if DEBUG
                        print("AuthService: No provided/display name, using generated name: \(nameToSave)")
                        #endif
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

                    #if DEBUG
                    print("AuthService: Successfully created new profile for \(userId).")
                    #endif
                }
            }
        } catch let specificError as AuthServiceError {
            #if DEBUG
            print("AuthService: Specific AuthServiceError caught: \(specificError)")
            #endif
            throw specificError
        }
        catch let firestoreError {
            #if DEBUG
            print("❌ AuthService: Firestore error during profile check/create for \(userId): \(firestoreError)")
            #endif
            throw AuthServiceError.dataSaveError(firestoreError)
        }
        catch {
            #if DEBUG
            print("❌ AuthService: Unknown error during profile check/create for \(userId): \(error)")
            #endif
            throw AuthServiceError.unknownError
        }
    }

    func addAuthStateListener(completion: @escaping (Auth, FirebaseAuth.User?) -> Void) -> AuthStateDidChangeListenerHandle? {
        return firebaseAuth.addStateDidChangeListener(completion)
    }
}
