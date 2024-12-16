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
    }
    
    var body: some Scene {
        WindowGroup {
            //ContentView()
            //    .environmentObject(AuthViewModel())
            //TestView()
            MainTabView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure() // Configura Firebase
        return true
    }
}
