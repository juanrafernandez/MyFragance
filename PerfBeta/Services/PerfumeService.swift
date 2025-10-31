import FirebaseFirestore
import UIKit

protocol PerfumeServiceProtocol {
    func fetchAllPerfumesOnce() async throws -> [Perfume]
    func fetchPerfume(byKey key: String) async throws -> Perfume?
    func fetchPerfume(id: String) async throws -> Perfume
    func fetchPerfumesPaginated(limit: Int, lastDocument: DocumentSnapshot?) async throws -> (perfumes: [Perfume], lastDocument: DocumentSnapshot?)
    func fetchPerfumesWithFilters(gender: String?, family: String?, price: String?, subfamilies: [String]?, limit: Int) async throws -> [Perfume]
    func fetchRecommendations(for profile: OlfactiveProfile, limit: Int) async throws -> [Perfume]
    func searchPerfumes(query: String, limit: Int) async throws -> [Perfume]
}

class PerfumeService: PerfumeServiceProtocol {
    // Propiedades
    private let db: Firestore
    private let brandService: BrandServiceProtocol
    private let language: String

    // MARK: - Cache Properties
    private var cachedAllPerfumes: [Perfume]?
    private var cacheTimestamp: Date?
    private let cacheTimeout: TimeInterval = 3600 // 1 hora (aumentado de 5 minutos para reducir fetches)

    // Performance optimization: O(1) lookup by perfume key instead of O(n) linear search
    // This index eliminates the need to iterate through all brands to find a perfume
    private var perfumeKeyIndex: [String: Perfume] = [:]

    // ✅ OPTIMIZATION: Prevent duplicate simultaneous fetches
    // When multiple callers request all perfumes at the same time, reuse the same Task
    private var inflightFetchTask: Task<[Perfume], Error>?

    init(
        firestore: Firestore = Firestore.firestore(),
        brandService: BrandServiceProtocol = DependencyContainer.shared.brandService,
        language: String = AppState.shared.language
    ) {
        self.db = firestore
        self.brandService = brandService
        self.language = language
    }

    // MARK: - Cache Management
    private func buildPerfumeIndex(from perfumes: [Perfume]) {
        // Index by perfume.key for O(1) lookup
        // Note: perfume.key is NOT unique (e.g., "eau_fraiche" exists for multiple brands)
        // We use reduce to handle this - keep the first occurrence for each key
        perfumeKeyIndex = perfumes.reduce(into: [String: Perfume]()) { dict, perfume in
            // Only store if key doesn't exist yet (keeps first occurrence)
            if dict[perfume.key] == nil {
                dict[perfume.key] = perfume
            }
            // No warning needed - multiple brands having same perfume name is expected
        }
        print("PerfumeService: Built index with \(perfumeKeyIndex.count) unique keys from \(perfumes.count) perfumes")
    }

    private func invalidateCache() {
        cachedAllPerfumes = nil
        cacheTimestamp = nil
        perfumeKeyIndex.removeAll()
        print("PerfumeService: Cache invalidated")
    }

