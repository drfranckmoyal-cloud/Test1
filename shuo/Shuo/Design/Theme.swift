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

/// Papier, encre et un rouge de sceau. Les noms décrivent le rôle, pas la
/// teinte : `ink` est la couleur du texte — encre sur papier clair, crème sur
/// fond sombre.
///
/// Les valeurs viennent de la planche d'identité : papier légèrement chaud,
/// encre presque noire mais jamais tout à fait, rouge vermillon.
enum Theme {

    /// La signature, telle qu'elle est écrite sur la planche d'identité.
    /// Le point final en fait partie : c'est une phrase, pas une étiquette.
    static let slogan = "Parlez chinois."
    /// La ligne chinoise du splash : « un monde plus proche ».
    static let tagline = "更近的世界"

    static let paper = adaptive(light: 0xF5F0E6, dark: 0x121110)
    static let card = adaptive(light: 0xFFFCF5, dark: 0x1C1B18)
    static let ink = adaptive(light: 0x1A1917, dark: 0xF3EEE3)
    static let inkSoft = adaptive(light: 0x6B6459, dark: 0x9A9286)
    static let hairline = adaptive(light: 0xE2D9C8, dark: 0x2E2B24)
    static let seal = adaptive(light: 0xCC2E26, dark: 0xDE4438)

    /// Les trois statuts de maîtrise, dans leurs couleurs.
    static let red = adaptive(light: 0xCC2E26, dark: 0xE06A5A)
    static let orange = adaptive(light: 0xC77B24, dark: 0xE0A055)
    static let green = adaptive(light: 0x3E7A4E, dark: 0x6BB07E)

    static func color(for status: MasteryStatus) -> Color {
        switch status {
        case .red: return red
        case .orange: return orange
        case .green: return green
        }
    }

    // MARK: - Typographie

    /// Le grand caractère : la police système sait déjà rendre les hanzi, et
    /// elle est là sur tous les appareils.
    static func hanzi(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .serif)
    }

    static let pinyin = Font.system(size: 22, weight: .medium, design: .rounded)
    static let meaning = Font.system(size: 19, weight: .regular)
    static let title = Font.system(size: 26, weight: .semibold, design: .serif)
    /// Le mot-symbole « Shuō », en romain, comme sur la planche.
    static func wordmark(_ size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .serif)
    }
    static let body = Font.system(size: 17)
    static let caption = Font.system(size: 13, weight: .medium)
    static let mono = Font.system(size: 12, design: .monospaced)
}

/// Le fond de l'app : du papier, partout.
struct PaperBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.paper.ignoresSafeArea())
    }
}

extension View {
    func paperBackground() -> some View { modifier(PaperBackground()) }

    /// Le cartouche utilisé pour les cartes et les blocs d'information.
    func cartouche(padding: CGFloat = 20) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Theme.hairline, lineWidth: 1)
                    )
            )
    }
}
