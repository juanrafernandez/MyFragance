import Foundation

enum Occasion: String, CaseIterable, Identifiable, SelectableOption {
    case sundays = "sunny_days"
    case office = "office"
    case socialEvents = "social_events"
    case dates = "dates"
    case parties = "parties"
    case dailyUse = "daily_use"
    case formalMeetings = "formal_meetings"
    case nights = "nights"
    case sports = "sports"
    case natureWalks = "nature_walks"
    case beachDays = "beach_days"
    
    var id: Occasion { self }

    /// Nombre traducido de la ocasión
    var displayName: String {
        NSLocalizedString("occasion.\(rawValue).name", comment: "Display name for occasion: \(rawValue)")
    }

    /// Descripción traducida de la ocasión
    var description: String {
        NSLocalizedString("occasion.\(rawValue).description", comment: "Description for occasion: \(rawValue)")
    }
    
    var imageName: String {
        switch self {
        case .sundays:
            return "occasion_sunny_days"
        case .office:
            return "occasion_office"
        case .socialEvents:
            return "occasion_social_events"
        case .dates:
            return "occasion_dates"
        case .parties:
            return "occasion_parties"
        case .dailyUse:
            return "occasion_daily_use"
        case .formalMeetings:
            return "occasion_formal_meetings"
        case .nights:
            return "occasion_nights"
        case .sports:
            return "occasion_sports"
        case .natureWalks:
            return "occasion_nature_walks"
        case .beachDays:
            return "occasion_beach_days"
        }
    }
}
