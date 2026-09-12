import SwiftUI

/// La fiche d'entraînement du jour : tout le contenu de la séance, lisible
/// d'un coup d'œil, à garder ouverte pendant l'effort.
///
/// C'est le chemin normal. Le guidage minuté reste possible pour les séances
/// en salle, mais il n'est plus obligatoire : personne ne va sortir courir en
/// suivant son téléphone minute par minute.
struct SessionSheetView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    let session: PlannedSession

    private enum Step { case card, feedback, outcome }
    /// Vrai quand le guidage a déjà enregistré la séance : le ressenti ne
    /// doit alors rien enregistrer de plus.
    @State private var alreadyRecorded = false
    @State private var step: Step = .card
    @State private var guided: PlannedSession?
    @State private var outcome: SessionOutcome?
    @State private var report = SessionReport()

    private var program: Program { Catalog.program(session.programID) }
    /// La séance telle qu'elle sera faite, curseur d'intensité compris.
    /// La séance telle qu'elle sera faite.
    ///
    /// Une séance prescrite porte déjà son dosage : on la prend telle quelle.
    /// Seuls les anciens programmes, qui n'expriment qu'un volume, se
    /// recalculent avec le curseur d'intensité.
    private var tuned: PlannedSession {
        if session.prescribed != nil { return session }
        return Catalog.session(for: session.programID, index: session.index - 1,
                               tier: store.state.tier,
                               intensity: store.intensity(session.programID)) ?? session
    }

    var body: some View {
        ZStack {
            Theme.ground.ignoresSafeArea()
            switch step {
            case .card: card
            case .feedback: feedbackScreen
            case .outcome:
                if let outcome = outcome {
                    OutcomeView(outcome: outcome) { dismiss() }
                }
            }
        }
        .fullScreenCover(item: $guided) { session in
            GuidedSessionView(session: session) { alreadyRecorded = true }
        } 
    }

    // MARK: - La fiche

    private var card: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 18) {
                    if let note = engineNote { engineCard(note) }
                    exercises
                    if let story = narrative { narrativeCard(story) }
                    if tuned.prescribed == nil { intensityDial }
                    if !program.equipment.isEmpty && program.equipment != "Aucun" {
                        note("Matériel : \(program.equipment)")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            actions
        }
    }

    private var header: some View {
        ZStack(alignment: .bottomLeading) {
            program.gradient
            ArtworkFill(name: program.environmentImage).opacity(0.42)
            LinearGradient(colors: [Color.black.opacity(0.25), Color.black.opacity(0.72)],
                           startPoint: .top, endPoint: .bottom)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(program.name.uppercased())
                        .font(.ui(11, .bold))
                        .kerning(2.4)
                        .foregroundStyle(Theme.cream.opacity(0.85))
                    Text(session.title)
                        .font(.display(25))
                        .foregroundStyle(Theme.cream)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                    Text(positionLabel)
                        .font(.ui(12, .semibold))
                        .foregroundStyle(Theme.cream.opacity(0.8))
                }
                Spacer(minLength: 8)
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.cream)
                        .frame(width: 36, height: 36)
                        .background(Color.black.opacity(0.32), in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .padding(.top, 54)
        }
        .frame(height: 190)
        .ignoresSafeArea(edges: .top)
    }

    /// Le récit de la séance, quand il existe et que le réglage de spoilers
    /// l'autorise.
    private var narrative: NarrativeContent? {
        guard session.programID == .saitama,
              let id = tuned.narrativeId,
              let content = SaitamaNarrative.beats.first(where: { $0.id == id }),
              content.isVisible(at: store.state.spoilerLevel) else { return nil }
        return content
    }

    private func narrativeCard(_ story: NarrativeContent) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(story.arc.uppercased())
                .font(.ui(9, .bold))
                .kerning(2.0)
                .foregroundStyle(program.light)
            Text(story.narrativeTitle)
                .font(.display(19))
                .foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
            Text(story.storyRecap)
                .font(.ui(13))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
            if let sensei = story.senseiMessage {
                HStack(alignment: .top, spacing: 8) {
                    Rectangle().fill(program.light).frame(width: 2)
                    Text(sensei)
                        .font(.ui(12))
                        .italic()
                        .foregroundStyle(Theme.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.border, lineWidth: 1))
    }

    /// Où se situe cette séance dans le parcours.
    private var positionLabel: String {
        if session.programID == .saitama, let block = store.saitamaBlock {
            return "Bloc \(block.index) sur 8 · \(block.title) · environ \(tuned.estimatedMinutes) min"
        }
        return "Séance \(session.index) sur \(program.totalSessions) · environ \(tuned.estimatedMinutes) min"
    }

    /// Ce que le moteur a décidé, dit en clair. Le cadrage veut que le
    /// pratiquant voie **pourquoi** l'exercice change, jamais les
    /// coefficients qui le décident.
    private var engineNote: (icon: String, title: String, body: String)? {
        guard session.programID == .saitama else { return nil }
        // rien à expliquer tant qu'aucune séance n'a été faite
        guard store.progress(.saitama).completedSessions > 0 else { return nil }

        if let consolidation = store.saitamaConsolidation {
            let names = consolidation.domains.map { $0.label.lowercased() }.joined(separator: " et ")
            return ("arrow.triangle.2.circlepath",
                    "Microcycle de consolidation",
                    "Le bloc n'est pas encore tenu sur \(names). \(consolidation.remaining) séance\(consolidation.remaining > 1 ? "s" : "") ciblée\(consolidation.remaining > 1 ? "s" : "") avant de le rejuger. Rien n'est perdu, le récit continue.")
        }
        if tuned.title.contains("décharge") {
            return ("moon.zzz.fill", "Semaine allégée",
                    "Volume réduit exprès. C'est pendant ces semaines que l'adaptation se fait.")
        }
        if let move = store.lastMove(of: .saitama), move != .hold {
            return (move.isProgression ? "arrow.up.right" : "arrow.down.right",
                    move.label, move.explanation)
        }
        return nil
    }

    private func engineCard(_ note: (icon: String, title: String, body: String)) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: note.icon)
                .font(.system(size: 15))
                .foregroundStyle(program.light)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 3) {
                Text(note.title)
                    .font(.ui(13, .bold))
                    .foregroundStyle(Theme.text)
                Text(note.body)
                    .font(.ui(12))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(15)
        .frame(maxWidth: .infinity)
        .background(program.light.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(program.light.opacity(0.32), lineWidth: 1))
    }

    // MARK: - Le curseur d'intensité

    private var intensityDial: some View {
        let value = store.intensity(session.programID)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionLabel(text: "INTENSITÉ")
                Text(percentLabel(value))
                    .font(.ui(13, .bold))
                    .foregroundStyle(value == 1 ? Theme.muted : program.light)
            }

            HStack(spacing: 12) {
                dialButton(systemName: "minus", enabled: value > 0.5) {
                    store.setIntensity(value - 0.05, for: session.programID)
                }
                ProgressBar(value: (value - 0.5) / 2.0, height: 8, tint: program.light)
                dialButton(systemName: "plus", enabled: value < 2.5) {
                    store.setIntensity(value + 0.05, for: session.programID)
                }
            }

            Text("À lire avant de commencer : si la séance te paraît déjà inutile ou hors de portée, ajuste-la ici. Elle se règle aussi toute seule, d'après ce que tu répondras en fin de séance.")
                .font(.ui(11))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.border, lineWidth: 1))
    }

    private func dialButton(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            guard enabled else { return }
            Haptics.tap()
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(enabled ? Theme.text : Theme.dim)
                .frame(width: 42, height: 42)
                .background(Theme.surfaceAlt, in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private func percentLabel(_ value: Double) -> String {
        let percent = Int((value * 100).rounded())
        if percent == 100 { return "Comme prévu" }
        return percent > 100 ? "+\(percent - 100) %" : "−\(100 - percent) %"
    }

    // MARK: - Le contenu de la séance

    private var exercises: some View {
        let open = store.openSession(of: session.programID)
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionLabel(text: "LA SÉANCE")
                if let open = open {
                    Text("\(Int(open.ratio(against: tuned.prescriptions) * 100)) %")
                        .font(.ui(12, .bold))
                        .foregroundStyle(program.light)
                }
            }
            ForEach(tuned.prescriptions) { item in
                if let progress = open?.objectives[item.id] {
                    DailyProgressObjective(
                        prescription: item, progress: progress, tint: program.light,
                        onAdd: { store.addProgress($0, to: item.id, of: session.programID) },
                        onDeclareComplete: { store.declareComplete(item.id, of: session.programID) },
                        onRemoveEntry: { store.removeProgress($0, from: item.id, of: session.programID) },
                        onEditEntry: { store.updateProgress($0, to: $1, in: item.id, of: session.programID) })
                } else {
                    staticRow(item)
                }
            }
        }
    }

    /// La ligne simple, avant que la séance ne soit ouverte.
    private func staticRow(_ item: ExercisePrescription) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.ui(15, .bold))
                    .foregroundStyle(Theme.text)
                if let intensity = item.intensityLabel {
                    Text(intensity)
                        .font(.ui(11, .bold))
                        .foregroundStyle(program.light)
                }
                if let detail = item.detail {
                    Text(detail)
                        .font(.ui(12))
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            Text(item.amountLabel)
                .font(.ui(15, .bold))
                .foregroundStyle(program.light)
                .multilineTextAlignment(.trailing)
        }
        .padding(14)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.border, lineWidth: 1))
    }

    private func row(_ line: Line, number: Int) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.display(14))
                .foregroundStyle(program.light)
                .frame(width: 26, height: 26)
                .background(program.light.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(line.name)
                    .font(.ui(15, .bold))
                    .foregroundStyle(Theme.text)
                if !line.detail.isEmpty {
                    Text(line.detail)
                        .font(.ui(12))
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 8)

            Text(line.amount)
                .font(.ui(15, .bold))
                .foregroundStyle(program.light)
                .multilineTextAlignment(.trailing)
        }
        .padding(14)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.border, lineWidth: 1))
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(.ui(12, .semibold))
            .foregroundStyle(Theme.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Les boutons du bas

    private var actions: some View {
        let open = store.openSession(of: session.programID)
        return VStack(spacing: 9) {
            if open == nil {
                PrimaryButton(title: "COMMENCER LE SUIVI", tint: program.light) {
                    store.beginSession(tuned)
                }
                GhostButton(title: "Marquer la séance faite, sans détailler") {
                    step = .feedback
                }
            } else {
                PrimaryButton(title: "SÉANCE RÉALISÉE", tint: program.light) {
                    step = .feedback
                }
            }
            if program.allowsGuidance {
                GhostButton(title: "Me guider pas à pas, avec minuteur") {
                    guided = tuned
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(
            Theme.groundDeep
                .overlay(Rectangle().frame(height: 1).foregroundStyle(Theme.border), alignment: .top)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Le ressenti

    private var feedbackScreen: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("C'EST FAIT")
                        .font(.display(27))
                        .foregroundStyle(Theme.text)
                    Text("Trois questions, pas une de plus. Tu peux n'en répondre aucune.")
                        .font(.ui(13))
                        .foregroundStyle(Theme.muted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 34)

                question("DIFFICULTÉ GLOBALE") {
                    ForEach(PerceivedEffort.allCases) { candidate in
                        choice(candidate.label, icon: candidate.icon,
                               picked: report.effort == candidate) {
                            report.effort = candidate
                        }
                    }
                }

                question("SÉANCE TERMINÉE ?") {
                    ForEach(CompletionStatus.allCases) { candidate in
                        choice(candidate.label, icon: nil, picked: report.completion == candidate) {
                            report.completion = candidate
                            if candidate == .entirely { report.failureReason = nil }
                        }
                    }
                }

                if let completion = report.completion, completion != .entirely {
                    question("QU'EST-CE QUI A MANQUÉ ?") {
                        ForEach(FailureReason.allCases) { candidate in
                            choice(candidate.label, icon: nil, picked: report.failureReason == candidate) {
                                report.failureReason = candidate
                            }
                        }
                    }
                }

                question("QUALITÉ D'EXÉCUTION") {
                    ForEach(TechnicalQuality.allCases) { candidate in
                        choice(candidate.label, icon: nil, picked: report.quality == candidate) {
                            report.quality = candidate
                        }
                    }
                }

                VStack(spacing: 9) {
                    PrimaryButton(title: "VALIDER LA SÉANCE", tint: program.light) {
                        finish(with: report)
                    }
                    Button {
                        Haptics.tap()
                        finish(with: SessionReport())
                    } label: {
                        Text("Je préfère ne pas répondre")
                            .font(.ui(13, .semibold))
                            .foregroundStyle(Theme.muted)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
    }

    private func question<Content: View>(_ title: String,
                                         @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: title)
            VStack(spacing: 7) { content() }
        }
    }

    private func choice(_ label: String, icon: String?, picked: Bool,
                        _ action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 17))
                        .foregroundStyle(picked ? Theme.cream : program.light)
                        .frame(width: 24)
                }
                Text(label)
                    .font(.ui(14, .bold))
                    .foregroundStyle(picked ? Theme.cream : Theme.text)
                Spacer(minLength: 0)
                if picked {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.cream)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(picked ? AnyShapeStyle(program.light) : AnyShapeStyle(Theme.surface),
                        in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(picked ? Color.clear : Theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    /// Enregistre la séance comme faite, au niveau où elle était prévue,
    /// puis laisse le moteur décider de la suivante.
    private func finish(with report: SessionReport) {
        let done = tuned
        let openRatio = store.openSession(of: done.programID)?
            .ratio(against: done.prescriptions)
        let ratio = openRatio ?? 1.0

        store.record(report, for: done.programID, completedRatio: ratio)

        if alreadyRecorded {
            store.closeSession(of: done.programID)
            dismiss()
            return
        }
        var achieved: [Int: Int] = [:]
        for item in done.steps { achieved[item.id] = item.goal.value }
        // l'enregistrement lit les contributions : la séance se referme après
        outcome = store.complete(session: done, achieved: achieved)
        store.closeSession(of: done.programID)
        step = .outcome
    }

    // MARK: - Regroupement des étapes

    private struct Line {
        var name: String
        var detail: String
        var amount: String
    }

    /// « Pompes · 4 × 12 » plutôt que quatre lignes identiques.
    private var grouped: [Line] {
        var order: [String] = []
        var counts: [String: Int] = [:]
        var goals: [String: Goal] = [:]
        var details: [String: String] = [:]
        for item in tuned.steps {
            if counts[item.name] == nil {
                order.append(item.name)
                details[item.name] = item.detail
            }
            counts[item.name, default: 0] += 1
            goals[item.name] = item.goal
        }
        return order.map { name in
            let count = counts[name] ?? 1
            let goal = goals[name] ?? Goal(unit: .reps, value: 0)
            return Line(name: name,
                        detail: count > 1 ? "" : (details[name] ?? ""),
                        amount: count > 1 ? "\(count) × \(goal.short)" : goal.short)
        }
    }
}
