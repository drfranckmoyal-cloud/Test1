import Foundation

/// Ton des messages.
enum MotivationTone: String, Codable, CaseIterable, Identifiable {
    case cash, coach, zen, absurd
    var id: String { rawValue }
    var label: String {
        switch self {
        case .cash: return "Cash"
        case .coach: return "Coach"
        case .zen: return "Zen"
        case .absurd: return "Absurde"
        }
    }
}

/// Un rappel quotidien.
struct Reminder: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    var hour: Int
    var minute: Int
    var isEnabled: Bool = true

    var timeLabel: String { String(format: "%02d : %02d", hour, minute) }

    static let defaults: [Reminder] = [
        Reminder(title: "L'entraînement du matin", hour: 7, minute: 30),
        Reminder(title: "Pense à ta séance", hour: 13, minute: 0),
        Reminder(title: "Dernière ligne droite", hour: 20, minute: 30)
    ]
}

/// Une séance terminée. C'est l'unité d'historique : tout le reste s'en déduit.
struct SessionRecord: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var programID: String
    var sessionIndex: Int
    var stageIndex: Int
    var day: String          // "yyyy-MM-dd"
    var xp: Int
    var reps: Int
    var seconds: Int
    var meters: Int
    /// Ce que la séance a fait gagner en caractéristiques. Sans cette
    /// mémoire, l'effacer ne pouvait pas les rendre : on ne savait pas quoi
    /// retirer. Vide pour les séances enregistrées avant cette correction.
    var statGains: [String: Int] = [:]

    /// Volume réellement réalisé, domaine par domaine. Sans cette mesure, les
    /// prérequis du combat final reposaient sur une division par trois.
    var domainVolume: [String: Int] = [:]
    /// Les domaines travaillés en séance structurée — les seuls qui comptent
    /// pour le standard du combat final.
    var structuredDomains: [String] = []
    /// L'échelon du mouvement utilisé, domaine par domaine. Quatre-vingt-dix
    /// pompes inclinées ne valent pas quatre-vingt-dix pompes au sol.
    var domainLevel: [String: Int] = [:]
    /// Distance parcourue d'une seule traite, en mètres.
    var continuousMeters: Int = 0

    // MARK: Séance abandonnée

    /// Vrai quand la séance a été arrêtée en cours. Elle ne compte pas : pas
    /// d'expérience, pas de caractéristiques, et elle reste à faire dans le
    /// programme. Elle garde seulement une trace, pour qu'on voie ce qui
    /// bloque quand ça se répète.
    var abandoned: Bool = false
    /// Pourquoi la séance s'est arrêtée.
    var abandonReason: String?
    /// Les exercices obligatoires que le pratiquant n'a pas réussi à faire.
    var failedExercises: [String] = []
}

/// Avancement dans un programme.
struct ProgramProgress: Codable, Equatable {
    var completedSessions: Int = 0
    var startedOn: String?
    var finishedOn: String?
    /// Le curseur d'intensité du programme, 1 = ce qui était prévu.
    /// Il monte quand les séances sont jugées faciles, descend quand elles
    /// sont trop dures. C'est lui qui rend le programme adaptatif.
    var intensity: Double = 1.0

    /// Vrai tant qu'aucune séance n'a été faite.
    var notStarted: Bool { completedSessions == 0 }

    // MARK: Nouveau moteur

