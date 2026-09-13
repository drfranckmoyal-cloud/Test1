import SwiftUI

/// Le visage du héros, dessiné, qui prend l'expression de l'effort.
///
/// C'est la seule question posée après une séance. L'échelle à visages est
/// celle qu'emploient les échelles d'effort perçu — du visage détendu au
/// visage crispé, avec la sueur qui apparaît en haut — et que reprennent la
/// plupart des applications d'entraînement, parce qu'elle se lit sans être
/// lue.
///
/// Le visage n'est pas un portrait : c'est une tête neutre qui porte la
/// couleur du programme et un détail signature du personnage — les moustaches
/// de Naruto, la crinière de Goku, la frange nette de Levi. Reconnaissable
/// d'un coup d'œil, sans prétendre à la ressemblance.
struct HeroFace: View {

    let hero: BudokaiHero?
    let effort: PerceivedEffort
    /// Le visage retenu est plus grand et plus coloré que les autres.
    var selected: Bool = false
    var size: CGFloat = 54

    private var tint: Color { effort.faceColor }
    private var hair: Color { hero?.hairColor ?? Theme.dim }

    var body: some View {
        ZStack {
            Circle()
                .fill(selected ? tint.opacity(0.22) : Theme.surfaceAlt)
                .overlay(Circle().stroke(selected ? tint : Theme.border,
                                         lineWidth: selected ? 2.5 : 1))

            Canvas { context, canvas in
                let box = CGRect(origin: .zero, size: canvas)
                draw(in: &context, box: box)
            }
            .frame(width: size * 0.78, height: size * 0.78)
            .opacity(selected ? 1 : 0.55)
        }
        .frame(width: size, height: size)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selected)
        .accessibilityHidden(true)
    }

    // MARK: - Le dessin

    private func draw(in context: inout GraphicsContext, box: CGRect) {
        let w = box.width, h = box.height
        let ink = selected ? tint : Theme.dim

        // la chevelure, derrière la tête : c'est elle qui dit le personnage
        drawHair(&context, box: box, w: w, h: h)

        // les yeux, dont la forme porte l'effort
        let eyeY = h * 0.47
        for side in [-1.0, 1.0] {
            let x = w * 0.5 + CGFloat(side) * w * 0.17
            drawEye(&context, at: CGPoint(x: x, y: eyeY), scale: w, ink: ink, side: side)
        }

        // la bouche
        drawMouth(&context, box: box, w: w, h: h, ink: ink)

        // la sueur, à partir de « difficile »
        if effort.sweatDrops > 0 {
            for index in 0..<effort.sweatDrops {
                let x = w * (index == 0 ? 0.88 : 0.12)
                let y = h * (index == 0 ? 0.44 : 0.52)
                var drop = Path()
                drop.move(to: CGPoint(x: x, y: y))
                drop.addQuadCurve(to: CGPoint(x: x, y: y + h * 0.13),
                                  control: CGPoint(x: x + w * 0.055, y: y + h * 0.08))
                drop.addQuadCurve(to: CGPoint(x: x, y: y),
                                  control: CGPoint(x: x - w * 0.055, y: y + h * 0.08))
                context.fill(drop, with: .color(Theme.steel))
            }
        }
    }

    private func drawHair(_ context: inout GraphicsContext, box: CGRect, w: CGFloat, h: CGFloat) {
        var path = Path()
        switch hero?.hairShape ?? .plain {
        case .spiky:
            // une crinière hérissée : Goku, Naruto
            let base = h * 0.30
            path.move(to: CGPoint(x: w * 0.14, y: base))
            var x = 0.14
            var up = true
            while x < 0.86 {
                let next = min(0.86, x + 0.12)
                let peak = up ? h * 0.02 : h * 0.12
                path.addLine(to: CGPoint(x: w * (x + next) / 2, y: peak))
                path.addLine(to: CGPoint(x: w * next, y: base))
                x = next
                up.toggle()
            }
            path.closeSubpath()
        case .flat:
            // une frange nette, coupée droit : Levi, Minato
            path.addRoundedRect(in: CGRect(x: w * 0.13, y: h * 0.08,
                                           width: w * 0.74, height: h * 0.21),
                                cornerSize: CGSize(width: w * 0.1, height: h * 0.09))
        case .wild:
            // une masse ébouriffée : Ichigo, Luffy
            path.addEllipse(in: CGRect(x: w * 0.10, y: h * 0.04,
                                       width: w * 0.80, height: h * 0.26))
            path.addEllipse(in: CGRect(x: w * 0.03, y: h * 0.13,
                                       width: w * 0.26, height: h * 0.19))
            path.addEllipse(in: CGRect(x: w * 0.71, y: h * 0.13,
                                       width: w * 0.26, height: h * 0.19))
        case .plain:
            path.addEllipse(in: CGRect(x: w * 0.15, y: h * 0.07,
                                       width: w * 0.70, height: h * 0.22))
        case .bald:
            break   // Saitama
        }
        if !path.isEmpty {
            context.fill(path, with: .color(hair.opacity(selected ? 0.9 : 0.7)))
        }

        // le bandeau ou la cicatrice, en travers du front
        if hero?.hasHeadband == true {
            let band = Path(CGRect(x: w * 0.09, y: h * 0.24, width: w * 0.82, height: h * 0.065))
            context.fill(band, with: .color(hair.opacity(0.55)))
        }
    }

    private func drawEye(_ context: inout GraphicsContext, at point: CGPoint,
                         scale: CGFloat, ink: Color, side: Double) {
        var path = Path()
        let r = scale * 0.055
        switch effort {
        case .veryEasy, .easy:
            path.addEllipse(in: CGRect(x: point.x - r, y: point.y - r, width: r * 2, height: r * 2))
            context.fill(path, with: .color(ink))
        case .wellDosed:
            path.addEllipse(in: CGRect(x: point.x - r * 0.9, y: point.y - r * 0.9,
                                       width: r * 1.8, height: r * 1.8))
            context.fill(path, with: .color(ink))
        case .hard:
            // le regard se ferme : un trait incliné vers l'intérieur
            path.move(to: CGPoint(x: point.x - CGFloat(side) * r * 1.3, y: point.y - r * 0.6))
            path.addLine(to: CGPoint(x: point.x + CGFloat(side) * r * 1.3, y: point.y + r * 0.5))
            context.stroke(path, with: .color(ink), style: StrokeStyle(lineWidth: r * 0.8, lineCap: .round))
        case .veryHard, .maximum:
            // yeux serrés : deux traits en accent circonflexe
            path.move(to: CGPoint(x: point.x - r * 1.3, y: point.y + r * 0.5))
            path.addLine(to: CGPoint(x: point.x, y: point.y - r * 0.7))
            path.addLine(to: CGPoint(x: point.x + r * 1.3, y: point.y + r * 0.5))
            context.stroke(path, with: .color(ink), style: StrokeStyle(lineWidth: r * 0.8,
                                                                      lineCap: .round,
                                                                      lineJoin: .round))
        }

        // les moustaches de Naruto, sur la joue
        if hero?.hasWhiskers == true {
            var whiskers = Path()
            for row in 0..<2 {
                let y = point.y + scale * (0.10 + CGFloat(row) * 0.055)
                let x0 = point.x + CGFloat(side) * scale * 0.04
                whiskers.move(to: CGPoint(x: x0, y: y))
                whiskers.addLine(to: CGPoint(x: x0 + CGFloat(side) * scale * 0.10, y: y))
            }
            context.stroke(whiskers, with: .color(ink.opacity(0.45)),
                           style: StrokeStyle(lineWidth: scale * 0.018, lineCap: .round))
        }
    }

    private func drawMouth(_ context: inout GraphicsContext, box: CGRect,
                           w: CGFloat, h: CGFloat, ink: Color) {
        var path = Path()
        let cx = w * 0.5, y = h * 0.72, half = w * 0.15
        switch effort {
        case .veryEasy:
            path.move(to: CGPoint(x: cx - half, y: y - h * 0.04))
            path.addQuadCurve(to: CGPoint(x: cx + half, y: y - h * 0.04),
                              control: CGPoint(x: cx, y: y + h * 0.13))
        case .easy:
            path.move(to: CGPoint(x: cx - half * 0.85, y: y - h * 0.01))
            path.addQuadCurve(to: CGPoint(x: cx + half * 0.85, y: y - h * 0.01),
                              control: CGPoint(x: cx, y: y + h * 0.07))
        case .wellDosed:
            path.move(to: CGPoint(x: cx - half * 0.7, y: y))
            path.addLine(to: CGPoint(x: cx + half * 0.7, y: y))
        case .hard:
            path.move(to: CGPoint(x: cx - half * 0.85, y: y + h * 0.04))
            path.addQuadCurve(to: CGPoint(x: cx + half * 0.85, y: y + h * 0.04),
                              control: CGPoint(x: cx, y: y - h * 0.05))
        case .veryHard, .maximum:
            // une grimace : bouche ouverte, dents serrées
            let rect = CGRect(x: cx - half, y: y - h * 0.02, width: half * 2, height: h * 0.12)
            path.addRoundedRect(in: rect, cornerSize: CGSize(width: w * 0.03, height: h * 0.03))
            context.fill(path, with: .color(ink))
            var teeth = Path()
            teeth.move(to: CGPoint(x: rect.minX, y: rect.midY))
            teeth.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            context.stroke(teeth, with: .color(Theme.surface),
                           style: StrokeStyle(lineWidth: h * 0.022))
            return
        }
        context.stroke(path, with: .color(ink),
                       style: StrokeStyle(lineWidth: w * 0.055, lineCap: .round))
    }
}

