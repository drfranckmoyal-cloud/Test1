import SwiftUI

/// L'ouverture de l'application : le panorama, deux secondes, puis l'app.
///
/// Ce n'est pas l'écran de lancement du système — celui-là reste vide et
/// instantané. C'est la respiration qui vient juste après : le temps de voir
/// où l'on met les pieds avant que l'interface n'arrive.
///
/// Le visuel porte déjà son logo et sa devise. La vue n'écrit rien par-dessus,
/// n'ajoute ni bouton, ni indicateur, ni texte : elle le laisse respirer.
struct BudokaiOpeningView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Appelé quand l'ouverture est finie.
    var onFinish: () -> Void

    /// Combien de temps le panorama reste pleinement visible.
    private let dwell: Double = 1.6
    private let entrance: Double = 0.5
    private let exit: Double = 0.3

    @State private var shown = false
    @State private var leaving = false
    @State private var drift = false
    @State private var done = false

    var body: some View {
        GeometryReader { geometry in
            // Le panorama est plus large, proportionnellement, qu'un iPhone :
            // le remplir coupe environ un dixième de chaque côté. Le logo, la
            // devise et la ligne des héros restent lisibles, et le plein cadre
            // vaut mieux qu'un compromis à bandes — c'est une ouverture, pas
            // une photo encadrée.
            ZStack {
                // le même fond que l'écran de lancement du système : sans lui,
                // un éclair blanc s'intercale entre les deux
                Theme.groundDeep.ignoresSafeArea()

                Image("budokai_opening")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .scaleEffect(scale)
                    .clipped()
                    .ignoresSafeArea()
            }
            .opacity(shown && !leaving ? 1 : 0)
        }
        .ignoresSafeArea()
        .accessibilityElement()
        .accessibilityLabel("Budokai Ichiban, s'entraîner avec les légendes")
        // un toucher passe l'ouverture : personne ne doit subir un splash
        .contentShape(Rectangle())
        .onTapGesture { finish() }
        .onAppear(perform: begin)
    }

    /// Le mouvement : une arrivée douce, une dérive imperceptible, une sortie
    /// qui s'éloigne à peine. Rien de spectaculaire, et rien du tout quand le
    /// téléphone demande à réduire les animations.
    private var scale: CGFloat {
        guard !reduceMotion else { return 1 }
        if leaving { return 1.01 }
        if !shown { return 1.02 }
        return drift ? 1.015 : 1
    }

    private func begin() {
        withAnimation(.easeOut(duration: reduceMotion ? 0.3 : entrance)) { shown = true }
        if !reduceMotion {
            withAnimation(.easeInOut(duration: dwell + entrance)) { drift = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + entrance + dwell) { finish() }
    }

    private func finish() {
        guard !done else { return }
        done = true
        withAnimation(.easeIn(duration: reduceMotion ? 0.2 : exit)) { leaving = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.2 : exit)) {
            onFinish()
        }
    }
}
