import Foundation
import SwiftUI

/// Le chef d'orchestre d'une séance en cours.
///
/// Il tient la recette, avance de phase en phase, fait parler le tuteur,
/// écoute l'apprenant, et range chaque observation dans le modèle apprenant.
/// Il ne décide jamais d'un statut : il transmet des preuves à `MasteryEngine`.
@MainActor
final class SessionRunner: ObservableObject {

    // MARK: - État observable

    @Published private(set) var plan: SessionPlan
    @Published private(set) var phaseIndex: Int = 0
    /// Ce que le tuteur vient de dire, affiché sous la carte.
    @Published private(set) var tutorFrench: String = ""
    @Published private(set) var tutorMandarin: String = ""
    /// Ce que l'apprenant vient de dire.
    @Published private(set) var learnerSaid: String = ""
    @Published private(set) var isThinking = false
    /// La phrase de transition jouée pendant l'attente.
    @Published private(set) var transition: String?
    @Published private(set) var isFinished = false
    /// Le récapitulatif final, une fois la séance bouclée.
    @Published private(set) var recap: SessionRecap?
    /// L'échelle d'aide sur la tentative en cours.
    @Published private(set) var helpLevel: HelpLevel = .none
    @Published private(set) var isPausedForNetwork = false

    let tutor: Tutor

    // MARK: - Dépendances

    private let store: LearnerStore
    private let library: ContentLibrary
    private let voice: VoiceService
    private let telemetry: Telemetry
    private let network: NetworkMonitor

    private var record: SessionRecord
    private var ladder = HelpLadderState()
    private var recentTurns: [TurnContext.Exchange] = []
    private var verdicts: [String: SessionVerdict] = [:]
    private var lastTransition: String?
    private var recallScores: [Double] = []
    private var didAdaptToRecall = false
    private var pendingItemIndex = 0
    private var blockTimer: Timer?
    private var pendingFrench: String?
    private var pendingOutcome: (TutorTurn, SessionPhase)?

    /// Le mode de routage, réglé en mode développeur.
    var routingMode: RoutingMode = RoutingMode(
        rawValue: UserDefaults.standard.string(forKey: "shuo.routing") ?? ""
    ) ?? .automatic

    // MARK: - Cycle de vie

    init(
        plan: SessionPlan,
        store: LearnerStore,
        library: ContentLibrary = .shared,
        voice: VoiceService,
        telemetry: Telemetry,
        network: NetworkMonitor
    ) {
        self.plan = plan
        self.store = store
        self.library = library
        self.voice = voice
        self.telemetry = telemetry
        self.network = network
        self.tutor = Tutor.tutor(id: plan.tutorID)
        self.record = SessionRecord(
            id: plan.sessionID,
            startedAt: Date(),
            endedAt: nil,
            durationChoice: plan.durationMinutes,
            mode: plan.mode,
            tutorID: plan.tutorID,
            newItemIDs: plan.newItemIDs,
            reviewedItemIDs: plan.reviewItemIDs,
            verdicts: [:]
        )
    }

    /// Démarre la séance. L'invariant des trois mots neufs est vérifié ici,
    /// avant le premier mot dit (A02).
    func start() {
        assert(SessionOrchestrator.isValid(plan), "Plus de trois mots nouveaux dans une séance")
        telemetry.beginSession()
        store.beginSession(record)

        voice.onUtterance = { [weak self] said, confidence in
            self?.handleUtterance(said, confidence: confidence)
        }
        voice.onSpeechFinished = { [weak self] in
            self?.tutorFinishedSpeaking()
        }
        Task { await playCurrentPhase() }
    }

    /// Range la séance sans la terminer : elle pourra être reprise.
    func suspend() {
        blockTimer?.invalidate()
        voice.pause()
        record.estimatedCostEUR = telemetry.sessionCostEUR
        record.verdicts = verdicts
        store.updateSession(record)
    }

