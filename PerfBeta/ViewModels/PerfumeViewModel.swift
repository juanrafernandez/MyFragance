import Foundation
import Combine
import SwiftUI
import FirebaseFirestore

@MainActor
public final class PerfumeViewModel: ObservableObject {
    @Published var perfumes: [Perfume] = [] // Lista de perfumes completos (para backward compatibility)
    @Published var metadataIndex: [PerfumeMetadata] = [] // ✅ NUEVO: Índice de metadata ligero
    @Published var isLoading: Bool = false // Estado de carga
    @Published var errorMessage: IdentifiableString? // Mensaje de error
    @Published var currentPage = 0
    let pageSize = 20
    var hasMoreData = true

    // ✅ CRITICAL FIX: Diccionario O(1) para búsqueda instantánea
    @Published private(set) var perfumeIndex: [String: Perfume] = [:]

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

    // MARK: - Cargar Metadata Index (NUEVO - Recomendado)
    /// ✅ Carga solo el índice de metadata ligero (~200KB vs ~10MB)
    /// Usa caché permanente + sync incremental
    @MainActor
    func loadMetadataIndex() async {
        isLoading = true
        do {
            let metadata = try await MetadataIndexManager.shared.getMetadataIndex()
            print("✅ [PerfumeViewModel] Metadata index loaded: \(metadata.count) perfumes")
            self.metadataIndex = metadata
            isLoading = false
        } catch {
            self.handleError("Error al cargar índice de perfumes: \(error.localizedDescription)")
            print("❌ [PerfumeViewModel] Error loading metadata index: \(error)")
            isLoading = false
        }
    }

