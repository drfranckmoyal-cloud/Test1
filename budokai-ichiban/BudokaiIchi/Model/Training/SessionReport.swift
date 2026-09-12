import Foundation

// MARK: - Difficulté globale

/// L'effort perçu, exprimé sur l'échelle que voit l'utilisateur et traduit en
/// RPE de 1 à 10 pour le moteur.
enum PerceivedEffort: String, Codable, CaseIterable, Identifiable {
    case veryEasy, easy, wellDosed, hard, veryHard, maximum

    var id: String { rawValue }

    var label: String {
        switch self {
        case .veryEasy: return "Très facile"
        case .easy: return "Facile"
        case .wellDosed: return "Bien dosé"
        case .hard: return "Difficile"
        case .veryHard: return "Très difficile"
        case .maximum: return "Maximum"
        }
    }

    /// La valeur de RPE retenue pour le moteur.
    var rpe: Int {
        switch self {
        case .veryEasy: return 4
        case .easy: return 6
        case .wellDosed: return 7
        case .hard: return 8
        case .veryHard: return 9
        case .maximum: return 10
        }
    }

    var icon: String {
        switch self {
        case .veryEasy: return "arrow.up.right.circle.fill"
        case .easy: return "arrow.up.circle"
        case .wellDosed: return "checkmark.circle.fill"
        case .hard: return "arrow.down.circle"
        case .veryHard: return "arrow.down.right.circle.fill"
        case .maximum: return "flame.fill"
        }
    }
}

// MARK: - Séance terminée ?

enum CompletionStatus: String, Codable, CaseIterable, Identifiable {
    case entirely, partially, no
    var id: String { rawValue }

    var label: String {
        switch self {
        case .entirely: return "Entièrement"
        case .partially: return "Partiellement"
        case .no: return "Non"
        }
    }

    var isComplete: Bool { self == .entirely }
}

/// Pourquoi la séance n'a pas été menée à son terme. Demandé seulement si
/// elle est partielle ou abandonnée.
enum FailureReason: String, Codable, CaseIterable, Identifiable {
    case tooHard, technique, time, fatigue, other
    var id: String { rawValue }

    var label: String {
        switch self {
        case .tooHard: return "Trop difficile"
        case .technique: return "Problème technique"
        case .time: return "Manque de temps"
        case .fatigue: return "Fatigue générale"
        case .other: return "Autre"
        }
    }
}

// MARK: - Qualité d'exécution

enum TechnicalQuality: String, Codable, CaseIterable, Identifiable {
    case good, correct, degraded
    var id: String { rawValue }

    var label: String {
        switch self {
        case .good: return "Très bonne"
        case .correct: return "Correcte"
        case .degraded: return "Dégradée"
        }
    }
}

// MARK: - Le retour complet

/// Les trois informations demandées après une séance, pas une de plus.
/// Chacune reste facultative : l'utilisateur peut passer.
struct SessionReport: Codable, Equatable {
    var effort: PerceivedEffort?
    var completion: CompletionStatus?
    var failureReason: FailureReason?
    var quality: TechnicalQuality?
    var recordedAt: Date = Date()

    var isEmpty: Bool {
        effort == nil && completion == nil && quality == nil
    }

    /// Le RPE retenu, quand il a été donné.
    var rpe: Int? { effort?.rpe }
}
