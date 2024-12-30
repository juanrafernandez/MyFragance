import Foundation
import SwiftUI

struct GiftSearch: Identifiable, Codable {
    let id: UUID // Identificador único
    let name: String // Nombre de la búsqueda
    let description: String // Descripción breve
    let perfumes: [Perfume] // Lista de perfumes recomendados
    let familia: FamiliaOlfativa // Familia olfativa asociada
    let icon: String? // Icono representativo (opcional)

    // Gradiente basado en el color de la familia
    var gradientColors: [Color] {
        [Color.white, Color(hex: familia.color).opacity(0.2)]
    }
}

let familiaGiftManager = FamiliaOlfativaManager()

let mockSearches = [
    GiftSearch(
        id: UUID(),
        name: "Regalo para Marta",
        description: "Florales y frescos",
        perfumes: MockPerfumes.perfumes.filter { $0.familia == "florales" },
        familia: FamiliaOlfativa(
            id: "florales",
            nombre: "Florales",
            descripcion: "Fragancias románticas y delicadas.",
            notasClave: ["Rosa", "Jazmín"],
            ingredientesAsociados: ["Gardenia"],
            intensidadPromedio: "Media",
            estacionRecomendada: ["Primavera"],
            personalidadAsociada: ["Romántico"],
            color: "#FFB6C1"
        ),
        icon: "icon_florales"
    ),
    GiftSearch(
        id: UUID(),
        name: "Cumpleaños de Pedro",
        description: "Amaderados intensos",
        perfumes: MockPerfumes.perfumes.filter { $0.familia == "amaderados" },
        familia: FamiliaOlfativa(
            id: "amaderados",
            nombre: "Amaderados",
            descripcion: "Perfumes cálidos y sofisticados.",
            notasClave: ["Sándalo", "Cedro"],
            ingredientesAsociados: ["Vetiver"],
            intensidadPromedio: "Alta",
            estacionRecomendada: ["Invierno"],
            personalidadAsociada: ["Elegante"],
            color: "#8B4513"
        ),
        icon: "icon_amaderados"
    )
]
