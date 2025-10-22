import Foundation
import Combine
import SwiftUI
import FirebaseFirestore

@MainActor
public final class PerfumeViewModel: ObservableObject {
    @Published var perfumes: [Perfume] = [] // Lista de perfumes
    @Published var isLoading: Bool = false // Estado de carga
    @Published var errorMessage: IdentifiableString? // Mensaje de error
    @Published var currentPage = 0
    let pageSize = 20
    var hasMoreData = true

    // MARK: - Pagination Properties
    @Published var isLoadingMore: Bool = false // Estado de carga de más perfumes
    @Published var hasMorePerfumes: Bool = true // Indica si hay más perfumes disponibles
    private var lastDocument: DocumentSnapshot? = nil // Cursor para paginación
    let paginationPageSize = 50 // Tamaño de página para paginación

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

    // MARK: - Pagination Methods
    /// Loads initial page of perfumes (50 items) with pagination support
    @MainActor
    func loadInitialPerfumes() async {
        guard !isLoading else {
            print("PerfumeViewModel: Already loading initial perfumes, skipping...")
            return
        }

        isLoading = true
        lastDocument = nil
        hasMorePerfumes = true
        perfumes = []

        do {
            let result = try await perfumeService.fetchPerfumesPaginated(
                limit: paginationPageSize,
                lastDocument: nil
            )

            self.perfumes = result.perfumes
            self.lastDocument = result.lastDocument
            self.hasMorePerfumes = result.lastDocument != nil

            print("PerfumeViewModel: Loaded initial \(result.perfumes.count) perfumes, hasMore: \(hasMorePerfumes)")
            isLoading = false
        } catch {
            self.handleError("Error al cargar perfumes: \(error.localizedDescription)")
            print("Error fetching initial perfumes: \(error)")
            isLoading = false
        }
    }

    /// Loads next page of perfumes (50 items) using pagination cursor
    @MainActor
    func loadMorePerfumes() async {
        guard !isLoadingMore, !isLoading, hasMorePerfumes else {
            if !hasMorePerfumes {
                print("PerfumeViewModel: No more perfumes to load")
            } else {
                print("PerfumeViewModel: Already loading more perfumes, skipping...")
            }
            return
        }

        isLoadingMore = true

        do {
            let result = try await perfumeService.fetchPerfumesPaginated(
                limit: paginationPageSize,
                lastDocument: lastDocument
            )

            self.perfumes.append(contentsOf: result.perfumes)
            self.lastDocument = result.lastDocument
            self.hasMorePerfumes = result.lastDocument != nil

            print("PerfumeViewModel: Loaded \(result.perfumes.count) more perfumes, total: \(perfumes.count), hasMore: \(hasMorePerfumes)")
            isLoadingMore = false
        } catch {
            self.handleError("Error al cargar más perfumes: \(error.localizedDescription)")
            print("Error fetching more perfumes: \(error)")
            isLoadingMore = false
        }
    }

    /// Helper to determine if we should load more perfumes based on current scroll position
    /// Call this in .onAppear of perfume cards near the end of the list
    func shouldLoadMore(currentPerfume perfume: Perfume) -> Bool {
        // Load more when user reaches the last 10 items
        guard let index = perfumes.firstIndex(where: { $0.id == perfume.id }) else {
            return false
        }

        let threshold = perfumes.count - 10
        return index >= threshold && hasMorePerfumes && !isLoadingMore
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
