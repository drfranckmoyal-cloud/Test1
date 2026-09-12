import Foundation

// MARK: - Ce qu'on demande une fois pour toutes

/// Les réponses de l'onboarding commun, celui de moins de deux minutes.
///
/// Les données médicales et la douleur sont volontairement absentes : le
/// cadrage les exclut de cette version du moteur.
struct OnboardingProfile: Codable, Equatable {
    /// Séances d'activité par semaine sur les trois derniers mois.
    var weeklyExternalTraining: Int?
    var otherSports: [String] = []
    var availableDaysPerWeek: Int?
    var availableSessionMinutes: Int?
    var equipment: [String] = []
    /// Expérience déclarée dans la qualité physique choisie, de 0 à 3.
    var experienceLevel: Int?
    var mainGoal: String?

    var isAnswered: Bool {
        availableDaysPerWeek != nil && availableSessionMinutes != nil
    }
}

// MARK: - Les tests de calibration

/// Un test de calibration : deux à quatre par programme, au démarrage.
struct CalibrationTest: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var instruction: String
    var unit: ObjectiveUnit
    /// Vrai quand la valeur se mesure sur un temps imposé plutôt que libre.
    var timedSeconds: Int?
}

/// Le résultat d'un test, conservé avec sa date : on historise, on n'écrase
/// pas. Un retest ajoute une mesure, il n'en remplace aucune.
struct CalibrationResult: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var testId: String
    var value: Int
    var unit: ObjectiveUnit
    var measuredAt: Date = Date()
}

/// Les tests connus, programme par programme.
///
/// Ceux de Saitama, Naruto, Rock Lee, Kenshiro, Minato et Levi sont donnés au
/// chapitre 3.2 du cadrage. Ceux d'Ichigo, Luffy et Goku y sont décrits en
/// termes trop généraux pour être encodés sans les inventer : ils restent
/// vides jusqu'au livrable correspondant.
enum CalibrationCatalog {

    static func tests(for program: ProgramID) -> [CalibrationTest] {
        switch program {
        case .saitama:
            return [
                .init(id: "sai.push", name: "Pompes propres",
                      instruction: "Autant de pompes correctes que possible, en gardant une à deux répétitions en réserve.",
                      unit: .reps, timedSeconds: nil),
                .init(id: "sai.squat", name: "Squats propres",
                      instruction: "Autant de squats corrects que possible, une à deux répétitions en réserve.",
                      unit: .reps, timedSeconds: nil),
                .init(id: "sai.core", name: "Test de tronc",
                      instruction: "Gainage ventral tenu, arrêt dès que la position se dégrade.",
                      unit: .seconds, timedSeconds: nil),
                .init(id: "sai.run6", name: "Six minutes",
                      instruction: "Distance parcourue en six minutes, en courant ou en marchant.",
                      unit: .meters, timedSeconds: 360)
            ]
        case .naruto:
            return [
                .init(id: "nar.comfort", name: "Course confortable",
                      instruction: "Combien de temps peux-tu courir sans t'arrêter, sans forcer ?",
                      unit: .seconds, timedSeconds: nil),
                .init(id: "nar.run6", name: "Six minutes",
                      instruction: "Distance parcourue en six minutes.",
                      unit: .meters, timedSeconds: 360),
                .init(id: "nar.frequency", name: "Sorties par semaine",
                      instruction: "Combien de fois cours-tu aujourd'hui, dans une semaine ordinaire ?",
                      unit: .reps, timedSeconds: nil),
                .init(id: "nar.interval", name: "Course et marche",
                      instruction: "Le plus long bloc couru que tu tiennes en alternant avec de la marche.",
                      unit: .seconds, timedSeconds: nil)
            ]
        case .rocklee:
            return [
                .init(id: "lee.calf", name: "Montées de mollet",
                      instruction: "Vingt montées par jambe, pour vérifier que la cheville suit.",
                      unit: .reps, timedSeconds: nil),
                .init(id: "lee.squat", name: "Squats contrôlés",
                      instruction: "Dix squats lents et propres.",
                      unit: .reps, timedSeconds: nil),
                .init(id: "lee.balance", name: "Équilibre sur un pied",
                      instruction: "Tenir trente secondes sur chaque pied.",
                      unit: .seconds, timedSeconds: 30),
                .init(id: "lee.hops", name: "Petits rebonds",
                      instruction: "Rebonds de faible amplitude, réception souple.",
                      unit: .reps, timedSeconds: nil)
            ]
        case .kenshiro:
            return [
                .init(id: "ken.push", name: "Pompes", instruction: "Autant de pompes propres que possible.",
                      unit: .reps, timedSeconds: nil),
                .init(id: "ken.pull", name: "Tractions ou variante",
                      instruction: "Tractions strictes, ou la variante que tu tiens aujourd'hui.",
                      unit: .reps, timedSeconds: nil),
                .init(id: "ken.leg", name: "Squat unilatéral assisté",
                      instruction: "Par jambe, avec l'appui dont tu as besoin.",
                      unit: .reps, timedSeconds: nil),
                .init(id: "ken.core", name: "Gainage court exigeant",
                      instruction: "Tenue maximale en position stricte.",
                      unit: .seconds, timedSeconds: nil)
            ]
        case .minato:
            return [
                .init(id: "min.comfort", name: "Course confortable",
                      instruction: "Durée que tu tiens à allure tranquille.",
                      unit: .seconds, timedSeconds: nil),
                .init(id: "min.accel", name: "Accélération sur 30 m",
                      instruction: "Montée en vitesse progressive, sans départ arrêté violent.",
                      unit: .seconds, timedSeconds: nil),
                .init(id: "min.reference", name: "Chrono de référence",
                      instruction: "Le temps de référence sur la distance choisie.",
                      unit: .seconds, timedSeconds: nil),
                .init(id: "min.recovery", name: "Récupération entre efforts",
                      instruction: "Temps qu'il te faut entre deux accélérations.",
                      unit: .seconds, timedSeconds: nil)
            ]
        case .levi:
            return [
                .init(id: "lev.plank", name: "Gainage antérieur",
                      instruction: "Tenue stricte, arrêt à la première dégradation.",
                      unit: .seconds, timedSeconds: nil),
                .init(id: "lev.side", name: "Gainage latéral",
                      instruction: "De chaque côté.", unit: .seconds, timedSeconds: nil),
                .init(id: "lev.hang", name: "Suspension",
                      instruction: "Suspendu à la barre, bras tendus.", unit: .seconds, timedSeconds: nil),
                .init(id: "lev.pull", name: "Traction ou alternative",
                      instruction: "Tractions strictes, ou la variante accessible.",
                      unit: .reps, timedSeconds: nil)
            ]
        case .ichigo, .luffy, .goku:
            // Le cadrage décrit ces tests en termes trop généraux pour être
            // encodés sans les inventer. Ils attendent leur livrable.
            return []
        }
    }
}
