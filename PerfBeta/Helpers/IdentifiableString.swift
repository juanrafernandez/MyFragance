import Foundation

struct IdentifiableString: Identifiable {
    let id = UUID()
    let value: String
}
