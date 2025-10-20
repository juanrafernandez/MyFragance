import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseCore

final class DependencyContainer {
    static let shared = DependencyContainer()

    private lazy var firestoreInstance: Firestore = {
        print("🔥 DependencyContainer: Creando instancia Firestore...")
        let instance = Firestore.firestore()
        print("✅ DependencyContainer: Instancia Firestore obtenida.")
        return instance
    }()

    lazy var authService: AuthServiceProtocol = {
        print("🔧 DependencyContainer: Creando AuthService...")
        return AuthService(firestore: self.firestoreInstance)
    }()

    lazy var userService: UserServiceProtocol = {
        print("🔧 DependencyContainer: Creando UserService...")
        return UserService(firestore: self.firestoreInstance)
    }()

    lazy var perfumeService: PerfumeServiceProtocol = {
        print("🔧 DependencyContainer: Creando PerfumeService...")
        return PerfumeService()
    }()

    lazy var brandService: BrandServiceProtocol = {
        print("🔧 DependencyContainer: Creando BrandService...")
        return BrandService()
    }()

    lazy var familyService: FamilyServiceProtocol = {
        print("🔧 DependencyContainer: Creando FamilyService...")
        return FamilyService()
    }()

    lazy var notesService: NotesServiceProtocol = {
        print("🔧 DependencyContainer: Creando NotesService...")
        return NotesService()
    }()

    lazy var perfumistService: PerfumistServiceProtocol = {
        print("🔧 DependencyContainer: Creando PerfumistService...")
        return PerfumistService()
    }()

    lazy var questionsService: QuestionsServiceProtocol = {
        print("🔧 DependencyContainer: Creando QuestionsService...")
        return QuestionsService()
    }()

    lazy var testService: TestServiceProtocol = {
        print("🔧 DependencyContainer: Creando TestService...")
        return TestService()
    }()

    lazy var olfactiveProfileService: OlfactiveProfileServiceProtocol = {
        print("🔧 DependencyContainer: Creando OlfactiveProfileService...")
        return OlfactiveProfileService()
    }()

    private init() {
        print("🔩 DependencyContainer inicializado (servicios son lazy).")
    }
}
