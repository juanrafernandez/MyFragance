//
//  LoggingService.swift
//  PerfBeta
//
//  Sistema de logging centralizado para la aplicación
//  Solo activo en DEBUG, no afecta el rendimiento en producción
//

import Foundation
import os.log

// MARK: - Log Level

enum LogLevel: Int, Comparable {
    case verbose = 0  // Detalles muy granulares
    case debug = 1    // Información de debugging
    case info = 2     // Información general
    case warning = 3  // Advertencias que no son errores
    case error = 4    // Errores que afectan funcionalidad
    case none = 5     // Desactivar logs

    var emoji: String {
        switch self {
        case .verbose: return "🔍"
        case .debug: return "🐛"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .none: return ""
        }
    }

    var osLogType: OSLogType {
        switch self {
        case .verbose, .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        case .none: return .debug
        }
    }

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Log Category

enum LogCategory: String {
    case auth = "Auth"
    case perfume = "Perfume"
    case profile = "Profile"
    case cache = "Cache"
    case network = "Network"
    case ui = "UI"
    case recommendation = "Recommendation"
    case questions = "Questions"
    case gift = "Gift"
    case startup = "Startup"
    case general = "General"
}

// MARK: - AppLogger

final class AppLogger {

    // MARK: - Configuration

    /// Nivel mínimo de log que se mostrará
    static var minimumLevel: LogLevel = .debug

    /// Categorías activas (nil = todas)
    static var activeCategories: Set<LogCategory>? = nil

    /// Mostrar timestamps en los logs
    static var showTimestamp: Bool = false

    /// Mostrar el archivo y línea del log
    static var showFileInfo: Bool = true

    // MARK: - Private Properties

    private static let osLog = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "PerfBeta", category: "App")
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()

    // MARK: - Public Methods

    /// Log principal con todos los parámetros
    static func log(
        _ message: String,
        level: LogLevel = .debug,
        category: LogCategory = .general,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        #if DEBUG
        guard level >= minimumLevel else { return }

        if let categories = activeCategories, !categories.contains(category) {
            return
        }

        let filename = URL(fileURLWithPath: file).deletingPathExtension().lastPathComponent
        var logMessage = "\(level.emoji) [\(category.rawValue)]"

        if showTimestamp {
            logMessage += " \(dateFormatter.string(from: Date()))"
        }

        if showFileInfo {
            logMessage += " [\(filename):\(line)]"
        }

        logMessage += " \(message)"

        print(logMessage)
        os_log("%{public}@", log: osLog, type: level.osLogType, logMessage)
        #endif
    }

    // MARK: - Convenience Methods

    /// Log verbose (muy detallado)
    static func verbose(_ message: String, category: LogCategory = .general, file: String = #file, line: Int = #line) {
        log(message, level: .verbose, category: category, file: file, line: line)
    }

    /// Log debug (para desarrollo)
    static func debug(_ message: String, category: LogCategory = .general, file: String = #file, line: Int = #line) {
        log(message, level: .debug, category: category, file: file, line: line)
    }

    /// Log info (información general)
    static func info(_ message: String, category: LogCategory = .general, file: String = #file, line: Int = #line) {
        log(message, level: .info, category: category, file: file, line: line)
    }

    /// Log warning (advertencias)
    static func warning(_ message: String, category: LogCategory = .general, file: String = #file, line: Int = #line) {
        log(message, level: .warning, category: category, file: file, line: line)
    }

    /// Log error (errores)
    static func error(_ message: String, category: LogCategory = .general, file: String = #file, line: Int = #line) {
        log(message, level: .error, category: category, file: file, line: line)
    }

    /// Log error con Error object
    static func error(_ message: String, error: Error, category: LogCategory = .general, file: String = #file, line: Int = #line) {
        log("\(message): \(error.localizedDescription)", level: .error, category: category, file: file, line: line)
    }

    // MARK: - Performance Logging

    /// Mide el tiempo de ejecución de un bloque
    @discardableResult
    static func measure<T>(_ label: String, category: LogCategory = .general, block: () throws -> T) rethrows -> T {
        #if DEBUG
        let start = CFAbsoluteTimeGetCurrent()
        let result = try block()
        let duration = CFAbsoluteTimeGetCurrent() - start
        log("⏱️ \(label): \(String(format: "%.3f", duration * 1000))ms", level: .debug, category: category)
        return result
        #else
        return try block()
        #endif
    }

    /// Mide el tiempo de ejecución de un bloque async
    @discardableResult
    static func measureAsync<T>(_ label: String, category: LogCategory = .general, block: () async throws -> T) async rethrows -> T {
        #if DEBUG
        let start = CFAbsoluteTimeGetCurrent()
        let result = try await block()
        let duration = CFAbsoluteTimeGetCurrent() - start
        log("⏱️ \(label): \(String(format: "%.3f", duration * 1000))ms", level: .debug, category: category)
        return result
        #else
        return try await block()
        #endif
    }

    // MARK: - Configuration Helpers

    /// Configura el logger para desarrollo (todos los logs)
    static func configureDevelopment() {
        minimumLevel = .verbose
        activeCategories = nil
        showTimestamp = true
        showFileInfo = true
    }

    /// Configura el logger para producción (solo errores)
    static func configureProduction() {
        minimumLevel = .error
        activeCategories = nil
        showTimestamp = false
        showFileInfo = false
    }

    /// Configura el logger para debugging de una categoría específica
    static func configureForDebugging(_ categories: LogCategory...) {
        minimumLevel = .verbose
        activeCategories = Set(categories)
        showTimestamp = true
        showFileInfo = true
    }
}

// MARK: - Global Convenience Functions

/// Shortcut para AppLogger.debug
func logDebug(_ message: String, category: LogCategory = .general, file: String = #file, line: Int = #line) {
    AppLogger.debug(message, category: category, file: file, line: line)
}

/// Shortcut para AppLogger.info
func logInfo(_ message: String, category: LogCategory = .general, file: String = #file, line: Int = #line) {
    AppLogger.info(message, category: category, file: file, line: line)
}

/// Shortcut para AppLogger.warning
func logWarning(_ message: String, category: LogCategory = .general, file: String = #file, line: Int = #line) {
    AppLogger.warning(message, category: category, file: file, line: line)
}

/// Shortcut para AppLogger.error
func logError(_ message: String, category: LogCategory = .general, file: String = #file, line: Int = #line) {
    AppLogger.error(message, category: category, file: file, line: line)
}
