import SwiftUI

/// La carte du programme : les huit blocs, ce que chacun vise, et où l'on se
/// situe dedans.
///
/// Sans cet écran, le pratiquant répond à dix questions puis se retrouve
/// devant une séance isolée, sans savoir où elle mène ni combien il en reste.
struct ProgramJourneyView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    let program: Program
    /// Vrai quand l'écran s'ouvre juste après le lancement du programme.
    var isIntroduction: Bool = false

    @State private var openBlock: Int?

    private var tint: Color { program.light }
    private var blocks: [SaitamaBlockSpec] { program.id == .saitama ? SaitamaBlocks.all : [] }

    // MARK: - Où l'on en est

    private var perWeek: Int {
        store.schedule(of: program.id)?.sessionsPerWeek
            ?? store.schedulingRules(of: program.id)?.recommendedSessionsPerWeek ?? 5
    }
    private var done: Int { store.progress(program.id).completedSessions }
    private var position: SaitamaPlan.Position {
        SaitamaPlan.position(sessionIndex: done, sessionsPerWeek: perWeek)
    }
    private var currentBlock: Int { position.blockIndex }

    /// Séances faites et totales dans le bloc en cours.
    private var blockProgress: (done: Int, total: Int) {
        let first = SaitamaPlan.firstWeek(ofBlock: currentBlock)
        let weeks = SaitamaPlan.weeks(inBlock: currentBlock)
        let total = weeks * perWeek
        let doneBefore = (first - 1) * perWeek
        return (max(0, done - doneBefore), total)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if isIntroduction { welcome }
                    header
                    if blocks.isEmpty { unavailable } else { map }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
            .background(Theme.ground)
            .navigationTitle(isIntroduction ? "Ton parcours" : program.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(isIntroduction ? "Commencer" : "Fermer") { dismiss() }
                        .font(.ui(15, .bold))
                }
            }
        }
        .onAppear { openBlock = currentBlock }
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("TON PROGRAMME EST PRÊT")
                .font(.ui(10, .bold))
                .kerning(2.2)
                .foregroundStyle(tint)
            Text("Voilà où tu vas")
                .font(.display(27))
                .foregroundStyle(Theme.text)
            Text("Huit blocs, chacun avec son repère à atteindre. Tu avances bloc par bloc, et chaque bloc terminé laisse une trace dans ta collection.")
                .font(.ui(14))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 4)
    }

    // MARK: - Où j'en suis

    private var header: some View {
        let block = SaitamaBlocks.spec(currentBlock)
        let inBlock = blockProgress

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    ProgressRing(progress: inBlock.total > 0
                                 ? Double(inBlock.done) / Double(inBlock.total) : 0,
                                 lineWidth: 8, tint: tint)
                    VStack(spacing: 0) {
                        Text("\(currentBlock)")
                            .font(.display(24))
                            .foregroundStyle(tint)
                        Text("SUR 8")
                            .font(.ui(7, .bold))
                            .kerning(0.6)
                            .foregroundStyle(Theme.muted)
                    }
                }
                .frame(width: 72, height: 72)

                VStack(alignment: .leading, spacing: 3) {
                    Text("TU ES ICI")
                        .font(.ui(9, .bold))
                        .kerning(1.8)
                        .foregroundStyle(Theme.muted)
                    Text(block.title)
                        .font(.display(20))
                        .foregroundStyle(Theme.text)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Semaine \(position.week) · séance \(inBlock.done + 1) sur \(inBlock.total) du bloc")
                        .font(.ui(12, .semibold))
                        .foregroundStyle(Theme.muted)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                tally(block.benchmark, "REPÈRE DU BLOC")
                if let weeks = store.estimatedWeeksRemaining(of: program.id) {
                    tally("\(weeks) sem.", "ESTIMÉ AVANT LA FIN")
                }
                tally("\(perWeek)/sem.", "TON RYTHME")
            }
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.border, lineWidth: 1))
    }

    private func tally(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.ui(13, .bold))
                .foregroundStyle(Theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.ui(8, .bold))
                .kerning(0.6)
                .foregroundStyle(Theme.muted)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 9)
        .padding(.horizontal, 11)
        .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - La carte des blocs

    private var map: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "LES HUIT BLOCS")
            VStack(spacing: 0) {
                ForEach(blocks) { block in
                    blockRow(block)
                    if block.index < blocks.count { connector(after: block) }
                }
            }
            bossRow
        }
    }

    private func blockRow(_ block: SaitamaBlockSpec) -> some View {
        let state = state(of: block)
        let isOpen = openBlock == block.index

        return VStack(spacing: 0) {
            Button {
                Haptics.tap()
                withAnimation(.easeInOut(duration: 0.2)) {
                    openBlock = isOpen ? nil : block.index
                }
            } label: {
                HStack(spacing: 13) {
                    marker(state, number: block.index)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(block.title)
                            .font(.ui(15, .bold))
                            .foregroundStyle(state == .locked ? Theme.dim : Theme.text)
                            .multilineTextAlignment(.leading)
                        Text(block.arc)
                            .font(.ui(11))
                            .foregroundStyle(Theme.muted)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 6)

                    if state == .done, store.state.rewards.has(block.rewardId) {
                        Image(systemName: "rosette")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.gold)
                    }
                    Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.dim)
                }
                .padding(14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isOpen { blockDetail(block, state) }
        }
        .background(state == .current ? tint.opacity(0.08) : Theme.surface,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(state == .current ? tint.opacity(0.55) : Theme.border,
                    lineWidth: state == .current ? 2 : 1))
    }

    private func blockDetail(_ block: SaitamaBlockSpec, _ state: BlockState) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            detail("Repère à atteindre", block.benchmark)
            detail("Routine", "\(block.routineVolume) de chaque · \(block.routinePolicy.label.lowercased())")
            detail("Sortie longue", ObjectiveUnit.meters.format(block.longMeters.lowerBound))
            detail("Durée", "\(SaitamaPlan.weeks(inBlock: block.index)) semaines · \(SaitamaPlan.weeks(inBlock: block.index) * perWeek) séances")

            if let reward = RewardCatalog.reward(block.rewardId) {
                HStack(spacing: 8) {
                    Image(systemName: store.state.rewards.has(reward.rewardId) ? "rosette" : "lock.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(store.state.rewards.has(reward.rewardId) ? Theme.gold : Theme.dim)
                    Text(store.state.rewards.has(reward.rewardId)
                         ? "Vignette obtenue : \(reward.title)"
                         : "Vignette à débloquer")
                        .font(.ui(11, .semibold))
                        .foregroundStyle(store.state.rewards.has(reward.rewardId) ? Theme.gold : Theme.muted)
                }
                .padding(.top, 2)
            }

            if state == .current {
                Text("C'est le bloc en cours. Il se valide quand au moins trois domaines sur quatre atteignent le repère.")
                    .font(.ui(11))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
    }

    private func detail(_ label: String, _ value: String?) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(label.uppercased())
                .font(.ui(9, .bold))
                .kerning(0.9)
                .foregroundStyle(Theme.dim)
                .frame(width: 116, alignment: .leading)
            Text(value ?? "—")
                .font(.ui(12, .semibold))
                .foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private var bossRow: some View {
        let eligible = store.saitamaBossEligibility.isEligible
        let won = store.progress(.saitama).bossDefeated

        return HStack(spacing: 13) {
            ZStack {
                Circle()
                    .fill(won ? Theme.gold : (eligible ? Theme.gold.opacity(0.22) : Theme.surfaceAlt))
                    .frame(width: 34, height: 34)
                Image(systemName: won ? "crown.fill" : (eligible ? "flame.fill" : "lock.fill"))
                    .font(.system(size: 14))
                    .foregroundStyle(won ? Theme.ink : (eligible ? Theme.gold : Theme.dim))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("COMBAT FINAL")
                    .font(.display(15))
                    .foregroundStyle(won || eligible ? Theme.text : Theme.dim)
                Text(won ? "Gagné — Serious Mode ouvert"
                     : "100 pompes, 100 abdominaux, 100 squats et 10 km d'une traite")
                    .font(.ui(11))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(won || eligible ? Theme.gold.opacity(0.5) : Theme.border, lineWidth: 1))
        .padding(.top, 6)
    }

    // MARK: - État d'un bloc

    private enum BlockState { case done, current, locked }

    private func state(of block: SaitamaBlockSpec) -> BlockState {
        if store.progress(program.id).completedBlocks.contains(block.id) { return .done }
        if block.index == currentBlock { return .current }
        return block.index < currentBlock ? .done : .locked
    }

    private func marker(_ state: BlockState, number: Int) -> some View {
        ZStack {
            Circle()
                .fill(state == .done ? tint : (state == .current ? tint.opacity(0.22) : Theme.surfaceAlt))
                .frame(width: 34, height: 34)
            if state == .done {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.ink)
            } else {
                Text("\(number)")
                    .font(.display(14))
                    .foregroundStyle(state == .current ? tint : Theme.dim)
            }
        }
    }

    private func connector(after block: SaitamaBlockSpec) -> some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(block.index < currentBlock ? tint : Theme.border)
                .frame(width: 2, height: 14)
                .padding(.leading, 30)
            if block.endsWithDeload {
                Text("semaine allégée")
                    .font(.ui(9, .bold))
                    .kerning(0.8)
                    .foregroundStyle(Theme.muted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.surfaceAlt, in: Capsule())
                    .padding(.leading, 10)
            }
            Spacer(minLength: 0)
        }
    }

    private var unavailable: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ce programme n'a pas encore sa carte")
                .font(.display(18))
                .foregroundStyle(Theme.text)
            Text("Seul Saitama est découpé en blocs pour l'instant. Les autres avancent par étapes, visibles dans le détail du programme.")
                .font(.ui(13))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
