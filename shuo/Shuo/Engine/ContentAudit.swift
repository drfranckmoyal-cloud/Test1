import Foundation

/// La vérification du contenu, exécutable depuis l'app.
///
/// Le dossier de livraison est arrivé avec un rapport qualité. Le refaire ici,
/// sur le contenu réellement embarqué, évite la situation classique : un
/// fichier tronqué au moment de la copie, et une app qui enseigne 287 mots au
/// lieu de 300 sans que personne ne le voie. Couvre A01, A02 et A18.
enum ContentAudit {

    struct Result: Identifiable {
        let id: String
        let title: String
        let passed: Bool
        let detail: String
    }

    static func run(library: ContentLibrary = .shared) -> [Result] {
        [
            vocabularyCount(library),
            everyWordTaughtOnce(library),
            noSessionOverThree(library),
            examplesContainTheirWord(library),
            officialScopeStaysDistinct(library),
            curriculumIsComplete(library),
        ]
    }

    /// A01 — les 300 mots officiels sont là, une fois chacun.
    private static func vocabularyCount(_ library: ContentLibrary) -> Result {
        let keys = Set(library.vocabulary.map(\.officialKey))
        let passed = library.vocabulary.count == 300 && keys.count == 300
        return Result(
            id: "A01a",
            title: "300 mots officiels HSK 1",
            passed: passed,
            detail: "\(library.vocabulary.count) entrées, \(keys.count) clés uniques"
        )
    }

    /// A01 — chaque mot est enseigné une fois et une seule dans le programme.
    private static func everyWordTaughtOnce(_ library: ContentLibrary) -> Result {
        var counts: [String: Int] = [:]
        for entry in library.entries where entry.kind == .newContent {
            for item in entry.newItems {
                counts[item.officialKey, default: 0] += 1
            }
        }
        let official = Set(library.vocabulary.map(\.officialKey))
        let taught = Set(counts.keys)
        let missing = official.subtracting(taught)
        let duplicated = counts.filter { $0.value > 1 }.keys

        let passed = missing.isEmpty && duplicated.isEmpty && taught.count == 300
        var detail = "\(taught.count) mots enseignés"
        if !missing.isEmpty { detail += " · manquants : \(missing.sorted().prefix(5).joined(separator: " "))" }
        if !duplicated.isEmpty { detail += " · en double : \(duplicated.sorted().prefix(5).joined(separator: " "))" }
        return Result(id: "A01b", title: "Chaque mot enseigné une seule fois", passed: passed, detail: detail)
    }

    /// A02 — aucune entrée du programme ne dépasse trois mots nouveaux.
    ///
    /// C'est la moitié de l'invariant ; l'autre moitié est vérifiée par
    /// `SessionOrchestrator.isValid` avant chaque séance.
    private static func noSessionOverThree(_ library: ContentLibrary) -> Result {
        let offenders = library.entries.filter {
            $0.newItems.count > SessionOrchestrator.maxNewItemsPerSession
        }
        return Result(
            id: "A02",
            title: "Jamais plus de 3 mots nouveaux",
            passed: offenders.isEmpty,
            detail: offenders.isEmpty
                ? "155 entrées vérifiées"
                : "en faute : \(offenders.map(\.id).joined(separator: " "))"
        )
    }

    /// L'exemple d'un mot contient ce mot : sinon il n'illustre rien.
    private static func examplesContainTheirWord(_ library: ContentLibrary) -> Result {
        let offenders = library.vocabulary.filter { !$0.exampleZh.contains($0.hanzi) }
        return Result(
            id: "QA",
            title: "Chaque exemple contient son mot",
            passed: offenders.isEmpty,
            detail: offenders.isEmpty
                ? "300 exemples vérifiés"
                : "sans le mot : \(offenders.map(\.hanzi).prefix(5).joined(separator: " "))"
        )
    }

    /// A18 — on sait encore, mot par mot, ce qui vient du programme officiel
    /// et ce que Shuō a écrit autour.
    private static func officialScopeStaysDistinct(_ library: ContentLibrary) -> Result {
        let tagged = library.vocabulary.filter {
            $0.contentStatus.contains("HSK1_official_scope")
        }
        let passed = tagged.count == library.vocabulary.count && !library.vocabulary.isEmpty
        return Result(
            id: "A18",
            title: "Périmètre officiel distinct de la couche Shuō",
            passed: passed,
            detail: "\(tagged.count)/\(library.vocabulary.count) mots portent leur provenance"
        )
    }

    /// Le programme est bien celui de la livraison : 155 entrées, cinq familles.
    private static func curriculumIsComplete(_ library: ContentLibrary) -> Result {
        var byKind: [EntryKind: Int] = [:]
        for entry in library.entries { byKind[entry.kind, default: 0] += 1 }
        let passed = library.entries.count == 155
            && byKind[.pronunciationBootcamp] == 8
            && byKind[.newContent] == 106
            && byKind[.spacedReview] == 21
            && byKind[.moduleCheckpoint] == 14
            && byKind[.integration] == 6
        let detail = EntryKind.allCases
            .map { "\($0.label) \(byKind[$0] ?? 0)" }
            .joined(separator: " · ")
        return Result(id: "CUR", title: "155 entrées de programme", passed: passed, detail: detail)
    }
}

extension EntryKind: CaseIterable {
    static var allCases: [EntryKind] {
        [.pronunciationBootcamp, .newContent, .spacedReview, .moduleCheckpoint, .integration]
    }
}
