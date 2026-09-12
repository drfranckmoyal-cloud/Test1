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

    /// Le programme que l'on vient de prendre : l'app doit y conduire
    /// directement plutôt que de laisser le joueur le rechercher.
    @Published var justStarted: ProgramID?

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
            self.state = PlayerState()
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
    /// Remet d'aplomb ce qu'une version antérieure a pu laisser incohérent.
    /// Un historique vide ne peut pas porter de caractéristiques.
    private func healIfNeeded() {
        guard state.history.isEmpty, !state.stats.isEmpty else { return }
        state.stats = [:]
        save()
    }

    func refreshDate() {
        healIfNeeded()
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

    /// Les programmes suivis en parallèle, dans l'ordre où ils ont été pris.
    var activePrograms: [Program] {
        state.activePrograms.compactMap(ProgramID.init(rawValue:)).map(Catalog.program)
    }

    /// Le premier programme suivi. Sert là où il n'y a qu'une place à remplir,
    /// comme le libellé d'un rappel.
    var activeProgram: Program? { activePrograms.first }

    func isActive(_ id: ProgramID) -> Bool { state.activePrograms.contains(id.rawValue) }

    func progress(_ id: ProgramID) -> ProgramProgress { state.progress(id) }

    func isFinished(_ id: ProgramID) -> Bool {
        state.progress(id).completedSessions >= Catalog.program(id).totalSessions
    }

    func isUnlocked(_ program: Program) -> Bool {
        GameEngine.isUnlocked(program, state: state)
    }

    /// La prochaine séance d'un programme, ou nil s'il est terminé.
    /// Elle sort déjà ajustée au curseur d'intensité du programme.
    func session(of id: ProgramID) -> PlannedSession? {
        let program = Catalog.program(id)
        let done = state.progress(id).completedSessions
        guard done < program.totalSessions else { return nil }
        return Catalog.session(for: id, index: done, tier: state.tier,
                               intensity: state.progress(id).intensity)
    }

    /// Le curseur d'intensité d'un programme.
    func intensity(_ id: ProgramID) -> Double { state.progress(id).intensity }

    /// Borne le curseur : ni caricature d'effort, ni séance vidée.
    private func clamp(_ value: Double) -> Double { min(2.5, max(0.5, value)) }

    /// Règle l'intensité à la main, avant ou pendant la séance.
    func setIntensity(_ value: Double, for id: ProgramID) {
        var progress = state.progress(id)
        progress.intensity = clamp(value)
        state.programs[id.rawValue] = progress
        save()
    }

    /// Applique le ressenti d'une séance au programme : c'est ce qui rend la
    /// suivante plus dure ou plus douce.
    func apply(_ feedback: SessionFeedback, to id: ProgramID) {
        var progress = state.progress(id)
        progress.intensity = clamp(progress.intensity + feedback.adjustment)
        state.programs[id.rawValue] = progress
        save()
    }

    /// Jour où la prochaine séance d'un programme est attendue.
    func nextDueDay(of id: ProgramID) -> Date? {
        guard isActive(id) else { return nil }
        guard let last = lastSessionDay(id) else { return today }
        return Calendar.current.date(byAdding: .day, value: 1 + Catalog.program(id).restDays, to: last)
    }

    /// Vrai quand le programme attend une séance aujourd'hui ou l'a laissée passer.
    func isDueToday(_ id: ProgramID) -> Bool {
        guard session(of: id) != nil, let due = nextDueDay(of: id) else { return false }
        return due <= today
    }

    /// Vrai quand le programme tourne mais se repose aujourd'hui.
    func isResting(_ id: ProgramID) -> Bool {
        guard session(of: id) != nil, let due = nextDueDay(of: id) else { return false }
        return due > today
    }

    /// Les séances attendues aujourd'hui, tous programmes suivis confondus.
    var sessionsDueToday: [(program: Program, session: PlannedSession)] {
        activePrograms.compactMap { program in
            guard isDueToday(program.id), let session = session(of: program.id) else { return nil }
            return (program, session)
        }
    }

    /// Les programmes suivis qui se reposent aujourd'hui.
    var programsResting: [Program] { activePrograms.filter { isResting($0.id) } }

    /// Les programmes suivis arrivés à leur terme.
    var programsFinished: [Program] { activePrograms.filter { session(of: $0.id) == nil } }

    // Conservés pour les écrans qui ne parlent que du premier programme.
    var currentSession: PlannedSession? { activeProgram.flatMap { session(of: $0.id) } }
    var nextDueDay: Date? { activeProgram.flatMap { nextDueDay(of: $0.id) } }
    var isSessionDueToday: Bool { activeProgram.map { isDueToday($0.id) } ?? false }
    var isRestDay: Bool { activeProgram.map { isResting($0.id) } ?? false }

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

    var totalReps: Int { state.history.reduce(0) { $0 + $1.reps } }
    var sessionsDone: Int { state.history.count }

    // MARK: - Programmes

    /// Prend un programme de plus. Les autres continuent en parallèle.
    func startProgram(_ id: ProgramID) {
        if !state.activePrograms.contains(id.rawValue) {
            state.activePrograms.append(id.rawValue)
        }
        var progress = state.progress(id)
        if progress.startedOn == nil { progress.startedOn = todayKey }
        state.programs[id.rawValue] = progress
        justStarted = id
        save()
        syncNotifications()
    }

    /// Retire un programme du suivi. L'avancée déjà faite est conservée : le
    /// reprendre plus tard repart d'où il en était.
    func stopProgram(_ id: ProgramID) {
        state.activePrograms.removeAll { $0 == id.rawValue }
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
        let onTime = nextDueDay(of: program.id).map { $0 >= today } ?? true
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

        let gains = GameEngine.statGains(for: session, achieved: achieved)
        var gainsByName: [String: Int] = [:]
        for (kind, value) in gains {
            state.stats[kind.rawValue] = state.stat(kind) + value
            gainsByName[kind.rawValue] = value
        }

        state.history.append(SessionRecord(
            programID: program.id.rawValue, sessionIndex: session.index,
            stageIndex: session.stageIndex, day: todayKey,
            xp: gained, reps: reps, seconds: seconds, meters: meters,
            statGains: gainsByName))
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
        guard state.penalty == nil, state.streak > 0 else { return }
        // un seul programme en retard suffit
        let late = activePrograms.contains { program in
            guard session(of: program.id) != nil, let due = nextDueDay(of: program.id) else { return false }
            return due < today
        }
        guard late else { return }
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
    func setAvatar(_ avatar: AvatarConfig) { state.avatar = avatar; save() }

    // MARK: - Séance ouverte et suivi fractionné

    /// La séance d'un programme laissée ouverte aujourd'hui.
    func openSession(of id: ProgramID) -> OpenSession? {
        state.openSessions.first { $0.programID == id.rawValue && $0.day == todayKey }
    }

    /// Ouvre la séance d'un programme, ou retrouve celle déjà ouverte.
    /// Une séance fractionnable vit toute la journée : on ne la recrée pas à
    /// chaque passage dans l'écran.
    @discardableResult
    func beginSession(_ session: PlannedSession) -> OpenSession {
        if let existing = openSession(of: session.programID) { return existing }
        var fresh = OpenSession(programID: session.programID.rawValue,
                                sessionIndex: session.index, day: todayKey)
        for item in session.prescriptions {
            fresh.objectives[item.id] = DailyObjectiveProgress(
                prescriptionId: item.id, day: todayKey,
                targetValue: item.targetValue, unit: item.unit,
                completionPolicy: item.completionPolicy)
        }
        state.openSessions.append(fresh)
        save()
        return fresh
    }

    /// Enregistre une contribution à un objectif.
    func addProgress(_ value: Int, to prescriptionId: String, of id: ProgramID,
                     source: ProgressEntry.Source = .manual) {
        guard value > 0,
              let index = state.openSessions.firstIndex(where: {
                  $0.programID == id.rawValue && $0.day == todayKey }),
              var objective = state.openSessions[index].objectives[prescriptionId]
        else { return }
        objective.add(ProgressEntry(prescriptionId: prescriptionId,
                                    value: value, unit: objective.unit, source: source))
        state.openSessions[index].objectives[prescriptionId] = objective
        save()
    }

    /// Déclare un objectif atteint sans détailler les contributions.
    func declareComplete(_ prescriptionId: String, of id: ProgramID) {
        mutate(prescriptionId, of: id) { $0.declaredComplete = true }
    }

    func removeProgress(_ entryId: UUID, from prescriptionId: String, of id: ProgramID) {
        mutate(prescriptionId, of: id) { $0.remove(entryId) }
    }

    func updateProgress(_ entryId: UUID, to value: Int,
                        in prescriptionId: String, of id: ProgramID) {
        mutate(prescriptionId, of: id) { $0.update(entryId, to: value) }
    }

    private func mutate(_ prescriptionId: String, of id: ProgramID,
                        _ change: (inout DailyObjectiveProgress) -> Void) {
        guard let index = state.openSessions.firstIndex(where: {
            $0.programID == id.rawValue && $0.day == todayKey }),
              var objective = state.openSessions[index].objectives[prescriptionId]
        else { return }
        change(&objective)
        state.openSessions[index].objectives[prescriptionId] = objective
        save()
    }

    /// Referme la séance ouverte d'un programme.
    func closeSession(of id: ProgramID) {
        state.openSessions.removeAll { $0.programID == id.rawValue }
        save()
    }

    /// Les séances ouvertes d'un autre jour, à solder.
    var staleSessions: [OpenSession] {
        state.openSessions.filter { $0.day != todayKey }
    }

    // MARK: - Retour de séance et adaptation

    /// Enregistre le retour à trois questions et applique la décision du
    /// moteur. Chaque réponse est facultative.
    func record(_ report: SessionReport, for id: ProgramID, completedRatio: Double) {
        guard !report.isEmpty else { return }
        state.reports["\(id.rawValue)-\(state.progress(id).completedSessions)"] = report

        let move = AdaptationEngine.decide(
            AdaptationInput(report: report, completedRatio: completedRatio))

        var progress = state.progress(id)
        progress.lastMove = move
        progress.intensity = clamp(progress.intensity * AdaptationEngine.volumeFactor(for: move))
        state.programs[id.rawValue] = progress
        save()
    }

    /// Ce que le moteur a décidé pour la prochaine séance d'un programme.
    func lastMove(of id: ProgramID) -> AdaptationMove? { state.progress(id).lastMove }

    // MARK: - Planification

    /// Les règles de planification d'un programme, quand elles sont écrites.
    func schedulingRules(of id: ProgramID) -> ProgramSchedulingRules? {
        SchedulingCatalog.rules(for: id)
    }

    /// Vrai quand le programme réclame ses disponibilités avant de démarrer.
    func needsScheduling(_ id: ProgramID) -> Bool {
        schedulingRules(of: id) != nil && state.progress(id).schedule == nil
    }

    func availability(of id: ProgramID) -> TrainingAvailability? { state.progress(id).availability }
    func schedule(of id: ProgramID) -> ProgramSchedule? { state.progress(id).schedule }

    /// Construit le calendrier et le range. Renvoie le refus quand la
    /// fréquence demandée passe sous le minimum du programme : on ne comprime
    /// jamais un programme sous son minimum.
    @discardableResult
    func applyAvailability(_ availability: TrainingAvailability,
                           to id: ProgramID) -> Result<ProgramSchedule, SchedulingRefusal> {
        guard let rules = schedulingRules(of: id) else {
            return .failure(.belowMinimum(minimum: 1))
        }
        let outcome = CalendarPlanner.plan(rules: rules, availability: availability,
                                           structure: structure(of: id))
        if case .success(let schedule) = outcome {
            var progress = state.progress(id)
            progress.availability = availability
            progress.schedule = schedule
            state.programs[id.rawValue] = progress
            save()
            syncNotifications()
        }
        return outcome
    }

    /// Les semaines encore estimées avant la fin, d'après ce qui est fait.
    func estimatedWeeksRemaining(of id: ProgramID) -> Int? {
        guard let schedule = schedule(of: id), schedule.sessionsPerWeek > 0 else { return nil }
        let done = state.progress(id).completedSessions
        let weeksDone = done / schedule.sessionsPerWeek
        return max(0, schedule.estimatedWeeks - weeksDone)
    }

    // MARK: - Structure, blocs et récompenses

    /// La structure du programme, quand elle est écrite.
    func structure(of id: ProgramID) -> ProgramStructure? { ProgramStructures.structure(for: id) }

    /// Le bloc en cours, d'après les séances déjà faites.
    ///
    /// La semaine se compte sur la **fréquence réelle** du calendrier, pas
    /// sur la fréquence nominale : quelqu'un qui s'entraîne quatre fois par
    /// semaine avance en semaines plus lentement, et ses blocs suivent.
    func currentBlock(of id: ProgramID) -> ProgramBlock? {
        guard let structure = structure(of: id) else { return nil }
        let perWeek = schedule(of: id)?.sessionsPerWeek ?? structure.nominalSessionsPerWeek
        let done = state.progress(id).completedSessions
        let week = max(1, done / max(1, perWeek) + 1)
        return structure.block(forWeek: min(week, structure.nominalWeeks))
    }

    /// Marque un bloc comme validé et débloque sa vignette.
    func completeBlock(_ blockId: String, of id: ProgramID) {
        var progress = state.progress(id)
        guard !progress.completedBlocks.contains(blockId) else { return }
        progress.completedBlocks.append(blockId)
        state.programs[id.rawValue] = progress
        if let reward = RewardCatalog.reward(forBlock: blockId) {
            state.rewards.unlock(reward.rewardId)
        }
        save()
    }

    /// Les vignettes obtenues, les plus récentes d'abord.
    var unlockedRewards: [Reward] {
        state.rewards.unlocked
            .compactMap { id, date in RewardCatalog.reward(id).map { ($0, date) } }
            .sorted { $0.1 > $1.1 }
            .map(\.0)
    }

    /// Les vignettes obtenues mais pas encore montrées en grand.
    var rewardsToReveal: [Reward] {
        RewardCatalog.all.filter { state.rewards.needsReveal($0.rewardId) }
    }

    func markRevealed(_ rewardId: String) {
        state.rewards.markRevealed(rewardId)
        save()
    }

    func setSpoilerLevel(_ level: SpoilerLevel) {
        state.spoilerLevel = level
        save()
    }

    // MARK: - Historique

    /// Les séances faites, de la plus récente à la plus ancienne.
    var historyNewestFirst: [SessionRecord] {
        state.history.sorted { lhs, rhs in
            lhs.day == rhs.day ? lhs.sessionIndex > rhs.sessionIndex : lhs.day > rhs.day
        }
    }

    /// Efface une séance enregistrée par erreur, et défait ce qu'elle avait
    /// apporté : son expérience, son avancement, et la série si elle en
    /// dépendait.
    func deleteRecord(_ id: UUID) {
        guard let position = state.history.firstIndex(where: { $0.id == id }) else { return }
        let record = state.history.remove(at: position)

        state.xp = max(0, state.xp - record.xp)

        if let programID = ProgramID(rawValue: record.programID) {
            var progress = state.progress(programID)
            progress.completedSessions = max(0, progress.completedSessions - 1)
            if progress.completedSessions == 0 { progress.startedOn = nil }
            progress.finishedOn = nil
            state.programs[programID.rawValue] = progress
        }

        recomputeStreak()
        reconcileStats()
        save()
        syncNotifications()
    }

    /// Ramène un programme à une séance donnée : cette séance et toutes
    /// celles qui la suivent redeviennent à faire.
    ///
    /// L'avancement se compte en nombre de séances, pas en cases cochées :
    /// un programme ne peut pas avoir de trou. Effacer une séance du milieu
    /// revient donc à défaire tout ce qui vient après.
    func rewind(_ id: ProgramID, toSession index: Int) {
        let removed = state.history.filter { $0.programID == id.rawValue && $0.sessionIndex >= index }
        guard !removed.isEmpty else { return }

        state.history.removeAll { $0.programID == id.rawValue && $0.sessionIndex >= index }
        state.xp = max(0, state.xp - removed.reduce(0) { $0 + $1.xp })

        var progress = state.progress(id)
        progress.completedSessions = max(0, index - 1)
        if progress.completedSessions == 0 { progress.startedOn = nil }
        progress.finishedOn = nil
        state.programs[id.rawValue] = progress

        recomputeStreak()
        reconcileStats()
        save()
        syncNotifications()
    }

    /// Combien de séances seraient défaites en revenant à celle-ci.
    func sessionsUndone(_ id: ProgramID, toSession index: Int) -> Int {
        state.history.filter { $0.programID == id.rawValue && $0.sessionIndex >= index }.count
    }

    /// Remet les caractéristiques d'accord avec l'historique, après une
    /// suppression.
    ///
    /// Plus d'historique, plus de caractéristiques : c'est la seule lecture
    /// cohérente. Tant qu'il reste des séances d'avant la mémorisation des
    /// gains, on ne retire que ce qu'on sait retirer, et le rattrapage reste
    /// proposé dans l'historique.
    private func reconcileStats() {
        if state.history.isEmpty {
            state.stats = [:]
            return
        }
        guard !hasUntrackedStatGains else { return }
        recomputeStats(persist: false)
    }

    /// Recalcule les caractéristiques à partir de tout l'historique.
    ///
    /// Sert de rattrapage : les séances enregistrées avant que l'app ne garde
    /// leurs gains n'en portent aucun, et ne peuvent donc pas être défaites
    /// une par une. Ce recalcul remet le compteur d'aplomb sur ce qui reste.
    func recomputeStats(persist: Bool = true) {
        var totals: [String: Int] = [:]
        for record in state.history {
            for (name, value) in record.statGains {
                totals[name, default: 0] += value
            }
        }
        state.stats = totals
        if persist { save() }
    }

    /// Vrai quand l'historique contient des séances d'avant la correction :
    /// leurs caractéristiques ne peuvent pas être rendues précisément.
    var hasUntrackedStatGains: Bool {
        state.history.contains { $0.statGains.isEmpty }
    }

    /// Recalcule la série d'après ce qui reste : des jours consécutifs
    /// jusqu'au dernier jour où une séance a été faite.
    private func recomputeStreak() {
        let days = Set(state.history.map(\.day)).compactMap(date(fromKey:)).sorted(by: >)
        guard let mostRecent = days.first else {
            state.streak = 0
            state.lastCompletedDay = nil
            return
        }
        var run = 1
        var cursor = mostRecent
        for day in days.dropFirst() {
            guard let previous = Calendar.current.date(byAdding: .day, value: -1, to: cursor) else { break }
            if Calendar.current.isDate(day, inSameDayAs: previous) {
                run += 1
                cursor = day
            } else if !Calendar.current.isDate(day, inSameDayAs: cursor) {
                break
            }
        }
        state.streak = run
        state.lastCompletedDay = key(mostRecent)
    }

    /// La ceinture que la série en cours a méritée.
    var belt: Belt { Belt.earned(streak: state.streak) }
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
        let due = sessionsDueToday
        let label: String
        switch due.count {
        case 0: label = ""
        case 1: label = "\(due[0].program.name) · \(due[0].session.title)"
        default: label = "\(due.count) séances : " + due.map(\.program.name).joined(separator: ", ")
        }
        Task { await NotificationManager.reschedule(reminders: reminders, tone: tone, sessionLabel: label) }
    }

    // MARK: - Persistance

    private func save() {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
