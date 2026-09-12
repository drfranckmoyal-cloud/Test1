import Foundation

/// Les chaînes de mouvements de Saitama, chapitre 21 de la spécification.
///
/// Trois familles comptent pour la routine finale — poussée, squat, tronc — et
/// leur dernier échelon est celui du Boss : pompe standard, squat au poids du
/// corps, sit-up contrôlé. Les familles d'assistance ne comptent jamais dans
/// les 100/100/100.
enum SaitamaLibrary {

    // MARK: - Les familles qui comptent

    static let push = ExerciseFamily(
        id: "sai.push", name: "Poussée", function: "Pousser",
        ladder: [
            ex("wallPushUp", "Pompes au mur", 1, "Mains au mur, corps gréé"),
            ex("highInclinePushUp", "Pompes inclinaison haute", 2, "Mains sur un appui à hauteur de hanche"),
            ex("lowInclinePushUp", "Pompes inclinaison basse", 3, "Mains sur une marche ou un banc bas"),
            ex("floorPushUp", "Pompes au sol", 4, "La variante du Boss Final"),
            ex("pausedPushUp", "Pompes avec pause", 5, "Une seconde d'arrêt en bas"),
            ex("declinePushUp", "Pompes déclinées", 6, "Pieds surélevés"),
            ex("archerPushUp", "Pompes archer", 7, "Un bras tendu sur le côté"),
            ex("oneArmProgression", "Progression pompe à une main", 8, "Appui décalé, amplitude partielle")
        ])

    static let squat = ExerciseFamily(
        id: "sai.squat", name: "Squat", function: "Jambes",
        ladder: [
            ex("chairStand", "Assis-debout", 1, "Se lever d'une chaise sans les mains"),
            ex("targetSquat", "Squat avec cible", 2, "Descendre effleurer un appui"),
            ex("bodyweightSquat", "Squat au poids du corps", 3, "La variante du Boss Final"),
            ex("pausedSquat", "Squat avec pause", 4, "Une seconde d'arrêt en bas"),
            ex("splitSquat", "Split squat", 5, "Par jambe"),
            ex("assistedSingleLegSquat", "Squat unilatéral assisté", 6, "Une main en appui")
        ])

    static let core = ExerciseFamily(
        id: "sai.core", name: "Tronc", function: "Abdominaux",
        ladder: [
            ex("deadBug", "Dead bug", 1, "Bas du dos plaqué au sol"),
            ex("curlUp", "Curl-up", 2, "Décoller les omoplates, sans tirer sur la nuque"),
            ex("reverseCrunch", "Reverse crunch", 3, "Genoux ramenés vers la poitrine"),
            ex("partialSitUp", "Sit-up partiel", 4, "Remontée à mi-course"),
            ex("controlledSitUp", "Sit-up contrôlé", 5, "La variante du Boss Final"),
            ex("highVolumeControlledSitUp", "Sit-up contrôlé, gros volume", 6, "Même mouvement, séries longues")
        ])

    /// L'échelon qui fait foi pour le Boss Final, famille par famille.
    static let bossLevels: [String: Int] = [
        "sai.push": 4,   // pompe au sol
        "sai.squat": 3,  // squat au poids du corps
        "sai.core": 5    // sit-up contrôlé
    ]

    // MARK: - L'assistance, qui ne compte pas dans la routine

    static let assistance: [Exercise] = [
        ex("gluteBridge", "Pont fessier", 1, nil, family: "sai.assist"),
        ex("singleLegBridge", "Pont fessier unilatéral", 2, "Par jambe", family: "sai.assist"),
        ex("hipHinge", "Hip hinge au poids du corps", 3, "Dos neutre, bascule de hanche", family: "sai.assist"),
        ex("calfRaise", "Montées de mollet", 4, nil, family: "sai.assist"),
        ex("assistSplitSquat", "Split squat", 5, "Par jambe", family: "sai.assist")
    ]

    static let scapular: [Exercise] = [
        ex("scapularPushUp", "Scapular push-up", 1, "Amplitude d'omoplate seule", family: "sai.scap"),
        ex("reverseSnowAngel", "Reverse snow angel", 2, "Bras au sol, à plat ventre", family: "sai.scap"),
        ex("proneYTW", "Y-T-W à plat ventre", 3, nil, family: "sai.scap")
    ]

