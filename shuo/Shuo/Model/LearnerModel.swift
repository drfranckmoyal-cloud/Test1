import Foundation

// Le modèle apprenant, version V2 du dossier de livraison.
//
// Principe directeur, à ne pas contourner : la maîtrise se prouve par des
// preuves accumulées, jamais par l'avis d'un modèle de langue sur un tour de
// parole. Le tuteur observe et note ; c'est `MasteryEngine` qui décide.

/// Les sept dimensions notées séparément pour chaque mot.
enum Dimension: String, Codable, CaseIterable, Hashable {
    case listeningRecognition = "listening_recognition"
    case meaningRecall = "meaning_recall"
    case guidedProduction = "guided_production"
    case spontaneousProduction = "spontaneous_production"
    case pronunciation
    case tone
    case usage

    var label: String {
        switch self {
        case .listeningRecognition: return "Reconnaissance à l'oreille"
        case .meaningRecall: return "Sens retrouvé"
        case .guidedProduction: return "Production guidée"
        case .spontaneousProduction: return "Production spontanée"
        case .pronunciation: return "Prononciation"
        case .tone: return "Tons"
        case .usage: return "Emploi"
        }
    }

    /// Les deux dimensions qui font barrage au vert.
    var isOralGate: Bool { self == .pronunciation || self == .tone }

    /// Les dimensions qui comptent comme une production.
    var isProduction: Bool {
        self == .guidedProduction || self == .spontaneousProduction
    }
}

/// Un score et le nombre de preuves qui le soutiennent.
struct DimensionScore: Codable, Hashable {
    var score: Double = 0
    var evidenceCount: Int = 0

    enum CodingKeys: String, CodingKey {
        case score
        case evidenceCount = "evidence_count"
    }

    /// Moyenne pondérée par la récence : une preuve récente pèse plus qu'une
    /// ancienne, sans effacer l'historique d'un seul coup.
    mutating func record(_ value: Double) {
        let clamped = min(max(value, 0), 1)
        if evidenceCount == 0 {
            score = clamped
        } else {
            score = score * 0.6 + clamped * 0.4
        }
        evidenceCount += 1
    }
}

/// L'échelle d'aide, du silence à la solution donnée.
enum HelpLevel: String, Codable, CaseIterable, Hashable, Comparable {
    case none
    case hint
    case strongHint = "strong_hint"
    case model
    case answer

    var rank: Int {
        switch self {
        case .none: return 0
        case .hint: return 1
        case .strongHint: return 2
        case .model: return 3
        case .answer: return 4
        }
    }

    static func < (lhs: HelpLevel, rhs: HelpLevel) -> Bool { lhs.rank < rhs.rank }

    /// Le barreau suivant de l'échelle. `answer` est le dernier.
    var next: HelpLevel {
        switch self {
        case .none: return .hint
        case .hint: return .strongHint
        case .strongHint: return .model
        case .model, .answer: return .answer
        }
    }

    var label: String {
        switch self {
        case .none: return "sans aide"
        case .hint: return "indice"
        case .strongHint: return "indice appuyé"
        case .model: return "modèle"
        case .answer: return "réponse donnée"
        }
    }
}

/// Le statut visible d'un mot.
enum MasteryStatus: String, Codable, CaseIterable, Hashable {
    case red
    case orange
    case green

    var label: String {
        switch self {
        case .red: return "à apprendre"
        case .orange: return "à consolider"
        case .green: return "acquis"
        }
    }
}

/// Le verdict d'une séance sur un item, plus grossier que le statut durable.
enum SessionVerdict: String, Codable, Hashable {
    case valide
    case aConsolider
    case nonValide

    var label: String {
        switch self {
        case .valide: return "validé"
        case .aConsolider: return "à consolider"
        case .nonValide: return "non validé"
        }
    }
}

/// Une faiblesse repérée, nommée, et qui doit pouvoir disparaître.
enum FragilityFlag: String, Codable, Hashable {
    case weakTone = "ton fragile"
    case weakPronunciation = "prononciation fragile"
    case needsHelp = "dépend de l'aide"
    case slowRecall = "rappel lent"
    case repeatedMiss = "échecs répétés"
}

