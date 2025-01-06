import FirebaseFirestore
import SwiftData
import Combine

class FamiliaOlfativaService: ObservableObject {
    private var db: Firestore
    private var listener: ListenerRegistration?
    private var modelContext: ModelContext

    @Published var familiasOlfativas: [FamiliaOlfativa] = []

    init(modelContext: ModelContext) {
        self.db = Firestore.firestore()
        self.modelContext = modelContext
    }

    /// Inicia la escucha de cambios en la colección `familiasOlfativas` en Firestore.
    func startListeningToFamiliasOlfativas() {
        listener = db.collection("familiasOlfativas").addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error {
                print("Error al escuchar cambios: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            // Convertir documentos de Firestore en modelos FamiliaOlfativa
            let familias: [FamiliaOlfativa] = documents.compactMap { doc in
                return FamiliaOlfativa(from: doc.data())
            }
            
            // Actualizar la memoria y sincronizar con SwiftData
            DispatchQueue.main.async {
                self.familiasOlfativas = familias
                self.updateCache(with: familias)
            }
        }
    }

    /// Detiene la escucha de cambios en Firestore.
    func stopListeningToFamiliasOlfativas() {
        listener?.remove()
    }

    /// Carga las familias olfativas almacenadas en SwiftData
    private func fetchLocalCache() {
        let fetchDescriptor = FetchDescriptor<FamiliaOlfativa>()
        
        do {
            let cachedFamilias = try modelContext.fetch(fetchDescriptor)
            DispatchQueue.main.async {
                self.familiasOlfativas = cachedFamilias
            }
        } catch {
            print("Error al cargar el caché local: \(error.localizedDescription)")
        }
    }
    
    /// Actualiza el caché local en SwiftData con las familias recibidas.
    private func updateCache(with familias: [FamiliaOlfativa]) {
        for familia in familias {
            // Crear un descriptor de búsqueda con un predicado adecuado
            let fetchDescriptor = FetchDescriptor<FamiliaOlfativa>(
                predicate: #Predicate { existingFamilia in
                    existingFamilia.id == familia.id
                }
            )

            if var existingFamilia = try? modelContext.fetch(fetchDescriptor).first {
                // Actualizar datos de la familia existente
                existingFamilia.nombre = familia.nombre
                existingFamilia.descripcion = familia.descripcion
                existingFamilia.color = familia.color
                existingFamilia.notasClave = familia.notasClave
                existingFamilia.ingredientesAsociados = familia.ingredientesAsociados
                existingFamilia.intensidadPromedio = familia.intensidadPromedio
                existingFamilia.estacionRecomendada = familia.estacionRecomendada
                existingFamilia.personalidadAsociada = familia.personalidadAsociada
                existingFamilia.ocasion = familia.ocasion
            } else {
                // Insertar nueva familia en SwiftData
                modelContext.insert(familia)
            }
        }
    }

    
//    func loadFamilias() -> [FamiliaOlfativa] {
//        guard let url = Bundle.main.url(forResource: "familiasOlfativas", withExtension: "json") else {
//            print("Error: No se encontró el archivo familiasOlfativas.json")
//            return []
//        }
//
//        do {
//            let data = try Data(contentsOf: url)
//            let familias = try JSONDecoder().decode([FamiliaOlfativa].self, from: data)
//            print("Familias cargadas exitosamente: \(familias)")
//            return familias
//        } catch {
//            print("Error al cargar familias olfativas: \(error)")
//            return []
//        }
//    }
}