    // MARK: - Accès

    static let families: [ExerciseFamily] = [push, squat, core]

    static func family(_ id: String) -> ExerciseFamily? {
        families.first { $0.id == id }
    }

    static func exercise(_ id: String) -> Exercise? {
        (families.flatMap(\.ladder) + assistance + scapular).first { $0.id == id }
    }

    /// Le mouvement d'une famille à un échelon donné, borné aux extrêmes.
    static func exercise(family: String, level: Int) -> Exercise? {
        guard let family = self.family(family) else { return nil }
        let clamped = min(max(level, 1), family.ladder.count)
        return family.exercise(atLevel: clamped)
    }

    static func maxLevel(_ familyId: String) -> Int { family(familyId)?.ladder.count ?? 1 }

    private static func ex(_ id: String, _ name: String, _ level: Int, _ detail: String?,
                           family: String = "") -> Exercise {
        let familyId = family.isEmpty ? inferredFamily(id) : family
        return Exercise(id: id, name: name, familyId: familyId, level: level,
                        characteristic: .force, passCriterion: nil, detail: detail)
    }

    private static func inferredFamily(_ id: String) -> String {
        if id.lowercased().contains("push") || id == "oneArmProgression" { return "sai.push" }
        if id.lowercased().contains("squat") || id == "chairStand" { return "sai.squat" }
        return "sai.core"
    }
}

// MARK: - Ce que la calibration mesure

/// Les quatre domaines de Saitama, calibrés séparément.
///
/// C'est le point 1 de la définition de « Saitama terminé » : poussée, jambes,
/// tronc et endurance ont chacun leur niveau, leur variante et leur
/// progression. Rien ne les moyenne.
enum SaitamaDomain: String, Codable, CaseIterable, Identifiable {
    case push, squat, core, endurance
    var id: String { rawValue }

    var label: String {
        switch self {
        case .push: return "Poussée"
        case .squat: return "Jambes"
        case .core: return "Tronc"
        case .endurance: return "Endurance"
        }
    }

    var familyId: String? {
        switch self {
        case .push: return "sai.push"
        case .squat: return "sai.squat"
        case .core: return "sai.core"
        case .endurance: return nil
        }
    }

    var characteristic: TrainingCharacteristic {
        self == .endurance ? .endurance : .force
    }
}

/// Ce que la calibration de Saitama retient, domaine par domaine.
struct SaitamaCalibration: Codable, Equatable {
    /// Échelon retenu dans chaque famille.
    var level: [String: Int] = [:]
    /// Répétitions propres mesurées, à 1–2 RIR.
    var cleanReps: [String: Int] = [:]
    /// Distance parcourue au test de six minutes, en mètres.
    var sixMinuteMeters: Int?
    /// Part du test réellement courue, de 0 à 1.
    var runRatio: Double?
    var measuredAt: Date?

    var isComplete: Bool {
        level["push"] != nil && level["squat"] != nil && level["core"] != nil && sixMinuteMeters != nil
    }

    func level(_ domain: SaitamaDomain) -> Int { level[domain.rawValue] ?? 1 }
    func reps(_ domain: SaitamaDomain) -> Int { cleanReps[domain.rawValue] ?? 8 }

    /// Le mouvement retenu pour un domaine.
    func exercise(_ domain: SaitamaDomain) -> Exercise? {
        guard let family = domain.familyId else { return nil }
        return SaitamaLibrary.exercise(family: family, level: level(domain))
    }
}


extension ExercisePrescription {
    /// Le domaine Saitama auquel cette prescription se rattache, quand elle
    /// compte dans la routine ou l'endurance.
    var saitamaDomain: SaitamaDomain? {
        guard countsTowardAdaptation else { return nil }
        if let id = exerciseId, let exercise = SaitamaLibrary.exercise(id) {
            switch exercise.familyId {
            case "sai.push": return .push
            case "sai.squat": return .squat
            case "sai.core": return .core
            default: return nil
            }
        }
        if characteristic == .endurance { return .endurance }
        return nil
    }
}