    // MARK: - Cargar Perfumes Inicialmente (LEGACY - Solo usar si necesitas todos los perfumes completos)
    @MainActor
    func loadInitialData() async {
        isLoading = true
        do {
            let perfumesStored = try await perfumeService.fetchAllPerfumesOnce()
            print("Perfumes cargados: \(perfumesStored.count) perfumes")
            self.perfumes = perfumesStored
            rebuildIndex() // ✅ Reconstruir índice después de cargar
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
            rebuildIndex() // ✅ Reconstruir índice

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
            rebuildIndex() // ✅ Actualizar índice con nuevos perfumes

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

    // ✅ NUEVO: Obtiene recomendaciones usando metadata + descarga perfumes completos
    func getRelatedPerfumes(for profile: OlfactiveProfile, from families: [Family], loadMore: Bool = false) async throws -> [(perfume: Perfume, score: Double)] {
        if loadMore {
            currentPage += 1
        } else {
            currentPage = 0
            hasMoreData = true
        }

        isLoading = true

        // Si metadataIndex está vacío, cargar primero
        if metadataIndex.isEmpty {
            print("⚠️ [PerfumeViewModel] metadataIndex vacío, cargando...")
            await loadMetadataIndex()
        }

        // Si aún está vacío después de cargar, usar perfumes completos como fallback
        if metadataIndex.isEmpty && !perfumes.isEmpty {
            print("⚠️ [PerfumeViewModel] Usando perfumes completos como fallback")
            let recommendedPerfumes = try await OlfactiveProfileHelper.suggestPerfumes(
                perfil: profile,
                baseDeDatos: perfumes,
                allFamilies: families,
                page: currentPage,
                limit: pageSize
            )

            isLoading = false
            hasMoreData = recommendedPerfumes.count >= pageSize

            return recommendedPerfumes.compactMap { recommendedPerfume in
                guard let perfume = perfumes.first(where: { $0.id == recommendedPerfume.perfumeId }) else { return nil }
                return (perfume: perfume, score: recommendedPerfume.matchPercentage)
            }
        }

        // ✅ NUEVO FLUJO: Usar metadata para recomendaciones
        print("✅ [PerfumeViewModel] Calculando recomendaciones desde metadata (\(metadataIndex.count) perfumes)")

        // 1. Convertir metadata a perfumes "fake" solo para cálculo
        let fakePerfumes: [Perfume] = metadataIndex.map { meta in
            Perfume(
                id: meta.id,
                name: meta.name,
                brand: meta.brand,
                key: meta.key,
                family: meta.family,
                subfamilies: meta.subfamilies ?? [],
                topNotes: [],
                heartNotes: [],
                baseNotes: [],
                projection: "media",
                intensity: "media",
                duration: "media",
                recommendedSeason: [],
                associatedPersonalities: [],
                occasion: [],
                popularity: meta.popularity,
                year: meta.year,
                perfumist: nil,
                imageURL: "",  // ✅ Valor por defecto vacío (se descarga el real después)
                description: "",
                gender: meta.gender,
                price: meta.price,
                createdAt: nil,
                updatedAt: nil
            )
        }

        // 2. Calcular recomendaciones
        let recommendedPerfumes = try await OlfactiveProfileHelper.suggestPerfumes(
            perfil: profile,
            baseDeDatos: fakePerfumes,
            allFamilies: families,
            page: currentPage,
            limit: pageSize
        )

        isLoading = false
        hasMoreData = recommendedPerfumes.count >= pageSize

        print("✅ [PerfumeViewModel] \(recommendedPerfumes.count) recomendaciones calculadas")

        // ⚡ 3. Descargar perfumes COMPLETOS en PARALELO (withTaskGroup)
        // Los que están en caché llegan instantáneamente (< 0.1s)
        // Los que faltan descargan en background sin bloquear
        var fullPerfumes: [(perfume: Perfume, score: Double)] = []

        await withTaskGroup(of: (Int, Perfume?, Double).self) { group in
            for (index, recommended) in recommendedPerfumes.enumerated() {
                group.addTask { [weak self] in
                    do {
                        guard let self = self else { return (index, nil, 0.0) }
                        let perfume = try await self.perfumeService.fetchPerfume(id: recommended.perfumeId)
                        return (index, perfume, recommended.matchPercentage)
                    } catch {
                        print("   ⚠️ Error descargando perfume \(recommended.perfumeId): \(error.localizedDescription)")
                        return (index, nil, 0.0)
                    }
                }
            }

            // ⚡ CRÍTICO: Agregar perfumes INMEDIATAMENTE cuando lleguen
            // No esperar a que todos completen
            var count = 0
            for await (index, perfume, score) in group {
                guard let perfume = perfume else { continue }
                fullPerfumes.append((perfume: perfume, score: score))
                count += 1
                print("   ✅ Descargado (\(count)/\(recommendedPerfumes.count)): \(perfume.name)")
            }
        }

        // Ordenar por índice original para mantener el orden de scoring
        fullPerfumes.sort { $0.score > $1.score }

        print("✅ [PerfumeViewModel] \(fullPerfumes.count) perfumes completos descargados")

        return fullPerfumes
    }

    // MARK: - Obtener Perfume por Clave

    /// ✅ DEPRECATED: Usa getPerfumeFromIndex() para búsqueda O(1) instantánea
    func getPerfume(byKey key: String) -> Perfume? {
        // Usar el índice en lugar de búsqueda lineal
        return perfumeIndex[key]
    }

    /// Versión async para cargar desde servicio si no existe localmente
    func fetchPerfume(byKey key: String) async throws -> Perfume? {
        // Primero buscar en el índice (O(1))
        if let perfume = perfumeIndex[key] {
            return perfume
        }

        // Si no está, cargar desde servicio
        guard let perfume = try await perfumeService.fetchPerfume(byKey: key) else {
            return nil
        }

        // Agregar al array y al índice para futuras búsquedas
        perfumes.append(perfume)
        perfumeIndex[key] = perfume

        return perfume
    }

    // ✅ NUEVO: Cargar múltiples perfumes por sus keys
    /// Carga perfumes que aún no están en la lista local
    /// Útil para Mi Colección - solo descarga lo necesario
    func loadPerfumesByKeys(_ keys: [String]) async {
        // Filtrar keys que NO están ya en perfumes
        let missingKeys = keys.filter { key in
            !perfumes.contains(where: { $0.key == key })
        }

        guard !missingKeys.isEmpty else {
            print("✅ [PerfumeViewModel] Todos los perfumes ya están cargados")
            return
        }

        print("📥 [PerfumeViewModel] Cargando \(missingKeys.count) perfumes faltantes...")

        // Cargar en paralelo
        await withTaskGroup(of: Perfume?.self) { group in
            for key in missingKeys {
                group.addTask {
                    do {
                        return try await self.perfumeService.fetchPerfume(byKey: key)
                    } catch {
                        print("⚠️ Error cargando perfume \(key): \(error.localizedDescription)")
                        return nil
                    }
                }
            }

            // Recolectar resultados
            for await perfume in group {
                if let perfume = perfume {
                    perfumes.append(perfume)
                    perfumeIndex[perfume.key] = perfume // ✅ Agregar al índice inmediatamente
                }
            }
        }

        print("✅ [PerfumeViewModel] Perfumes cargados. Total: \(perfumes.count), Index: \(perfumeIndex.count)")
    }

    // MARK: - Index Management

    /// ✅ CRITICAL: Reconstruye el índice O(1) desde el array de perfumes
    /// Este índice permite búsquedas instantáneas sin bloquear el main thread
    /// Maneja duplicados de forma segura usando el primer perfume encontrado
    private func rebuildIndex() {
        var duplicateCount = 0
        perfumeIndex = perfumes.reduce(into: [String: Perfume]()) { dict, perfume in
            if dict[perfume.key] == nil {
                dict[perfume.key] = perfume
            } else {
                duplicateCount += 1
                print("⚠️ [PerfumeViewModel] Duplicate key found: '\(perfume.key)' (id: \(perfume.id)) - usando el primero")
            }
        }

        if duplicateCount > 0 {
            print("⚠️ [PerfumeViewModel] Total duplicates found: \(duplicateCount)")
        }
        print("🔍 [PerfumeViewModel] Índice reconstruido: \(perfumeIndex.count) perfumes únicos de \(perfumes.count) totales")
    }

    /// ✅ Búsqueda O(1) instantánea usando el índice
    /// NO bloquea el main thread, ideal para usar en ForEach
    func getPerfumeFromIndex(byKey key: String) -> Perfume? {
        return perfumeIndex[key]
    }
}
