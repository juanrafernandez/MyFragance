import Foundation
import Combine
import SwiftUI

@MainActor
public final class PerfumeViewModel: ObservableObject {
    @Published var perfumes: [Perfume] = [] // Lista de perfumes
    @Published var isLoading: Bool = false // Estado de carga
    @Published var errorMessage: IdentifiableString? // Mensaje de error

    private let perfumeService: PerfumeServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(perfumeService: PerfumeServiceProtocol = DependencyContainer.shared.perfumeService) {
        self.perfumeService = perfumeService
    }

    // MARK: - Cargar Perfumes Inicialmente
    @MainActor
    func loadInitialData() async {
        isLoading = true
        do {
            let perfumesStored = try await perfumeService.fetchAllPerfumesOnce()
            print("Perfumes cargados: \(perfumesStored.count) perfumes")
            self.perfumes = perfumesStored
            isLoading = false
        } catch {
            self.handleError("Error al cargar perfumes: \(error.localizedDescription)")
            print("Error fetching perfumes: \(error)")
        }
        //isLoading = false
    }

    // MARK: - Manejo de Errores
    private func handleError(_ message: String) {
        errorMessage = IdentifiableString(value: message)
    }

    func getRelatedPerfumes(for profile: OlfactiveProfile) -> [Perfume] {
        return OlfactiveProfileHelper.suggestPerfumes(perfil: profile, baseDeDatos: perfumes)
    }
    
    // MARK: - Obtener Perfume por Clave
    func getPerfume(byKey key: String) async throws -> Perfume? {
        // Primero, busca en la lista de perfumes cargados
        if let perfume = perfumes.first(where: { $0.key == key }) {
            return perfume
        }
        
        // Si no se encuentra en la lista cargada, intenta cargarlo desde el servicio
        return try await perfumeService.fetchPerfume(byKey: key)
    }
}
