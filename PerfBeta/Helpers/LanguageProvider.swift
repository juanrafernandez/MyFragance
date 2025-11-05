import Foundation

/// Protocol for providing language configuration to services.
/// This abstraction allows services to depend on language without coupling to AppState singleton.
protocol LanguageProvider {
    /// The current language code (e.g., "es", "en")
    var language: String { get }
}

/// Default implementation using AppState for production use
extension AppState: LanguageProvider {
    // AppState already has `language` property, so it automatically conforms
}

/// Mock implementation for testing
class MockLanguageProvider: LanguageProvider {
    var language: String

    init(language: String = "es") {
        self.language = language
    }
}
