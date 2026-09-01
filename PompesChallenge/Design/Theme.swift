import SwiftUI

/// Palette et typographie du défi — reprise à l'identique de la maquette.
enum Theme {
    // Fonds
    static let background = Color(hex: 0x14100E)
    static let backgroundDeep = Color(hex: 0x100C0A)
    static let surface = Color(hex: 0x1D1611)
    static let surfaceAlt = Color(hex: 0x251C17)
    static let border = Color(hex: 0x2A201A)

    // Texte
    static let cream = Color(hex: 0xFCF3EA)
    static let muted = Color(hex: 0x8E7A6C)
    static let tabInactive = Color(hex: 0x6B5B50)

    // Jours du calendrier
    static let missedFill = Color(hex: 0x221A15)
    static let missedText = Color(hex: 0x5C4C42)
    static let upcomingFill = Color(hex: 0x1A1411)
    static let upcomingText = Color(hex: 0x463A32)

    // Orange
    static let orange = Color(hex: 0xFF6B1A)
    static let orangeLight = Color(hex: 0xFF8A3D)
    static let orangeDeep = Color(hex: 0xE8460A)
    static let amber = Color(hex: 0xFFA33D)
    static let ink = Color(hex: 0x2A1204)
    static let creamOnOrange = Color(hex: 0xFFF3E6)

    static var progressGradient: LinearGradient {
        LinearGradient(colors: [orange, amber], startPoint: .leading, endPoint: .trailing)
    }

    static var starGradient: LinearGradient {
        LinearGradient(colors: [Color(hex: 0xFF7A2E), orangeDeep],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var celebrationGradient: LinearGradient {
        LinearGradient(colors: [orangeLight, orange, Color(hex: 0xDB3F06)],
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
    /// Gros chiffres et titres — l'équivalent système d'Archivo Black.
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .default)
    }

    static func ui(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}
