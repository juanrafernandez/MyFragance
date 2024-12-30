import SwiftUI

class TriedPerfumesManager: ObservableObject {
    @Published var triedPerfumes: [Perfume] = MockPerfumes.perfumes

    func removePerfume(_ perfume: Perfume) {
        triedPerfumes.removeAll { $0.id == perfume.id }
    }

    func move(from source: IndexSet, to destination: Int) {
        triedPerfumes.move(fromOffsets: source, toOffset: destination)
    }
    
    // Método para añadir un perfume
    func addPerfume(_ perfume: Perfume) {
        // Evitar duplicados
        if !triedPerfumes.contains(where: { $0.id == perfume.id }) {
            triedPerfumes.append(perfume)
        }
    }
}
