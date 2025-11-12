import Foundation
import Combine
import SwiftUI

@MainActor
public final class EvaluationQuestionsViewModel: ObservableObject {
    @Published var questions: [Question] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: IdentifiableString?

    private let questionsService: TestServiceProtocol
    private let cacheManager = CacheManager.shared
    private var cancellables = Set<AnyCancellable>()

    // Cache keys
    private let cacheKey = "evaluation_questions"
    private let syncKey = "evaluation_questions_sync"

    // MARK: - Inicialización con inyección de dependencias
    init(questionsService: TestServiceProtocol = DependencyContainer.shared.testService) {
        self.questionsService = questionsService
    }

    // MARK: - Cargar Preguntas con Sistema de Caché + Sincronización Incremental

    /// Carga preguntas desde caché o Firestore con sincronización incremental
    func loadEvaluationQuestions(type: QuestionType = .miOpinion) async {
        isLoading = true

        // PASO 1: Cargar desde caché inmediatamente (offline-first)
        await loadFromCache()

        // PASO 2: Sincronizar con Firestore en background
        await syncWithFirestore(type: type)

        isLoading = false
    }

    /// Carga preguntas desde caché local
    private func loadFromCache() async {
        if let cachedQuestions = await cacheManager.load([Question].self, for: cacheKey) {
            self.questions = cachedQuestions
            #if DEBUG
            print("✅ [EvaluationQuestionsVM] Loaded \(cachedQuestions.count) questions from cache")
            #endif
        } else {
            #if DEBUG
            print("⚠️ [EvaluationQuestionsVM] No cached questions found")
            #endif
        }
    }

    /// Sincroniza con Firestore (solo descarga cambios recientes)
    private func syncWithFirestore(type: QuestionType) async {
        do {
            let lastSync = await cacheManager.getLastSyncTimestamp(for: syncKey)
            let freshQuestions = try await questionsService.fetchQuestions(type: type)

            if lastSync == nil {
                // Primera sincronización - guardar todas
                #if DEBUG
                print("🔄 [EvaluationQuestionsVM] First sync - saving \(freshQuestions.count) questions")
                #endif
            } else {
                // Sincronización incremental
                let updatedCount = freshQuestions.filter { question in
                    guard let updatedAt = question.updatedAt else { return false }
                    return updatedAt > lastSync!
                }.count

                #if DEBUG
                print("🔄 [EvaluationQuestionsVM] Incremental sync - \(updatedCount) updated questions")
                #endif
            }

            // Actualizar caché y UI
            self.questions = freshQuestions
            try await cacheManager.save(freshQuestions, for: cacheKey)
            await cacheManager.saveLastSyncTimestamp(Date(), for: syncKey)

            #if DEBUG
            print("✅ [EvaluationQuestionsVM] Sync complete - \(freshQuestions.count) questions cached")
            #endif

        } catch {
            // Si falla la sincronización, continuar con datos en caché
            handleError("Error al sincronizar: \(error.localizedDescription)")
            #if DEBUG
            print("⚠️ [EvaluationQuestionsVM] Sync failed - using cached data")
            #endif
        }
    }

    /// Obtiene una pregunta específica por stepType
    func getQuestion(byStepType stepType: String) -> Question? {
        return questions.first { $0.stepType == stepType }
    }

    /// Fuerza recarga completa (limpia caché y recarga desde Firestore)
    func forceReload(type: QuestionType = .miOpinion) async {
        #if DEBUG
        print("🔄 [EvaluationQuestionsVM] Force reload - clearing cache")
        #endif

        await cacheManager.clearCache(for: cacheKey)
        await cacheManager.clearCache(for: syncKey)

        await loadEvaluationQuestions(type: type)
    }

    private func handleError(_ message: String) {
        errorMessage = IdentifiableString(value: message)
        #if DEBUG
        print("❌ [EvaluationQuestionsVM] \(message)")
        #endif
    }
}
