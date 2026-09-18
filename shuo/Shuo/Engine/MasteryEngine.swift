import Foundation

/// Une observation faite pendant la séance, sur un mot précis.
///
/// C'est la seule porte d'entrée du modèle apprenant. Le tuteur — scripté ou
/// modèle de langue — peut proposer des notes ; il ne peut pas écrire un
/// statut.
struct Evidence {
    let itemID: String
    let dimension: Dimension
    /// 0 à 1. Au-dessus de `MasteryEngine.successThreshold`, c'est une réussite.
    let score: Double
    var helpLevel: HelpLevel = .none
    var sessionID: UUID
    var at: Date = Date()
    /// Vrai quand l'observation vient d'une séance postérieure à celle qui a
    /// introduit le mot : c'est ce qui fait un rappel *différé*.
    var isDelayedRecall: Bool = false
    /// Vrai en mode révision : seuls ces échecs-là peuvent, répétés, faire
    /// redescendre un statut.
    var isReviewOpportunity: Bool = false
    /// Le ton travaillé, si l'observation en vise un.
    var tone: String?
    /// La famille articulatoire travaillée, le cas échéant.
    var pronunciationPattern: String?
    /// La vitesse d'écoute, pour une observation de compréhension.
    var listeningSpeed: String?
    /// Le point de grammaire mis en jeu.
    var grammarStructure: String?
    /// Une erreur nommée, si elle se répète assez pour mériter un nom.
    var errorPattern: String?
}

/// Le juge. Il applique les règles de maîtrise du dossier V2, et rien d'autre.
///
/// Les trois règles qu'on ne contourne pas :
/// 1. un mot mal prononcé ne passe pas au vert, même compris (A03) ;
/// 2. un échec isolé ne fait jamais redescendre un vert (A05) ;
/// 3. le vert demande des rappels différés sur des séances *différentes*.
enum MasteryEngine {

    // MARK: - Seuils

    /// Au-dessus, une tentative compte comme réussie.
    static let successThreshold = 0.75
    /// Le seuil de prononciation et de tons pour prétendre au vert.
    static let oralGateThreshold = 0.85
    /// En dessous, la prononciation ou le ton renvoient au rouge.
    static let oralFailureThreshold = 0.5
    /// Productions correctes exigées pour un vert durable.
    static let requiredCorrectProductions = 5
    /// Rappels différés exigés, sur des séances distinctes.
    static let requiredDelayedRecalls = 3
    /// Un de plus quand l'item est marqué fragile.
    static let requiredDelayedRecallsWhenFragile = 4
    /// Deux séances d'échec distinctes avant d'autoriser une rétrogradation.
    static let failedSessionsBeforeDowngrade = 2
    /// Le nombre de récurrences qui déclenche une micro-remédiation.
    static let recurrencesBeforeRemediation = 3
    /// On ne garde pas un journal d'erreurs sans fin.
    static let maxErrorSignatures = 8

    // MARK: - Enregistrement

