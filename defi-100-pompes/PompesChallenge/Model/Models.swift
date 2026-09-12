import Foundation

/// Les exercices qu'un défi peut contenir.
enum ExerciseKind: String, Codable, CaseIterable, Identifiable {
    case pushups
    case pullups
    case abs

    var id: String { rawValue }

    var name: String {
        switch self {
        case .pushups: return "Pompes"
        case .pullups: return "Tractions"
        case .abs: return "Abdos"
        }
    }

    /// Utilisé au fil du texte : « plus que 37 pompes ».
    var unit: String {
        switch self {
        case .pushups: return "pompes"
        case .pullups: return "tractions"
        case .abs: return "abdos"
        }
    }

    var symbol: String {
        switch self {
        case .pushups: return "figure.strengthtraining.functional"
        case .pullups: return "figure.strengthtraining.traditional"
        case .abs: return "figure.core.training"
        }
    }

    var defaultGoal: Int {
        switch self {
        case .pushups: return 100
        case .pullups: return 20
        case .abs: return 150
        }
    }

    /// Boutons d'ajout rapide, calibrés par exercice.
    var quickAdds: [Int] {
        switch self {
        case .pushups: return [5, 10, 20]
        case .pullups: return [1, 2, 5]
        case .abs: return [10, 20, 30]
        }
    }

    /// Pas du réglage d'objectif.
    var goalStep: Int {
        switch self {
        case .pushups: return 10
        case .pullups: return 1
        case .abs: return 10
        }
    }

    var maxGoal: Int {
        switch self {
        case .pushups: return 500
        case .pullups: return 100
        case .abs: return 600
        }
    }
}

/// Un exercice du défi, avec son objectif quotidien.
/// Un même exercice ne peut apparaître qu'une fois : sa nature sert d'identité.
struct Exercise: Identifiable, Codable, Equatable {
    var kind: ExerciseKind
    var dailyGoal: Int

    var id: ExerciseKind { kind }
    var name: String { kind.name }
}

/// Un des rappels quotidiens. `weight` est la part de l'objectif de chaque
/// exercice à réaliser sur ce créneau (0,30 = 30 %).
struct Reminder: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var hour: Int
    var minute: Int
    var weight: Double
    var isEnabled: Bool = true

    var timeLabel: String { String(format: "%02d : %02d", hour, minute) }

    static let defaults: [Reminder] = [
        Reminder(title: "Réveil musculaire", hour: 7, minute: 30, weight: 0.30),
        Reminder(title: "Pause déjeuner", hour: 13, minute: 0, weight: 0.35),
        Reminder(title: "Dernière ligne droite", hour: 20, minute: 30, weight: 0.35)
    ]
}

/// Ton des messages de motivation.
enum MotivationTone: String, Codable, CaseIterable, Identifiable {
    case cash
    case coach
    case zen
    case absurd

    var id: String { rawValue }

    var label: String {
        switch self {
        case .cash: return "Cash"
        case .coach: return "Coach"
        case .zen: return "Zen"
        case .absurd: return "Absurde"
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
    let id: Int          // numéro du jour dans le défi, 1...n
    let date: Date
    let totalReps: Int
    let status: DayStatus
    let progress: Double
}

/// Tout ce qui est persisté.
struct ChallengeState: Codable {
    var startDate: Date
    var durationDays: Int = 30
    var exercises: [Exercise] = [Exercise(kind: .pushups, dailyGoal: 100)]
    /// "yyyy-MM-dd" -> exercice -> répétitions
    var logs: [String: [String: Int]] = [:]
    var reminders: [Reminder] = Reminder.defaults
    var tone: MotivationTone = .cash
    var appearance: Appearance = .light
    /// Jours dont la célébration a déjà été affichée.
    var celebrated: Set<String> = []
}

/// Contenu de l'écran de célébration.
struct Celebration: Identifiable, Equatable {
    let id = UUID()
    let dayIndex: Int
    let durationDays: Int
    let streak: Int
    let total: Int
    /// « 100 pompes », « 20 tractions »…
    let summary: [String]
}
