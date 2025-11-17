import Foundation
import FirebaseFirestore
import Combine

protocol TestServiceProtocol {
    func fetchQuestions(type: QuestionType) async throws -> [Question]
    func listenToQuestionsChanges(type: QuestionType) -> AnyPublisher<[Question], Error>
}

class TestService: TestServiceProtocol {
    private let db: Firestore
    private let languageProvider: LanguageProvider
    private var listener: ListenerRegistration?
    private let questionParser: QuestionParserProtocol

    init(
        firestore: Firestore = Firestore.firestore(),
        languageProvider: LanguageProvider = AppState.shared,
        questionParser: QuestionParserProtocol = QuestionParser()
    ) {
        self.db = firestore
        self.languageProvider = languageProvider
        self.questionParser = questionParser
    }

    /// Computed property to access current language
    private var language: String {
        languageProvider.language
    }
    
    // MARK: - Obtener Preguntas desde Firestore
    func fetchQuestions(type: QuestionType = .perfilOlfativo) async throws -> [Question] {
        let collectionPath = "questions_\(language)"

        #if DEBUG
        print("🔍 [TestService] Buscando preguntas en: \(collectionPath)")
        print("   Filtro: questionType == '\(type.rawValue)'")
        #endif

        // Forzar a ir al servidor (ignorar caché local)
        let snapshot = try await db.collection(collectionPath)
            .whereField("questionType", isEqualTo: type.rawValue)
            .getDocuments(source: .server)

        #if DEBUG
        print("   Documentos encontrados: \(snapshot.documents.count)")

        // Mostrar primeros documentos y detectar duplicados
        print("   Primeros documentos:")
        for (index, doc) in snapshot.documents.prefix(5).enumerated() {
            let docID = doc.documentID
            let key = doc.data()["key"] as? String ?? "sin key"
            let order = doc.data()["order"] as? Int ?? -999
            print("     [\(index)] ID:\(docID) | key:\(key) | order:\(order)")
        }

        // Detectar duplicados por key
        var keyCount: [String: Int] = [:]
        var duplicateKeys: [String: [String]] = [:]
        for doc in snapshot.documents {
            let key = doc.data()["key"] as? String ?? "sin key"
            keyCount[key, default: 0] += 1
            duplicateKeys[key, default: []].append(doc.documentID)
        }

        let hasDuplicates = keyCount.values.contains(where: { $0 > 1 })
        if hasDuplicates {
            print("   ⚠️ DUPLICADOS DETECTADOS:")
            for (key, count) in keyCount.sorted(by: { $0.value > $1.value }) where count > 1 {
                print("     - '\(key)': \(count) copias")
                print("       IDs: \(duplicateKeys[key]?.joined(separator: ", ") ?? "")")
            }
        }

        // Verificar si existe profile_00_classification
        let hasClassificationByKey = snapshot.documents.contains { doc in
            (doc.data()["key"] as? String) == "profile_00_classification"
        }
        let hasClassificationByID = snapshot.documents.contains { doc in
            doc.documentID == "profile_00_classification"
        }

        print("   ¿Existe profile_00_classification?")
        print("     - Por campo 'key': \(hasClassificationByKey ? "✅ SÍ" : "❌ NO")")
        print("     - Por document ID: \(hasClassificationByID ? "✅ SÍ" : "❌ NO")")

        if hasClassificationByID && !hasClassificationByKey {
            // Documento existe pero el campo key es diferente
            if let doc = snapshot.documents.first(where: { $0.documentID == "profile_00_classification" }) {
                let actualKey = doc.data()["key"] as? String ?? "null"
                print("   ⚠️ PROBLEMA: Document ID es 'profile_00_classification' pero campo key es '\(actualKey)'")
            }
        }

        if !hasClassificationByKey && !hasClassificationByID {
            // Buscar si existe con cualquier questionType
            let allSnapshot = try? await db.collection(collectionPath)
                .limit(to: 5)
                .getDocuments()

            print("   📋 Primeros 5 documentos en la colección:")
            allSnapshot?.documents.prefix(5).forEach { doc in
                let key = doc.data()["key"] as? String ?? "sin key"
                let qType = doc.data()["questionType"] as? String ?? "sin tipo"
                let order = doc.data()["order"] as? Int ?? -999
                print("     ID:\(doc.documentID) | key:\(key) | type:\(qType) | order:\(order)")
            }
        }
        #endif

        // Ordenar en memoria en lugar de en Firestore (evita necesidad de índice compuesto)
        let questions = snapshot.documents.compactMap { questionParser.parseQuestion(from: $0) }
        return questions.sorted { $0.order < $1.order }
    }

    // MARK: - Escuchar Cambios en Tiempo Real
    func listenToQuestionsChanges(type: QuestionType = .perfilOlfativo) -> AnyPublisher<[Question], Error> {
        let subject = PassthroughSubject<[Question], Error>()

        let collectionPath = "questions_\(language)"
        let collectionRef = db.collection(collectionPath)
            .whereField("questionType", isEqualTo: type.rawValue)

        listener = collectionRef.addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                subject.send(completion: .failure(error))
                return
            }

            guard let documents = snapshot?.documents else {
                subject.send([])
                return
            }

            // Ordenar en memoria en lugar de en Firestore (evita necesidad de índice compuesto)
            let questions = documents.compactMap { self?.questionParser.parseQuestion(from: $0) }
            let sortedQuestions = questions.sorted { $0.order < $1.order }
            subject.send(sortedQuestions)
        }

        // Asegúrate de cancelar la escucha cuando el publisher termine
        return subject.handleEvents(receiveCancel: { [weak self] in
            self?.listener?.remove()
        }).eraseToAnyPublisher()
    }
}
