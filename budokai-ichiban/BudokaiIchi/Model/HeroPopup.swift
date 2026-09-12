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

/// Le moment où le héros intervient.
///
/// Les visuels de fin de séance ne sont pas encore produits ; le moteur les
/// attend déjà, et les servira sans une ligne de code de plus le jour où les
/// images seront déposées dans le catalogue.
enum HeroPopupPhase: String, Codable, CaseIterable {
    case sessionStart
    case sessionComplete

    var assetKey: String { self == .sessionStart ? "start" : "complete" }
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
/// La règle est simple et tient en une phrase : jamais deux fois de suite la
/// même, et les quatre passent à peu près autant. Un vrai tirage au sort
/// répéterait une image une fois sur quatre, ce qui se remarque tout de suite.
enum HeroPopupSelector {

    static func next(hero: BudokaiHero,
                     phase: HeroPopupPhase = .sessionStart,
                     excluding last: Int?) -> HeroPopupAsset? {
        let all = HeroPopupLibrary.assets(hero, phase: phase)
        guard !all.isEmpty else { return nil }
        guard all.count > 1 else { return all[0] }

        let candidates = all.filter { $0.variant != last }
        return candidates.randomElement() ?? all[0]
    }
}
