import Foundation

/// Un bloc de programme : plusieurs semaines, un arc narratif, un repère
/// sportif à atteindre, une récompense à la sortie.
///
/// Vient se superposer aux « étapes » existantes sans les remplacer : les
/// étapes portent les noms du personnage et l'identité du jeu, les blocs
/// portent la structure sportive.
struct ProgramBlock: Identifiable, Codable, Equatable {
    var id: String
    var index: Int
    var title: String
    var weeks: ClosedRange<Int>
    /// Le repère chiffré de fin de bloc, en clair.
    var benchmark: String?
    /// Vrai quand le bloc se termine par une semaine allégée. La décharge est
    /// rattachée au bloc, pas à un numéro de semaine du calendrier : si le
    /// bloc s'allonge, elle le suit.
    var endsWithDeload: Bool = false
    /// L'identifiant de la vignette débloquée à la sortie du bloc.
    var rewardId: String?
    /// Vrai quand le bloc porte le combat final du programme.
    var isBoss: Bool = false

    var weeksLabel: String {
        weeks.lowerBound == weeks.upperBound
            ? "Semaine \(weeks.lowerBound)"
            : "Semaines \(weeks.lowerBound) à \(weeks.upperBound)"
    }
}

/// La forme d'un programme : blocs, semaines de décharge, fréquence.
struct ProgramStructure: Codable, Equatable {
    var programID: String
    /// Durée de référence pour la fréquence recommandée. **Une estimation**,
    /// jamais une propriété fixe du programme : la durée réelle dépend du
    /// niveau de départ, de la fréquence choisie, des séances manquées et des
    /// blocs de consolidation.
    var nominalWeeks: Int
    var nominalSessionsPerWeek: Int
    /// Les semaines allégées **dans le scénario nominal**. Ce sont des
    /// repères, pas un calendrier : le moteur les déplace quand la durée d'un
    /// bloc évolue.
    var nominalDeloadWeeks: [Int] = []
    var blocks: [ProgramBlock] = []
    /// Le standard sportif qui valide le programme, en clair.
    var finalStandard: String?
    /// Le nom du mode qui s'ouvre après validation.
    var superRankName: String?

    /// Vrai quand cette semaine est allégée dans le scénario nominal.
    func isNominalDeload(week: Int) -> Bool { nominalDeloadWeeks.contains(week) }

    func block(forWeek week: Int) -> ProgramBlock? {
        blocks.first { $0.weeks.contains(week) }
    }

    /// La décharge d'un bloc, rattachée au bloc lui-même.
    func deloadFollows(_ block: ProgramBlock) -> Bool { block.endsWithDeload }
}

/// Les structures connues.
///
/// **Seul Saitama est décrit**, parce que c'est le seul que le cadrage
/// détaille — chapitre 16. Les huit autres relèvent du livrable 3 et ne sont
/// pas inventés ici : `structure(for:)` renvoie simplement `nil`, et l'app
/// continue de fonctionner sur les étapes existantes.
enum ProgramStructures {

    static func structure(for id: ProgramID) -> ProgramStructure? {
        id == .saitama ? saitama : nil
    }

    /// Saitama, programme pilote. Huit blocs. Les dix-sept semaines et les
    /// décharges en 4, 8, 12 et 16 ne valent que pour le scénario nominal à
    /// cinq séances par semaine : la durée réelle est calculée.
    static let saitama = ProgramStructure(
        programID: ProgramID.saitama.rawValue,
        nominalWeeks: 17,
        nominalSessionsPerWeek: 5,
        nominalDeloadWeeks: [4, 8, 12, 16],
        blocks: [
            .init(id: "SAI-B1", index: 1, title: "Le Déclic", weeks: 1...2,
                  benchmark: "20 / 20 / 20 + 2 km", rewardId: "SAI-001"),
            .init(id: "SAI-B2", index: 2, title: "L'Entraînement", weeks: 3...4,
                  benchmark: "30 / 30 / 30 + 3 km", endsWithDeload: true, rewardId: "SAI-002"),
            .init(id: "SAI-B3", index: 3, title: "Le Disciple", weeks: 5...6,
                  benchmark: "40 / 40 / 40 + 4 à 4,5 km", rewardId: "SAI-003"),
            .init(id: "SAI-B4", index: 4, title: "Héros professionnel", weeks: 7...8,
                  benchmark: "50 / 50 / 50 + 5 km", endsWithDeload: true, rewardId: "SAI-004"),
            .init(id: "SAI-B5", index: 5, title: "La Météorite", weeks: 9...10,
                  benchmark: "65 / 65 / 65 + 6,5 km", rewardId: "SAI-005"),
            .init(id: "SAI-B6", index: 6, title: "Justice indomptable", weeks: 11...12,
                  benchmark: "75 / 75 / 75 + 7,5 km", endsWithDeload: true, rewardId: "SAI-006"),
            .init(id: "SAI-B7", index: 7, title: "Conquérant de l'Univers", weeks: 13...14,
                  benchmark: "90 / 90 / 90 + 9 km", rewardId: "SAI-007"),
            .init(id: "SAI-B8", index: 8, title: "Le Plus Fort", weeks: 15...17,
                  benchmark: "100 / 100 / 100 + 10 km continus",
                  endsWithDeload: true, rewardId: "SAI-008", isBoss: true)
        ],
        finalStandard: "100 pompes, 100 abdominaux, 100 squats le même jour, et 10 km d'une seule traite.",
        superRankName: "SERIOUS MODE")

