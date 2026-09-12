import SwiftUI

/// Le chemin du programme : une route de jalons, du premier pas au combat
/// final.
///
/// C'est la page de garde d'un programme lancé. Elle ne liste pas des blocs,
/// elle dessine un trajet — et chaque jalon porte d'abord son arc narratif,
/// le détail sportif ne venant qu'en se dépliant.
struct ProgramJourneyView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    let program: Program
    /// Vrai quand l'écran s'ouvre juste après le lancement du programme.
    var isIntroduction: Bool = false

    @State private var opened: Int?
    @State private var showDetail = false
    @State private var showSetup = false

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

    private var blockProgress: (done: Int, total: Int) {
        let first = SaitamaPlan.firstWeek(ofBlock: currentBlock)
        let total = SaitamaPlan.weeks(inBlock: currentBlock) * perWeek
        return (max(0, done - (first - 1) * perWeek), total)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    banner
                    if !store.isActive(program.id) {
                        startCall
                    } else if store.needsSetup(program.id) {
                        setupCall
                    } else if blocks.isEmpty {
                        unavailable
                    } else {
                        roadway
                    }
                    footer
                }
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
            .background(Theme.ground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(isIntroduction ? "C'est parti" : "Fermer") { dismiss() }
                        .font(.ui(15, .bold))
                }
            }
        }
        .sheet(isPresented: $showDetail) { ProgramDetailView(program: program) }
        .sheet(isPresented: $showSetup) {
            ProgramLaunchView(program: program) { store.startProgram(program.id) }
        }
        .onAppear { if isIntroduction { opened = currentBlock } }
    }

    // MARK: - Le bandeau

    private var banner: some View {
        ZStack(alignment: .bottomLeading) {
            program.gradient
            ArtworkFill(name: program.stageImage(max(0, currentBlock - 1))).opacity(0.55)
            LinearGradient(colors: [Color.black.opacity(0.15), Theme.ground],
                           startPoint: .top, endPoint: .bottom)

            VStack(alignment: .leading, spacing: 6) {
                Text(program.family.uppercased())
                    .font(.ui(10, .bold))
                    .kerning(2.4)
                    .foregroundStyle(Theme.cream.opacity(0.9))
                Text(program.name.uppercased())
                    .font(.display(34))
                    .foregroundStyle(Theme.cream)
                Text(bannerLine)
                    .font(.ui(14, .semibold))
                    .foregroundStyle(Theme.cream.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 18)
        }
        .frame(height: 230)
    }

    private var bannerLine: String {
        if !store.isActive(program.id) {
            return "Huit jalons, une histoire, un combat au bout."
        }
        if isIntroduction { return "Voilà la route. Huit étapes, une histoire, un combat au bout." }
        if store.needsSetup(program.id) { return "Il reste ton point de départ à mesurer." }
        return "Tu es au jalon \(currentBlock) sur \(blocks.count)."
    }

    // MARK: - Le départ

    private var start: some View {
        VStack(spacing: 0) {
            Text("LE DÉPART")
                .font(.ui(9, .bold))
                .kerning(2.2)
                .foregroundStyle(Theme.muted)
            path(from: 0.5, to: side(1), height: 38, reached: true)
        }
        .padding(.top, 18)
    }

    // MARK: - Un jalon

    private func milestone(_ block: SaitamaBlockSpec) -> some View {
        let state = state(of: block)
        let isOpen = opened == block.index
        let onLeft = side(block.index) < 0.5

        return VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 14) {
                if !onLeft { label(block, state, aligned: .trailing); Spacer(minLength: 0) }
                node(block, state)
                if onLeft { label(block, state, aligned: .leading); Spacer(minLength: 0) }
            }
            .padding(.horizontal, 22)
            .contentShape(Rectangle())
            .onTapGesture {
                Haptics.tap()
                withAnimation(.easeInOut(duration: 0.22)) {
                    opened = isOpen ? nil : block.index
                }
            }

            if isOpen { card(block, state) }
        }
    }

    /// La pastille du jalon, posée sur la route.
    private func node(_ block: SaitamaBlockSpec, _ state: BlockState) -> some View {
        ZStack {
            if state == .current {
                Circle().fill(tint.opacity(0.18)).frame(width: 74, height: 74)
            }
            Circle()
                .fill(state == .done ? tint : Theme.surface)
                .frame(width: 54, height: 54)
                .overlay(Circle().stroke(state == .locked ? Theme.border : tint,
                                         lineWidth: state == .current ? 3 : 2))

            if state == .done {
                Image(systemName: "checkmark")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Theme.ink)
            } else if state == .locked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(Theme.dim)
            } else {
                Text("\(block.index)")
                    .font(.display(22))
                    .foregroundStyle(tint)
            }
        }
        .frame(width: 78, height: 78)
    }

    /// Le libellé à côté de la pastille : l'arc d'abord, le sport ensuite.
    private func label(_ block: SaitamaBlockSpec, _ state: BlockState,
                       aligned: HorizontalAlignment) -> some View {
        VStack(alignment: aligned, spacing: 3) {
            if state == .current {
                Text("TU ES ICI")
                    .font(.ui(8, .bold))
                    .kerning(1.6)
                    .foregroundStyle(Theme.ink)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(tint, in: Capsule())
            }
            Text(block.title)
                .font(.display(18))
                .foregroundStyle(state == .locked ? Theme.dim : Theme.text)
                .multilineTextAlignment(aligned == .leading ? .leading : .trailing)
                .fixedSize(horizontal: false, vertical: true)
            Text(block.arc)
                .font(.ui(11, .semibold))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(aligned == .leading ? .leading : .trailing)
                .fixedSize(horizontal: false, vertical: true)
            if state == .done, store.state.rewards.has(block.rewardId),
               let reward = RewardCatalog.reward(block.rewardId) {
                HStack(spacing: 4) {
                    Image(systemName: "rosette").font(.system(size: 9))
                    Text(reward.title).font(.ui(10, .bold))
                }
                .foregroundStyle(Theme.gold)
            }
        }
        .frame(maxWidth: 170, alignment: aligned == .leading ? .leading : .trailing)
    }

    // MARK: - Le jalon déplié

    private func card(_ block: SaitamaBlockSpec, _ state: BlockState) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            story(block)
            target(block)
            if state == .current { currentNote }
            rewardLine(block)
        }
        .padding(17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(state == .current ? tint.opacity(0.5) : Theme.border, lineWidth: 1))
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    /// L'histoire de l'arc, en clair. C'est ce qu'on venait chercher.
    private func story(_ block: SaitamaBlockSpec) -> some View {
        let beats = SaitamaNarrative.beats(inBlock: block.index)
            .filter { $0.isVisible(at: store.state.spoilerLevel) }

        return VStack(alignment: .leading, spacing: 9) {
            Text("CE QUI SE PASSE DANS L'HISTOIRE")
                .font(.ui(9, .bold))
                .kerning(1.8)
                .foregroundStyle(tint)

            if let first = beats.first {
                Text(first.storyRecap)
                    .font(.ui(13))
                    .foregroundStyle(Theme.text)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 5) {
                ForEach(beats.dropFirst()) { beat in
                    HStack(alignment: .top, spacing: 8) {
                        Circle()
                            .fill(Theme.dim)
                            .frame(width: 4, height: 4)
                            .padding(.top, 7)
                        Text(beat.narrativeTitle)
                            .font(.ui(12))
                            .foregroundStyle(Theme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            if let sensei = beats.first?.senseiMessage {
                HStack(alignment: .top, spacing: 9) {
                    Rectangle().fill(tint).frame(width: 2)
                    Text(sensei)
                        .font(.ui(12))
                        .italic()
                        .foregroundStyle(Theme.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 2)
            }
        }
    }

    /// Le sport, dit sans jargon.
    private func target(_ block: SaitamaBlockSpec) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("CE QUE TU DOIS TENIR À LA FIN")
                .font(.ui(9, .bold))
                .kerning(1.8)
                .foregroundStyle(Theme.muted)
            Text("\(block.routineVolume) pompes, \(block.routineVolume) abdominaux, \(block.routineVolume) squats, et \(ObjectiveUnit.meters.format(block.benchmarkMeters)) de course.")
                .font(.ui(13, .semibold))
                .foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
            Text("\(SaitamaPlan.weeks(inBlock: block.index)) semaines, soit \(SaitamaPlan.weeks(inBlock: block.index) * perWeek) séances à ton rythme."
                 + (block.endsWithDeload ? " La dernière semaine est allégée." : ""))
                .font(.ui(11))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var currentNote: some View {
        let inBlock = blockProgress
        return VStack(alignment: .leading, spacing: 7) {
            ProgressBar(value: inBlock.total > 0 ? Double(inBlock.done) / Double(inBlock.total) : 0,
                        height: 7, tint: tint)
            Text("Séance \(inBlock.done + 1) sur \(inBlock.total) de ce jalon."
                 + (store.estimatedWeeksRemaining(of: program.id).map { " Environ \($0) semaines avant la fin du parcours." } ?? ""))
                .font(.ui(11, .semibold))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func rewardLine(_ block: SaitamaBlockSpec) -> some View {
        let owned = store.state.rewards.has(block.rewardId)
        let reward = RewardCatalog.reward(block.rewardId)
        return HStack(spacing: 9) {
            Image(systemName: owned ? "rosette" : "gift")
                .font(.system(size: 13))
                .foregroundStyle(owned ? Theme.gold : Theme.dim)
            Text(owned
                 ? "Vignette obtenue : \(reward?.title ?? "")"
                 : "Une vignette t'attend à la sortie de ce jalon.")
                .font(.ui(11, .semibold))
                .foregroundStyle(owned ? Theme.gold : Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - La route

    /// Position horizontale d'un jalon, en fraction de largeur. Le trajet
    /// serpente au lieu de s'empiler.
    private func side(_ index: Int) -> CGFloat {
        index % 2 == 1 ? 0.26 : 0.74
    }

    private func connector(after block: SaitamaBlockSpec) -> some View {
        let next = block.index + 1
        let reached = block.index < currentBlock
        return Group {
            if next <= blocks.count {
                path(from: side(block.index), to: side(next), height: 54, reached: reached)
            } else {
                path(from: side(block.index), to: 0.5, height: 54, reached: reached)
            }
        }
    }

    /// Un segment de route, tracé en courbe d'un jalon au suivant.
    private func path(from: CGFloat, to: CGFloat, height: CGFloat, reached: Bool) -> some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            var shape = Path()
            let start = CGPoint(x: width * from, y: 0)
            let end = CGPoint(x: width * to, y: height)
            shape.move(to: start)
            shape.addCurve(to: end,
                           control1: CGPoint(x: start.x, y: height * 0.6),
                           control2: CGPoint(x: end.x, y: height * 0.4))
            return shape
                .stroke(reached ? tint : Theme.border,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round,
                                           dash: reached ? [] : [5, 7]))
        }
        .frame(height: height)
    }

    // MARK: - L'arrivée

    private var finish: some View {
        let eligible = store.saitamaBossEligibility.isEligible
        let won = store.progress(.saitama).bossDefeated

        return VStack(spacing: 9) {
            ZStack {
                if won || eligible {
                    Circle().fill(Theme.gold.opacity(0.18)).frame(width: 86, height: 86)
                }
                Circle()
                    .fill(won ? Theme.gold : Theme.surface)
                    .frame(width: 62, height: 62)
                    .overlay(Circle().stroke(won || eligible ? Theme.gold : Theme.border, lineWidth: 2))
                Image(systemName: won ? "crown.fill" : (eligible ? "flame.fill" : "lock.fill"))
                    .font(.system(size: 22))
                    .foregroundStyle(won ? Theme.ink : (eligible ? Theme.gold : Theme.dim))
            }

            Text("LE COMBAT FINAL")
                .font(.display(17))
                .foregroundStyle(won || eligible ? Theme.text : Theme.dim)
            Text(won
                 ? "Gagné. Le Serious Mode est ouvert."
                 : "Cent pompes, cent abdominaux, cent squats, et dix kilomètres d'une seule traite.")
                .font(.ui(12))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 40)
        }
        .padding(.top, 4)
    }

    private var footer: some View {
        Button {
            Haptics.tap()
            showDetail = true
        } label: {
            Text("Voir la fiche technique du programme")
                .font(.ui(12, .semibold))
                .foregroundStyle(Theme.muted)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
        }
        .buttonStyle(.plain)
        .padding(.top, 24)
    }

    // MARK: - État d'un jalon

    private enum BlockState { case done, current, locked }

    private func state(of block: SaitamaBlockSpec) -> BlockState {
        guard store.isActive(program.id) else { return block.index == 1 ? .current : .locked }
        if store.progress(program.id).completedBlocks.contains(block.id) { return .done }
        if block.index == currentBlock { return .current }
        return block.index < currentBlock ? .done : .locked
    }

    /// La route elle-même, du départ au combat.
    private var roadway: some View {
        VStack(spacing: 0) {
            start
            ForEach(blocks) { block in
                milestone(block)
                connector(after: block)
            }
            finish
        }
    }

    /// Le programme n'est pas encore pris : on montre quand même la route,
    /// et on propose de partir.
    private var startCall: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 13) {
                Text(program.pitch)
                    .font(.ui(14))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                PrimaryButton(title: "PRENDRE CE PROGRAMME", tint: tint) {
                    showSetup = true
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(tint.opacity(0.4), lineWidth: 1))
            .padding(.horizontal, 20)
            .padding(.top, 20)

            roadway
        }
    }

    /// Le programme tourne mais n'a jamais été réglé : il faut ses
    /// disponibilités et ses mesures avant de pouvoir prescrire quoi que ce
    /// soit.
    private var setupCall: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Il manque ton point de départ")
                .font(.display(21))
                .foregroundStyle(Theme.text)
            Text("Ce programme a été lancé avant que l'app ne sache mesurer ton niveau. Sans tes disponibilités et tes quatre mesures, elle ne peut rien te prescrire de sensé.")
                .font(.ui(14))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
            Text("Deux minutes, et la route s'ouvre.")
                .font(.ui(13, .semibold))
                .foregroundStyle(tint)
            PrimaryButton(title: "RÉGLER LE PROGRAMME", tint: tint) {
                showSetup = true
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(tint.opacity(0.4), lineWidth: 1))
        .padding(.horizontal, 20)
        .padding(.top, 22)
    }

    private var unavailable: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ce programme n'a pas encore sa route")
                .font(.display(18))
                .foregroundStyle(Theme.text)
            Text("Seul Saitama est découpé en jalons pour l'instant. Les autres avancent par étapes, visibles dans la fiche du programme.")
                .font(.ui(13))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
}
