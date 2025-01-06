import Foundation

class GiftRecomendacionViewModel: ObservableObject {
    @Published var perfilPrincipal: String? = "Desconocido"
    @Published var perfilSecundario: String? = ""
    @Published var recomendaciones: [Perfume] = []

    private var respuestas: [String: Option] = [:]

    init(respuestas: [String: Option]) {
        self.respuestas = respuestas
        calcularPerfil()
    }

    func calcularPerfil() {
//        var puntuaciones: [String: Int] = [:]
//
//        // Sumar puntos según las familias asociadas a las respuestas
//        for (_, opcion) in respuestas {
//            guard let familias = opcion.familiasAsociadas else { continue }
//            for (familia, puntos) in familias {
//                puntuaciones[familia, default: 0] += puntos
//            }
//        }
//
//        // Ordenar familias por puntuación
//        let ordenadas = puntuaciones.sorted { $0.value > $1.value }
//        if let principal = ordenadas.first?.key {
//            perfilPrincipal = principal
//        }
//        if ordenadas.count > 1 {
//            perfilSecundario = ordenadas[1].key
//        }
//
//        // Generar recomendaciones basadas en las familias
//        recomendaciones = PerfumeManager().getAllPerfumes().filter { perfume in
//            perfume.familia.lowercased() == perfilPrincipal?.lowercased()
//        }
//
//        // Si no hay recomendaciones basadas en el perfil principal, busca en el secundario
//        if recomendaciones.isEmpty, let secundario = perfilSecundario {
//            recomendaciones = PerfumeManager().getAllPerfumes().filter { perfume in
//                perfume.familia.lowercased() == secundario.lowercased()
//            }
//        }

        // Si aún no hay recomendaciones, generar una recomendación por defecto
        if recomendaciones.isEmpty {
            recomendaciones = [
//                Perfume(
//                    id: "default",
//                    nombre: "Sin Recomendaciones",
//                    familia: "Desconocida",
//                    popularidad: 0.0,
//                    image_name: "",
//                    notas: ["No se encontraron coincidencias"], fabricante: ""
//                )
            ]
        }
    }

}
