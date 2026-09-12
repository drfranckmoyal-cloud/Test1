import SwiftUI

/// Le combat final de Saitama : les quatre composantes suivies séparément.
///
/// Les trois cents répétitions se fractionnent librement dans la journée du
/// défi ; les dix kilomètres se font en une seule sortie. Cette différence
/// n'est pas cosmétique, c'est le cœur de la règle du chapitre 19.
struct BossFightView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    let fight: ProgramStructures.BossFight
    @State private var confirmVictory = false

    private let program = Catalog.program(.saitama)
    private var eligibility: SaitamaPlan.BossEligibility { store.saitamaBossEligibility }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    banner
                    if eligibility.isEligible { components } else { requirements }
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
                if eligibility.isEligible { victoryBar }
            }
        }
        .confirmationDialog("Le combat est gagné ?", isPresented: $confirmVictory,
                            titleVisibility: .visible) {
            Button("C'est validé", role: .destructive) {
                store.defeatSaitamaBoss()
                dismiss()
            }
            Button("Pas encore", role: .cancel) {}
        } message: {
            Text("Les quatre compteurs doivent être atteints le même jour, et les dix kilomètres courus d'une seule traite.")
        }
    }

    private var banner: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("COMBAT FINAL")
                .font(.ui(10, .bold))
                .kerning(2.6)
                .foregroundStyle(Theme.gold)
            Text(fight.title.uppercased())
                .font(.display(30))
                .foregroundStyle(Theme.text)
            Text("La routine canonique, réussie une fois. Les trois cents répétitions se répartissent dans la journée. Les dix kilomètres, non.")
                .font(.ui(14))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 10)
    }

    // MARK: - Pas encore éligible

    private var requirements: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 9) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(Theme.muted)
                Text("Pas encore ouvert")
                    .font(.ui(15, .bold))
                    .foregroundStyle(Theme.text)
            }

            Text("Le combat ne s'ouvre que si tes capacités récentes en sont proches. Il te manque :")
                .font(.ui(13))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 7) {
                ForEach(eligibility.missing, id: \.self) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "circle")
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.dim)
                            .padding(.top, 3)
                        Text(item)
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
            }

            Text("Un microcycle de consolidation est inséré sur les domaines en retard. Tu ne perds aucune récompense et le récit ne repart pas en arrière.")
                .font(.ui(11))
                .foregroundStyle(Theme.dim)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
        }
    }

    // MARK: - Le jour du combat

    private var components: some View {
        let open = store.openSession(of: .saitama)
        return VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "LES QUATRE COMPTEURS")

            if open == nil {
                Text("Ouvre la journée du combat quand tu commences. Les compteurs restent ouverts jusqu'à minuit.")
                    .font(.ui(12))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ForEach(store.bossPrescriptions(fight)) { item in
                if let progress = open?.objectives[item.id] {
                    DailyProgressObjective(
                        prescription: item, progress: progress,
                        tint: item.completionPolicy == .continuous ? Theme.gold : program.light,
                        onAdd: { store.addProgress($0, to: item.id, of: .saitama) },
                        onDeclareComplete: { store.declareComplete(item.id, of: .saitama) },
                        onRemoveEntry: { store.removeProgress($0, from: item.id, of: .saitama) },
                        onEditEntry: { store.updateProgress($0, to: $1, in: item.id, of: .saitama) })
                } else {
                    preview(item)
                }
            }
        }
    }

    private func preview(_ item: ExercisePrescription) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(item.name.uppercased())
                    .font(.display(16))
                    .foregroundStyle(Theme.text)
                Text(item.completionPolicy.instruction)
                    .font(.ui(11, .semibold))
                    .foregroundStyle(item.completionPolicy == .continuous ? Theme.gold : Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Text(item.unit.format(item.targetValue))
                .font(.ui(15, .bold))
                .foregroundStyle(program.light)
        }
        .padding(15)
        .frame(maxWidth: .infinity)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(item.completionPolicy == .continuous ? Theme.gold.opacity(0.5) : Theme.border,
                    lineWidth: 1))
    }

    private var victoryBar: some View {
        let open = store.bossDayOpen
        let complete = store.bossComplete(fight)
        return PrimaryButton(
            title: !open ? "COMMENCER LE COMBAT"
                 : (complete ? "VALIDER LE COMBAT" : "LES QUATRE COMPTEURS D'ABORD"),
            tint: Theme.gold, enabled: !open || complete) {
            if !open { store.beginBoss(fight) } else { confirmVictory = true }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Theme.groundDeep
                .overlay(Rectangle().frame(height: 1).foregroundStyle(Theme.border), alignment: .top)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}
