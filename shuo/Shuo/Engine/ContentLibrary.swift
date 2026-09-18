import Foundation

/// Tout le contenu embarqué, chargé une fois et indexé.
///
/// Les fichiers gardent le nom qu'ils portaient dans le dossier de livraison :
/// c'est ce qui permet de retrouver, des mois plus tard, d'où vient une donnée
/// et ce qui relève du programme officiel plutôt que de Shuō.
final class ContentLibrary {

    static let shared = ContentLibrary()

    /// Les 155 entrées, dans l'ordre de `sequence_no`.
    let entries: [CurriculumEntry]
    /// Les 300 mots officiels HSK 1.
    let vocabulary: [VocabItem]
    /// Les 15 modules thématiques et leurs dialogues originaux.
    let modules: [CurriculumModule]
    /// Le périmètre officiel : tâches et points de grammaire.
    let scope: OfficialScope?

    private let vocabByKey: [String: VocabItem]
    private let modulesByID: [String: CurriculumModule]
    private let entriesByID: [String: CurriculumEntry]

    private init() {
        let decoder = JSONDecoder()

        let loadedEntries: [CurriculumEntry] =
            Self.load("04_CURRICULUM_155_ENTRIES_V2", as: [CurriculumEntry].self, decoder) ?? []
        entries = loadedEntries.sorted { $0.sequenceNo < $1.sequenceNo }
        vocabulary = Self.load("02_HSK1_VOCABULARY_300_QA", as: [VocabItem].self, decoder) ?? []
        modules = Self.load("05_MODULES_DIALOGUES", as: [CurriculumModule].self, decoder) ?? []
        scope = Self.load("01_HSK1_OFFICIAL_SCOPE", as: OfficialScope.self, decoder)

        vocabByKey = Dictionary(vocabulary.map { ($0.officialKey, $0) }, uniquingKeysWith: { first, _ in first })
        modulesByID = Dictionary(modules.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        entriesByID = Dictionary(entries.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    }

    private static func load<T: Decodable>(_ name: String, as type: T.Type, _ decoder: JSONDecoder) -> T? {
        guard let url = Bundle.main.url(forResource: name, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            assertionFailure("Contenu manquant dans le bundle : \(name).json")
            return nil
        }
        do {
            return try decoder.decode(type, from: data)
        } catch {
            assertionFailure("Contenu illisible : \(name).json — \(error)")
            return nil
        }
    }

    // MARK: - Accès

    func item(id: String) -> VocabItem? { vocabByKey[id] }
    func module(id: String) -> CurriculumModule? { modulesByID[id] }
    func entry(id: String) -> CurriculumEntry? { entriesByID[id] }

    func items(ids: [String]) -> [VocabItem] { ids.compactMap { vocabByKey[$0] } }

    /// L'entrée à l'index du curseur, s'il est encore dans le programme.
    func entry(at index: Int) -> CurriculumEntry? {
        entries.indices.contains(index) ? entries[index] : nil
    }

    /// Un dialogue du module, choisi sans répéter deux fois le même de suite.
    func dialogue(forModule moduleID: String?, avoiding recent: [String] = []) -> Dialogue? {
        guard let moduleID, let module = modulesByID[moduleID] else { return nil }
        let bank = module.dialogueBank
        guard !bank.isEmpty else { return nil }
        let fresh = bank.filter { !recent.contains($0.zh.joined()) }
        return (fresh.isEmpty ? bank : fresh).randomElement()
    }

    /// Les mots du module, dans l'ordre du programme officiel.
    func items(inModule moduleID: String) -> [VocabItem] {
        vocabulary.filter { $0.moduleID == moduleID }.sorted { $0.officialNo < $1.officialNo }
    }

    /// Les huit étapes de prononciation, dans l'ordre.
    var bootcamp: [CurriculumEntry] {
        entries.filter { $0.kind == .pronunciationBootcamp }
    }

    /// La tâche officielle correspondante, pour situer une séance dans le
    /// programme HSK.
    func officialTasks(ids: [Int]) -> [OfficialTask] {
        guard let scope else { return [] }
        return scope.tasks.filter { ids.contains($0.id) }
    }
}
