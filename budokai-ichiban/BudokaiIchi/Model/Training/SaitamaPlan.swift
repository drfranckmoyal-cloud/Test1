import Foundation

/// Traduit l'avancement dans le programme en séance concrète.
///
/// C'est la pièce qui remplace l'ancien générateur : à partir du numéro de
/// séance, du calendrier réel et de la calibration, elle dit quel bloc, quelle
/// semaine, quel type de séance, et si la semaine est allégée.
enum SaitamaPlan {

    /// Semaines nominales par bloc, dans le scénario à cinq séances.
    /// Deux semaines par bloc, trois pour le dernier.
    static func weeks(inBlock index: Int) -> Int { index == 8 ? 3 : 2 }

    /// Le bloc auquel appartient une semaine.
    static func blockIndex(forWeek week: Int) -> Int {
        var remaining = week
        for index in 1...SaitamaBlocks.all.count {
            let span = weeks(inBlock: index)
            if remaining <= span { return index }
            remaining -= span
        }
        return SaitamaBlocks.all.count
    }

    /// Première semaine d'un bloc, à partir de 1.
    static func firstWeek(ofBlock index: Int) -> Int {
        (1..<max(1, index)).reduce(1) { $0 + weeks(inBlock: $1) }
    }

    /// Où en est le pratiquant, d'après le nombre de séances faites.
    struct Position {
        var week: Int
        var blockIndex: Int
        var slot: Int
        var sessionsPerWeek: Int
    }

    static func position(sessionIndex: Int, sessionsPerWeek: Int) -> Position {
        let perWeek = max(1, sessionsPerWeek)
        let week = sessionIndex / perWeek + 1
        return Position(week: week, blockIndex: blockIndex(forWeek: week),
                        slot: sessionIndex % perWeek, sessionsPerWeek: perWeek)
    }

    /// Le type de séance d'un créneau, d'après la semaine type de la
    /// spécification — chapitre 2.
    static func sessionType(slot: Int, sessionsPerWeek: Int) -> SessionType {
        if sessionsPerWeek >= 5 {
            switch slot {
            case 0: return .strength          // Force A
            case 1: return .easyEndurance
            case 2: return .strength          // Force B / routine
            case 3: return .qualityEndurance
            default: return .longEndurance
            }
        }
        switch slot {
        case 0: return .strength              // Force A
        case 1: return .qualityEndurance
        case 2: return .strength              // Force B / routine
        default: return .longEndurance
        }
    }

    /// Vrai quand ce créneau porte la Routine B plutôt que la Force A.
    static func isRoutineSlot(_ slot: Int, sessionsPerWeek: Int) -> Bool {
        sessionsPerWeek >= 5 ? slot == 2 : slot == 2
    }

    // MARK: - Décharge dynamique

    /// Décide si la semaine doit être allégée — chapitre 9.
    ///
    /// Trois portes : environ trois semaines de charge continue, une fin de
    /// bloc clé, ou deux des trois dernières séances clés à RPE ≥ 9,
    /// partielles ou techniquement dégradées.
    static func isDeloadWeek(week: Int, servedWeeks: [Int], recentReports: [SessionReport]) -> Bool {
        if servedWeeks.contains(week) { return true }

        let hardSignals = recentReports.prefix(3).filter { report in
            (report.rpe ?? 0) >= 9
                || (report.completion ?? .entirely) != .entirely
                || report.quality == .degraded
        }.count
        if hardSignals >= 2 { return true }

        let lastServed = servedWeeks.max() ?? 0
        if week - lastServed >= 4 { return true }

        // fin de bloc pair : la position nominale du scénario à cinq séances
        let block = blockIndex(forWeek: week)
        let lastWeekOfBlock = firstWeek(ofBlock: block) + weeks(inBlock: block) - 1
        return block % 2 == 0 && week == lastWeekOfBlock
    }

    // MARK: - Passage de bloc

    /// Où en est chaque domaine par rapport au repère du bloc — chapitre 10.
    struct DomainStatus {
        var domain: SaitamaDomain
        var reached: Int
        var target: Int
        var isAtTarget: Bool { reached >= target }
        var blocksBehind: Int
    }

    /// Juge les quatre domaines contre le repère du bloc.
    static func domainStatuses(blockIndex: Int, best: [String: Int]) -> [DomainStatus] {
        let spec = SaitamaBlocks.spec(blockIndex)
        return SaitamaDomain.allCases.map { domain in
            let target = domain == .endurance ? spec.benchmarkMeters : spec.routineVolume
            let reached = best[domain.rawValue] ?? 0
            var behind = 0
            if reached < target {
                for earlier in stride(from: blockIndex - 1, through: 1, by: -1) {
                    let earlierSpec = SaitamaBlocks.spec(earlier)
                    let earlierTarget = domain == .endurance
                        ? earlierSpec.benchmarkMeters : earlierSpec.routineVolume
                    behind += 1
                    if reached >= earlierTarget { break }
                }
            }
            return DomainStatus(domain: domain, reached: reached, target: target, blocksBehind: behind)
        }
    }

    /// Ce que le moteur décide en fin de bloc.
    enum BlockOutcome: Equatable {
        case advance
        case advanceWithCorrective(SaitamaDomain)
        case consolidate([SaitamaDomain])

        var label: String {
            switch self {
            case .advance: return "Bloc validé"
            case .advanceWithCorrective(let domain): return "Bloc validé, module correctif \(domain.label.lowercased())"
            case .consolidate(let domains):
                return "Consolidation — " + domains.map { $0.label.lowercased() }.joined(separator: " et ")
            }
        }

        var unlocksReward: Bool {
            if case .consolidate = self { return false }
            return true
        }
    }

    /// Applique la règle : au moins trois domaines sur quatre au niveau, et le
    /// quatrième à un bloc de retard au maximum.
    static func outcome(blockIndex: Int, best: [String: Int]) -> BlockOutcome {
        let statuses = domainStatuses(blockIndex: blockIndex, best: best)
        let late = statuses.filter { !$0.isAtTarget }

        if late.isEmpty { return .advance }
        if late.count == 1 {
            let domain = late[0]
            return domain.blocksBehind <= 1
                ? .advanceWithCorrective(domain.domain)
                : .consolidate([domain.domain])
        }
        return .consolidate(late.map(\.domain))
    }

    // MARK: - Combat final

    /// Les prérequis du chapitre 19, mesurés sur les expositions récentes.
    struct BossEligibility {
        var pushOK: Bool
        var coreOK: Bool
        var squatOK: Bool
        var runOK: Bool
        var lastBigSessionOK: Bool

        var isEligible: Bool { pushOK && coreOK && squatOK && runOK && lastBigSessionOK }

        var missing: [String] {
            var items: [String] = []
            if !pushOK { items.append("90 pompes propres en séance structurée") }
            if !coreOK { items.append("90 abdominaux contrôlés en séance structurée") }
            if !squatOK { items.append("90 squats propres en séance structurée") }
            if !runOK { items.append("9 km courus d'une seule traite") }
            if !lastBigSessionOK { items.append("une grosse séance récente menée à son terme") }
            return items
        }
    }

    static func eligibility(best: [String: Int], lastReport: SessionReport?) -> BossEligibility {
        BossEligibility(
            pushOK: (best["push"] ?? 0) >= 90,
            coreOK: (best["core"] ?? 0) >= 90,
            squatOK: (best["squat"] ?? 0) >= 90,
            runOK: (best["endurance"] ?? 0) >= 9000,
            lastBigSessionOK: lastReport.map { ($0.completion ?? .entirely) == .entirely } ?? false)
    }
}