    // MARK: - Obtener todos los perfumes una vez
    // ✅ CACHE IMPLEMENTATION: 5-minute cache + builds O(1) index for fast lookups
    // ✅ NEW: Uses flat structure perfumes/{brand}_{key}
    func fetchAllPerfumesOnce() async throws -> [Perfume] {
        let startTime = Date()

        // Check cache first
        if let cached = cachedAllPerfumes,
           let timestamp = cacheTimestamp,
           Date().timeIntervalSince(timestamp) < cacheTimeout {
            PerformanceLogger.logCacheHit("allPerfumes")
            let duration = Date().timeIntervalSince(startTime)
            PerformanceLogger.logNetworkEnd("fetchAllPerfumesOnce [CACHED]", duration: duration)
            print("PerfumeService: Returning cached perfumes (\(cached.count) items)")
            return cached
        }

        // ✅ OPTIMIZATION: Check if there's already a fetch in progress
        if let existingTask = inflightFetchTask {
            print("PerfumeService: Fetch already in progress, waiting for result...")
            let result = try await existingTask.value
            print("PerfumeService: Returning result from in-flight fetch (\(result.count) items)")
            return result
        }

        PerformanceLogger.trackFetch("fetchAllPerfumesOnce")
        PerformanceLogger.logCacheMiss("allPerfumes")
        PerformanceLogger.logNetworkStart("fetchAllPerfumesOnce")

        defer {
            let duration = Date().timeIntervalSince(startTime)
            PerformanceLogger.logNetworkEnd("fetchAllPerfumesOnce", duration: duration)
            inflightFetchTask = nil
        }

        // Create a new Task for fetching
        let fetchTask = Task<[Perfume], Error> { [weak self] in
            guard let self = self else { throw NSError(domain: "PerfumeService", code: -1) }

            // ✅ NEW: Fetch from flat structure perfumes collection
            let collectionPath = "perfumes"
            let queryStart = Date()
            PerformanceLogger.logFirestoreQuery(collectionPath, filters: "all")

            let snapshot = try await self.db.collection(collectionPath)
                .order(by: "popularity", descending: true)
                .getDocuments()

            let queryDuration = Date().timeIntervalSince(queryStart)
            PerformanceLogger.logFirestoreResult(collectionPath, count: snapshot.documents.count, duration: queryDuration)

            print("🔍 [PerfumeService] Processing \(snapshot.documents.count) documents from Firestore")

            let allPerfumes = snapshot.documents.compactMap { document -> Perfume? in
                do {
                    var perfume = try document.data(as: Perfume.self)
                    perfume.id = document.documentID
                    return perfume
                } catch {
                    print("❌ Error decoding perfume \(document.documentID): \(error)")
                    print("   Document data: \(document.data())")
                    return nil
                }
            }

            print("✅ [PerfumeService] Successfully decoded \(allPerfumes.count) perfumes out of \(snapshot.documents.count) documents")

            // Store in cache and build index
            self.cachedAllPerfumes = allPerfumes
            self.cacheTimestamp = Date()
            self.buildPerfumeIndex(from: allPerfumes)
            print("PerfumeService: Cached \(allPerfumes.count) perfumes and built index")

            return allPerfumes
        }

        inflightFetchTask = fetchTask
        return try await fetchTask.value
    }
    
    // ✅ CACHE IMPLEMENTATION: O(1) index lookup
    // ✅ NEW: Direct fetch from flat structure perfumes/{brand}_{key}
    func fetchPerfume(byKey key: String) async throws -> Perfume? {
        let startTime = Date()
        PerformanceLogger.trackFetch("fetchPerfume-\(key)")

        // Try index lookup first (O(1) - instant!)
        if let perfume = perfumeKeyIndex[key] {
            PerformanceLogger.logCacheHit("perfume-\(key)")
            let duration = Date().timeIntervalSince(startTime)
            PerformanceLogger.logNetworkEnd("fetchPerfume(byKey: \(key)) [INDEX]", duration: duration)
            print("PerfumeService: Found perfume '\(key)' in index (O(1) lookup)")
            return perfume
        }

        // ✅ CACHE-FIRST: Try disk cache before Firestore
        let cacheKey = "perfume_\(key)"
        if let cached = await CacheManager.shared.load(Perfume.self, for: cacheKey) {
            PerformanceLogger.logCacheHit("perfume-\(key)")
            let duration = Date().timeIntervalSince(startTime)
            PerformanceLogger.logNetworkEnd("fetchPerfume(byKey: \(key)) [DISK CACHE]", duration: duration)
            print("✅ [PerfumeService] '\(key)' from cache")

            // Add to index for future lookups
            perfumeKeyIndex[key] = cached
            return cached
        }

        // ✅ Cache miss - fetch directly from Firestore (1 perfume only)
        print("❌ [PerfumeService] Cache MISS '\(key)' - fetching from Firestore")
        PerformanceLogger.logCacheMiss("perfume-\(key)")
        PerformanceLogger.logNetworkStart("fetchPerfume(byKey: \(key)) [DIRECT]")

        defer {
            let duration = Date().timeIntervalSince(startTime)
            PerformanceLogger.logNetworkEnd("fetchPerfume(byKey: \(key))", duration: duration)
        }

        // Try direct document fetch (perfume ID is brand_key format)
        let snapshot = try await db.collection("perfumes")
            .whereField("key", isEqualTo: key)
            .limit(to: 1)
            .getDocuments()

        guard let document = snapshot.documents.first else {
            print("PerfumeService: Perfume '\(key)' not found in Firestore")
            return nil
        }

        var perfume = try document.data(as: Perfume.self)
        perfume.id = document.documentID

        // ✅ Cache the perfume for future use
        do {
            try await CacheManager.shared.save(perfume, for: cacheKey)
            print("💾 [PerfumeService] Perfume '\(key)' cached permanently")
        } catch {
            print("⚠️ [PerfumeService] Failed to cache '\(key)': \(error.localizedDescription)")
        }

        // Add to index for future lookups
        perfumeKeyIndex[key] = perfume

        return perfume
    }

