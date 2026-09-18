import Foundation

/// Ce que le tuteur reçoit avant de parler.
///
/// Jamais tout l'historique : un résumé structuré de l'apprenant, la recette
/// de la séance, et une courte fenêtre d'échanges récents. C'est la règle de
/// budget de contexte du dossier.
struct TurnContext {
    /// Le tuteur du jour.
    let tutor: Tutor
    /// La phase en cours et ce qu'elle demande.
    let phase: SessionPhase
    /// Les mots en jeu, avec leur fiche complète.
    let items: [VocabItem]
    /// L'état de ces mots chez l'apprenant, résumé en une ligne chacun.
    let itemSummaries: [String]
    /// Ce que l'apprenant vient de dire, s'il a dit quelque chose.
    let learnerSaid: String?
    /// La consigne d'aide à appliquer, le cas échéant.
    let helpStep: HelpStep?
    /// Les derniers tours, tuteur et apprenant mêlés. Court, volontairement.
    let recentTurns: [Exchange]
    /// Les points faibles transversaux à surveiller.
    let profileNotes: [String]
    /// Le point de langue et le point de son de la séance.
    let grammarFocus: String?
    let pronunciationFocus: String?

    struct Exchange {
        let isTutor: Bool
        let text: String
    }
}

/// Ce que le tuteur répond.
struct TutorTurn {
    /// Ce qui est dit en mandarin, et prononcé.
    var mandarin: String
    /// Ce qui est dit en français : consigne, explication, correction.
    var french: String
    /// Les observations à ranger dans le modèle apprenant. Elles ne décident
    /// de rien toutes seules : `MasteryEngine` garde la main.
    var evidence: [ProposedEvidence]
    /// Vrai quand le tuteur estime que la phase est terminée.
    var phaseComplete: Bool
    /// Une erreur nommée, si elle mérite d'être suivie.
    var errorPattern: String?

    /// Une note proposée par le tuteur, pas encore un verdict.
    struct ProposedEvidence {
        let itemID: String
        let dimension: Dimension
        let score: Double
    }

    static func silent() -> TutorTurn {
        TutorTurn(mandarin: "", french: "", evidence: [], phaseComplete: false, errorPattern: nil)
    }
}

/// La couche d'exécution du tuteur. Interchangeable par construction : le
/// moteur pédagogique ne sait pas qui parle derrière.
protocol TutorBrain {
    /// Le nom affiché dans le badge.
    var displayName: String { get }
    func respond(to context: TurnContext) async throws -> TutorTurn
}

/// Le tuteur local : déterministe, gratuit, hors ligne.
///
/// Il joue les scripts que le programme fournit déjà — annonce d'ouverture,
/// cycle par mot, récapitulatif — et sert de repli quand le réseau ou la clé
/// manquent. Une séance entière tient avec lui seul ; elle est simplement
/// moins souple en conversation libre.
struct ScriptedTutorBrain: TutorBrain {

    let displayName = "Local"

    func respond(to context: TurnContext) async throws -> TutorTurn {
        // L'aide passe avant tout le reste : c'est une demande explicite.
        if let step = context.helpStep {
            return help(step, context: context)
        }

        switch context.phase.kind {
        case .remediation:
            return TutorTurn(
                mandarin: "",
                french: "On reprend une minute : \(context.phase.patterns.joined(separator: ", ")). "
                    + "Écoute, puis répète.",
                evidence: [],
                phaseComplete: false,
                errorPattern: nil
            )

        case .opening:
            return TutorTurn(
                mandarin: "",
                french: context.phase.text ?? "On commence.",
                evidence: [],
                phaseComplete: true,
                errorPattern: nil
            )

        case .newItem:
            guard let item = context.items.first else { return .silent() }
            if let said = context.learnerSaid {
                return assess(said, item: item, dimension: .guidedProduction)
            }
            return TutorTurn(
                mandarin: item.hanzi,
                french: "\(item.hanzi) — \(item.pinyin) — \(item.fr). "
                    + "Écoute, puis répète. Exemple : \(item.exampleZh) (\(item.exampleFr))",
                evidence: [],
                phaseComplete: false,
                errorPattern: nil
            )

        case .recall, .checkpoint:
            guard let item = context.items.first else { return .silent() }
            if let said = context.learnerSaid {
                return assess(said, item: item, dimension: .meaningRecall)
            }
            return TutorTurn(
                mandarin: item.hanzi,
                french: "Comment dit-on « \(item.fr) » ?",
                evidence: [],
                phaseComplete: false,
                errorPattern: nil
            )

        case .bootcamp:
            return TutorTurn(
                mandarin: "",
                french: context.phase.text ?? "Écoute la différence, puis reproduis-la.",
                evidence: [],
                phaseComplete: context.learnerSaid != nil,
                errorPattern: nil
            )

        case .guided, .semiGuided, .free:
            guard let item = context.items.first ?? context.items.last else {
                return TutorTurn(
                    mandarin: context.phase.dialogue?.zh.first ?? "",
                    french: context.phase.text ?? "À toi.",
                    evidence: [],
                    phaseComplete: context.learnerSaid != nil,
                    errorPattern: nil
                )
            }
            if let said = context.learnerSaid {
                return assess(said, item: item, dimension: context.phase.kind == .free
                    ? .spontaneousProduction
                    : .guidedProduction)
            }
            return TutorTurn(
                mandarin: context.phase.dialogue?.zh.first ?? item.exampleZh,
                french: context.phase.text ?? "Réponds avec ce qu'on vient de voir.",
                evidence: [],
                phaseComplete: false,
                errorPattern: nil
            )

        case .listening:
            let dialogue = context.phase.dialogue
            return TutorTurn(
                mandarin: dialogue?.zh.joined(separator: " ") ?? "",
                french: context.phase.text ?? "Écoute d'abord.",
                evidence: [],
                phaseComplete: context.learnerSaid != nil,
                errorPattern: nil
            )

        case .recap:
            return TutorTurn(
                mandarin: "",
                french: recap(context),
                evidence: [],
                phaseComplete: true,
                errorPattern: nil
            )
        }
    }

