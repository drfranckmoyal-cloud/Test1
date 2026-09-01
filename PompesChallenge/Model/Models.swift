import Foundation

/// Un des trois rappels quotidiens.
struct Reminder: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var hour: Int
    var minute: Int
    /// Nombre de pompes visé sur ce créneau (recalculé si l'objectif change).
    var share: Int
    var isEnabled: Bool = true

    var timeLabel: String { String(format: "%02d : %02d", hour, minute) }

    static let defaults: [Reminder] = [
        Reminder(title: "Réveil musculaire", hour: 7, minute: 30, share: 30),
        Reminder(title: "Pause déjeuner", hour: 13, minute: 0, share: 35),
        Reminder(title: "Dernière ligne droite", hour: 20, minute: 30, share: 35)
    ]
}

/// Ton des messages de motivation.
enum MotivationTone: String, Codable, CaseIterable, Identifiable {
    case cash
    case coach
    case zen

    var id: String { rawValue }

    var label: String {
        switch self {
        case .cash: return "Cash"
        case .coach: return "Coach"
        case .zen: return "Zen"
        }
    }
}

/// État d'un jour du défi.
enum DayStatus: Equatable {
    case validated
    case missed
    case today
    case upcoming
}

/// Une case du calendrier.
struct DayCell: Identifiable, Equatable {
    let id: Int          // numéro du jour dans le défi, 1...30
    let date: Date
    let count: Int
    let status: DayStatus
    let progress: Double
}

/// Tout ce qui est persisté.
struct ChallengeState: Codable {
    var startDate: Date
    var dailyGoal: Int = 100
    var durationDays: Int = 30
    /// "yyyy-MM-dd" -> nombre de pompes
    var logs: [String: Int] = [:]
    var reminders: [Reminder] = Reminder.defaults
    var tone: MotivationTone = .cash
    /// Jours dont la célébration a déjà été affichée.
    var celebrated: Set<String> = []
}

/// Contenu de l'écran de célébration.
struct Celebration: Identifiable, Equatable {
    let id = UUID()
    let dayIndex: Int
    let count: Int
    let streak: Int
    let total: Int
    let durationDays: Int
}