    /// Résultats des tests de calibration, historisés : un retest ajoute une
    /// mesure, il n'en écrase aucune.
    var calibration: [CalibrationResult] = []
    /// L'échelon atteint dans chaque famille de mouvements.
    var exerciseLevel: [String: Int] = [:]
    /// La variante retenue pour une famille, quand elle diffère de l'échelon.
    var exerciseVariant: [String: String] = [:]
    /// Le dernier mouvement d'adaptation décidé par le moteur.
    var lastMove: AdaptationMove?
    /// Séances consécutives sans progrès mesuré, par famille de mouvements.
    var sessionsWithoutProgress: [String: Int] = [:]
    /// Bloc en cours dans la structure du programme, à partir de 1.
    var blockIndex: Int = 1
    /// Semaine en cours dans le programme, à partir de 1.
    var weekIndex: Int = 1
    /// Blocs déjà validés.
    var completedBlocks: [String] = []
    /// Vrai quand le standard sportif final a été tenu.
    var standardValidated: Bool = false
    /// Les disponibilités déclarées au lancement du programme.
    var availability: TrainingAvailability?
    /// Le calendrier construit à partir de ces disponibilités.
    var schedule: ProgramSchedule?
    /// La calibration à quatre domaines de Saitama.
    var saitama: SaitamaCalibration?
    /// Décharges déjà servies, par index de semaine.
    var deloadWeeksServed: [Int] = []
    /// Microcycles de consolidation insérés avant le combat final.
    var consolidationCycles: Int = 0
    /// Les domaines que le microcycle de consolidation en cours cible.
    /// Vide quand aucune consolidation ne tourne.
    var consolidationDomains: [String] = []
    /// Séances restantes dans le microcycle de consolidation.
    var consolidationRemaining: Int = 0
    /// Le combat final a été gagné.
    var bossDefeated: Bool = false
    /// Expositions consécutives propres par famille : deux ouvrent la
    /// variante suivante.
    var cleanExposures: [String: Int] = [:]
    /// Expositions consécutives dégradées : deux font redescendre d'un cran.
    var poorExposures: [String: Int] = [:]
    /// Familles dont la variante vient de changer : le premier contact se
    /// fait à volume réduit.
    var freshVariants: [String] = []

    /// La dernière mesure d'un test donné.
    func latest(_ testId: String) -> CalibrationResult? {
        calibration.filter { $0.testId == testId }.max { $0.measuredAt < $1.measuredAt }
    }
}

/// Ce que le joueur répond après une séance. C'est la seule mesure
/// d'intensité que l'app puisse obtenir sans matériel : l'effort perçu.
enum SessionFeedback: String, Codable, CaseIterable, Identifiable {
    case tooEasy, easy, right, hard, tooHard, unfinished
    var id: String { rawValue }

    var label: String {
        switch self {
        case .tooEasy: return "Trop facile"
        case .easy: return "Facile"
        case .right: return "Juste ce qu'il faut"
        case .hard: return "Difficile"
        case .tooHard: return "Très difficile"
        case .unfinished: return "Je n'ai pas pu la terminer"
        }
    }

    var icon: String {
        switch self {
        case .tooEasy: return "arrow.up.right.circle.fill"
        case .easy: return "arrow.up.circle"
        case .right: return "checkmark.circle.fill"
        case .hard: return "arrow.down.circle"
        case .tooHard: return "arrow.down.right.circle.fill"
        case .unfinished: return "xmark.circle.fill"
        }
    }

    /// Ce que la réponse fait au curseur d'intensité.
    var adjustment: Double {
        switch self {
        case .tooEasy: return 0.12
        case .easy: return 0.05
        case .right: return 0
        case .hard: return -0.04
        case .tooHard: return -0.09
        case .unfinished: return -0.15
        }
    }

    /// Ce qu'on annonce au joueur.
    var consequence: String {
        switch self {
        case .tooEasy: return "La prochaine montera nettement."
        case .easy: return "La prochaine montera un peu."
        case .right: return "On garde ce rythme."
        case .hard: return "La prochaine s'allégera un peu."
        case .tooHard: return "La prochaine s'allégera nettement."
        case .unfinished: return "On redescend franchement, et on repart de là."
        }
    }
}

/// Une tâche de la quête de pénalité.
struct PenaltyTask: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var target: Int
    var done: Int = 0
    var isComplete: Bool { done >= target }
}

/// La quête qui sauve la série après une séance manquée.
struct PenaltyQuest: Codable, Equatable {
    var issuedDay: String
    var dueDay: String
    var tasks: [PenaltyTask]
    var accepted: Bool = false

    var isComplete: Bool { tasks.allSatisfy { $0.isComplete } }
    var progress: Double {
        guard !tasks.isEmpty else { return 0 }
        let total = tasks.reduce(0.0) { partial, task in
            partial + (task.target > 0 ? min(1.0, Double(task.done) / Double(task.target)) : 1)
        }
        return total / Double(tasks.count)
    }
}

