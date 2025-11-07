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
            #if DEBUG
            print("Marcas cargadas exitosamente. Total: \(brands.count)")
            #endif
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
    
    // MARK: - Obtener Marca por Clave (Key)
    func getBrand(byKey key: String?) -> Brand? {
        guard let key = key else { return nil }
        return brands.first { $0.key == key }
    }

    // MARK: - Helpers

    /// Obtiene el nombre bonito de una marca desde su key/slug
    /// - Parameter brandKey: El slug de la marca (ej: "lattafa")
    /// - Returns: El nombre bonito (ej: "Lattafa") o el slug si no se encuentra
    func getBrandName(for brandKey: String) -> String {
        if let brand = brands.first(where: { $0.key == brandKey }) {
            return brand.name
        }

        // Fallback: capitalizar primera letra del slug
        return brandKey.prefix(1).uppercased() + brandKey.dropFirst()
    }

    /// Obtiene el objeto Brand completo desde su key/slug
    /// - Parameter brandKey: El slug de la marca
    /// - Returns: El objeto Brand o nil si no se encuentra
    func getBrand(for brandKey: String) -> Brand? {
        return brands.first(where: { $0.key == brandKey })
    }
}

extension BrandViewModel {
    var brandKeys: [String] {
        brands.map { $0.key }
    }
}
