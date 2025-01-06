import SwiftUI
import SwiftData

class OlfactiveProfileViewModel: ObservableObject {
    @Published var profiles: [OlfactiveProfile] = []
    @Published var isLoading: Bool = false
    
    private let modelContext: ModelContext
    private let service: OlfactiveProfileService

    // Inicializador único
    init(context: ModelContext, service: OlfactiveProfileService = OlfactiveProfileService()) {
        self.modelContext = context
        self.service = service
        self.profiles = [] // Inicializamos propiedades necesarias
        self.fetchProfiles() // Llamada segura a métodos
    }

    func fetchProfiles() {
        let fetchDescriptor = FetchDescriptor<OlfactiveProfile>(
            sortBy: [SortDescriptor(\.name, order: .forward)]
        )
        do {
            profiles = try modelContext.fetch(fetchDescriptor)
        } catch {
            print("Error al obtener perfiles olfativos: \(error.localizedDescription)")
        }
    }

    func addProfile(_ profile: OlfactiveProfile) {
        profiles.append(profile)
        service.saveProfile(profile)
    }

    func deleteProfile(_ profile: OlfactiveProfile) {
        profiles.removeAll { $0.id == profile.id }
        service.deleteProfile(profile)
    }
}
