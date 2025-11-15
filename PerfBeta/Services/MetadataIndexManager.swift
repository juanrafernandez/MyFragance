import Foundation
import FirebaseFirestore

/// Gestor de índice de metadata con caché infinita + sync incremental
actor MetadataIndexManager {
    static let shared = MetadataIndexManager()

    private let db = Firestore.firestore()
    private let cacheManager = CacheManager.shared
    private let cacheKey = "metadata_index"

    // ✅ Cache en memoria para evitar cargas repetidas desde disco
    private var cachedIndex: [PerfumeMetadata]?

    private init() {}

    // MARK: - Get Metadata Index

    /// Obtiene el índice completo de metadata (desde caché o Firestore)
    func getMetadataIndex() async throws -> [PerfumeMetadata] {
        // 0. Check memoria primero (muy rápido)
        if let memoryCache = cachedIndex {
            #if DEBUG
            print("⚡ [MetadataIndex] Returned from MEMORY cache (\(memoryCache.count) perfumes)")
            #endif
            return memoryCache
        }

        // 1. Cargar de caché permanente (disco)
        if let cached = await cacheManager.load([PerfumeMetadata].self, for: cacheKey) {
            #if DEBUG
            print("✅ [MetadataIndex] Loaded \(cached.count) from permanent cache")
            #endif

            // ✅ FIX: Si el cache está vacío, es inválido - forzar descarga completa
            if cached.isEmpty {
                #if DEBUG
                print("⚠️ [MetadataIndex] Cache vacío detectado - forzando descarga completa...")
                #endif
                return try await downloadFullIndex()
            }

            // ✅ Guardar en memoria para próximas llamadas
            cachedIndex = cached

            // Auto-sync en background (no bloqueante)
            Task {
                do {
                    try await syncIncrementalChanges()
                } catch {
                    #if DEBUG
                    print("⚠️ [MetadataIndex] Background sync failed: \(error)")
                    #endif
                }
            }

            return cached
        }

        // 2. Primera vez: descarga completo
        #if DEBUG
        print("📥 [MetadataIndex] First download - this will take a moment...")
        #endif
        return try await downloadFullIndex()
    }

    // MARK: - Download Full Index

    /// Descarga el índice completo la primera vez
    private func downloadFullIndex() async throws -> [PerfumeMetadata] {
        let startTime = Date()

        let snapshot = try await db.collection("perfumes")
            .order(by: "popularity", descending: true)
            .getDocuments()

        let duration = Date().timeIntervalSince(startTime)
        #if DEBUG
        print("⚠️ FIRESTORE READ: \(snapshot.documents.count) docs (FULL INDEX) in \(String(format: "%.2f", duration))s")
        #endif

        let metadata = snapshot.documents.compactMap { document -> PerfumeMetadata? in
            do {
                var meta = try document.data(as: PerfumeMetadata.self)
                meta.id = document.documentID
                return meta
            } catch {
                #if DEBUG
                print("❌ Error decoding metadata \(document.documentID): \(error)")
                #endif
                return nil
            }
        }

        // Guardar en caché permanente
        try await cacheManager.save(metadata, for: cacheKey)
        await cacheManager.saveLastSyncTimestamp(Date(), for: cacheKey)

        // ✅ Guardar en memoria
        cachedIndex = metadata

        #if DEBUG
        print("✅ [MetadataIndex] Cached \(metadata.count) perfumes permanently (disk + memory)")
        #endif
        return metadata
    }

    // MARK: - Sync Incremental

    /// Sincroniza solo los cambios desde el último sync
    func syncIncrementalChanges() async throws {
        guard let lastSync = await cacheManager.getLastSyncTimestamp(for: cacheKey) else {
            #if DEBUG
            print("ℹ️ [MetadataIndex] No last sync timestamp, skipping incremental sync")
            #endif
            return
        }

        let hoursSinceSync = Date().timeIntervalSince(lastSync) / 3600
        #if DEBUG
        print("🔄 [MetadataIndex] Syncing changes since \(String(format: "%.1f", hoursSinceSync))h ago")
        #endif

        let startTime = Date()

        // Query solo documentos modificados/creados desde lastSync
        let snapshot = try await db.collection("perfumes")
            .whereField("updatedAt", isGreaterThan: Timestamp(date: lastSync))
            .getDocuments()

        if snapshot.documents.isEmpty {
            #if DEBUG
            print("✅ [MetadataIndex] No changes since last sync")
            #endif
            await cacheManager.saveLastSyncTimestamp(Date(), for: cacheKey)
            return
        }

        let duration = Date().timeIntervalSince(startTime)
        #if DEBUG
        print("⚠️ FIRESTORE READ: \(snapshot.documents.count) docs (INCREMENTAL) in \(String(format: "%.2f", duration))s")
        #endif

        let updated = snapshot.documents.compactMap { document -> PerfumeMetadata? in
            do {
                var meta = try document.data(as: PerfumeMetadata.self)
                meta.id = document.documentID
                return meta
            } catch {
                #if DEBUG
                print("❌ Error decoding metadata \(document.documentID): \(error)")
                #endif
                return nil
            }
        }

        // Cargar caché actual
        var cached = await cacheManager.load([PerfumeMetadata].self, for: cacheKey) ?? []

        // Merge: actualizar existentes y añadir nuevos
        var updatedCount = 0
        var newCount = 0

        for item in updated {
            guard let id = item.id else { continue }

            if let index = cached.firstIndex(where: { $0.id == id }) {
                cached[index] = item
                updatedCount += 1
                #if DEBUG
                print("   🔄 Updated: \(item.name)")
                #endif
            } else {
                cached.append(item)
                newCount += 1
                #if DEBUG
                print("   ✨ New: \(item.name)")
                #endif
            }
        }

        // Guardar caché actualizada (disco)
        try await cacheManager.save(cached, for: cacheKey)
        await cacheManager.saveLastSyncTimestamp(Date(), for: cacheKey)

        // ✅ Actualizar cache en memoria también
        cachedIndex = cached

        #if DEBUG
        print("✅ [MetadataIndex] Synced: \(cached.count) total (\(updatedCount) updated, \(newCount) new)")
        #endif
    }

    // MARK: - Force Refresh

    /// Fuerza descarga completa (útil para debug o después de cambios masivos)
    func forceRefresh() async throws {
        await cacheManager.clearCache(for: cacheKey)
        _ = try await downloadFullIndex()
    }
}
