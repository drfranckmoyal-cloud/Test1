import Foundation

/// Ton des messages.
enum MotivationTone: String, Codable, CaseIterable, Identifiable {
    case cash, coach, zen, absurd
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

/// Un rappel quotidien.
struct Reminder: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var hour: Int
    var minute: Int
    var isEnabled: Bool = true

    var timeLabel: String { String(format: "%02d : %02d", hour, minute) }

    static let defaults: [Reminder] = [
        Reminder(title: "L'entraînement du matin", hour: 7, minute: 30),
        Reminder(title: "Pense à ta séance", hour: 13, minute: 0),
        Reminder(title: "Dernière ligne droite", hour: 20, minute: 30)
    ]
}

/// Une séance terminée. C'est l'unité d'historique : tout le reste s'en déduit.
struct SessionRecord: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var programID: String
    var sessionIndex: Int
    var stageIndex: Int
    var day: String          // "yyyy-MM-dd"
    var xp: Int
    var reps: Int
    var seconds: Int
    var meters: Int
}

/// Avancement dans un programme.
struct ProgramProgress: Codable, Equatable {
    var completedSessions: Int = 0
    var startedOn: String?
    var finishedOn: String?
}

/// Une tâche de la quête de pénalité.
struct PenaltyTask: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var target: Int
    var done: Int = 0
    var isComplete: Bool { done >= target }
}

/// La quête qui sauve la série après une séance manquée.
struct PenaltyQuest: Codable, Equatable {
    var issuedDay: String
    var dueDay: String
    var tasks: [PenaltyTask]
    var accepted: Bool = false

    var isComplete: Bool { tasks.allSatisfy { $0.isComplete } }
    var progress: Double {
        guard !tasks.isEmpty else { return 0 }
        let total = tasks.reduce(0.0) { partial, task in
            partial + (task.target > 0 ? min(1.0, Double(task.done) / Double(task.target)) : 1)
        }
        return total / Double(tasks.count)
    }
}

/// Tout ce qui est conservé d'une ouverture à l'autre.
struct PlayerState: Codable {
    var xp: Int = 0
    var stats: [String: Int] = [:]
    var tier: Tier = .novice
    var programs: [String: ProgramProgress] = [:]
    var activeProgram: String?
    var history: [SessionRecord] = []
    var streak: Int = 0
    var bestStreak: Int = 0
    var lastCompletedDay: String?
    var penalty: PenaltyQuest?
    var badges: [String] = []
    var equipment: [String] = []
    var appearance: Appearance = .dark
    var tone: MotivationTone = .absurd
    var reminders: [Reminder] = Reminder.defaults
    var onboarded: Bool = false

    func stat(_ kind: StatKind) -> Int { stats[kind.rawValue] ?? 0 }
    func progress(_ id: ProgramID) -> ProgramProgress { programs[id.rawValue] ?? ProgramProgress() }
}
