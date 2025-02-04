import Foundation

enum Country: String, CaseIterable, Identifiable {
    case usa = "usa"
    case spain = "spain"
    case france = "france"
    case germany = "germany"
    case italy = "italy"
    case uk = "uk"
    case canada = "canada"
    case australia = "australia"
    case india = "india"
    case japan = "japan"
    case china = "china"
    case mexico = "mexico"
    case brazil = "brazil"
    case argentina = "argentina"
    case southKorea = "south_korea"
    case southAfrica = "south_africa"
    case russia = "russia"
    case saudiArabia = "saudi_arabia"
    case uae = "uae"
    case egypt = "egypt"
    case nigeria = "nigeria"
    case singapore = "singapore"
    case newZealand = "new_zealand"
    case sweden = "sweden"
    case norway = "norway"
    case denmark = "denmark"
    case switzerland = "switzerland"
    case portugal = "portugal"
    case netherlands = "netherlands"
    case belgium = "belgium"
    case greece = "greece"
    case turkey = "turkey"

    var id: String { rawValue }

    /// Retorna el nombre traducido desde el archivo Localizable.strings
    var displayName: String {
        return NSLocalizedString(self.rawValue, comment: "")
    }
}
