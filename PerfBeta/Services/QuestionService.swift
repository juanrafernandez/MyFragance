import Foundation

class QuestionService {
    func loadQuestions() -> [Question] {
        guard let url = Bundle.main.url(forResource: "questions", withExtension: "json") else {
            print("Error: No se encontró el archivo questions.json")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let questions = try JSONDecoder().decode([Question].self, from: data)
            print("Preguntas cargadas exitosamente: \(questions)")
            return questions
        } catch {
            print("Error al cargar las preguntas: \(error)")
            return []
        }
    }
}
