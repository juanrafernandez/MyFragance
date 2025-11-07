import Foundation

/// Sistema de caché permanente (sin expiración) + timestamps para sync incremental
actor CacheManager {
    static let shared = CacheManager()

    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    private init() {
        // Crear directorio de caché si no existe
        let cachePaths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = cachePaths[0].appendingPathComponent("PerfBetaCache", isDirectory: true)

        do {
            try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            #if DEBUG
            print("📦 [CacheManager] Directory: \(cacheDirectory.path)")
            #endif
        } catch {
            #if DEBUG
            print("❌ [CacheManager] Error creating directory: \(error)")
            #endif
        }
    }

    // MARK: - Save/Load (Caché SIN expiración)

    /// Guarda objeto en caché permanente (sin expiración)
    func save<T: Codable>(_ object: T, for key: String) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(object)

        let fileURL = cacheDirectory.appendingPathComponent("\(key).cache")
        try data.write(to: fileURL)

        let size = ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)
        #if DEBUG
        print("💾 [CacheManager] Saved '\(key)' permanently (\(size))")
        #endif
    }

    /// Carga objeto desde caché (no expira nunca)
    func load<T: Codable>(_ type: T.Type, for key: String) -> T? {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).cache")

        guard fileManager.fileExists(atPath: fileURL.path) else {
            #if DEBUG
            print("❌ [CacheManager] Cache MISS for '\(key)'")
            #endif
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let object = try decoder.decode(T.self, from: data)

            let size = ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)
            #if DEBUG
            print("✅ [CacheManager] Cache HIT for '\(key)' (\(size))")
            #endif
            return object
        } catch {
            #if DEBUG
            print("❌ [CacheManager] Error loading '\(key)': \(error)")
            #endif
            return nil
        }
    }

    // MARK: - Sync Timestamps

    /// Guarda timestamp del último sync (para sync incremental)
    func saveLastSyncTimestamp(_ timestamp: Date, for key: String) {
        UserDefaults.standard.set(timestamp.timeIntervalSince1970, forKey: "\(key)_last_sync")
        #if DEBUG
        print("⏰ [CacheManager] Saved sync timestamp for '\(key)'")
        #endif
    }

    /// Obtiene timestamp del último sync
    func getLastSyncTimestamp(for key: String) -> Date? {
        let interval = UserDefaults.standard.double(forKey: "\(key)_last_sync")
        guard interval > 0 else { return nil }
        return Date(timeIntervalSince1970: interval)
    }

    // MARK: - Clear Cache

    /// Borra caché específica
    func clearCache(for key: String) {
        let fileURL = cacheDirectory.appendingPathComponent("\(key).cache")
        try? fileManager.removeItem(at: fileURL)
        UserDefaults.standard.removeObject(forKey: "\(key)_last_sync")
        #if DEBUG
        print("🗑️ [CacheManager] Cleared cache for '\(key)'")
        #endif
    }

    /// Borra toda la caché
    func clearAllCache() {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try fileManager.removeItem(at: file)
            }
            #if DEBUG
            print("🗑️ [CacheManager] All cache cleared")
            #endif
        } catch {
            #if DEBUG
            print("❌ [CacheManager] Error clearing cache: \(error)")
            #endif
        }
    }

    // MARK: - Cache Stats

    /// Obtiene tamaño total de la caché
    func getCacheSize() -> Int64 {
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
            let totalSize = files.reduce(Int64(0)) { total, fileURL in
                let attributes = try? fileManager.attributesOfItem(atPath: fileURL.path)
                let size = attributes?[.size] as? Int64 ?? 0
                return total + size
            }
            return totalSize
        } catch {
            return 0
        }
    }
}
