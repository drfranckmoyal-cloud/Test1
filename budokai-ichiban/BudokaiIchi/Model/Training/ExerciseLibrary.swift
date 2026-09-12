import Foundation

/// Un mouvement, situé dans sa famille de progression.
///
/// Le moteur a besoin de savoir, pour chaque mouvement : à quoi il sert, à
/// quel échelon il se trouve, ce qui vient avant, ce qui vient après, et à
/// quelle condition on passe à la suite.
struct Exercise: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var familyId: String
    /// Rang dans la famille, à partir de 1.
    var level: Int
    var characteristic: TrainingCharacteristic

    /// Ce qu'il faut tenir pour passer à l'échelon suivant.
    /// Exprimé dans l'unité du mouvement.
    var passCriterion: PassCriterion?

    var detail: String?

    struct PassCriterion: Codable, Equatable {
        var value: Int
        var unit: ObjectiveUnit
        var sets: Int?
        /// Effort perçu à ne pas dépasser pour que le critère compte.
        var maxRPE: Int?

        var label: String {
            var text = sets.map { "\($0) × \(unit.short(value))" } ?? unit.format(value)
            if let rpe = maxRPE { text += " à \(rpe)/10 ou moins" }
            return text
        }
    }
}

/// Une famille de mouvements, ordonnée du plus accessible au plus exigeant.
struct ExerciseFamily: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    /// La fonction travaillée, en clair : « pousser », « tirer », « jambes ».
    var function: String
    var ladder: [Exercise]

    func exercise(atLevel level: Int) -> Exercise? {
        ladder.first { $0.level == level }
    }
}

/// La bibliothèque des mouvements.
///
/// **Volontairement incomplète.** Le cadrage donne trois chaînes — pompe,
/// traction, pistol — et renvoie le reste au livrable 5. On n'invente pas les
/// autres : la structure les attend, et `families` s'étoffera quand elles
/// arriveront.
enum ExerciseLibrary {

    static let families: [ExerciseFamily] = [pushFamily, pullFamily, legFamily]

    static func family(_ id: String) -> ExerciseFamily? {
        families.first { $0.id == id }
    }

    static func exercise(_ id: String) -> Exercise? {
        families.lazy.flatMap(\.ladder).first { $0.id == id }
    }

    /// Le mouvement d'un cran plus accessible, s'il existe.
    static func easier(than id: String) -> Exercise? {
        guard let current = exercise(id), let family = family(current.familyId) else { return nil }
        return family.exercise(atLevel: current.level - 1)
    }

    /// Le mouvement d'un cran plus exigeant, s'il existe.
    static func harder(than id: String) -> Exercise? {
        guard let current = exercise(id), let family = family(current.familyId) else { return nil }
        return family.exercise(atLevel: current.level + 1)
    }

    // MARK: - Pousser

    /// Chaîne donnée au chapitre 10 du cadrage.
    private static let pushFamily = ExerciseFamily(
        id: "push", name: "Pompes", function: "Pousser",
        ladder: [
            Exercise(id: "push.wall", name: "Pompes au mur", familyId: "push", level: 1,
                     characteristic: .force,
                     passCriterion: .init(value: 15, unit: .reps, sets: 3, maxRPE: 7)),
            Exercise(id: "push.highIncline", name: "Pompes inclinaison haute", familyId: "push", level: 2,
                     characteristic: .force,
                     passCriterion: .init(value: 12, unit: .reps, sets: 3, maxRPE: 7),
                     detail: "Mains sur un appui à hauteur de hanche"),
            Exercise(id: "push.lowIncline", name: "Pompes inclinaison basse", familyId: "push", level: 3,
                     characteristic: .force,
                     passCriterion: .init(value: 12, unit: .reps, sets: 3, maxRPE: 7),
                     detail: "Mains sur un appui bas, une marche par exemple"),
            Exercise(id: "push.floor", name: "Pompes au sol", familyId: "push", level: 4,
                     characteristic: .force,
                     passCriterion: .init(value: 10, unit: .reps, sets: 3, maxRPE: 7)),
            Exercise(id: "push.volume", name: "Pompes, volume supérieur", familyId: "push", level: 5,
                     characteristic: .force,
                     passCriterion: .init(value: 20, unit: .reps, sets: 3, maxRPE: 8)),
            Exercise(id: "push.tempo", name: "Pompes tempo", familyId: "push", level: 6,
                     characteristic: .force,
                     passCriterion: .init(value: 8, unit: .reps, sets: 3, maxRPE: 8),
                     detail: "Descente lente et temps d'arrêt en bas"),
            Exercise(id: "push.decline", name: "Pompes déclinées ou archer", familyId: "push", level: 7,
                     characteristic: .force,
                     passCriterion: .init(value: 8, unit: .reps, sets: 3, maxRPE: 8)),
            Exercise(id: "push.oneArm", name: "Progression pompe à une main", familyId: "push", level: 8,
                     characteristic: .force,
                     passCriterion: .init(value: 1, unit: .reps, sets: 1, maxRPE: 9),
                     detail: "Contrôlée, de chaque côté")
        ])

