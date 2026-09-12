import SwiftUI

/// Première ouverture : on situe le niveau de départ. Le test de forme
/// viendra plus tard ; cette déclaration suffit à calibrer les charges.
struct OnboardingView: View {
    @EnvironmentObject private var store: GameStore
    @State private var tier: Tier = .novice

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 40)

            ZStack {
                Rectangle().fill(Theme.crimson)
                    .frame(width: 132, height: 132)
                    .rotationEffect(.degrees(-4))
                Rectangle().stroke(Theme.text.opacity(0.28), lineWidth: 2)
                    .frame(width: 132, height: 132)
                    .rotationEffect(.degrees(3))
                Text("武")
                    .font(.system(size: 104, weight: .black))
                    .foregroundStyle(Theme.cream)
            }

            Rectangle()
                .fill(Theme.text)
                .frame(width: 168, height: 9)
                .rotationEffect(.degrees(-3))
                .padding(.top, 22)

            Text("BUDOKAI ICHI")
                .font(.display(28))
                .foregroundStyle(Theme.text)
                .padding(.top, 18)

            Text("Neuf maîtres, une seule échelle.")
                .font(.ui(14))
                .foregroundStyle(Theme.muted)
                .padding(.top, 8)

            Spacer(minLength: 30)

            VStack(alignment: .leading, spacing: 12) {
                SectionLabel(text: "OÙ TU EN ES AUJOURD'HUI")
                ForEach(Tier.allCases) { candidate in
                    Button {
                        tier = candidate
                        Haptics.tap()
                    } label: {
                        HStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(label(for: candidate))
                                    .font(.ui(15, .bold))
                                    .foregroundStyle(Theme.text)
                                Text(detail(for: candidate))
                                    .font(.ui(13))
                                    .foregroundStyle(Theme.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: tier == candidate ? "largecircle.fill.circle" : "circle")
                                .font(.system(size: 21))
                                .foregroundStyle(tier == candidate ? Theme.crimson : Theme.dim)
                        }
                        .padding(16)
                        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(tier == candidate ? Theme.crimson : Theme.border, lineWidth: tier == candidate ? 1.5 : 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 22)

            Spacer(minLength: 24)

            PrimaryButton(title: "COMMENCER") {
                store.finishOnboarding(tier: tier)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 30)
        }
        .background(Theme.ground)
    }

    private func label(for tier: Tier) -> String {
        switch tier {
        case .novice: return "Je reprends"
        case .confirme: return "Je suis actif"
        case .classeS: return "Je m'entraîne déjà"
        }
    }

    private func detail(for tier: Tier) -> String {
        switch tier {
        case .novice: return "Peu ou pas de sport depuis un moment. Les charges partent bas et montent doucement."
        case .confirme: return "Du sport de temps en temps. Les programmes sont donnés à leur valeur d'origine."
        case .classeS: return "Plusieurs séances par semaine. Les charges sont relevées d'un tiers."
        }
    }
}
