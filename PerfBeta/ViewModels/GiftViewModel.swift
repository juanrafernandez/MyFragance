import SwiftData
import FirebaseFirestore
import SwiftUI

class GiftViewModel: ObservableObject {
    @Published var preguntasRelevantes: [Question] = []
    @Published var answers: [String: Option] = [:]
    @Published var currentQuestionIndex: Int = 0
    @Published var progress: Double = 0.0

    private var allQuestions: [Question] = []
    private let modelContext: ModelContext
    private var listener: ListenerRegistration?

    var currentQuestion: Question? {
        if currentQuestionIndex < preguntasRelevantes.count {
            return preguntasRelevantes[currentQuestionIndex]
        }
        return nil
    }

    init(context: ModelContext) {
        self.modelContext = context
        fetchQuestionsFromFirestore()
    }

    /// Escucha cambios en Firestore y sincroniza con SwiftData
    private func fetchQuestionsFromFirestore() {
        let db = Firestore.firestore()
        listener = db.collection("gift_questions").addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                print("Error al escuchar cambios en Firestore: \(error.localizedDescription)")
                return
            }

            guard let documents = snapshot?.documents else { return }

            // Mapear preguntas desde Firestore
            let fetchedQuestions = documents.compactMap { doc -> Question? in
                let data = doc.data() // Ya es [String: Any], no es necesario un cast
                return Question(from: data) // Asegúrate de que este inicializador sea correcto
            }

            // Guardar en SwiftData y actualizar en memoria
            self.updateLocalCache(with: fetchedQuestions)
        }
    }

    /// Actualiza el caché local en SwiftData
    private func updateLocalCache(with questions: [Question]) {
        for question in questions {
            let fetchDescriptor = FetchDescriptor<Question>(
                predicate: #Predicate { $0.id == question.id }
            )

            do {
                if try modelContext.fetch(fetchDescriptor).isEmpty {
                    modelContext.insert(question)
                }
            } catch {
                print("Error al actualizar el caché de preguntas: \(error.localizedDescription)")
            }
        }

        do {
            try modelContext.save()
            loadQuestionsFromSwiftData()
        } catch {
            print("Error al guardar en SwiftData: \(error.localizedDescription)")
        }
    }

    /// Carga preguntas desde SwiftData
    private func loadQuestionsFromSwiftData() {
        let fetchDescriptor = FetchDescriptor<Question>()

        do {
            allQuestions = try modelContext.fetch(fetchDescriptor)
            filtrarPreguntasRelevantes(nivelDetalle: 1) // Nivel inicial
        } catch {
            print("Error al cargar preguntas desde SwiftData: \(error.localizedDescription)")
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
        guard let currentQuestion = currentQuestion else { return false }
        answers[currentQuestion.id] = option

        if currentQuestion.category == "Nivel de Conocimiento", let nivelDetalle = option.nivelDetalle {
            filtrarPreguntasRelevantes(nivelDetalle: nivelDetalle)

            currentQuestionIndex = 1
            progress = Double(currentQuestionIndex + 1) / Double(preguntasRelevantes.count)
            return false
        }

        if currentQuestionIndex < preguntasRelevantes.count - 1 {
            currentQuestionIndex += 1
            progress = Double(currentQuestionIndex + 1) / Double(preguntasRelevantes.count)
            return false
        }

        progress = 1.0
        return true
    }

    /// Reinicia el proceso de búsqueda
    func restartTest() {
        currentQuestionIndex = 0
        answers.removeAll()
        progress = 0.0
    }

    /// Detiene la escucha de Firestore
    func stopListening() {
        listener?.remove()
    }
}
