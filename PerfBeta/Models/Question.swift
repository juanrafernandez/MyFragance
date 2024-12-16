import Foundation

struct Question: Codable, Identifiable {
    let id: String
    let category: String
    let text: String
    let options: [Option]
}
