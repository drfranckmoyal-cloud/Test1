import SwiftUI

/// Le cercle tracé au pinceau, ouvert en haut.
///
/// Ce n'est pas un `Circle().stroke` : un trait d'épaisseur constante se voit
/// tout de suite, il a l'air fait au compas. Ici le trait attaque fin, s'épaissit,
/// puis s'efface — et le rayon tremble très légèrement, comme une main.
///
/// La forme est pleine, pas un contour : on construit le bord extérieur dans un
/// sens, le bord intérieur dans l'autre, et on ferme.
struct EnsoShape: Shape {

    /// La part du tour laissée ouverte, entre 0 et 1.
    var gap: Double = 0.09
    /// Où le pinceau se pose, en degrés (0 = à droite, sens horaire).
    ///
    /// En haut à droite : le geste part de là, fait le tour, et revient mourir
    /// au même endroit. L'ouverture tombe donc sous le disque rouge.
    var startAngle: Double = -58
    /// L'épaisseur maximale du trait, en fraction du diamètre.
    var thickness: Double = 0.085
    /// La part du trait déjà tracée, entre 0 et 1.
    ///
    /// C'est ce qui permet d'animer le geste. Un `trim` ne marcherait pas : la
    /// forme est pleine, pas un contour, et le tronquer donnerait une tache qui
    /// grandit au lieu d'un trait qui avance.
    var progress: Double = 1

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let drawn = min(max(progress, 0), 1)
        guard drawn > 0.001 else { return Path() }

        let side = min(rect.width, rect.height)
        let radius = side / 2 * 0.86
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let fullSweep = (1 - gap) * 2 * .pi
        let maxWidth = side * thickness
        let steps = 200

        var outer: [CGPoint] = []
        var inner: [CGPoint] = []
        outer.reserveCapacity(steps + 1)
        inner.reserveCapacity(steps + 1)

        for step in 0...steps {
            // `t` est la position le long du trait *complet* : le profil
            // d'épaisseur ne se recalcule donc pas à chaque image, et la pointe
            // reste franche pendant que le geste avance.
            let t = Double(step) / Double(steps) * drawn
            let angle = startAngle * .pi / 180 + t * fullSweep
            let width = maxWidth * widthProfile(t)
            // Le tremblé : assez pour que ça respire, pas assez pour qu'on le voie.
            let wobble = radius * 0.013 * sin(t * 9.4 + 0.7)
            let r = radius + wobble

            outer.append(CGPoint(
                x: center.x + cos(angle) * (r + width / 2),
                y: center.y + sin(angle) * (r + width / 2)
            ))
            inner.append(CGPoint(
                x: center.x + cos(angle) * (r - width / 2),
                y: center.y + sin(angle) * (r - width / 2)
            ))
        }

        var path = Path()
        guard let first = outer.first else { return path }
        path.move(to: first)
        for point in outer.dropFirst() { path.addLine(to: point) }
        for point in inner.reversed() { path.addLine(to: point) }
        path.closeSubpath()
        return path
    }

    /// Le profil d'épaisseur du trait, de l'attaque à la fuite.
    private func widthProfile(_ t: Double) -> Double {
        let attack = min(t / 0.10, 1)            // le pinceau se pose
        let release = min((1 - t) / 0.24, 1)     // et se relève
        let body = 0.70 + 0.30 * sin(t * .pi)    // plein dans le virage
        return max(0.06, attack * pow(release, 1.7) * body)
    }
}

/// Le disque rouge. Encre posée à plat, un peu plus dense sur les bords —
/// c'est ce qui l'empêche de ressembler à une pastille d'interface.
struct SunMark: View {
    var diameter: CGFloat = 96

    var body: some View {
        Circle()
            // Plat sur presque tout le disque : seul le bord fonce, là où le
            // pigment s'accumule en séchant.
            .fill(
                RadialGradient(
                    gradient: Gradient(stops: [
                        .init(color: Theme.seal, location: 0),
                        .init(color: Theme.seal, location: 0.90),
                        .init(color: Theme.sealDeep, location: 1),
                    ]),
                    center: .center,
                    startRadius: 0,
                    endRadius: diameter / 2
                )
            )
            .frame(width: diameter, height: diameter)
            .accessibilityHidden(true)
    }
}

/// Le sceau : un carré vermillon, le caractère réservé en clair dedans.
///
/// C'est la marque la plus chinoise de la planche — le 印章 qu'on appose au bas
/// d'un rouleau.
struct SealMark: View {
    var side: CGFloat = 34
    var glyph: String = "说"

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: side * 0.10, style: .continuous)
                .fill(Theme.seal)
            Text(glyph)
                .font(Theme.hanzi(side * 0.62))
                .foregroundStyle(Theme.paper)
        }
        .frame(width: side, height: side)
        .accessibilityHidden(true)
    }
}

/// La marque complète : le cercle, le disque, le caractère.
///
/// Une seule vue pour tous les usages — l'écran de lancement, l'en-tête, le
/// générateur d'icône s'en inspire. Tout est proportionnel à `size`, donc elle
/// reste juste à 40 points comme à 400.
struct ShuoMark: View {
    var size: CGFloat = 220
    /// Le cercle et le caractère prennent cette couleur ; le disque reste rouge.
    var inkColor: Color = Theme.ink

    var body: some View {
        ZStack {
            EnsoShape()
                .fill(inkColor)
                .frame(width: size, height: size)

            // Le disque mord sur le cercle, en haut à droite, là où le trait
            // s'interrompt.
            SunMark(diameter: size * 0.34)
                .offset(x: size * 0.30, y: -size * 0.30)

            Text("说")
                .font(Theme.hanzi(size * 0.41))
                .foregroundStyle(inkColor)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Shuō")
    }
}

/// Le logo horizontal : la marque, puis le nom et la signature.
struct HorizontalLogo: View {
    var markSize: CGFloat = 64

    var body: some View {
        HStack(spacing: markSize * 0.32) {
            ShuoMark(size: markSize)
            VStack(alignment: .leading, spacing: 4) {
                Text("Shuō")
                    .font(Theme.wordmark(markSize * 0.46))
                    .foregroundStyle(Theme.ink)
                Text(Theme.slogan)
                    .font(.system(size: markSize * 0.17, weight: .regular))
                    .tracking(markSize * 0.055)
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Shuō — \(Theme.slogan)")
    }
}
