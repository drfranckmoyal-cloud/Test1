import SwiftUI

/// Tout le contenu d'un programme, étape par étape et séance par séance,
/// sans rien avoir à débloquer.
///
/// Sert à juger le contenu sportif : on veut voir où mène le programme, pas
/// seulement la séance du jour.
struct ProgramContentView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    let program: Program

    /// L'étape ouverte. Une seule à la fois : le contenu est long.
    @State private var openStage: Int?
    @State private var openSession: String?
    /// Voir le programme tel qu'il est écrit, ou tel qu'il sortira pour moi.
    @State private var asWritten = false
    /// La séance à laquelle on propose de revenir, le temps de confirmer.
    @State private var rewinding: PlannedSession?

    /// Le programme entier, tel que son moteur le déroule.
    ///
    /// Ce n'est plus l'ancien catalogue : les séances viennent du même moteur
    /// que celle du jour, jalon par jalon, à la fréquence retenue. L'ancien
    /// catalogue ne sert plus que si aucune spécification n'existe.
    private var sessions: [PlannedSession] {
        let plan = store.plan(of: program.id, asWritten: asWritten)
        if !plan.isEmpty { return plan }
        return Catalog.sessions(for: program.id,
                                tier: asWritten ? .confirme : store.state.tier,
                                intensity: asWritten ? 1.0 : store.intensity(program.id))
    }

    /// Vrai quand le programme est déroulé par le moteur : le découpage vient
    /// alors de sa spécification, plus de l'ancien catalogue.
    private var isGenerated: Bool { !store.plan(of: program.id).isEmpty }

    /// Les étapes réelles du programme.
    private var blockTitles: [String] {
        isGenerated ? store.shape(of: program.id).stageTitles : program.stages
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    summary
                    lens
                    ForEach(blockTitles.indices, id: \.self) { stage in
                        stageBlock(stage)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
            .background(Theme.ground)
            .navigationTitle(program.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
        .confirmationDialog("Revenir à cette séance ?",
                            isPresented: Binding(get: { rewinding != nil },
                                                 set: { if !$0 { rewinding = nil } }),
                            titleVisibility: .visible) {
            if let session = rewinding {
                let count = store.sessionsUndone(program.id, toSession: session.index)
                Button(count > 1 ? "Défaire ces \(count) séances" : "Défaire cette séance",
                       role: .destructive) {
                    store.rewind(program.id, toSession: session.index)
                    rewinding = nil
                }
            }
            Button("Ne rien changer", role: .cancel) { rewinding = nil }
        } message: {
            if let session = rewinding {
                let count = store.sessionsUndone(program.id, toSession: session.index)
                Text(count > 1
                     ? "« \(session.title) » et les \(count - 1) séances suivantes redeviendront à faire. Leur expérience et leurs points de Force, Vitesse et Endurance seront retirés, et ta série recalculée."
                     : "« \(session.title) » redeviendra à faire. Son expérience et ses points de Force, Vitesse et Endurance seront retirés, et ta série recalculée.")
            }
        }
    }

    // MARK: - Ce que pèse le programme

    private var summary: some View {
        let all = sessions
        let minutes = all.reduce(0) { $0 + $1.estimatedMinutes }
        let reps = all.reduce(0) { $0 + $1.totalReps }

        return HStack(spacing: 10) {
            tally("\(all.count)", "SÉANCES")
            tally("\(blockTitles.count)", program.id == .saitama ? "BLOCS" : "ÉTAPES")
            tally("\(minutes / 60) h", "AU TOTAL")
            if reps > 0 { tally(reps.grouped, "RÉPÉTITIONS") }
        }
    }

    private func tally(_ value: String, _ label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.display(18))
                .foregroundStyle(Theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.ui(8, .bold))
                .kerning(0.8)
                .foregroundStyle(Theme.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.border, lineWidth: 1))
    }

    private var lens: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("", selection: $asWritten) {
                Text("Pour moi").tag(false)
                Text("Tel qu'écrit").tag(true)
            }
            .pickerStyle(.segmented)

            Text(lensNote)
                .font(.ui(11))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Ce que la bascule change, dit selon le moteur qui produit le programme.
    private var lensNote: String {
        guard isGenerated else {
            return asWritten
                ? "Le programme d'origine, au palier Confirmé, sans ton curseur d'intensité."
                : "Ce que l'app te donnerait aujourd'hui : ton palier \(store.state.tier.label.lowercased()) et ton intensité \(percent)."
        }
        return asWritten
            ? "Le programme tel que le coach l'a écrit, aux variantes de référence."
            : "Le programme tel qu'il sortira pour toi, aux échelons que tu as atteints."
    }

    private var percent: String {
        let value = Int((store.intensity(program.id) * 100).rounded())
        return value == 100 ? "réglée comme prévu" : "à \(value) %"
    }

    // MARK: - Une étape

    private func stageBlock(_ stage: Int) -> some View {
        let inStage = isGenerated
            ? sessions.filter { $0.stageIndex == stage }
            : sessions.filter {
                $0.index > program.firstSession(ofStage: stage)
                    && $0.index <= program.firstSession(ofStage: stage) + program.sessionsPerStage[stage]
            }
        let count = inStage.count
        let isOpen = openStage == stage

        return VStack(spacing: 0) {
            Button {
                Haptics.tap()
                withAnimation(.easeInOut(duration: 0.2)) {
                    openStage = isOpen ? nil : stage
                }
            } label: {
                HStack(spacing: 12) {
                    Text("\(stage + 1)")
                        .font(.display(15))
                        .foregroundStyle(Theme.ink)
                        .frame(width: 30, height: 30)
                        .background(program.light, in: Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(blockTitles[stage])
                            .font(.ui(15, .bold))
                            .foregroundStyle(Theme.text)
                            .multilineTextAlignment(.leading)
                        Text("\(count) séance\(count > 1 ? "s" : "")")
                            .font(.ui(11, .semibold))
                            .foregroundStyle(Theme.muted)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.muted)
                }
                .padding(14)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isOpen {
                VStack(spacing: 7) {
                    ForEach(inStage) { session in
                        sessionBlock(session)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(Theme.border, lineWidth: 1))
    }

    // MARK: - Une séance

    private func sessionBlock(_ session: PlannedSession) -> some View {
        let isOpen = openSession == session.id
        let done = store.progress(program.id).completedSessions >= session.index

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                Haptics.tap()
                withAnimation(.easeInOut(duration: 0.18)) {
                    openSession = isOpen ? nil : session.id
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: done ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 15))
                        .foregroundStyle(done ? program.light : Theme.dim)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(session.title)
                            .font(.ui(13, .bold))
                            .foregroundStyle(Theme.text)
                            .multilineTextAlignment(.leading)
                        Text(subtitle(of: session))
                            .font(.ui(10, .semibold))
                            .foregroundStyle(Theme.muted)
                    }

                    Spacer(minLength: 6)

                    Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.dim)
                }
                .padding(11)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .overlay(alignment: .trailing) {
                if done {
                    Button {
                        Haptics.tap()
                        rewinding = session
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Theme.muted)
                            .frame(width: 34, height: 34)
                            .background(Theme.ground, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Revenir à cette séance")
                    .offset(x: -26)
                }
            }

            if isOpen {
                VStack(spacing: 5) {
                    ForEach(lines(of: session).indices, id: \.self) { position in
                        let line = lines(of: session)[position]
                        HStack(alignment: .top, spacing: 8) {
                            Text(line.name)
                                .font(.ui(12, .semibold))
                                .foregroundStyle(Theme.text)
                            Spacer(minLength: 6)
                            Text(line.amount)
                                .font(.ui(12, .bold))
                                .foregroundStyle(program.light)
                        }
                        .padding(.horizontal, 11)
                        .padding(.vertical, 7)
                        .background(Theme.ground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
                .padding(.horizontal, 11)
                .padding(.bottom, 11)
            }
        }
        .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
    }

    // MARK: - Regroupement

    private struct Line {
        var name: String
        var amount: String
    }

    /// Ce qu'on lit sous le titre : la durée et le nombre d'exercices.
    private func subtitle(of session: PlannedSession) -> String {
        let count = lines(of: session).count
        let word = count > 1 ? "exercices" : "exercice"
        return "\(session.estimatedMinutes) min · \(count) \(word)"
    }

    private func lines(of session: PlannedSession) -> [Line] {
        // une séance prescrite porte ses exercices, pas des étapes répétées
        if let prescribed = session.prescribed, !prescribed.isEmpty {
            return prescribed.map { item in
                Line(name: item.name,
                     amount: [item.amountLabel, item.intensityLabel]
                        .compactMap { $0 }.joined(separator: " · "))
            }
        }
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
            return Line(name: name, amount: count > 1 ? "\(count) × \(goal.short)" : goal.short)
        }
    }
}