    // MARK: - Paginated Fetch
    /// ✅ NEW: Fetches perfumes with pagination from flat structure
    /// - Parameters:
    ///   - limit: Number of perfumes to fetch per page (e.g., 50)
    ///   - lastDocument: DocumentSnapshot from previous fetch to continue pagination, nil for first page
    /// - Returns: Tuple with array of perfumes and lastDocument for next page (nil if no more data)
    func fetchPerfumesPaginated(limit: Int, lastDocument: DocumentSnapshot?) async throws -> (perfumes: [Perfume], lastDocument: DocumentSnapshot?) {
        let startTime = Date()
        PerformanceLogger.trackFetch("fetchPerfumesPaginated")
        PerformanceLogger.logNetworkStart("fetchPerfumesPaginated(limit: \(limit))")

        defer {
            let duration = Date().timeIntervalSince(startTime)
            PerformanceLogger.logNetworkEnd("fetchPerfumesPaginated", duration: duration)
        }

        // ✅ NEW: Single query on flat perfumes collection
        let collectionPath = "perfumes"
        PerformanceLogger.logFirestoreQuery(collectionPath, filters: "paginated(limit: \(limit))")

        var query: Query = db.collection(collectionPath)
            .order(by: "popularity", descending: true)
            .limit(to: limit)

        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }

        let queryStart = Date()
        let snapshot = try await query.getDocuments()

        let queryDuration = Date().timeIntervalSince(queryStart)
        PerformanceLogger.logFirestoreResult(collectionPath, count: snapshot.documents.count, duration: queryDuration)

        let perfumes = snapshot.documents.compactMap { document -> Perfume? in
            do {
                var perfume = try document.data(as: Perfume.self)
                perfume.id = document.documentID
                return perfume
            } catch {
                print("⚠️ Error decoding perfume \(document.documentID): \(error.localizedDescription)")
                return nil
            }
        }

        print("PerfumeService: Fetched \(perfumes.count) perfumes (paginated)")

        let finalLastDoc = perfumes.count < limit ? nil : snapshot.documents.last

