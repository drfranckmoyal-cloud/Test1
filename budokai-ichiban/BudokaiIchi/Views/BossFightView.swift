import SwiftUI

/// Le combat final d'un programme, quel qu'il soit.
///
/// Les neuf combats ne se ressemblent pas : Saitama compte trois cents
/// répétitions et dix kilomètres, Minato des dixièmes de seconde, Luffy des
/// degrés d'amplitude. Ce que l'écran doit rendre lisible, c'est la **règle**
/// du combat, et elle n'est pas la même partout :
///
/// - ce qui est obligatoire l'est sans discussion ;
/// - ce qui est facultatif se valide « deux sur trois » ou « quatre sur cinq » ;
/// - ce qui se chronomètre ne se compte pas, il s'annonce et se coche.
///
/// Cette distinction vient de la spécification de chaque programme, pas d'un
/// choix d'interface.
struct BossFightView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    let challenge: BossChallenge
    @State private var confirmVictory = false

    private var program: Program { Catalog.program(challenge.programID) }
    private var isOpen: Bool { store.bossIsOpen(challenge.programID) }
    private var missing: [String] { store.bossMissing(challenge.programID) }
    private var outcome: BossChallenge.Outcome { store.bossOutcome(challenge) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    banner
                    if isOpen {
                        rule
                        components
                        if let note = challenge.note { footnote(note) }
                    } else {
                        requirements
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 26)
            }
            .scrollIndicators(.hidden)
            .background(Theme.ground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if isOpen { victoryBar }
            }
        }
        .confirmationDialog("Le combat est gagné ?", isPresented: $confirmVictory,
                            titleVisibility: .visible) {
            Button("C'est validé", role: .destructive) {
                store.defeatBoss(challenge.programID)
                dismiss()
            }
            Button("Pas encore", role: .cancel) {}
        } message: {
            Text(challenge.requirements.joined(separator: " · "))
        }
    }

    // MARK: - En-tête

    private var banner: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("COMBAT FINAL")
                .font(.ui(10, .bold))
                .kerning(2.6)
                .foregroundStyle(Theme.gold)
            Text(challenge.title.uppercased())
                .font(.display(30))
                .foregroundStyle(Theme.text)
            Text(challenge.summary)
                .font(.ui(14))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 10)
    }

    // MARK: - Pas encore ouvert

    private var requirements: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 9) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(Theme.muted)
                Text("Pas encore ouvert")
                    .font(.ui(15, .bold))
                    .foregroundStyle(Theme.text)
            }

            Text("Le combat ne s'ouvre pas avant que la route soit faite. Il te manque :")
                .font(.ui(13))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 7) {
                ForEach(missing, id: \.self) { item in
                    bullet(item)
                }
            }

            SectionLabel(text: "CE QUE LE COMBAT DEMANDERA")
                .padding(.top, 8)
            VStack(alignment: .leading, spacing: 6) {
                ForEach(challenge.requirements, id: \.self) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("·").foregroundStyle(Theme.dim)
                        Text(item)
                            .font(.ui(12))
                            .foregroundStyle(Theme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "circle")
                .font(.system(size: 11))
                .foregroundStyle(Theme.dim)
                .padding(.top, 3)
            Text(text)
                .font(.ui(13, .semibold))
                .foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(13)
        .frame(maxWidth: .infinity)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(Theme.border, lineWidth: 1))
    }

    // MARK: - La règle du combat

    /// Ce qu'il faut valider pour gagner, avec l'avancement du jour.
    private var rule: some View {
        let result = outcome
        return VStack(alignment: .leading, spacing: 9) {
            SectionLabel(text: "POUR GAGNER")
            HStack(spacing: 10) {
                if result.mandatoryTotal > 0 {
                    tally("Obligatoires", result.mandatoryDone, result.mandatoryTotal,
                          ok: result.mandatoryOK)
                }
                if !challenge.optionalComponents.isEmpty {
                    tally("Performances", result.optionalDone, result.optionalThreshold,
                          ok: result.optionalOK)
                }
            }
            if let tolerance = challenge.toleranceLabel {
                Text(tolerance)
                    .font(.ui(11))
                    .foregroundStyle(Theme.dim)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func tally(_ label: String, _ done: Int, _ total: Int, ok: Bool) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(.ui(9, .bold))
                .kerning(1.6)
                .foregroundStyle(Theme.dim)
            Text("\(done) / \(total)")
                .font(.display(22))
                .foregroundStyle(ok ? Theme.gold : Theme.text)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(ok ? Theme.gold.opacity(0.55) : Theme.border, lineWidth: ok ? 2 : 1))
    }

    // MARK: - Le jour du combat

    private var components: some View {
        let open = store.openSession(of: challenge.programID)
        return VStack(alignment: .leading, spacing: 14) {
            if open == nil {
                Text("Ouvre la journée du combat quand tu commences. Les compteurs restent ouverts jusqu'à minuit.")
                    .font(.ui(12))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            group("OBLIGATOIRE", challenge.mandatoryComponents, open: open)
            if !challenge.optionalComponents.isEmpty {
                group(challenge.optionalThreshold < challenge.optionalComponents.count
                      ? "\(challenge.optionalThreshold) SUR \(challenge.optionalComponents.count)"
                      : "PERFORMANCES",
                      challenge.optionalComponents, open: open)
            }
        }
    }

    private func group(_ label: String, _ items: [BossChallenge.Component],
                       open: OpenSession?) -> some View {
        let prescriptions = challenge.prescriptions
        return Group {
            if items.isEmpty {
                EmptyView()
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    SectionLabel(text: label)
                    ForEach(items) { component in
                        if let item = prescriptions.first(where: { $0.id == component.id }) {
                            row(component, item, progress: open?.objectives[component.id])
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func row(_ component: BossChallenge.Component,
                     _ item: ExercisePrescription,
                     progress: DailyObjectiveProgress?) -> some View {
        if let progress = progress {
            DailyProgressObjective(
                prescription: item, progress: progress,
                tint: component.mandatory ? Theme.gold : program.light,
                onAdd: { store.addProgress($0, to: component.id, of: challenge.programID) },
                onDeclareComplete: { store.declareComplete(component.id, of: challenge.programID) },
                onRemoveEntry: { store.removeProgress($0, from: component.id, of: challenge.programID) },
                onEditEntry: { store.updateProgress($0, to: $1, in: component.id, of: challenge.programID) },
                onUncheck: { store.resetObjective(component.id, of: challenge.programID) },
                // ce qui ne se compte pas se coche : un chrono, un critère
                // d'atterrissage, une amplitude jugée à l'œil
                compact: !challenge.isCounted(component))
        } else {
            preview(component)
        }
    }

    private func preview(_ component: BossChallenge.Component) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(component.name.uppercased())
                    .font(.display(16))
                    .foregroundStyle(Theme.text)
                Text(component.note ?? component.policy.instruction)
                    .font(.ui(11, .semibold))
                    .foregroundStyle(component.policy == .continuous ? Theme.gold : Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Text(component.targetLabel)
                .font(.ui(13, .bold))
                .foregroundStyle(component.mandatory ? Theme.gold : program.light)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(15)
        .frame(maxWidth: .infinity)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(component.mandatory ? Theme.gold.opacity(0.5) : Theme.border, lineWidth: 1))
    }

    private func footnote(_ text: String) -> some View {
        Text(text)
            .font(.ui(11))
            .foregroundStyle(Theme.dim)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var victoryBar: some View {
        let started = store.bossDayOpen(of: challenge.programID)
        let won = outcome.isWon
        return PrimaryButton(
            title: !started ? "COMMENCER LE COMBAT"
                 : (won ? "VALIDER LE COMBAT" : missingLabel),
            tint: Theme.gold, enabled: !started || won) {
            if !started { store.beginBoss(challenge) } else { confirmVictory = true }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Theme.groundDeep
                .overlay(Rectangle().frame(height: 1).foregroundStyle(Theme.border), alignment: .top)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var missingLabel: String {
        outcome.missing.first?.uppercased() ?? "IL RESTE DES COMPTEURS"
    }
}