/// Une erreur qui revient. Agrégée, bornée : on compte les récurrences, on
/// n'archive pas chaque occurrence.
struct ErrorSignature: Codable, Hashable, Identifiable {
    var pattern: String
    var occurrences: Int
    var lastSeenAt: Date
    /// Vrai une fois la micro-remédiation programmée, pour ne pas la reprogrammer.
    var remediationScheduled: Bool = false

    var id: String { pattern }

    enum CodingKeys: String, CodingKey {
        case pattern, occurrences
        case lastSeenAt = "last_seen_at"
        case remediationScheduled = "remediation_scheduled"
    }
}

/// Tout ce que l'app sait d'un mot pour un apprenant donné.
struct ItemState: Codable, Identifiable, Hashable {
    let itemID: String
    var firstSeenAt: Date
    var lastSeenAt: Date
    var exposures: Int = 0
    var dimensions: [Dimension: DimensionScore] = [:]
    var helpLevelLast: HelpLevel = .none
    var memoryStrength: Double = 0
    var nextReviewAt: Date
    var status: MasteryStatus = .red
    var fragilityFlags: Set<FragilityFlag> = []
    var errorSignatures: [ErrorSignature] = []

    /// Productions correctes et sans aide, tous contextes confondus.
    var correctProductions: Int = 0
    /// Les séances — pas les tentatives — où un rappel différé a réussi.
    var delayedRecallSessions: [UUID] = []
    /// Les séances où un rappel a échoué. Deux séances distinctes ouvrent la
    /// porte à une rétrogradation ; une seule, jamais.
    var failedReviewSessions: [UUID] = []
    /// La séance qui a introduit le mot : un rappel n'est différé que plus tard.
    var introducedInSession: UUID?

    var id: String { itemID }

    enum CodingKeys: String, CodingKey {
        case itemID = "item_id"
        case firstSeenAt = "first_seen_at"
        case lastSeenAt = "last_seen_at"
        case exposures, dimensions, memoryStrength, status
        case helpLevelLast = "help_level_last"
        case nextReviewAt = "next_review_at"
        case fragilityFlags = "fragility_flags"
        case errorSignatures = "error_signatures"
        case correctProductions = "correct_productions"
        case delayedRecallSessions = "delayed_recall_sessions"
        case failedReviewSessions = "failed_review_sessions"
        case introducedInSession = "introduced_in_session"
    }

    init(itemID: String, at date: Date = Date()) {
        self.itemID = itemID
        self.firstSeenAt = date
        self.lastSeenAt = date
        self.nextReviewAt = date
    }

    func score(_ dimension: Dimension) -> Double {
        dimensions[dimension]?.score ?? 0
    }

    func evidenceCount(_ dimension: Dimension) -> Int {
        dimensions[dimension]?.evidenceCount ?? 0
    }

    /// Un item fragile demande un rappel différé de plus avant le vert.
    var isFragile: Bool { !fragilityFlags.isEmpty }
}

/// Le profil transversal : ce qui ne tient pas à un mot mais à l'oreille et à
/// la bouche de l'apprenant.
struct GlobalProfile: Codable, Hashable {
    /// Compréhension par vitesse d'écoute.
    var listeningBySpeed: [String: DimensionScore] = [:]
    /// Un score par ton, ton neutre et sandhi compris.
    var toneProfile: [String: DimensionScore] = [:]
    /// Un score par famille articulatoire (initiales, rétroflexes, j/q/x…).
    var pronunciationPatterns: [String: DimensionScore] = [:]
    /// L'état de chaque point de grammaire rencontré.
    var grammarStructures: [String: DimensionScore] = [:]

    enum CodingKeys: String, CodingKey {
        case listeningBySpeed = "listening_by_speed"
        case toneProfile = "tone_profile"
        case pronunciationPatterns = "pronunciation_patterns"
        case grammarStructures = "grammar_structures"
    }

    static let speeds = ["slow", "normal", "fast_native"]
    static let tones = ["tone1", "tone2", "tone3", "tone4", "neutral", "sandhi"]
    static let patterns = [
        "initials", "finals", "aspiration", "retroflexes", "j_q_x", "u_umlaut", "rhythm",
    ]