// MARK: - Ce que chaque héros porte

extension BudokaiHero {

    enum HairShape { case spiky, flat, wild, plain, bald }

    var hairShape: HairShape {
        switch self {
        case .saitama: return .bald
        case .goku, .naruto: return .spiky
        case .levi, .minato, .kenshiro: return .flat
        case .ichigo, .luffy: return .wild
        case .rockLee: return .plain
        }
    }

    /// La couleur de la chevelure, tirée du programme.
    var hairColor: Color {
        switch self {
        case .saitama: return Color(hex: 0xE8B84B)
        case .naruto: return Color(hex: 0xE8A33D)
        case .goku: return Color(hex: 0x2C2C34)
        case .rockLee: return Color(hex: 0x1F1F26)
        case .kenshiro: return Color(hex: 0x3A3A44)
        case .ichigo: return Color(hex: 0xE0601F)
        case .levi: return Color(hex: 0x2A3038)
        case .luffy: return Color(hex: 0x27272E)
        case .minato: return Color(hex: 0xE3C25A)
        }
    }

    /// Les marques sur les joues de Naruto.
    var hasWhiskers: Bool { self == .naruto }
    /// Le bandeau frontal, de ninja ou d'entraînement.
    var hasHeadband: Bool { self == .naruto || self == .minato || self == .rockLee }
}

