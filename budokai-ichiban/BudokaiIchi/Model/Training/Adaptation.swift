import Foundation

/// La décision que prend le moteur pour la séance suivante.
///
/// Une seule variable principale bouge à la fois — c'est la règle du chapitre
/// 11 du cadrage. Faire monter le volume *et* la difficulté technique dans le
/// même mouvement, c'est ne plus savoir ce qui a produit l'effet.
enum AdaptationMove: String, Codable, CaseIterable {
    case progressVolume
    case progressLoad
    case progressVariant
    case progressDuration
    case progressDistance
    case shortenRest
    case hold
    case reduceVolume
    case reduceIntensity
    case easierVariant

    var label: String {
        switch self {
        case .progressVolume: return "Plus de volume"
        case .progressLoad: return "Plus de charge"
        case .progressVariant: return "Variante plus exigeante"
        case .progressDuration: return "Plus longtemps"
        case .progressDistance: return "Plus loin"
        case .shortenRest: return "Récupération plus courte"
        case .hold: return "On garde ce niveau"
        case .reduceVolume: return "Moins de volume"
        case .reduceIntensity: return "Moins d'intensité"
        case .easierVariant: return "Variante plus accessible"
        }
    }

    /// Ce qu'on annonce à l'utilisateur, sans lui montrer les coefficients.
    var explanation: String {
        switch self {
        case .progressVolume: return "La séance suivante ajoute du travail."
        case .progressLoad: return "La séance suivante ajoute de la charge."
        case .progressVariant: return "Tu passes au mouvement suivant de la série."
        case .progressDuration: return "La séance suivante dure plus longtemps."
        case .progressDistance: return "La séance suivante va plus loin."
        case .shortenRest: return "Les temps de repos se raccourcissent."
        case .hold: return "Même dosage la prochaine fois : c'est le bon."
        case .reduceVolume: return "La séance suivante s'allège."
        case .reduceIntensity: return "La séance suivante baisse d'intensité."
        case .easierVariant: return "On revient au mouvement précédent, le temps de le maîtriser."
        }
    }

    var isProgression: Bool {
        switch self {
        case .hold, .reduceVolume, .reduceIntensity, .easierVariant: return false
        default: return true
        }
    }
}

/// Ce que le moteur retient d'une séance pour décider de la suivante.
struct AdaptationInput {
    var report: SessionReport
    /// Part du travail prescrit réellement accompli, de 0 à 1.
    var completedRatio: Double
    /// Vrai quand le mouvement principal n'est pas tenu proprement.
    var variantTooHard: Bool = false
    /// Nombre de séances consécutives sans progrès mesuré.
    var sessionsWithoutProgress: Int = 0
}

/// Les règles d'adaptation du cadrage, appliquées telles quelles.
///
/// Elles décident d'un **mouvement**, pas d'un coefficient : c'est la vue qui
/// traduit ensuite ce mouvement en chiffres, exercice par exercice.
enum AdaptationEngine {

    /// Seuil de stagnation au-delà duquel on change de variante plutôt que
    /// d'ajouter du volume.
    static let stagnationLimit = 3

    static func decide(_ input: AdaptationInput) -> AdaptationMove {
        let rpe = input.report.rpe
        let quality = input.report.quality ?? .correct
        let completion = input.report.completion ?? .entirely

        // — Réduction : l'un de ces signaux suffit
        if let rpe = rpe, rpe >= 9 { return .reduceVolume }
        if completion != .entirely || input.completedRatio < 0.85 {
            return input.report.failureReason == .time ? .hold : .reduceVolume
        }
        if quality == .degraded {
            return input.variantTooHard ? .easierVariant : .reduceIntensity
        }

        // — Changement de variante : mouvement non maîtrisé, ou stagnation
        if input.variantTooHard { return .easierVariant }
        if input.sessionsWithoutProgress >= stagnationLimit { return .progressVariant }

        // — Progression : séance terminée, technique bonne, RPE ≤ 7
        if let rpe = rpe, rpe <= 7, quality != .degraded, completion == .entirely {
            return rpe <= 5 ? .progressVariant : .progressVolume
        }

        // — Maintien : RPE 7–8, séance terminée, technique correcte
        return .hold
    }

