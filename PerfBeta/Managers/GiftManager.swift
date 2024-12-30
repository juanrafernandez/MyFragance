import Foundation

class GiftManager: ObservableObject {
    @Published var searches: [GiftSearch] = []

    init() {
        loadSearches()
    }

    func addSearch(_ search: GiftSearch) {
        searches.append(search)
        saveSearches()
    }

    func deleteSearch(at indexSet: IndexSet) {
        searches.remove(atOffsets: indexSet)
        saveSearches()
    }

    private func loadSearches() {
        if let data = UserDefaults.standard.data(forKey: "giftSearches"),
           let decoded = try? JSONDecoder().decode([GiftSearch].self, from: data) {
            searches = decoded
        } else {
            searches = mockSearches // Carga mocks si no hay datos
        }
    }

    private func saveSearches() {
        if let encoded = try? JSONEncoder().encode(searches) {
            UserDefaults.standard.set(encoded, forKey: "giftSearches")
        }
    }
}
