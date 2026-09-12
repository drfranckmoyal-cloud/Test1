import SwiftUI

/// Les séances déjà faites, de la plus récente à la plus ancienne.
/// On peut en effacer une : c'est le recours quand on a coché une séance
/// par mégarde.
struct HistoryView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    @State private var pendingDeletion: SessionRecord?

    var body: some View {
        NavigationStack {
            Group {
                if store.state.history.isEmpty {
                    empty
                } else {
                    list
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
            Text("Son expérience sera retirée, le programme reculera d'une séance et ta série sera recalculée.")
        }
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