    // MARK: - Tirer

    private static let pullFamily = ExerciseFamily(
        id: "pull", name: "Tractions", function: "Tirer",
        ladder: [
            Exercise(id: "pull.row", name: "Tirage horizontal", familyId: "pull", level: 1,
                     characteristic: .force,
                     passCriterion: .init(value: 12, unit: .reps, sets: 3, maxRPE: 7),
                     detail: "Corps incliné sous une barre basse ou une table"),
            Exercise(id: "pull.heavyAssist", name: "Traction très assistée", familyId: "pull", level: 2,
                     characteristic: .force,
                     passCriterion: .init(value: 8, unit: .reps, sets: 3, maxRPE: 7)),
            Exercise(id: "pull.assisted", name: "Traction assistée", familyId: "pull", level: 3,
                     characteristic: .force,
                     passCriterion: .init(value: 6, unit: .reps, sets: 3, maxRPE: 7)),
            Exercise(id: "pull.negative", name: "Traction négative", familyId: "pull", level: 4,
                     characteristic: .force,
                     passCriterion: .init(value: 5, unit: .reps, sets: 3, maxRPE: 8),
                     detail: "Descente freinée, cinq secondes"),
            Exercise(id: "pull.strict", name: "Traction stricte", familyId: "pull", level: 5,
                     characteristic: .force,
                     passCriterion: .init(value: 5, unit: .reps, sets: 3, maxRPE: 8)),
            Exercise(id: "pull.volume", name: "Tractions, volume supérieur", familyId: "pull", level: 6,
                     characteristic: .force,
                     passCriterion: .init(value: 8, unit: .reps, sets: 3, maxRPE: 8)),
            Exercise(id: "pull.weighted", name: "Traction lestée", familyId: "pull", level: 7,
                     characteristic: .force,
                     passCriterion: .init(value: 5, unit: .reps, sets: 3, maxRPE: 8))
        ])

    // MARK: - Jambes

    private static let legFamily = ExerciseFamily(
        id: "leg", name: "Squats", function: "Jambes",
        ladder: [
            Exercise(id: "leg.squat", name: "Squat", familyId: "leg", level: 1,
                     characteristic: .force,
                     passCriterion: .init(value: 20, unit: .reps, sets: 3, maxRPE: 7)),
            Exercise(id: "leg.split", name: "Split squat", familyId: "leg", level: 2,
                     characteristic: .force,
                     passCriterion: .init(value: 12, unit: .reps, sets: 3, maxRPE: 7),
                     detail: "Par jambe"),
            Exercise(id: "leg.toSupport", name: "Squat unilatéral vers un support", familyId: "leg", level: 3,
                     characteristic: .force,
                     passCriterion: .init(value: 8, unit: .reps, sets: 3, maxRPE: 8),
                     detail: "Descente sur une chaise, par jambe"),
            Exercise(id: "leg.assistedPistol", name: "Pistol assisté", familyId: "leg", level: 4,
                     characteristic: .force,
                     passCriterion: .init(value: 5, unit: .reps, sets: 3, maxRPE: 8),
                     detail: "Une main en appui"),
            Exercise(id: "leg.pistol", name: "Pistol squat", familyId: "leg", level: 5,
                     characteristic: .force,
                     passCriterion: .init(value: 5, unit: .reps, sets: 2, maxRPE: 8),
                     detail: "Par jambe")
        ])
}
