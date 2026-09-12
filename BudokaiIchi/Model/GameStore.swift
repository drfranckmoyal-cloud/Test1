import Foundation
import SwiftUI

/// Ce qu'on montre à la fin d'une séance.
struct SessionOutcome: Identifiable, Equatable {
    let id = UUID()
    var programID: ProgramID
    var sessionTitle: String
    var breakdown: GameEngine.XPBreakdown
    var statGains: [StatKind: Int]
    var streak: Int
    var stageCompleted: String?
    var stageIndex: Int
    var programCompleted: Bool
    var newRank: Rank?
    var totalXP: Int
}

/// Source de vérité de l'app : l'état du joueur, la séance du jour, les
/// quêtes de pénalité. Une journée court de minuit à minuit.
@MainActor
final class GameStore: ObservableObject {

    @Published private(set) var state: PlayerState
    @Published private(set) var today: Date

    private let storageKey = "budokai.player.v1"
    private let defaults: UserDefaults

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.today = Calendar.current.startOfDay(for: Date())
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(PlayerState.self, from: data) {
            self.state = decoded
        } else {
            self.state = LegacyImport.makeInitialState(defaults: defaults)
        }
        expirePenaltyIfNeeded()
    }

    // MARK: - Jours

    func key(_ date: Date) -> String {
        Self.dayFormatter.timeZone = TimeZone.current
        return Self.dayFormatter.string(from: date)
    }

    func date(fromKey key: String) -> Date? {
        Self.dayFormatter.timeZone = TimeZone.current
        return Self.dayFormatter.date(from: key)
    }

    var todayKey: String { key(today) }

    /// À appeler au lancement, au retour au premier plan et chaque minute.
    func refreshDate() {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        guard startOfToday != today else { return }
        today = startOfToday
        expirePenaltyIfNeeded()
        issuePenaltyIfNeeded()
    }

    // MARK: - Lecture

    var level: Int { GameEngine.level(forXP: state.xp) }
    var rank: Rank { GameEngine.rank(forXP: state.xp) }
    var levelProgress: Double { GameEngine.levelProgress(forXP: state.xp) }
    var xpToNextLevel: Int { max(0, GameEngine.xpNeeded(forLevel: level + 1) - state.xp) }

    var activeProgram: Program? {
        guard let raw = state.activeProgram, let id = ProgramID(rawValue: raw) else { return nil }
        return Catalog.program(id)
    }

    func progress(_ id: ProgramID) -> ProgramProgress { state.progress(id) }

    func isFinished(_ id: ProgramID) -> Bool {
        state.progress(id).completedSessions >= Catalog.program(id).totalSessions
    }

    func isUnlocked(_ program: Program) -> Bool {
        GameEngine.isUnlocked(program, state: state)
    }

    /// La prochaine séance du programme actif, ou nil s'il est terminé.
    var currentSession: PlannedSession? {
        guard let program = activeProgram else { return nil }
        let done = state.progress(program.id).completedSessions
        guard done < program.totalSessions else { return nil }
        return Catalog.session(for: program.id, index: done, tier: state.tier)
    }

    /// Jour où la prochaine séance est attendue.
    var nextDueDay: Date? {
        guard let program = activeProgram else { return nil }
        guard let last = lastSessionDay(program.id) else { return today }
        return Calendar.current.date(byAdding: .day, value: 1 + program.restDays, to: last)
    }

    var isSessionDueToday: Bool {
        guard let due = nextDueDay else { return false }
        return due <= today
    }

    var isRestDay: Bool {
        guard currentSession != nil, let due = nextDueDay else { return false }
        return due > today
    }

    func lastSessionDay(_ id: ProgramID) -> Date? {
        let days = state.history
            .filter { $0.programID == id.rawValue }
            .compactMap { date(fromKey: $0.day) }
        return days.max()
    }

    /// Étape en cours d'un programme et avancement à l'intérieur.
    func stageStatus(_ program: Program) -> (index: Int, done: Int, total: Int) {
        let completed = state.progress(program.id).completedSessions
        let index = min(program.stageIndex(forSession: completed), program.stages.count - 1)
        let first = program.firstSession(ofStage: index)
        let total = program.sessionsPerStage[index]
        return (index, min(completed - first, total), total)
    }

    var totalReps: Int { state.history.reduce(0) { $0 + $1.reps } + state.legacyReps }
    var sessionsDone: Int { state.history.count }

    // MARK: - Programmes

    func startProgram(_ id: ProgramID) {
        state.activeProgram = id.rawValue
        var progress = state.progress(id)
        if progress.startedOn == nil { progress.startedOn = todayKey }
        state.programs[id.rawValue] = progress
        save()
        syncNotifications()
    }

    // MARK: - Séance terminée

    /// `achieved` donne, par identifiant d'étape, ce qui a réellement été fait.
    @discardableResult
    func complete(session: PlannedSession, achieved: [Int: Int]) -> SessionOutcome {
        let program = Catalog.program(session.programID)

        let reps = session.steps.reduce(0) { partial, step in
            step.goal.unit == .reps ? partial + (achieved[step.id] ?? step.goal.value) : partial
        }
        let seconds = session.steps.reduce(0) { partial, step in
            step.goal.unit == .seconds ? partial + (achieved[step.id] ?? step.goal.value) : partial
        }
        let meters = session.steps.reduce(0) { partial, step in
            step.goal.unit == .meters ? partial + (achieved[step.id] ?? step.goal.value) : partial
        }

        let bestReps = state.history.map(\.reps).max() ?? 0
        let isRecord = reps > 0 && reps > bestReps

        // la série monte si la séance tombe le jour attendu ou avant
        let onTime = nextDueDay.map { $0 >= today } ?? true
        let previousStreak = state.streak
        if onTime || state.streak == 0 {
            state.streak += 1
        }
        state.bestStreak = max(state.bestStreak, state.streak)

        let breakdown = GameEngine.xp(forSession: session, achieved: achieved,
                                      tier: state.tier, streak: previousStreak,
                                      isPersonalRecord: isRecord)
        var gained = breakdown.total

        var progress = state.progress(program.id)
        progress.completedSessions += 1
        if progress.startedOn == nil { progress.startedOn = todayKey }

        // étape franchie ?
        let stageBefore = program.stageIndex(forSession: progress.completedSessions - 1)
        let stageAfter = program.stageIndex(forSession: progress.completedSessions)
        let crossedStage = progress.completedSessions >= program.totalSessions || stageAfter != stageBefore
        var stageName: String?
        if crossedStage && stageBefore < program.stages.count {
            stageName = program.stages[stageBefore]
            gained += GameEngine.stageXP
        }

        let programComplete = progress.completedSessions >= program.totalSessions
        if programComplete {
            progress.finishedOn = todayKey
            gained += GameEngine.programXP
            let badge = "\(program.name) : programme bouclé"
            if !state.badges.contains(badge) { state.badges.append(badge) }
            if !state.equipment.contains(program.name) { state.equipment.append(program.name) }
        }
        state.programs[program.id.rawValue] = progress

        let rankBefore = rank
        state.xp += gained
        let rankAfter = GameEngine.rank(forXP: state.xp)

        for (kind, value) in GameEngine.statGains(for: session, achieved: achieved) {
            state.stats[kind.rawValue] = state.stat(kind) + value
        }

        state.history.append(SessionRecord(
            programID: program.id.rawValue, sessionIndex: session.index,
            stageIndex: session.stageIndex, day: todayKey,
            xp: gained, reps: reps, seconds: seconds, meters: meters))
        state.lastCompletedDay = todayKey
        state.penalty = nil
        save()
        syncNotifications()

        return SessionOutcome(
            programID: program.id, sessionTitle: session.title, breakdown: breakdown,
            statGains: GameEngine.statGains(for: session, achieved: achieved),
            streak: state.streak, stageCompleted: stageName, stageIndex: stageBefore,
            programCompleted: programComplete,
            newRank: rankAfter > rankBefore ? rankAfter : nil, totalXP: gained)
    }

    // MARK: - Quête de pénalité

    /// Une séance attendue hier ou avant, et rien de fait : la série est en
    /// danger et une quête s'ouvre pour la sauver.
    func issuePenaltyIfNeeded() {
        guard state.penalty == nil, state.streak > 0, currentSession != nil else { return }
        guard let due = nextDueDay, due < today else { return }
        state.penalty = PenaltyQuest(issuedDay: todayKey, dueDay: todayKey,
                                     tasks: GameEngine.penaltyTasks(forRank: rank))
        save()
    }

    /// Passé son échéance, une quête non accomplie casse la série.
    private func expirePenaltyIfNeeded() {
        guard let penalty = state.penalty else { return }
        guard let due = date(fromKey: penalty.dueDay), due < today else { return }
        if !penalty.isComplete { state.streak = 0 }
        state.penalty = nil
        save()
    }

    func acceptPenalty() {
        state.penalty?.accepted = true
        save()
    }

    func addPenalty(_ amount: Int, to taskID: UUID) {
        guard var penalty = state.penalty,
              let index = penalty.tasks.firstIndex(where: { $0.id == taskID }) else { return }
        penalty.tasks[index].done = max(0, min(penalty.tasks[index].target, penalty.tasks[index].done + amount))
        if penalty.isComplete {
            state.penalty = nil
            state.xp += 120                     // la quête rapporte peu : elle répare, elle n'avance pas
        } else {
            state.penalty = penalty
        }
        save()
    }

    func abandonStreak() {
        state.streak = 0
        state.penalty = nil
        save()
    }

    // MARK: - Réglages

    func setTier(_ tier: Tier) { state.tier = tier; save() }
    func setTone(_ tone: MotivationTone) { state.tone = tone; save(); syncNotifications() }
    func setAppearance(_ appearance: Appearance) { state.appearance = appearance; save() }
    func finishOnboarding(tier: Tier) {
        state.tier = tier
        state.onboarded = true
        save()
    }

    func update(_ reminder: Reminder) {
        guard let index = state.reminders.firstIndex(where: { $0.id == reminder.id }) else { return }
        state.reminders[index] = reminder
        save()
        syncNotifications()
    }

    func resetEverything() {
        state = PlayerState()
        save()
        syncNotifications()
    }

    // MARK: - Rappels

    func syncNotifications() {
        let reminders = state.reminders
        let tone = state.tone
        let label = currentSession.map { "\(activeProgram?.name ?? "") · \($0.title)" } ?? ""
        Task { await NotificationManager.reschedule(reminders: reminders, tone: tone, sessionLabel: label) }
    }

    // MARK: - Persistance

    private func save() {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: storageKey)
    }
}

