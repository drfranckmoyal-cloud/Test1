import SwiftUI

/// L'ouverture d'un nouveau jalon : une page pleine, une fois.
///
/// C'est le moment où l'histoire avance en même temps que l'entraînement.
/// Elle ne se montre qu'à la première ouverture d'une étape — revoir la même
/// page à chaque séance la viderait de son sens — mais reste consultable
/// depuis le parcours.
struct StageIntroView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let program: Program
    let stageIndex: Int
    var onEnter: () -> Void

    @State private var imageIn = false
    @State private var logoIn = false
    @State private var textIn = false
    @State private var buttonIn = false

    private var stage: ProgramDefinition.Stage? {
        let stages = ProgramLibrary.stages(program.id)
        guard stageIndex >= 0, stageIndex < stages.count else { return nil }
        return stages[stageIndex]
    }

    private var title: String {
        if program.id == .saitama, store.progress(.saitama).saitama?.isComplete == true {
            return SaitamaBlocks.spec(stageIndex + 1).title
        }
        return store.shape(of: program.id).title(ofStage: stageIndex)
    }

    private var subtitle: String {
        "Étape \(stageIndex + 1) sur \(store.shape(of: program.id).stageCount)"
    }

    /// Le récit de l'étape, tel que sa spécification le donne. Rien n'est
    /// écrit ici : on montre ce qui existe, ou le but sportif à défaut.
    private var story: String? {
        if program.id == .saitama, store.progress(.saitama).saitama?.isComplete == true {
            return SaitamaBlocks.spec(stageIndex + 1).arc
        }
        return stage?.goal
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if let art = ProgramVisuals.stage(program.id, index: stageIndex) {
                StageArtwork(name: art, presentation: .hero,
                             label: "\(program.name), \(title)")
                    .ignoresSafeArea()
                    .opacity(imageIn ? 1 : 0)
                    .scaleEffect(reduceMotion ? 1 : (imageIn ? 1 : 1.06))
            } else {
                program.gradient.ignoresSafeArea()
            }

            // le texte descend dans la zone sombre du bas : posé au milieu,
            // il tombait sur le cœur de l'illustration et devenait illisible
            VStack(spacing: 0) {
                Spacer(minLength: 0)

                VStack(spacing: 14) {
                    ProgramLogo(program: program, height: 78)
                        .opacity(logoIn ? 1 : 0)
                        .scaleEffect(reduceMotion ? 1 : (logoIn ? 1 : 0.92))

                    VStack(spacing: 9) {
                        Text("NOUVELLE ÉTAPE")
                            .font(.ui(10, .bold))
                            .kerning(2.8)
                            .foregroundStyle(Theme.cream.opacity(0.8))
                        Text(title.uppercased())
                            .font(.display(34))
                            .foregroundStyle(Theme.cream)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .shadow(color: .black.opacity(0.6), radius: 10, y: 3)
                        Text(subtitle)
                            .font(.ui(12, .semibold))
                            .foregroundStyle(Theme.cream.opacity(0.8))
                        if let story = story {
                            Text(story)
                                .font(.system(size: 15, weight: .regular, design: .serif))
                                .lineSpacing(3)
                                .foregroundStyle(Theme.cream.opacity(0.92))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 4)
                        }
                    }
                    .opacity(textIn ? 1 : 0)
                    .offset(y: reduceMotion ? 0 : (textIn ? 0 : 14))
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 26)

                PrimaryButton(title: "ENTRER DANS L'ÉTAPE", tint: program.light) {
                    store.markStageSeen(program.id, stage: stageIndex)
                    onEnter()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
                .opacity(buttonIn ? 1 : 0)
            }
        }
        .onAppear(perform: reveal)
    }

    /// L'image, puis le logo, puis le texte, puis le bouton. Court : on entre
    /// dans une étape, on ne regarde pas un générique.
    private func reveal() {
        guard !reduceMotion else {
            withAnimation(.easeOut(duration: 0.25)) {
                imageIn = true; logoIn = true; textIn = true; buttonIn = true
            }
            return
        }
        withAnimation(.easeOut(duration: 0.55)) { imageIn = true }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.72).delay(0.25)) { logoIn = true }
        withAnimation(.easeOut(duration: 0.35).delay(0.45)) { textIn = true }
        withAnimation(.easeOut(duration: 0.3).delay(0.7)) { buttonIn = true }
    }
}
