import Foundation

/// Les règles du jeu, sans état : toutes les valeurs se calculent à partir de
/// ce qui est passé en argument. C'est ce qui permet de régler la courbe plus
/// tard sans toucher au reste de l'app.
enum GameEngine {

    // MARK: - Niveaux et rangs

    /// Expérience cumulée nécessaire pour atteindre un niveau.
    static func xpNeeded(forLevel level: Int) -> Int {
        guard level > 1 else { return 0 }
        return Int((250.0 * pow(Double(level), 1.6)).rounded())
    }

    static func level(forXP xp: Int) -> Int {
        var level = 1
        while level < 200 && xp >= xpNeeded(forLevel: level + 1) { level += 1 }
        return level
    }

    /// Part du chemin parcouru vers le niveau suivant, de 0 à 1.
    static func levelProgress(forXP xp: Int) -> Double {
        let level = self.level(forXP: xp)
        let floorXP = xpNeeded(forLevel: level)
        let nextXP = xpNeeded(forLevel: level + 1)
        guard nextXP > floorXP else { return 1 }
        return min(1, max(0, Double(xp - floorXP) / Double(nextXP - floorXP)))
    }

    static func rank(forXP xp: Int) -> Rank { Rank.forLevel(level(forXP: xp)) }

    // MARK: - Expérience d'une séance

    /// Multiplicateur de série.
    static func streakMultiplier(_ streak: Int) -> Double {
        if streak >= 14 { return 1.5 }
        if streak >= 7 { return 1.25 }
        if streak >= 3 { return 1.1 }
        return 1.0
    }

    /// Détail de l'expérience gagnée sur une séance, ligne par ligne, pour
    /// pouvoir l'afficher au lieu d'un total opaque.
    struct XPBreakdown: Equatable {
        var base: Int = 0
        var overshoot: Int = 0
        var record: Int = 0
        var streakBonus: Int = 0
        var total: Int { base + overshoot + record + streakBonus }
    }

    static func xp(forSession session: PlannedSession,
                   achieved: [Int: Int],
                   tier: Tier,
                   streak: Int,
                   isPersonalRecord: Bool) -> XPBreakdown {
        var breakdown = XPBreakdown()
        breakdown.base = Int((100.0 * tier.xpFactor).rounded())

        var extra = 0
        for step in session.steps where step.goal.unit == .reps {
            let done = achieved[step.id] ?? step.goal.value
            extra += max(0, done - step.goal.value)
        }
        breakdown.overshoot = min(50, extra)

        if isPersonalRecord { breakdown.record = 150 }

        let subtotal = breakdown.base + breakdown.overshoot + breakdown.record
        let multiplier = streakMultiplier(streak)
        breakdown.streakBonus = Int((Double(subtotal) * (multiplier - 1)).rounded())
        return breakdown
    }

    static let stageXP = 850
    static let programXP = 1500

    // MARK: - Caractéristiques

    /// Points de caractéristique gagnés sur une séance. Volontairement lents :
    /// ce sont eux qui conditionnent les déblocages.
    static func statGains(for session: PlannedSession, achieved: [Int: Int]) -> [StatKind: Int] {
        var reps = 0
        var runSeconds = 0
        var meters = 0
        var sprintBlocks = 0

        for step in session.steps {
            let done = achieved[step.id] ?? step.goal.value
            switch step.goal.unit {
            case .reps:
                reps += done
                if step.stat == .vitesse { sprintBlocks += 1 }
            case .seconds:
                if step.name.lowercased().contains("course") { runSeconds += done }
                if step.stat == .vitesse { sprintBlocks += 1 }
            case .meters:
                meters += done
            }
        }

        var gains: [StatKind: Int] = [:]
        let force = reps / 25
        if force > 0 { gains[.force] = min(6, force) }
        let endurance = meters / 800 + runSeconds / 480
        if endurance > 0 { gains[.endurance] = min(6, endurance) }
        if sprintBlocks > 0 { gains[.vitesse] = min(6, sprintBlocks) }
        return gains
    }

    // MARK: - Déblocages

    static func isUnlocked(_ program: Program, state: PlayerState) -> Bool {
        switch program.unlock {
        case .open:
            return true
        case .stat(let kind, let value):
            return state.stat(kind) >= value
        case .rank(let required):
            return rank(forXP: state.xp) >= required
        }
    }

    // MARK: - Quête de pénalité

    static func penaltyTasks(forRank rank: Rank) -> [PenaltyTask] {
        switch rank {
        case .e:
            return [PenaltyTask(name: "Squats", target: 20)]
        case .d:
            return [PenaltyTask(name: "Squats", target: 30), PenaltyTask(name: "Abdos", target: 20)]
        case .c:
            return [PenaltyTask(name: "Pompes", target: 40), PenaltyTask(name: "Abdos", target: 40)]
        case .b:
            return [PenaltyTask(name: "Pompes", target: 60), PenaltyTask(name: "Abdos", target: 60),
                    PenaltyTask(name: "Squats", target: 60)]
        case .a:
            return [PenaltyTask(name: "Pompes", target: 100), PenaltyTask(name: "Abdos", target: 100),
                    PenaltyTask(name: "Squats", target: 100)]
        case .s, .sPlus:
            return [PenaltyTask(name: "Pompes", target: 100), PenaltyTask(name: "Abdos", target: 100),
                    PenaltyTask(name: "Squats", target: 100),
                    PenaltyTask(name: "Course (centaines de mètres)", target: 100)]
        }
    }
}
