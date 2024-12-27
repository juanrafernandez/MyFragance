import Foundation

class GiftViewModel: ObservableObject {
    @Published var preguntasRelevantes: [Question] = []
    @Published var answers: [String: Option] = [:]
    @Published var currentQuestionIndex: Int = 0
    @Published var progress: Double = 0.0

    private var allQuestions: [Question] = []
    var currentQuestion: Question? {
            if currentQuestionIndex < preguntasRelevantes.count {
                return preguntasRelevantes[currentQuestionIndex]
            }
            return nil
        }
    
    init() {
        loadQuestions()
    }

    /// Cargar preguntas desde el JSON
    private func loadQuestions() {
        guard let url = Bundle.main.url(forResource: "gift_questions", withExtension: "json") else {
            print("No se encontró el archivo JSON")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let loadedQuestions = try JSONDecoder().decode([Question].self, from: data)
            self.allQuestions = loadedQuestions
            self.filtrarPreguntasRelevantes(nivelDetalle: 1) // Nivel inicial
        } catch {
            print("Error al cargar las preguntas: \(error)")
        }
    }

    /// Filtra preguntas relevantes según el nivel de detalle
    func filtrarPreguntasRelevantes(nivelDetalle: Int) {
        let categoriasObligatorias: [String] = ["Nivel de Conocimiento", "Edad", "Género del Destinatario", "Contexto del Regalo"]
        let categoriasNivel2: [String] = ["Personalidad"]
        
        preguntasRelevantes = allQuestions.filter { pregunta in
            if categoriasObligatorias.contains(pregunta.category) {
                return true
            } else if nivelDetalle >= 2 && categoriasNivel2.contains(pregunta.category) {
                return true
            }
            return false
        }
    }

    /// Maneja la selección de una opción
    func seleccionarOpcion(_ option: Option) -> Bool {
        let currentQuestion = preguntasRelevantes[currentQuestionIndex]
        answers[currentQuestion.id] = option

        // Si estamos en la primera pregunta, ajustar nivelDetalle
        if currentQuestion.category == "Nivel de Conocimiento", let nivelDetalle = option.nivelDetalle {
            filtrarPreguntasRelevantes(nivelDetalle: nivelDetalle)
            
            // Avanzar a la siguiente pregunta directamente
            currentQuestionIndex = 1
            progress = Double(currentQuestionIndex + 1) / Double(preguntasRelevantes.count)
            return false
        }

        // Verificar si hay más preguntas
        if currentQuestionIndex < preguntasRelevantes.count - 1 {
            currentQuestionIndex += 1
            progress = Double(currentQuestionIndex + 1) / Double(preguntasRelevantes.count)
            return false
        }

        // Es la última pregunta
        progress = 1.0
        return true
    }

    func restartTest() {
        currentQuestionIndex = 0
        answers.removeAll()
        progress = 0.0 // Reinicia la barra de progreso
    }

}
