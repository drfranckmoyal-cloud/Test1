import Foundation

/// Les trois mots que l'apprenant peut dire à tout moment.
///
/// Ils sont reconnus en français, parce que c'est la langue dans laquelle on
/// appelle à l'aide quand on est bloqué en chinois.
enum HelpCommand: String, CaseIterable {
    /// Assistance graduée : on demande d'abord ce qui bloque.
    case aide
    /// La solution tout de suite, puis un réemploi.
    case reponse
    /// On suspend et on repasse en mode guidé.
    case arreteToi

    /// Les formes entendues. La reconnaissance vocale ne rend pas toujours les
    /// accents ni les traits d'union.
    var spokenForms: [String] {
        switch self {
        case .aide:
            return ["aide", "aide moi", "aide-moi", "à l'aide", "a l'aide", "help"]
        case .reponse:
            return ["réponse", "reponse", "la réponse", "la reponse", "donne la réponse"]
        case .arreteToi:
            return ["arrête-toi", "arrete toi", "arrête toi", "arrete-toi", "stop", "arrête", "arrete"]
        }
    }

    var label: String {
        switch self {
        case .aide: return "aide"
        case .reponse: return "réponse"
        case .arreteToi: return "arrête-toi"
        }
    }

    /// Repère une commande dans une transcription. La commande doit être
    /// l'essentiel de ce qui a été dit : « je voudrais de l'aide pour manger »
    /// n'est pas un appel à l'aide au milieu d'une phrase chinoise.
    static func detect(in transcript: String) -> HelpCommand? {
        let normalized = transcript
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: ".!?,;"))
        guard normalized.count <= 30 else { return nil }
        for command in allCases where command.spokenForms.contains(normalized) {
            return command
        }
        return nil
    }
}

/// L'état de l'aide sur la tentative en cours.
///
/// L'échelle ne saute pas de barreau : indice, indice appuyé, modèle, solution.
/// `réponse` est le seul raccourci, et il est explicite.
struct HelpLadderState {
    private(set) var level: HelpLevel = .none
    /// Vrai tant que le tuteur n'a pas encore demandé ce qui bloque.
    private(set) var needsBlockingQuestion = true
    /// Vrai quand on doit faire réutiliser après avoir donné la solution.
    private(set) var owesReuse = false

    /// « aide » : on monte d'un cran, et la première fois on demande d'abord
    /// ce qui bloque plutôt que de donner quoi que ce soit.
    mutating func requestGradedHelp() -> HelpStep {
        if needsBlockingQuestion {
            needsBlockingQuestion = false
            return .askWhatBlocks
        }
        level = level.next
        return .give(level)
    }

    /// « réponse » : on saute l'échelle, on donne, puis on fait réutiliser.
    mutating func requestAnswer() -> HelpStep {
        level = .answer
        needsBlockingQuestion = false
        owesReuse = true
        return .give(.answer)
    }

    mutating func reuseHonoured() {
        owesReuse = false
    }

    /// Nouvelle tentative, nouvelle échelle.
    mutating func reset() {
        level = .none
        needsBlockingQuestion = true
        owesReuse = false
    }

    /// Le blocage prolongé ne donne rien : il propose.
    func offerOnProlongedBlock() -> HelpStep {
        .offer
    }
}

/// Ce que le tuteur doit faire à ce cran de l'échelle.
enum HelpStep: Equatable {
    /// Demander ce qui bloque, sans rien donner.
    case askWhatBlocks
    /// Proposer de l'aide, après un silence prolongé.
    case offer
    /// Donner ce que ce niveau autorise.
    case give(HelpLevel)

    var instruction: String {
        switch self {
        case .askWhatBlocks:
            return "Demande ce qui bloque exactement, en une phrase. Ne donne encore rien."
        case .offer:
            return "L'apprenant reste bloqué. Propose de l'aide en une phrase courte, sans la donner d'office."
        case .give(let level):
            switch level {
            case .none:
                return "Laisse l'apprenant essayer."
            case .hint:
                return "Donne un indice léger : le contexte, la première syllabe, rien de plus."
            case .strongHint:
                return "Donne un indice appuyé : la structure de la phrase ou le mot amorcé."
            case .model:
                return "Donne un modèle complet à imiter, puis fais répéter."
            case .answer:
                return "Donne la solution directement, puis fais-la réutiliser dans une phrase."
            }
        }
    }
}