    /// Range une observation, recalcule le statut, et dit si une erreur vient
    /// d'atteindre le seuil de remédiation.
    ///
    /// - Returns: le motif d'erreur à reprendre au début de la prochaine
    ///   séance, s'il y en a un.
    @discardableResult
    static func record(_ evidence: Evidence, into state: inout LearnerState) -> String? {
        var item = state.items[evidence.itemID] ?? ItemState(itemID: evidence.itemID, at: evidence.at)
        if state.items[evidence.itemID] == nil {
            item.introducedInSession = evidence.sessionID
        }

        item.exposures += 1
        item.lastSeenAt = evidence.at
        item.helpLevelLast = evidence.helpLevel

        var dimensionScore = item.dimensions[evidence.dimension] ?? DimensionScore()
        dimensionScore.record(evidence.score)
        item.dimensions[evidence.dimension] = dimensionScore

        let succeeded = evidence.score >= successThreshold && evidence.helpLevel < .model

        if evidence.dimension.isProduction && succeeded {
            item.correctProductions += 1
        }

        // Un rappel ne compte comme différé que s'il tombe dans une autre
        // séance que celle qui a introduit le mot, et une seule fois par séance.
        let isLaterSession = evidence.sessionID != item.introducedInSession
        if evidence.isDelayedRecall, isLaterSession, succeeded,
           !item.delayedRecallSessions.contains(evidence.sessionID) {
            item.delayedRecallSessions.append(evidence.sessionID)
        }

        if evidence.isReviewOpportunity, !succeeded,
           !item.failedReviewSessions.contains(evidence.sessionID) {
            item.failedReviewSessions.append(evidence.sessionID)
        }

        updateFragility(&item, from: evidence, succeeded: succeeded)
        let remediation = recordError(&item, from: evidence)

        item.memoryStrength = ReviewScheduler.updatedStrength(for: item, after: evidence, succeeded: succeeded)
        item.nextReviewAt = ReviewScheduler.nextReview(for: item, from: evidence.at)
        item.status = status(for: item)

        state.items[evidence.itemID] = item
        recordInProfile(evidence, profile: &state.profile)

        if let remediation, !state.pendingRemediations.contains(remediation) {
            state.pendingRemediations.append(remediation)
        }
        return remediation
    }

    // MARK: - Statut

    /// Le statut visible, recalculé depuis les preuves. Jamais posé à la main.
    static func status(for item: ItemState) -> MasteryStatus {
        let pronunciation = item.score(.pronunciation)
        let tone = item.score(.tone)
        let hasOralEvidence = item.evidenceCount(.pronunciation) > 0 || item.evidenceCount(.tone) > 0

        // Rouge : jamais travaillé, solution donnée au dernier essai, ou oral
        // nettement sous le seuil.
        if item.exposures == 0 { return .red }
        if item.helpLevelLast == .answer { return .red }
        if hasOralEvidence && (pronunciation < oralFailureThreshold || tone < oralFailureThreshold) {
            return .red
        }

        // Vert : le verrou oral d'abord — comprendre ne suffit pas (A03).
        let oralGatePassed = pronunciation >= oralGateThreshold
            && tone >= oralGateThreshold
            && item.evidenceCount(.pronunciation) > 0
            && item.evidenceCount(.tone) > 0
        let recallsNeeded = item.isFragile ? requiredDelayedRecallsWhenFragile : requiredDelayedRecalls
        let durable = item.correctProductions >= requiredCorrectProductions
            && item.delayedRecallSessions.count >= recallsNeeded
        let spontaneous = item.score(.spontaneousProduction) >= successThreshold
            && item.evidenceCount(.spontaneousProduction) > 0

        if oralGatePassed && durable && spontaneous && item.memoryStrength >= 0.6 {
            return .green
        }

        // Le reste est orange dès qu'il y a un début de réussite, rouge sinon.
        let understood = item.score(.meaningRecall) >= 0.6
            || item.score(.listeningRecognition) >= 0.6
            || item.score(.guidedProduction) >= 0.6
        return understood ? .orange : .red
    }

    /// Applique une rétrogradation, mais seulement si les échecs se sont
    /// répartis sur des séances distinctes (A05 / A06).
    ///
    /// Un échec isolé se contente d'abîmer la force mémoire et de poser un
    /// drapeau de fragilité — le vert tient.
    static func applyDowngradeIfWarranted(itemID: String, in state: inout LearnerState) {
        guard var item = state.items[itemID] else { return }
        guard item.failedReviewSessions.count >= failedSessionsBeforeDowngrade else { return }

        item.fragilityFlags.insert(.repeatedMiss)
        item.memoryStrength = max(0, item.memoryStrength - 0.25)

        switch item.status {
        case .green:
            item.status = .orange
        case .orange:
            // Le rouge n'arrive qu'après un troisième échec séparé : on ne
            // détruit pas un acquis sur une mauvaise passe.
            if item.failedReviewSessions.count >= failedSessionsBeforeDowngrade + 1 {
                item.status = .red
            }
        case .red:
            break
        }
        item.nextReviewAt = ReviewScheduler.nextReview(for: item, from: Date())
        state.items[itemID] = item
    }

