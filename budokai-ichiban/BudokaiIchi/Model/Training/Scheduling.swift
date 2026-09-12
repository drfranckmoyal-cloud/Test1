import Foundation

// MARK: - Les jours

enum Weekday: Int, Codable, CaseIterable, Identifiable, Comparable {
    case monday = 1, tuesday, wednesday, thursday, friday, saturday, sunday

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .monday: return "Lundi"
        case .tuesday: return "Mardi"
        case .wednesday: return "Mercredi"
        case .thursday: return "Jeudi"
        case .friday: return "Vendredi"
        case .saturday: return "Samedi"
        case .sunday: return "Dimanche"
        }
    }

    var short: String { String(label.prefix(1)) }

    var isWeekend: Bool { self == .saturday || self == .sunday }

    static func < (lhs: Weekday, rhs: Weekday) -> Bool { lhs.rawValue < rhs.rawValue }

    /// Écart en jours jusqu'au jour suivant, en tournant sur la semaine.
    func days(until other: Weekday) -> Int {
        let diff = other.rawValue - rawValue
        return diff > 0 ? diff : diff + 7
    }
}

// MARK: - Ce qu'est une séance dans le calendrier

enum SessionType: String, Codable, CaseIterable, Identifiable {
    case strength, easyEndurance, longEndurance, qualityEndurance
    case speed, power, mobility, recovery, benchmark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .strength: return "Renforcement"
        case .easyEndurance: return "Endurance facile"
        case .longEndurance: return "Sortie longue"
        case .qualityEndurance: return "Course de développement"
        case .speed: return "Vitesse"
        case .power: return "Explosivité"
        case .mobility: return "Mobilité"
        case .recovery: return "Récupération"
        case .benchmark: return "Test"
        }
    }

    /// Une séance dure laisse des traces : le planificateur les espace.
    var isHard: Bool {
        switch self {
        case .strength, .qualityEndurance, .longEndurance, .speed, .power, .benchmark: return true
        case .easyEndurance, .mobility, .recovery: return false
        }
    }
}

enum SessionPriority: String, Codable, CaseIterable {
    case critical, important, optional

    var label: String {
        switch self {
        case .critical: return "Incontournable"
        case .important: return "Importante"
        case .optional: return "Facultative"
        }
    }

    var rank: Int {
        switch self {
        case .critical: return 0
        case .important: return 1
        case .optional: return 2
        }
    }
}

enum LoadCategory: String, Codable, CaseIterable {
    case easy, moderate, hard

    var label: String {
        switch self {
        case .easy: return "Légère"
        case .moderate: return "Modérée"
        case .hard: return "Lourde"
        }
    }
}

/// Ce que le planificateur doit savoir d'une séance pour la placer.
struct SessionSchedulingMetadata: Codable, Equatable, Identifiable {
    var id: String = UUID().uuidString
    var type: SessionType
    var priority: SessionPriority
    var estimatedDurationMinutes: Int
    var loadCategory: LoadCategory
    /// Le libellé affiché, quand il diffère du type.
    var title: String?

    var displayTitle: String { title ?? type.label }
}

// MARK: - Les règles d'un programme

/// Ce qu'un programme exige, quelles que soient les envies du pratiquant.
/// Les préférences ne cassent jamais ces règles.
struct ProgramSchedulingRules: Codable, Equatable {
    var programID: String

    var minimumSessionsPerWeek: Int
    var recommendedSessionsPerWeek: Int
    var maximumStructuredSessionsPerWeek: Int

    var requiredSessionTypes: [SessionType]
    var keySessionsPerWeek: Int
    var requiresLongSession: Bool
    /// Heures de récupération minimales entre deux séances dures.
    var minimumRecoveryBetweenHardSessionsHours: Int?

    /// La semaine type, pour une fréquence donnée. Renvoie nil quand la
    /// fréquence n'est pas admissible.
    var weeklyTemplates: [Int: [SessionSchedulingMetadata]] = [:]

    /// Les fréquences proposées à l'utilisateur.
    var allowedFrequencies: [Int] {
        Array(minimumSessionsPerWeek...maximumStructuredSessionsPerWeek)
    }

    /// La séance clé : celle que le planificateur protège en premier.
    var keySessionType: SessionType? {
        requiresLongSession ? .longEndurance : requiredSessionTypes.first { $0.isHard }
    }

    /// Nombre de jours de récupération à respecter entre deux séances dures.
    var recoveryDays: Int {
        guard let hours = minimumRecoveryBetweenHardSessionsHours else { return 1 }
        return max(1, Int((Double(hours) / 24.0).rounded(.up)))
    }
}

// MARK: - Les disponibilités du pratiquant

struct TrainingAvailability: Codable, Equatable {
    var targetSessionsPerWeek: Int

    var availableWeekdays: [Weekday] = Weekday.allCases
    var blockedWeekdays: [Weekday] = []
    var preferredWeekdays: [Weekday] = []

    var preferredKeySessionDay: Weekday?
    var preferredLongSessionDay: Weekday?

    var defaultSessionMinutes: Int?
    var sessionMinutesByDay: [Int: Int] = [:]

    /// Les jours réellement utilisables : disponibles, et non interdits.
    var usableDays: [Weekday] {
        availableWeekdays.filter { !blockedWeekdays.contains($0) }.sorted()
    }

