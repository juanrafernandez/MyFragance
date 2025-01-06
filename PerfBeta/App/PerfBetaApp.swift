import SwiftUI
import Firebase
import Kingfisher
import SwiftData

@main
struct PerfBetaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    // Managers y servicios
    @StateObject private var favoritesManager = FavoritesManager()
    @StateObject private var wishlistManager = WishlistManager()
    @StateObject private var triedPerfumesManager = TriedPerfumesManager()
    @StateObject private var familiaOlfativaViewModel: FamiliaOlfativaViewModel
    @StateObject private var perfumeViewModel: PerfumeViewModel
    @StateObject private var olfactiveProfileViewModel: OlfactiveProfileViewModel

    private let modelContainer: ModelContainer

    init() {
        // Configurar Kingfisher Cache
        let cache = ImageCache.default
        cache.memoryStorage.config.totalCostLimit = 100 * 1024 * 1024
        cache.diskStorage.config.expiration = .days(7)

        // Inicializar el contenedor de SwiftData
        modelContainer = try! ModelContainer(for: Perfume.self, FamiliaOlfativa.self, OlfactiveProfile.self)

        // Obtener el contexto antes de inicializar StateObjects
        let context = modelContainer.mainContext
        _familiaOlfativaViewModel = StateObject(wrappedValue: FamiliaOlfativaViewModel(context: context))
        _olfactiveProfileViewModel = StateObject(wrappedValue: OlfactiveProfileViewModel(context: context))

        // Configurar Apariencia
        setupAppearance()
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(favoritesManager)
                .environmentObject(wishlistManager)
                .environmentObject(triedPerfumesManager)
                .environmentObject(familiaOlfativaViewModel)
                .environmentObject(olfactiveProfileViewModel)
        }
        .modelContainer(modelContainer) // Vincula el ModelContainer a la vista principal
    }

    private func setupAppearance() {
        // Configuración de colores de la barra de navegación
        UINavigationBar.appearance().barTintColor = UIColor(named: "neutralBackground")
        UINavigationBar.appearance().titleTextAttributes = [
            .foregroundColor: UIColor(named: "secondaryMidnightBlue")!,
            .font: UIFont.systemFont(ofSize: 18, weight: .bold)
        ]

        // Configuración de la TabBar
        UITabBar.appearance().tintColor = UIColor(named: "primaryChampagne")
        UITabBar.appearance().barTintColor = UIColor(named: "neutralBackground")
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}
