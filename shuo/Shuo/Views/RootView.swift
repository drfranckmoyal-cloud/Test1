import SwiftUI

/// L'app commence par un caractère. On le touche, on entre.
struct RootView: View {
    @State private var entered = false

    var body: some View {
        Group {
            if entered {
                HomeView()
                    .transition(.opacity)
            } else {
                LaunchView { withAnimation(.easeInOut(duration: 0.5)) { entered = true } }
                    .transition(.opacity)
            }
        }
        .paperBackground()
    }
}

/// L'écran de lancement, d'après la planche d'identité : le cercle au pinceau,
/// le disque rouge, le caractère, le nom, la signature.
///
/// Le cercle se trace au lieu d'apparaître — un enso se dessine d'un geste, et
/// c'est le geste qui fait la marque. Une seconde et demie, une seule fois.
struct LaunchView: View {
    let onEnter: () -> Void

    @State private var strokeDrawn = false
    @State private var glyphShown = false
    @State private var sunShown = false
    @State private var wordsShown = false

    var body: some View {
        ZStack {
            Theme.paper.ignoresSafeArea()

            // La colonne chinoise et le sceau, contre le bord gauche, comme sur
            // un rouleau.
            HStack {
                VStack(spacing: 14) {
                    Text(Theme.tagline)
                        .font(Theme.hanzi(15))
                        .foregroundStyle(Theme.inkSoft)
                        // Une colonne, pas une ligne : c'est ainsi qu'elle est
                        // écrite sur la planche.
                        .lineLimit(nil)
                        .frame(width: 20)
                    SealMark(side: 24)
                }
                .opacity(wordsShown ? 1 : 0)
                .padding(.leading, 26)
                Spacer()
            }

            VStack(spacing: 30) {
                Spacer()

                Button(action: onEnter) {
                    ZStack {
                        EnsoShape(progress: strokeDrawn ? 1 : 0)
                            .fill(Theme.ink)
                            .frame(width: 230, height: 230)

                        SunMark(diameter: 78)
                            .offset(x: 69, y: -69)
                            .opacity(sunShown ? 1 : 0)
                            .scaleEffect(sunShown ? 1 : 0.85)

                        Text("说")
                            .font(Theme.hanzi(94))
                            .foregroundStyle(Theme.ink)
                            .opacity(glyphShown ? 1 : 0)
                    }
                    .frame(width: 300, height: 300)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Entrer dans Shuō")

                VStack(spacing: 10) {
                    Text("Shuō")
                        .font(Theme.wordmark(40))
                        .foregroundStyle(Theme.ink)
                    Text(Theme.slogan)
                        .font(.system(size: 15))
                        .tracking(4.5)
                        .foregroundStyle(Theme.inkSoft)
                }
                .opacity(wordsShown ? 1 : 0)

                Spacer()

                Text("Touche le caractère pour commencer")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.inkSoft)
                    .opacity(wordsShown ? 1 : 0)
                    .padding(.bottom, 30)
            }
        }
        .onAppear(perform: animate)
    }

    private func animate() {
        withAnimation(.easeInOut(duration: 1.35)) { strokeDrawn = true }
        withAnimation(.easeOut(duration: 0.5).delay(0.95)) { glyphShown = true }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(1.3)) { sunShown = true }
        withAnimation(.easeIn(duration: 0.6).delay(1.5)) { wordsShown = true }
    }
}
