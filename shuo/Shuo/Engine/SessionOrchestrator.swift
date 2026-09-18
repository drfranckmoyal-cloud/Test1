import Foundation

/// Le moteur pédagogique. C'est lui qui décide ce que contient une séance :
/// combien de mots neufs, quoi rappeler, dans quel ordre, et pour combien de
/// temps. Le modèle de langue n'entre jamais ici — il exécute la conversation,
/// il ne choisit pas le programme.
enum SessionOrchestrator {

    /// Le plafond absolu de mots nouveaux par séance. Invariant dur : aucune
    /// branche du code ne doit pouvoir le dépasser (A02).
    static let maxNewItemsPerSession = 3

    /// La recette par durée, telle que le dossier V2 la fixe.
    struct Recipe {
        let newItemBudget: Int
        let recallSeconds: Int
        let recapSeconds: Int
        /// Vrai quand la durée laisse la place à une conversation libre.
        let allowsFreeConversation: Bool

        static func forDuration(_ minutes: Int) -> Recipe {
            switch minutes {
            case ..<10:
                // Cinq minutes : rien de neuf par défaut, écoute et rappel léger.
                return Recipe(newItemBudget: 0, recallSeconds: 0, recapSeconds: 30, allowsFreeConversation: false)
            case 10..<15:
                return Recipe(newItemBudget: 2, recallSeconds: 90, recapSeconds: 60, allowsFreeConversation: false)
            case 15..<20:
                return Recipe(newItemBudget: 3, recallSeconds: 120, recapSeconds: 120, allowsFreeConversation: true)
            default:
                return Recipe(newItemBudget: 3, recallSeconds: 150, recapSeconds: 120, allowsFreeConversation: true)
            }
        }
    }

    /// Les durées proposées à l'accueil.
    static let offeredDurations = [5, 10, 15, 20]

    // MARK: - Construction

    /// Compose la séance du jour.
    ///
    /// L'ordre est toujours le même : la reprise d'erreur d'abord si elle est
    /// due, puis le rappel, puis le contenu, puis le récapitulatif. Rien de
    /// neuf après le rappel final.
    static func buildPlan(
        mode: SessionMode,
        durationMinutes: Int,
        state: LearnerState,
        library: ContentLibrary,
        tutorID: String,
        now: Date = Date()
    ) -> SessionPlan {
        let sessionID = UUID()
        let recipe = Recipe.forDuration(durationMinutes)
        var phases: [SessionPhase] = []
        var cursor = state.cursor
        var handled: [String] = []

        // 1. Reprise d'une erreur répétée. Bornée à une minute pour qu'elle ne
        //    prenne jamais la leçon en otage (A15).
        if mode == .progression || mode == .review, !state.pendingRemediations.isEmpty {
            let patterns = Array(state.pendingRemediations.prefix(2))
            handled = patterns
            phases.append(
                SessionPhase(
                    kind: .remediation,
                    seconds: 60,
                    text: "On reprend une minute ce qui a coincé : \(patterns.joined(separator: ", ")).",
                    patterns: patterns
                )
            )
        }

        switch mode {
        case .progression:
            let content = buildProgression(
                recipe: recipe,
                durationMinutes: durationMinutes,
                state: state,
                library: library,
                cursor: &cursor,
                now: now
            )
            phases.append(contentsOf: content)

        case .review:
            phases.append(contentsOf: buildReview(
                durationMinutes: durationMinutes,
                state: state,
                library: library,
                now: now
            ))

        case .returnTest:
            phases.append(contentsOf: buildReturnTest(state: state, library: library, now: now))

        case .replay:
            phases.append(contentsOf: buildReplay(state: state, library: library))
        }

        // Le récapitulatif ferme toujours la séance, et n'introduit rien.
        let seenToday = phases.filter { $0.kind == .newItem }.flatMap(\.itemIDs)
        phases.append(
            SessionPhase(
                kind: .recap,
                seconds: recipe.recapSeconds,
                itemIDs: seenToday,
                text: "Ce qu'on a vu, ce qui tient, ce qui reviendra."
            )
        )

        return SessionPlan(
            sessionID: sessionID,
            mode: mode,
            durationMinutes: durationMinutes,
            tutorID: tutorID,
            phases: phases,
            cursorBefore: state.cursor,
            cursorAfter: cursor,
            remediationsHandled: handled
        )
    }

