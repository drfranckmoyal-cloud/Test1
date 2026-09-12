import Foundation

/// Jusqu'où l'on accepte d'être spoilé.
enum SpoilerLevel: String, Codable, CaseIterable, Identifiable, Comparable {
    /// Ce que l'anime a déjà montré.
    case anime
    /// Ce que le manga a publié, au-delà de l'anime.
    case manga
    /// Les révélations majeures.
    case major

    var id: String { rawValue }

    var label: String {
        switch self {
        case .anime: return "Anime seulement"
        case .manga: return "Manga inclus"
        case .major: return "Tout, révélations comprises"
        }
    }

    private var rank: Int {
        switch self {
        case .anime: return 0
        case .manga: return 1
        case .major: return 2
        }
    }

    static func < (lhs: SpoilerLevel, rhs: SpoilerLevel) -> Bool { lhs.rank < rhs.rank }
}

/// La couche narrative d'une séance, tenue **séparée du sport**.
///
/// Rien ici ne doit influencer la prescription : c'est la règle d'ordre du
/// cadrage — sport, puis adaptation, puis narration, puis récompense.
struct NarrativeContent: Identifiable, Codable, Equatable {
    var id: String
    var anime: String
    var character: String

    var arc: String
    /// Place dans la chronologie de l'œuvre, pour ordonner sans se tromper.
    var chronologyIndex: Int

    var narrativeTitle: String
    /// Cinquante à cent mots. Différent à chaque séance.
    var storyRecap: String
    var references: [String] = []

    /// Une citation réelle, courte, vérifiée. Jamais inventée : en cas de
    /// doute, on paraphrase et on laisse ce champ vide.
    var canonicalQuote: String?
    var quoteCharacter: String?

    /// Un texte original Budokai, qui n'est pas une citation de l'œuvre et ne
    /// doit jamais être présenté comme telle.
    var senseiMessage: String?

    var spoilerLevel: SpoilerLevel = .anime

    /// Vrai quand ce contenu peut être montré au réglage choisi.
    func isVisible(at level: SpoilerLevel) -> Bool { spoilerLevel <= level }
}

/// Le catalogue narratif.
///
/// **Vide à dessein.** Le cadrage renvoie l'écriture des récits au livrable 6
/// et interdit d'inventer des citations. La structure est prête, les vues
/// savent l'afficher, et un contenu déposé ici apparaîtra sans toucher au
/// moteur.
enum NarrativeCatalog {
    static var entries: [String: NarrativeContent] = [:]

    /// Le récit d'une séance donnée, s'il a été écrit.
    static func content(program: ProgramID, sessionIndex: Int) -> NarrativeContent? {
        entries["\(program.rawValue)-\(sessionIndex)"]
    }

    static func content(id: String) -> NarrativeContent? { entries[id] }
}
