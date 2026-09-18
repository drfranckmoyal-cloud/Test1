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

/// L'écran de lancement : un grand 说 calligraphique, seul.
struct LaunchView: View {
    let onEnter: () -> Void

    @State private var inkRevealed = false
    @State private var sealShown = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Button(action: onEnter) {
                ZStack(alignment: .bottomTrailing) {
                    Text("说")
                        .font(Theme.hanzi(180))
                        .foregroundStyle(Theme.ink)
                        // L'encre se dépose de haut en bas, une fois, au premier
                        // affichage. Rien de plus : ce n'est pas un logo animé.
                        .mask(
                            GeometryReader { geometry in
                                Rectangle()
                                    .frame(height: inkRevealed ? geometry.size.height : 0)
                                    .frame(maxHeight: .infinity, alignment: .top)
                            }
                        )

                    Rectangle()
                        .fill(Theme.seal)
                        .frame(width: 22, height: 22)
                        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                        .opacity(sealShown ? 1 : 0)
                        .offset(x: 14, y: -6)
                }
                .padding(40)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Entrer dans Shuō")

            Text("Shuō")
                .font(Theme.title)
                .foregroundStyle(Theme.ink)
            Text("Touche le caractère pour commencer")
                .font(Theme.caption)
                .foregroundStyle(Theme.inkSoft)

            Spacer()
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.1)) { inkRevealed = true }
            withAnimation(.easeIn(duration: 0.4).delay(1.1)) { sealShown = true }
        }
    }
}
