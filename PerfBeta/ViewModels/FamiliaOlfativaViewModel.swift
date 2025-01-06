import Foundation
import SwiftData

class FamiliaOlfativaViewModel : ObservableObject {
    @Published var familias: [FamiliaOlfativa] = []
    private var modelContext: ModelContext

    init(context: ModelContext) {
        self.modelContext = context
        loadFamilias()
    }

    /// Carga familias desde SwiftData
    private func loadFamilias() {
        let fetchDescriptor = FetchDescriptor<FamiliaOlfativa>(
            sortBy: [SortDescriptor(\.nombre, order: .forward)]
        )

        do {
            familias = try modelContext.fetch(fetchDescriptor)
        } catch {
            print("Error al obtener las familias olfativas: \(error.localizedDescription)")
        }
    }

    /// Obtiene una familia olfativa por su ID
    func getFamilia(byID id: String) -> FamiliaOlfativa? {
        return familias.first { $0.id == id }
    }

    /// Obtiene la estación recomendada de una familia olfativa por su ID
    func getEstacionRecomendada(byID id: String) -> [String]? {
        guard let familia = getFamilia(byID: id) else {
            print("Error: No se encontró la familia con ID: \(id)")
            return nil
        }
        return familia.estacionRecomendada
    }

    /// Obtiene la ocasión ideal de una familia olfativa por su ID
    func getOcasion(byID id: String) -> [String]? {
        guard let familia = getFamilia(byID: id) else {
            print("Error: No se encontró la familia con ID: \(id)")
            return nil
        }
        return familia.ocasion
    }
}
