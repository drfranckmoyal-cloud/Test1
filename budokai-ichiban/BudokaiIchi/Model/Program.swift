import SwiftUI

// MARK: - Caractéristiques

enum StatKind: String, Codable, CaseIterable, Identifiable {
    case force, vitesse, endurance
    var id: String { rawValue }
    var label: String {
        switch self {
        case .force: return "Force"
        case .vitesse: return "Vitesse"
        case .endurance: return "Endurance"
        }
    }
}

// MARK: - Rangs

enum Rank: Int, Codable, CaseIterable, Comparable, Identifiable {
    case e = 0, d, c, b, a, s, sPlus

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .e: return "E"
        case .d: return "D"
        case .c: return "C"
        case .b: return "B"
        case .a: return "A"
        case .s: return "S"
        case .sPlus: return "S+"
        }
    }

    /// Niveau à partir duquel le rang est acquis.
    var levelThreshold: Int {
        switch self {
        case .e: return 1
        case .d: return 5
        case .c: return 10
        case .b: return 18
        case .a: return 28
        case .s: return 41
        case .sPlus: return 61
        }
    }

    static func < (lhs: Rank, rhs: Rank) -> Bool { lhs.rawValue < rhs.rawValue }

    static func forLevel(_ level: Int) -> Rank {
        var result = Rank.e
        for rank in Rank.allCases where level >= rank.levelThreshold {
            result = rank
        }
        return result
    }
}

// MARK: - Palier de calibrage

enum Tier: String, Codable, CaseIterable, Identifiable {
    case novice, confirme, classeS
    var id: String { rawValue }
    var label: String {
        switch self {
        case .novice: return "Novice"
        case .confirme: return "Confirmé"
        case .classeS: return "Classe S"
        }
    }
    /// Multiplie les charges du programme.
    var load: Double {
        switch self {
        case .novice: return 0.7
        case .confirme: return 1.0
        case .classeS: return 1.3
        }
    }
    /// Multiplie l'expérience gagnée.
    var xpFactor: Double {
        switch self {
        case .novice: return 1.0
        case .confirme: return 1.5
        case .classeS: return 2.0
        }
    }
}

// MARK: - Une étape de séance

struct Goal: Codable, Equatable {
    enum Unit: String, Codable { case reps, seconds, meters }
    var unit: Unit
    var value: Int

    var short: String {
        switch unit {
        case .reps: return "\(value)"
        case .seconds: return value >= 60 ? "\(value / 60) min" : "\(value) s"
        case .meters: return value >= 1000
            ? String(format: "%.1f km", Double(value) / 1000).replacingOccurrences(of: ".", with: ",")
            : "\(value) m"
        }
    }

    var unitLabel: String {
        switch unit {
        case .reps: return "répétitions"
        case .seconds: return "secondes"
        case .meters: return "mètres"
        }
    }
}

struct SessionStep: Identifiable, Equatable {
    var id: Int
    var name: String
    var detail: String
    var goal: Goal
    var restSeconds: Int
    var stat: StatKind

    /// Faux pour l'échauffement et le retour au calme, qui ne se durcissent
    /// pas avec le reste.
    var isWork: Bool {
        let soft = ["échauffement", "retour au calme", "marche", "récupération"]
        let lowered = name.lowercased()
        return !soft.contains { lowered.contains($0) }
    }
}

struct PlannedSession: Identifiable, Equatable {
    var id: String
    var programID: ProgramID
    var index: Int          // numéro de séance dans le programme, à partir de 1
    var stageIndex: Int     // étape à laquelle elle appartient, à partir de 0
    var title: String
    var steps: [SessionStep]
    /// La prescription complète, quand le programme sait l'exprimer.
    ///
    /// Les anciens programmes ne portent que des `steps` : une quantité et un
    /// repos. Saitama, lui, prescrit des variantes, des RIR, des politiques de
    /// complétion — ce que `SessionStep` ne sait pas dire. Quand ce champ est
    /// rempli, c'est lui qui fait foi.
    var prescribed: [ExercisePrescription]?
    /// Le rôle de la séance dans le calendrier, quand il est connu.
    var scheduling: SessionSchedulingMetadata?
    /// Le récit attaché à cette séance.
    var narrativeId: String?

