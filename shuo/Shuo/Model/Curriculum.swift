import Foundation

// Le contenu pédagogique tel qu'il arrive du dossier de livraison HSK 1.
// Ces structures décrivent les fichiers JSON embarqués dans l'app sans rien
// y ajouter : ce que le programme officiel dit reste séparé de ce que Shuō
// écrit autour. `contentStatus`, porté par chaque mot, garde cette frontière
// lisible jusque dans l'app (test d'acceptation A18).

/// Un mot ou une expression du vocabulaire officiel HSK 1.
struct VocabItem: Codable, Identifiable, Hashable {
    let officialNo: Int
    let officialKey: String
    let hanzi: String
    let pinyin: String
    let posOfficialAbbrev: String
    let fr: String
    let moduleID: String
    let hskLevel: Int
    let masteryDimensions: [String]
    let visualCharacterExposure: Bool
    let readingRequiredForOralMastery: Bool
    let exampleZh: String
    let exampleFr: String
    let contentStatus: String
    let readingBlocking: Bool
    let oralFirst: Bool

    /// L'identité d'un item dans tout le modèle apprenant.
    var id: String { officialKey }

    enum CodingKeys: String, CodingKey {
        case officialNo = "official_no"
        case officialKey = "official_key"
        case hanzi
        case pinyin
        case posOfficialAbbrev = "pos_official_abbrev"
        case fr
        case moduleID = "module_id"
        case hskLevel = "hsk_level"
        case masteryDimensions = "mastery_dimensions"
        case visualCharacterExposure = "visual_character_exposure"
        case readingRequiredForOralMastery = "reading_required_for_oral_mastery"
        case exampleZh = "example_zh"
        case exampleFr = "example_fr"
        case contentStatus = "content_status"
        case readingBlocking = "reading_blocking"
        case oralFirst = "oral_first"
    }

    /// La nature grammaticale, en français, pour la carte de mot.
    var posFr: String {
        switch posOfficialAbbrev {
        case "动": return "verbe"
        case "名": return "nom"
        case "代": return "pronom"
        case "形": return "adjectif"
        case "副": return "adverbe"
        case "数": return "numéral"
        case "量": return "classificateur"
        case "介": return "préposition"
        case "连": return "conjonction"
        case "助": return "particule"
        case "叹": return "interjection"
        case "短语": return "expression"
        default: return posOfficialAbbrev
        }
    }

    /// Les items structurants (pronoms, particules, prépositions…) reviennent
    /// plus souvent en révision : ils portent la grammaire, pas seulement du
    /// lexique.
    var isStructural: Bool {
        ["代", "助", "介", "连", "副", "量", "数"].contains(posOfficialAbbrev)
    }
}

/// Un module thématique (M01…M15) avec sa banque de dialogues originaux.
struct CurriculumModule: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let goal: String
    let officialTaskIDs: [Int]
    let newVocabCount: Int
    let newContentSessions: Int
    let grammarFocus: [String]
    let pronunciationFocus: [String]
    let dialogueBank: [Dialogue]

    enum CodingKeys: String, CodingKey {
        case id, title, goal
        case officialTaskIDs = "official_task_ids"
        case newVocabCount = "new_vocab_count"
        case newContentSessions = "new_content_sessions"
        case grammarFocus = "grammar_focus"
        case pronunciationFocus = "pronunciation_focus"
        case dialogueBank = "dialogue_bank"
    }
}

/// Un court dialogue original, en chinois et en français, ligne à ligne.
struct Dialogue: Codable, Hashable {
    let zh: [String]
    let fr: [String]

    /// Les répliques appariées, dans l'ordre.
    var turns: [(zh: String, fr: String)] {
        zip(zh, fr).map { ($0, $1) }
    }
}

/// Ce qu'une entrée du programme demande de faire.
enum EntryKind: String, Codable {
    case pronunciationBootcamp
    case newContent
    case spacedReview
    case moduleCheckpoint
    case integration

