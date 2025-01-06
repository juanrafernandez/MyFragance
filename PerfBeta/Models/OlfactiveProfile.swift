import SwiftUI
import SwiftData

@Model
struct OlfactiveProfile: Identifiable {
    @Attribute(.unique) var id: String = UUID().uuidString // ID único generado automáticamente
    var name: String // Nombre del perfil
    var genero: String // Género principal asociado
    var familia: FamiliaOlfativa // Familia olfativa principal asociada
    var complementaryFamilies: [FamiliaOlfativa] // Familias complementarias
    var descriptionProfile: String? // Descripción breve del perfil (opcional)
    var icon: String? // Icono representativo del perfil (opcional)
    var questionsAndAnswers: [QuestionAnswer]? // Preguntas y respuestas asociadas (opcional)

    // Inicializador para crear manualmente un perfil
    init(
        id: String = UUID().uuidString,
        name: String,
        genero: String,
        familia: FamiliaOlfativa,
        complementaryFamilies: [FamiliaOlfativa],
        descriptionProfile: String? = nil,
        icon: String? = nil,
        questionsAndAnswers: [QuestionAnswer]? = nil
    ) {
        self.id = id
        self.name = name
        self.genero = genero
        self.familia = familia
        self.complementaryFamilies = complementaryFamilies
        self.descriptionProfile = descriptionProfile
        self.icon = icon
        self.questionsAndAnswers = questionsAndAnswers
    }

    // Inicializador para manejar datos desde Firestore
    init?(from data: [String: Any]) {
        guard
            let id = data["id"] as? String,
            let name = data["name"] as? String,
            let genero = data["genero"] as? String,
            let perfumesArray = data["perfumes"] as? [[String: Any]],
            let familiaData = data["familia"] as? [String: Any],
            let complementaryFamiliesArray = data["complementaryFamilies"] as? [[String: Any]]
        else {
            return nil
        }

        self.id = id
        self.name = name
        self.genero = genero
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
        self.complementaryFamilies = complementaryFamiliesArray.compactMap { FamiliaOlfativa(from: $0) } // Mapear familias
        self.descriptionProfile = data["descriptionProfile"] as? String
        self.icon = data["icon"] as? String
        self.questionsAndAnswers = (data["questionsAndAnswers"] as? [[String: Any]])?.compactMap { QuestionAnswer(from: $0) }
    }
    
    // Método para convertir el perfil a un diccionario
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "name": name,
            "genero": genero,
            "familia": familia.toDictionary(),
            "complementaryFamilies": complementaryFamilies.map { $0.toDictionary() },
            "descriptionProfile": descriptionProfile ?? "",
            "icon": icon ?? "",
            "questionsAndAnswers": questionsAndAnswers?.map { $0.toDictionary() } ?? []
        ]
    }
    
    // Propiedad computada para descripción compacta
    var compactDescription: String {
        descriptionProfile ?? "Descripción no disponible"
    }
}
