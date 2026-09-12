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
    @State private var chosen: SessionFeedback?

    private var program: Program { Catalog.program(session.programID) }
    /// La séance telle qu'elle sera faite, curseur d'intensité compris.
    private var tuned: PlannedSession {
        Catalog.session(for: session.programID, index: session.index - 1,
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
                    intensityDial
                    exercises
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
                    Text("Séance \(session.index) sur \(program.totalSessions) · environ \(tuned.estimatedMinutes) min")
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
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "LA SÉANCE")
            VStack(spacing: 7) {
                ForEach(grouped.indices, id: \.self) { position in
                    row(grouped[position], number: position + 1)
                }
            }
        }
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
        VStack(spacing: 9) {
            PrimaryButton(title: "SÉANCE RÉALISÉE", tint: program.light) {
                step = .feedback
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
            VStack(spacing: 18) {
                VStack(spacing: 8) {
                    Text("C'EST FAIT")
                        .font(.display(27))
                        .foregroundStyle(Theme.text)
                    Text("Comment as-tu trouvé cette séance ?")
                        .font(.ui(15))
                        .foregroundStyle(Theme.muted)
                    Text("C'est cette réponse, et rien d'autre, qui règle la séance suivante.")
                        .font(.ui(12))
                        .foregroundStyle(Theme.dim)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 40)

                VStack(spacing: 9) {
                    ForEach(SessionFeedback.allCases) { candidate in
                        Button {
                            Haptics.tap()
                            chosen = candidate
                            finish(with: candidate)
                        } label: {
                            HStack(spacing: 13) {
                                Image(systemName: candidate.icon)
                                    .font(.system(size: 19))
                                    .foregroundStyle(program.light)
                                    .frame(width: 26)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(candidate.label)
                                        .font(.ui(15, .bold))
                                        .foregroundStyle(Theme.text)
                                    Text(candidate.consequence)
                                        .font(.ui(11))
                                        .foregroundStyle(Theme.muted)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(15)
                            .frame(maxWidth: .infinity)
                            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Theme.border, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
    }

    /// Enregistre la séance comme faite, au niveau où elle était prévue.
    /// Si le guidage l'a déjà fait, on se contente du ressenti.
    private func finish(with feedback: SessionFeedback) {
        let done = tuned
        store.apply(feedback, to: done.programID)
        if alreadyRecorded {
            dismiss()
            return
        }
        var achieved: [Int: Int] = [:]
        for item in done.steps { achieved[item.id] = item.goal.value }
        outcome = store.complete(session: done, achieved: achieved)
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
