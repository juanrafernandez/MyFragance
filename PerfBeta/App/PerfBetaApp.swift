import SwiftUI
import FirebaseCore
import FirebaseFirestore
import Kingfisher
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {

    func clearFirestoreCache() {
        guard FirebaseApp.app() != nil else {
            #if DEBUG
            print("❌ Error Firestore Cache: Firebase no configurado.")
            #endif
            return
        }
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        let db = Firestore.firestore()
        db.settings = settings
        db.clearPersistence { error in
            #if DEBUG
            if let error = error { print("❌ Error Firestore Cache: \(error.localizedDescription)") }
            else { print("✅ Firestore Cache Cleared.") }
            #endif
        }
    }

    static func configureKingfisherCache() {
        let cache = ImageCache.default
        cache.memoryStorage.config.totalCostLimit = 50 * 1024 * 1024
        cache.diskStorage.config.sizeLimit = 200 * 1024 * 1024

        // ✅ NUEVO: Caché de imágenes SIN expiración (permanente)
        cache.diskStorage.config.expiration = .never

        #if DEBUG
        print("✅ Kingfisher Configured (Memory: 50MB, Disk: 200MB, Expiration: Never)")
        #endif
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        #if DEBUG
        print("➡️ AppDelegate: didFinishLaunchingWithOptions INICIO")
        #endif

        guard let firebaseApp = FirebaseApp.app(), let clientID = firebaseApp.options.clientID else {
             fatalError("❌ FATAL ERROR en AppDelegate: FirebaseApp no disponible o Client ID no encontrado. ¿Se llamó a configure() en PerfBetaApp.init()?")
        }
        #if DEBUG
        print("ℹ️ AppDelegate: Firebase ya configurado (verificado).")
        #endif

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        #if DEBUG
        print("✅ Google Sign In Configured in AppDelegate")
        #endif

        Self.configureKingfisherCache()

        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings()
        Firestore.firestore().settings = settings
        #if DEBUG
        print("✅ Firestore Persistence Configured in AppDelegate")
        #endif

        #if DEBUG
        print("⬅️ AppDelegate: didFinishLaunchingWithOptions FIN")
        #endif
        return true
    }

    func application(_ app: UIApplication,
                       open url: URL,
                       options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        var handled: Bool
        handled = GIDSignIn.sharedInstance.handle(url)
        if handled {
            #if DEBUG
            print("✅ URL Handled by Google Sign In")
            #endif
            return true
        }
        #if DEBUG
        print("⚠️ URL Not Handled by Google Sign In: \(url)")
        #endif
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

    // MARK: - Network Monitor
    @State private var networkMonitor = NetworkMonitor()

    // MARK: - Scene Phase (para auto-sync)
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Initialization
    // Setup order:
    // 1. Firebase configuration (once)
    // 2. Services creation (lazy in DependencyContainer)
    // 3. ViewModels initialization with dependency injection
    init() {
        #if DEBUG
        print("🚀 PerfBetaApp Init - Iniciando configuración...")
        #endif

        // Step 1: Configure Firebase (once)
        if FirebaseApp.app() == nil {
            #if DEBUG
            print("🔥 PerfBetaApp Init: Firebase NO configurado. Llamando a FirebaseApp.configure()...")
            #endif

            // ✅ Reduce Firebase logging verbosity (only errors in production)
            #if DEBUG
            FirebaseConfiguration.shared.setLoggerLevel(.min) // Only critical errors
            #else
            FirebaseConfiguration.shared.setLoggerLevel(.error) // Production: errors only
            #endif

            FirebaseApp.configure()
            #if DEBUG
            print("✅ PerfBetaApp Init: Firebase configurado.")
            #endif
        } else {
            #if DEBUG
            print("ℹ️ PerfBetaApp Init: Firebase YA estaba configurado.")
            #endif
        }

        // Step 2: Initialize dependency container (lazy services)
        #if DEBUG
        print("🔩 DependencyContainer inicializado (servicios son lazy).")
        #endif
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

        #if DEBUG
        print("✅ PerfBetaApp ViewModels Initialized.")
        #endif
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
            .onChange(of: scenePhase, initial: false) { oldPhase, newPhase in
                handleScenePhaseChange(oldPhase: oldPhase, newPhase: newPhase)
            }
        }
    }

    // MARK: - Auto-Sync Logic

    /// Maneja cambios de estado de la app (background/foreground)
    private func handleScenePhaseChange(oldPhase: ScenePhase, newPhase: ScenePhase) {
        if oldPhase == .background && newPhase == .active {
            #if DEBUG
            print("🔄 [PerfBetaApp] App regresó al foreground")
            #endif
            handleAppBecameActive()
        }
    }

    /// Ejecuta sync incremental si han pasado 24h desde el último sync
    private func handleAppBecameActive() {
        Task {
            do {
                // Verificar si necesita sync (último sync > 24h)
                let shouldSync = await shouldPerformSync()

                if shouldSync {
                    #if DEBUG
                    print("⏰ [PerfBetaApp] Han pasado >24h desde último sync, ejecutando sync incremental...")
                    #endif
                    try await MetadataIndexManager.shared.syncIncrementalChanges()
                    #if DEBUG
                    print("✅ [PerfBetaApp] Sync incremental completado")
                    #endif
                } else {
                    #if DEBUG
                    print("ℹ️ [PerfBetaApp] Sync no necesario (última sincronización reciente)")
                    #endif
                }
            } catch {
                #if DEBUG
                print("⚠️ [PerfBetaApp] Error en auto-sync: \(error.localizedDescription)")
                #endif
            }
        }
    }

    /// Verifica si han pasado más de 24 horas desde el último sync
    private func shouldPerformSync() async -> Bool {
        guard let lastSync = await CacheManager.shared.getLastSyncTimestamp(for: "metadata_index") else {
            #if DEBUG
            print("ℹ️ [PerfBetaApp] No hay timestamp de sync previo")
            #endif
            return false // Primera vez, no forzar sync aquí (se hace en getMetadataIndex)
        }

        let hoursSinceSync = Date().timeIntervalSince(lastSync) / 3600

        if hoursSinceSync >= 24 {
            #if DEBUG
            print("⏰ [PerfBetaApp] Han pasado \(String(format: "%.1f", hoursSinceSync))h desde último sync")
            #endif
            return true
        } else {
            #if DEBUG
            print("ℹ️ [PerfBetaApp] Solo han pasado \(String(format: "%.1f", hoursSinceSync))h desde último sync")
            #endif
            return false
        }
    }
}
