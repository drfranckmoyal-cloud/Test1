import SwiftUI

/// Les trois coiffures proposées.
enum AvatarHair: String, Codable, CaseIterable, Identifiable {
    case spiky, bowl, ponytail
    var id: String { rawValue }
    var label: String {
        switch self {
        case .spiky: return "Hérissée"
        case .bowl: return "Bol"
        case .ponytail: return "Queue"
        }
    }
}

/// La carrure du combattant. Change la chevelure arrière, qui donnait à
/// tout le monde une silhouette féminine.
enum AvatarBuild: String, Codable, CaseIterable, Identifiable {
    case male, female
    var id: String { rawValue }
    var label: String {
        switch self {
        case .male: return "Homme"
        case .female: return "Femme"
        }
    }
}

/// Une tenue. Le kimono blanc du débutant, puis celles des neuf maîtres.
struct AvatarOutfit: Identifiable, Equatable {
    let id: String
    let name: String
    /// Veste et manches.
    let top: UInt32
    /// Pantalon.
    let bottom: UInt32
    /// Revers et parements.
    let accent: UInt32
    /// Cape ou haori, porté dans le dos. Absent pour la plupart.
    let cape: UInt32?

    static let all: [AvatarOutfit] = [
        .init(id: "white", name: "Kimono blanc",
              top: 0xF2E7D8, bottom: 0xEADFD0, accent: 0xD9C6AE, cape: nil),
        .init(id: "saitama", name: "Saitama",
              top: 0xF2C94C, bottom: 0xF2C94C, accent: 0xE03A2F, cape: 0xF7F3EC),
        .init(id: "goku", name: "Goku",
              top: 0xF08A24, bottom: 0xF08A24, accent: 0x2E5FA3, cape: nil),
        .init(id: "rocklee", name: "Rock Lee",
              top: 0x3E8E41, bottom: 0x3E8E41, accent: 0xE8843C, cape: nil),
        .init(id: "kenshiro", name: "Kenshiro",
              top: 0x2B3A57, bottom: 0x2B3A57, accent: 0xC9A227, cape: nil),
        .init(id: "ichigo", name: "Ichigo",
              top: 0x1A1A1F, bottom: 0x1A1A1F, accent: 0xE8E4DC, cape: nil),
        .init(id: "minato", name: "Minato",
              top: 0x1E3A5F, bottom: 0x1E3A5F, accent: 0xE8E4DC, cape: 0xF2EDE4),
        .init(id: "levi", name: "Levi",
              top: 0xF2EDE4, bottom: 0x4A4034, accent: 0x6B5B45, cape: 0x3E6B4A),
        .init(id: "luffy", name: "Luffy",
              top: 0xD2352C, bottom: 0x2E5FA3, accent: 0xD2352C, cape: nil),
        .init(id: "naruto", name: "Naruto",
              top: 0xF07A1A, bottom: 0x1F2937, accent: 0x1F2937, cape: nil),
    ]

    static func named(_ id: String) -> AvatarOutfit {
        all.first { $0.id == id } ?? all[0]
    }
}

/// La tenue et les traits du combattant, tels que Franck les choisit.
/// Rangé dans `PlayerState` à côté du ton et de l'apparence.
struct AvatarConfig: Codable, Equatable {
    var build: AvatarBuild = .male
    var hair: AvatarHair = .spiky
    var hairColor: UInt32 = 0x2A2320
    var skin: UInt32 = 0xF6CBA4
    var eye: UInt32 = 0x3E7FB5
    var outfitID: String = "white"

    var outfit: AvatarOutfit { .named(outfitID) }

    /// Relit une sauvegarde d'avant la carrure et les tenues.
    init(from decoder: Decoder) throws {
        let box = try decoder.container(keyedBy: CodingKeys.self)
        func read<T: Decodable>(_ key: CodingKeys, _ fallback: T) -> T {
            (try? box.decode(T.self, forKey: key)) ?? fallback
        }
        build = read(.build, .male)
        hair = read(.hair, .spiky)
        hairColor = read(.hairColor, 0x2A2320)
        skin = read(.skin, 0xF6CBA4)
        eye = read(.eye, 0x3E7FB5)
        outfitID = read(.outfitID, "white")
    }

    init() {}

    static let hairChoices: [UInt32] = [0x2A2320, 0x6E3A1E, 0xD9A441, 0xC7402F, 0x5B6FA8, 0xE8E2DA]
    static let skinChoices: [UInt32] = [0xFBDCC0, 0xF6CBA4, 0xDCA274, 0xB67548, 0x7E4A2C]
    static let eyeChoices: [UInt32] = [0x3E7FB5, 0x4E8A5A, 0x8A5A2E, 0x8C4A6E, 0xC4472A]

}

/// La ceinture, qui monte avec la série de jours tenue.
enum Belt: Int, CaseIterable, Identifiable {
    case white = 0, yellow, orange, green, brown, black
    var id: Int { rawValue }

