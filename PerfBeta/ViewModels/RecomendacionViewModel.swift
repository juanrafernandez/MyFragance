import Foundation

class RecomendacionViewModel: ObservableObject {
    @Published var perfilPrincipal: String = ""
    @Published var perfilSecundario: String = ""
    @Published var puntajes: [String: Int] = [:]

    func calcularPerfil(respuestas: [String: Option]) {
        var puntosFamilias: [String: Int] = [:]

        // Iterar sobre las respuestas del usuario
        for (_, respuesta) in respuestas {
            // Sumar puntos de las familias asociadas a la opción seleccionada
            for (familia, puntos) in respuesta.familiasAsociadas {
                puntosFamilias[familia, default: 0] += puntos
            }
        }

        // Ordenar las familias por puntaje
        let familiasOrdenadas = puntosFamilias.sorted { $0.value > $1.value }

        // Asignar perfil principal y secundario
        if let principal = familiasOrdenadas.first {
            perfilPrincipal = principal.key
        }
        if familiasOrdenadas.count > 1 {
            perfilSecundario = familiasOrdenadas[1].key
        }

        // Guardar puntajes
        puntajes = puntosFamilias
        print("Puntajes calculados: \(puntajes)")
    }
}