// MARK: - Ce que chaque effort montre

extension PerceivedEffort {

    /// Les cinq visages présentés. « Maximum » n'a pas le sien : il se déclare
    /// en abandonnant, pas en validant une séance terminée.
    static var faces: [PerceivedEffort] { [.veryEasy, .easy, .wellDosed, .hard, .veryHard] }

    var faceColor: Color {
        switch self {
        case .veryEasy: return Color(hex: 0x4E9E6B)
        case .easy: return Color(hex: 0x76A84F)
        case .wellDosed: return Theme.gold
        case .hard: return Color(hex: 0xD98A3A)
        case .veryHard, .maximum: return Theme.crimson
        }
    }

    var sweatDrops: Int {
        switch self {
        case .veryEasy, .easy, .wellDosed: return 0
        case .hard: return 1
        case .veryHard, .maximum: return 2
        }
    }

    /// La légende sous le visage retenu.
    var caption: String {
        switch self {
        case .veryEasy: return "Je n'ai rien senti passer"
        case .easy: return "C'était confortable"
        case .wellDosed: return "Bien dosé, j'ai travaillé"
        case .hard: return "Dur, mais je suis allé au bout"
        case .veryHard: return "Très dur, j'ai failli lâcher"
        case .maximum: return "Au maximum"
        }
    }
}