    func minutes(on day: Weekday) -> Int? {
        sessionMinutesByDay[day.rawValue] ?? defaultSessionMinutes
    }
}

// MARK: - Le catalogue des règles

/// Les règles de planification, programme par programme.
///
/// **Saitama et Naruto seulement.** Ce sont les deux que le chapitre 3.3
/// chiffre. Les sept autres relèvent du livrable 3 : leur absence est un fait,
/// pas un oubli, et l'app continue de tourner sans eux.
enum SchedulingCatalog {

    static func rules(for id: ProgramID) -> ProgramSchedulingRules? {
        switch id {
        case .saitama: return saitama
        case .naruto: return naruto
        default: return nil
        }
    }

    // MARK: Saitama — 4 minimum, 5 recommandé, 5 maximum

    private static let saitama = ProgramSchedulingRules(
        programID: ProgramID.saitama.rawValue,
        minimumSessionsPerWeek: 4,
        recommendedSessionsPerWeek: 5,
        maximumStructuredSessionsPerWeek: 5,
        requiredSessionTypes: [.strength, .qualityEndurance, .longEndurance],
        keySessionsPerWeek: 1,
        requiresLongSession: true,
        minimumRecoveryBetweenHardSessionsHours: 48,
        weeklyTemplates: [
            5: [
                .init(type: .strength, priority: .critical, estimatedDurationMinutes: 45,
                      loadCategory: .hard, title: "Force A"),
                .init(type: .easyEndurance, priority: .optional, estimatedDurationMinutes: 30,
                      loadCategory: .easy, title: "Endurance facile"),
                .init(type: .strength, priority: .critical, estimatedDurationMinutes: 45,
                      loadCategory: .hard, title: "Force B / routine"),
                .init(type: .qualityEndurance, priority: .important, estimatedDurationMinutes: 40,
                      loadCategory: .moderate, title: "Course de développement"),
                .init(type: .longEndurance, priority: .critical, estimatedDurationMinutes: 60,
                      loadCategory: .hard, title: "Sortie longue")
            ],
            4: [
                .init(type: .strength, priority: .critical, estimatedDurationMinutes: 45,
                      loadCategory: .hard, title: "Force A"),
                .init(type: .qualityEndurance, priority: .important, estimatedDurationMinutes: 40,
                      loadCategory: .moderate, title: "Course de développement"),
                .init(type: .strength, priority: .critical, estimatedDurationMinutes: 45,
                      loadCategory: .hard, title: "Force B / routine"),
                .init(type: .longEndurance, priority: .critical, estimatedDurationMinutes: 60,
                      loadCategory: .hard, title: "Sortie longue")
            ]
        ])

    // MARK: Naruto — 3 minimum, 4 recommandé, 5 maximum

    private static let naruto = ProgramSchedulingRules(
        programID: ProgramID.naruto.rawValue,
        minimumSessionsPerWeek: 3,
        recommendedSessionsPerWeek: 4,
        maximumStructuredSessionsPerWeek: 5,
        requiredSessionTypes: [.easyEndurance, .qualityEndurance, .longEndurance],
        keySessionsPerWeek: 1,
        requiresLongSession: true,
        minimumRecoveryBetweenHardSessionsHours: 48,
        weeklyTemplates: [
            3: [
                .init(type: .easyEndurance, priority: .important, estimatedDurationMinutes: 35,
                      loadCategory: .easy, title: "Endurance facile"),
                .init(type: .qualityEndurance, priority: .important, estimatedDurationMinutes: 40,
                      loadCategory: .hard, title: "Séance spécifique"),
                .init(type: .longEndurance, priority: .critical, estimatedDurationMinutes: 70,
                      loadCategory: .hard, title: "Sortie longue")
            ],
            4: [
                .init(type: .easyEndurance, priority: .important, estimatedDurationMinutes: 35,
                      loadCategory: .easy, title: "Endurance facile"),
                .init(type: .qualityEndurance, priority: .important, estimatedDurationMinutes: 40,
                      loadCategory: .hard, title: "Séance spécifique"),
                .init(type: .recovery, priority: .optional, estimatedDurationMinutes: 30,
                      loadCategory: .easy, title: "Endurance facile ou récupération"),
                .init(type: .longEndurance, priority: .critical, estimatedDurationMinutes: 70,
                      loadCategory: .hard, title: "Sortie longue")
            ],
            // À cinq séances, on ajoute une seconde séance facile — jamais une
            // seconde séance intense.
            5: [
                .init(type: .easyEndurance, priority: .important, estimatedDurationMinutes: 35,
                      loadCategory: .easy, title: "Endurance facile"),
                .init(type: .qualityEndurance, priority: .important, estimatedDurationMinutes: 40,
                      loadCategory: .hard, title: "Séance spécifique"),
                .init(type: .easyEndurance, priority: .optional, estimatedDurationMinutes: 30,
                      loadCategory: .easy, title: "Endurance facile"),
                .init(type: .recovery, priority: .optional, estimatedDurationMinutes: 30,
                      loadCategory: .easy, title: "Récupération"),
                .init(type: .longEndurance, priority: .critical, estimatedDurationMinutes: 70,
                      loadCategory: .hard, title: "Sortie longue")
            ]
        ])
}
