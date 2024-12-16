import SwiftUI

class SuggestionsViewModel: ObservableObject {
    @Published var recomendaciones: [FamiliaOlfativa] = []

    private let familiaService = FamiliaOlfativaService()

    func generarRecomendaciones(basadoEn respuestas: [String: Option]) {
        let familias = familiaService.loadFamilias()

        // Debugging: Ver respuestas y familias cargadas
        print("Respuestas del usuario: \(respuestas)")
        print("Familias cargadas: \(familias)")

        // Lógica de filtrado
        let personalidad = respuestas["personalidad"]?.value ?? ""
        let preferenciaSensorial = respuestas["preferenciaSensorial"]?.value ?? ""
        let estacionFavorita = respuestas["clima"]?.value ?? ""

        recomendaciones = familias.filter { familia in
            let coincidePersonalidad = familia.personalidadAsociada.contains(personalidad)
            let coincideSensorial = familia.notasClave.contains(preferenciaSensorial)
            let coincideEstacion = familia.estacionRecomendada.contains(estacionFavorita)

            return coincidePersonalidad || coincideSensorial || coincideEstacion
        }

        // Debugging: Ver las recomendaciones generadas
        print("Recomendaciones generadas: \(recomendaciones)")
    }
}
