import Foundation

enum Occasion: String, CaseIterable, Identifiable {
    case sunnyDays = "sunny_days"
    case office = "office"
    case socialEvents = "social_events"
    case dates = "dates"
    case parties = "parties"
    case dailyUse = "daily_use"
    case formalMeetings = "formal_meetings"
    case nights = "nights"
    case nightDates = "night_dates"
    case sports = "sports"
    case natureWalks = "nature_walks"
    case beachDays = "beach_days"
    case winter = "winter"

    var id: String { rawValue }

    /// Nombre traducido de la ocasión
    var displayName: String {
        NSLocalizedString("occasion.\(rawValue).name", comment: "Display name for occasion: \(rawValue)")
    }

    /// Descripción traducida de la ocasión
    var description: String {
        NSLocalizedString("occasion.\(rawValue).description", comment: "Description for occasion: \(rawValue)")
    }
}
