import SwiftUI

/// Lit un tracé au format SVG et le rend en `Path`.
///
/// La maquette de l'avatar est dessinée en SVG ; plutôt que de retranscrire
/// ses courbes à la main — et d'y glisser des erreurs — on relit ses chaînes
/// telles quelles. Seules les commandes utilisées par la maquette sont
/// reconnues : déplacements, lignes, courbes cubiques et fermeture. Ni arcs,
/// ni courbes quadratiques.
enum SVGPath {

    static func path(_ d: String) -> Path {
        var path = Path()
        var tokens = Tokenizer(d)
        var current = CGPoint.zero
        var start = CGPoint.zero
        var lastControl: CGPoint?
        var command: Character = "M"

        while let token = tokens.peek() {
            if let letter = token.letter {
                command = letter
                tokens.advance()
                if letter == "Z" || letter == "z" {
                    path.closeSubpath()
                    current = start
                    lastControl = nil
                    continue
                }
            }

            let relative = command.isLowercase
            let base = relative ? current : .zero

            switch Character(command.uppercased()) {
            case "M":
                guard let x = tokens.number(), let y = tokens.number() else { return path }
                current = CGPoint(x: base.x + x, y: base.y + y)
                start = current
                path.move(to: current)
                // les paires suivantes d'un « M » sont des lignes
                command = relative ? "l" : "L"
                lastControl = nil

            case "L":
                guard let x = tokens.number(), let y = tokens.number() else { return path }
                current = CGPoint(x: base.x + x, y: base.y + y)
                path.addLine(to: current)
                lastControl = nil

            case "H":
                guard let x = tokens.number() else { return path }
                current = CGPoint(x: base.x + x, y: current.y)
                path.addLine(to: current)
                lastControl = nil

            case "V":
                guard let y = tokens.number() else { return path }
                current = CGPoint(x: current.x, y: base.y + y)
                path.addLine(to: current)
                lastControl = nil

            case "C":
                guard let x1 = tokens.number(), let y1 = tokens.number(),
                      let x2 = tokens.number(), let y2 = tokens.number(),
                      let x = tokens.number(), let y = tokens.number() else { return path }
                let c1 = CGPoint(x: base.x + x1, y: base.y + y1)
                let c2 = CGPoint(x: base.x + x2, y: base.y + y2)
                current = CGPoint(x: base.x + x, y: base.y + y)
                path.addCurve(to: current, control1: c1, control2: c2)
                lastControl = c2

            case "S":
                guard let x2 = tokens.number(), let y2 = tokens.number(),
                      let x = tokens.number(), let y = tokens.number() else { return path }
                // le premier point de contrôle reflète celui de la courbe précédente
                let mirrored = lastControl.map {
                    CGPoint(x: 2 * current.x - $0.x, y: 2 * current.y - $0.y)
                } ?? current
                let c2 = CGPoint(x: base.x + x2, y: base.y + y2)
                current = CGPoint(x: base.x + x, y: base.y + y)
                path.addCurve(to: current, control1: mirrored, control2: c2)
                lastControl = c2

            default:
                return path
            }
        }
        return path
    }

    // MARK: - Découpage

    private struct Tokenizer {
        private let chars: [Character]
        private var index = 0

        init(_ text: String) { chars = Array(text) }

        private mutating func skipSeparators() {
            while index < chars.count, chars[index] == " " || chars[index] == "," || chars[index] == "\n" {
                index += 1
            }
        }

        /// Regarde le caractère courant sans le consommer.
        mutating func peek() -> Token? {
            skipSeparators()
            guard index < chars.count else { return nil }
            let c = chars[index]
            return c.isLetter ? Token(letter: c) : Token(letter: nil)
        }

        mutating func advance() { index += 1 }

        /// Lit un nombre. Les signes collés aux chiffres les séparent :
        /// « 30-6 » vaut 30 puis -6.
        mutating func number() -> CGFloat? {
            skipSeparators()
            guard index < chars.count else { return nil }
            var text = ""
            if chars[index] == "-" || chars[index] == "+" {
                text.append(chars[index]); index += 1
            }
            var seenDot = false
            while index < chars.count {
                let c = chars[index]
                if c.isNumber {
                    text.append(c); index += 1
                } else if c == "." && !seenDot {
                    seenDot = true; text.append(c); index += 1
                } else {
                    break
                }
            }
            return Double(text).map { CGFloat($0) }
        }
    }

    private struct Token {
        let letter: Character?
    }
}

/// Une forme bâtie sur un tracé SVG, exprimée dans le repère de la maquette.
///
/// Le dessin garde ses coordonnées d'origine (400 × 540) : la vue qui le
/// contient se charge de la mise à l'échelle, si bien que toutes les valeurs
/// du fichier restent celles de la maquette.
struct SVGShape: Shape {
    let d: String
    func path(in rect: CGRect) -> Path { SVGPath.path(d) }
}
