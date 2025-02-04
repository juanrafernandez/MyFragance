import Foundation

class AppState: ObservableObject {
    static let shared = AppState() // Singleton para acceder globalmente
    @Published var levelSelected: String = "beginner" // Valor inicial
    @Published var language: String = "es"
    private init() {}
}
