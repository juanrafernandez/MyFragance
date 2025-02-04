import Foundation

enum Gender: String, CaseIterable, Identifiable {
    case male = "male"
    case female = "female"
    case unisex = "unisex"

    var id: String { rawValue }

    /// Traducción automática usando `NSLocalizedString`
    var displayName: String {
        NSLocalizedString(self.rawValue, comment: "")
    }
}
