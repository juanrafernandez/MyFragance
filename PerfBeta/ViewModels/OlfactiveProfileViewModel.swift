import Foundation
import Combine
import SwiftUI

@MainActor
public final class OlfactiveProfileViewModel: ObservableObject {
    @Published var profiles: [OlfactiveProfile] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: IdentifiableString?

    private let olfactiveProfileService: OlfactiveProfileServiceProtocol

    // MARK: - Inicialización con inyección de dependencias
    init(
        olfactiveProfileService: OlfactiveProfileServiceProtocol = DependencyContainer.shared.olfactiveProfileService
    ) {
        self.olfactiveProfileService = olfactiveProfileService
    }

    // MARK: - Cargar Perfiles Olfativos desde Firestore
    func loadInitialData() async {
        isLoading = true
        do {
            profiles = try await olfactiveProfileService.fetchProfiles()
            print("✅ Perfiles olfativos cargados: \(profiles.count)")
            startListeningToProfiles()
        } catch {
            handleError("Error al cargar perfiles olfativos: \(error.localizedDescription)")
        }
        isLoading = false
    }

    // MARK: - Escuchar Cambios en Firestore
    func startListeningToProfiles() {
        olfactiveProfileService.listenToProfilesChanges { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let updatedProfiles):
                    self?.profiles = updatedProfiles
                    print("✅ Perfiles actualizados: \(updatedProfiles.count)")
                case .failure(let error):
                    self?.handleError("Error al escuchar cambios en los perfiles olfativos: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Agregar o Actualizar Perfil en Firestore
    func addOrUpdateProfile(_ profile: OlfactiveProfile) async {
        do {
            try await olfactiveProfileService.addOrUpdateProfile(profile)
            if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
                profiles[index] = profile
            } else {
                profiles.append(profile)
            }
            print("✅ Perfil agregado o actualizado exitosamente.")
        } catch {
            handleError("Error al guardar el perfil olfativo: \(error.localizedDescription)")
        }
    }

    // MARK: - Eliminar Perfil en Firestore
    func deleteProfile(_ profile: OlfactiveProfile) async {
        do {
            try await olfactiveProfileService.deleteProfile(profile)
            profiles.removeAll { $0.id == profile.id }
            print("✅ Perfil eliminado exitosamente.")
        } catch {
            handleError("Error al eliminar el perfil olfativo: \(error.localizedDescription)")
        }
    }

    // MARK: - Manejo de Errores
    private func handleError(_ message: String) {
        errorMessage = IdentifiableString(value: message)
    }
}