    // MARK: - Verdict de séance

    /// Le verdict affiché au récapitulatif. Plus grossier que le statut, il ne
    /// parle que de ce qui vient de se passer.
    static func verdict(for item: ItemState, helpUsed: HelpLevel) -> SessionVerdict {
        if helpUsed >= .model { return .nonValide }
        let oralOK = item.score(.pronunciation) >= oralGateThreshold
            && item.score(.tone) >= oralGateThreshold
        let produced = item.score(.guidedProduction) >= successThreshold
            || item.score(.spontaneousProduction) >= successThreshold
        let understood = item.score(.meaningRecall) >= successThreshold

        if oralOK && produced && understood && helpUsed == .none { return .valide }
        if produced || understood { return .aConsolider }
        return .nonValide
    }

    // MARK: - Détails

    private static func updateFragility(_ item: inout ItemState, from evidence: Evidence, succeeded: Bool) {
        if evidence.dimension == .tone {
            if evidence.score < oralGateThreshold {
                item.fragilityFlags.insert(.weakTone)
            } else if evidence.score >= oralGateThreshold && item.evidenceCount(.tone) >= 3 {
                item.fragilityFlags.remove(.weakTone)
            }
        }
        if evidence.dimension == .pronunciation {
            if evidence.score < oralGateThreshold {
                item.fragilityFlags.insert(.weakPronunciation)
            } else if evidence.score >= oralGateThreshold && item.evidenceCount(.pronunciation) >= 3 {
                item.fragilityFlags.remove(.weakPronunciation)
            }
        }
        if evidence.helpLevel >= .strongHint {
            item.fragilityFlags.insert(.needsHelp)
        } else if succeeded && evidence.helpLevel == .none {
            item.fragilityFlags.remove(.needsHelp)
        }
    }

    /// Agrège une erreur nommée et signale la troisième récurrence.
    private static func recordError(_ item: inout ItemState, from evidence: Evidence) -> String? {
        guard let pattern = evidence.errorPattern, evidence.score < successThreshold else { return nil }

        if let index = item.errorSignatures.firstIndex(where: { $0.pattern == pattern }) {
            item.errorSignatures[index].occurrences += 1
            item.errorSignatures[index].lastSeenAt = evidence.at
            if item.errorSignatures[index].occurrences >= recurrencesBeforeRemediation,
               !item.errorSignatures[index].remediationScheduled {
                item.errorSignatures[index].remediationScheduled = true
                return pattern
            }
            return nil
        }

        item.errorSignatures.append(
            ErrorSignature(pattern: pattern, occurrences: 1, lastSeenAt: evidence.at)
        )
        // On garde les plus fréquentes, et on jette le reste : un motif vu une
        // fois il y a trois semaines n'apprend plus rien.
        if item.errorSignatures.count > maxErrorSignatures {
            item.errorSignatures.sort {
                ($0.occurrences, $0.lastSeenAt) > ($1.occurrences, $1.lastSeenAt)
            }
            item.errorSignatures.removeLast(item.errorSignatures.count - maxErrorSignatures)
        }
        return nil
    }

    private static func recordInProfile(_ evidence: Evidence, profile: inout GlobalProfile) {
        if let tone = evidence.tone {
            profile.record(evidence.score, tone: tone)
        }
        if let pattern = evidence.pronunciationPattern {
            profile.record(evidence.score, pattern: pattern)
        }
        if let speed = evidence.listeningSpeed {
            profile.record(evidence.score, speed: speed)
        }
        if let structure = evidence.grammarStructure {
            profile.record(evidence.score, structure: structure)
        }
    }
}