    /// Termine la séance et écrit tout ce qui doit l'être.
    func finish() {
        blockTimer?.invalidate()
        voice.stopSpeaking()
        voice.stopListening()

        // La rétrogradation ne s'applique qu'ici, et seulement quand les échecs
        // se sont répartis sur des séances différentes (A05 / A06).
        if plan.mode == .review || plan.mode == .returnTest {
            store.applyDowngrades(for: plan.reviewItemIDs)
        }

        record.estimatedCostEUR = telemetry.sessionCostEUR
        record.verdicts = verdicts
        store.finishSession(
            record,
            cursor: plan.mode == .progression ? plan.cursorAfter : nil,
            clearedRemediations: plan.remediationsHandled
        )
        recap = buildRecap()
        isFinished = true
        telemetry.note("Séance terminée.")
    }

    // MARK: - Phases

    var currentPhase: SessionPhase? {
        plan.phases.indices.contains(phaseIndex) ? plan.phases[phaseIndex] : nil
    }

    var progress: Double {
        guard !plan.phases.isEmpty else { return 1 }
        return Double(phaseIndex) / Double(plan.phases.count)
    }

    /// Le mot affiché sur la carte, s'il y en a un.
    var currentItem: VocabItem? {
        guard let phase = currentPhase else { return nil }
        let ids = phase.itemIDs
        guard !ids.isEmpty else { return nil }
        let index = min(pendingItemIndex, ids.count - 1)
        return library.item(id: ids[index])
    }

    private func playCurrentPhase() async {
        guard !isFinished else { return }
        guard let phase = currentPhase else {
            finish()
            return
        }
        ladder.reset()
        helpLevel = .none
        learnerSaid = ""
        await speakTurn(learnerSaid: nil, phase: phase)
    }

    private func advancePhase() {
        blockTimer?.invalidate()
        pendingItemIndex = 0

        // Le rappel initial vient de se terminer : si l'apprenant a peiné, on
        // réduit le neuf du jour avant d'y arriver.
        if currentPhase?.kind == .recall, !didAdaptToRecall, !recallScores.isEmpty {
            didAdaptToRecall = true
            let average = recallScores.reduce(0, +) / Double(recallScores.count)
            let reduced = SessionOrchestrator.reduceNewItems(in: plan, afterRecallScore: average)
            if reduced.newItemIDs.count != plan.newItemIDs.count {
                telemetry.note(String(
                    format: "Rappel à %.0f %% : %d mot(s) neuf(s) au lieu de %d.",
                    average * 100, reduced.newItemIDs.count, plan.newItemIDs.count
                ))
                plan = reduced
                record.newItemIDs = reduced.newItemIDs
            }
        }

        phaseIndex += 1
        Task { await playCurrentPhase() }
    }

    /// Passe la phase en cours à la demande de l'apprenant.
    func skipPhase() {
        advancePhase()
    }

    /// Avance dans les mots d'une même phase, ou passe à la suivante.
    private func advanceWithinPhase() {
        guard let phase = currentPhase else { return }
        if pendingItemIndex + 1 < phase.itemIDs.count {
            pendingItemIndex += 1
            ladder.reset()
            helpLevel = .none
            Task { await speakTurn(learnerSaid: nil, phase: phase) }
        } else {
            advancePhase()
        }
    }

    // MARK: - Tour de parole

