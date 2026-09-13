import SwiftUI
import UIKit

/// Choix d'apparence. Le jeu s'installe en sombre ; le clair reste disponible.
enum Appearance: String, Codable, CaseIterable, Identifiable {
    case dark, light, system
    var id: String { rawValue }
    var label: String {
        switch self {
        case .dark: return "Sombre"
        case .light: return "Clair"
        case .system: return "Système"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .dark: return .dark
        case .light: return .light
        case .system: return nil
        }
    }
}

private extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(red: CGFloat((rgb >> 16) & 0xFF) / 255.0,
                  green: CGFloat((rgb >> 8) & 0xFF) / 255.0,
                  blue: CGFloat(rgb & 0xFF) / 255.0, alpha: 1.0)
    }
}

/// Une couleur qui bascule seule entre les deux thèmes.
private func adaptive(dark: UInt32, light: UInt32) -> Color {
    Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(rgb: dark) : UIColor(rgb: light)
    })
}

/// Palette du jeu. Les noms décrivent le rôle : `text` est crème sur fond
/// sombre, brun très foncé sur fond clair.
enum Theme {
    static let ground = adaptive(dark: 0x0B0A0C, light: 0xF7F4EF)
    static let groundDeep = adaptive(dark: 0x0F0E11, light: 0xFFFFFF)
    static let surface = adaptive(dark: 0x151318, light: 0xFFFFFF)
    static let surfaceAlt = adaptive(dark: 0x1E1B22, light: 0xF0EAE2)
    static let border = adaptive(dark: 0x2A2630, light: 0xE4DCD2)

    static let text = adaptive(dark: 0xF4F1EC, light: 0x17141A)
    static let muted = adaptive(dark: 0x8E8894, light: 0x7C7486)
    static let dim = adaptive(dark: 0x4E4956, light: 0xB4ABBC)

    static let crimson = adaptive(dark: 0xE02B20, light: 0xC71D12)
    static let gold = adaptive(dark: 0xE0B44A, light: 0xA97C17)

    /// Le bleu froid d'une goutte de sueur.
    static let steel = adaptive(dark: 0x6FA8D4, light: 0x4C86B8)

    static let ink = Color(hex: 0x17140F)
    static let cream = Color(hex: 0xFFF3E6)

    /// Couleur d'un rang, du plus bas au plus haut.
    static func rankColor(_ rank: Rank) -> Color {
        switch rank {
        case .e: return adaptive(dark: 0x9B9BA0, light: 0x8A8A8F)
        case .d: return adaptive(dark: 0x5AA97C, light: 0x3F7D5B)
        case .c: return adaptive(dark: 0x5A9BD4, light: 0x2E6FA8)
        case .b: return adaptive(dark: 0xA97ED4, light: 0x7A4BA8)
        case .a: return adaptive(dark: 0xE8714B, light: 0xC0431E)
        case .s: return adaptive(dark: 0xE0B44A, light: 0xB98514)
        case .sPlus: return adaptive(dark: 0xF4F1EC, light: 0x17141A)
        }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255.0,
                  green: Double((hex >> 8) & 0xFF) / 255.0,
                  blue: Double(hex & 0xFF) / 255.0,
                  opacity: 1.0)
    }
}

extension Font {
    /// Chiffres et titres : l'équivalent système d'une grasse japonaise.
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .default)
    }
    static func ui(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }

    /// Les titres d'arc : noire et resserrée, comme un titre de chapitre de
    /// shōnen, mais c'est la police du système — donc parfaitement lisible,
    /// et elle suit les réglages d'accessibilité du téléphone.
    static func manga(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .default).width(.compressed)
    }
}

extension Int {
    /// 1563 -> "1 563"
    var grouped: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "\u{00A0}"
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
