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

/// L'écran de lancement : la marque, le nom, la signature.
///
/// La marque ne s'allume pas, elle infuse — elle arrive floue et se resserre,
/// comme de l'encre qui prend sur le papier. C'est la seule animation qui aille
/// avec un tracé au pinceau : le faire mine de se dessiner tout seul sonnerait
/// faux, puisque c'est une image et non un trait calculé.
struct LaunchView: View {
    let onEnter: () -> Void

    @State private var inkSettled = false
    @State private var wordsShown = false

    var body: some View {
        ZStack {
            Theme.paper.ignoresSafeArea()

            // La colonne chinoise contre le bord gauche, comme la marge d'un
            // rouleau. Le sceau, lui, est déjà dans la calligraphie.
            VStack {
                HStack {
                    InkColumn()
                        .opacity(wordsShown ? 1 : 0)
                        .padding(.leading, 26)
                    Spacer()
                }
                .padding(.top, 40)
                Spacer()
            }

            VStack(spacing: 28) {
                Spacer()

                Button(action: onEnter) {
                    ShuoMark(size: 260)
                        .opacity(inkSettled ? 1 : 0)
                        .blur(radius: inkSettled ? 0 : 9)
                        .scaleEffect(inkSettled ? 1 : 0.94)
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
        withAnimation(.easeOut(duration: 1.1)) { inkSettled = true }
        withAnimation(.easeIn(duration: 0.7).delay(0.8)) { wordsShown = true }
    }
}