    private func speakTurn(learnerSaid said: String?, phase: SessionPhase, helpStep: HelpStep? = nil) async {
        guard !isPausedForNetwork else { return }

        let items = currentItem.map { [$0] } ?? library.items(ids: phase.itemIDs)
        let context = TurnContext(
            tutor: tutor,
            phase: phase,
            items: items,
            itemSummaries: items.map(summary(for:)),
            learnerSaid: said,
            helpStep: helpStep,
            recentTurns: recentTurns,
            profileNotes: profileNotes(),
            grammarFocus: phase.grammarFocus,
            pronunciationFocus: phase.pronunciationFocus
        )

        let routing = ModelRouter.choose(
            ModelRouter.Context(
                phaseKind: phase.kind,
                helpLevel: helpLevel,
                asrConfidence: voice.lastConfidence,
                errorCount: 0,
                recoveringFromFailure: ladder.level >= .model,
                offScript: said != nil && phase.kind == .free
            ),
            mode: routingMode
        )

        let brain = makeBrain(for: routing.model)
        telemetry.setActive(brainModel(for: brain, requested: routing.model), trigger: routing.trigger)

        isThinking = true
        startTransitionPhrase()
        let started = Date()
        let usage = AnthropicTutorBrain.Usage()

        let turn: TutorTurn
        do {
            if let remote = brain as? AnthropicTutorBrain {
                turn = try await remote.respond(to: context, usage: usage)
            } else {
                turn = try await brain.respond(to: context)
            }
        } catch {
            usage.failedOver = true
            turn = (try? await ScriptedTutorBrain().respond(to: context)) ?? .silent()
        }

        isThinking = false
        transition = nil

        if brain is AnthropicTutorBrain {
            telemetry.record(ModelCallLog(
                at: started,
                modelID: routing.model.id,
                modelName: routing.model.displayName,
                complexity: routing.model.complexity,
                trigger: routing.trigger?.rawValue,
                latency: Date().timeIntervalSince(started),
                inputTokens: usage.inputTokens,
                outputTokens: usage.outputTokens,
                costUSD: routing.model.cost(inputTokens: usage.inputTokens, outputTokens: usage.outputTokens),
                phase: phase.kind.label,
                failedOver: usage.failedOver
            ))
        }

        apply(turn, phase: phase)
    }

    private func apply(_ turn: TutorTurn, phase: SessionPhase) {
        tutorFrench = turn.french
        tutorMandarin = turn.mandarin
        if !turn.french.isEmpty {
            recentTurns.append(.init(isTutor: true, text: turn.french))
        }
        if recentTurns.count > 8 { recentTurns.removeFirst(recentTurns.count - 8) }

        // Les notes proposées deviennent des preuves — jamais des statuts.
        for note in turn.evidence {
            var evidence = Evidence(
                itemID: note.itemID,
                dimension: note.dimension,
                score: note.score,
                helpLevel: ladder.level,
                sessionID: plan.sessionID
            )
            evidence.isDelayedRecall = isDelayedRecall(note.itemID, in: phase)
            evidence.isReviewOpportunity = isReviewOpportunity(phase)
            evidence.errorPattern = turn.errorPattern
            evidence.pronunciationFocus(from: phase)
            store.record(evidence)

            if phase.kind == .recall, note.dimension == .meaningRecall {
                recallScores.append(note.score)
            }
            if let item = store.item(note.itemID) {
                verdicts[note.itemID] = MasteryEngine.verdict(for: item, helpUsed: ladder.level)
            }
        }

        let toSay = [turn.mandarin, turn.french].filter { !$0.isEmpty }
        if toSay.isEmpty {
            handlePhaseOutcome(turn, phase: phase)
            return
        }

        // Ce qui doit suivre est posé avant de parler : la fin de la synthèse
        // peut arriver plus vite qu'on ne croit.
        pendingOutcome = (turn, phase)

        // Le mandarin d'abord, avec la voix chinoise ; le français ensuite.
        if !turn.mandarin.isEmpty {
            pendingFrench = turn.french
            voice.speak(turn.mandarin, tutor: tutor, language: "zh-CN")
        } else {
            pendingFrench = nil
            voice.speak(turn.french, tutor: tutor, language: "fr-FR")
        }
    }

    private func tutorFinishedSpeaking() {
        if let french = pendingFrench, !french.isEmpty {
            pendingFrench = nil
            voice.speak(french, tutor: tutor, language: "fr-FR")
            return
        }
        guard let (turn, phase) = pendingOutcome else { return }
        pendingOutcome = nil
        handlePhaseOutcome(turn, phase: phase)
    }

    private func handlePhaseOutcome(_ turn: TutorTurn, phase: SessionPhase) {
        if turn.phaseComplete {
            advanceWithinPhase()
            return
        }
        // C'est à l'apprenant. On l'écoute, et on ne le presse pas.
        if voice.mode == .handsFree {
            voice.startListening()
        }
        watchForProlongedBlock()
    }

