import Foundation
import Combine
import SwiftUI

@MainActor
public final class QuestionsViewModel: ObservableObject {
    @Published var questions: [Question] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: IdentifiableString?

    private let questionsService: QuestionsServiceProtocol

    // MARK: - Inicialización con Dependencias Inyectadas
    init(questionsService: QuestionsServiceProtocol = DependencyContainer.shared.questionsService) {
        self.questionsService = questionsService
    }

    // MARK: - Cargar Datos Iniciales
    func loadInitialData() async {
        isLoading = true
        do {
            questions = try await questionsService.fetchQuestions()
            print("Preguntas cargadas exitosamente. Total: \(questions.count)")
            // Iniciar la escucha de cambios en tiempo real
            startListeningToQuestions(for: AppState.shared.levelSelected)
        } catch {
            handleError("Error al cargar preguntas: \(error.localizedDescription)")
        }
        isLoading = false
    }

    // MARK: - Manejo de Errores
    private func handleError(_ message: String) {
        errorMessage = IdentifiableString(value: message)
    }
    
    // MARK: - Escuchar Cambios en Tiempo Real
    func startListeningToQuestions(for level: String) {
        questionsService.listenToQuestionsChanges() { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let updatedQuestions):
                    self?.questions = updatedQuestions
                case .failure(let error):
                    self?.errorMessage = IdentifiableString(value: "Error al escuchar cambios: \(error.localizedDescription)")
                }
            }
        }
    }
}
