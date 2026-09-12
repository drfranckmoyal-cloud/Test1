import SwiftUI

/// Le combattant, dessiné entièrement en courbes — aucun fichier image.
///
/// Le dessin vit dans le repère de la maquette (400 × 540) et la vue le met à
/// l'échelle d'un bloc : toutes les coordonnées de ce fichier sont donc celles
/// du SVG d'origine, lisibles telles quelles.
struct AvatarView: View {
    var config: AvatarConfig
    var pose: AvatarPose = .idle
    var belt: Belt = .white
    /// Largeur voulue à l'écran. La hauteur suit la proportion de la maquette.
    var width: CGFloat = 260
    /// Respiration et flamme. À couper sur les petites vignettes.
    var animated: Bool = true

    private static let boardWidth: CGFloat = 400
    private static let boardHeight: CGFloat = 540

    @State private var breathing = false

    private var outline: Color { Color(hex: 0x2B211B) }
    private var skin: Color { Color(hex: config.skin) }
    private var skinShade: Color { .shade(config.skin, -0.16) }
    private var hair: Color { Color(hex: config.hairColor) }
    private var outfit: AvatarOutfit { config.outfit }
    private var gi: Color { Color(hex: outfit.top) }
    private var giShade: Color { Color(hex: outfit.accent) }
    private var trousers: Color { Color(hex: outfit.bottom) }
    private var beltColor: Color { Color(hex: belt.color) }

    var body: some View {
        board
            .frame(width: Self.boardWidth, height: Self.boardHeight)
            .scaleEffect(width / Self.boardWidth, anchor: .center)
            .frame(width: width, height: width * Self.boardHeight / Self.boardWidth)
            .animation(.spring(response: 0.34, dampingFraction: 0.62), value: pose)
            .animation(.easeInOut(duration: 0.45), value: belt)
            .onAppear { if animated { breathing = true } }
    }

    private var board: some View {
        ZStack {
            aura
            floor
            character
                .offset(y: breathing && animated ? -4 : 0)
                .animation(animated ? .easeInOut(duration: 2.6).repeatForever(autoreverses: true) : nil,
                           value: breathing)
        }
    }

    // MARK: - Aura et sol

    private var aura: some View {
        ZStack {
            Ellipse()
                .fill(RadialGradient(colors: [Color(hex: 0xFFC46B).opacity(0.55),
                                              Color(hex: 0xFF6B1A).opacity(0.28),
                                              Color(hex: 0xFF6B1A).opacity(0)],
                                     center: .init(x: 0.5, y: 0.62),
                                     startRadius: 0, endRadius: 232))
                .frame(width: 320, height: 460)
                .position(x: 200, y: 330)

            SVGShape(d: Self.auraFlame)
                .fill(LinearGradient(colors: [Color(hex: 0xFFE0A8).opacity(0.10),
                                              Color(hex: 0xFFA33D).opacity(0.55),
                                              Color(hex: 0xFF6B1A).opacity(0.85)],
                                     startPoint: .top, endPoint: .bottom))
        }
        .opacity(belt.aura)
    }

    private var floor: some View {
        ZStack {
            Ellipse().fill(Color.black.opacity(0.10))
                .frame(width: 252, height: 50).position(x: 200, y: 470)
            Ellipse().fill(Color.black.opacity(0.07))
                .frame(width: 184, height: 32).position(x: 200, y: 470)
        }
    }

    // MARK: - Le personnage

    private var character: some View {
        ZStack {
            cape
            backHair
            leg(left: true)
            leg(left: false)
            torso
            beltGroup
            arm(left: true)
            arm(left: false)
            head
        }
    }

    /// Cape ou haori. Dessiné derrière le corps, seulement pour les tenues
    /// qui en portent une.
    @ViewBuilder
    private var cape: some View {
        if let color = outfit.cape {
            SVGShape(d: Self.capePath)
                .fill(Color(hex: color))
                .overlay(SVGShape(d: Self.capePath).stroke(outline, lineWidth: 3.2))
        }
    }

    private var backHair: some View {
        ZStack {
            SVGShape(d: Self.ponytail)
                .fill(hair)
                .overlay(SVGShape(d: Self.ponytail).stroke(outline, lineWidth: 3.2))
                .opacity(config.hair == .ponytail ? 1 : 0)

            SVGShape(d: backHairPath)
                .fill(hair)
                .overlay(SVGShape(d: backHairPath).stroke(outline, lineWidth: 3.2))
        }
        .scaleEffect(x: 1, y: belt.spike, anchor: UnitPoint(x: 200 / 400, y: 140 / 540))
    }

