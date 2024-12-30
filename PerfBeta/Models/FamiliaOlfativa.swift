import Foundation

struct FamiliaOlfativa: Identifiable, Codable {
    let id: String // Identificador único
    let nombre: String // Nombre de la familia
    let descripcion: String // Breve descripción
    let notasClave: [String] // Ingredientes principales
    let ingredientesAsociados: [String] // Ingredientes secundarios o complementarios
    let intensidadPromedio: String // Intensidad media (Baja, Media, Alta)
    let estacionRecomendada: [String] // Estaciones ideales
    let personalidadAsociada: [String] // Perfiles de personalidad vinculados
    let color: String
}
