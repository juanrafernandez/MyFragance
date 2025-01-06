import Foundation
import FirebaseFirestore

class QuestionService: ObservableObject {
    private var db = Firestore.firestore()
    @Published var preguntas: [Question] = []
    private var options: [String: Option] = [:]

    init() {
        fetchPreguntas() // Carga inicial de preguntas
        listenToPreguntas() // Escucha en tiempo real los cambios
    }

    /// Obtiene todas las preguntas desde Firestore
    func fetchPreguntas() {
        db.collection("preguntas").getDocuments { [weak self] (snapshot, error) in
            if let error = error {
                print("Error al obtener preguntas: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }
            
            self?.preguntas = documents.compactMap { doc -> Question? in
                Question(from: doc.data()) // Inicializador personalizado desde Firestore
            }
            
            self?.cacheOptions()
        }
    }

    /// Escucha en tiempo real los cambios en la colección `preguntas`
    func listenToPreguntas() {
        db.collection("preguntas").addSnapshotListener { [weak self] (snapshot, error) in
            if let error = error {
                print("Error al escuchar cambios en preguntas: \(error.localizedDescription)")
                return
            }
            
            guard let documents = snapshot?.documents else { return }

            self?.preguntas = documents.compactMap { doc -> Question? in
                Question(from: doc.data()) // Inicializador personalizado desde Firestore
            }
            
            self?.cacheOptions()
        }
    }

    /// Construye un diccionario para búsqueda rápida de opciones
    private func cacheOptions() {
        options.removeAll() // Limpia el cache previo
        for question in preguntas {
            for option in question.options {
                options[option.value] = option
            }
        }
    }

    /// Obtiene todas las preguntas
    func getAllQuestions() -> [Question] {
        return preguntas
    }
    
    /// Encuentra el texto de una pregunta por su ID
    func findQuestionText(by id: String) -> String? {
        preguntas.first(where: { $0.id == id })?.text
    }

    /// Encuentra el texto de una opción por su ID
    func findAnswerText(by id: String) -> String? {
        options[id]?.label
    }
}