    // MARK: - Parole de l'apprenant

    private func handleUtterance(_ said: String, confidence: Float?) {
        blockTimer?.invalidate()
        learnerSaid = said
        recentTurns.append(.init(isTutor: false, text: said))

        // Les trois mots de commande passent avant l'évaluation : ce ne sont
        // pas des tentatives.
        if let command = HelpCommand.detect(in: said) {
            handle(command)
            return
        }

        guard let phase = currentPhase else { return }
        Task { await speakTurn(learnerSaid: said, phase: phase) }
    }

    private func handle(_ command: HelpCommand) {
        guard let phase = currentPhase else { return }
        switch command {
        case .aide:
            let step = ladder.requestGradedHelp()
            helpLevel = ladder.level
            telemetry.note("Aide demandée → \(ladder.level.label)")
            Task { await speakTurn(learnerSaid: nil, phase: phase, helpStep: step) }

        case .reponse:
            let step = ladder.requestAnswer()
            helpLevel = .answer
            telemetry.note("Réponse demandée.")
            Task { await speakTurn(learnerSaid: nil, phase: phase, helpStep: step) }

        case .arreteToi:
            telemetry.note("Retour en mode guidé.")
            returnToGuidedMode()
        }
    }

    /// « arrête-toi » : on sort de la conversation libre et on revient au
    /// guidé, sans perdre le fil ni le scénario (A16).
    private func returnToGuidedMode() {
        voice.stopSpeaking()
        guard let phase = currentPhase else { return }
        if phase.kind == .free || phase.kind == .semiGuided {
            advancePhase()
        } else {
            ladder.reset()
            helpLevel = .none
            Task { await speakTurn(learnerSaid: nil, phase: phase) }
        }
    }

    /// Le silence prolongé ne coupe pas la parole : il propose de l'aide.
    private func watchForProlongedBlock() {
        blockTimer?.invalidate()
        blockTimer = Timer.scheduledTimer(withTimeInterval: 12, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self, let phase = self.currentPhase else { return }
                let step = self.ladder.offerOnProlongedBlock()
                await self.speakTurn(learnerSaid: nil, phase: phase, helpStep: step)
            }
        }
    }

    // MARK: - Réseau

    /// Met la séance en pause quand la connexion tombe, la reprend au retour.
    func networkChanged(isOnline: Bool) {
        if !isOnline, !isPausedForNetwork {
            isPausedForNetwork = true
            voice.pause()
            telemetry.note("Réseau perdu : séance en pause.")
        } else if isOnline, isPausedForNetwork {
            isPausedForNetwork = false
            voice.resume()
            telemetry.note("Réseau retrouvé.")
            Task { await playCurrentPhase() }
        }
    }

    // MARK: - Contexte envoyé au tuteur

    /// Une ligne par mot : c'est tout ce que le modèle a besoin de savoir.
    private func summary(for item: VocabItem) -> String {
        guard let state = store.item(item.officialKey) else {
            return "\(item.hanzi) : jamais vu"
        }
        var parts = ["\(item.hanzi) : \(state.status.label)"]
        if state.score(.tone) < MasteryEngine.oralGateThreshold, state.evidenceCount(.tone) > 0 {
            parts.append("ton fragile")
        }
        if state.helpLevelLast != .none {
            parts.append("dernier essai \(state.helpLevelLast.label)")
        }
        return parts.joined(separator: ", ")
    }

    /// Les faiblesses transversales : tons et familles de sons sous le seuil.
    private func profileNotes() -> [String] {
        var notes: [String] = []
        for (tone, score) in store.state.profile.toneProfile
        where score.evidenceCount >= 3 && score.score < 0.7 {
            notes.append("ton \(tone) à \(Int(score.score * 100)) %")
        }
        for (pattern, score) in store.state.profile.pronunciationPatterns
        where score.evidenceCount >= 3 && score.score < 0.7 {
            notes.append("\(pattern) à \(Int(score.score * 100)) %")
        }
        return Array(notes.prefix(4))
    }

    private func isDelayedRecall(_ itemID: String, in phase: SessionPhase) -> Bool {
        guard phase.kind == .recall || phase.kind == .checkpoint else { return false }
        guard let state = store.item(itemID) else { return false }
        return state.introducedInSession != plan.sessionID
    }

    private func isReviewOpportunity(_ phase: SessionPhase) -> Bool {
        (plan.mode == .review || plan.mode == .returnTest || phase.kind == .recall)
            && phase.kind != .newItem
    }

    // MARK: - Modèles

    private func makeBrain(for model: LanguageModel) -> TutorBrain {
        guard network.isOnline, let key = Keychain.anthropicAPIKey, !key.isEmpty else {
            return ScriptedTutorBrain()
        }
        return AnthropicTutorBrain(model: model, apiKey: key)
    }

    private func brainModel(for brain: TutorBrain, requested: LanguageModel) -> LanguageModel {
        brain is AnthropicTutorBrain ? requested : .light
    }

    private func startTransitionPhrase() {
        // Une phrase courte en mandarin plutôt qu'un silence : c'est ce que le
        // dossier demande pour couvrir la latence.
        let phrase = TransitionPhrases.random(avoiding: lastTransition)
        lastTransition = phrase.zh
        transition = "\(phrase.zh) · \(phrase.pinyin)"
    }

    // MARK: - Récapitulatif

    private func buildRecap() -> SessionRecap {
        let items = plan.newItemIDs.compactMap { id -> SessionRecap.Line? in
            guard let item = library.item(id: id) else { return nil }
            let state = store.item(id)
            return SessionRecap.Line(
                hanzi: item.hanzi,
                pinyin: item.pinyin,
                fr: item.fr,
                verdict: verdicts[id] ?? .aConsolider,
                status: state?.status ?? .red
            )
        }
        let returning = store.dueItems(at: Date().addingTimeInterval(86_400 * 2))
            .compactMap { library.item(id: $0)?.hanzi }
            .prefix(5)

        return SessionRecap(
            lines: items,
            pronunciationNote: pronunciationNote(),
            comingBack: Array(returning),
            durationMinutes: plan.durationMinutes
        )
    }

    private func pronunciationNote() -> String? {
        let notes = profileNotes()
        guard let first = notes.first else { return nil }
        return "À surveiller : \(first)."
    }
}

