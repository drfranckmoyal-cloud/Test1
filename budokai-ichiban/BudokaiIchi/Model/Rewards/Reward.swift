import SwiftUI

// MARK: - Ce qu'on collectionne

enum RewardType: String, Codable, CaseIterable, Identifiable {
    case character, technique, transformation, object, location, fight, sensei, event, rank
    var id: String { rawValue }

    var label: String {
        switch self {
        case .character: return "Personnage"
        case .technique: return "Technique"
        case .transformation: return "Transformation"
        case .object: return "Objet"
        case .location: return "Lieu"
        case .fight: return "Combat"
        case .sensei: return "Maître"
        case .event: return "Événement"
        case .rank: return "Rang"
        }
    }

    var icon: String {
        switch self {
        case .character: return "person.fill"
        case .technique: return "bolt.fill"
        case .transformation: return "flame.fill"
        case .object: return "shippingbox.fill"
        case .location: return "map.fill"
        case .fight: return "figure.martial.arts"
        case .sensei: return "person.2.fill"
        case .event: return "sparkles"
        case .rank: return "rosette"
        }
    }
}

enum RewardRarity: String, Codable, CaseIterable, Identifiable, Comparable {
    case standard, rare, epic, legendary
    var id: String { rawValue }

    var label: String {
        switch self {
        case .standard: return "Standard"
        case .rare: return "Rare"
        case .epic: return "Épique"
        case .legendary: return "Légendaire"
        }
    }

    var color: Color {
        switch self {
        case .standard: return Theme.muted
        case .rare: return Color(hex: 0x5A9BD4)
        case .epic: return Color(hex: 0xA97ED4)
        case .legendary: return Theme.gold
        }
    }

    private var rank: Int {
        switch self {
        case .standard: return 0
        case .rare: return 1
        case .epic: return 2
        case .legendary: return 3
        }
    }

    static func < (lhs: RewardRarity, rhs: RewardRarity) -> Bool { lhs.rank < rhs.rank }
}

/// À quelle condition une vignette se débloque.
enum UnlockCondition: Codable, Equatable {
    /// Un bloc du programme terminé.
    case blockCompleted(blockId: String)
    /// Le combat final gagné.
    case bossDefeated(programId: String)
    /// Le standard sportif validé, qui ouvre le S+.
    case standardValidated(programId: String)

    var label: String {
        switch self {
        case .blockCompleted: return "Bloc terminé"
        case .bossDefeated: return "Combat final gagné"
        case .standardValidated: return "Standard validé"
        }
    }
}

/// Une vignette de collection.
struct Reward: Identifiable, Codable, Equatable {
    var id: String { rewardId }
    var rewardId: String

    var anime: String
    var programId: String

    var arc: String
    var blockId: String?

    var rewardType: RewardType

    var title: String
    var subtitle: String?
    var description: String

    var rarity: RewardRarity
    var chronologyIndex: Int
    var spoilerLevel: SpoilerLevel = .anime

    var imageAsset: String?

    var relatedCharacters: [String] = []
    var relatedTechniques: [String] = []

    var unlockCondition: UnlockCondition
}

/// Ce que le joueur possède.
struct RewardInventory: Codable, Equatable {
    /// Identifiants des vignettes obtenues, avec leur date.
    var unlocked: [String: Date] = [:]
    /// Les vignettes déjà montrées en grand : les autres attendent leur
    /// écran de révélation.
    var revealed: Set<String> = []

    func has(_ id: String) -> Bool { unlocked[id] != nil }
    func needsReveal(_ id: String) -> Bool { has(id) && !revealed.contains(id) }

    mutating func unlock(_ id: String, at date: Date = Date()) {
        guard unlocked[id] == nil else { return }
        unlocked[id] = date
    }

    mutating func markRevealed(_ id: String) { revealed.insert(id) }
}

/// Le catalogue des vignettes.
///
/// Seules les neuf vignettes de Saitama sont déclarées : ce sont les seules
/// que le cadrage nomme, au chapitre 16. Leurs textes de description relèvent
/// du livrable 7 et restent volontairement courts et factuels plutôt
/// qu'inventés. Les huit autres programmes n'ont aucune vignette tant que
/// leur contenu n'est pas écrit.
enum RewardCatalog {

    static let all: [Reward] = saitama

    static func reward(_ id: String) -> Reward? { all.first { $0.rewardId == id } }

    static func rewards(for program: ProgramID) -> [Reward] {
        all.filter { $0.programId == program.rawValue }.sorted { $0.chronologyIndex < $1.chronologyIndex }
    }

    /// La vignette que déclenche la fin d'un bloc.
    static func reward(forBlock blockId: String) -> Reward? {
        all.first { $0.unlockCondition == .blockCompleted(blockId: blockId) }
    }

    private static func saitamaReward(_ id: String, _ index: Int, _ block: String?,
                                      _ type: RewardType, _ title: String,
                                      _ rarity: RewardRarity,
                                      _ condition: UnlockCondition) -> Reward {
        Reward(rewardId: id, anime: "One Punch Man", programId: ProgramID.saitama.rawValue,
               arc: "Saitama", blockId: block, rewardType: type, title: title,
               subtitle: nil,
               description: "Vignette obtenue à la fin de ce bloc. Son récit reste à écrire.",
               rarity: rarity, chronologyIndex: index, unlockCondition: condition)
    }

    private static let saitama: [Reward] = [
        saitamaReward("SAI-001", 1, "SAI-B1", .event, "Le Déclic", .standard,
                      .blockCompleted(blockId: "SAI-B1")),
        saitamaReward("SAI-002", 2, "SAI-B2", .technique, "La Routine", .standard,
                      .blockCompleted(blockId: "SAI-B2")),
        saitamaReward("SAI-003", 3, "SAI-B3", .character, "Genos : Le Disciple", .rare,
                      .blockCompleted(blockId: "SAI-B3")),
        saitamaReward("SAI-004", 4, "SAI-B4", .rank, "Caped Baldy : Classe C", .rare,
                      .blockCompleted(blockId: "SAI-B4")),
        saitamaReward("SAI-005", 5, "SAI-B5", .event, "Météorite de Z-City", .epic,
                      .blockCompleted(blockId: "SAI-B5")),
        saitamaReward("SAI-006", 6, "SAI-B6", .character, "Mumen Rider", .rare,
                      .blockCompleted(blockId: "SAI-B6")),
        saitamaReward("SAI-007", 7, "SAI-B7", .fight, "Boros", .epic,
                      .blockCompleted(blockId: "SAI-B7")),
        saitamaReward("SAI-008", 8, "SAI-B8", .rank, "Le Plus Fort", .epic,
                      .blockCompleted(blockId: "SAI-B8")),
        saitamaReward("SAI-009", 9, nil, .transformation, "One Punch Man", .legendary,
                      .bossDefeated(programId: ProgramID.saitama.rawValue))
    ]
}
