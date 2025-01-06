import FirebaseFirestore
import Combine
import SwiftData

class PerfumeService: ObservableObject {
    private var db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private let modelContext: ModelContext

    @Published var perfumes: [Perfume] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func startListeningToPerfumes() {
        listener = db.collection("perfumes").addSnapshotListener { [weak self] (snapshot, error) in
            if let error = error {
                print("Error al escuchar cambios: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            // Actualizar perfumes con los datos del backend
            self?.perfumes = documents.compactMap { doc -> Perfume? in
                Perfume(from: doc.data())
            }
            
            // Sincronizar con SwiftData
            self?.updateCache()
        }
    }

    func stopListeningToPerfumes() {
        listener?.remove()
    }

    private func updateCache() {
        for perfume in perfumes {
            let fetchDescriptor = FetchDescriptor<Perfume>(
                predicate: #Predicate { $0.id == perfume.id }
            )
            
            if var existingPerfume = try? modelContext.fetch(fetchDescriptor).first {
                // Actualizar perfume existente
                existingPerfume.nombre = perfume.nombre
                existingPerfume.marca = perfume.marca
                existingPerfume.familia = perfume.familia
                existingPerfume.notasPrincipales = perfume.notasPrincipales
                existingPerfume.notasSalida = perfume.notasSalida
                existingPerfume.notasCorazon = perfume.notasCorazon
                existingPerfume.notasFondo = perfume.notasFondo
                existingPerfume.proyeccion = perfume.proyeccion
                existingPerfume.duracion = perfume.duracion
                existingPerfume.anio = perfume.anio
                existingPerfume.perfumista = perfume.perfumista
                existingPerfume.imagenURL = perfume.imagenURL
                existingPerfume.descripcion = perfume.descripcion
                existingPerfume.genero = perfume.genero
            } else {
                // Insertar nuevo perfume en SwiftData
                modelContext.insert(perfume)
            }
        }
    }
}