    // MARK: - Progression

    private static func buildProgression(
        recipe: Recipe,
        durationMinutes: Int,
        state: LearnerState,
        library: ContentLibrary,
        cursor: inout CurriculumCursor,
        now: Date
    ) -> [SessionPhase] {
        var phases: [SessionPhase] = []
        var budget = min(recipe.newItemBudget, maxNewItemsPerSession)

        // Rappel initial, puisé dans tout l'historique.
        if recipe.recallSeconds > 0 {
            let count = max(3, recipe.recallSeconds / 25)
            let pool = ReviewScheduler.reviewPool(from: state, library: library, count: count, at: now)
            if !pool.isEmpty {
                phases.append(
                    SessionPhase(
                        kind: .recall,
                        seconds: recipe.recallSeconds,
                        itemIDs: pool,
                        text: "Rappel avant d'avancer."
                    )
                )
            }
        }

        // Le programme, entrée par entrée, dans l'ordre de `sequence_no`.
        var seconds = remainingContentSeconds(durationMinutes: durationMinutes, recipe: recipe)
        var guard0 = 0

        while seconds > 0, guard0 < 12, let entry = library.entry(at: cursor.entryIndex) {
            guard0 += 1

            switch entry.kind {
            case .pronunciationBootcamp:
                let cost = min(seconds, 180)
                cursor.entryIndex += 1
                cursor.itemOffset = 0
                phases.append(
                    SessionPhase(
                        kind: .bootcamp,
                        seconds: cost,
                        entryID: entry.id,
                        text: entry.goal,
                        pronunciationFocus: entry.bootcampContent.joined(separator: " · "),
                        cursorAfterPhase: cursor
                    )
                )
                seconds -= cost

            case .newContent:
                guard budget > 0 else {
                    // Plus de place pour du neuf : on s'arrête ici, on ne
                    // remplit pas mécaniquement.
                    seconds = 0
                    continue
                }
                let items = Array(entry.newItems.dropFirst(cursor.itemOffset))
                guard !items.isEmpty else {
                    cursor.entryIndex += 1
                    cursor.itemOffset = 0
                    continue
                }

                // L'annonce d'ouverture, une seule fois par séance.
                if !phases.contains(where: { $0.kind == .opening }) {
                    phases.append(
                        SessionPhase(
                            kind: .opening,
                            seconds: 30,
                            entryID: entry.id,
                            text: entry.openingAnnouncement,
                            grammarFocus: entry.grammarFocus,
                            pronunciationFocus: entry.pronunciationFocus
                        )
                    )
                    seconds -= 30
                }

                let taken = min(budget, items.count)
                let perItem = max(60, seconds / max(1, taken + 1))
                for item in items.prefix(taken) {
                    cursor.itemOffset += 1
                    if cursor.itemOffset >= entry.newItems.count {
                        cursor.entryIndex += 1
                        cursor.itemOffset = 0
                    }
                    phases.append(
                        SessionPhase(
                            kind: .newItem,
                            seconds: perItem,
                            itemIDs: [item.officialKey],
                            entryID: entry.id,
                            text: entry.goal ?? entry.officialTaskAlignment,
                            grammarFocus: entry.grammarFocus,
                            pronunciationFocus: entry.pronunciationFocus,
                            cursorAfterPhase: cursor
                        )
                    )
                    seconds -= perItem
                    budget -= 1
                }

                // Réemploi : guidé, puis semi-guidé, puis libre si la durée le
                // permet et si le niveau suit.
                phases.append(contentsOf: practicePhases(
                    entry: entry,
                    library: library,
                    recipe: recipe,
                    seconds: &seconds
                ))

            case .spacedReview:
                let cost = min(seconds, 240)
                let pool = ReviewScheduler.reviewPool(
                    from: state, library: library, count: max(5, cost / 25), at: now
                )
                cursor.entryIndex += 1
                cursor.itemOffset = 0
                phases.append(
                    SessionPhase(
                        kind: .recall,
                        seconds: cost,
                        itemIDs: pool,
                        entryID: entry.id,
                        text: entry.goal,
                        cursorAfterPhase: cursor
                    )
                )
                seconds -= cost

            case .moduleCheckpoint, .integration:
                let cost = min(seconds, 240)
                let moduleItems = entry.moduleID.map { library.items(inModule: $0) } ?? []
                let known = moduleItems.map(\.officialKey).filter { state.items[$0] != nil }
                cursor.entryIndex += 1
                cursor.itemOffset = 0
                phases.append(
                    SessionPhase(
                        kind: .checkpoint,
                        seconds: cost,
                        itemIDs: known,
                        entryID: entry.id,
                        text: entry.goal ?? entry.title,
                        dialogue: library.dialogue(forModule: entry.moduleID),
                        pronunciationFocus: entry.pronunciationFocus,
                        cursorAfterPhase: cursor
                    )
                )
                seconds -= cost
            }
        }

        // Séance de cinq minutes, ou programme épuisé : de l'écoute plutôt que
        // du remplissage.
        if phases.allSatisfy({ $0.kind == .remediation }) || phases.isEmpty {
            phases.append(contentsOf: listeningFallback(
                state: state, library: library, seconds: durationMinutes * 60 - 30, now: now
            ))
        }

        return phases
    }

