import Foundation
import FirebaseFirestore

/// Gestor de índice de metadata con caché infinita + sync incremental
actor MetadataIndexManager {
    static let shared = MetadataIndexManager()

    private let db = Firestore.firestore()
    private let cacheManager = CacheManager.shared
    private let cacheKey = "metadata_index"

    private init() {}

    // MARK: - Get Metadata Index

    /// Obtiene el índice completo de metadata (desde caché o Firestore)
    func getMetadataIndex() async throws -> [PerfumeMetadata] {
        // 1. Cargar de caché permanente
        if let cached = await cacheManager.load([PerfumeMetadata].self, for: cacheKey) {
            print("✅ [MetadataIndex] Loaded \(cached.count) from permanent cache")

            // ✅ FIX: Si el cache está vacío, es inválido - forzar descarga completa
            if cached.isEmpty {
                print("⚠️ [MetadataIndex] Cache vacío detectado - forzando descarga completa...")
                return try await downloadFullIndex()
            }

            // Auto-sync en background (no bloqueante)
            Task {
                do {
                    try await syncIncrementalChanges()
                } catch {
                    print("⚠️ [MetadataIndex] Background sync failed: \(error)")
                }
            }

            return cached
        }

        // 2. Primera vez: descarga completo
        print("📥 [MetadataIndex] First download - this will take a moment...")
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
        print("⚠️ FIRESTORE READ: \(snapshot.documents.count) docs (FULL INDEX) in \(String(format: "%.2f", duration))s")

        let metadata = snapshot.documents.compactMap { document -> PerfumeMetadata? in
            do {
                var meta = try document.data(as: PerfumeMetadata.self)
                meta.id = document.documentID
                return meta
            } catch {
                print("❌ Error decoding metadata \(document.documentID): \(error)")
                return nil
            }
        }

        // Guardar en caché permanente
        try await cacheManager.save(metadata, for: cacheKey)
        await cacheManager.saveLastSyncTimestamp(Date(), for: cacheKey)

        print("✅ [MetadataIndex] Cached \(metadata.count) perfumes permanently")
        return metadata
    }

    // MARK: - Sync Incremental

    /// Sincroniza solo los cambios desde el último sync
    func syncIncrementalChanges() async throws {
        guard let lastSync = await cacheManager.getLastSyncTimestamp(for: cacheKey) else {
            print("ℹ️ [MetadataIndex] No last sync timestamp, skipping incremental sync")
            return
        }

        let hoursSinceSync = Date().timeIntervalSince(lastSync) / 3600
        print("🔄 [MetadataIndex] Syncing changes since \(String(format: "%.1f", hoursSinceSync))h ago")

        let startTime = Date()

        // Query solo documentos modificados/creados desde lastSync
        let snapshot = try await db.collection("perfumes")
            .whereField("updatedAt", isGreaterThan: Timestamp(date: lastSync))
            .getDocuments()

        if snapshot.documents.isEmpty {
            print("✅ [MetadataIndex] No changes since last sync")
            await cacheManager.saveLastSyncTimestamp(Date(), for: cacheKey)
            return
        }

        let duration = Date().timeIntervalSince(startTime)
        print("⚠️ FIRESTORE READ: \(snapshot.documents.count) docs (INCREMENTAL) in \(String(format: "%.2f", duration))s")

        let updated = snapshot.documents.compactMap { document -> PerfumeMetadata? in
            do {
                var meta = try document.data(as: PerfumeMetadata.self)
                meta.id = document.documentID
                return meta
            } catch {
                print("❌ Error decoding metadata \(document.documentID): \(error)")
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
                print("   🔄 Updated: \(item.name)")
            } else {
                cached.append(item)
                newCount += 1
                print("   ✨ New: \(item.name)")
            }
        }

        // Guardar caché actualizada
        try await cacheManager.save(cached, for: cacheKey)
        await cacheManager.saveLastSyncTimestamp(Date(), for: cacheKey)

        print("✅ [MetadataIndex] Synced: \(cached.count) total (\(updatedCount) updated, \(newCount) new)")
    }

    // MARK: - Force Refresh

    /// Fuerza descarga completa (útil para debug o después de cambios masivos)
    func forceRefresh() async throws {
        await cacheManager.clearCache(for: cacheKey)
        _ = try await downloadFullIndex()
    }
}