// MARK: - Reprise de l'app « 100 Pompes »

/// L'ancienne app rangeait ses totaux sous une autre clé. On ne perd rien :
/// les répétitions déjà faites deviennent de l'expérience de départ.
enum LegacyImport {

    private struct LegacyExercise: Codable { var kind: String; var dailyGoal: Int }
    private struct LegacyState: Codable {
        var startDate: Date
        var durationDays: Int
        var exercises: [LegacyExercise]
        var logs: [String: [String: Int]]
    }
    private struct LegacyStateV1: Codable {
        var startDate: Date
        var dailyGoal: Int
        var logs: [String: Int]
    }

    static func makeInitialState(defaults: UserDefaults) -> PlayerState {
        var state = PlayerState()
        var reps = 0

        if let data = defaults.data(forKey: "pompes.challenge.state.v2"),
           let legacy = try? JSONDecoder().decode(LegacyState.self, from: data) {
            reps = legacy.logs.values.reduce(0) { $0 + $1.values.reduce(0, +) }
        } else if let data = defaults.data(forKey: "pompes.challenge.state.v1"),
                  let legacy = try? JSONDecoder().decode(LegacyStateV1.self, from: data) {
            reps = legacy.logs.values.reduce(0, +)
        }

        guard reps > 0 else { return state }
        state.legacyReps = reps
        state.xp = reps
        state.stats[StatKind.force.rawValue] = min(40, reps / 100)
        state.badges.append("Reprise du défi 100 pompes")
        return state
    }
}
