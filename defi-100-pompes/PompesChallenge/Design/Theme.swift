import SwiftUI
import UIKit

/// Choix d'apparence de l'utilisateur.
enum Appearance: String, Codable, CaseIterable, Identifiable {
    case light
    case dark
    case system

    var id: String { rawValue }

    var label: String {
        switch self {
        case .light: return "Clair"
        case .dark: return "Sombre"
        case .system: return "Système"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

private extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(
            red: CGFloat((rgb >> 16) & 0xFF) / 255.0,
            green: CGFloat((rgb >> 8) & 0xFF) / 255.0,
            blue: CGFloat(rgb & 0xFF) / 255.0,
            alpha: 1.0
        )
    }
}

/// Une couleur qui bascule seule entre le thème clair et le thème sombre.
private func adaptive(light: UInt32, dark: UInt32) -> Color {
    Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(rgb: dark) : UIColor(rgb: light)
    })
}

/// Palette et typographie. Les noms décrivent le rôle, pas la teinte :
/// `cream` est la couleur du texte principal — crème sur fond sombre,
/// brun très foncé sur fond clair.
enum Theme {
    // Fonds
    static let background = adaptive(light: 0xFDF4EB, dark: 0x14100E)
    static let backgroundDeep = adaptive(light: 0xFFFFFF, dark: 0x100C0A)
    static let surface = adaptive(light: 0xFFFFFF, dark: 0x1D1611)
    static let surfaceAlt = adaptive(light: 0xFDE3D0, dark: 0x251C17)
    static let border = adaptive(light: 0xF2DFCE, dark: 0x2A201A)

    // Texte
    static let cream = adaptive(light: 0x2A1204, dark: 0xFCF3EA)
    static let muted = adaptive(light: 0xA2836E, dark: 0x8E7A6C)
    static let tabInactive = adaptive(light: 0xBFA694, dark: 0x6B5B50)

    // Jours du calendrier
    static let missedFill = adaptive(light: 0xF4E8DD, dark: 0x221A15)
    static let missedText = adaptive(light: 0xB9A192, dark: 0x5C4C42)
    static let upcomingFill = adaptive(light: 0xF8EFE6, dark: 0x1A1411)
    static let upcomingText = adaptive(light: 0xCDB8A7, dark: 0x463A32)

    // Orange
    static let orange = adaptive(light: 0xF2540B, dark: 0xFF6B1A)
    static let orangeLight = adaptive(light: 0xC43D06, dark: 0xFF8A3D)
    static let orangeDeep = adaptive(light: 0xB33507, dark: 0xE8460A)
    static let amber = adaptive(light: 0xFF8A3D, dark: 0xFFA33D)

    // Constantes : toujours lues sur un aplat orange
    static let ink = Color(hex: 0x2A1204)
    static let creamOnOrange = Color(hex: 0xFFF3E6)

    static var progressGradient: LinearGradient {
        LinearGradient(colors: [orange, amber], startPoint: .leading, endPoint: .trailing)
    }

    static var starGradient: LinearGradient {
        LinearGradient(colors: [orange, orangeDeep],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var celebrationGradient: LinearGradient {
        LinearGradient(colors: [Color(hex: 0xFF8A3D), Color(hex: 0xFF6B1A), Color(hex: 0xDB3F06)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: 1.0
        )
    }
}

extension Font {
    /// Gros chiffres et titres.
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .default)
    }

    static func ui(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}
