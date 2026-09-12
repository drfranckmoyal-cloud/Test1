import SwiftUI

/// L'intervention du héros : il lance la séance, puis il revient une fois
/// qu'elle est faite.
///
/// Ce n'est pas une modale : l'écran reste visible derrière, à peine
/// assombri, et le personnage entre comme dans un jeu. Il reste deux
/// secondes, puis s'efface — ou disparaît au premier toucher.
///
/// Un seul composant sert les neuf héros et les deux moments. Seul le
/// mouvement d'entrée change : le héros du début arrive par le côté, celui de
/// la fin monte depuis le bas avec un léger rebond. L'image porte déjà le
/// personnage, sa bulle et sa phrase : la vue n'écrit rien dessus.
struct HeroSessionPopup: View {
    let asset: HeroPopupAsset
    var onDismiss: () -> Void

    /// Combien de temps le visuel reste en place une fois entré.
    var dwell: Double = 2.1

    /// Vrai quand le héros revient après l'effort.
    private var isCompletion: Bool { asset.phase == .sessionComplete }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var shown = false
    @State private var leaving = false
    /// Empêche qu'un toucher et la minuterie ferment le popup deux fois.
    @State private var dismissed = false

    var body: some View {
        ZStack {
            // le fond s'assombrit à peine : la séance reste lisible derrière
            Color.black
                .opacity(shown && !leaving ? (isCompletion ? 0.20 : 0.22) : 0)
                .ignoresSafeArea()

            GeometryReader { geometry in
                Image(asset.assetName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: geometry.size.width * 0.92,
                           maxHeight: geometry.size.height * 0.76)
                    .shadow(color: .black.opacity(0.45), radius: 24, y: 12)
                    .scaleEffect(scale)
                    .offset(x: offsetX, y: offsetY)
                    .opacity(shown && !leaving ? 1 : 0)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    // un peu plus bas que le centre : le regard tombe dessus
                    .offset(y: geometry.size.height * 0.03)
            }
            .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .onTapGesture { close() }
        .accessibilityElement()
        .accessibilityLabel(asset.phase.accessibilityLabel(asset.hero))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { close() }
        .onAppear(perform: enter)
    }

    // MARK: - Le mouvement

    private var scale: CGFloat {
        if leaving { return isCompletion ? 0.96 : 0.97 }
        guard !reduceMotion else { return shown ? 1 : 0.98 }
        return shown ? 1 : (isCompletion ? 0.90 : 0.92)
    }

    /// Le héros de la fin ne vient pas du côté : il monte, de face.
    private var offsetX: CGFloat {
        guard !reduceMotion, !isCompletion else { return 0 }
        if leaving { return -15 }
        return shown ? 0 : 60
    }

    private var offsetY: CGFloat {
        guard !reduceMotion else { return 0 }
        if leaving { return isCompletion ? -15 : 0 }
        return shown ? 0 : (isCompletion ? 35 : 30)
    }

    private func enter() {
        // l'effort est fini : la note est plus franche qu'au départ
        if isCompletion { Haptics.success() } else { Haptics.light() }

        if reduceMotion {
            withAnimation(.easeOut(duration: 0.25)) { shown = true }
        } else {
            // ressort court, avec le léger dépassement qui donne le poids
            withAnimation(.spring(response: isCompletion ? 0.42 : 0.38,
                                  dampingFraction: isCompletion ? 0.58 : 0.62)) { shown = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + dwell) { close() }
    }

    private func close() {
        guard !dismissed else { return }
        dismissed = true
        withAnimation(.easeIn(duration: 0.24)) { leaving = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) { onDismiss() }
    }
}

// MARK: - Pose sur n'importe quel écran

extension View {
    /// Fait intervenir le héros par-dessus cet écran.
    ///
    /// Tant que `asset` porte un visuel, il s'affiche ; le remettre à nil est
    /// ce qui le fait disparaître.
    func heroPopup(_ asset: Binding<HeroPopupAsset?>,
                   onDismiss: @escaping () -> Void = {}) -> some View {
        overlay {
            if let value = asset.wrappedValue {
                HeroSessionPopup(asset: value) {
                    asset.wrappedValue = nil
                    onDismiss()
                }
                .transition(.identity)
            }
        }
    }
}