    /// La nuque dégagée pour l'homme, la chevelure longue pour la femme.
    private var backHairPath: String {
        config.build == .male ? Self.backHairMale : Self.backHairFemale
    }

    // MARK: Jambes

    private func leg(left: Bool) -> some View {
        let thighFrom = CGPoint(x: left ? 178 : 222, y: 296)
        let thighTo = CGPoint(x: left ? 172 : 228, y: 372)
        let shinTo = CGPoint(x: left ? 170 : 230, y: 436)
        let footX: CGFloat = left ? 167 : 233

        return ZStack {
            limb(from: thighFrom, to: thighTo, outer: 38, inner: 32, color: trousers)

            limb(from: thighTo, to: shinTo, outer: 32, inner: 26, color: trousers)
            Ellipse()
                .fill(Color(hex: 0x3A2E27))
                .overlay(Ellipse().stroke(outline, lineWidth: 3.2))
                .frame(width: 42, height: 22)
                .position(x: footX, y: 447)
        }
        .rotationEffect(.degrees(left ? pose.legL : pose.legR), anchor: anchor(thighFrom))
    }

    // MARK: Bras

    private func arm(left: Bool) -> some View {
        let shoulder = CGPoint(x: left ? 158 : 242, y: 208)
        let elbow = CGPoint(x: left ? 145 : 255, y: 258)
        let wrist = CGPoint(x: left ? 149 : 251, y: 304)
        let handX: CGFloat = left ? 149 : 251

        return ZStack {
            limb(from: shoulder, to: elbow, outer: 37, inner: 31, color: gi)

            ZStack {
                limb(from: elbow, to: wrist, outer: 30, inner: 24, color: skin)
                Circle()
                    .fill(skin)
                    .overlay(Circle().stroke(outline, lineWidth: 3.2))
                    .frame(width: 28, height: 28)
                    .position(x: handX, y: 308)
            }
            .rotationEffect(.degrees(left ? pose.foreL : pose.foreR), anchor: anchor(elbow))
        }
        .rotationEffect(.degrees(left ? pose.armL : pose.armR), anchor: anchor(shoulder))
    }

    /// Un segment de membre : un trait épais sombre, puis le trait clair
    /// par-dessus. C'est ce qui donne le contour dessiné.
    private func limb(from: CGPoint, to: CGPoint, outer: CGFloat, inner: CGFloat, color: Color) -> some View {
        ZStack {
            segment(from: from, to: to)
                .stroke(outline, style: StrokeStyle(lineWidth: outer, lineCap: .round))
            segment(from: from, to: to)
                .stroke(color, style: StrokeStyle(lineWidth: inner, lineCap: .round))
        }
    }

    private func segment(from: CGPoint, to: CGPoint) -> Path {
        var path = Path()
        path.move(to: from)
        path.addLine(to: to)
        return path
    }

    // MARK: Buste

