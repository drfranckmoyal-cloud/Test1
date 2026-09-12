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

    /// Ce qui se dit avant la séance, et ce qui se dit une fois finie.
    var openingMessage: String?
    var closingMessage: String?

    /// Vrai quand ce contenu peut être montré au réglage choisi.
    func isVisible(at level: SpoilerLevel) -> Bool { spoilerLevel <= level }
}

/// Le récit d'une séance, pris dans le pack éditorial.
enum NarrativeCatalog {
    static func content(program: ProgramID, sessionIndex: Int) -> NarrativeContent? {
        guard let session = NarrationLibrary.session(program, index: sessionIndex) else { return nil }
        return NarrativeContent(session, program: Catalog.program(program))
    }
}
