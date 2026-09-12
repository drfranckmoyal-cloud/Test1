import SwiftUI

/// L'écran de révélation d'une vignette.
struct RewardRevealView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    let reward: Reward
    @State private var appeared = false

    var body: some View {
        ZStack {
            Theme.ground.ignoresSafeArea()
            RadialGradient(colors: [reward.rarity.color.opacity(0.22), .clear],
                           center: .init(x: 0.5, y: 0.34), startRadius: 0, endRadius: 320)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer(minLength: 30)

                Text(reward.rarity.label.uppercased())
                    .font(.ui(10, .bold))
                    .kerning(2.6)
                    .foregroundStyle(reward.rarity.color)

                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Theme.surface)
                        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(reward.rarity.color, lineWidth: 2))
                        .shadow(color: reward.rarity.color.opacity(0.35), radius: 26)

                    VStack(spacing: 12) {
                        Image(systemName: reward.rewardType.icon)
                            .font(.system(size: 44))
                            .foregroundStyle(reward.rarity.color)
                        Text(reward.title.uppercased())
                            .font(.display(25))
                            .foregroundStyle(Theme.text)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.6)
                        if let subtitle = reward.subtitle {
                            Text(subtitle)
                                .font(.ui(13, .semibold))
                                .foregroundStyle(Theme.muted)
                        }
                    }
                    .padding(24)
                }
                .frame(height: 250)
                .padding(.horizontal, 36)
                .scaleEffect(appeared ? 1 : 0.82)
                .opacity(appeared ? 1 : 0)

                VStack(spacing: 8) {
                    Text(reward.arc.uppercased())
                        .font(.ui(10, .bold))
                        .kerning(1.8)
                        .foregroundStyle(Theme.muted)
                    Text(reward.description)
                        .font(.ui(14))
                        .foregroundStyle(Theme.text)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 28)

                Spacer()

                PrimaryButton(title: "AJOUTER À LA COLLECTION", tint: reward.rarity.color) {
                    store.markRevealed(reward.rewardId)
                    dismiss()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.66).delay(0.1)) {
                appeared = true
            }
            Haptics.success()
        }
    }
}

/// La collection, par programme.
struct RewardAlbumView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    @State private var revealing: Reward?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(ProgramID.allCases) { id in
                        let rewards = RewardCatalog.rewards(for: id)
                        if !rewards.isEmpty { album(Catalog.program(id), rewards) }
                    }
                    if RewardCatalog.all.isEmpty { empty }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
            }
            .scrollIndicators(.hidden)
            .background(Theme.ground)
            .navigationTitle("Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
        .fullScreenCover(item: $revealing) { reward in
            RewardRevealView(reward: reward)
        }
    }

    private func album(_ program: Program, _ rewards: [Reward]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionLabel(text: program.name.uppercased())
                Text("\(rewards.filter { store.state.rewards.has($0.rewardId) }.count) / \(rewards.count)")
                    .font(.ui(12, .bold))
                    .foregroundStyle(program.light)
            }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 10)], spacing: 10) {
                ForEach(rewards) { reward in
                    tile(reward, tint: program.light)
                }
            }
        }
    }

    private func tile(_ reward: Reward, tint: Color) -> some View {
        let owned = store.state.rewards.has(reward.rewardId)
        return Button {
            guard owned else { return }
            Haptics.tap()
            revealing = reward
        } label: {
            VStack(spacing: 7) {
                Image(systemName: owned ? reward.rewardType.icon : "lock.fill")
                    .font(.system(size: 21))
                    .foregroundStyle(owned ? reward.rarity.color : Theme.dim)
                Text(owned ? reward.title : "???")
                    .font(.ui(11, .bold))
                    .foregroundStyle(owned ? Theme.text : Theme.dim)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 92)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(owned ? reward.rarity.color.opacity(0.6) : Theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var empty: some View {
        Text("Aucune vignette n'existe encore pour les autres programmes.")
            .font(.ui(13))
            .foregroundStyle(Theme.muted)
    }
}
