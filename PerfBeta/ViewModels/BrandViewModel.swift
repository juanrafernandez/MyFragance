import Foundation
import Combine
import SwiftUI

@MainActor
public final class BrandViewModel: ObservableObject {
    @Published var brands: [Brand] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: IdentifiableString? // Para manejar errores identificables

    private let brandService: BrandServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Inicialización con Dependencias Inyectadas
    init(
        brandService: BrandServiceProtocol = DependencyContainer.shared.brandService
    ) {
        self.brandService = brandService
    }

    // MARK: - Cargar Marcas Inicialmente
    func loadInitialData() async {
        isLoading = true
        do {
            brands = try await brandService.fetchBrands()
            print("Marcas cargadas exitosamente. Total: \(brands.count)")
            // Iniciar la escucha de cambios en tiempo real
            startListeningToBrands()
        } catch {
            errorMessage = IdentifiableString(value: "Error al cargar marcas: \(error.localizedDescription)")
        }
        isLoading = false
    }

    // MARK: - Escuchar Cambios en Tiempo Real
    func startListeningToBrands() {
        brandService.listenToBrands { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let updatedBrands):
                    self?.brands = updatedBrands
                case .failure(let error):
                    self?.errorMessage = IdentifiableString(value: "Error al escuchar cambios en marcas: \(error.localizedDescription)")
                }
            }
        }
    }
}

extension BrandViewModel {
    var brandKeys: [String] {
        brands.map { $0.key }
    }
}