        return (perfumes, finalLastDoc)
    }

    // MARK: - Fetch with Filters (using metadata index)

    /// Obtiene perfumes con filtros usando el índice de metadata
    func fetchPerfumesWithFilters(
        gender: String? = nil,
        family: String? = nil,
        price: String? = nil,
        subfamilies: [String]? = nil,
        limit: Int = 50
    ) async throws -> [Perfume] {
        print("🔍 [PerfumeService] Filtering perfumes...")

        // 1. Obtener índice de metadata (desde caché o Firestore)
        let metadata = try await MetadataIndexManager.shared.getMetadataIndex()

        // 2. Filtrar en memoria
        var filtered = metadata

        if let gender = gender {
            filtered = filtered.filter { $0.gender == gender }
            print("   - Gender: \(gender) → \(filtered.count) perfumes")
        }

        if let family = family {
            filtered = filtered.filter { $0.family == family }
            print("   - Family: \(family) → \(filtered.count) perfumes")
        }

        if let price = price {
            filtered = filtered.filter { $0.price == price }
            print("   - Price: \(price) → \(filtered.count) perfumes")
        }

        if let subfamilies = subfamilies, !subfamilies.isEmpty {
            filtered = filtered.filter { meta in
                guard let metaSubfamilies = meta.subfamilies else { return false }
                return !Set(subfamilies).isDisjoint(with: metaSubfamilies)
            }
            print("   - Subfamilies: \(subfamilies) → \(filtered.count) perfumes")
        }

        // 3. Ordenar por popularidad y limitar
        let sortedAndLimited = filtered
            .sorted { ($0.popularity ?? 0) > ($1.popularity ?? 0) }
            .prefix(limit)

        print("✅ [PerfumeService] Filtered: \(sortedAndLimited.count) perfumes")

        // 4. Cargar perfumes completos (desde caché individual o Firestore)
        var perfumes: [Perfume] = []

        for meta in sortedAndLimited {
            guard let id = meta.id else { continue }

            do {
                let perfume = try await fetchPerfume(id: id)
                perfumes.append(perfume)
            } catch {
                print("⚠️ Error loading perfume \(id): \(error.localizedDescription)")
            }
        }

        return perfumes
    }

    // MARK: - Search
    /// ✅ NEW: Searches perfumes using searchTerms array
    func searchPerfumes(query: String, limit: Int = 50) async throws -> [Perfume] {
        let startTime = Date()
        PerformanceLogger.trackFetch("searchPerfumes")

        let searchQuery = query.lowercased()
        print("🔍 Searching for: \(searchQuery)")

        let snapshot = try await db.collection("perfumes")
            .whereField("searchTerms", arrayContains: searchQuery)
            .order(by: "popularity", descending: true)
            .limit(to: limit)
            .getDocuments()

        let perfumes = snapshot.documents.compactMap { document -> Perfume? in
            do {
                var perfume = try document.data(as: Perfume.self)
                perfume.id = document.documentID
                return perfume
            } catch {
                print("⚠️ Error decoding perfume \(document.documentID): \(error.localizedDescription)")
                return nil
            }
        }

        print("PerfumeService: Found \(perfumes.count) perfumes for query '\(query)'")

        return perfumes
    }

    // MARK: - Fetch Single Perfume (with individual cache)

    /// Obtiene un perfume individual con caché permanente
    func fetchPerfume(id: String) async throws -> Perfume {
        let cacheKey = "perfume_\(id)"

        // 1. Intentar cargar de caché
        if let cached = await CacheManager.shared.load(Perfume.self, for: cacheKey) {
            print("✅ [PerfumeService] '\(id)' from cache")
            return cached
        }

        // 2. Descargar de Firestore
        print("📥 [PerfumeService] Downloading '\(id)'...")
        let document = try await db.collection("perfumes").document(id).getDocument()

        guard document.exists else {
            throw NSError(domain: "PerfumeService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Perfume not found"])
        }

        var perfume = try document.data(as: Perfume.self)
        perfume.id = document.documentID

        // 3. Guardar en caché individual
        try await CacheManager.shared.save(perfume, for: cacheKey)

        return perfume
    }

    // MARK: - Recommendations (using metadata index)

    /// Obtiene recomendaciones para un perfil olfativo
    func fetchRecommendations(for profile: OlfactiveProfile, limit: Int = 20) async throws -> [Perfume] {
        print("🎯 [PerfumeService] Generating recommendations for profile '\(profile.name)'...")

        // 1. Obtener índice de metadata
        let metadata = try await MetadataIndexManager.shared.getMetadataIndex()

        // 2. Filtrar por género del perfil
        var candidates = metadata.filter { $0.gender == profile.gender || $0.gender == "Unisex" }

        print("   - Gender filter: \(candidates.count) candidates")

        // 3. Calcular scores para cada perfume
        let scoredPerfumes = candidates.map { meta -> (meta: PerfumeMetadata, score: Double) in
            let score = calculateScore(for: meta, with: profile)
            return (meta, score)
        }

        // 4. Ordenar por score y tomar los top N
        let topRecommendations = scoredPerfumes
            .sorted { $0.score > $1.score }
            .prefix(limit)

        print("✅ [PerfumeService] Top \(topRecommendations.count) recommendations calculated")

        // 5. Cargar perfumes completos
        var perfumes: [Perfume] = []

        for (meta, score) in topRecommendations {
            guard let id = meta.id else { continue }

            do {
                let perfume = try await fetchPerfume(id: id)
                perfumes.append(perfume)
                print("   - \(meta.name) (score: \(String(format: "%.2f", score)))")
            } catch {
                print("⚠️ Error loading perfume \(id): \(error.localizedDescription)")
            }
        }

        return perfumes
    }

    // MARK: - Private Helpers

    /// Calcula el score de compatibilidad entre metadata y perfil
    private func calculateScore(for meta: PerfumeMetadata, with profile: OlfactiveProfile) -> Double {
        var score: Double = 0.0

        // 1. Score por familia (peso: 80%)
        if let familyMatch = profile.families.first(where: { $0.family == meta.family }) {
            score += Double(familyMatch.puntuation) * 0.8
        }

        // 2. Score por subfamilias (peso: 10%)
        // Si el perfume tiene subfamilias que coinciden con las familias del perfil, dar puntos extras
        if let metaSubfamilies = meta.subfamilies {
            let profileFamilyNames = profile.families.map { $0.family }
            let matchingSubfamilies = Set(metaSubfamilies).intersection(profileFamilyNames)

            if !matchingSubfamilies.isEmpty {
                score += Double(matchingSubfamilies.count) * 5.0 * 0.1
            }
        }

        // 3. Score por popularidad (peso: 10%)
        if let popularity = meta.popularity {
            score += (popularity / 100.0) * 10.0 * 0.1
        }

        return score
    }
}
