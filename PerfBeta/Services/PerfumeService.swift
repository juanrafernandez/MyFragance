import FirebaseFirestore
import UIKit

protocol PerfumeServiceProtocol {
    func fetchAllPerfumesOnce() async throws -> [Perfume]
    func fetchPerfume(byKey key: String) async throws -> Perfume?
    func fetchPerfumesPaginated(limit: Int, lastDocument: DocumentSnapshot?) async throws -> (perfumes: [Perfume], lastDocument: DocumentSnapshot?)
    func fetchPerfumesWithFilters(gender: String?, family: String?, price: String?, limit: Int, lastDocument: DocumentSnapshot?) async throws -> (perfumes: [Perfume], lastDocument: DocumentSnapshot?)
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
        if cachedAllPerfumes != nil {
            print("PerfumeService: Perfume '\(key)' not found in complete index of \(perfumeKeyIndex.count) perfumes - returning nil (perfume doesn't exist)")
            let duration = Date().timeIntervalSince(startTime)
            PerformanceLogger.logNetworkEnd("fetchPerfume(byKey: \(key)) [NOT FOUND]", duration: duration)
            return nil
        }

        // ✅ NEW: Direct fetch from flat structure (fallback if cache somehow empty)
        print("⚠️ PerfumeService: Cache empty, trying direct fetch for '\(key)'")
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

    // MARK: - Fetch with Filters
    /// ✅ NEW: Fetches perfumes with filters and pagination
    func fetchPerfumesWithFilters(
        gender: String? = nil,
        family: String? = nil,
        price: String? = nil,
        limit: Int = 50,
        lastDocument: DocumentSnapshot? = nil
    ) async throws -> (perfumes: [Perfume], lastDocument: DocumentSnapshot?) {
        let startTime = Date()
        PerformanceLogger.trackFetch("fetchPerfumesWithFilters")

        var query: Query = db.collection("perfumes")

        // Apply filters
        if let gender = gender {
            query = query.whereField("gender", isEqualTo: gender)
            print("🔍 Filtering by gender: \(gender)")
        }

        if let family = family {
            query = query.whereField("family", isEqualTo: family)
            print("🔍 Filtering by family: \(family)")
        }

        if let price = price {
            query = query.whereField("price", isEqualTo: price)
            print("🔍 Filtering by price: \(price)")
        }

        // Order and pagination
        query = query.order(by: "popularity", descending: true)
            .limit(to: limit)

        if let lastDoc = lastDocument {
            query = query.start(afterDocument: lastDoc)
        }

        let snapshot = try await query.getDocuments()

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

        let finalLastDoc = perfumes.count < limit ? nil : snapshot.documents.last

        print("PerfumeService: Fetched \(perfumes.count) perfumes with filters")

        return (perfumes, finalLastDoc)
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
}
