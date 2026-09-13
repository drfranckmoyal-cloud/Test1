import SwiftUI

/// La séance du jour, dans le moment de l'histoire où elle se joue.
///
/// La vue ne porte **pas** l'illustration : celle-ci est le fond de la page
/// entière, d'un bord à l'autre, posé par l'écran du jour. Ici il n'y a que ce
/// qui se lit par-dessus — le logo, le nom du jalon, la progression, le
/// contexte et le bouton. Une carte à coins arrondis aurait enfermé l'image
/// dans un cadre, et c'est tout l'inverse de l'effet cherché.
///
/// `standalone` remet le décor pour les écrans d'essai, qui montrent la carte
/// hors de sa page.
struct ArcSessionCard: View {
    let program: Program
    /// Le jalon montré, compté à partir de zéro.
    let stageIndex: Int
    let stageName: String
    let stageCount: Int
    let done: Int
    let total: Int
    let minutes: Int
    /// Vrai quand la vue doit porter elle-même son illustration et son cadre.
    var standalone: Bool = false
    var onOpen: () -> Void = {}

    private var ratio: Double { total > 0 ? Double(done) / Double(total) : 0 }
    private var context: String? {
        NarrationLibrary.stageContext(program.id, stageIndex: stageIndex)
    }

    var body: some View {
        ZStack(alignment: .top) {
            if standalone {
                if let art = ProgramVisuals.arc(program.id, index: stageIndex) {
                    Image(art).resizable().scaledToFill().accessibilityHidden(true)
                } else {
                    program.gradient
                }
                LinearGradient(stops: [
                    .init(color: .black.opacity(0.55), location: 0),
                    .init(color: .black.opacity(0.12), location: 0.26),
                    .init(color: .black.opacity(0.38), location: 0.54),
                    .init(color: .black.opacity(0.90), location: 1)],
                    startPoint: .top, endPoint: .bottom)
            }

            VStack(spacing: 0) {
                ProgramLogo(program: program, height: 84)
                    .padding(.top, standalone ? 22 : 4)

                VStack(spacing: 7) {
                    Text("JALON \(stageIndex + 1) SUR \(stageCount)")
                        .font(.ui(10, .bold))
                        .kerning(2.4)
                        .foregroundStyle(Theme.cream.opacity(0.92))
                        .shadow(color: .black.opacity(0.8), radius: 6, y: 1)
                    Text(stageName.uppercased())
                        .font(.display(28))
                        .foregroundStyle(Theme.cream)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.7)
                        .shadow(color: .black.opacity(0.7), radius: 10, y: 2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 14)
                .padding(.horizontal, 18)

                Spacer(minLength: 26)

                ZStack {
                    ProgressRing(progress: ratio, lineWidth: 11, tint: program.light)
                    VStack(spacing: 2) {
                        Text("\(done)")
                            .font(.display(44))
                            .foregroundStyle(program.light)
                        Text("SUR \(total) SÉANCES")
                            .font(.ui(9, .bold))
                            .kerning(1.4)
                            .foregroundStyle(Theme.cream.opacity(0.92))
                            .shadow(color: .black.opacity(0.8), radius: 5, y: 1)
                    }
                }
                .frame(width: 132, height: 132)
                .shadow(color: .black.opacity(0.5), radius: 12)

                if let context = context {
                    Text(context)
                        .font(.system(size: 14, weight: .regular, design: .serif))
                        .lineSpacing(2)
                        .foregroundStyle(Theme.cream.opacity(0.94))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .shadow(color: .black.opacity(0.7), radius: 8, y: 1)
                        .padding(.horizontal, 26)
                        .padding(.top, 16)
                }

                Text("AU PROGRAMME · \(minutes) MIN")
                    .font(.ui(9, .bold))
                    .kerning(1.8)
                    .foregroundStyle(Theme.cream.opacity(0.9))
                    .shadow(color: .black.opacity(0.8), radius: 5, y: 1)
                    .padding(.top, 14)

                PrimaryButton(title: "OUVRIR LA SÉANCE DU JOUR", tint: program.light, action: onOpen)
                    .padding(.horizontal, 20)
                    .padding(.top, 14)
                    .padding(.bottom, standalone ? 20 : 8)
            }
        }
        .frame(height: 620)
        .clipShape(RoundedRectangle(cornerRadius: standalone ? 20 : 0, style: .continuous))
    }
}
