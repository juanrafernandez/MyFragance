import Foundation
import os.log

/// Sistema de logging avanzado para diagnosticar problemas de performance
/// Detecta: fetches duplicados, bloqueos del main thread, operaciones lentas, cache misses
struct PerformanceLogger {
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "PerfBeta", category: "Performance")

    // MARK: - Network Tracking

    /// Registra el inicio de una llamada de red
    /// - Parameters:
    ///   - endpoint: Nombre del endpoint o operación
    ///   - file: Archivo donde se llama (auto-capturado)
    ///   - line: Línea donde se llama (auto-capturado)
    static func logNetworkStart(_ endpoint: String, file: String = #file, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent
        logger.info("🌐 START: \(endpoint) | \(fileName):\(line)")
    }

    /// Registra el fin de una llamada de red con su duración
    /// - Parameters:
    ///   - endpoint: Nombre del endpoint o operación
    ///   - duration: Duración en segundos
    ///   - file: Archivo donde se llama (auto-capturado)
    static func logNetworkEnd(_ endpoint: String, duration: TimeInterval, file: String = #file) {
        let fileName = (file as NSString).lastPathComponent
        let emoji = duration > 1.0 ? "🐌" : duration > 0.5 ? "⚠️" : "✅"
        logger.info("\(emoji) END: \(endpoint) | \(String(format: "%.3f", duration))s | \(fileName)")
    }

    // MARK: - Cache Tracking

    /// Registra cuando se encuentra un elemento en caché (evita fetch de red)
    /// - Parameters:
    ///   - key: Clave del elemento en caché
    ///   - file: Archivo donde se llama (auto-capturado)
    static func logCacheHit(_ key: String, file: String = #file) {
        let fileName = (file as NSString).lastPathComponent
        logger.info("✅ CACHE HIT: \(key) | \(fileName)")
    }

    /// Registra cuando NO se encuentra un elemento en caché (requiere fetch)
    /// - Parameters:
    ///   - key: Clave del elemento que no está en caché
    ///   - file: Archivo donde se llama (auto-capturado)
    static func logCacheMiss(_ key: String, file: String = #file) {
        let fileName = (file as NSString).lastPathComponent
        logger.warning("❌ CACHE MISS: \(key) | \(fileName)")
    }

    // MARK: - Duplicate Fetch Detection

    /// Diccionario thread-safe para rastrear fetches duplicados
    private static var fetchTracking: [String: Int] = [:]
    private static let trackingQueue = DispatchQueue(label: "com.perfbeta.fetchTracking")

    /// Rastrea un fetch para detectar llamadas duplicadas a la misma operación
    /// ⚠️ CRÍTICO: Si ves DUPLICATE FETCH en logs, significa que estás haciendo fetches innecesarios
    /// - Parameters:
    ///   - endpoint: Nombre del endpoint o operación
    ///   - file: Archivo donde se llama (auto-capturado)
    ///   - line: Línea donde se llama (auto-capturado)
    static func trackFetch(_ endpoint: String, file: String = #file, line: Int = #line) {
        trackingQueue.sync {
            let key = "\(endpoint)_\((file as NSString).lastPathComponent)"
            fetchTracking[key, default: 0] += 1
            let count = fetchTracking[key]!

            if count > 1 {
                logger.error("⚠️⚠️ DUPLICATE FETCH #\(count): \(endpoint) | \((file as NSString).lastPathComponent):\(line)")
            }
        }
    }

    /// Resetea el tracking de fetches (útil entre sesiones de debugging)
    static func resetFetchTracking() {
        trackingQueue.sync {
            fetchTracking.removeAll()
            logger.info("🔄 Fetch tracking reset")
        }
    }

    /// Obtiene estadísticas de fetches duplicados
    static func getFetchStats() -> [(endpoint: String, count: Int)] {
        trackingQueue.sync {
            return fetchTracking
                .filter { $0.value > 1 }
                .map { (endpoint: $0.key, count: $0.value) }
                .sorted { $0.count > $1.count }
        }
    }

    // MARK: - Main Thread Warning

    /// Detecta operaciones que bloquean el main thread
    /// ⚠️ CRÍTICO: Operaciones > 16ms causan frames dropped y UI no responsivo
    /// - Parameters:
    ///   - operation: Nombre de la operación
    ///   - duration: Duración en segundos
    ///   - file: Archivo donde se llama (auto-capturado)
    ///   - line: Línea donde se llama (auto-capturado)
    static func logMainThreadBlock(_ operation: String, duration: TimeInterval, file: String = #file, line: Int = #line) {
        let fileName = (file as NSString).lastPathComponent

        if duration > 0.016 { // 16ms = 1 frame @ 60fps
            let frames = Int(duration / 0.016)
            logger.error("🚫 MAIN THREAD BLOCKED: \(operation) | \(String(format: "%.3f", duration))s (~\(frames) frames) | \(fileName):\(line)")
        }
    }

    // MARK: - ViewModel Lifecycle

    /// Registra cuando una vista aparece (para detectar fetches en onAppear)
    /// - Parameter viewName: Nombre de la vista
    static func logViewAppear(_ viewName: String) {
        logger.info("👁️ VIEW APPEAR: \(viewName)")
    }

    /// Registra cuando una vista desaparece
    /// - Parameter viewName: Nombre de la vista
    static func logViewDisappear(_ viewName: String) {
        logger.info("👋 VIEW DISAPPEAR: \(viewName)")
    }

    /// Registra una carga de datos en un ViewModel
    /// - Parameters:
    ///   - viewModel: Nombre del ViewModel
    ///   - action: Acción realizada (ej: "loadPerfumes")
    static func logViewModelLoad(_ viewModel: String, action: String) {
        logger.info("📦 VIEWMODEL LOAD: \(viewModel).\(action)")
    }

    // MARK: - Helper: Measure Block

    /// Mide la duración de un bloque síncrono de código
    /// Uso:
    /// ```
    /// let result = PerformanceLogger.measure("parseJSON") {
    ///     return try JSONDecoder().decode(Model.self, from: data)
    /// }
    /// ```
    /// - Parameters:
    ///   - operation: Nombre de la operación a medir
    ///   - file: Archivo donde se llama (auto-capturado)
    ///   - line: Línea donde se llama (auto-capturado)
    ///   - block: Bloque de código a ejecutar y medir
    /// - Returns: Resultado del bloque
    @discardableResult
    static func measure<T>(_ operation: String, file: String = #file, line: Int = #line, block: () throws -> T) rethrows -> T {
        let fileName = (file as NSString).lastPathComponent
        let start = Date()
        logger.info("⏱️ START: \(operation) | \(fileName):\(line)")

        let result = try block()

        let duration = Date().timeIntervalSince(start)
        let emoji = duration > 1.0 ? "🐌" : duration > 0.5 ? "⚠️" : "✅"
        logger.info("\(emoji) FINISH: \(operation) | \(String(format: "%.3f", duration))s | \(fileName)")

        return result
    }

    /// Mide la duración de un bloque asíncrono de código
    /// Uso:
    /// ```
    /// let perfumes = await PerformanceLogger.measureAsync("fetchPerfumes") {
    ///     return try await service.fetchPerfumes()
    /// }
    /// ```
    /// - Parameters:
    ///   - operation: Nombre de la operación a medir
    ///   - file: Archivo donde se llama (auto-capturado)
    ///   - line: Línea donde se llama (auto-capturado)
    ///   - block: Bloque asíncrono a ejecutar y medir
    /// - Returns: Resultado del bloque
    @discardableResult
    static func measureAsync<T>(_ operation: String, file: String = #file, line: Int = #line, block: () async throws -> T) async rethrows -> T {
        let fileName = (file as NSString).lastPathComponent
        let start = Date()
        logger.info("⏱️ START ASYNC: \(operation) | \(fileName):\(line)")

        let result = try await block()

        let duration = Date().timeIntervalSince(start)
        let emoji = duration > 1.0 ? "🐌" : duration > 0.5 ? "⚠️" : "✅"
        logger.info("\(emoji) FINISH ASYNC: \(operation) | \(String(format: "%.3f", duration))s | \(fileName)")

        return result
    }

    // MARK: - Firestore Specific

    /// Registra una query de Firestore (útil para optimizar queries complejas)
    /// - Parameters:
    ///   - collection: Nombre de la colección
    ///   - filters: Descripción de los filtros aplicados
    ///   - file: Archivo donde se llama (auto-capturado)
    static func logFirestoreQuery(_ collection: String, filters: String = "none", file: String = #file) {
        let fileName = (file as NSString).lastPathComponent
        logger.info("🔥 FIRESTORE QUERY: \(collection) | filters: \(filters) | \(fileName)")
    }

    /// Registra el resultado de una query de Firestore
    /// - Parameters:
    ///   - collection: Nombre de la colección
    ///   - count: Número de documentos retornados
    ///   - duration: Duración de la query
    static func logFirestoreResult(_ collection: String, count: Int, duration: TimeInterval) {
        let emoji = duration > 1.0 ? "🐌" : duration > 0.5 ? "⚠️" : "✅"
        logger.info("\(emoji) FIRESTORE RESULT: \(collection) | \(count) docs | \(String(format: "%.3f", duration))s")
    }

    // MARK: - Image Loading

    /// Registra inicio de carga de imagen
    /// - Parameters:
    ///   - url: URL de la imagen
    ///   - file: Archivo donde se llama (auto-capturado)
    static func logImageLoadStart(_ url: String, file: String = #file) {
        let fileName = (file as NSString).lastPathComponent
        logger.info("🖼️ IMAGE LOAD START: \(url) | \(fileName)")
    }

    /// Registra fin de carga de imagen
    /// - Parameters:
    ///   - url: URL de la imagen
    ///   - fromCache: Si la imagen vino del caché
    ///   - duration: Duración de la carga
    static func logImageLoadEnd(_ url: String, fromCache: Bool, duration: TimeInterval) {
        let emoji = fromCache ? "✅" : (duration > 1.0 ? "🐌" : "⚠️")
        let source = fromCache ? "CACHE" : "NETWORK"
        logger.info("\(emoji) IMAGE LOAD END: \(url) | \(source) | \(String(format: "%.3f", duration))s")
    }

    // MARK: - Performance Summary

    /// Genera un resumen de performance para debugging
    static func printPerformanceSummary() {
        let separator = String(repeating: "=", count: 50)
        logger.info("\(separator)")
        logger.info("📊 PERFORMANCE SUMMARY")
        logger.info("\(separator)")

        let stats = getFetchStats()
        if !stats.isEmpty {
            logger.warning("⚠️ DUPLICATE FETCHES DETECTED:")
            for stat in stats.prefix(10) {
                logger.warning("   - \(stat.endpoint): \(stat.count) times")
            }
        } else {
            logger.info("✅ No duplicate fetches detected")
        }

        logger.info("\(separator)")
    }
}