/// Ce que le récapitulatif dit — et rien de plus. Pas de note, pas de nouveau
/// contenu, pas d'annonce de la leçon suivante (A17).
struct SessionRecap {
    struct Line: Identifiable {
        let hanzi: String
        let pinyin: String
        let fr: String
        let verdict: SessionVerdict
        let status: MasteryStatus

        var id: String { hanzi }
    }

    let lines: [Line]
    let pronunciationNote: String?
    /// Ce qui reviendra bientôt, sans promettre quand.
    let comingBack: [String]
    let durationMinutes: Int
}

private extension Evidence {
    /// Rattache l'observation au point de son de la séance, quand il y en a un.
    mutating func pronunciationFocus(from phase: SessionPhase) {
        guard dimension == .pronunciation || dimension == .tone else { return }
        if let focus = phase.pronunciationFocus {
            if focus.contains("ton") { tone = Self.toneName(in: focus) }
            pronunciationPattern = Self.patternName(in: focus)
        }
    }

    static func toneName(in text: String) -> String? {
        for index in 1...4 where text.contains("ton \(index)") || text.contains("tons \(index)") {
            return "tone\(index)"
        }
        if text.contains("neutre") { return "neutral" }
        if text.contains("sandhi") || text.contains("3+3") { return "sandhi" }
        return nil
    }

    static func patternName(in text: String) -> String? {
        if text.contains("aspir") { return "aspiration" }
        if text.contains("rétroflex") || text.contains("zh/ch/sh") { return "retroflexes" }
        if text.contains("j/q/x") { return "j_q_x" }
        if text.contains("ü") { return "u_umlaut" }
        if text.contains("rythme") { return "rhythm" }
        if text.contains("initiale") { return "initials" }
        if text.contains("finale") { return "finals" }
        return nil
    }
}
