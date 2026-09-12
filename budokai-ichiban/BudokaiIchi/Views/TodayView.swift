import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: GameStore
    @State private var running: PlannedSession?
    /// Quand plusieurs séances tombent le même jour, une seule est dépliée :
    /// sinon la page fait trois écrans de haut.
    @State private var opened: ProgramID?
    @State private var setting: Program?

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                header
                if let penalty = store.state.penalty, penalty.accepted {
                    penaltyCard(penalty)
                }
                mainContent
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 26)
        }
        .scrollIndicators(.hidden)
        .background(Theme.ground)
        .fullScreenCover(item: $running) { session in
            SessionSheetView(session: session)
        }
        .sheet(item: $setting) { program in
            ProgramLaunchView(program: program) { store.startProgram(program.id) }
        }
    }

    // MARK: - En-tête

    private var header: some View {
        HStack(spacing: 14) {
            RankBadge(rank: store.rank, size: 52)
            VStack(alignment: .leading, spacing: 3) {
                Text("NIVEAU \(store.level)")
                    .font(.display(18))
                    .foregroundStyle(Theme.text)
                Text("\(store.state.xp.grouped) XP")
                    .font(.ui(12, .semibold))
                    .foregroundStyle(Theme.muted)
                ProgressBar(value: store.levelProgress, height: 5, tint: Theme.gold)
            }
            VStack(spacing: 2) {
                Text("\(store.state.streak)")
                    .font(.display(20))
                    .foregroundStyle(store.state.streak > 0 ? Theme.crimson : Theme.dim)
                Text(store.state.streak > 1 ? "jours" : "jour")
                    .font(.ui(10, .bold))
                    .foregroundStyle(Theme.muted)
            }
            .frame(width: 48)
        }
    }

    // MARK: - Corps selon la situation

    @ViewBuilder
    private var mainContent: some View {
        if store.activePrograms.isEmpty {
            emptyCard
        } else {
            let due = store.sessionsDueToday
            if due.count > 1 {
                SectionLabel(text: "\(due.count) SÉANCES AUJOURD'HUI")
                ForEach(due.indices, id: \.self) { index in
                    let entry = due[index]
                    if opened == entry.program.id {
                        sessionCard(program: entry.program, session: entry.session,
                                    collapsible: true)
                    } else {
                        compactCard(program: entry.program, session: entry.session)
                    }
                }
            } else {
                ForEach(due.indices, id: \.self) { index in
                    sessionCard(program: due[index].program, session: due[index].session)
                }
            }
            ForEach(store.programsResting) { program in
                restCard(program)
            }
            ForEach(store.programsNeedingSetup) { program in
                setupCard(program)
            }
            ForEach(store.programsFinished) { program in
                finishedCard(program)
            }
        }
    }

    private var emptyCard: some View {
        VStack(spacing: 16) {
            Text("Aucun programme en cours")
                .font(.display(20))
                .foregroundStyle(Theme.text)
            Text("Choisis un maître dans l'onglet Programmes. Deux sont ouverts : Saitama pour la transformation, Naruto pour la course.")
                .font(.ui(14))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.border, lineWidth: 1))
    }

    /// Un programme lancé mais jamais réglé. Il était affiché comme
    /// « terminé », ce qui n'avait aucun sens.
    private func setupCard(_ program: Program) -> some View {
        VStack(spacing: 13) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 28))
                .foregroundStyle(program.light)
            Text(program.name.uppercased())
                .font(.display(19))
                .foregroundStyle(Theme.text)
            Text("Il manque ton point de départ. Sans tes disponibilités et tes mesures, l'app ne peut rien te prescrire.")
                .font(.ui(13))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: "RÉGLER LE PROGRAMME", tint: program.light) {
                setting = program
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(program.light.opacity(0.4), lineWidth: 1))
    }

    private func finishedCard(_ program: Program) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "star.fill")
                .font(.system(size: 34))
                .foregroundStyle(Theme.gold)
            Text("\(program.name.uppercased()) : TERMINÉ")
                .font(.display(20))
                .foregroundStyle(Theme.text)
                .multilineTextAlignment(.center)
            Text("Tu peux le reprendre au palier supérieur, ou passer à un autre maître.")
                .font(.ui(14))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.border, lineWidth: 1))
    }

    private func restCard(_ program: Program) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 28))
                .foregroundStyle(program.light)
            Text("JOUR DE REPOS")
                .font(.display(20))
                .foregroundStyle(Theme.text)
            Text(Motivation.restLine(tone: store.state.tone, program: program.name))
                .font(.ui(14))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let due = store.nextDueDay(of: program.id) {
                Text("Prochaine séance \(dayLabel(due)).")
                    .font(.ui(13, .bold))
                    .foregroundStyle(program.light)
                    .padding(.top, 2)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.border, lineWidth: 1))
    }

    /// La version repliée : le maître, l'étape, l'estimation, et de quoi
    /// lancer la séance sans rien déplier.
    private func compactCard(program: Program, session: PlannedSession) -> some View {
        let status = store.stageStatus(program)
        let stageName = store.stageName(program)

        return HStack(spacing: 0) {
            Button {
                Haptics.tap()
                withAnimation(.easeInOut(duration: 0.2)) { opened = program.id }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        program.gradient
                        ArtworkFill(name: program.stageImage(status.index)).opacity(0.9)
                    }
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(program.name.uppercased())
                            .font(.display(15))
                            .foregroundStyle(Theme.text)
                            .lineLimit(1)
                        Text(stageName)
                            .font(.ui(11, .semibold))
                            .foregroundStyle(Theme.muted)
                            .lineLimit(1)
                        Text("\(status.done)/\(status.total) · \(session.estimatedMinutes) min")
                            .font(.ui(10, .semibold))
                            .foregroundStyle(program.light)
                    }
                    Spacer(minLength: 6)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                Haptics.tap()
                running = session
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 42, height: 42)
                    .background(program.light, in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.border, lineWidth: 1))
    }

    private func sessionCard(program: Program, session: PlannedSession,
                             collapsible: Bool = false) -> some View {
        let status = store.stageStatus(program)
        let stageName = store.stageName(program)
        let ratio = status.total > 0 ? Double(status.done) / Double(status.total) : 0

        return VStack(spacing: 0) {
            // bandeau de l'univers
            ZStack {
                program.gradient
                ArtworkFill(name: program.environmentImage)
                    .opacity(0.5)
                // le décor pose l'ambiance sans gêner la lecture
                LinearGradient(colors: [Color.black.opacity(0.30), Color.black.opacity(0.62)],
                               startPoint: .top, endPoint: .bottom)
                VStack(spacing: 4) {
                    Text(program.name.uppercased())
                        .font(.ui(11, .bold))
                        .kerning(2.6)
                        .foregroundStyle(Theme.cream.opacity(0.85))
                    Text(stageName.uppercased())
                        .font(.display(23))
                        .foregroundStyle(Theme.cream)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                }
                .padding(.horizontal, 18)

                if collapsible {
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                Haptics.tap()
                                withAnimation(.easeInOut(duration: 0.2)) { opened = nil }
                            } label: {
                                Image(systemName: "chevron.up")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Theme.cream)
                                    .frame(width: 34, height: 34)
                                    .background(Color.black.opacity(0.32), in: Circle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Replier \(program.name)")
                        }
                        Spacer()
                    }
                    .padding(10)
                }
            }
            .frame(height: 104)

            VStack(spacing: 18) {
                ZStack {
                    ProgressRing(progress: ratio, lineWidth: 16, tint: program.light)
                    VStack(spacing: 2) {
                        Text("\(status.done)")
                            .font(.display(54))
                            .foregroundStyle(program.light)
                        Text("SUR \(status.total) SÉANCES")
                            .font(.ui(10, .bold))
                            .kerning(1.6)
                            .foregroundStyle(Theme.muted)
                    }
                }
                .frame(width: 176, height: 176)
                .padding(.top, 18)

                Text(Motivation.sessionLine(tone: store.state.tone, program: program.name,
                                            stage: stageName,
                                            remaining: max(0, status.total - status.done),
                                            streak: store.state.streak))
                    .font(.ui(14, .semibold))
                    .foregroundStyle(Theme.text)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 18)

                VStack(spacing: 8) {
                    SectionLabel(text: "AU PROGRAMME · \(session.estimatedMinutes) MIN")
                    ForEach(summary(of: session), id: \.self) { line in
                        HStack {
                            Text(line.name)
                                .font(.ui(14, .semibold))
                                .foregroundStyle(Theme.text)
                            Spacer(minLength: 8)
                            Text(line.detail)
                                .font(.ui(14, .bold))
                                .foregroundStyle(program.light)
                        }
                        .padding(.horizontal, 14)
                        .frame(height: 46)
                        .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                    }
                }
                .padding(.horizontal, 18)

                PrimaryButton(title: "OUVRIR LA SÉANCE DU JOUR", tint: program.light) {
                    running = session
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 20)
            }
        }
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.border, lineWidth: 1))
    }

    // MARK: - Quête de pénalité acceptée

    private func penaltyCard(_ penalty: PenaltyQuest) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "bolt.fill").foregroundStyle(Theme.crimson)
                Text("QUÊTE DE PÉNALITÉ")
                    .font(.ui(11, .bold))
                    .kerning(2)
                    .foregroundStyle(Theme.crimson)
                Spacer()
                Text("avant minuit")
                    .font(.ui(11, .semibold))
                    .foregroundStyle(Theme.muted)
            }

            ForEach(penalty.tasks) { task in
                HStack(spacing: 12) {
                    Text(task.name)
                        .font(.ui(14, .semibold))
                        .foregroundStyle(Theme.text)
                    Spacer(minLength: 8)
                    Text("\(task.done) / \(task.target)")
                        .font(.ui(14, .bold))
                        .foregroundStyle(task.isComplete ? Theme.gold : Theme.crimson)
                    StepButton(systemName: "plus", size: 38, enabled: !task.isComplete) {
                        store.addPenalty(10, to: task.id)
                    }
                }
            }

            ProgressBar(value: penalty.progress, height: 5, tint: Theme.crimson)
        }
        .padding(16)
        .background(Theme.crimson.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(Theme.crimson.opacity(0.35), lineWidth: 1))
    }

    // MARK: - Outils

    private struct Line: Hashable {
        var name: String
        var detail: String
    }

    /// Regroupe les étapes identiques : « Pompes · 4 × 12 » plutôt que quatre lignes.
    private func summary(of session: PlannedSession) -> [Line] {
        var order: [String] = []
        var counts: [String: Int] = [:]
        var goals: [String: Goal] = [:]
        for step in session.steps {
            if counts[step.name] == nil { order.append(step.name) }
            counts[step.name, default: 0] += 1
            goals[step.name] = step.goal
        }
        return order.map { name in
            let count = counts[name] ?? 1
            let goal = goals[name] ?? Goal(unit: .reps, value: 0)
            return Line(name: name, detail: count > 1 ? "\(count) × \(goal.short)" : goal.short)
        }
    }

    private func dayLabel(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInTomorrow(date) { return "demain" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}
