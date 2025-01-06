import SwiftUI

class TriedPerfumesManager: ObservableObject {
    @Published var triedPerfumes: [Perfume] = []

    private let perfumeManager = PerfumeManager()

    /// Inicializador que utiliza `PerfumeManager` para cargar datos iniciales
    init() {
        self.triedPerfumes = perfumeManager.getAllPerfumes() // Carga inicial desde PerfumeManager
    }

    /// Elimina un perfume de la lista de probados
    func removePerfume(_ perfume: Perfume) {
        triedPerfumes.removeAll { $0.id == perfume.id }
    }

    /// Reorganiza los perfumes en la lista
    func move(from source: IndexSet, to destination: Int) {
        triedPerfumes.move(fromOffsets: source, toOffset: destination)
    }
    
    /// Añade un perfume a la lista de probados
    func addPerfume(_ perfume: Perfume) {
        if !triedPerfumes.contains(where: { $0.id == perfume.id }) {
            triedPerfumes.append(perfume)
        }
    }

    /// Filtra perfumes probados por género
    func getTriedPerfumes(byGenero genero: String) -> [Perfume] {
        return triedPerfumes.filter { $0.genero.lowercased() == genero.lowercased() }
    }

    /// Filtra perfumes probados por género y familia
    func getTriedPerfumes(byGenero genero: String? = nil, byFamilia familia: String? = nil) -> [Perfume] {
        return triedPerfumes.filter { perfume in
            let matchesGenero = genero == nil || perfume.genero.lowercased() == genero?.lowercased()
            let matchesFamilia = familia == nil || perfume.familia.lowercased() == familia?.lowercased()
            return matchesGenero && matchesFamilia
        }
    }
}
