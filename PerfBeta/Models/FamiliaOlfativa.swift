import Foundation

struct FamiliaOlfativa: Identifiable, Codable {
    let id: String
    let nombre: String
    let descripcion: String
    let notasClave: [String]
    let intensidadPromedio: String
    let estacionRecomendada: [String]
    let personalidadAsociada: [String]
}
