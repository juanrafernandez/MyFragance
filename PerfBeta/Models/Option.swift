import SwiftData
import Foundation

@Model
struct Option: Identifiable {
    @Attribute(.unique) var id: String
    var label: String?
    var value: String
    var descriptionOption: String
    var imageAsset: String
    var familiasAsociadas: [String: Int]?
    var nivelDetalle: Int?

    // Inicializador para Firestore
    init?(data: [String: Any]) {
        guard
            let value = data["value"] as? String,
            let description = data["description"] as? String,
            let imageAsset = data["image_asset"] as? String
        else {
            return nil
        }
        
        self.id = UUID().uuidString
        self.label = data["label"] as? String
        self.value = value
        self.descriptionOption = descriptionOption
        self.imageAsset = imageAsset
        self.familiasAsociadas = data["familiasAsociadas"] as? [String: Int]
        self.nivelDetalle = data["nivel_detalle"] as? Int
    }
    
    // Inicializador para SwiftData
    init(
        id: String = UUID().uuidString,
        label: String?,
        value: String,
        description: String,
        imageAsset: String,
        familiasAsociadas: [String: Int]? = nil,
        nivelDetalle: Int? = nil
    ) {
        self.id = id
        self.label = label
        self.value = value
        self.descriptionOption = descriptionOption
        self.imageAsset = imageAsset
        self.familiasAsociadas = familiasAsociadas
        self.nivelDetalle = nivelDetalle
    }
}

@Model
class FamiliaAsociada: Identifiable {
    @Attribute(.unique) var id: String = UUID().uuidString
    var name: String
    var score: Int

    init(id: String = UUID().uuidString, name: String, score: Int) {
        self.id = id
        self.name = name
        self.score = score
    }
}
