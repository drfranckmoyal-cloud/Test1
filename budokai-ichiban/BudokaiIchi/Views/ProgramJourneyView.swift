import SwiftUI

/// Le chemin du programme : une route de jalons, du premier pas au combat
/// final.
///
/// C'est la page de garde d'un programme. Elle ne liste pas des blocs, elle
/// dessine un trajet — et chaque jalon porte d'abord son arc narratif, le
/// détail sportif ne venant qu'en se dépliant.
///
/// Les jalons viennent de la définition du programme : la même vue sert les
/// neuf.
struct ProgramJourneyView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    let program: Program
    /// Vrai quand l'écran s'ouvre juste après le lancement du programme.
    var isIntroduction: Bool = false

    @State private var opened: Int?
    @State private var showDetail = false
    @State private var showContent = false
    @State private var showBoss = false
    @State private var showSetup = false

    private var tint: Color { program.light }
    private var stages: [ProgramDefinition.Stage] { ProgramLibrary.stages(program.id) }
    private var boss: BossChallenge? { store.bossChallenge(of: program.id) }

    // MARK: - Où l'on en est

    private var perWeek: Int {
        store.schedule(of: program.id)?.sessionsPerWeek
            ?? store.schedulingRules(of: program.id)?.recommendedSessionsPerWeek ?? 4
    }
    private var done: Int { store.progress(program.id).completedSessions }

    /// Séances prévues par jalon, dans le scénario nominal.
    private func sessions(inStage index: Int) -> Int {
        guard index >= 1, index <= stages.count else { return perWeek }
        return max(1, stages[index - 1].weeksMin * perWeek)
    }

    private var currentStage: Int {
        guard !stages.isEmpty else { return 1 }
        var remaining = done
        for index in 1...stages.count {
            let count = sessions(inStage: index)
            if remaining < count { return index }
            remaining -= count
        }
        return stages.count
    }

    private var stageProgress: (done: Int, total: Int) {
        let before = currentStage > 1
            ? (1..<currentStage).reduce(0) { $0 + sessions(inStage: $1) }
            : 0
        return (max(0, done - before), sessions(inStage: currentStage))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    banner
                    if store.isPaused(program.id) {
                        resumeCall
                        roadway
                    } else if !store.isActive(program.id) {
                        startCall
                        roadway
                    } else if store.needsSetup(program.id) {
                        setupCall
                    } else if stages.isEmpty {
                        unavailable
                    } else {
                        roadway
                    }
                    footer
                }
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
            .background(pageBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(isIntroduction ? "C'est parti" : "Fermer") { dismiss() }
                        .font(.ui(15, .bold))
                }
            }
        }
        .sheet(isPresented: $showDetail) { ProgramDetailView(program: program) }
        .sheet(isPresented: $showContent) { ProgramContentView(program: program) }
        .sheet(isPresented: $showBoss) {
            if let boss = boss { BossFightView(challenge: boss) }
        }
        .sheet(isPresented: $showSetup) {
            ProgramLaunchView(program: program) { store.startProgram(program.id) }
        }
        .onAppear { if isIntroduction { opened = currentStage } }
    }

    // MARK: - Le fond de page

    /// La couverture du programme, en plein format derrière toute la page.
    ///
    /// Ce n'est pas un bandeau : l'image tient tout l'écran et le parcours se
    /// lit par-dessus. Et c'est volontairement une image **générique** de
    /// l'univers, pas l'illustration d'un jalon : celles-là appartiennent à
    /// leur moment de la progression, et les poser ici les ferait déborder sur
    /// les jalons suivants.
    @ViewBuilder
    private var pageBackground: some View {
        if ProgramVisuals.hasCover(program.id) {
            ZStack {
                Color.black
                Image(ProgramVisuals.cover(program.id))
                    .resizable()
                    .scaledToFill()
                    .accessibilityHidden(true)
                // le voile qui rend le parcours lisible sans éteindre l'image
                LinearGradient(stops: [
                    .init(color: .black.opacity(0.30), location: 0),
                    .init(color: .black.opacity(0.12), location: 0.22),
                    .init(color: .black.opacity(0.62), location: 0.52),
                    .init(color: .black.opacity(0.86), location: 1)],
                    startPoint: .top, endPoint: .bottom)
            }
            .ignoresSafeArea()
        } else {
            Theme.ground
        }
    }

    // MARK: - Le bandeau

    /// La tête de page : le logo du programme, puis le jalon où l'on se trouve.
    private var banner: some View {
        let over = ProgramVisuals.hasCover(program.id)

        return ZStack(alignment: .bottomLeading) {
            if !over {
                program.gradient
                ArtworkFill(name: program.stageImage(max(0, currentStage - 1))).opacity(0.55)
                LinearGradient(colors: [Color.black.opacity(0.15), Theme.ground],
                               startPoint: .top, endPoint: .bottom)
            }

            VStack(alignment: .leading, spacing: over ? 12 : 6) {
                if over {
                    // le logo est la signature du programme : il tient la
                    // largeur de la page, pas un coin
                    ProgramLogo(program: program, height: 132)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.bottom, 4)
                } else {
                    Text(quality.uppercased())
                        .font(.ui(10, .bold))
                        .kerning(2.4)
                        .foregroundStyle(Theme.cream.opacity(0.9))
                    Text(program.name.uppercased())
                        .font(.display(34))
                        .foregroundStyle(Theme.cream)
                }
                if over, store.isActive(program.id) || store.isPaused(program.id) {
                    Text(store.stageName(program).uppercased())
                        .font(.display(26))
                        .foregroundStyle(Theme.cream)
                        .shadow(color: .black.opacity(0.7), radius: 10, y: 2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(bannerLine)
                    .font(.ui(14, .semibold))
                    .foregroundStyle(Theme.cream.opacity(0.92))
                    .shadow(color: .black.opacity(over ? 0.7 : 0), radius: 8, y: 1)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 18)
            .padding(.top, over ? 26 : 0)
        }
        // une fois le programme lancé, c'est la route qu'on vient voir : la
        // couverture se contente de la moitié haute de l'écran
        .frame(height: over ? (store.isActive(program.id) ? 300 : 390) : 230)
    }

    private var quality: String {
        ProgramLibrary.definition(program.id)?.quality ?? program.family
    }

    private var bannerLine: String {
        if !store.isActive(program.id) {
            return "\(stages.count) jalons, une histoire, un combat au bout."
        }
        if isIntroduction { return "Voilà la route. Une histoire, et un combat au bout." }
        if store.needsSetup(program.id) { return "Il reste ton point de départ à mesurer." }
        return "Tu es au jalon \(currentStage) sur \(stages.count)."
    }

    // MARK: - La route

    private var roadway: some View {
        VStack(spacing: 0) {
            start
            ForEach(Array(stages.enumerated()), id: \.element.key) { offset, stage in
                milestone(stage, number: offset + 1)
                connector(after: offset + 1)
            }
            finishNode
        }
    }

    /// L'arrivée se touche quand le programme tourne : c'est le bout de la
    /// route, donc l'endroit où l'on cherche le combat final.
    @ViewBuilder
    private var finishNode: some View {
        if store.isActive(program.id), boss != nil {
            Button { Haptics.tap(); showBoss = true } label: { finish }
                .buttonStyle(.plain)
        } else {
            finish
        }
    }

    private var start: some View {
        VStack(spacing: 0) {
            Text("LE DÉPART")
                .font(.ui(9, .bold))
                .kerning(2.2)
                .foregroundStyle(Theme.muted)
            path(from: 0.5, to: side(1), height: 24, reached: true)
        }
        .padding(.top, 12)
    }

    // MARK: - Un jalon

    private func milestone(_ stage: ProgramDefinition.Stage, number: Int) -> some View {
        let state = state(of: number)
        let isOpen = opened == number
        let onLeft = side(number) < 0.5

        return VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 14) {
                if !onLeft { label(stage, state, aligned: .trailing); Spacer(minLength: 0) }
                node(number, state)
                if onLeft { label(stage, state, aligned: .leading); Spacer(minLength: 0) }
            }
            .padding(.horizontal, 22)
            .contentShape(Rectangle())
            .onTapGesture {
                Haptics.tap()
                withAnimation(.easeInOut(duration: 0.22)) { opened = isOpen ? nil : number }
            }

            if isOpen { card(stage, state) }
        }
    }

    private func node(_ number: Int, _ state: StageState) -> some View {
        ZStack {
            if state == .current {
                Circle().fill(tint.opacity(0.18)).frame(width: 60, height: 60)
            }
            Circle()
                .fill(state == .done ? tint : Theme.surface)
                .frame(width: 44, height: 44)
                .overlay(Circle().stroke(state == .locked ? Theme.border : tint,
                                         lineWidth: state == .current ? 3 : 2))
            if state == .done {
                Image(systemName: "checkmark")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Theme.ink)
            } else if state == .locked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.dim)
            } else {
                Text("\(number)")
                    .font(.display(18))
                    .foregroundStyle(tint)
            }
        }
        .frame(width: 62, height: 58)
    }

    private func label(_ stage: ProgramDefinition.Stage, _ state: StageState,
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
            Text(stage.title)
                .font(.display(16))
                .foregroundStyle(state == .locked ? Theme.dim : Theme.text)
                .multilineTextAlignment(aligned == .leading ? .leading : .trailing)
                .fixedSize(horizontal: false, vertical: true)
            Text(stage.weeksLabel)
                .font(.ui(11, .semibold))
                .foregroundStyle(Theme.muted)
            if state == .done,
               let first = rewards(of: stage).first(where: { store.state.rewards.has($0.rewardId) }) {
                HStack(spacing: 4) {
                    Image(systemName: "rosette").font(.system(size: 9))
                    Text(first.title).font(.ui(10, .bold))
                }
                .foregroundStyle(Theme.gold)
            }
        }
        .frame(maxWidth: 170, alignment: aligned == .leading ? .leading : .trailing)
    }

    // MARK: - Le jalon déplié

    private func card(_ stage: ProgramDefinition.Stage, _ state: StageState) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            story(stage)
            target(stage)
            if state == .current { currentNote }
            rewardLine(stage)
        }
        .padding(17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(state == .current ? tint.opacity(0.5) : Theme.border, lineWidth: 1))
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    /// L'histoire de l'arc, prise dans le pack narratif.
    private func story(_ stage: ProgramDefinition.Stage) -> some View {
        let beats = NarrationLibrary.sessions(program.id, stage: stage.key)
            .map { NarrativeContent($0, program: program) }
            .filter { $0.isVisible(at: store.state.spoilerLevel) }

        return VStack(alignment: .leading, spacing: 9) {
            Text("CE QUI SE PASSE DANS L'HISTOIRE")
                .font(.ui(9, .bold))
                .kerning(1.8)
                .foregroundStyle(tint)

            if let first = beats.first {
                Text(first.storyRecap)
                    .font(.system(size: 14, weight: .regular, design: .serif))
                    .lineSpacing(2)
                    .foregroundStyle(Theme.text.opacity(0.88))
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Le récit de ce jalon se dévoile séance après séance.")
                    .font(.ui(12))
                    .foregroundStyle(Theme.muted)
            }

            VStack(alignment: .leading, spacing: 5) {
                ForEach(beats.dropFirst().prefix(8)) { beat in
                    HStack(alignment: .top, spacing: 8) {
                        Circle().fill(Theme.dim).frame(width: 4, height: 4).padding(.top, 7)
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
                        .font(.system(size: 13, weight: .regular, design: .serif))
                        .italic()
                        .foregroundStyle(Theme.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 2)
            }
        }
    }

    /// Le sport, dit sans jargon.
    private func target(_ stage: ProgramDefinition.Stage) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("CE QUE TU VIENS Y CHERCHER")
                .font(.ui(9, .bold))
                .kerning(1.8)
                .foregroundStyle(Theme.muted)
            Text(stage.goal)
                .font(.ui(13, .semibold))
                .foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)

            if let benchmark = stage.benchmark {
                Text("Repère de sortie : \(benchmark)")
                    .font(.ui(12, .semibold))
                    .foregroundStyle(tint)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !stage.exit.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(stage.exit, id: \.self) { item in
                        HStack(alignment: .top, spacing: 7) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Theme.dim)
                                .padding(.top, 3)
                            Text(item)
                                .font(.ui(11))
                                .foregroundStyle(Theme.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            Text("\(stage.weeksLabel) à ton rythme.")
                .font(.ui(11))
                .foregroundStyle(Theme.dim)
        }
    }

    private var currentNote: some View {
        let progress = stageProgress
        return VStack(alignment: .leading, spacing: 7) {
            ProgressBar(value: progress.total > 0 ? Double(progress.done) / Double(progress.total) : 0,
                        height: 7, tint: tint)
            Text("Séance \(progress.done + 1) sur \(progress.total) de ce jalon.")
                .font(.ui(11, .semibold))
                .foregroundStyle(Theme.muted)
        }
    }

    private func rewards(of stage: ProgramDefinition.Stage) -> [Reward] {
        RewardCatalog.rewards(for: program.id).filter { $0.blockId == stage.key }
    }

    private func rewardLine(_ stage: ProgramDefinition.Stage) -> some View {
        let items = rewards(of: stage)
        let owned = items.filter { store.state.rewards.has($0.rewardId) }
        return Group {
            if items.isEmpty {
                EmptyView()
            } else {
                HStack(spacing: 9) {
                    Image(systemName: owned.isEmpty ? "gift" : "rosette")
                        .font(.system(size: 13))
                        .foregroundStyle(owned.isEmpty ? Theme.dim : Theme.gold)
                    Text(owned.isEmpty
                         ? "\(items.count) vignette\(items.count > 1 ? "s" : "") à débloquer ici."
                         : "\(owned.count) sur \(items.count) obtenue\(owned.count > 1 ? "s" : "").")
                        .font(.ui(11, .semibold))
                        .foregroundStyle(owned.isEmpty ? Theme.muted : Theme.gold)
                }
            }
        }
    }

    // MARK: - Le tracé

    private func side(_ index: Int) -> CGFloat { index % 2 == 1 ? 0.26 : 0.74 }

    private func connector(after number: Int) -> some View {
        let next = number + 1
        let reached = number < currentStage
        return path(from: side(number), to: next <= stages.count ? side(next) : 0.5,
                    height: 30, reached: reached)
    }

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
            return shape.stroke(reached ? tint : Theme.border,
                                style: StrokeStyle(lineWidth: 3, lineCap: .round,
                                                   dash: reached ? [] : [5, 7]))
        }
        .frame(height: height)
    }

    // MARK: - L'arrivée

    private var finish: some View {
        let won = store.progress(program.id).bossDefeated
        let eligible = store.isActive(program.id) && store.bossIsOpen(program.id)

        return VStack(spacing: 9) {
            ZStack {
                if won || eligible {
                    Circle().fill(Theme.gold.opacity(0.18)).frame(width: 70, height: 70)
                }
                Circle()
                    .fill(won ? Theme.gold : Theme.surface)
                    .frame(width: 50, height: 50)
                    .overlay(Circle().stroke(won || eligible ? Theme.gold : Theme.border, lineWidth: 2))
                Image(systemName: won ? "crown.fill" : (eligible ? "flame.fill" : "lock.fill"))
                    .font(.system(size: 18))
                    .foregroundStyle(won ? Theme.ink : (eligible ? Theme.gold : Theme.dim))
            }

            Text((boss?.title ?? "Le combat final").uppercased())
                .font(.display(15))
                .foregroundStyle(won || eligible ? Theme.text : Theme.dim)
                .multilineTextAlignment(.center)
            Text(won
                 ? "Gagné. \(ProgramStructures.superRankName(for: program.id) ?? "Le mode supérieur") est ouvert."
                 : (eligible
                    ? "Le combat est ouvert. Touche pour l'engager."
                    : (ProgramLibrary.bossSummary(program.id) ?? "Le standard qui valide le programme.")))
                .font(.ui(12))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 34)
        }
        .padding(.top, 4)
    }

    // MARK: - Appels à l'action

    /// Un programme en pause ne se reprend pas de zéro : il redémarre là où
    /// il s'est arrêté.
    private var resumeCall: some View {
        let done = store.progress(program.id).completedSessions
        return VStack(alignment: .leading, spacing: 13) {
            Text(done > 0
                 ? "Tu l'as mis en pause après \(done) séance\(done > 1 ? "s" : ""). Rien n'a bougé : il repart exactement là où tu l'as laissé."
                 : "Tu l'as mis en pause avant de commencer. Il repart du début.")
                .font(.ui(14))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: "REPRENDRE CE PROGRAMME", tint: tint) {
                store.resumeProgram(program.id)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(tint.opacity(0.4), lineWidth: 1))
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var startCall: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text(program.pitch)
                .font(.ui(14))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: "PRENDRE CE PROGRAMME", tint: tint) { showSetup = true }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(tint.opacity(0.4), lineWidth: 1))
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var setupCall: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Il manque ton point de départ")
                .font(.display(21))
                .foregroundStyle(Theme.text)
            Text("Sans tes disponibilités et tes mesures, l'app ne peut rien te prescrire de sensé. Deux minutes, et la route s'ouvre.")
                .font(.ui(14))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: "RÉGLER LE PROGRAMME", tint: tint) { showSetup = true }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(tint.opacity(0.4), lineWidth: 1))
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var footer: some View {
        Button {
            Haptics.tap()
            showContent = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "list.bullet.rectangle")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Voir le détail du programme")
                        .font(.ui(14, .bold))
                        .foregroundStyle(Theme.text)
                    Text("Toutes les étapes et toutes les séances, séance par séance.")
                        .font(.ui(11))
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.dim)
            }
            .padding(15)
            .frame(maxWidth: .infinity)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(tint.opacity(0.45), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.top, 24)
    }

    // MARK: - État d'un jalon

    private enum StageState { case done, current, locked }

    private func state(of number: Int) -> StageState {
        guard store.isActive(program.id) else { return number == 1 ? .current : .locked }
        if number < currentStage { return .done }
        return number == currentStage ? .current : .locked
    }

    private var unavailable: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Ce programme n'a pas encore sa route")
                .font(.display(18))
                .foregroundStyle(Theme.text)
            Text("Ses jalons ne sont pas encore décrits. Il avance par étapes, visibles dans la fiche du programme.")
                .font(.ui(13))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
}