/// Tout ce qui est conservé d'une ouverture à l'autre.
struct PlayerState: Codable {
    var xp: Int = 0
    var stats: [String: Int] = [:]
    var tier: Tier = .novice
    var programs: [String: ProgramProgress] = [:]
    /// Les programmes suivis en parallèle, dans l'ordre où ils ont été pris.
    var activePrograms: [String] = []
    /// Les programmes mis en pause : ils quittent l'accueil mais restent
    /// visibles, en grisé, dans l'onglet des séances, prêts à repartir.
    var pausedPrograms: [String] = []
    var history: [SessionRecord] = []
    var streak: Int = 0
    var bestStreak: Int = 0
    var lastCompletedDay: String?
    var penalty: PenaltyQuest?
    var badges: [String] = []
    var equipment: [String] = []
    var appearance: Appearance = .dark
    var tone: MotivationTone = .absurd
    var reminders: [Reminder] = Reminder.defaults
    var onboarded: Bool = false
    var avatar: AvatarConfig = AvatarConfig()

    // MARK: Nouveau moteur

    /// Les réponses de l'onboarding commun.
    var profile: OnboardingProfile = OnboardingProfile()
    /// La séance laissée ouverte, s'il y en a une. Une séance fractionnable
    /// peut rester ouverte toute la journée, et survivre à la fermeture.
    var openSessions: [OpenSession] = []
    /// Les retours de séance, par identifiant d'enregistrement.
    var reports: [String: SessionReport] = [:]
    /// La collection de vignettes.
    var rewards: RewardInventory = RewardInventory()
    /// Jusqu'où l'on accepte d'être spoilé.
    var spoilerLevel: SpoilerLevel = .anime
    /// L'intervention du héros au début d'une séance.
    var heroPopups: Bool = true
    /// La dernière variante montrée, par héros et par moment, pour ne jamais
    /// servir deux fois de suite la même image.
    var lastHeroVariant: [String: Int] = [:]
    /// Les étapes dont la page d'ouverture a déjà été montrée, sous la forme
    /// « programme.numéro ». Une page d'introduction revue à chaque séance
    /// perdrait tout son sens.
    var stagesSeen: [String] = []
    /// Les variantes qu'il reste à sortir avant de rebattre les cartes. C'est
    /// ce qui garantit que les quatre passent autant, au lieu d'un tirage au
    /// sort qui en répéterait une et en oublierait une autre.
    var heroVariantBag: [String: [Int]] = [:]

    /// Relit une sauvegarde écrite quand un seul programme était suivi.
    init(from decoder: Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        func read<T: Decodable>(_ key: CodingKeys, _ fallback: T) -> T {
            (try? box.decode(T.self, forKey: key)) ?? fallback
        }
        xp = read(.xp, 0)
        stats = read(.stats, [:])
        tier = read(.tier, .novice)
        programs = read(.programs, [:])
        history = read(.history, [])
        streak = read(.streak, 0)
        bestStreak = read(.bestStreak, 0)
        lastCompletedDay = try? box.decode(String.self, forKey: .lastCompletedDay)
        penalty = try? box.decode(PenaltyQuest.self, forKey: .penalty)
        badges = read(.badges, [])
        equipment = read(.equipment, [])
        appearance = read(.appearance, .dark)
        tone = read(.tone, .absurd)
        reminders = read(.reminders, Reminder.defaults)
        onboarded = read(.onboarded, false)
        avatar = read(.avatar, AvatarConfig())
        profile = read(.profile, OnboardingProfile())
        openSessions = read(.openSessions, [])
        reports = read(.reports, [:])
        rewards = read(.rewards, RewardInventory())
        spoilerLevel = read(.spoilerLevel, .anime)
        pausedPrograms = read(.pausedPrograms, [])
        heroPopups = read(.heroPopups, true)
        lastHeroVariant = read(.lastHeroVariant, [:])
        heroVariantBag = read(.heroVariantBag, [:])
        stagesSeen = read(.stagesSeen, [])

        if let many = try? box.decode([String].self, forKey: .activePrograms) {
            activePrograms = many
        } else if let old = try? decoder.container(keyedBy: LegacyKey.self),
                  let single = try? old.decode(String.self, forKey: .activeProgram) {
            activePrograms = [single]          // sauvegarde d'avant le multi-programmes
        } else {
            activePrograms = []
        }
    }

    private enum LegacyKey: String, CodingKey { case activeProgram }

    init() {}

    func stat(_ kind: StatKind) -> Int { stats[kind.rawValue] ?? 0 }
    func progress(_ id: ProgramID) -> ProgramProgress { programs[id.rawValue] ?? ProgramProgress() }
}
