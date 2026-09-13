import SwiftUI
import UIKit

/// Les illustrations narratives d'un programme, et la façon de les montrer.
///
/// Une même illustration sert à trois endroits, avec trois intensités. Sans
/// cette distinction, l'app deviendrait un catalogue d'images : belle et
/// illisible. Le niveau décide du cadrage, du dégradé et de la place laissée
/// au texte — jamais de l'image elle-même, qui n'est ni recadrée ni retouchée.
enum StageArtworkPresentation: Equatable {
    /// Plein écran ou presque : l'entrée dans une étape, l'en-tête de séance.
    case hero
    /// Un bandeau au-dessus d'une carte : on voit la scène, le texte domine.
    case card
    /// Une pastille dans une liste de jalons.
    case thumbnail

    /// Par où l'image est retenue quand elle déborde de son cadre.
    ///
    /// Les illustrations narratives placent le personnage au tiers bas et la
    /// scène au-dessus. Un cadrage par le haut, qui convenait aux anciennes
    /// images de personnage, décapiterait ici toute la composition.
    var anchor: Alignment {
        switch self {
        case .hero: return .center
        case .card: return .center
        case .thumbnail: return .center
        }
    }

    /// Le dégradé posé sur l'image pour que le texte se détache. Jamais un
    /// voile opaque : l'illustration doit rester lisible.
    var scrim: [Gradient.Stop] {
        switch self {
        case .hero:
            return [.init(color: .black.opacity(0.45), location: 0),
                    .init(color: .black.opacity(0.05), location: 0.28),
                    .init(color: .black.opacity(0.12), location: 0.45),
                    .init(color: .black.opacity(0.62), location: 0.70),
                    .init(color: .black.opacity(0.92), location: 1)]
        case .card:
            return [.init(color: .black.opacity(0.10), location: 0),
                    .init(color: .black.opacity(0.30), location: 0.5),
                    .init(color: .black.opacity(0.78), location: 1)]
        case .thumbnail:
            return [.init(color: .black.opacity(0), location: 0),
                    .init(color: .black.opacity(0.18), location: 1)]
        }
    }
}

// MARK: - La source de vérité

/// Quelles images un programme possède, et sous quel nom.
///
/// Un seul endroit répond à la question. Les vues ne connaissent ni les noms
/// de fichiers ni les numéros d'étape : elles demandent l'illustration d'une
/// étape et reçoivent ce qui existe, ou rien.
enum ProgramVisuals {

    /// Le logo-signature du programme, quand il a été produit.
    ///
    /// À ne pas confondre avec le logo de l'univers (`logoImage`), qui est
    /// celui de l'animé. Celui-ci est l'identité du programme lui-même.
    static func logo(_ id: ProgramID) -> String? {
        named("logo_program_\(id.rawValue)")
    }

    /// L'illustration d'une étape, comptée à partir de zéro.
    static func stage(_ id: ProgramID, index: Int) -> String? {
        named("stage_\(id.rawValue)_\(max(0, index) + 1)")
    }

    /// L'illustration du mode supérieur, quand elle existe.
    static func superRank(_ id: ProgramID) -> String? {
        named("superrank_\(id.rawValue)")
    }

    /// Vrai quand le programme a reçu la direction artistique narrative :
    /// une illustration par jalon et un logo. Les autres gardent l'habillage
    /// existant, sans qu'aucune image ne soit inventée pour eux.
    static func hasNarrativeArt(_ id: ProgramID) -> Bool {
        logo(id) != nil
    }

    private static var cache: [String: Bool] = [:]

    private static func named(_ name: String) -> String? {
        if let known = cache[name] { return known ? name : nil }
        let exists = UIImage(named: name) != nil
        cache[name] = exists
        return exists ? name : nil
    }
}

// MARK: - La vue

/// Une illustration d'étape, posée à l'intensité demandée.
struct StageArtwork: View {
    let name: String
    var presentation: StageArtworkPresentation = .card
    /// Ce qu'un lecteur d'écran annonce. L'image est narrative, pas décorative.
    var label: String?

    var body: some View {
        Color.clear
            .overlay(alignment: presentation.anchor) {
                image
                    .resizable()
                    .scaledToFill()
            }
            .overlay(
                LinearGradient(stops: presentation.scrim,
                               startPoint: .top, endPoint: .bottom)
            )
            .clipped()
            .accessibilityElement()
            .accessibilityLabel(label ?? "")
            .accessibilityHidden(label == nil)
    }

    /// Une pastille n'a pas besoin de deux millions de pixels : elle passe par
    /// une miniature, calculée une fois et gardée. Sans cela, une liste de
    /// jalons décoderait une dizaine d'illustrations pleine résolution d'un
    /// coup, et le défilement s'en ressentirait.
    private var image: Image {
        guard presentation == .thumbnail,
              let small = ThumbnailCache.thumbnail(named: name) else {
            return Image(name)
        }
        return Image(uiImage: small)
    }
}

/// Les miniatures déjà calculées.
enum ThumbnailCache {
    /// Assez grand pour une pastille sur un écran à trois fois la densité.
    private static let side: CGFloat = 180
    private static var cache: [String: UIImage] = [:]

    static func thumbnail(named name: String) -> UIImage? {
        if let known = cache[name] { return known }
        guard let full = UIImage(named: name) else { return nil }
        let scale = UIScreen.main.scale
        let target = CGSize(width: side * scale, height: side * scale)
        let small = full.preparingThumbnail(of: target) ?? full
        cache[name] = small
        return small
    }
}

// MARK: - Le logo d'un programme

/// Le logo-signature, avec son repli en texte.
///
/// Le logo porte l'identité, jamais l'information : le nom du programme reste
/// un vrai texte pour les lecteurs d'écran, et l'app sait se passer de l'image
/// quand elle n'existe pas.
struct ProgramLogo: View {
    let program: Program
    var height: CGFloat = 54
    /// Le repli quand aucun logo n'a été produit pour ce programme.
    var fallbackFont: Font = .display(26)

    var body: some View {
        Group {
            if let name = ProgramVisuals.logo(program.id) {
                Image(name)
                    .resizable()
                    .scaledToFit()
                    .frame(height: height)
                    .shadow(color: .black.opacity(0.45), radius: 10, y: 3)
            } else {
                Text(program.name.uppercased())
                    .font(fallbackFont)
                    .foregroundStyle(Theme.cream)
                    .shadow(color: .black.opacity(0.6), radius: 8, y: 2)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(program.name)
    }
}
