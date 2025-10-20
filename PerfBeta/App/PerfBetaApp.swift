import SwiftUI
import FirebaseCore
import FirebaseFirestore
import Kingfisher
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {

    func clearFirestoreCache() {
        guard FirebaseApp.app() != nil else {
            print("❌ Error Firestore Cache: Firebase no configurado.")
            return
        }
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        let db = Firestore.firestore()
        db.settings = settings
        db.clearPersistence { error in
            if let error = error { print("❌ Error Firestore Cache: \(error.localizedDescription)") }
            else { print("✅ Firestore Cache Cleared.") }
        }
    }

    static func configureKingfisherCache() {
        let cache = ImageCache.default
        cache.memoryStorage.config.totalCostLimit = 50 * 1024 * 1024
        cache.diskStorage.config.sizeLimit = 200 * 1024 * 1024
        print("✅ Kingfisher Configured")
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        print("➡️ AppDelegate: didFinishLaunchingWithOptions INICIO")

        guard let firebaseApp = FirebaseApp.app(), let clientID = firebaseApp.options.clientID else {
             fatalError("❌ FATAL ERROR en AppDelegate: FirebaseApp no disponible o Client ID no encontrado. ¿Se llamó a configure() en PerfBetaApp.init()?")
        }
        print("ℹ️ AppDelegate: Firebase ya configurado (verificado).")

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        print("✅ Google Sign In Configured in AppDelegate")

        Self.configureKingfisherCache()

        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings()
        Firestore.firestore().settings = settings
        print("✅ Firestore Persistence Configured in AppDelegate")

        print("⬅️ AppDelegate: didFinishLaunchingWithOptions FIN")
        return true
    }

    func application(_ app: UIApplication,
                       open url: URL,
                       options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        var handled: Bool
        handled = GIDSignIn.sharedInstance.handle(url)
        if handled {
            print("✅ URL Handled by Google Sign In")
            return true
        }
        print("⚠️ URL Not Handled by Google Sign In: \(url)")
        return false
    }
}

@main
struct PerfBetaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    private var dependencyContainer = DependencyContainer.shared

    // MARK: - ViewModels
    @StateObject private var authViewModel: AuthViewModel
    @StateObject private var appState: AppState
    @StateObject private var brandViewModel: BrandViewModel
    @StateObject private var perfumeViewModel: PerfumeViewModel
    @StateObject private var familyViewModel: FamilyViewModel
    @StateObject private var notesViewModel: NotesViewModel
    @StateObject private var testViewModel: TestViewModel
    @StateObject private var olfactiveProfileViewModel: OlfactiveProfileViewModel
    @StateObject private var userViewModel: UserViewModel

    // MARK: - Network Monitor (NUEVO)
    @State private var networkMonitor = NetworkMonitor()

    init() {
        print("🚀 PerfBetaApp Init - Iniciando configuración...")

        if FirebaseApp.app() == nil {
            print("🔥 PerfBetaApp Init: Firebase NO configurado. Llamando a FirebaseApp.configure()...")
            FirebaseApp.configure()
            print("✅ PerfBetaApp Init: Firebase configurado.")
        } else {
            print("ℹ️ PerfBetaApp Init: Firebase YA estaba configurado.")
        }

        print("🚀 PerfBetaApp Init - Creando ViewModels...")
        let container = self.dependencyContainer
        let authServ = container.authService
        let appSt = AppState.shared
        let brandServ = container.brandService
        let perfumeServ = container.perfumeService
        let familyServ = container.familyService
        let notesServ = container.notesService
        let testServ = container.testService
        let olfactiveServ = container.olfactiveProfileService
        let userServ = container.userService

        let authVM = AuthViewModel(authService: authServ)

        _authViewModel = StateObject(wrappedValue: authVM)
        _appState = StateObject(wrappedValue: appSt)
        _brandViewModel = StateObject(wrappedValue: BrandViewModel(brandService: brandServ))
        _perfumeViewModel = StateObject(wrappedValue: PerfumeViewModel(perfumeService: perfumeServ))
        _familyViewModel = StateObject(wrappedValue: FamilyViewModel(familiaService: familyServ))
        _notesViewModel = StateObject(wrappedValue: NotesViewModel(notesService: notesServ))
        _testViewModel = StateObject(wrappedValue: TestViewModel(questionsService: testServ))
        _olfactiveProfileViewModel = StateObject(wrappedValue: OlfactiveProfileViewModel(
            olfactiveProfileService: olfactiveServ,
            authViewModel: authVM,
            appState: appSt
        ))
        _userViewModel = StateObject(wrappedValue: UserViewModel(
            userService: userServ,
            authViewModel: authVM
        ))

        print("✅ PerfBetaApp ViewModels Initialized.")
    }

    var body: some Scene {
        WindowGroup {
            ZStack(alignment: .top) {
                // MARK: - Contenido Principal
                ContentView()
                    .environmentObject(authViewModel)
                    .environmentObject(appState)
                    .environmentObject(brandViewModel)
                    .environmentObject(perfumeViewModel)
                    .environmentObject(familyViewModel)
                    .environmentObject(notesViewModel)
                    .environmentObject(testViewModel)
                    .environmentObject(olfactiveProfileViewModel)
                    .environmentObject(userViewModel)
                    .environment(networkMonitor) // ✅ Nuevo: Network monitor disponible en toda la app

                // MARK: - Network Status Banner (NUEVO)
                if !networkMonitor.isConnected {
                    NetworkStatusBanner(networkMonitor: networkMonitor)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(999) // Asegurar que esté arriba de todo
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: networkMonitor.isConnected)
        }
    }
}
