import Foundation

/// La narration des neuf programmes, telle que le pack éditorial la livre.
///
/// Les fichiers sont embarqués **tels quels** : on ne réécrit ni les récits,
/// ni les messages du maître, ni les citations. L'app ne fait que les lire et
/// les servir dans l'ordre.
enum NarrationLibrary {

    // MARK: - Ce que le pack contient

    /// Une séance narrative, au format du pack.
    struct Session: Codable, Identifiable, Equatable {
        var id: String
        /// L'étape ou le bloc auquel elle appartient.
        var stage: String?
        var chronologyIndex: Int?
        var title: String
        /// Ce qui s'affiche avant la séance.
        var openingMessage: String?
        var storyRecap: String
        var references: [String]?
        var senseiMessage: String?
        /// Ce qui s'affiche une fois la séance finie.
        var closingMessage: String?
        /// Jamais inventée : nulle tant qu'une source n'a pas été vérifiée.
        var canonicalQuote: String?
        var quoteCharacter: String?
    }

    /// Le contenu d'un programme.
    struct Pack: Codable, Equatable {
        var program: String
        var version: String
        var narrativeSessions: [Session]
        /// Servis en rotation quand le moteur allonge un bloc — consolidation,
        /// décharge, prolongation — pour ne pas faire avancer la chronologie
        /// canonique sans raison.
        var dynamicInterludes: [Session]
    }

    // MARK: - Chargement

    private static var cache: [String: Pack] = [:]

    /// Le pack d'un programme, chargé une seule fois.
    static func pack(_ id: ProgramID) -> Pack? {
        if let cached = cache[id.rawValue] { return cached }
        guard let url = Bundle.main.url(forResource: id.rawValue, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let pack = try? JSONDecoder().decode(Pack.self, from: data)
        else { return nil }
        cache[id.rawValue] = pack
        return pack
    }

    // MARK: - Ce que l'app demande

    /// La phrase de contexte d'un jalon : le moment de l'histoire où l'on
    /// s'entraîne, en une phrase.
    ///
    /// Elle n'est pas écrite ici : c'est la première phrase du récit qui ouvre
    /// le jalon, prise telle quelle dans le pack éditorial. L'app ne rédige
    /// rien, elle découpe.
    static func stageContext(_ id: ProgramID, stageIndex: Int) -> String? {
        guard let pack = pack(id) else { return nil }
        // les jalons dans leur ordre d'apparition, sans les dédoublonner par
        // un ensemble qui perdrait l'ordre
        var stages: [String] = []
        for session in pack.narrativeSessions {
            guard let stage = session.stage, !stages.contains(stage) else { continue }
            stages.append(stage)
        }
        guard stageIndex >= 0, stageIndex < stages.count else { return nil }
        let stage = stages[stageIndex]
        guard let opening = pack.narrativeSessions.first(where: { $0.stage == stage })
        else { return nil }
        return firstSentence(of: opening.storyRecap)
    }

    /// La première phrase d'un récit. Le pack sépare le titre du récit par un
    /// deux-points : on garde l'ensemble, qui se lit comme une légende.
    private static func firstSentence(of text: String) -> String {
        var sentence = ""
        var characters = Array(text)
        var index = 0
        while index < characters.count {
            sentence.append(characters[index])
            if characters[index] == "." {
                // « Z-City. » s'arrête ; « M. » ou une décimale, non
                let next = index + 1 < characters.count ? characters[index + 1] : " "
                if next == " " || index == characters.count - 1 { break }
            }
            index += 1
        }
        return sentence.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Le récit d'une séance, dans l'ordre chronologique.
    ///
    /// Au-delà de la banque principale — quand un bloc a été prolongé — on
    /// sert les interludes en rotation, comme le contrat éditorial l'exige.
    static func session(_ id: ProgramID, index: Int) -> Session? {
        guard let pack = pack(id), !pack.narrativeSessions.isEmpty else { return nil }
        if index < pack.narrativeSessions.count { return pack.narrativeSessions[index] }
        guard !pack.dynamicInterludes.isEmpty else { return pack.narrativeSessions.last }
        let overflow = index - pack.narrativeSessions.count
        return pack.dynamicInterludes[overflow % pack.dynamicInterludes.count]
    }

    /// Les séances d'une étape, pour la carte du parcours.
    static func sessions(_ id: ProgramID, stage: String) -> [Session] {
        pack(id)?.narrativeSessions.filter { $0.stage == stage } ?? []
    }

    /// Les étapes nommées par la narration, dans l'ordre d'apparition.
    static func stages(_ id: ProgramID) -> [String] {
        guard let pack = pack(id) else { return [] }
        var seen: [String] = []
        for session in pack.narrativeSessions {
            if let stage = session.stage, !seen.contains(stage) { seen.append(stage) }
        }
        return seen
    }

    static func count(_ id: ProgramID) -> Int { pack(id)?.narrativeSessions.count ?? 0 }
}

// MARK: - Passerelle avec le modèle de l'app

extension NarrativeContent {
    /// Construit le contenu affiché à partir d'une séance du pack.
    init(_ session: NarrationLibrary.Session, program: Program) {
        self.id = session.id
        self.anime = program.universe
        self.character = program.name
        self.arc = session.stage ?? program.family
        self.chronologyIndex = session.chronologyIndex ?? 0
        self.narrativeTitle = session.title
        self.storyRecap = session.storyRecap
        self.references = session.references ?? []
        self.canonicalQuote = session.canonicalQuote
        self.quoteCharacter = session.quoteCharacter
        self.senseiMessage = session.senseiMessage
        self.spoilerLevel = .anime
        self.openingMessage = session.openingMessage
        self.closingMessage = session.closingMessage
    }
}
