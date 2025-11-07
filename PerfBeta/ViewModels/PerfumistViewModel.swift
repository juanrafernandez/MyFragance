import Foundation
import Combine
import SwiftUI

@MainActor
public final class PerfumistViewModel: ObservableObject {
    @Published var perfumists: [Perfumist] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: IdentifiableString?

    private let perfumistService: PerfumistServiceProtocol

    // MARK: - Inicialización con Dependencias Inyectadas
    init(
        perfumistService: PerfumistServiceProtocol = DependencyContainer.shared.perfumistService
    ) {
        self.perfumistService = perfumistService
    }

    // MARK: - Cargar Datos Iniciales
    func loadInitialData() async {
        isLoading = true
        do {
            perfumists = try await perfumistService.fetchPerfumists()
            #if DEBUG
            print("Perfumistas cargados exitosamente. Total: \(perfumists.count)")
            #endif
            // Iniciar la escucha de cambios en tiempo real
            startListeningToPerfumists()
        } catch {
            handleError("Error al cargar perfumistas: \(error.localizedDescription)")
        }
        isLoading = false
    }

    // MARK: - Buscar Perfumista por Nombre (Opcional)
    func fetchPerfumistByName(name: String) async -> Perfumist? {
        do {
            return try await perfumistService.fetchPerfumistByName(name: name)
        } catch {
            handleError("Error al buscar perfumista por nombre: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Manejo de Errores
    private func handleError(_ message: String) {
        errorMessage = IdentifiableString(value: message)
    }
    
    // MARK: - Escuchar Cambios en Tiempo Real
    func startListeningToPerfumists() {
        perfumistService.listenToPerfumistsChanges { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let updatedPerfumists):
                    self?.perfumists = updatedPerfumists
                case .failure(let error):
                    self?.errorMessage = IdentifiableString(value: "Error al escuchar cambios: \(error.localizedDescription)")
                }
            }
        }
    }
}