    /// De combien le pratiquant règle la séance suivante, dans un sens comme
    /// dans l'autre.
    ///
    /// Le moteur décide de la direction ; le pratiquant règle l'ampleur, dans
    /// des bornes. Lui seul sait si la séance était un peu au-dessus ou très
    /// au-dessus. Les mêmes bornes valent pour progresser : cinq pour cent au
    /// minimum, vingt-cinq au maximum, pour qu'un bon jour n'envoie pas le
    /// programme trop loin, ni un mauvais jour ne le vide.
    enum Dose: String, Codable, CaseIterable, Identifiable {
        case gentle
        case asProposed
        case strong

        var id: String { rawValue }

        var label: String {
            switch self {
            case .gentle: return "Un peu"
            case .asProposed: return "Conseillé"
            case .strong: return "Nettement"
            }
        }

        /// L'écart retenu, en pourcentage entier, à partir de celui que le
        /// moteur propose. Jamais moins de 5 %, jamais plus de 25 %, dans un
        /// sens comme dans l'autre.
        func percent(from proposed: Double) -> Int {
            let step = Int((abs(proposed - 1) * 100).rounded())
            guard step > 0 else { return 0 }
            // arrondi au multiple de cinq le plus proche : « −7 % » ne veut
            // rien dire à personne
            func toFive(_ value: Double) -> Int { Int((value / 5).rounded()) * 5 }
            switch self {
            case .gentle: return max(5, toFive(Double(step) / 2))
            case .asProposed: return step
            case .strong: return min(25, toFive(Double(step) * 2))
            }
        }

        func factor(from proposed: Double) -> Double {
            guard proposed != 1 else { return 1 }
            let shift = Double(percent(from: proposed)) / 100
            return proposed > 1 ? 1 + shift : 1 - shift
        }

        /// Les doses réellement distinctes, de la plus douce à la plus
        /// franche. Deux doses qui tombent sur le même chiffre n'occupent
        /// qu'un bouton, et c'est celle du moteur qui le garde : c'est elle
        /// qui doit porter la mention « conseillé ».
        static func choices(for proposed: Double) -> [Dose] {
            var seen = Set<Int>()
            let byPriority: [Dose] = [.asProposed, .gentle, .strong]
            let kept = byPriority.filter { seen.insert($0.percent(from: proposed)).inserted }
            return kept.sorted { $0.percent(from: proposed) < $1.percent(from: proposed) }
        }

        /// Vrai quand il y a vraiment quelque chose à régler.
        static func isAdjustable(_ proposed: Double) -> Bool {
            proposed != 1 && choices(for: proposed).count > 1
        }
    }

    /// Le facteur de volume qu'entraîne un mouvement, pour les prescriptions
    /// qui n'ont pas encore de variante ni de charge à faire bouger.
    ///
    /// C'est le pont avec le curseur d'intensité existant : tant que les
    /// séances n'expriment qu'un volume, c'est sur lui que le moteur agit.
    static func volumeFactor(for move: AdaptationMove) -> Double {
        switch move {
        case .progressVariant, .progressLoad: return 1.00
        case .progressVolume, .progressDuration, .progressDistance: return 1.05
        case .shortenRest, .hold: return 1.00
        case .reduceIntensity: return 0.95
        case .reduceVolume: return 0.90
        case .easierVariant: return 0.85
        }
    }

    /// Le facteur de récupération : raccourcir le repos est une progression à
    /// part entière, sans toucher au volume.
    static func restFactor(for move: AdaptationMove) -> Double {
        switch move {
        case .shortenRest: return 0.90
        case .reduceVolume, .reduceIntensity, .easierVariant: return 1.10
        default: return 1.00
        }
    }
}
