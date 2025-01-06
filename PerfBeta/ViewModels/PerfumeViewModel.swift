import SwiftUI
import Combine
import SwiftData

class PerfumeViewModel: ObservableObject {
    @Published var perfumes: [Perfume] = [] // Datos visibles en la vista
    @Published var filteredPerfumes: [Perfume] = [] // Para filtros
    private var modelContext: ModelContext
    private var cancellables = Set<AnyCancellable>()

    init(context: ModelContext) {
        self.modelContext = context
        loadPerfumes()
    }

    /// Carga inicial de perfumes desde SwiftData
    func loadPerfumes() {
        do {
            let fetchDescriptor = FetchDescriptor<Perfume>()
            let results = try modelContext.fetch(fetchDescriptor)
            DispatchQueue.main.async {
                self.perfumes = results
            }
        } catch {
            print("Error al cargar perfumes: \(error.localizedDescription)")
        }
    }

    /// Filtra perfumes por género
    func filterPerfumes(byGenero genero: String) {
        filteredPerfumes = perfumes.filter { $0.genero.lowercased() == genero.lowercased() }
    }

    func filterPerfumes(byGenero genero: String? = nil, byFamilia familia: String? = nil) {
        filteredPerfumes = perfumes.filter { perfume in
            let matchesGenero = genero == nil || perfume.genero.lowercased() == genero?.lowercased()
            let matchesFamilia = familia == nil || perfume.familia.lowercased() == familia?.lowercased()
            return matchesGenero && matchesFamilia
        }
    }

    /// Agrega un nuevo perfume
    func addPerfume(_ perfume: Perfume) {
        modelContext.insert(perfume)
        saveChanges()
        loadPerfumes()
    }

    /// Elimina un perfume
    func deletePerfume(_ perfume: Perfume) {
        modelContext.delete(perfume)
        saveChanges()
        loadPerfumes()
    }

    /// Guarda los cambios en el contexto
    private func saveChanges() {
        do {
            try modelContext.save()
        } catch {
            print("Error al guardar cambios: \(error.localizedDescription)")
        }
    }
    
    let mockPerfumes = [
        Perfume(
            id: "1",
            nombre: "Citrus Breeze",
            marca: "Adolfo Domínguez",
            familia: "citricos",
            notasPrincipales: ["Limón", "Pomelo", "Vetiver"],
            notasSalida: ["Limón", "Pomelo", "Mandarina"],
            notasCorazon: ["Jazmín", "Ylang-Ylang", "Naranja"],
            notasFondo: ["Vetiver", "Ámbar"],
            proyeccion: "Moderada",
            duracion: "4-6 horas",
            anio: 2020,
            perfumista: "Jean Claude Ellena",
            imagenURL: "adolfo_dominguez_agua_tonka",
            descripcion: "Una fragancia cítrica y vibrante, ideal para días soleados.",
            genero: "masculino"
        ),
        Perfume(
            id: "2",
            nombre: "Floral Bloom",
            marca: "Giorgio Armani",
            familia: "florales",
            notasPrincipales: ["Rosa", "Jazmín", "Almizcle"],
            notasSalida: ["Bergamota", "Neroli"],
            notasCorazon: ["Rosa", "Jazmín", "Peonía"],
            notasFondo: ["Almizcle", "Madera de Cedro"],
            proyeccion: "Intensa",
            duracion: "6-8 horas",
            anio: 2018,
            perfumista: "Dominique Ropion",
            imagenURL: "aqua_di_gio_profondo",
            descripcion: "Una fragancia floral y elegante que evoca jardines en primavera.",
            genero: "femenino"
        ),
        Perfume(
            id: "3",
            nombre: "Woody Warmth",
            marca: "Armani",
            familia: "amaderados",
            notasPrincipales: ["Pimienta Rosa", "Canela", "Sándalo"],
            notasSalida: ["Pimienta Rosa", "Bergamota"],
            notasCorazon: ["Canela", "Madera de Oud"],
            notasFondo: ["Sándalo", "Vetiver"],
            proyeccion: "Moderada",
            duracion: "8-10 horas",
            anio: 2019,
            perfumista: "Alberto Morillas",
            imagenURL: "armani_code",
            descripcion: "Un perfume amaderado y cálido con un toque exótico.",
            genero: "masculino"
        ),
        Perfume(
            id: "4",
            nombre: "Sweet Delight",
            marca: "Dolce & Gabbana",
            familia: "gourmand",
            notasPrincipales: ["Vainilla", "Caramelo", "Chocolate"],
            notasSalida: ["Vainilla", "Canela"],
            notasCorazon: ["Caramelo", "Chocolate"],
            notasFondo: ["Miel", "Tonka"],
            proyeccion: "Intensa",
            duracion: "6-8 horas",
            anio: 2021,
            perfumista: "Olivier Cresp",
            imagenURL: "dolce_gabana_light_blue",
            descripcion: "Una fragancia dulce y seductora con notas gourmand.",
            genero: "femenino"
        ),
        Perfume(
            id: "5",
            nombre: "Ocean Breeze",
            marca: "Givenchy",
            familia: "acuaticos",
            notasPrincipales: ["Cáscara de Limón", "Brisa Marina", "Lavanda"],
            notasSalida: ["Cáscara de Limón", "Brisa Marina"],
            notasCorazon: ["Cilantro", "Lavanda"],
            notasFondo: ["Madera de Cedro", "Almizcle"],
            proyeccion: "Moderada",
            duracion: "4-6 horas",
            anio: 2017,
            perfumista: "Francis Kurkdjian",
            imagenURL: "givenchy_gentleman_Intense",
            descripcion: "Un aroma fresco y marino que captura la esencia del océano.",
            genero: "masculino"
        )
    ]
}
