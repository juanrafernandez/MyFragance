import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseCore

final class DependencyContainer {
    static let shared = DependencyContainer()

    private lazy var firestoreInstance: Firestore = {
        #if DEBUG
        print("🔥 DependencyContainer: Creando instancia Firestore...")
        #endif
        let instance = Firestore.firestore()
        #if DEBUG
        print("✅ DependencyContainer: Instancia Firestore obtenida.")
        #endif
        return instance
    }()

    lazy var authService: AuthServiceProtocol = {
        #if DEBUG
        print("🔧 DependencyContainer: Creando AuthService...")
        #endif
        return AuthService(firestore: self.firestoreInstance)
    }()

    lazy var userService: UserServiceProtocol = {
        #if DEBUG
        print("🔧 DependencyContainer: Creando UserService...")
        #endif
        return UserService()
    }()

    lazy var perfumeService: PerfumeServiceProtocol = {
        #if DEBUG
        print("🔧 DependencyContainer: Creando PerfumeService...")
        #endif
        return PerfumeService()
    }()

    lazy var brandService: BrandServiceProtocol = {
        #if DEBUG
        print("🔧 DependencyContainer: Creando BrandService...")
        #endif
        return BrandService()
    }()

    lazy var familyService: FamilyServiceProtocol = {
        #if DEBUG
        print("🔧 DependencyContainer: Creando FamilyService...")
        #endif
        return FamilyService()
    }()

    lazy var notesService: NotesServiceProtocol = {
        #if DEBUG
        print("🔧 DependencyContainer: Creando NotesService...")
        #endif
        return NotesService()
    }()

    lazy var perfumistService: PerfumistServiceProtocol = {
        #if DEBUG
        print("🔧 DependencyContainer: Creando PerfumistService...")
        #endif
        return PerfumistService()
    }()

    lazy var questionsService: QuestionsServiceProtocol = {
        #if DEBUG
        print("🔧 DependencyContainer: Creando QuestionsService...")
        #endif
        return QuestionsService()
    }()

    lazy var testService: TestServiceProtocol = {
        #if DEBUG
        print("🔧 DependencyContainer: Creando TestService...")
        #endif
        return TestService()
    }()

    lazy var olfactiveProfileService: OlfactiveProfileServiceProtocol = {
        #if DEBUG
        print("🔧 DependencyContainer: Creando OlfactiveProfileService...")
        #endif
        return OlfactiveProfileService()
    }()

    private init() {
        #if DEBUG
        print("🔩 DependencyContainer inicializado (servicios son lazy).")
        #endif
    }
}
