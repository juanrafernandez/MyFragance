import Foundation
import Combine
import SwiftUI

@MainActor
public final class FamilyViewModel: ObservableObject {
    @Published var familias: [Family] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: IdentifiableString?

    let familiaService: FamilyServiceProtocol

    // MARK: - Inicialización con Dependencias Inyectadas
    init(
        familiaService: FamilyServiceProtocol = DependencyContainer.shared.familyService
    ) {
        self.familiaService = familiaService
    }

    // MARK: - Cargar Datos Iniciales
    func loadInitialData() async {
        isLoading = true
        do {
            familias = try await familiaService.fetchFamilias()
            #if DEBUG
            print("Familias cargadas exitosamente. Total: \(familias.count)")
            #endif
            // Iniciar la escucha de cambios en tiempo real
            startListeningToFamilias()
        }
        catch {
            handleError("Error al cargar familias: \(error.localizedDescription)")
        }
        isLoading = false
    }

    // MARK: - Manejo de Errores
    private func handleError(_ message: String) {
        errorMessage = IdentifiableString(value: message)
    }
    
    // MARK: - Escuchar Cambios en Tiempo Real
    func startListeningToFamilias() {
        familiaService.listenToFamiliasChanges { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let updatedFamilias):
                    self?.familias = updatedFamilias
                case .failure(let error):
                    self?.errorMessage = IdentifiableString(value: "Error al escuchar cambios: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func getFamily(byKey id: String) -> Family? {
        return familias.first { $0.key == id }
    }
    
    func getFamilia(byID id: String) -> Family? {
        return familias.first { $0.id == id }
    }

    func getRecommendedSeason(byID id: String) -> [String]? {
        return getFamilia(byID: id)?.recommendedSeason
    }

    func getOcasion(byID id: String) -> [String]? {
        return getFamilia(byID: id)?.occasion
    }
}
