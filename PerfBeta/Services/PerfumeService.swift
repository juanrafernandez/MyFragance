import FirebaseFirestore
import UIKit

protocol PerfumeServiceProtocol {
    func fetchAllPerfumesOnce() async throws -> [Perfume]
    func fetchPerfume(byKey key: String) async throws -> Perfume?
}

class PerfumeService: PerfumeServiceProtocol {
    // Propiedades
    private let db: Firestore
    private let brandService: BrandServiceProtocol
    private let language: String

    // MARK: - Cache Properties
    private var cachedAllPerfumes: [Perfume]?
    private var cacheTimestamp: Date?
    private let cacheTimeout: TimeInterval = 300 // 5 minutos

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
        // Index by perfume.key (not perfume.id!) - this is the searchable key like "41_cologne"
        perfumeKeyIndex = Dictionary(uniqueKeysWithValues: perfumes.map { ($0.key, $0) })
        print("PerfumeService: Built index with \(perfumeKeyIndex.count) perfumes for O(1) lookup by key")
    }

    private func invalidateCache() {
        cachedAllPerfumes = nil
        cacheTimestamp = nil
        perfumeKeyIndex.removeAll()
        print("PerfumeService: Cache invalidated")
    }

    // MARK: - Obtener todos los perfumes una vez
    // ✅ CACHE IMPLEMENTATION: 5-minute cache + builds O(1) index for fast lookups
    // Eliminates the need to refetch 1,635 perfumes from Firestore on every call
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
        // If multiple callers request perfumes simultaneously, reuse the same Task
        if let existingTask = inflightFetchTask {
            print("PerfumeService: Fetch already in progress, waiting for result...")
            let result = try await existingTask.value
            print("PerfumeService: Returning result from in-flight fetch (\(result.count) items)")
            return result
        }

        // ✅ Only track fetch when actually starting a new fetch (not on cache hit or in-flight reuse)
        PerformanceLogger.trackFetch("fetchAllPerfumesOnce")

        // Cache miss - fetch from Firestore
        PerformanceLogger.logCacheMiss("allPerfumes")
        PerformanceLogger.logNetworkStart("fetchAllPerfumesOnce")

        defer {
            let duration = Date().timeIntervalSince(startTime)
            PerformanceLogger.logNetworkEnd("fetchAllPerfumesOnce", duration: duration)
            // Clear in-flight task when done
            inflightFetchTask = nil
        }

        // Create a new Task for fetching
        let fetchTask = Task<[Perfume], Error> { [weak self] in
            guard let self = self else { throw NSError(domain: "PerfumeService", code: -1) }

                // 1. Obtener las brandKeys de marcas con perfumes asociados
            PerformanceLogger.logFirestoreQuery("brands", filters: "withPerfumes")
            let brandKeys = try await self.brandService.fetchBrandKeysWithPerfumes()

            if brandKeys.isEmpty {
                PerformanceLogger.logFirestoreResult("brands", count: 0, duration: Date().timeIntervalSince(startTime))
                return [] // No hay marcas con perfumes asociados
            }

            var allPerfumes: [Perfume] = []

            // 2. Obtener los perfumes para cada brandKey
            for brandKey in brandKeys {
                let collectionPath = "perfumes/\(self.language)/\(brandKey)"
                let queryStart = Date()
                PerformanceLogger.logFirestoreQuery(collectionPath, filters: "all")

                let snapshot = try await self.db.collection(collectionPath).getDocuments()

                let queryDuration = Date().timeIntervalSince(queryStart)
                PerformanceLogger.logFirestoreResult(collectionPath, count: snapshot.documents.count, duration: queryDuration)

                let perfumes = snapshot.documents.compactMap { document -> Perfume? in
                    do {
                        var perfume = try document.data(as: Perfume.self)
                        perfume.id = document.documentID
                        perfume.brand = brandKey
                        return perfume
                    } catch {
                        print("⚠️ Error decoding perfume \(document.documentID) in \(brandKey): \(error.localizedDescription)")
                        return nil
                    }
                }
                allPerfumes.append(contentsOf: perfumes)
            }

            // Store in cache and build index
            self.cachedAllPerfumes = allPerfumes
            self.cacheTimestamp = Date()
            self.buildPerfumeIndex(from: allPerfumes)
            print("PerfumeService: Cached \(allPerfumes.count) perfumes and built index")

            return allPerfumes
        }

        // Store the task so other callers can reuse it
        inflightFetchTask = fetchTask

        // Wait for the task to complete
        return try await fetchTask.value
    }
    
    // ✅ CACHE IMPLEMENTATION: O(1) index lookup - ELIMINATES 14-query linear search
    // Before: iterated through ALL brands making individual Firestore queries (0.740s)
    // After: instant O(1) dictionary lookup (~0.001s)
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

        // Index miss - try loading all perfumes first to build index
        if cachedAllPerfumes == nil {
            print("PerfumeService: Index empty, loading all perfumes to build index...")
            let _ = try await fetchAllPerfumesOnce()

            // After loading, try index again
            if let perfume = perfumeKeyIndex[key] {
                PerformanceLogger.logCacheHit("perfume-\(key)")
                let duration = Date().timeIntervalSince(startTime)
                PerformanceLogger.logNetworkEnd("fetchPerfume(byKey: \(key)) [INDEX after load]", duration: duration)
                print("PerfumeService: Found perfume '\(key)' in index after loading all")
                return perfume
            }
        }

        // ✅ OPTIMIZATION: If index is built but perfume not found, it doesn't exist
        // Avoid 14-query linear search for perfumes that were deleted or never existed
        if cachedAllPerfumes != nil {
            print("PerfumeService: Perfume '\(key)' not found in complete index of \(perfumeKeyIndex.count) perfumes - returning nil (perfume doesn't exist)")
            let duration = Date().timeIntervalSince(startTime)
            PerformanceLogger.logNetworkEnd("fetchPerfume(byKey: \(key)) [NOT FOUND]", duration: duration)
            return nil
        }

        // Should rarely reach here - only if cache is somehow inconsistent
        print("⚠️ PerfumeService: Cache inconsistent state - falling back to linear search for '\(key)'")
        PerformanceLogger.logCacheMiss("perfume-\(key)")
        PerformanceLogger.logNetworkStart("fetchPerfume(byKey: \(key)) [FALLBACK]")

        defer {
            let duration = Date().timeIntervalSince(startTime)
            PerformanceLogger.logNetworkEnd("fetchPerfume(byKey: \(key))", duration: duration)
        }

        // 1. Obtener marcas con perfumes
        let brandKeys = try await brandService.fetchBrandKeysWithPerfumes()

        // 2. Buscar en cada marca (slow O(n) search)
        for brandKey in brandKeys {
            let collectionPath = "perfumes/\(language)/\(brandKey)"
            PerformanceLogger.logFirestoreQuery(collectionPath, filters: "document(\(key))")
            let document = try await db.collection(collectionPath).document(key).getDocument()

            if document.exists {
                var perfume = try document.data(as: Perfume.self)
                perfume.id = document.documentID
                perfume.brand = brandKey
                return perfume
            }
        }

        return nil
    }
}
