import Foundation

class FamiliaOlfativaService {
    func loadFamilias() -> [FamiliaOlfativa] {
        guard let url = Bundle.main.url(forResource: "familiasOlfativas", withExtension: "json") else {
            print("Error: No se encontró el archivo familiasOlfativas.json")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let familias = try JSONDecoder().decode([FamiliaOlfativa].self, from: data)
            print("Familias cargadas exitosamente: \(familias)")
            return familias
        } catch {
            print("Error al cargar familias olfativas: \(error)")
            return []
        }
    }
}

