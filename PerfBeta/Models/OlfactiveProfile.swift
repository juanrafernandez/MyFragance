import Foundation
import SwiftUI

struct OlfactiveProfile: Identifiable, Equatable, Hashable {
    let id = UUID() // ID único generado automáticamente
    let name: String // Nombre del perfil
    let perfumes: [Perfume] // Lista de perfumes asociados
    let familia: FamiliaOlfativa // Familia olfativa asociada
    let description: String? // Descripción breve del perfil (opcional)
    let icon: String? // Icono representativo del perfil (opcional)
}

// Ejemplo de perfiles simulados
let familiaManager = FamiliaOlfativaManager()
let mockProfiles = [
    OlfactiveProfile(
        name: "Amaderado",
        perfumes: MockPerfumes.perfumes.filter { $0.familia == "amaderados" },
        familia: familiaManager.getFamilia(byID: "amaderados") ?? FamiliaOlfativa(
            id: "amaderados",
            nombre: "Amaderados",
            descripcion: "Descripción predeterminada.",
            notasClave: [],
            ingredientesAsociados: [],
            intensidadPromedio: "Media",
            estacionRecomendada: [],
            personalidadAsociada: [],
            color: "#8B4513"
        ),
        description: "Fragancias cálidas y sofisticadas con notas de sándalo y cedro.",
        icon: "icon_amaderado"
    )
]


