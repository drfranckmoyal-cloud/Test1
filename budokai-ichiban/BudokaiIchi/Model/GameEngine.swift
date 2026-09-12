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

    // MARK: - Rangs, comptés en programmes

    /// Ce qu'un programme complet rapporte, en gros.
    ///
    /// Mesuré sur Saitama : environ 85 séances à 150 XP au palier Confirmé,
    /// plus les bonus d'étape et de fin, plus la série. C'est l'unité dans
    /// laquelle les rangs sont exprimés — sans elle, un seuil en XP brut ne
    /// dit rien à personne.
    static let programXPReference = 25_000

    /// Les rangs, en nombre de programmes terminés.
    ///
    /// Le rang S demande **quatre programmes et demi** : on ne l'atteint pas
    /// en finissant un maître, il faut en avoir traversé plusieurs.
    static func programsNeeded(for rank: Rank) -> Double {
        switch rank {
        case .e: return 0
        case .d: return 0.3
        case .c: return 0.8
        case .b: return 1.6
        case .a: return 2.8
        case .s: return 4.5
        case .sPlus: return 7.0
        }
    }

    static func xpNeeded(for rank: Rank) -> Int {
        Int((programsNeeded(for: rank) * Double(programXPReference)).rounded())
    }

    static func rank(forXP xp: Int) -> Rank {
        var result = Rank.e
        for candidate in Rank.allCases where xp >= xpNeeded(for: candidate) {
            result = candidate
        }
        return result
    }

    /// Ce qu'il reste à gagner avant le rang suivant, et lequel.
    static func nextRank(forXP xp: Int) -> (rank: Rank, missing: Int)? {
        let current = rank(forXP: xp)
        guard let next = Rank.allCases.first(where: { $0 > current }) else { return nil }
        return (next, max(0, xpNeeded(for: next) - xp))
    }

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

    /// Tous les programmes sont ouverts, le temps d'éprouver le contenu.
    /// Repasser à `false` rend leurs conditions aux programmes : elles sont
    /// toujours décrites dans le catalogue, rien n'a été effacé.
    static let allProgramsOpen = true

    static func isUnlocked(_ program: Program, state: PlayerState) -> Bool {
        if allProgramsOpen { return true }
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
