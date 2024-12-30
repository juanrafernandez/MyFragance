import Foundation

class FamiliaOlfativaManager: ObservableObject {
    @Published var familias: [FamiliaOlfativa] = []

    init() {
        loadFamilias()
    }

    private func loadFamilias() {
        guard let url = Bundle.main.url(forResource: "familiasOlfativas", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("Error: No se pudo cargar el archivo JSON.")
            return
        }

        do {
            let decoder = JSONDecoder()
            let loadedFamilias = try decoder.decode([FamiliaOlfativa].self, from: data)
            familias = loadedFamilias
        } catch {
            print("Error al decodificar el JSON: \(error)")
        }
    }

    func getFamilia(byID id: String) -> FamiliaOlfativa? {
        return familias.first { $0.id == id }
    }
}