    /// Le temps qui reste pour le contenu, une fois le rappel et le
    /// récapitulatif réservés.
    private static func remainingContentSeconds(durationMinutes: Int, recipe: Recipe) -> Int {
        max(0, durationMinutes * 60 - recipe.recallSeconds - recipe.recapSeconds)
    }

    private static func practicePhases(
        entry: CurriculumEntry,
        library: ContentLibrary,
        recipe: Recipe,
        seconds: inout Int
    ) -> [SessionPhase] {
        var phases: [SessionPhase] = []
        guard seconds > 30 else { return phases }

        if let activities = entry.guidedActivities {
            let guidedCost = min(seconds, 60)
            phases.append(
                SessionPhase(
                    kind: .guided,
                    seconds: guidedCost,
                    entryID: entry.id,
                    text: activities.guided,
                    dialogue: entry.sampleDialogue
                )
            )
            seconds -= guidedCost

            if seconds > 45 {
                let semiCost = min(seconds, 60)
                phases.append(
                    SessionPhase(
                        kind: .semiGuided,
                        seconds: semiCost,
                        entryID: entry.id,
                        text: activities.semi
                    )
                )
                seconds -= semiCost
            }

            if recipe.allowsFreeConversation, seconds > 60 {
                let freeCost = min(seconds, 180)
                phases.append(
                    SessionPhase(
                        kind: .free,
                        seconds: freeCost,
                        entryID: entry.id,
                        text: activities.free,
                        dialogue: library.dialogue(forModule: entry.moduleID)
                    )
                )
                seconds -= freeCost
            }
        }
        return phases
    }

    // MARK: - Révision

    private static func buildReview(
        durationMinutes: Int,
        state: LearnerState,
        library: ContentLibrary,
        now: Date
    ) -> [SessionPhase] {
        // Pas de nouveau contenu en révision, jamais.
        let usable = durationMinutes * 60 - 45
        let count = max(5, usable / 30)
        let pool = ReviewScheduler.reviewPool(from: state, library: library, count: count, at: now)
        guard !pool.isEmpty else {
            return listeningFallback(state: state, library: library, seconds: usable, now: now)
        }

        var phases: [SessionPhase] = []
        // Écoute, rappel actif, prononciation, réemploi, mini-conversation :
        // le dossier demande explicitement mieux que des cartes mémoire.
        let listeningIDs = Array(pool.prefix(max(2, pool.count / 4)))
        phases.append(
            SessionPhase(
                kind: .listening,
                seconds: min(usable / 4, 120),
                itemIDs: listeningIDs,
                text: "Écoute d'abord, sans rien dire.",
                dialogue: library.dialogue(forModule: library.item(id: pool[0])?.moduleID),
                listeningSpeed: "normal"
            )
        )
        phases.append(
            SessionPhase(
                kind: .recall,
                seconds: usable / 2,
                itemIDs: pool,
                text: "Rappel actif et prononciation."
            )
        )
        phases.append(
            SessionPhase(
                kind: .free,
                seconds: usable / 4,
                itemIDs: Array(pool.prefix(4)),
                text: "Mini-conversation avec ce qui vient d'être revu.",
                dialogue: library.dialogue(forModule: library.item(id: pool[0])?.moduleID)
            )
        )
        return phases
    }

