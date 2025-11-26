//
//  AppConstants.swift
//  PerfBeta
//
//  Constantes centralizadas de la aplicación
//  Evita magic numbers dispersos en el código
//

import Foundation

// MARK: - App Constants

enum AppConstants {

    // MARK: - Pagination

    enum Pagination {
        /// Tamaño de página para recomendaciones iniciales
        static let defaultPageSize = 20

        /// Tamaño de página para exploración/scroll infinito
        static let explorePageSize = 50

        /// Límite de resultados en búsquedas
        static let searchResultsLimit = 50
    }

    // MARK: - Cache

    enum Cache {
        /// Tiempo de expiración del caché de perfumes (en segundos)
        static let perfumeCacheTimeout: TimeInterval = 3600 // 1 hora

        /// Tiempo de expiración del caché de preguntas (en segundos)
        static let questionsCacheTimeout: TimeInterval = 86400 // 24 horas

        /// Versión actual del caché (incrementar para forzar recarga)
        static let currentVersion = 2
    }

    // MARK: - Timing

    enum Timing {
        /// Delay para debouncing en búsquedas (en segundos)
        static let searchDebounceDelay: TimeInterval = 0.3

        /// Delay para mostrar indicador de carga (en segundos)
        static let loadingIndicatorDelay: TimeInterval = 0.1

        /// Duración de animaciones estándar (en segundos)
        static let standardAnimationDuration: TimeInterval = 0.3

        /// Duración de animaciones rápidas (en segundos)
        static let fastAnimationDuration: TimeInterval = 0.15
    }

    // MARK: - Layout

    enum Layout {
        /// Corner radius pequeño (botones, campos de texto)
        static let cornerRadiusSmall: CGFloat = 8

        /// Corner radius mediano (cards, modals)
        static let cornerRadiusMedium: CGFloat = 12

        /// Corner radius grande (sheets, overlays)
        static let cornerRadiusLarge: CGFloat = 16

        /// Padding horizontal estándar
        static let horizontalPadding: CGFloat = 16

        /// Padding vertical estándar
        static let verticalPadding: CGFloat = 12

        /// Spacing entre elementos de lista
        static let listItemSpacing: CGFloat = 8

        /// Spacing entre secciones
        static let sectionSpacing: CGFloat = 24
    }

    // MARK: - Limits

    enum Limits {
        /// Número máximo de perfiles olfativos por usuario
        static let maxOlfactiveProfiles = 10

        /// Número máximo de perfumes en wishlist
        static let maxWishlistItems = 100

        /// Número máximo de familias seleccionables en filtros
        static let maxFamilySelections = 2

        /// Longitud máxima de impresiones/comentarios
        static let maxImpressionsLength = 500
    }

    // MARK: - Image Cache (Kingfisher)

    enum ImageCache {
        /// Límite de memoria para caché de imágenes (en bytes)
        static let memoryLimit: UInt = 50 * 1024 * 1024 // 50 MB

        /// Límite de disco para caché de imágenes (en bytes)
        static let diskLimit: UInt = 200 * 1024 * 1024 // 200 MB
    }

    // MARK: - Firebase

    enum Firebase {
        /// Nombre de la colección de usuarios
        static let usersCollection = "users"

        /// Nombre de la colección de perfumes
        static let perfumesCollection = "perfumes"

        /// Prefijo para colecciones de preguntas por idioma
        static let questionsCollectionPrefix = "questions_"
    }
}