    var totalReps: Int {
        if let prescribed = prescribed {
            return prescribed.reduce(0) { $0 + ($1.unit == .reps ? $1.targetValue : 0) }
        }
        return steps.reduce(0) { $0 + ($1.goal.unit == .reps ? $1.goal.value : 0) }
    }

    /// La même séance, allégée ou durcie par le curseur d'intensité.
    /// L'échauffement et le retour au calme n'en dépendent pas : ils durent
    /// ce qu'ils durent, quelle que soit la forme du jour.
    func scaled(by intensity: Double) -> PlannedSession {
        // une séance prescrite porte déjà son dosage : le curseur global n'a
        // plus rien à y faire
        if prescribed != nil { return self }
        var copy = self
        copy.steps = steps.map { step in
            guard step.isWork else { return step }
            var changed = step
            let raw = Double(step.goal.value) * intensity
            switch step.goal.unit {
            case .reps: changed.goal.value = max(1, Int(raw.rounded()))
            case .seconds: changed.goal.value = max(5, Int((raw / 5).rounded()) * 5)
            case .meters: changed.goal.value = max(50, Int((raw / 50).rounded()) * 50)
            }
            return changed
        }
        return copy
    }

    var estimatedMinutes: Int {
        if let scheduling = scheduling { return scheduling.estimatedDurationMinutes }
        if let prescribed = prescribed {
            let work = prescribed.reduce(0) { partial, item in
                switch item.unit {
                case .reps: return partial + item.targetValue * 3
                case .seconds: return partial + item.targetValue
                case .meters: return partial + item.targetValue / 3
                case .kg, .centimeters, .degrees, .centiseconds: return partial
                }
            }
            let rest = prescribed.reduce(0) { $0 + (($1.restSeconds ?? 0) * max(0, ($1.sets ?? 1) - 1)) }
            return max(1, (work + rest) / 60)
        }
        let work = steps.reduce(0) { partial, step in
            switch step.goal.unit {
            case .reps: return partial + step.goal.value * 2
            case .seconds: return partial + step.goal.value
            case .meters: return partial + step.goal.value / 3
            }
        }
        let rest = steps.reduce(0) { $0 + $1.restSeconds }
        return max(1, (work + rest) / 60)
    }
}

// MARK: - Programmes

enum ProgramID: String, Codable, CaseIterable, Identifiable {
    case saitama, naruto, rocklee, kenshiro, ichigo, minato, levi, luffy, goku
    var id: String { rawValue }
}

enum Unlock: Equatable {
    case open
    case stat(StatKind, Int)
    case rank(Rank)

    var label: String {
        switch self {
        case .open: return "Ouvert"
        case .stat(let kind, let value): return "\(kind.label) \(value) requis"
        case .rank(let rank): return "Rang \(rank.label) requis"
        }
    }
}

struct Program: Identifiable, Equatable {
    var id: ProgramID
    var name: String
    var family: String
    var pitch: String
    var stages: [String]
    /// Nombre de séances par étape ; la somme donne la longueur du programme.
    var sessionsPerStage: [Int]
    var rhythm: String
    var equipment: String
    var darkColor: UInt32
    var lightColor: UInt32
    var unlock: Unlock
    /// Faux tant que le contenu sportif n'est pas écrit.
    var playable: Bool

    var totalSessions: Int { sessionsPerStage.reduce(0, +) }

    /// Jours de repos entre deux séances. Zéro pour les programmes quotidiens.
    var restDays: Int { (id == .saitama || id == .luffy || id == .ichigo) ? 0 : 1 }
    var dark: Color { Color(hex: darkColor) }
    var light: Color { Color(hex: lightColor) }

    var gradient: LinearGradient {
        LinearGradient(colors: [light, dark], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// Index de l'étape à laquelle appartient une séance donnée.
    func stageIndex(forSession session: Int) -> Int {
        var remaining = session
        for (index, count) in sessionsPerStage.enumerated() {
            if remaining < count { return index }
            remaining -= count
        }
        return max(sessionsPerStage.count - 1, 0)
    }

    /// Première séance d'une étape, en numérotation à partir de zéro.
    func firstSession(ofStage stage: Int) -> Int {
        sessionsPerStage.prefix(max(0, stage)).reduce(0, +)
    }

    static func == (lhs: Program, rhs: Program) -> Bool { lhs.id == rhs.id }
}