    /// Le champ `type` du JSON. Les entrées P n'en portent pas : leur absence
    /// est justement ce qui les désigne.
    init(rawType: String?) {
        switch rawType {
        case "new_content": self = .newContent
        case "spaced_review": self = .spacedReview
        case "module_checkpoint": self = .moduleCheckpoint
        case "integration": self = .integration
        default: self = .pronunciationBootcamp
        }
    }

    var label: String {
        switch self {
        case .pronunciationBootcamp: return "Prononciation"
        case .newContent: return "Nouveau contenu"
        case .spacedReview: return "Révision"
        case .moduleCheckpoint: return "Bilan de module"
        case .integration: return "Intégration"
        }
    }
}

/// Les consignes d'aide, identiques partout, telles que le programme les écrit.
struct HelpRules: Codable, Hashable {
    let aide: String
    let reponse: String
    let arreteToi: String

    enum CodingKeys: String, CodingKey {
        case aide
        case reponse = "réponse"
        case arreteToi = "arrête-toi"
    }
}

/// Les trois paliers de réemploi d'une séance de nouveau contenu.
struct GuidedActivities: Codable, Hashable {
    let guided: String
    let semi: String
    let free: String
}

/// Ce que le programme dit de faire quand la séance dérape dans un sens ou
/// dans l'autre.
struct AdaptiveBranches: Codable, Hashable {
    let easy: String
    let fragile: String
    let blocked: String
    let poorRecallAtStart: String

    enum CodingKeys: String, CodingKey {
        case easy, fragile, blocked
        case poorRecallAtStart = "poor_recall_at_start"
    }
}

/// Une des 155 entrées du programme, dans l'ordre où elles se suivent.
///
/// Les cinq familles d'entrées ne portent pas les mêmes champs — une séance de
/// nouveau contenu en a une vingtaine, un bilan de module cinq. Tout ce qui
/// n'est pas commun est optionnel, et le décodage ne présume rien.
struct CurriculumEntry: Codable, Identifiable, Hashable {
    let id: String
    let kind: EntryKind
    let sequenceNo: Int

    let title: String?
    let goal: String?
    let moduleID: String?
    let moduleTitle: String?
    let officialTaskIDs: [Int]
    let officialTaskAlignment: String?

    /// Les mots introduits. Vide partout sauf en nouveau contenu.
    let newItems: [VocabItem]
    let openingAnnouncement: String?
    let grammarFocus: String?
    let pronunciationFocus: String?
    let lessonFlow: [String]
    let helpRules: HelpRules?
    let guidedActivities: GuidedActivities?
    /// Les activités des entrées R / C / I, qui les listent simplement.
    let activityList: [String]
    let sampleDialogue: Dialogue?
    let adaptiveBranches: AdaptiveBranches?

    /// Les entrées de prononciation P01…P08 : le contenu à travailler et le
    /// critère de validation, en toutes lettres.
    let bootcampContent: [String]
    let bootcampValidation: String?

    enum CodingKeys: String, CodingKey {
        case id, type, title, goal, content, validation, activities
        case sequenceNo = "sequence_no"
        case moduleID = "module_id"
        case moduleTitle = "module_title"
        case officialTaskIDs = "official_task_ids"
        case officialTaskAlignment = "official_task_alignment"
        case newItems = "new_items"
        case openingAnnouncement = "opening_announcement"
        case grammarFocus = "grammar_focus"
        case pronunciationFocus = "pronunciation_focus"
        case lessonFlow = "lesson_flow"
        case helpRules = "help_rules"
        case sampleDialogue = "sample_dialogue"
        case adaptiveBranches = "adaptive_branches"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        kind = EntryKind(rawType: try c.decodeIfPresent(String.self, forKey: .type))
        sequenceNo = try c.decode(Int.self, forKey: .sequenceNo)

