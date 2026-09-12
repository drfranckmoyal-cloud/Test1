import Foundation

/// Une séance posée sur un jour de la semaine.
struct ScheduledSession: Identifiable, Codable, Equatable {
    var id: String { "\(day.rawValue)-\(metadata.id)" }
    var day: Weekday
    var metadata: SessionSchedulingMetadata
    /// Vrai quand le jour retenu n'est pas celui que le pratiquant préférait :
    /// une règle sportive est passée devant.
    var movedFromPreference: Bool = false
}

/// Le calendrier d'une semaine type, et ce qu'il coûte.
struct ProgramSchedule: Codable, Equatable {
    var programID: String
    var sessionsPerWeek: Int
    var sessions: [ScheduledSession]
    /// Semaines estimées pour boucler le programme. Une estimation, pas une
    /// promesse : elle se recalcule à chaque changement.
    var estimatedWeeks: Int
    /// Ce que le planificateur a dû arbitrer, dit en clair.
    var notes: [String] = []

    func session(on day: Weekday) -> ScheduledSession? {
        sessions.first { $0.day == day }
    }

    var restDays: [Weekday] {
        Weekday.allCases.filter { day in !sessions.contains { $0.day == day } }
    }

    var weeklyMinutes: Int {
        sessions.reduce(0) { $0 + $1.metadata.estimatedDurationMinutes }
    }
}

/// Pourquoi une fréquence est refusée.
enum SchedulingRefusal: Error, Equatable {
    case belowMinimum(minimum: Int)
    case notEnoughDays(available: Int, needed: Int)

    var message: String {
        switch self {
        case .belowMinimum(let minimum):
            return "Ce programme demande au moins \(minimum) séances par semaine. En dessous, il ne tient plus debout : mieux vaut dégager une séance de plus, ou choisir un autre maître."
        case .notEnoughDays(let available, let needed):
            return "Tu as retenu \(available) jour\(available > 1 ? "s" : "") disponible\(available > 1 ? "s" : "") pour \(needed) séances. Il faut au moins autant de jours que de séances."
        }
    }
}

/// Construit le meilleur calendrier compatible avec les règles du programme
/// et la vie du pratiquant.
///
/// L'ordre d'arbitrage est celui du chapitre 3.3, et il ne se discute pas :
/// contraintes sportives, récupération, jours impossibles, séances clés,
/// nombre de séances, puis seulement les jours préférés.
enum CalendarPlanner {

    // MARK: - Refus

    /// Vérifie qu'un calendrier est possible. On ne comprime jamais un
    /// programme sous son minimum : on l'explique et on s'arrête.
    static func refusal(rules: ProgramSchedulingRules,
                        availability: TrainingAvailability) -> SchedulingRefusal? {
        if availability.targetSessionsPerWeek < rules.minimumSessionsPerWeek {
            return .belowMinimum(minimum: rules.minimumSessionsPerWeek)
        }
        let days = availability.usableDays.count
        if days < availability.targetSessionsPerWeek {
            return .notEnoughDays(available: days, needed: availability.targetSessionsPerWeek)
        }
        return nil
    }

    // MARK: - Construction

    static func plan(rules: ProgramSchedulingRules,
                     availability: TrainingAvailability,
                     structure: ProgramStructure?) -> Result<ProgramSchedule, SchedulingRefusal> {

        if let refusal = refusal(rules: rules, availability: availability) {
            return .failure(refusal)
        }

        let frequency = min(availability.targetSessionsPerWeek, rules.maximumStructuredSessionsPerWeek)
        guard let template = rules.weeklyTemplates[frequency] ?? rules.weeklyTemplates[rules.recommendedSessionsPerWeek] else {
            return .failure(.belowMinimum(minimum: rules.minimumSessionsPerWeek))
        }

        var notes: [String] = []
        var free = availability.usableDays
        var placed: [ScheduledSession] = []

        // 1 — la séance clé d'abord : c'est elle que l'on protège
        let ordered = template.sorted { lhs, rhs in
            if lhs.priority.rank != rhs.priority.rank { return lhs.priority.rank < rhs.priority.rank }
            return lhs.loadCategory == .hard && rhs.loadCategory != .hard
        }

        for session in ordered {
            let preferred = preference(for: session, availability: availability)
            guard let day = pick(for: session, among: free, preferred: preferred, placed: placed,
                                 recoveryDays: rules.recoveryDays) else {
                notes.append("« \(session.displayTitle) » n'a pas pu être placée cette semaine.")
                continue
            }
            let moved = preferred != nil && preferred != day
            if moved {
                notes.append("« \(session.displayTitle) » est passée au \(day.label.lowercased()) : "
                             + "deux séances lourdes ne peuvent pas se suivre.")
            }
            placed.append(ScheduledSession(day: day, metadata: session, movedFromPreference: moved))
            free.removeAll { $0 == day }
        }

        if frequency < rules.recommendedSessionsPerWeek {
            notes.append("À \(frequency) séances, la progression est plus lente qu'à "
                         + "\(rules.recommendedSessionsPerWeek). C'est un choix tenable, pas un défaut.")
        }

        let schedule = ProgramSchedule(
            programID: rules.programID,
            sessionsPerWeek: placed.count,
            sessions: placed.sorted { $0.day < $1.day },
            estimatedWeeks: estimatedWeeks(rules: rules, frequency: frequency, structure: structure),
            notes: notes)
        return .success(schedule)
    }