    // MARK: - Test de retour

    /// Très court, et sautable : c'est ce que le dossier demande après trois
    /// jours d'absence (A11).
    private static func buildReturnTest(
        state: LearnerState,
        library: ContentLibrary,
        now: Date
    ) -> [SessionPhase] {
        let pool = ReviewScheduler.reviewPool(from: state, library: library, count: 5, at: now)
        guard !pool.isEmpty else { return [] }
        return [
            SessionPhase(
                kind: .recall,
                seconds: 120,
                itemIDs: pool,
                text: "Cinq mots, deux minutes, pour voir où on en est."
            )
        ]
    }

    // MARK: - Leçon précédente

    private static func buildReplay(state: LearnerState, library: ContentLibrary) -> [SessionPhase] {
        guard let last = state.lastFinishedSession else { return [] }
        let items = last.newItemIDs + last.reviewedItemIDs
        guard !items.isEmpty else { return [] }
        return [
            SessionPhase(
                kind: .recall,
                seconds: 240,
                itemIDs: items,
                text: "On refait la séance précédente, sans rien ajouter."
            )
        ]
    }

    // MARK: - Repli

    /// Quand il n'y a rien à rappeler ni à apprendre : de l'écoute, à trois
    /// vitesses.
    private static func listeningFallback(
        state: LearnerState,
        library: ContentLibrary,
        seconds: Int,
        now: Date
    ) -> [SessionPhase] {
        let pool = ReviewScheduler.reviewPool(from: state, library: library, count: 6, at: now)
        let moduleID = pool.first.flatMap { library.item(id: $0)?.moduleID } ?? "M01"
        let speed = pool.isEmpty ? "slow" : "normal"
        return [
            SessionPhase(
                kind: .listening,
                seconds: max(60, seconds),
                itemIDs: pool,
                text: "Écoute courte, puis vérification de ce qui a été compris.",
                dialogue: library.dialogue(forModule: moduleID),
                listeningSpeed: speed
            )
        ]
    }

    // MARK: - Adaptation en cours de séance

    /// Réduit le contenu neuf quand le rappel initial s'est mal passé.
    ///
    /// Le dossier est explicite : si le rappel est faible, on descend à un
    /// mot, voire zéro, et on ne remplit pas le temps pour le remplir.
    static func reduceNewItems(in plan: SessionPlan, afterRecallScore score: Double) -> SessionPlan {
        let allowed: Int
        switch score {
        case ..<0.4: allowed = 0
        case ..<0.6: allowed = 1
        default: return plan
        }

        var updated = plan
        var kept = 0
        updated.phases = plan.phases.filter { phase in
            guard phase.kind == .newItem else { return true }
            if kept < allowed {
                kept += 1
                return true
            }
            return false
        }

        // Le curseur ne va pas plus loin que la dernière phase gardée : les
        // mots retirés n'ont pas été vus, ils reviendront la prochaine fois.
        updated.cursorAfter = updated.phases.compactMap(\.cursorAfterPhase).last ?? plan.cursorBefore

        // Si tout le neuf est tombé, on rend le temps à la conversation plutôt
        // qu'à rien.
        if allowed == 0 {
            updated.phases.removeAll { $0.kind == .opening }
        }
        return updated
    }

    /// Vérifie l'invariant dur avant de lancer la séance (A02).
    static func isValid(_ plan: SessionPlan) -> Bool {
        plan.newItemIDs.count <= maxNewItemsPerSession
            && Set(plan.newItemIDs).count == plan.newItemIDs.count
    }
}
