import SwiftUI

/// La prochaine séance, en lecture seule.
///
/// Un jour de repos, on veut souvent savoir ce qui arrive — pour prévoir sa
/// tenue, son créneau, ou simplement se rassurer. Cette fiche montre tout le
/// contenu sans rien ouvrir : aucune case à cocher, aucun compteur, rien qui
/// puisse démarrer la séance par mégarde.
struct SessionPreviewView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    let session: PlannedSession

    private var program: Program { Catalog.program(session.programID) }
    private var items: [ExercisePrescription] { session.prescriptions }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    group("ÉCHAUFFEMENT", items.filter(\.isWarmup))
                    group("LE TRAVAIL", items.filter { !$0.isWarmup && !$0.isCooldown })
                    group("RETOUR AU CALME", items.filter(\.isCooldown))
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
            .background(Theme.ground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("À VENIR")
                .font(.ui(9, .bold))
                .kerning(2.2)
                .foregroundStyle(program.light)
            Text(session.title)
                .font(.display(25))
                .foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
            Text("Séance \(session.index) sur \(store.shape(of: session.programID).totalSessions) · environ \(session.estimatedMinutes) min")
                .font(.ui(12, .semibold))
                .foregroundStyle(Theme.muted)
        }
        .padding(.top, 12)
    }

    @ViewBuilder
    private func group(_ title: String, _ list: [ExercisePrescription]) -> some View {
        if !list.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel(text: title)
                VStack(spacing: 7) {
                    ForEach(list) { item in row(item) }
                }
            }
        }
    }

    private func row(_ item: ExercisePrescription) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.ui(14, .semibold))
                    .foregroundStyle(Theme.text)
                    .fixedSize(horizontal: false, vertical: true)
                if let detail = item.detail {
                    Text(detail)
                        .font(.ui(11))
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let intensity = item.intensityLabel, !item.isWarmup, !item.isCooldown {
                    Text(intensity)
                        .font(.ui(11, .bold))
                        .foregroundStyle(program.light)
                }
            }
            Spacer(minLength: 8)
            Text(item.amountLabel)
                .font(.ui(13, .bold))
                .foregroundStyle(item.isWarmup || item.isCooldown ? Theme.muted : program.light)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(13)
        .frame(maxWidth: .infinity)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(Theme.border, lineWidth: 1))
    }
}
