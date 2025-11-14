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

    internal let perfumeService: PerfumeServiceProtocol // Exposed for views that need to load specific perfumes
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
            #if DEBUG
            print("✅ [PerfumeViewModel] Metadata index loaded: \(metadata.count) perfumes")
            #endif
            self.metadataIndex = metadata
            isLoading = false
        } catch {
            self.handleError("Error al cargar índice de perfumes: \(error.localizedDescription)")
            #if DEBUG
            print("❌ [PerfumeViewModel] Error loading metadata index: \(error)")
            #endif
            isLoading = false
        }
    }

    // MARK: - Cargar Perfumes Inicialmente (LEGACY - Solo usar si necesitas todos los perfumes completos)
    @MainActor
    func loadInitialData() async {
        isLoading = true
        do {
            let perfumesStored = try await perfumeService.fetchAllPerfumesOnce()
            #if DEBUG
            print("Perfumes cargados: \(perfumesStored.count) perfumes")
            #endif
            self.perfumes = perfumesStored
            rebuildIndex() // ✅ Reconstruir índice después de cargar
            isLoading = false
        } catch {
            self.handleError("Error al cargar perfumes: \(error.localizedDescription)")
            #if DEBUG
            print("Error fetching perfumes: \(error)")
            #endif
        }
    }

    // MARK: - Pagination Methods
    /// Loads initial page of perfumes (50 items) with pagination support
    @MainActor
    func loadInitialPerfumes() async {
        guard !isLoading else {
            #if DEBUG
            print("PerfumeViewModel: Already loading initial perfumes, skipping...")
            #endif
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

            #if DEBUG
            print("PerfumeViewModel: Loaded initial \(result.perfumes.count) perfumes, hasMore: \(hasMorePerfumes)")
            #endif
            isLoading = false
        } catch {
            self.handleError("Error al cargar perfumes: \(error.localizedDescription)")
            #if DEBUG
            print("Error fetching initial perfumes: \(error)")
            #endif
            isLoading = false
        }
    }

    /// Loads next page of perfumes (50 items) using pagination cursor
    @MainActor
    func loadMorePerfumes() async {
        guard !isLoadingMore, !isLoading, hasMorePerfumes else {
            #if DEBUG
            if !hasMorePerfumes {
                print("PerfumeViewModel: No more perfumes to load")
            } else {
                print("PerfumeViewModel: Already loading more perfumes, skipping...")
            }
            #endif
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

            #if DEBUG
            print("PerfumeViewModel: Loaded \(result.perfumes.count) more perfumes, total: \(perfumes.count), hasMore: \(hasMorePerfumes)")
            #endif
            isLoadingMore = false
        } catch {
            self.handleError("Error al cargar más perfumes: \(error.localizedDescription)")
            #if DEBUG
            print("Error fetching more perfumes: \(error)")
            #endif
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
            #if DEBUG
            print("⚠️ [PerfumeViewModel] metadataIndex vacío, cargando...")
            #endif
            await loadMetadataIndex()
        }

        // Si aún está vacío después de cargar, usar perfumes completos como fallback
        if metadataIndex.isEmpty && !perfumes.isEmpty {
            #if DEBUG
            print("⚠️ [PerfumeViewModel] Usando perfumes completos como fallback")
            #endif
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
        #if DEBUG
        print("✅ [PerfumeViewModel] Calculando recomendaciones desde metadata (\(metadataIndex.count) perfumes)")
        #endif

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

        #if DEBUG
        print("✅ [PerfumeViewModel] \(recommendedPerfumes.count) recomendaciones calculadas")
        #endif

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
                        #if DEBUG
                        print("   ⚠️ Error descargando perfume \(recommended.perfumeId): \(error.localizedDescription)")
                        #endif
                        return (index, nil, 0.0)
                    }
                }
            }

            // ⚡ CRÍTICO: Agregar perfumes INMEDIATAMENTE cuando lleguen
            // No esperar a que todos completen
            var count = 0
            for await (_, perfume, score) in group { // ✅ Fixed: Replaced unused 'index' with '_'
                guard let perfume = perfume else { continue }
                fullPerfumes.append((perfume: perfume, score: score))
                count += 1
                #if DEBUG
                print("   ✅ Descargado (\(count)/\(recommendedPerfumes.count)): \(perfume.name)")
                #endif
            }
        }

        // Ordenar por índice original para mantener el orden de scoring
        fullPerfumes.sort { $0.score > $1.score }

        #if DEBUG
        print("✅ [PerfumeViewModel] \(fullPerfumes.count) perfumes completos descargados")
        #endif

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
        // ✅ CRITICAL: Load metadata index first to enable cache fallback
        // Without this, fetchPerfume(byKey:) cannot use Level 2 fallback (ID-based cache lookup)
        if metadataIndex.isEmpty {
            #if DEBUG
            print("🔄 [PerfumeViewModel] Loading metadata index for cache fallback...")
            #endif
            await loadMetadataIndex()
        }

        // ✅ RACE CONDITION FIX: Small delay to let HomeTab recommendations load first
        // Recommendations and pre-loading run in parallel. This prevents duplicate downloads
        // by giving recommendations a head start to cache perfumes first.
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay

        // Filtrar keys que NO están ya en perfumes o en el índice
        let missingKeys = keys.filter { key in
            // Check both array and index (index updates faster from parallel tasks)
            !perfumes.contains(where: { $0.key == key }) && perfumeIndex[key] == nil
        }

        guard !missingKeys.isEmpty else {
            #if DEBUG
            print("✅ [PerfumeViewModel] Todos los perfumes ya están cargados (array: \(perfumes.count), index: \(perfumeIndex.count))")
            #endif
            return
        }

        #if DEBUG
        print("📥 [PerfumeViewModel] Cargando \(missingKeys.count) perfumes faltantes...")
        #endif

        // ✅ Capture metadata keys BEFORE TaskGroup (MainActor requirement)
        let metadataKeys = metadataIndex.map { $0.key }

        // Cargar en paralelo con fuzzy matching
        await withTaskGroup(of: (requestedKey: String, perfume: Perfume?).self) { group in
            for key in missingKeys {
                group.addTask {
                    do {
                        // ✅ FUZZY MATCH: Try to find the real key in metadata index
                        var actualKey = key

                        // 1. Check metadata index with original key
                        if metadataKeys.contains(key) {
                            actualKey = key
                        }
                        // 2. Try without brand prefix (e.g., "lattafa_khamrah" → "khamrah")
                        else if let underscoreIndex = key.firstIndex(of: "_") {
                            let keyWithoutBrand = String(key[key.index(after: underscoreIndex)...])
                            if metadataKeys.contains(keyWithoutBrand) {
                                #if DEBUG
                                print("✅ [PerfumeViewModel] Fuzzy match: '\(key)' → '\(keyWithoutBrand)'")
                                #endif
                                actualKey = keyWithoutBrand
                            }
                        }

                        let perfume = try await self.perfumeService.fetchPerfume(byKey: actualKey)
                        return (requestedKey: key, perfume: perfume)
                    } catch {
                        #if DEBUG
                        print("⚠️ Error cargando perfume \(key): \(error.localizedDescription)")
                        #endif
                        return (requestedKey: key, perfume: nil)
                    }
                }
            }

            // Recolectar resultados
            for await (requestedKey, perfume) in group {
                if let perfume = perfume {
                    perfumes.append(perfume)
                    // ✅ TRIPLE INDEX: Index by id, actual key, AND requested key
                    perfumeIndex[perfume.id] = perfume  // For Wishlist (uses ID)
                    perfumeIndex[perfume.key] = perfume // For TriedPerfumes (uses Firestore key)
                    perfumeIndex[requestedKey] = perfume // ✅ FIX: Also index by requested key for GiftRecommendations

                    #if DEBUG
                    if requestedKey != perfume.key {
                        print("🔗 [PerfumeViewModel] Indexed '\(perfume.name)' by both '\(requestedKey)' AND '\(perfume.key)'")
                    }
                    #endif
                }
            }
        }

        #if DEBUG
        print("✅ [PerfumeViewModel] Perfumes cargados. Total: \(perfumes.count), Index: \(perfumeIndex.count)")
        #endif
    }

    // ✅ NUEVO: Cargar un único perfume por su key (on-demand para búsqueda)
    /// Carga un perfume individual y lo agrega a perfumes si no existe
    /// Útil para cargar imágenes on-demand durante búsqueda
    @MainActor
    func loadPerfumeByKey(_ key: String) async throws -> Perfume? {
        // 1. Verificar si ya está en memoria
        if let existingPerfume = perfumeIndex[key] ?? perfumes.first(where: { $0.key == key }) {
            #if DEBUG
            print("✅ [PerfumeViewModel] Perfume already in memory: \(key)")
            #endif
            return existingPerfume
        }

        // 2. Cargar desde Firestore
        #if DEBUG
        print("📥 [PerfumeViewModel] Fetching perfume: \(key)")
        #endif
        guard let fetchedPerfume = try await perfumeService.fetchPerfume(byKey: key) else {
            #if DEBUG
            print("⚠️ [PerfumeViewModel] Perfume not found: \(key)")
            #endif
            return nil
        }

        // 3. Agregar a perfumes y al índice
        perfumes.append(fetchedPerfume)
        perfumeIndex[fetchedPerfume.key] = fetchedPerfume

        #if DEBUG
        print("✅ [PerfumeViewModel] Perfume loaded and cached: \(fetchedPerfume.name)")
        #endif
        return fetchedPerfume
    }

    // ✅ NUEVO: Cargar un único perfume por su document ID (on-demand)
    /// Carga un perfume individual por su document ID de Firestore
    /// Útil cuando el key field no coincide con el unified key
    @MainActor
    func loadPerfumeById(_ id: String) async throws -> Perfume? {
        // 1. Verificar si ya está en memoria (por ID)
        if let existingPerfume = perfumeIndex[id] {
            #if DEBUG
            print("✅ [PerfumeViewModel] Perfume already in memory by ID: \(id)")
            #endif
            return existingPerfume
        }

        // 2. Verificar en array de perfumes por ID
        if let existingPerfume = perfumes.first(where: { $0.id == id }) {
            #if DEBUG
            print("✅ [PerfumeViewModel] Perfume found in array by ID: \(id)")
            #endif
            // Agregar al índice para futuras búsquedas
            perfumeIndex[id] = existingPerfume
            return existingPerfume
        }

        // 3. Cargar desde Firestore por document ID
        #if DEBUG
        print("📥 [PerfumeViewModel] Fetching perfume by ID: \(id)")
        #endif
        let fetchedPerfume = try await perfumeService.fetchPerfume(id: id)

        // 4. Agregar a perfumes y al índice (por ID y por key)
        perfumes.append(fetchedPerfume)
        perfumeIndex[fetchedPerfume.id] = fetchedPerfume
        perfumeIndex[fetchedPerfume.key] = fetchedPerfume

        #if DEBUG
        print("✅ [PerfumeViewModel] Perfume loaded by ID and cached: \(fetchedPerfume.name)")
        print("   - ID: \(fetchedPerfume.id)")
        print("   - Key: \(fetchedPerfume.key)")
        #endif
        return fetchedPerfume
    }

    // MARK: - Index Management

    /// ✅ CRITICAL: Reconstruye el índice O(1) desde el array de perfumes
    /// Este índice permite búsquedas instantáneas sin bloquear el main thread
    /// Maneja duplicados de forma segura usando el primer perfume encontrado
    /// ✅ DUAL INDEX: Indexa por BOTH id AND key para soportar búsquedas por ambos
    private func rebuildIndex() {
        var duplicateCount = 0
        perfumeIndex = perfumes.reduce(into: [String: Perfume]()) { dict, perfume in
            // ✅ Index by ID (if not empty) - For Wishlist lookups
            if !perfume.id.isEmpty {
                if dict[perfume.id] == nil {
                    dict[perfume.id] = perfume
                } else {
                    duplicateCount += 1
                    #if DEBUG
                    print("⚠️ [PerfumeViewModel] Duplicate ID found: '\(perfume.id)' - usando el primero")
                    #endif
                }
            }

            // ✅ Index by key - For TriedPerfumes lookups
            if dict[perfume.key] == nil {
                dict[perfume.key] = perfume
            } else {
                duplicateCount += 1
                #if DEBUG
                print("⚠️ [PerfumeViewModel] Duplicate key found: '\(perfume.key)' (id: \(perfume.id)) - usando el primero")
                #endif
            }
        }

        #if DEBUG
        if duplicateCount > 0 {
            print("⚠️ [PerfumeViewModel] Total duplicates found: \(duplicateCount)")
        }
        print("🔍 [PerfumeViewModel] Índice reconstruido: \(perfumeIndex.count) perfumes únicos de \(perfumes.count) totales")
        #endif
    }

    /// ✅ NUEVO: Garantiza que perfumeIndex esté inicializado
    /// Si perfumes está vacío pero hay metadata, construye el índice desde metadata
    /// Esto previene que FragranceLibraryTabView quede sin índice
    @MainActor
    func ensureIndexInitialized() async {
        // Si ya hay perfumes cargados, el índice ya debe estar construido
        if !perfumes.isEmpty {
            #if DEBUG
            print("✅ [PerfumeViewModel] Index already initialized with \(perfumeIndex.count) perfumes")
            #endif
            return
        }

        // Si no hay perfumes pero sí hay metadata, construir índice desde metadata
        guard !metadataIndex.isEmpty else {
            #if DEBUG
            print("⚠️ [PerfumeViewModel] No metadata available to build index")
            #endif
            return
        }

        #if DEBUG
        print("🔄 [PerfumeViewModel] Building perfumeIndex from \(metadataIndex.count) metadata objects...")
        #endif

        // Convertir metadata a Perfume y poblar el índice
        for metadata in metadataIndex {
            let perfume = convertMetadataToPerfume(metadata)

            // DUAL INDEX: Index by BOTH id AND key para soportar búsquedas por ambos
            if let id = perfume.id.isEmpty ? nil : perfume.id {
                perfumeIndex[id] = perfume
            }
            perfumeIndex[perfume.key] = perfume
        }

        #if DEBUG
        print("✅ [PerfumeViewModel] Index built from metadata: \(perfumeIndex.count) perfumes indexed")
        #endif
    }

    /// Convierte PerfumeMetadata a Perfume con valores por defecto para campos faltantes
    /// Esto permite usar el índice sin necesitar descargar datos completos de Firestore
    private func convertMetadataToPerfume(_ metadata: PerfumeMetadata) -> Perfume {
        // ✅ UNIFIED CRITERION: Construir key en formato "marca_nombre"
        let normalizedBrand = metadata.brand
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .folding(options: .diacriticInsensitive, locale: .current)
        let normalizedName = metadata.name
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .folding(options: .diacriticInsensitive, locale: .current)
        let unifiedKey = "\(normalizedBrand)_\(normalizedName)"

        return Perfume(
            id: metadata.id,
            name: metadata.name,
            brand: metadata.brand,
            brandName: nil, // Se puede obtener del BrandViewModel si es necesario
            key: unifiedKey,  // ✅ UNIFIED CRITERION: "marca_nombre"
            family: metadata.family,
            subfamilies: metadata.subfamilies ?? [],
            topNotes: [],
            heartNotes: [],
            baseNotes: [],
            projection: "media", // Default
            intensity: "media",  // Default
            duration: "media",   // Default
            recommendedSeason: [],
            associatedPersonalities: [],
            occasion: [],
            popularity: metadata.popularity,
            year: metadata.year,
            perfumist: nil,
            imageURL: metadata.imageURL ?? "", // ✅ FIX: Usar imageURL del metadata
            description: "",
            gender: metadata.gender,
            price: metadata.price,
            searchTerms: nil,
            createdAt: nil,
            updatedAt: metadata.updatedAt
        )
    }

    /// ✅ Búsqueda O(1) instantánea usando el índice
    /// NO bloquea el main thread, ideal para usar en ForEach
    /// IMPORTANTE: Busca por perfume.id (no por perfume.key)
    func getPerfumeFromIndex(byId id: String) -> Perfume? {
        return perfumeIndex[id]
    }
}
