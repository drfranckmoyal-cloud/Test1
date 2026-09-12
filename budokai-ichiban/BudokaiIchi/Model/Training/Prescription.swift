import Foundation

// MARK: - Politique de complétion

/// Comment un objectif doit être accompli. C'est une information
/// **physiologique**, pas un confort d'interface : 60 répétitions réparties
/// sur douze heures n'ont pas l'effet de 60 répétitions en une séance, et dix
/// kilomètres en trois fois ne valent pas dix kilomètres d'affilée.
enum CompletionPolicy: String, Codable, CaseIterable, Identifiable {
    /// En une seule fois. Les fragments ne s'additionnent pas.
    case continuous
    /// Dans une même séance, séries et repos compris.
    case structuredSession
    /// Librement réparti sur la journée.
    case dayCumulative

    var id: String { rawValue }

    var label: String {
        switch self {
        case .continuous: return "En une seule fois"
        case .structuredSession: return "En séance"
        case .dayCumulative: return "Dans la journée"
        }
    }

    /// Ce qu'on dit à l'utilisateur, en clair.
    var instruction: String {
        switch self {
        case .continuous: return "À réaliser en une seule sortie."
        case .structuredSession: return "À réaliser dans la même séance, avec les temps de repos."
        case .dayCumulative: return "À répartir comme tu veux dans la journée."
        }
    }

    /// Vrai quand plusieurs contributions s'additionnent pour valider.
    var acceptsFragments: Bool { self == .dayCumulative }
}

// MARK: - Qualité travaillée

/// Les qualités physiques que le moteur sait distinguer.
///
/// Les trois premières existaient déjà sous le nom `StatKind` ; les trois
/// suivantes sont nouvelles. La correspondance est assurée dans les deux sens
/// pour que rien de l'ancien modèle ne se perde.
enum TrainingCharacteristic: String, Codable, CaseIterable, Identifiable {
    case force, speed, endurance, mobility, power, control

    var id: String { rawValue }

    var label: String {
        switch self {
        case .force: return "Force"
        case .speed: return "Vitesse"
        case .endurance: return "Endurance"
        case .mobility: return "Mobilité"
        case .power: return "Explosivité"
        case .control: return "Contrôle"
        }
    }

    /// La caractéristique héritée qui compte les points, pour les trois
    /// nouvelles qualités qui n'en ont pas encore.
    var legacy: StatKind {
        switch self {
        case .force, .control: return .force
        case .speed, .power: return .vitesse
        case .endurance, .mobility: return .endurance
        }
    }

    init(_ legacy: StatKind) {
        switch legacy {
        case .force: self = .force
        case .vitesse: self = .speed
        case .endurance: self = .endurance
        }
    }
}

// MARK: - Unité d'objectif

/// Les unités de prescription. `kg` est nouvelle : elle porte la charge
/// externe, que l'ancien modèle ne savait pas exprimer.
enum ObjectiveUnit: String, Codable, CaseIterable, Identifiable {
    case reps, seconds, meters, kg

    var id: String { rawValue }

    /// L'unité héritée correspondante, quand elle existe.
    var legacy: Goal.Unit? {
        switch self {
        case .reps: return .reps
        case .seconds: return .seconds
        case .meters: return .meters
        case .kg: return nil
        }
    }

    init(_ legacy: Goal.Unit) {
        switch legacy {
        case .reps: self = .reps
        case .seconds: self = .seconds
        case .meters: self = .meters
        }
    }

    /// « 60 répétitions », « 2,4 km », « 45 s », « 12 kg ».
    func format(_ value: Int) -> String {
        switch self {
        case .reps:
            return "\(value) répétition\(value > 1 ? "s" : "")"
        case .seconds:
            if value >= 60 && value % 60 == 0 { return "\(value / 60) min" }
            if value >= 60 { return "\(value / 60) min \(value % 60) s" }
            return "\(value) s"
        case .meters:
            guard value >= 1000 else { return "\(value) m" }
            let km = Double(value) / 1000
            return String(format: "%.1f km", km).replacingOccurrences(of: ".", with: ",")
        case .kg:
            return "\(value) kg"
        }
    }

    /// Forme courte, pour les listes serrées.
    func short(_ value: Int) -> String {
        self == .reps ? "\(value)" : format(value)
    }
}

// MARK: - La prescription d'un exercice

