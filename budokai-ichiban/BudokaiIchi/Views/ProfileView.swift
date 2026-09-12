import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var store: GameStore
    @State private var showSettings = false
    @State private var showAvatar = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                avatarCard
                rankHeader
                characteristics
                figures
                if !store.state.equipment.isEmpty { equipment }
                if !store.state.badges.isEmpty { badges }
                GhostButton(title: "Réglages") { showSettings = true }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 26)
        }
        .scrollIndicators(.hidden)
        .background(Theme.ground)
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showAvatar) { AvatarEditorView() }
    }

    /// Le combattant, sa ceinture, et l'accès à sa personnalisation.
    private var avatarCard: some View {
        Button {
            Haptics.tap()
            showAvatar = true
        } label: {
            HStack(spacing: 4) {
                AvatarView(config: store.state.avatar, pose: .guardStance,
                           belt: store.belt, width: 150)

                VStack(alignment: .leading, spacing: 6) {
                    Text(store.belt.label.uppercased())
                        .font(.display(15))
                        .foregroundStyle(Theme.text)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(store.belt.japanese)
                        .font(.ui(13))
                        .foregroundStyle(Theme.muted)
                    if let next = nextBelt {
                        Text("Encore \(next.streakNeeded - store.state.streak) jours de série pour la \(next.label.lowercased()).")
                            .font(.ui(11))
                            .foregroundStyle(Theme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 2)
                    }
                    Text("PERSONNALISER")
                        .font(.ui(10, .bold))
                        .kerning(1.2)
                        .foregroundStyle(Theme.crimson)
                        .padding(.top, 4)
                }
                Spacer(minLength: 0)
            }
            .padding(.trailing, 14)
            .frame(maxWidth: .infinity)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    /// La ceinture juste au-dessus de celle déjà obtenue.
    private var nextBelt: Belt? {
        Belt.allCases.first { $0.streakNeeded > store.state.streak }
    }

    private var rankHeader: some View {
        HStack(spacing: 16) {
            RankBadge(rank: store.rank, size: 82)
            VStack(alignment: .leading, spacing: 5) {
                Text("NIVEAU \(store.level)")
                    .font(.display(22))
                    .foregroundStyle(Theme.text)
                Text("\(store.state.xp.grouped) XP · \(store.xpToNextLevel.grouped) avant le niveau \(store.level + 1)")
                    .font(.ui(11, .semibold))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                ProgressBar(value: store.levelProgress, height: 7, tint: Theme.gold)
            }
        }
    }

    private var characteristics: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "CARACTÉRISTIQUES")
            HStack(spacing: 18) {
                StatRadar(values: radarValues, size: 156)
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(StatKind.allCases) { kind in
                        VStack(alignment: .leading, spacing: 1) {
                            Text(kind.label.uppercased())
                                .font(.ui(10, .bold))
                                .kerning(1.2)
                                .foregroundStyle(Theme.muted)
                            Text("\(store.state.stat(kind))")
                                .font(.display(24))
                                .foregroundStyle(Theme.gold)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.border, lineWidth: 1))
        }
    }

    private var radarValues: [StatKind: Int] {
        var values: [StatKind: Int] = [:]
        for kind in StatKind.allCases { values[kind] = store.state.stat(kind) }
        return values
    }

    private var figures: some View {
        HStack(spacing: 10) {
            figure("\(store.state.streak)", "SÉRIE EN COURS", highlighted: true)
            figure("\(store.state.bestStreak)", "MEILLEURE SÉRIE")
            figure("\(store.sessionsDone)", "SÉANCES FAITES")
        }
    }

    private func figure(_ value: String, _ label: String, highlighted: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.display(20))
                .foregroundStyle(highlighted ? Theme.crimson : Theme.text)
            Text(label)
                .font(.ui(9, .bold))
                .kerning(0.6)
                .foregroundStyle(Theme.muted)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.border, lineWidth: 1))
    }

    private var equipment: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "ÉQUIPEMENT · \(store.state.equipment.count) / \(Catalog.programs.count)")
            HStack(spacing: 9) {
                ForEach(store.state.equipment, id: \.self) { item in
                    VStack(spacing: 6) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 19))
                            .foregroundStyle(Theme.gold)
                        Text(item)
                            .font(.ui(9, .bold))
                            .foregroundStyle(Theme.muted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Theme.gold.opacity(0.4), lineWidth: 1))
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var badges: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "HAUTS FAITS")
            VStack(spacing: 8) {
                ForEach(store.state.badges, id: \.self) { badge in
                    HStack(spacing: 12) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 15))
                            .foregroundStyle(Theme.gold)
                        Text(badge)
                            .font(.ui(13, .semibold))
                            .foregroundStyle(Theme.text)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 48)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(Theme.border, lineWidth: 1))
                }
            }
        }
    }
}
