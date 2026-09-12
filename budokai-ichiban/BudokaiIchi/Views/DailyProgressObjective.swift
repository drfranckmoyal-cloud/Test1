import SwiftUI

/// La carte d'un objectif : sa cible, ce qui est fait, et de quoi enregistrer
/// ce qu'on vient de faire.
///
/// C'est le composant central du suivi fractionné. Il sert aussi bien à un
/// objectif réparti sur la journée qu'à un exercice de séance structurée ou à
/// une sortie à faire d'une traite — seul le libellé et le comportement du
/// cumul changent, jamais la carte.
struct DailyProgressObjective: View {
    let prescription: ExercisePrescription
    let progress: DailyObjectiveProgress
    var tint: Color = Theme.crimson

    var onAdd: (Int) -> Void
    var onDeclareComplete: () -> Void
    var onRemoveEntry: (UUID) -> Void
    var onEditEntry: (UUID, Int) -> Void
    var onUncheck: () -> Void = {}

    @State private var showingPad = false
    @State private var showingHistory = false
    @State private var editing: ProgressEntry?

    private var done: Bool { progress.status.isDone }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            if !done { counter }
            if prescription.completionPolicy == .continuous && !done {
                policyNote
            }
            if !done { actions }
            if !progress.entries.isEmpty { historyToggle }
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(done ? tint.opacity(0.55) : Theme.border, lineWidth: done ? 2 : 1))
        .sheet(isPresented: $showingPad) {
            AmountPad(title: prescription.name, unit: prescription.unit,
                      suggestion: suggestion) { value in
                onAdd(value)
            }
        }
        .sheet(item: $editing) { entry in
            AmountPad(title: "Corriger", unit: entry.unit, suggestion: entry.value) { value in
                onEditEntry(entry.id, value)
            }
        }
    }

    // MARK: - En-tête

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            // la case à cocher : le geste le plus fréquent, le plus accessible
            Button {
                Haptics.success()
                if done { onUncheck() } else { onDeclareComplete() }
            } label: {
                Image(systemName: done ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 27))
                    .foregroundStyle(done ? tint : Theme.dim)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(done ? "Décocher \(prescription.name)" : "Marquer \(prescription.name) comme fait")

            VStack(alignment: .leading, spacing: 4) {
                Text(prescription.name)
                    .font(.ui(16, .bold))
                    .foregroundStyle(done ? Theme.muted : Theme.text)
                    .strikethrough(done, color: Theme.dim)
                    .fixedSize(horizontal: false, vertical: true)

                Text(prescription.amountLabel)
                    .font(.display(17))
                    .foregroundStyle(done ? Theme.dim : tint)

                if let rest = prescription.restLabel {
                    Text(rest)
                        .font(.ui(11, .semibold))
                        .foregroundStyle(Theme.muted)
                }

                if let intensity = prescription.intensityLabel {
                    Text(intensity)
                        .font(.ui(11, .bold))
                        .foregroundStyle(tint)
                }
                if let detail = prescription.detail {
                    Text(detail)
                        .font(.ui(11))
                        .foregroundStyle(Theme.dim)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let easier = prescription.easierVariantId,
                   let exercise = SaitamaLibrary.exercise(easier) {
                    Text("Trop dur ? Reviens à : \(exercise.name)")
                        .font(.ui(10, .semibold))
                        .foregroundStyle(Theme.dim)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)
        }
    }

    // MARK: - Le compteur

    private var counter: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .firstTextBaseline) {
                Text(prescription.unit.short(progress.completedValue))
                    .font(.display(27))
                    .foregroundStyle(tint)
                Text("/ \(prescription.unit.format(progress.targetValue))")
                    .font(.ui(14, .semibold))
                    .foregroundStyle(Theme.muted)
                Spacer()
                if progress.remaining > 0 && progress.completedValue > 0 {
                    Text("encore \(prescription.unit.format(progress.remaining))")
                        .font(.ui(11, .semibold))
                        .foregroundStyle(Theme.muted)
                }
            }
            ProgressBar(value: progress.ratio, height: 8, tint: tint)
        }
    }

    /// Une sortie d'une seule traite doit le dire, sinon on additionne des
    /// fragments qui ne valent pas le standard.
    private var policyNote: some View {
        HStack(spacing: 7) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 12))
                .foregroundStyle(Theme.gold)
            Text(prescription.completionPolicy.instruction)
                .font(.ui(11, .semibold))
                .foregroundStyle(Theme.gold)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(9)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.gold.opacity(0.10), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    // MARK: - Les boutons

    private var actions: some View {
        HStack(spacing: 9) {
            Button {
                Haptics.tap()
                showingPad = true
            } label: {
                Label(addLabel, systemImage: "plus")
                    .font(.ui(13, .bold))
                    .foregroundStyle(Theme.cream)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(tint, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)


        }
    }

    private var addLabel: String {
        switch prescription.unit {
        case .meters: return "Ajouter une distance"
        case .seconds: return "Ajouter un temps"
        default: return "J'ai fait…"
        }
    }

    /// Une suggestion sensée : ce qu'il reste, ou une série.
    private var suggestion: Int {
        if let perSet = prescription.targetPerSet, perSet > 0 { return perSet }
        return progress.remaining > 0 ? progress.remaining : prescription.targetValue
    }

    // MARK: - L'historique des contributions

    private var historyToggle: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.18)) { showingHistory.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Text(showingHistory
                         ? "Masquer le détail"
                         : "\(progress.entries.count) enregistrement\(progress.entries.count > 1 ? "s" : "")")
                        .font(.ui(11, .bold))
                        .foregroundStyle(Theme.muted)
                    Image(systemName: showingHistory ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.muted)
                }
            }
            .buttonStyle(.plain)

            if showingHistory {
                VStack(spacing: 5) {
                    ForEach(progress.entries) { entry in
                        HStack(spacing: 8) {
                            Text(entry.label)
                                .font(.ui(12, .semibold))
                                .foregroundStyle(Theme.text)
                            Spacer(minLength: 6)
                            Button {
                                Haptics.tap()
                                editing = entry
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Theme.muted)
                                    .frame(width: 30, height: 30)
                            }
                            .buttonStyle(.plain)
                            Button {
                                Haptics.tap()
                                onRemoveEntry(entry.id)
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Theme.muted)
                                    .frame(width: 30, height: 30)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 10)
                        .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                    }
                }
            }
        }
    }
}