/// Ce que le moteur prescrit pour un mouvement donné, un jour donné.
///
/// Remplace à terme `SessionStep`, qui ne portait qu'un nom, une quantité et
/// un repos. Ici volume, intensité, variante, récupération et charge sont
/// **des variables séparées** : c'est ce qui permet d'en faire progresser une
/// sans toucher aux autres.
struct ExercisePrescription: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    /// Le mouvement dans la bibliothèque, si le mouvement y figure.
    var exerciseId: String?

    var name: String
    var detail: String?

    // — volume
    var targetValue: Int
    var unit: ObjectiveUnit
    var sets: Int?
    var targetPerSet: Int?

    // — récupération
    var restSeconds: Int?

    // — qualité travaillée
    var characteristic: TrainingCharacteristic

    // — intensité, séparée du volume
    /// Effort perçu visé, de 1 à 10.
    var targetRPE: Int?
    /// Répétitions gardées en réserve.
    var targetRIR: Int?
    /// Notation de tempo, par exemple « 3-1-1-0 ».
    var tempo: String?

    var completionPolicy: CompletionPolicy = .structuredSession

    // — difficulté technique
    /// Rang du mouvement dans sa famille de progression.
    var exerciseLevel: Int?
    var variantId: String?
    var easierVariantId: String?
    var harderVariantId: String?

    // — charge externe
    var externalLoadKg: Int?

    var isWarmup: Bool = false
    var isCooldown: Bool = false

    /// Faux pour ce qui ne doit pas peser dans l'adaptation : échauffement,
    /// retour au calme, mobilité d'accompagnement.
    var countsTowardAdaptation: Bool = true

    /// La quantité, dite en toutes lettres. « 4 × 8 » ne dit pas ce qu'on
    /// compte ; « 4 séries de 8 répétitions » si.
    var amountLabel: String {
        if let sets = sets, let perSet = targetPerSet, sets > 1 {
            return "\(sets) séries de \(unit.format(perSet))"
        }
        return unit.format(targetValue)
    }

    /// Le repos entre les séries, quand il y en a.
    var restLabel: String? {
        guard let rest = restSeconds, rest > 0, (sets ?? 1) > 1 else { return nil }
        return rest >= 60 && rest % 60 == 0
            ? "\(rest / 60) min de repos entre les séries"
            : "\(rest) s de repos entre les séries"
    }

    /// L'indication d'intensité, quand il y en a une. C'est elle qui manquait
    /// entièrement à l'ancien modèle.
    var intensityLabel: String? {
        var pieces: [String] = []
        if let rir = targetRIR { pieces.append(rir == 0 ? "jusqu'à l'échec" : "\(rir) en réserve") }
        if let rpe = targetRPE, targetRIR == nil { pieces.append("effort \(rpe)/10") }
        if let tempo = tempo { pieces.append("tempo \(tempo)") }
        if let load = externalLoadKg, load > 0 { pieces.append("\(load) kg") }
        return pieces.isEmpty ? nil : pieces.joined(separator: " · ")
    }
}

// MARK: - Passerelle avec l'ancien modèle

extension ExercisePrescription {
    /// Construit une prescription à partir d'une étape de l'ancien modèle.
    ///
    /// Sert la migration : les 303 séances existantes deviennent lisibles par
    /// le nouveau moteur sans être réécrites. Les variables que l'ancien
    /// modèle ne portait pas — intensité, variante, charge — restent vides,
    /// et c'est exact : elles n'étaient pas prescrites.
    init(step: SessionStep, policy: CompletionPolicy = .structuredSession) {
        self.id = "legacy-\(step.id)"
        self.exerciseId = nil
        self.name = step.name
        self.detail = step.detail.isEmpty ? nil : step.detail
        self.targetValue = step.goal.value
        self.unit = ObjectiveUnit(step.goal.unit)
        self.sets = nil
        self.targetPerSet = nil
        self.restSeconds = step.restSeconds > 0 ? step.restSeconds : nil
        self.characteristic = TrainingCharacteristic(step.stat)
        self.completionPolicy = policy
        self.isWarmup = !step.isWork && step.name.lowercased().contains("échauffement")
        self.isCooldown = !step.isWork && !self.isWarmup
        self.countsTowardAdaptation = step.isWork
    }
}

extension PlannedSession {
    /// La séance vue par le nouveau moteur. Les étapes identiques
    /// consécutives sont regroupées en séries, ce que l'ancien modèle
    /// exprimait en répétant la même étape.
    var prescriptions: [ExercisePrescription] {
        if let prescribed = prescribed { return prescribed }
        var result: [ExercisePrescription] = []
        for step in steps {
            if var last = result.last, last.name == step.name,
               last.unit == ObjectiveUnit(step.goal.unit),
               last.targetPerSet ?? last.targetValue == step.goal.value {
                last.sets = (last.sets ?? 1) + 1
                last.targetPerSet = step.goal.value
                last.targetValue = (last.sets ?? 1) * step.goal.value
                result[result.count - 1] = last
            } else {
                var fresh = ExercisePrescription(step: step)
                fresh.sets = 1
                fresh.targetPerSet = step.goal.value
                result.append(fresh)
            }
        }
        // une série unique ne s'annonce pas « 1 × 12 »
        return result.map { item in
            var copy = item
            if copy.sets == 1 { copy.sets = nil; copy.targetPerSet = nil }
            return copy
        }
    }
}