    // MARK: - Le combat final

    /// Ce que doit tenir le combat final d'un programme.
    struct BossFight: Codable, Equatable {
        var programID: String
        var title: String
        /// Les composantes, suivies séparément.
        var components: [Component]
        /// Les capacités récentes qui ouvrent l'accès au combat.
        var entryRequirements: [String]
        /// La vignette de la victoire.
        var rewardId: String?

        struct Component: Identifiable, Codable, Equatable {
            var id: String
            var name: String
            var targetValue: Int
            var unit: ObjectiveUnit
            var policy: CompletionPolicy
        }
    }

    /// Le combat final de Saitama, tel que le chapitre 18 l'arrête : les
    /// répétitions peuvent être fractionnées dans la journée du défi, mais
    /// les dix kilomètres se font en une seule sortie.
    static let saitamaBoss = BossFight(
        programID: ProgramID.saitama.rawValue,
        title: "One Punch Man",
        components: [
            .init(id: "boss.sai.push", name: "Pompes", targetValue: 100, unit: .reps, policy: .dayCumulative),
            .init(id: "boss.sai.abs", name: "Abdominaux", targetValue: 100, unit: .reps, policy: .dayCumulative),
            .init(id: "boss.sai.squat", name: "Squats", targetValue: 100, unit: .reps, policy: .dayCumulative),
            .init(id: "boss.sai.run", name: "Course", targetValue: 10000, unit: .meters, policy: .continuous)
        ],
        entryRequirements: [
            "Environ 90 pompes propres",
            "Environ 90 abdominaux",
            "Environ 90 squats",
            "Environ 9 km courus d'une traite",
            "Une séance combinée significative menée à son terme"
        ],
        rewardId: "SAI-009")

    /// Le combat final de Naruto : un semi-marathon, d'une seule traite.
    /// Sa structure de blocs relève du livrable 3 et n'est pas écrite ici,
    /// mais le standard, lui, est arrêté par le cahier.
    static let narutoBoss = BossFight(
        programID: ProgramID.naruto.rawValue,
        title: "Hokage",
        components: [
            .init(id: "boss.nar.half", name: "Semi-marathon", targetValue: 21100,
                  unit: .meters, policy: .continuous)
        ],
        entryRequirements: [
            "Une sortie longue récente proche de 18 km",
            "Un volume hebdomadaire stable sur plusieurs semaines"
        ],
        rewardId: nil)

    static func boss(for id: ProgramID) -> BossFight? {
        switch id {
        case .saitama: return saitamaBoss
        case .naruto: return narutoBoss
        default: return nil
        }
    }

    /// Le nom du mode qui s'ouvre après validation, quand le cahier le donne.
    static func superRankName(for id: ProgramID) -> String? {
        switch id {
        case .saitama: return "SERIOUS MODE"
        case .naruto: return "MODE BARYON"
        case .rocklee: return "HUITIÈME PORTE"
        case .kenshiro: return "MUSŌ TENSEI"
        case .minato: return "HIRAISHIN"
        case .levi: return "ACKERMAN MODE"
        case .luffy: return "GEAR 5"
        case .goku: return "ULTRA INSTINCT"
        case .ichigo: return nil   // « à préciser » dans le cahier
        }
    }
}
