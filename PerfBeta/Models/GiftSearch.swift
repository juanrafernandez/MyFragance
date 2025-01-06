import SwiftData
import SwiftUI

@Model
struct GiftSearch: Identifiable {
    @Attribute(.unique) var id: String = UUID().uuidString // ID único
    var name: String // Nombre de la búsqueda o regalo
    var perfumes: [Perfume] // Lista de perfumes asociados
    var familia: FamiliaOlfativa // Familia olfativa asociada
    var descriptionGift: String // Descripción breve
    var icon: String // Icono representativo
    var questionsAndAnswers: [QuestionAnswer] // Preguntas y respuestas asociadas

    // Inicializador manual para crear instancias
    init(
        id: String = UUID().uuidString,
        name: String,
        perfumes: [Perfume],
        familia: FamiliaOlfativa,
        descriptionGift: String,
        icon: String,
        questionsAndAnswers: [QuestionAnswer]
    ) {
        self.id = id
        self.name = name
        self.perfumes = perfumes
        self.familia = familia
        self.descriptionGift = descriptionGift
        self.icon = icon
        self.questionsAndAnswers = questionsAndAnswers
    }

    // Inicializador para datos desde Firestore
    init?(from data: [String: Any]) {
        guard
            let id = data["id"] as? String,
            let name = data["name"] as? String,
            let perfumesArray = data["perfumes"] as? [[String: Any]],
            let familiaData = data["familia"] as? [String: Any],
            let descriptionGift = data["descriptionGift"] as? String,
            let icon = data["icon"] as? String,
            let questionsAndAnswersArray = data["questionsAndAnswers"] as? [[String: Any]]
        else {
            return nil
        }

        self.id = id
        self.name = name
        self.perfumes = perfumesArray.compactMap { Perfume(from: $0) }
        self.familia = FamiliaOlfativa(from: familiaData) ?? FamiliaOlfativa(
            id: UUID().uuidString,
            nombre: "Desconocido",
            descripcion: "Información no disponible",
            notasClave: [],
            ingredientesAsociados: [],
            intensidadPromedio: "Media",
            estacionRecomendada: [],
            personalidadAsociada: [],
            ocasion: [],
            color: "#000000"
        )
        self.descriptionGift = descriptionGift
        self.icon = icon
        self.questionsAndAnswers = questionsAndAnswersArray.compactMap { QuestionAnswer(from: $0) }
    }
}
