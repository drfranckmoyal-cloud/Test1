import SwiftUI

/// Les neuf héros, vus comme figures qui s'adressent au joueur.
///
/// Un héros n'est pas un programme : c'est le visage du programme. La
/// distinction compte, parce qu'un même héros pourra un jour parler ailleurs
/// que dans son propre programme.
enum BudokaiHero: String, Codable, CaseIterable, Identifiable {
    case saitama, naruto, goku, rockLee, kenshiro, ichigo, levi, luffy, minato

    var id: String { rawValue }

    /// Le héros d'un programme.
    init?(program: ProgramID) {
        switch program {
        case .saitama: self = .saitama
        case .naruto: self = .naruto
        case .goku: self = .goku
        case .rocklee: self = .rockLee
        case .kenshiro: self = .kenshiro
        case .ichigo: self = .ichigo
        case .levi: self = .levi
        case .luffy: self = .luffy
        case .minato: self = .minato
        }
    }

    /// Le fragment employé dans le nom des images.
    var assetKey: String { self == .rockLee ? "rocklee" : rawValue }

    var displayName: String {
        switch self {
        case .saitama: return "Saitama"
        case .naruto: return "Naruto"
        case .goku: return "Goku"
        case .rockLee: return "Rock Lee"
        case .kenshiro: return "Kenshiro"
        case .ichigo: return "Ichigo"
        case .levi: return "Levi"
        case .luffy: return "Luffy"
        case .minato: return "Minato"
        }
    }
}

/// Le moment où le héros intervient : il lance la séance, puis il revient
/// une fois qu'elle est faite.
enum HeroPopupPhase: String, Codable, CaseIterable {
    case sessionStart
    case sessionComplete

    var assetKey: String { self == .sessionStart ? "start" : "complete" }

    /// Ce qu'un lecteur d'écran annonce. Le texte de la bulle est dans
    /// l'image, donc hors de sa portée.
    func accessibilityLabel(_ hero: BudokaiHero) -> String {
        self == .sessionStart
            ? "\(hero.displayName), début de séance"
            : "\(hero.displayName), fin de séance"
    }
}

/// Ce qu'une intervention salue.
///
/// Les quatre variantes de fin sont des félicitations générales, valables
/// pour n'importe quelle séance terminée. Le moteur n'essaie donc pas de
/// choisir une phrase selon la performance — les phrases sont dans les
/// images. Cette distinction existe pour le jour où des visuels propres au
/// combat final ou au passage de jalon seront produits.
enum HeroPopupContext: String, Codable, CaseIterable {
    case standard
    case milestone
    case bossComplete
    case personalBest
}

/// Un visuel : un héros, un moment, une variante.
///
/// L'image porte déjà le personnage, sa bulle et sa phrase. L'app n'écrit
/// rien par-dessus — c'est une règle du pack, pas une facilité.
struct HeroPopupAsset: Identifiable, Equatable, Codable {
    let hero: BudokaiHero
    let phase: HeroPopupPhase
    let variant: Int

    var id: String { assetName }
    var assetName: String { "hero_\(phase.assetKey)_\(hero.assetKey)_\(variant)" }
}

// MARK: - Le catalogue

/// Les visuels réellement embarqués.
///
/// Le catalogue ne tient aucune liste écrite à la main : il demande au
/// catalogue d'images ce qui existe, et retient la réponse. Déposer quatre
/// nouveaux PNG suffit donc à les rendre disponibles.
enum HeroPopupLibrary {

    /// Au-delà, on considère qu'une série est complète. Large exprès : une
    /// future série de six variantes n'aurait rien à changer ici.
    private static let maxVariants = 12

    private static var cache: [String: [HeroPopupAsset]] = [:]

    static func assets(_ hero: BudokaiHero, phase: HeroPopupPhase) -> [HeroPopupAsset] {
        let key = "\(hero.assetKey).\(phase.assetKey)"
        if let cached = cache[key] { return cached }

        var found: [HeroPopupAsset] = []
        for variant in 1...maxVariants {
            let asset = HeroPopupAsset(hero: hero, phase: phase, variant: variant)
            guard UIImage(named: asset.assetName) != nil else { break }
            found.append(asset)
        }
        cache[key] = found
        return found
    }

    static func hasAssets(_ hero: BudokaiHero, phase: HeroPopupPhase) -> Bool {
        !assets(hero, phase: phase).isEmpty
    }

    /// Charge l'image en mémoire à l'avance, pour que le popup n'attende pas
    /// le décodage du PNG au moment du tap.
    static func preload(_ asset: HeroPopupAsset?) {
        guard let asset = asset else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            _ = UIImage(named: asset.assetName)
        }
    }
}

// MARK: - La rotation

/// Choisit la variante à montrer.
///
/// Un tirage au sort simple répéterait une image une fois sur quatre et en
/// oublierait une autre pendant dix séances — ça se remarque tout de suite.
/// On tire donc dans un **sac** : les quatre variantes y sont mélangées, on
/// les sort une à une, et on ne rebat les cartes qu'une fois le sac vide. Les
/// quatre passent alors exactement autant, et jamais deux fois de suite.
enum HeroPopupSelector {

    /// Ce qui sort du sac, et le sac tel qu'il reste ensuite.
    ///
    /// `bag` est ce qu'il restait à sortir ; `last` la dernière variante
    /// montrée **pour ce moment**, le début et la fin de séance ayant chacun
    /// leur mémoire. Rien n'est conservé ici : c'est à l'appelant de ranger
    /// le sac, pour que le tirage reste sans effet de bord.
    static func draw(hero: BudokaiHero,
                     phase: HeroPopupPhase,
                     bag: [Int],
                     last: Int?) -> (asset: HeroPopupAsset, bag: [Int])? {
        let all = HeroPopupLibrary.assets(hero, phase: phase)
        guard !all.isEmpty else { return nil }
        let variants = all.map(\.variant)

        // on rebat quand le sac est vide, en évitant de recommencer par la
        // variante qui vient de sortir
        var remaining = bag.filter(variants.contains)
        if remaining.isEmpty {
            remaining = variants.shuffled()
            if remaining.count > 1, remaining.first == last {
                remaining.swapAt(0, remaining.count - 1)
            }
        }

        let variant = remaining.removeFirst()
        guard let asset = all.first(where: { $0.variant == variant }) else { return nil }
        return (asset, remaining)
    }
}