        title = try c.decodeIfPresent(String.self, forKey: .title)
        goal = try c.decodeIfPresent(String.self, forKey: .goal)
        moduleID = try c.decodeIfPresent(String.self, forKey: .moduleID)
        moduleTitle = try c.decodeIfPresent(String.self, forKey: .moduleTitle)
        officialTaskIDs = try c.decodeIfPresent([Int].self, forKey: .officialTaskIDs) ?? []
        officialTaskAlignment = try c.decodeIfPresent(String.self, forKey: .officialTaskAlignment)

        newItems = try c.decodeIfPresent([VocabItem].self, forKey: .newItems) ?? []
        openingAnnouncement = try c.decodeIfPresent(String.self, forKey: .openingAnnouncement)
        grammarFocus = try c.decodeIfPresent(String.self, forKey: .grammarFocus)
        lessonFlow = try c.decodeIfPresent([String].self, forKey: .lessonFlow) ?? []
        helpRules = try c.decodeIfPresent(HelpRules.self, forKey: .helpRules)
        sampleDialogue = try c.decodeIfPresent(Dialogue.self, forKey: .sampleDialogue)
        adaptiveBranches = try c.decodeIfPresent(AdaptiveBranches.self, forKey: .adaptiveBranches)

        // `pronunciation_focus` est une chaîne dans les séances et un tableau
        // dans les modules ; ici les deux formes existent selon la famille.
        if let single = try? c.decodeIfPresent(String.self, forKey: .pronunciationFocus) {
            pronunciationFocus = single
        } else if let list = try? c.decodeIfPresent([String].self, forKey: .pronunciationFocus) {
            pronunciationFocus = list.joined(separator: " · ")
        } else {
            pronunciationFocus = nil
        }

        // `activities` : un objet guidé/semi/libre en nouveau contenu, une
        // simple liste ailleurs.
        if let guided = try? c.decodeIfPresent(GuidedActivities.self, forKey: .activities) {
            guidedActivities = guided
            activityList = []
        } else if let list = try? c.decodeIfPresent([String].self, forKey: .activities) {
            guidedActivities = nil
            activityList = list
        } else {
            guidedActivities = nil
            activityList = []
        }

        bootcampContent = (try? c.decodeIfPresent([String].self, forKey: .content)) ?? []
        // `validation` est une chaîne pour P01…P08, un objet pour les séances.
        bootcampValidation = try? c.decodeIfPresent(String.self, forKey: .validation)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(sequenceNo, forKey: .sequenceNo)
        try c.encodeIfPresent(title, forKey: .title)
        try c.encodeIfPresent(goal, forKey: .goal)
        try c.encode(newItems, forKey: .newItems)
    }

    /// Le titre affiché en tête de séance.
    var displayTitle: String {
        if let title { return title }
        if let moduleTitle { return moduleTitle }
        return kind.label
    }
}

/// Une des 15 tâches de communication du programme officiel.
struct OfficialTask: Codable, Identifiable, Hashable {
    let id: Int
    let nameFr: String
    let canDo: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case nameFr = "name_fr"
        case canDo = "can_do"
    }
}

/// Un bloc de grammaire officielle : une catégorie et ce qu'elle contient.
struct GrammarCategory: Codable, Identifiable, Hashable {
    let category: String
    let items: [String]

    var id: String { category }
}

/// Les thèmes officiels, du plus large au plus précis.
struct OfficialTopics: Codable, Hashable {
    let firstLevel: [String]
    let secondLevel: [String]
    let thirdLevel: [String]

    enum CodingKeys: String, CodingKey {
        case firstLevel = "first_level"
        case secondLevel = "second_level"
        case thirdLevel = "third_level"
    }
}

/// Le périmètre officiel HSK 1 : tâches, thèmes, grammaire.
///
/// Rien ici n'est écrit par Shuō : c'est le programme, recopié tel quel, et il
/// sert de référence quand une décision d'implémentation devient ambiguë.
struct OfficialScope: Codable {
    let tasks: [OfficialTask]
    let topics: OfficialTopics
    let grammar: [GrammarCategory]
}
