import Foundation
import Combine
import SwiftUI

@MainActor
public final class PerfumeViewModel: ObservableObject {
    @Published var perfumes: [Perfume] = [] // Lista de perfumes
    @Published var isLoading: Bool = false // Estado de carga
    @Published var errorMessage: IdentifiableString? // Mensaje de error
    @Published var currentPage = 0
    let pageSize = 20
    var hasMoreData = true
    
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
    }

    // MARK: - Manejo de Errores
    private func handleError(_ message: String) {
        errorMessage = IdentifiableString(value: message)
    }

    // En PerfumeViewModel.swift
    func getRelatedPerfumes(for profile: OlfactiveProfile, from families: [Family], loadMore: Bool = false) async throws -> [(perfume: Perfume, score: Double)] {
        if loadMore {
            currentPage += 1
        } else {
            currentPage = 0
            hasMoreData = true
        }
        
        isLoading = true
        
        let recommendedPerfumes = try await OlfactiveProfileHelper.suggestPerfumes(
            perfil: profile,
            baseDeDatos: perfumes,
            allFamilies: families,
            page: currentPage,
            limit: pageSize
        )
        
        isLoading = false
        
        // Verificar si hay más datos
        if recommendedPerfumes.count < pageSize {
            hasMoreData = false
        }
        
        return recommendedPerfumes.compactMap { recommendedPerfume in
            guard let perfume = perfumes.first(where: { $0.id == recommendedPerfume.perfumeId }) else { return nil }
            return (perfume: perfume, score: recommendedPerfume.matchPercentage)
        }
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
