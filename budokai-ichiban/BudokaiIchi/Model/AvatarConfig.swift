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

/// La tenue et les traits du combattant, tels que Franck les choisit.
/// Rangé dans `PlayerState` à côté du ton et de l'apparence.
struct AvatarConfig: Codable, Equatable {
    var hair: AvatarHair = .spiky
    var hairColor: UInt32 = 0x2A2320
    var skin: UInt32 = 0xF6CBA4
    var eye: UInt32 = 0x3E7FB5
    var gi: UInt32 = 0xF2E7D8

    static let hairChoices: [UInt32] = [0x2A2320, 0x6E3A1E, 0xD9A441, 0xC7402F, 0x5B6FA8, 0xE8E2DA]
    static let skinChoices: [UInt32] = [0xFBDCC0, 0xF6CBA4, 0xDCA274, 0xB67548, 0x7E4A2C]
    static let eyeChoices: [UInt32] = [0x3E7FB5, 0x4E8A5A, 0x8A5A2E, 0x8C4A6E, 0xC4472A]
    static let giChoices: [UInt32] = [0xF2E7D8, 0xE9843C, 0x4A6E8C, 0x57694E, 0x2E2A29]
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
