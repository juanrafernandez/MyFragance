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
    
    static func rawValue(forDisplayName displayName: String) -> String? {
        return Gender.allCases.first { gender in
            gender.displayName == displayName
        }?.rawValue
    }
}
