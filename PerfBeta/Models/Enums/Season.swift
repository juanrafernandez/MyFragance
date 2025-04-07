import Foundation

enum Season: String, CaseIterable, Identifiable, SelectableOption {
    case spring = "spring"
    case summer = "summer"
    case autumn = "autumn"
    case winter = "winter"
    case allSeasons = "all"
    case none = "none"
    
    var id: Season { self }

    var displayName: String {
        return NSLocalizedString(self.rawValue, comment: "")
    }
    
    var description: String {
        switch self {
        case .spring:
            return NSLocalizedString("season.spring.description", comment: "Description for spring season")
        case .summer:
            return NSLocalizedString("season.summer.description", comment: "Description for summer season")
        case .autumn:
            return NSLocalizedString("season.autumn.description", comment: "Description for autumn season")
        case .winter:
            return NSLocalizedString("season.winter.description", comment: "Description for winter season")
        case .allSeasons:
            return NSLocalizedString("season.allSeasons.description", comment: "Description for all seasons")
        case .none:
            return NSLocalizedString("season.allSeasons.description", comment: "Description for all seasons")
        }
    }
    
    var imageName: String {
        switch self {
        case .spring:
            return "season_spring"
        case .summer:
            return "season_summer"
        case .autumn:
            return "season_autumn"
        case .winter:
            return "season_winter"
        case .allSeasons:
            return "season_all"
        case .none:
            return "season_none"
        }
    }
}