    private var torso: some View {
        ZStack {
            SVGShape(d: Self.torsoGi)
                .fill(gi)
                .overlay(SVGShape(d: Self.torsoGi).stroke(outline, lineWidth: 3.2))

            SVGShape(d: Self.chest).fill(skin)

            SVGShape(d: Self.lapelL)
                .fill(giShade)
                .overlay(SVGShape(d: Self.lapelL).stroke(outline, lineWidth: 3.2))
            SVGShape(d: Self.lapelR)
                .fill(giShade)
                .overlay(SVGShape(d: Self.lapelR).stroke(outline, lineWidth: 3.2))

            // accrocs, visibles seulement aux rangs élevés
            ZStack {
                SVGShape(d: Self.wearA).fill(Color.black.opacity(0.32))
                SVGShape(d: Self.wearB).fill(Color.black.opacity(0.32))
                SVGShape(d: Self.wearC)
                    .stroke(Color.black.opacity(0.30),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round))
            }
            .opacity(belt.wear)
        }
    }

    private var beltGroup: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(beltColor)
                .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).stroke(outline, lineWidth: 3.2))
                .frame(width: 108, height: 25)
                .position(x: 200, y: 299.5)

            SVGShape(d: Self.beltTailL)
                .fill(beltColor)
                .overlay(SVGShape(d: Self.beltTailL).stroke(outline, lineWidth: 3.2))
            SVGShape(d: Self.beltTailR)
                .fill(beltColor)
                .overlay(SVGShape(d: Self.beltTailR).stroke(outline, lineWidth: 3.2))

            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(beltColor)
                .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).stroke(outline, lineWidth: 3.2))
                .frame(width: 26, height: 35)
                .position(x: 200, y: 299.5)
        }
    }

    // MARK: Tête

    private var head: some View {
        ZStack {
            SVGShape(d: Self.neck).fill(skin)

            Ellipse().fill(skin).overlay(Ellipse().stroke(outline, lineWidth: 3.2))
                .frame(width: 18, height: 26).position(x: 145, y: 142)
            Ellipse().fill(skin).overlay(Ellipse().stroke(outline, lineWidth: 3.2))
                .frame(width: 18, height: 26).position(x: 255, y: 142)

            SVGShape(d: Self.face)
                .fill(skin)
                .overlay(SVGShape(d: Self.face).stroke(outline, lineWidth: 3.2))

            Ellipse().fill(Color(hex: 0xF08A6B).opacity(0.32))
                .frame(width: 24, height: 11).position(x: 157, y: 168)
            Ellipse().fill(Color(hex: 0xF08A6B).opacity(0.32))
                .frame(width: 24, height: 11).position(x: 243, y: 168)

            eyes
            brows
            mouth
            frontHair
            band
        }
        .rotationEffect(.degrees(pose.head), anchor: anchor(CGPoint(x: 200, y: 196)))
    }

    private var eyes: some View {
        ZStack {
            Ellipse().fill(.white).frame(width: 32, height: 37).position(x: 178, y: 149)
            Ellipse().fill(.white).frame(width: 32, height: 37).position(x: 222, y: 149)
            Ellipse().fill(Color(hex: config.eye)).frame(width: 22, height: 28).position(x: 180, y: 151)
            Ellipse().fill(Color(hex: config.eye)).frame(width: 22, height: 28).position(x: 220, y: 151)
            Ellipse().fill(Color(hex: 0x1B1410)).frame(width: 9.6, height: 16.4).position(x: 180, y: 152)
            Ellipse().fill(Color(hex: 0x1B1410)).frame(width: 9.6, height: 16.4).position(x: 220, y: 152)
            Circle().fill(.white).frame(width: 9.2, height: 9.2).position(x: 174, y: 143)
            Circle().fill(.white).frame(width: 9.2, height: 9.2).position(x: 214, y: 143)
            Circle().fill(Color.white.opacity(0.75)).frame(width: 5, height: 5).position(x: 186, y: 159)
            Circle().fill(Color.white.opacity(0.75)).frame(width: 5, height: 5).position(x: 226, y: 159)
            SVGShape(d: Self.lidL).stroke(hair, style: StrokeStyle(lineWidth: 6.5, lineCap: .round))
            SVGShape(d: Self.lidR).stroke(hair, style: StrokeStyle(lineWidth: 6.5, lineCap: .round))
        }
    }

    private var brows: some View {
        ZStack {
            SVGShape(d: Self.browL)
                .stroke(hair, style: StrokeStyle(lineWidth: 5.2, lineCap: .round))
                .rotationEffect(.degrees(pose.angry ? 16 : 0), anchor: anchor(CGPoint(x: 175, y: 120)))
            SVGShape(d: Self.browR)
                .stroke(hair, style: StrokeStyle(lineWidth: 5.2, lineCap: .round))
                .rotationEffect(.degrees(pose.angry ? -16 : 0), anchor: anchor(CGPoint(x: 225, y: 120)))
        }
    }

    private var mouth: some View {
        ZStack {
            SVGShape(d: Self.mouthShut)
                .stroke(Color(hex: 0x8A4A38), style: StrokeStyle(lineWidth: 3.4, lineCap: .round))
                .opacity(pose.shouts ? 0 : 1)

            ZStack {
                SVGShape(d: Self.mouthOpen).fill(Color(hex: 0x6E2A22))
                SVGShape(d: Self.tongue).fill(Color(hex: 0xE0736A))
            }
            .opacity(pose.shouts ? 1 : 0)
        }
    }

    private var frontHair: some View {
        ZStack {
            SVGShape(d: Self.bangsSpiky)
                .fill(hair)
                .overlay(SVGShape(d: Self.bangsSpiky).stroke(outline, lineWidth: 3.2))
                .opacity(config.hair == .bowl ? 0 : 1)

            SVGShape(d: Self.bangsBowl)
                .fill(hair)
                .overlay(SVGShape(d: Self.bangsBowl).stroke(outline, lineWidth: 3.2))
                .opacity(config.hair == .bowl ? 1 : 0)
        }
    }

    private var band: some View {
        ZStack {
            SVGShape(d: Self.bandFront)
                .fill(Color(hex: 0xDC4708))
                .overlay(SVGShape(d: Self.bandFront).stroke(outline, lineWidth: 3.2))
            SVGShape(d: Self.bandTail)
                .fill(Color(hex: 0xDC4708))
                .overlay(SVGShape(d: Self.bandTail).stroke(outline, lineWidth: 3.2))
            Circle().fill(Color(hex: 0xFFF3E6)).frame(width: 13, height: 13).position(x: 200, y: 110)
        }
        .opacity(belt.hasBand ? 1 : 0)
    }

    // MARK: - Outils

    /// Traduit un point de la maquette en ancre de rotation.
    private func anchor(_ point: CGPoint) -> UnitPoint {
        UnitPoint(x: point.x / Self.boardWidth, y: point.y / Self.boardHeight)
    }

    // MARK: - Les tracés de la maquette

    private static let auraFlame = "M200 500c-58-40-92-92-86-156 20 34 40 50 48 54-20-58-8-110 26-152-4 44 14 70 32 86-12-42-6-76 16-104 0 40 20 64 36 88 14 22 20 46 14 70-8 44-42 80-86 114Z"
    private static let ponytail = "M248 78c30-6 58 8 66 34 8 26-2 54-20 74-8 8-20 0-16-10 10-26 10-46 2-60-8-14-20-24-32-28Z"
    /// Nuque rasée court : la calotte s'arrête au-dessus des oreilles.
    private static let backHairMale = "M200 48c40 0 66 30 66 70 0 10-1 19-3 26-2 7-11 8-14 1-3-9-5-17-6-25-2 10-4 17-6 22h-74c-2-5-4-12-6-22-1 8-3 16-6 25-3 7-12 6-14-1-2-7-3-16-3-26 0-40 26-70 66-70Z"

    /// Chevelure longue, qui retombe derrière les épaules.
    private static let backHairFemale = "M200 44c46 0 72 32 72 76 0 42-3 84-7 120-1 11-17 12-19 1-5-33-7-68-7-94-3 14-6 23-9 29h-60c-3-6-6-15-9-29 0 26-2 61-7 94-2 11-18 10-19-1-4-36-7-78-7-120 0-44 26-76 72-76Z"

    private static let capePath = "M154 198c-20 8-32 26-38 52-7 30-9 66-7 98h182c2-32 0-68-7-98-6-26-18-44-38-52 8 20 2 42-46 42s-54-22-46-42Z"

    private static let torsoGi = "M200 190 152 206c-6 2-9 7-9 14l7 84h100l7-84c0-7-3-12-9-14Z"
    private static let chest = "M200 194 181 200l19 46 19-46Z"
    private static let lapelL = "M154 202 168 196 207 252 199 270Z"
    private static let lapelR = "M246 202 232 196 193 252 201 270Z"
    private static let wearA = "M154 242l14 10-16 8Z"
    private static let wearB = "M247 268l-16 6 14 12Z"
    private static let wearC = "M234 228l10 14"
    private static let beltTailL = "M190 314h11l-4 35h-11z"
    private static let beltTailR = "M202 314h11l5 31h-11z"
    private static let neck = "M188 172h24v28h-24z"
    private static let face = "M200 70c40 0 56 26 56 58 0 25-9 44-24 56-9 8-22 13-32 13s-23-5-32-13c-15-12-24-31-24-56 0-32 16-58 56-58Z"
    private static let lidL = "M163 142c6-13 28-15 34-3"
    private static let lidR = "M237 142c-6-13-28-15-34-3"
    private static let browL = "M162 123c9-6 24-6 32-2"
    private static let browR = "M238 123c-9-6-24-6-32-2"
    private static let mouthShut = "M192 177c5 7 11 7 16 0"
    private static let mouthOpen = "M185 171c10-5 20-5 30 0-2 19-11 28-15 28s-13-9-15-28Z"
    private static let tongue = "M192 189c5-4 11-4 16 0-2 7-5 10-8 10s-6-3-8-10Z"
    private static let bangsSpiky = "M142 128c-3-46 24-76 58-76s61 30 58 76l-15-30-8 26-18-36-11 32-14-38-13 34-12-28-13 38Z"
    private static let bangsBowl = "M142 134c-4-50 24-82 58-82s62 32 58 82c-7-29-12-46-16-56-11 10-25 16-42 16s-31-6-42-16c-4 10-9 27-16 56Z"
    private static let bandFront = "M146 112c17-10 40-14 54-14s37 4 54 14l-2 17c-18-10-36-14-52-14s-34 4-52 14Z"
    private static let bandTail = "M253 118l33 9 8 25-39-20Z"
}
