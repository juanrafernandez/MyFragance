import SwiftUI
import Firebase
import Kingfisher

@main
struct PerfBetaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        let cache = ImageCache.default
        cache.memoryStorage.config.totalCostLimit = 100 * 1024 * 1024
        cache.diskStorage.config.expiration = .days(7)
        setupAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            //ContentView()
            //    .environmentObject(AuthViewModel())
            //TestView()
            MainTabView()
        }
    }
    
    func setupAppearance() {
        // Colores de la barra de navegación
        UINavigationBar.appearance().barTintColor = UIColor.neutralBackground
        UINavigationBar.appearance().titleTextAttributes = [
            .foregroundColor: UIColor.secondaryMidnightBlue,
            .font: UIFont.systemFont(ofSize: 18, weight: .bold)
        ]
        
        // TabBar
        UITabBar.appearance().tintColor = UIColor.primaryChampagne
        UITabBar.appearance().barTintColor = UIColor.neutralBackground
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure() // Configura Firebase
        return true
    }
}
