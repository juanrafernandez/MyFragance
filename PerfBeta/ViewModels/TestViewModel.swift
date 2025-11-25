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
    @Published var olfactiveProfile: OlfactiveProfile? // Legacy: Perfil olfativo generado
    @Published var unifiedProfile: UnifiedProfile? // NEW: Perfil unificado

    private let questionsService: TestServiceProtocol
    private let familyService: FamilyServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // Sistema unificado activo (legacy eliminado)
    private let useUnifiedEngine: Bool = true

    // NEW: Flow routing support
    private var allQuestions: [Question] = []  // Store all loaded questions
    private var selectedFlow: String? = nil     // Track which flow was selected (A, B, C)
    
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
    func loadInitialData(type: QuestionType = .perfilOlfativo) async {
        isLoading = true
        do {
            startListeningToQuestions(type: type)
            allQuestions = try await questionsService.fetchQuestions(type: type)

            // Initially show only the classification question
            if let classificationQuestion = allQuestions.first(where: { $0.id == "profile_00_classification" }) {
                questions = [classificationQuestion]
                currentQuestionIndex = 0
                selectedFlow = nil

                #if DEBUG
                print("📋 [TestViewModel] Preguntas cargadas: \(allQuestions.count) total")
                print("   Mostrando pregunta de clasificación: \(classificationQuestion.key ?? classificationQuestion.id)")
                print("   Opciones con rutas:")
                for option in classificationQuestion.options {
                    print("     - \(option.label): route = \(option.route ?? "nil")")
                }
                #endif
            } else {
                // Fallback: show all questions if classification not found
                questions = allQuestions
                #if DEBUG
                print("⚠️ [TestViewModel] No se encontró profile_00_classification, mostrando todas las preguntas")
                #endif
            }

            #if DEBUG
            print("   TODAS las preguntas cargadas:")
            for (index, q) in allQuestions.enumerated() {
                let isTargetQuestion = q.id == "profile_00_classification"
                let marker = isTargetQuestion ? " ⭐️" : ""
                print("     [\(index)] id:\(q.id) order:\(q.order) - \(q.key)\(marker)")
            }
            #endif
        } catch {
            handleError("Error al cargar preguntas: \(error.localizedDescription)")
        }
        isLoading = false
    }

    // MARK: - Escuchar Cambios en Tiempo Real
    private func startListeningToQuestions(type: QuestionType = .perfilOlfativo) {
        questionsService.listenToQuestionsChanges(type: type)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.handleError("Error al escuchar cambios: \(error.localizedDescription)")
                case .finished:
                    break
                }
            } receiveValue: { [weak self] updatedQuestions in
                guard let self = self else { return }

                // Update all questions
                self.allQuestions = updatedQuestions

                // Re-apply flow filter if a flow was selected
                if let flowPrefix = self.selectedFlow {
                    self.questions = updatedQuestions.filter { $0.id.hasPrefix(flowPrefix) }
                } else if self.currentQuestion?.id == "profile_00_classification" {
                    // Still at classification question, only show that one
                    if let classificationQuestion = updatedQuestions.first(where: { $0.id == "profile_00_classification" }) {
                        self.questions = [classificationQuestion]
                    }
                } else {
                    // No filter applied yet, show all
                    self.questions = updatedQuestions
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Seleccionar una Opción
    func selectOption(_ option: Option) {
        guard let currentQuestion = currentQuestion,
              let questionKey = currentQuestion.key else { return }

        // Solo guardar la respuesta seleccionada (no avanzar)
        answers[questionKey] = option

        #if DEBUG
        print("✅ [TestView] Opción seleccionada para \(questionKey): \(option.label)")
        #endif
    }

    func nextQuestion() async {
        // Special handling for classification question (first question)
        if currentQuestionIndex == 0 && currentQuestion?.id == "profile_00_classification" {
            await handleClassificationAnswer()
            return
        }

        // Verificar si es la última pregunta
        let isLastQuestion = currentQuestionIndex == questions.count - 1

        if !isLastQuestion {
            currentQuestionIndex += 1
            #if DEBUG
            print("➡️ [TestView] Avanzando a pregunta \(currentQuestionIndex + 1)/\(questions.count)")
            #endif
        } else {
            #if DEBUG
            print("🎉 [TestView] Última pregunta alcanzada, calculando perfil...")
            #endif
            await calculateOlfactiveProfile()
        }
    }

    /// Handle the classification question answer and filter questions by flow
    private func handleClassificationAnswer() async {
        guard let classificationQuestion = currentQuestion,
              let questionKey = classificationQuestion.key,
              let selectedOption = answers[questionKey],
              let route = selectedOption.route else {
            #if DEBUG
            print("⚠️ [TestViewModel] No se encontró route en la opción seleccionada")
            #endif
            // Fallback: show all questions
            questions = allQuestions
            currentQuestionIndex = 1
            return
        }

        // Extract flow prefix from route (e.g., "flow_A" -> "profile_A")
        let flowPrefix = route.replacingOccurrences(of: "flow_", with: "profile_")
        selectedFlow = flowPrefix

        #if DEBUG
        print("🔀 [TestViewModel] Filtrando preguntas por flow: \(route) -> \(flowPrefix)")
        #endif

        // Filter questions to only include those from the selected flow
        let flowQuestions = allQuestions.filter { question in
            question.id.hasPrefix(flowPrefix)
        }

        #if DEBUG
        print("   Preguntas del flow \(flowPrefix): \(flowQuestions.count)")
        for (index, q) in flowQuestions.enumerated() {
            print("     [\(index)] id:\(q.id) - \(q.key)")
        }
        #endif

        // Set the filtered questions and reset index
        questions = flowQuestions
        currentQuestionIndex = 0

        #if DEBUG
        if let firstQuestion = questions.first {
            print("   Primera pregunta del flow: \(firstQuestion.id) - \(firstQuestion.key)")
        }
        #endif
    }

    var isLastQuestion: Bool {
        return currentQuestionIndex == questions.count - 1
    }

    func previousQuestion() {
        guard currentQuestionIndex > 0 else { return }
        currentQuestionIndex -= 1
        #if DEBUG
        print("⬅️ [TestView] Retrocediendo a pregunta \(currentQuestionIndex + 1)/\(questions.count)")
        #endif
    }

    var canGoBack: Bool {
        return currentQuestionIndex > 0
    }
    
    /// Calcula el perfil olfativo basado en las respuestas del usuario.
    func calculateOlfactiveProfile() async {
        guard !answers.isEmpty else {
            #if DEBUG
            print("No hay suficientes respuestas para calcular el perfil.")
            #endif
            return
        }

        // Usar UnifiedRecommendationEngine (sistema único)
        await calculateWithUnifiedEngine()
    }

    /// Calcula perfil usando el nuevo UnifiedRecommendationEngine
    private func calculateWithUnifiedEngine() async {
        #if DEBUG
        print("🧮 [TestVM] Calculando perfil con UnifiedRecommendationEngine...")
        #endif

        // 1. Convertir answers al formato nuevo: [String: (Question, Option)]
        var answersDict: [String: (question: Question, option: Option)] = [:]

        for (questionKey, selectedOption) in answers {
            // Buscar la pregunta correspondiente
            if let question = questions.first(where: { $0.key == questionKey }) {
                answersDict[questionKey] = (question, selectedOption)
            } else {
                #if DEBUG
                print("⚠️ [TestVM] No se encontró pregunta para key: \(questionKey)")
                #endif
            }
        }

        guard !answersDict.isEmpty else {
            #if DEBUG
            print("❌ [TestVM] No se pudieron mapear las respuestas a preguntas")
            #endif
            return
        }

        // 2. Calcular perfil con el nuevo engine
        let profile = await UnifiedRecommendationEngine.shared.calculateProfile(
            from: answersDict,
            profileName: "Mi Perfil Olfativo",
            profileType: .personal
        )

        // 3. Guardar perfil unificado
        self.unifiedProfile = profile

        // 4. Convertir a legacy para compatibilidad con UI existente
        self.olfactiveProfile = profile.toLegacyProfile()

        #if DEBUG
        print("✅ [TestVM] Perfil calculado:")
        print("   Familia principal: \(profile.primaryFamily)")
        print("   Subfamilias: \(profile.subfamilies.joined(separator: ", "))")
        print("   Nivel experiencia: \(profile.experienceLevel.rawValue)")
        print("   Confianza: \(String(format: "%.2f", profile.confidenceScore))")
        print("   Completitud: \(String(format: "%.2f", profile.answerCompleteness))")
        #endif
    }
    
    func findQuestionAndAnswerTexts(for questionId: String, answerId: String) -> (question: String?, answer: String?) {
        let questionSelected = questions.first { $0.key == questionId }

        let answerSelected = questionSelected?.options.first { $0.id == answerId }

        return (question: questionSelected?.text, answer: answerSelected?.description)
    }

    /// Resetea el test a su estado inicial
    func resetTest() {
        currentQuestionIndex = 0
        answers = [:]
        olfactiveProfile = nil
        unifiedProfile = nil
        errorMessage = nil
    }

    private func handleError(_ message: String) {
        errorMessage = IdentifiableString(value: message)
    }
}