    mutating func record(_ value: Double, speed: String) {
        var entry = listeningBySpeed[speed] ?? DimensionScore()
        entry.record(value)
        listeningBySpeed[speed] = entry
    }

    mutating func record(_ value: Double, tone: String) {
        var entry = toneProfile[tone] ?? DimensionScore()
        entry.record(value)
        toneProfile[tone] = entry
    }

    mutating func record(_ value: Double, pattern: String) {
        var entry = pronunciationPatterns[pattern] ?? DimensionScore()
        entry.record(value)
        pronunciationPatterns[pattern] = entry
    }

    mutating func record(_ value: Double, structure: String) {
        var entry = grammarStructures[structure] ?? DimensionScore()
        entry.record(value)
        grammarStructures[structure] = entry
    }
}

/// Une séance terminée, telle qu'elle reste dans l'historique.
struct SessionRecord: Codable, Identifiable, Hashable {
    let id: UUID
    var startedAt: Date
    var endedAt: Date?
    var durationChoice: Int
    var mode: SessionMode
    var tutorID: String
    var newItemIDs: [String]
    var reviewedItemIDs: [String]
    var verdicts: [String: SessionVerdict]
    /// Coût estimé de la séance, en euros.
    var estimatedCostEUR: Double = 0

    enum CodingKeys: String, CodingKey {
        case id, mode, verdicts
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case durationChoice = "duration_choice"
        case tutorID = "tutor_id"
        case newItemIDs = "new_item_ids"
        case reviewedItemIDs = "reviewed_item_ids"
        case estimatedCostEUR = "estimated_cost_eur"
    }

    var isFinished: Bool { endedAt != nil }
}

/// Ce que l'apprenant a choisi de faire aujourd'hui.
enum SessionMode: String, Codable, Hashable {
    /// La progression : le programme avance.
    case progression
    /// La révision : rien de neuf, tout l'historique.
    case review
    /// Le test de retour après une absence.
    case returnTest
    /// Revoir la leçon précédente, sans toucher aux statuts à la hausse.
    case replay

    var label: String {
        switch self {
        case .progression: return "Progression"
        case .review: return "Révision"
        case .returnTest: return "Test de retour"
        case .replay: return "Leçon précédente"
        }
    }
}

/// La position dans le programme : quelle entrée, et quel mot dans l'entrée.
///
/// Une séance de 10 minutes ne consomme pas toujours une entrée entière ;
/// le curseur retient où l'on s'est arrêté, au mot près.
struct CurriculumCursor: Codable, Hashable {
    var entryIndex: Int = 0
    var itemOffset: Int = 0
}

/// L'état complet, celui qu'on écrit sur le disque.
struct LearnerState: Codable {
    var version: Int = 2
    var items: [String: ItemState] = [:]
    var profile = GlobalProfile()
    var cursor = CurriculumCursor()
    var sessions: [SessionRecord] = []
    /// Les erreurs à reprendre au début de la prochaine séance, une minute au plus.
    var pendingRemediations: [String] = []
    /// Le tuteur de la dernière séance, pour faire tourner la rotation.
    var lastTutorID: String?
    /// La séance laissée en plan, s'il y en a une.
    var interruptedSessionID: UUID?

    enum CodingKeys: String, CodingKey {
        case version, items, profile, cursor, sessions
        case pendingRemediations = "pending_remediations"
        case lastTutorID = "last_tutor_id"
        case interruptedSessionID = "interrupted_session_id"
    }

    var lastFinishedSession: SessionRecord? {
        sessions.last { $0.isFinished }
    }

    /// Le nombre de jours depuis la dernière séance terminée.
    func daysSinceLastSession(now: Date = Date()) -> Int? {
        guard let last = lastFinishedSession?.endedAt else { return nil }
        return Calendar.current.dateComponents([.day], from: last, to: now).day
    }

    /// Tous les mots déjà rencontrés, quel que soit leur statut.
    var seenItemIDs: [String] { Array(items.keys) }
}
