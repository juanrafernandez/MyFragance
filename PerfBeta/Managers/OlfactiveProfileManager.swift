import SwiftUI
import Combine

class OlfactiveProfileManager: ObservableObject {
    @Published var profiles: [OlfactiveProfile] = []

    private let familiaManager = FamiliaOlfativaManager()

    init() {
        loadMockProfiles()
    }

    private func loadMockProfiles() {
        guard let amaderados = familiaManager.getFamilia(byID: "amaderados"),
              let citricos = familiaManager.getFamilia(byID: "citricos") else {
            print("Error: No se pudieron cargar las familias iniciales.")
            return
        }

        profiles = [
            OlfactiveProfile(
                name: "Invierno Especial",
                perfumes: MockPerfumes.perfumes.filter { $0.familia == "amaderados" },
                familia: amaderados,
                description: "Un regalo especial con aromas amaderados.",
                icon: "icon_amaderado"
            ),
            OlfactiveProfile(
                name: "Verano Fresco",
                perfumes: MockPerfumes.perfumes.filter { $0.familia == "citricos" },
                familia: citricos,
                description: "Fragancias frescas y cítricas para el verano.",
                icon: "icon_citricos"
            )
        ]
    }

    func addProfile(_ profile: OlfactiveProfile) {
        profiles.append(profile)
    }

    func deleteProfile(named name: String) {
        profiles.removeAll { $0.name == name }
    }
}
