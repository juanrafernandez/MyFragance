import Foundation
import SwiftUI

struct OlfactiveProfile {
    let name: String
    let perfumes: [Perfume]
    let gradientColors: [Color]
}

// Ejemplo de perfiles simulados
let mockProfiles = [
    OlfactiveProfile(
        name: "Amaderado",
        perfumes: MockPerfumes.perfumes.filter { $0.familia == "amaderados" },
        gradientColors: [Color("champan"), Color("grisSuave")]
    ),
    OlfactiveProfile(
        name: "Cítrico",
        perfumes: MockPerfumes.perfumes.filter { $0.familia == "citricos" },
        gradientColors: [Color("fondoClaro"), Color("champanOscuro")]
    )
]
