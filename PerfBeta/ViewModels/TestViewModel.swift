import SwiftUI

class TestViewModel: ObservableObject {
    @Published var questions: [Question] = [] // Lista de preguntas cargadas
    @Published var currentQuestionIndex: Int = 0 // Índice de la pregunta actual
    @Published var answers: [String: Option] = [:] // Respuestas seleccionadas, asociadas al ID de cada pregunta

    private let dataService = QuestionService() // Servicio local para cargar las preguntas

    /// Pregunta actual basada en el índice
    var currentQuestion: Question {
        questions[currentQuestionIndex]
    }

    /// Progreso del test calculado como porcentaje
    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentQuestionIndex) / Double(questions.count)
    }

    init() {
        loadQuestions() // Cargar preguntas al inicializar
    }

    /// Cargar preguntas desde el archivo JSON
    func loadQuestions() {
        questions = dataService.getAllQuestions()
    }

    /// Seleccionar una respuesta para la pregunta actual
    func selectOption(_ option: Option) -> Bool {
        // Guardar la respuesta seleccionada asociada al ID de la pregunta actual
        answers[currentQuestion.id] = option

        // Comprobar si estamos en la última pregunta
        let isLastQuestion = currentQuestionIndex == questions.count - 1

        // Avanzar a la siguiente pregunta solo si no es la última
        if !isLastQuestion {
            currentQuestionIndex += 1
        }

        return isLastQuestion // Indica si se seleccionó una respuesta en la última pregunta
    }
}
