import Foundation
import Combine
import SwiftUI

@MainActor
public final class TestViewModel: ObservableObject {
    @Published var questions: [Question] = []
    @Published var currentQuestionIndex: Int = 0
    @Published var answers: [String: Option] = [:]
    @Published var isLoading: Bool = false
    @Published var errorMessage: IdentifiableString?
    @Published var olfactiveProfile: OlfactiveProfile? // Perfil olfativo generado
    
    private let questionsService: TestServiceProtocol
    private let familyService: FamilyServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    var currentQuestion: Question? {
        guard !questions.isEmpty else { return nil }
        return questions[currentQuestionIndex]
    }
    
    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentQuestionIndex + 1) / Double(questions.count)
    }
    
    // MARK: - Inicialización con inyección de dependencias
    init(
        questionsService: TestServiceProtocol = DependencyContainer.shared.testService,
        familyService: FamilyServiceProtocol = DependencyContainer.shared.familyService
    ) {
        self.questionsService = questionsService
        self.familyService = familyService
        Task {
            await loadInitialData()
        }
    }
    
    // MARK: - Cargar Preguntas Inicialmente
    func loadInitialData() async {
        isLoading = true
        do {
            startListeningToQuestions()
            questions = try await questionsService.fetchQuestions()
            print("Preguntas cargadas exitosamente. Total: \(questions.count)")
        } catch {
            handleError("Error al cargar preguntas: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    // MARK: - Escuchar Cambios en Tiempo Real
    private func startListeningToQuestions() {
        questionsService.listenToQuestionsChanges()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.handleError("Error al escuchar cambios: \(error.localizedDescription)")
                case .finished:
                    break
                }
            } receiveValue: { [weak self] updatedQuestions in
                self?.questions = updatedQuestions
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Seleccionar una Opción
    func selectOption(_ option: Option) -> Bool {
        guard let currentQuestion = currentQuestion else { return false }
        
        // Guardar la respuesta seleccionada
        answers[currentQuestion.key] = option
        
        // Verificar si es la última pregunta
        let isLastQuestion = currentQuestionIndex == questions.count - 1
        if !isLastQuestion {
            currentQuestionIndex += 1
        } else {
            Task {
                await calculateOlfactiveProfile()
            }
        }
        return isLastQuestion
    }
    
    /// Calcula el perfil olfativo basado en las respuestas del usuario.
    func calculateOlfactiveProfile() async {
        guard !answers.isEmpty else {
            print("No hay suficientes respuestas para calcular el perfil.")
            return
        }
        
        self.olfactiveProfile = OlfactiveProfileHelper.generateProfile(from: answers)
    }
    
    func findQuestionAndAnswerTexts(for questionId: String, answerId: String) -> (question: String?, answer: String?) {
        let questionSelected = questions.first { $0.key == questionId }
        
        let answerSelected = questionSelected?.options.first { $0.id == answerId }
        
        return (question: questionSelected?.text, answer: answerSelected?.description)
    }
    
    private func handleError(_ message: String) {
        errorMessage = IdentifiableString(value: message)
    }
}
