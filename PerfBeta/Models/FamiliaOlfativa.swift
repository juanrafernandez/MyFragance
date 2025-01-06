import SwiftUI
import SwiftData

@Model
struct FamiliaOlfativa: Identifiable, Hashable {
    @Attribute(.unique) var id: String
    var nombre: String
    var descripcion: String
    var notasClave: [String]
    var ingredientesAsociados: [String]
    var intensidadPromedio: String
    var estacionRecomendada: [String]
    var personalidadAsociada: [String]
    var ocasion: [String]
    var color: String

    // Propiedad computada para generar un gradiente
    var gradientColor: [Color] {
        let baseColor = Color(hex: color)
        return [
            baseColor.opacity(0.1),
            baseColor
        ]
    }

    // Inicializador explícito
    init(
        id: String = UUID().uuidString,
        nombre: String,
        descripcion: String,
        notasClave: [String],
        ingredientesAsociados: [String],
        intensidadPromedio: String,
        estacionRecomendada: [String],
        personalidadAsociada: [String],
        ocasion: [String],
        color: String
    ) {
        self.id = id
        self.nombre = nombre
        self.descripcion = descripcion
        self.notasClave = notasClave
        self.ingredientesAsociados = ingredientesAsociados
        self.intensidadPromedio = intensidadPromedio
        self.estacionRecomendada = estacionRecomendada
        self.personalidadAsociada = personalidadAsociada
        self.ocasion = ocasion
        self.color = color
    }

    // Inicializador adicional para manejar datos desde Firestore
    init?(from data: [String: Any]) {
        guard
            let id = data["id"] as? String,
            let nombre = data["nombre"] as? String,
            let descripcion = data["descripcion"] as? String,
            let notasClave = data["notasClave"] as? [String],
            let ingredientesAsociados = data["ingredientesAsociados"] as? [String],
            let intensidadPromedio = data["intensidadPromedio"] as? String,
            let estacionRecomendada = data["estacionRecomendada"] as? [String],
            let personalidadAsociada = data["personalidadAsociada"] as? [String],
            let ocasion = data["ocasion"] as? [String],
            let color = data["color"] as? String
        else {
            return nil
        }

        self.init(
            id: id,
            nombre: nombre,
            descripcion: descripcion,
            notasClave: notasClave,
            ingredientesAsociados: ingredientesAsociados,
            intensidadPromedio: intensidadPromedio,
            estacionRecomendada: estacionRecomendada,
            personalidadAsociada: personalidadAsociada,
            ocasion: ocasion,
            color: color
        )
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "nombre": nombre,
            "descripcion": descripcion,
            "notasClave": notasClave,
            "ingredientesAsociados": ingredientesAsociados,
            "intensidadPromedio": intensidadPromedio,
            "estacionRecomendada": estacionRecomendada,
            "personalidadAsociada": personalidadAsociada,
            "ocasion": ocasion,
            "color": color
        ]
    }
}
