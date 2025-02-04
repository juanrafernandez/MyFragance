import Foundation

enum Season: String, CaseIterable, Identifiable {
    case spring = "spring"
    case summer = "summer"
    case autumn = "autumn"
    case winter = "winter"

    var id: String { rawValue }

    var displayName: String {
        return NSLocalizedString(self.rawValue, comment: "")
    }
}