    // MARK: - Choix du jour

    private static func preference(for session: SessionSchedulingMetadata,
                                   availability: TrainingAvailability) -> Weekday? {
        if session.type == .longEndurance, let day = availability.preferredLongSessionDay { return day }
        if session.priority == .critical, let day = availability.preferredKeySessionDay { return day }
        return nil
    }

    /// Retient le jour le plus sain, la préférence ne l'emportant que si elle
    /// respecte la récupération.
    private static func pick(for session: SessionSchedulingMetadata,
                             among free: [Weekday],
                             preferred: Weekday?,
                             placed: [ScheduledSession],
                             recoveryDays: Int) -> Weekday? {
        guard !free.isEmpty else { return nil }

        let hardDays = placed.filter { $0.metadata.loadCategory == .hard }.map(\.day)

        func respectsRecovery(_ day: Weekday) -> Bool {
            guard session.loadCategory == .hard else { return true }
            return hardDays.allSatisfy { other in
                let gap = min(day.days(until: other), other.days(until: day))
                return gap >= recoveryDays
            }
        }

        // 1 — la préférence, si elle est sportivement tenable
        if let preferred = preferred, free.contains(preferred), respectsRecovery(preferred) {
            return preferred
        }

        // 2 — parmi les jours qui respectent la récupération, celui qui
        //     s'éloigne le plus de ce qui est déjà posé
        let candidates = free.filter(respectsRecovery)
        let pool = candidates.isEmpty ? free : candidates
        guard !placed.isEmpty else {
            // première séance : on privilégie la préférence, sinon le début de semaine
            return preferred.flatMap { pool.contains($0) ? $0 : nil } ?? pool.first
        }
        return pool.max { lhs, rhs in spacing(lhs, placed) < spacing(rhs, placed) }
    }

    /// Distance au jour occupé le plus proche.
    private static func spacing(_ day: Weekday, _ placed: [ScheduledSession]) -> Int {
        placed.map { other in
            min(day.days(until: other.day), other.day.days(until: day))
        }.min() ?? 7
    }

    // MARK: - Estimation de durée

    /// La durée n'est plus une constante du programme : elle se recalcule.
    ///
    /// Le repère nominal vaut pour la fréquence recommandée. À fréquence plus
    /// basse, le même travail s'étale : on allonge dans cette proportion.
    static func estimatedWeeks(rules: ProgramSchedulingRules,
                               frequency: Int,
                               structure: ProgramStructure?) -> Int {
        let nominal = structure?.nominalWeeks ?? 12
        guard frequency > 0, frequency < rules.recommendedSessionsPerWeek else { return nominal }
        let ratio = Double(rules.recommendedSessionsPerWeek) / Double(frequency)
        return Int((Double(nominal) * ratio).rounded())
    }

    // MARK: - Séance manquée

    /// Ce que devient une séance ratée. Jamais de doublage automatique le
    /// lendemain : c'est la règle du chapitre 3.3.
    enum MissedSessionOutcome: Equatable {
        case dropped
        case moved(to: Weekday)
        case weekExtended

        var message: String {
            switch self {
            case .dropped:
                return "Séance facultative passée : on l'abandonne, et la semaine continue."
            case .moved(let day):
                return "Séance déplacée au \(day.label.lowercased())."
            case .weekExtended:
                return "Séance incontournable : la semaine est prolongée plutôt que doublée."
            }
        }
    }

    static func handle(missed session: ScheduledSession,
                       in schedule: ProgramSchedule,
                       availability: TrainingAvailability,
                       recoveryDays: Int) -> MissedSessionOutcome {
        switch session.metadata.priority {
        case .optional:
            return .dropped
        case .important, .critical:
            let occupied = schedule.sessions.map(\.day)
            let free = availability.usableDays.filter { !occupied.contains($0) }
            if let day = pick(for: session.metadata, among: free, preferred: nil,
                              placed: schedule.sessions, recoveryDays: recoveryDays) {
                return .moved(to: day)
            }
            return session.metadata.priority == .critical ? .weekExtended : .dropped
        }
    }
}