    /// Série à partir de laquelle la ceinture est acquise.
    var streakNeeded: Int {
        switch self {
        case .white: return 0
        case .yellow: return 3
        case .orange: return 7
        case .green: return 14
        case .brown: return 21
        case .black: return 30
        }
    }

    var label: String {
        switch self {
        case .white: return "Ceinture blanche"
        case .yellow: return "Ceinture jaune"
        case .orange: return "Ceinture orange"
        case .green: return "Ceinture verte"
        case .brown: return "Ceinture marron"
        case .black: return "Ceinture noire — Ichiban"
        }
    }

    var japanese: String {
        switch self {
        case .white: return "白帯"
        case .yellow: return "黄帯"
        case .orange: return "橙帯"
        case .green: return "緑帯"
        case .brown: return "茶帯"
        case .black: return "黒帯"
        }
    }

    var color: UInt32 {
        switch self {
        case .white: return 0xF5EFE6
        case .yellow: return 0xF2C53D
        case .orange: return 0xF2801F
        case .green: return 0x3E9E62
        case .brown: return 0x6B4227
        case .black: return 0x1A1614
        }
    }

    /// Intensité de l'aura, du néant au brasier.
    var aura: Double {
        switch self {
        case .white, .yellow: return 0
        case .orange: return 0.30
        case .green: return 0.48
        case .brown: return 0.72
        case .black: return 1
        }
    }

    /// Usure du kimono : accrocs et salissures apparaissent avec le niveau.
    var wear: Double {
        switch self {
        case .white, .yellow, .orange: return 0
        case .green: return 0.35
        case .brown: return 0.70
        case .black: return 1
        }
    }

    /// Le bandeau n'apparaît qu'à partir de l'orange.
    var hasBand: Bool { rawValue >= Belt.orange.rawValue }

    /// Les cheveux se hérissent à mesure qu'on monte.
    var spike: Double {
        switch self {
        case .white, .yellow: return 1
        case .orange: return 1.02
        case .green: return 1.05
        case .brown: return 1.10
        case .black: return 1.16
        }
    }

    /// La ceinture méritée par une série donnée.
    static func earned(streak: Int) -> Belt {
        allCases.last { streak >= $0.streakNeeded } ?? .white
    }
}

/// Les attitudes du personnage.
enum AvatarPose: String, CaseIterable, Identifiable {
    case idle, guardStance, pushup, win, kiai
    var id: String { rawValue }

    var label: String {
        switch self {
        case .idle: return "Repos"
        case .guardStance: return "Garde"
        case .pushup: return "Pompes"
        case .win: return "Victoire"
        case .kiai: return "Kiai"
        }
    }

    var japanese: String {
        switch self {
        case .idle: return "やすめ"
        case .guardStance: return "かまえ"
        case .pushup: return "うでたて"
        case .win: return "しょうり"
        case .kiai: return "きあい"
        }
    }

    /// Rotations des membres, en degrés, reprises de la maquette.
    var armL: Double {
        switch self {
        case .idle: return 6
        case .guardStance: return 26
        case .pushup: return -52
        case .win: return 18
        case .kiai: return -34
        }
    }
    var foreL: Double {
        switch self {
        case .idle: return -4
        case .guardStance: return -118
        case .pushup: return -34
        case .win: return -30
        case .kiai: return -52
        }
    }
    var armR: Double {
        switch self {
        case .idle: return -6
        case .guardStance: return -26
        case .pushup: return 52
        case .win: return -158
        case .kiai: return 34
        }
    }
    var foreR: Double {
        switch self {
        case .idle: return 4
        case .guardStance: return 118
        case .pushup: return 34
        case .win: return -14
        case .kiai: return 52
        }
    }
    var head: Double {
        switch self {
        case .idle: return 0
        case .guardStance: return -3
        case .pushup: return 8
        case .win: return -7
        case .kiai: return -5
        }
    }
    var legL: Double {
        switch self {
        case .idle: return 0
        case .guardStance: return -6
        case .pushup: return 2
        case .win: return -10
        case .kiai: return -13
        }
    }
    var legR: Double {
        switch self {
        case .idle: return 0
        case .guardStance: return 8
        case .pushup: return -2
        case .win: return 14
        case .kiai: return 13
        }
    }

    /// Bouche ouverte : le cri.
    var shouts: Bool { self == .win || self == .kiai }
    /// Sourcils furieux.
    var angry: Bool { self == .kiai }
}

extension Color {
    /// Éclaircit (`amount` positif) ou assombrit une couleur, comme la
    /// fonction `shade` de la maquette.
    static func shade(_ hex: UInt32, _ amount: Double) -> Color {
        func channel(_ value: UInt32) -> Double {
            let raw = Double(value)
            return min(255, max(0, (raw + raw * amount).rounded()))
        }
        return Color(.sRGB,
                     red: channel((hex >> 16) & 0xFF) / 255,
                     green: channel((hex >> 8) & 0xFF) / 255,
                     blue: channel(hex & 0xFF) / 255,
                     opacity: 1)
    }
}