    // MARK: - Évaluation locale

    /// Une évaluation grossière, mais honnête sur ses limites : elle compare ce
    /// qui a été transcrit au caractère attendu. Elle ne prétend pas juger les
    /// tons — et c'est pour cela qu'elle ne donne jamais la note qui ouvre le
    /// vert toute seule.
    private func assess(_ said: String, item: VocabItem, dimension: Dimension) -> TutorTurn {
        let heard = said.trimmingCharacters(in: .whitespacesAndNewlines)
        let matched = heard.contains(item.hanzi)

        if matched {
            return TutorTurn(
                mandarin: item.hanzi,
                french: "Oui : \(item.hanzi), \(item.pinyin).",
                evidence: [
                    .init(itemID: item.officialKey, dimension: dimension, score: 0.85),
                    // Le tuteur local n'entend pas les tons : il note bas et
                    // laisse le modèle distant, ou une autre séance, trancher.
                    .init(itemID: item.officialKey, dimension: .pronunciation, score: 0.7),
                ],
                phaseComplete: true,
                errorPattern: nil
            )
        }

        return TutorTurn(
            mandarin: item.hanzi,
            french: "Pas encore. C'était \(item.hanzi) — \(item.pinyin) — \(item.fr). Réessaie.",
            evidence: [.init(itemID: item.officialKey, dimension: dimension, score: 0.2)],
            phaseComplete: false,
            errorPattern: "\(item.officialKey) non produit"
        )
    }

    private func help(_ step: HelpStep, context: TurnContext) -> TutorTurn {
        let item = context.items.first
        switch step {
        case .askWhatBlocks:
            return TutorTurn(
                mandarin: "",
                french: "Qu'est-ce qui bloque exactement : le sens, le mot, ou la prononciation ?",
                evidence: [],
                phaseComplete: false,
                errorPattern: nil
            )
        case .offer:
            return TutorTurn(
                mandarin: "",
                french: "Tu veux un coup de main ? Dis « aide ».",
                evidence: [],
                phaseComplete: false,
                errorPattern: nil
            )
        case .give(let level):
            return give(level, item: item)
        }
    }

    /// Chaque barreau de l'échelle donne un peu plus, et jamais plus que ça.
    private func give(_ level: HelpLevel, item: VocabItem?) -> TutorTurn {
        switch level {
        case .none:
            return .silent()

        case .hint:
            return TutorTurn(
                mandarin: "",
                french: item.map { "Ça commence par « \($0.pinyin.prefix(2)) »." } ?? "Pense au contexte.",
                evidence: [],
                phaseComplete: false,
                errorPattern: nil
            )

        case .strongHint:
            return TutorTurn(
                mandarin: "",
                french: item.map { "C'est \($0.pinyin), et ça veut dire « \($0.fr) »." }
                    ?? "Reprends la structure de la phrase.",
                evidence: [],
                phaseComplete: false,
                errorPattern: nil
            )

        case .model:
            return TutorTurn(
                mandarin: item?.exampleZh ?? "",
                french: item.map { "Écoute et répète : \($0.exampleZh) — \($0.exampleFr)" }
                    ?? "Écoute et répète après moi.",
                evidence: [],
                phaseComplete: false,
                errorPattern: nil
            )

        case .answer:
            // La solution est donnée, et notée comme telle : un mot dont on a
            // fourni la réponse ne peut pas passer pour acquis.
            return TutorTurn(
                mandarin: item?.hanzi ?? "",
                french: item.map { "\($0.hanzi) — \($0.pinyin) — \($0.fr). Maintenant réutilise-le dans une phrase." }
                    ?? "Voilà la réponse. Réutilise-la dans une phrase.",
                evidence: item.map { [.init(itemID: $0.officialKey, dimension: .meaningRecall, score: 0.1)] } ?? [],
                phaseComplete: false,
                errorPattern: nil
            )
        }
    }

    private func recap(_ context: TurnContext) -> String {
        guard !context.itemSummaries.isEmpty else {
            return "C'est fini pour aujourd'hui. Rien de neuf, on a consolidé."
        }
        return "Aujourd'hui : " + context.itemSummaries.joined(separator: " ; ")
            + ". Le reste reviendra tout seul en révision."
    }
}