// MARK: - La saisie d'une quantité

/// Le pavé de saisie. Volontairement large : on s'en sert les mains moites,
/// entre deux séries.
struct AmountPad: View {
    let title: String
    let unit: ObjectiveUnit
    var suggestion: Int
    var onValidate: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var text = ""

    private var value: Int { Int(text) ?? 0 }

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                VStack(spacing: 6) {
                    Text(text.isEmpty ? "0" : text)
                        .font(.display(58))
                        .foregroundStyle(Theme.text)
                        .contentTransition(.numericText())
                    Text(unitLabel)
                        .font(.ui(13, .bold))
                        .kerning(1.4)
                        .foregroundStyle(Theme.muted)
                }
                .padding(.top, 20)

                if suggestion > 0 {
                    Button {
                        Haptics.tap()
                        text = "\(suggestion)"
                    } label: {
                        Text("Proposition : \(unit.format(suggestion))")
                            .font(.ui(12, .semibold))
                            .foregroundStyle(Theme.crimson)
                    }
                    .buttonStyle(.plain)
                }

                pad

                PrimaryButton(title: "Enregistrer", enabled: value > 0) {
                    onValidate(value)
                    dismiss()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 10)
            }
            .background(Theme.ground)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }

    private var unitLabel: String {
        switch unit {
        case .reps: return "RÉPÉTITIONS"
        case .seconds: return "SECONDES"
        case .meters: return "MÈTRES"
        case .kg: return "KILOS"
        }
    }

    private var pad: some View {
        let keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "00", "0", "←"]
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3),
                         spacing: 10) {
            ForEach(keys, id: \.self) { key in
                Button {
                    Haptics.tap()
                    press(key)
                } label: {
                    Text(key)
                        .font(.display(23))
                        .foregroundStyle(Theme.text)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .stroke(Theme.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
    }

    private func press(_ key: String) {
        if key == "←" {
            if !text.isEmpty { text.removeLast() }
        } else if text.count < 6 {
            if text.isEmpty && key == "00" { return }
            text += key
        }
    }
}
