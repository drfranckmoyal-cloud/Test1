import SwiftUI

/// Les séances déjà faites, de la plus récente à la plus ancienne.
/// On peut en effacer une : c'est le recours quand on a coché une séance
/// par mégarde.
struct HistoryView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    @State private var pendingDeletion: SessionRecord?
    @State private var confirmRepair = false

    var body: some View {
        NavigationStack {
            Group {
                if store.state.history.isEmpty {
                    empty
                } else {
                    VStack(spacing: 0) {
                        if store.hasUntrackedStatGains { repairBanner }
                        list
                    }
                }
            }
            .background(Theme.ground)
            .navigationTitle("Historique")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
        .confirmationDialog("Effacer cette séance ?",
                            isPresented: Binding(get: { pendingDeletion != nil },
                                                 set: { if !$0 { pendingDeletion = nil } }),
                            titleVisibility: .visible) {
            if let record = pendingDeletion {
                Button("Effacer", role: .destructive) {
                    store.deleteRecord(record.id)
                    pendingDeletion = nil
                }
            }
            Button("Garder", role: .cancel) { pendingDeletion = nil }
        } message: {
            Text("Son expérience et ses caractéristiques seront retirées, le programme reculera d'une séance et ta série sera recalculée.")
        }
        .confirmationDialog("Recalculer les caractéristiques ?",
                            isPresented: $confirmRepair, titleVisibility: .visible) {
            Button("Recalculer", role: .destructive) { store.recomputeStats() }
            Button("Laisser comme ça", role: .cancel) {}
        } message: {
            Text("Force, Vitesse et Endurance seront reprises à partir des séances qui restent. Celles enregistrées avant la correction ne comptaient pas leurs gains : elles ne rapporteront rien.")
        }
    }

    /// L'app ne gardait pas les gains de caractéristiques : les anciennes
    /// séances ne peuvent donc pas les rendre en s'effaçant. On propose le
    /// rattrapage plutôt que de le faire dans le dos de Franck.
    private var repairBanner: some View {
        Button {
            Haptics.tap()
            confirmRepair = true
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "wrench.adjustable.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.gold)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Des séances anciennes ne rendent pas leurs caractéristiques")
                        .font(.ui(13, .bold))
                        .foregroundStyle(Theme.text)
                        .multilineTextAlignment(.leading)
                    Text("Elles ont été enregistrées avant que l'app ne garde ce qu'elles rapportaient. Touche ici pour recalculer.")
                        .font(.ui(11))
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
            .background(Theme.gold.opacity(0.10))
            .overlay(Rectangle().frame(height: 1).foregroundStyle(Theme.border), alignment: .bottom)
        }
        .buttonStyle(.plain)
    }

    private var empty: some View {
        VStack(spacing: 10) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 30))
                .foregroundStyle(Theme.dim)
            Text("Aucune séance enregistrée")
                .font(.display(18))
                .foregroundStyle(Theme.text)
            Text("Les séances que tu marqueras comme faites s'inscriront ici.")
                .font(.ui(13))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var list: some View {
        List {
            ForEach(store.historyNewestFirst) { record in
                row(record)
                    .listRowBackground(Theme.surface)
                    .listRowSeparatorTint(Theme.border)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            pendingDeletion = record
                        } label: {
                            Label("Effacer", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func row(_ record: SessionRecord) -> some View {
        let program = ProgramID(rawValue: record.programID).map(Catalog.program)

        return HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(program?.light ?? Theme.dim)
                .frame(width: 4, height: 38)

            VStack(alignment: .leading, spacing: 2) {
                Text(program?.name ?? record.programID)
                    .font(.ui(14, .bold))
                    .foregroundStyle(Theme.text)
                Text(subtitle(record))
                    .font(.ui(11, .semibold))
                    .foregroundStyle(Theme.muted)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text("+\(record.xp) XP")
                    .font(.ui(13, .bold))
                    .foregroundStyle(Theme.gold)
                Text(dayLabel(record.day))
                    .font(.ui(10, .semibold))
                    .foregroundStyle(Theme.dim)
            }
        }
        .padding(.vertical, 5)
    }

    /// « Séance 12 · 84 répétitions », en ne citant que ce qui a été fait.
    private func subtitle(_ record: SessionRecord) -> String {
        var pieces = ["Séance \(record.sessionIndex)"]
        if record.reps > 0 { pieces.append("\(record.reps) répétitions") }
        if record.meters > 0 { pieces.append("\(record.meters) m") }
        if record.seconds > 0 && record.reps == 0 && record.meters == 0 {
            pieces.append("\(record.seconds / 60) min")
        }
        return pieces.joined(separator: " · ")
    }

    private func dayLabel(_ key: String) -> String {
        guard let date = store.date(fromKey: key) else { return key }
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "aujourd'hui" }
        if calendar.isDateInYesterday(date) { return "hier" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "d MMM"
        return formatter.string(from: date)
    }
}
