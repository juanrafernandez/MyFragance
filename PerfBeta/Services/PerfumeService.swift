import FirebaseFirestore
import UIKit

/// Thread-safe actor for perfume key index to prevent data races
private actor PerfumeIndexActor {
    private var keyIndex: [String: Perfume] = [:]

    func get(_ key: String) -> Perfume? {
        return keyIndex[key]
    }

    func set(_ perfume: Perfume, forKey key: String) {
        keyIndex[key] = perfume
    }

    func buildIndex(from perfumes: [Perfume]) {
        keyIndex = perfumes.reduce(into: [String: Perfume]()) { dict, perfume in
            if dict[perfume.key] == nil {
                dict[perfume.key] = perfume
            }
        }
        #if DEBUG
        print("✅ [PerfumeIndexActor] Built index with \(keyIndex.count) unique keys from \(perfumes.count) perfumes")
        #endif
    }

    func clear() {
        keyIndex.removeAll()
        #if DEBUG
        print("🗑️ [PerfumeIndexActor] Index cleared")
        #endif
    }
}

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
    private let languageProvider: LanguageProvider

    // MARK: - Cache Properties
    private var cachedAllPerfumes: [Perfume]?
    private var cacheTimestamp: Date?
    private let cacheTimeout: TimeInterval = AppConstants.Cache.perfumeCacheTimeout

    // ✅ THREAD-SAFE: Actor-protected index for O(1) perfume lookups
    // This prevents data races that caused NSIndexPath corruption crashes
    private let perfumeIndex = PerfumeIndexActor()

    // ✅ OPTIMIZATION: Prevent duplicate simultaneous fetches
    // When multiple callers request all perfumes at the same time, reuse the same Task
    private var inflightFetchTask: Task<[Perfume], Error>?

    init(
        firestore: Firestore = Firestore.firestore(),
        brandService: BrandServiceProtocol = DependencyContainer.shared.brandService,
        languageProvider: LanguageProvider = AppState.shared
    ) {
        self.db = firestore
        self.brandService = brandService
        self.languageProvider = languageProvider
    }

    /// Computed property to access current language
    private var language: String {
        languageProvider.language
    }

    // MARK: - Cache Management
    private func buildPerfumeIndex(from perfumes: [Perfume]) async {
        await perfumeIndex.buildIndex(from: perfumes)
    }

    private func invalidateCache() async {
        cachedAllPerfumes = nil
        cacheTimestamp = nil
        await perfumeIndex.clear()
        #if DEBUG
        print("PerfumeService: Cache invalidated")
        #endif
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
            #if DEBUG
            print("PerfumeService: Returning cached perfumes (\(cached.count) items)")
            #endif
            return cached
        }

        // ✅ OPTIMIZATION: Check if there's already a fetch in progress
        if let existingTask = inflightFetchTask {
            #if DEBUG
            print("PerfumeService: Fetch already in progress, waiting for result...")
            #endif
            let result = try await existingTask.value
            #if DEBUG
            print("PerfumeService: Returning result from in-flight fetch (\(result.count) items)")
            #endif
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

            #if DEBUG
            print("🔍 [PerfumeService] Processing \(snapshot.documents.count) documents from Firestore")
            #endif

            let allPerfumes = snapshot.documents.compactMap { document -> Perfume? in
                do {
                    var perfume = try document.data(as: Perfume.self)
                    perfume.id = document.documentID

                    // ✅ UNIFIED CRITERION: Reconstruct key as "marca_nombre"
                    let normalizedBrand = perfume.brand
                        .lowercased()
                        .replacingOccurrences(of: " ", with: "_")
                        .folding(options: .diacriticInsensitive, locale: .current)
                    let normalizedName = perfume.name
                        .lowercased()
                        .replacingOccurrences(of: " ", with: "_")
                        .folding(options: .diacriticInsensitive, locale: .current)
                    let unifiedKey = "\(normalizedBrand)_\(normalizedName)"

                    #if DEBUG
                    if perfume.key != unifiedKey {
                        print("🔧 [PerfumeService] Key correction for '\(perfume.name)':")
                        print("   - Firestore key: '\(perfume.key)'")
                        print("   - Unified key: '\(unifiedKey)'")
                    }
                    #endif

                    perfume.key = unifiedKey  // ✅ Override with unified format

                    return perfume
                } catch {
                    #if DEBUG
                    print("❌ Error decoding perfume \(document.documentID): \(error)")
                    print("   Document data: \(document.data())")
                    #endif
                    return nil
                }
            }

            #if DEBUG
            print("✅ [PerfumeService] Successfully decoded \(allPerfumes.count) perfumes out of \(snapshot.documents.count) documents")
            #endif

            // Store in cache and build index
            self.cachedAllPerfumes = allPerfumes
            self.cacheTimestamp = Date()
            await self.buildPerfumeIndex(from: allPerfumes)
            #if DEBUG
            print("PerfumeService: Cached \(allPerfumes.count) perfumes and built index")
            #endif

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

        // Try index lookup first (O(1) - instant, thread-safe)
        if let perfume = await perfumeIndex.get(key) {
            PerformanceLogger.logCacheHit("perfume-\(key)")
            let duration = Date().timeIntervalSince(startTime)
            PerformanceLogger.logNetworkEnd("fetchPerfume(byKey: \(key)) [INDEX]", duration: duration)
            #if DEBUG
            print("PerfumeService: Found perfume '\(key)' in index (O(1) lookup)")
            #endif
            return perfume
        }

        // ✅ CACHE-FIRST: Try disk cache before Firestore
        // First try with key (backward compatibility with old cached data)
        let legacyCacheKey = "perfume_\(key)"
        if let cached = await CacheManager.shared.load(Perfume.self, for: legacyCacheKey) {
            PerformanceLogger.logCacheHit("perfume-\(key)")
            let duration = Date().timeIntervalSince(startTime)
            PerformanceLogger.logNetworkEnd("fetchPerfume(byKey: \(key)) [DISK CACHE - LEGACY]", duration: duration)
            #if DEBUG
            print("✅ [PerfumeService] '\(key)' from legacy cache (will migrate)")
            #endif

            // Add to index for future lookups
            await perfumeIndex.set(cached, forKey: key)

            // ✅ MIGRATION: Re-cache with correct ID for future lookups
            let correctCacheKey = "perfume_\(cached.id)"
            Task.detached {
                try? await CacheManager.shared.save(cached, for: correctCacheKey)
                #if DEBUG
                print("🔄 [PerfumeService] Migrated '\(key)' → '\(cached.id)' in cache")
                #endif
            }

            return cached
        }

        // ✅ FALLBACK: Try with document ID format (for perfumes cached with new format)
        // Check metadata index to find the actual document ID for this key
        do {
            let metadataIndex = try await MetadataIndexManager.shared.getMetadataIndex()
            if let metadata = metadataIndex.first(where: { $0.key == key }),
               let metadataId = metadata.id {
                let correctCacheKey = "perfume_\(metadataId)"
                if let cached = await CacheManager.shared.load(Perfume.self, for: correctCacheKey) {
                    PerformanceLogger.logCacheHit("perfume-\(key)")
                    let duration = Date().timeIntervalSince(startTime)
                    PerformanceLogger.logNetworkEnd("fetchPerfume(byKey: \(key)) [DISK CACHE - ID]", duration: duration)
                    #if DEBUG
                    print("✅ [PerfumeService] '\(key)' found via ID: '\(metadataId)'")
                    #endif

                    // Add to index for future lookups
                    await perfumeIndex.set(cached, forKey: key)
                    return cached
                }
            }
        } catch {
            #if DEBUG
            print("⚠️ [PerfumeService] Failed to load metadata index for fallback: \(error.localizedDescription)")
            #endif
        }

        // ✅ Cache miss - fetch directly from Firestore (1 perfume only)
        #if DEBUG
        print("❌ [PerfumeService] Cache MISS '\(key)' - fetching from Firestore")
        #endif
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
            #if DEBUG
            print("PerfumeService: Perfume '\(key)' not found in Firestore")
            #endif
            return nil
        }

        var perfume = try document.data(as: Perfume.self)
        perfume.id = document.documentID

        // ✅ UNIFIED CRITERION: Reconstruct key as "marca_nombre"
        let normalizedBrand = perfume.brand
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .folding(options: .diacriticInsensitive, locale: .current)
        let normalizedName = perfume.name
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .folding(options: .diacriticInsensitive, locale: .current)
        let unifiedKey = "\(normalizedBrand)_\(normalizedName)"

        #if DEBUG
        if perfume.key != unifiedKey {
            print("🔧 [PerfumeService] Key correction for '\(perfume.name)':")
            print("   - Firestore key: '\(perfume.key)'")
            print("   - Unified key: '\(unifiedKey)'")
        }
        #endif

        perfume.key = unifiedKey  // ✅ Override with unified format

        // ✅ Cache with DOCUMENT ID (not key) for consistency
        let correctCacheKey = "perfume_\(perfume.id)"
        do {
            try await CacheManager.shared.save(perfume, for: correctCacheKey)
            #if DEBUG
            print("💾 [PerfumeService] Perfume '\(perfume.id)' cached permanently (key: '\(key)')")
            #endif
        } catch {
            #if DEBUG
            print("⚠️ [PerfumeService] Failed to cache '\(perfume.id)': \(error.localizedDescription)")
            #endif
        }

        // Add to index for future lookups (index by key for fast lookup)
        await perfumeIndex.set(perfume, forKey: key)

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

                // ✅ UNIFIED CRITERION: Reconstruct key as "marca_nombre"
                let normalizedBrand = perfume.brand
                    .lowercased()
                    .replacingOccurrences(of: " ", with: "_")
                    .folding(options: .diacriticInsensitive, locale: .current)
                let normalizedName = perfume.name
                    .lowercased()
                    .replacingOccurrences(of: " ", with: "_")
                    .folding(options: .diacriticInsensitive, locale: .current)
                let unifiedKey = "\(normalizedBrand)_\(normalizedName)"

                #if DEBUG
                if perfume.key != unifiedKey {
                    print("🔧 [PerfumeService] Key correction for '\(perfume.name)':")
                    print("   - Firestore key: '\(perfume.key)'")
                    print("   - Unified key: '\(unifiedKey)'")
                }
                #endif

                perfume.key = unifiedKey  // ✅ Override with unified format

                return perfume
            } catch {
                #if DEBUG
                print("⚠️ Error decoding perfume \(document.documentID): \(error.localizedDescription)")
                #endif
                return nil
            }
        }

        #if DEBUG
        print("PerfumeService: Fetched \(perfumes.count) perfumes (paginated)")
        #endif

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
        #if DEBUG
        print("🔍 [PerfumeService] Filtering perfumes...")
        #endif

        // 1. Obtener índice de metadata (desde caché o Firestore)
        let metadata = try await MetadataIndexManager.shared.getMetadataIndex()

        // 2. Filtrar en memoria
        var filtered = metadata

        if let gender = gender {
            filtered = filtered.filter { $0.gender == gender }
            #if DEBUG
            print("   - Gender: \(gender) → \(filtered.count) perfumes")
            #endif
        }

        if let family = family {
            filtered = filtered.filter { $0.family == family }
            #if DEBUG
            print("   - Family: \(family) → \(filtered.count) perfumes")
            #endif
        }

        if let price = price {
            filtered = filtered.filter { $0.price == price }
            #if DEBUG
            print("   - Price: \(price) → \(filtered.count) perfumes")
            #endif
        }

        if let subfamilies = subfamilies, !subfamilies.isEmpty {
            filtered = filtered.filter { meta in
                guard let metaSubfamilies = meta.subfamilies else { return false }
                return !Set(subfamilies).isDisjoint(with: metaSubfamilies)
            }
            #if DEBUG
            print("   - Subfamilies: \(subfamilies) → \(filtered.count) perfumes")
            #endif
        }

        // 3. Ordenar por popularidad y limitar
        let sortedAndLimited = filtered
            .sorted { ($0.popularity ?? 0) > ($1.popularity ?? 0) }
            .prefix(limit)

        #if DEBUG
        print("✅ [PerfumeService] Filtered: \(sortedAndLimited.count) perfumes")
        #endif

        // 4. Cargar perfumes completos (desde caché individual o Firestore)
        var perfumes: [Perfume] = []

        for meta in sortedAndLimited {
            guard let id = meta.id else { continue }

            do {
                let perfume = try await fetchPerfume(id: id)
                perfumes.append(perfume)
            } catch {
                #if DEBUG
                print("⚠️ Error loading perfume \(id): \(error.localizedDescription)")
                #endif
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
        #if DEBUG
        print("🔍 Searching for: \(searchQuery)")
        #endif

        let snapshot = try await db.collection("perfumes")
            .whereField("searchTerms", arrayContains: searchQuery)
            .order(by: "popularity", descending: true)
            .limit(to: limit)
            .getDocuments()

        let perfumes = snapshot.documents.compactMap { document -> Perfume? in
            do {
                var perfume = try document.data(as: Perfume.self)
                perfume.id = document.documentID

                // ✅ UNIFIED CRITERION: Reconstruct key as "marca_nombre"
                let normalizedBrand = perfume.brand
                    .lowercased()
                    .replacingOccurrences(of: " ", with: "_")
                    .folding(options: .diacriticInsensitive, locale: .current)
                let normalizedName = perfume.name
                    .lowercased()
                    .replacingOccurrences(of: " ", with: "_")
                    .folding(options: .diacriticInsensitive, locale: .current)
                let unifiedKey = "\(normalizedBrand)_\(normalizedName)"

                #if DEBUG
                if perfume.key != unifiedKey {
                    print("🔧 [PerfumeService] Key correction for '\(perfume.name)':")
                    print("   - Firestore key: '\(perfume.key)'")
                    print("   - Unified key: '\(unifiedKey)'")
                }
                #endif

                perfume.key = unifiedKey  // ✅ Override with unified format

                return perfume
            } catch {
                #if DEBUG
                print("⚠️ Error decoding perfume \(document.documentID): \(error.localizedDescription)")
                #endif
                return nil
            }
        }

        #if DEBUG
        print("PerfumeService: Found \(perfumes.count) perfumes for query '\(query)'")
        #endif

        return perfumes
    }

    // MARK: - Fetch Single Perfume (with individual cache)

    /// Obtiene un perfume individual con caché permanente
    func fetchPerfume(id: String) async throws -> Perfume {
        let cacheKey = "perfume_\(id)"

        // 1. Intentar cargar de caché
        if let cached = await CacheManager.shared.load(Perfume.self, for: cacheKey) {
            #if DEBUG
            print("✅ [PerfumeService] '\(id)' from cache")
            #endif
            return cached
        }

        // 2. Descargar de Firestore
        #if DEBUG
        print("📥 [PerfumeService] Downloading '\(id)'...")
        #endif
        let document = try await db.collection("perfumes").document(id).getDocument()

        guard document.exists else {
            throw NSError(domain: "PerfumeService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Perfume not found"])
        }

        var perfume = try document.data(as: Perfume.self)
        perfume.id = document.documentID

        // ✅ UNIFIED CRITERION: Reconstruct key as "marca_nombre"
        let normalizedBrand = perfume.brand
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .folding(options: .diacriticInsensitive, locale: .current)
        let normalizedName = perfume.name
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .folding(options: .diacriticInsensitive, locale: .current)
        let unifiedKey = "\(normalizedBrand)_\(normalizedName)"

        #if DEBUG
        if perfume.key != unifiedKey {
            print("🔧 [PerfumeService] Key correction for '\(perfume.name)':")
            print("   - Firestore key: '\(perfume.key)'")
            print("   - Unified key: '\(unifiedKey)'")
        }
        #endif

        perfume.key = unifiedKey  // ✅ Override with unified format

        // 3. Guardar en caché individual
        try await CacheManager.shared.save(perfume, for: cacheKey)

        return perfume
    }

    // MARK: - Recommendations (using metadata index)

    /// Obtiene recomendaciones para un perfil olfativo
    func fetchRecommendations(for profile: OlfactiveProfile, limit: Int = 20) async throws -> [Perfume] {
        #if DEBUG
        print("🎯 [PerfumeService] Generating recommendations for profile '\(profile.name)'...")
        #endif

        // 1. Obtener índice de metadata
        let metadata = try await MetadataIndexManager.shared.getMetadataIndex()

        // 2. Filtrar por género del perfil
        var candidates = metadata.filter { $0.gender == profile.gender || $0.gender == "Unisex" }

        #if DEBUG
        print("   - Gender filter: \(candidates.count) candidates")
        #endif

        // 3. Calcular scores para cada perfume
        let scoredPerfumes = candidates.map { meta -> (meta: PerfumeMetadata, score: Double) in
            let score = calculateScore(for: meta, with: profile)
            return (meta, score)
        }

        // 4. Ordenar por score y tomar los top N
        let topRecommendations = scoredPerfumes
            .sorted { $0.score > $1.score }
            .prefix(limit)

        #if DEBUG
        print("✅ [PerfumeService] Top \(topRecommendations.count) recommendations calculated")
        #endif

        // 5. Cargar perfumes completos
        var perfumes: [Perfume] = []

        for (meta, score) in topRecommendations {
            guard let id = meta.id else { continue }

            do {
                let perfume = try await fetchPerfume(id: id)
                perfumes.append(perfume)
                #if DEBUG
                print("   - \(meta.name) (score: \(String(format: "%.2f", score)))")
                #endif
            } catch {
                #if DEBUG
                print("⚠️ Error loading perfume \(id): \(error.localizedDescription)")
                #endif
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
