import SwiftUI
import FirebaseCore
import FirebaseFirestore
import Kingfisher

class AppDelegate: NSObject, UIApplicationDelegate {
    static func configureFirebase() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }

    func clearFirestoreCache() {
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true // Asegúrate de que la persistencia esté habilitada (si ya lo está, puedes omitir esto)

        let db = Firestore.firestore()
        db.settings = settings

        db.clearPersistence { error in
            if let error = error {
                print("❌ Error al limpiar la caché de Firestore: \(error.localizedDescription)")
            } else {
                print("✅ Caché de Firestore limpiada exitosamente.")
            }
        }
    }
    
    // Configuración del caché de Kingfisher
    static func configureKingfisherCache() {
        let cache = ImageCache.default
        cache.memoryStorage.config.totalCostLimit = 50 * 1024 * 1024 // 50 MB en memoria
        cache.diskStorage.config.sizeLimit = 200 * 1024 * 1024 // 200 MB en disco
        print("Kingfisher cache configurado")
    }
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        Self.configureFirebase()
        Self.configureKingfisherCache()
        //self.clearFirestoreCache()
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings()
        Firestore.firestore().settings = settings

        print("Firebase configurado con persistencia local de Firestore")
        return true
    }
}

@main
struct PerfBetaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // Instanciamos el contenedor después de configurar Firebase
    private lazy var dependencyContainer = DependencyContainer.shared
    @StateObject private var appState = AppState.shared
    @StateObject private var brandViewModel = BrandViewModel(brandService: DependencyContainer.shared.brandService)
    @StateObject private var perfumeViewModel = PerfumeViewModel(perfumeService: DependencyContainer.shared.perfumeService)
    @StateObject private var familyViewModel = FamilyViewModel(familiaService: DependencyContainer.shared.familyService)
    @StateObject private var notesViewModel = NotesViewModel(notesService: DependencyContainer.shared.notesService)
    @StateObject private var testViewModel = TestViewModel(questionsService: DependencyContainer.shared.testService)
    @StateObject private var olfactiveProfileViewModel = OlfactiveProfileViewModel(olfactiveProfileService: DependencyContainer.shared.olfactiveProfileService)
    @StateObject private var userViewModel = UserViewModel(userService: DependencyContainer.shared.userService)
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appState)
                .environmentObject(brandViewModel)
                .environmentObject(perfumeViewModel)
                .environmentObject(familyViewModel)
                .environmentObject(notesViewModel)
                .environmentObject(testViewModel)
                .environmentObject(olfactiveProfileViewModel)
                .environmentObject(userViewModel)
        }
    }
}
