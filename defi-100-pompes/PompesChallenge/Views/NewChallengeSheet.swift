import SwiftUI

/// Création d'un nouveau défi : durée, exercices et objectifs quotidiens.
struct NewChallengeSheet: View {
    @EnvironmentObject private var store: ChallengeStore
    @Environment(\.dismiss) private var dismiss

    @State private var duration: Int
    @State private var goals: [ExerciseKind: Int]
    @State private var enabled: Set<ExerciseKind>
    @State private var showConfirmation = false

    private let presets = [7, 14, 21, 30, 60, 90]

    init(currentDuration: Int, current: [Exercise]) {
        _duration = State(initialValue: currentDuration)

        var startingGoals: [ExerciseKind: Int] = [:]
        for kind in ExerciseKind.allCases {
            startingGoals[kind] = kind.defaultGoal
        }
        var startingEnabled: Set<ExerciseKind> = []
        for exercise in current {
            startingGoals[exercise.kind] = exercise.dailyGoal
            startingEnabled.insert(exercise.kind)
        }
        _goals = State(initialValue: startingGoals)
        _enabled = State(initialValue: startingEnabled)
    }

    private var selectedExercises: [Exercise] {
        ExerciseKind.allCases
            .filter { enabled.contains($0) }
            .map { Exercise(kind: $0, dailyGoal: goals[$0] ?? $0.defaultGoal) }
    }

    var body: some View {
        VStack(spacing: 0) {
            handle

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SectionLabel(text: "DURÉE DU DÉFI")
                    durationPicker.padding(.top, 12)

                    SectionLabel(text: "EXERCICES").padding(.top, 26)
                    Text("Un jour est validé quand tous les exercices choisis ont atteint leur objectif.")
                        .font(.ui(12))
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 6)

                    VStack(spacing: 10) {
                        ForEach(ExerciseKind.allCases) { kind in
                            exerciseRow(kind)
                        }
                    }
                    .padding(.top, 12)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 20)
            }
            .scrollIndicators(.hidden)

            startButton
        }
        .background(Theme.background)
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationBackground(Theme.background)
        .alert("Démarrer ce nouveau défi ?", isPresented: $showConfirmation) {
            Button("Annuler", role: .cancel) {}
            Button("Démarrer", role: .destructive) {
                store.startChallenge(durationDays: duration, exercises: selectedExercises)
                Haptics.success()
                dismiss()
            }
        } message: {
            Text("Le défi en cours et tout son historique seront effacés. Le nouveau défi démarre aujourd'hui, au jour 1.")
        }
    }

    // MARK: - Morceaux

    private var handle: some View {
        HStack {
            Button("Annuler") { dismiss() }
                .font(.ui(15))
                .foregroundStyle(Theme.muted)
            Spacer()
            Text("NOUVEAU DÉFI")
                .font(.display(15))
                .foregroundStyle(Theme.cream)
            Spacer()
            Text("Annuler")
                .font(.ui(15))
                .foregroundStyle(Color.clear)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 22)
        .padding(.top, 20)
        .padding(.bottom, 18)
    }

    private var durationPicker: some View {
        VStack(spacing: 14) {
            HStack(spacing: 18) {
                StepButton(systemName: "minus", size: 52, enabled: duration > 1) {
                    duration = max(1, duration - 1)
                }
                VStack(spacing: 0) {
                    Text("\(duration)")
                        .font(.display(48))
                        .foregroundStyle(Theme.orange)
                        .contentTransition(.numericText())
                    Text(duration > 1 ? "JOURS" : "JOUR")
                        .font(.ui(11, .bold))
                        .kerning(2)
                        .foregroundStyle(Theme.muted)
                }
                .frame(minWidth: 110)
                StepButton(systemName: "plus", size: 52, enabled: duration < 365) {
                    duration = min(365, duration + 1)
                }
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 8) {
                ForEach(presets, id: \.self) { preset in
                    Button {
                        duration = preset
                        Haptics.tap()
                    } label: {
                        Text("\(preset)")
                            .font(.ui(14, duration == preset ? .bold : .semibold))
                            .foregroundStyle(duration == preset ? Theme.background : Theme.cream.opacity(0.75))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                duration == preset ? AnyShapeStyle(Theme.orange) : AnyShapeStyle(Theme.surface),
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(duration == preset ? Color.clear : Theme.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func exerciseRow(_ kind: ExerciseKind) -> some View {
        let isOn = enabled.contains(kind)
        let goal = goals[kind] ?? kind.defaultGoal
        return VStack(spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: kind.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(isOn ? Theme.orangeLight : Theme.muted)
                    .frame(width: 26)
                Text(kind.name)
                    .font(.ui(15, .bold))
                    .foregroundStyle(Theme.cream)
                Spacer(minLength: 0)
                Toggle("", isOn: Binding(
                    get: { isOn },
                    set: { newValue in
                        if newValue {
                            enabled.insert(kind)
                        } else {
                            enabled.remove(kind)
                        }
                        Haptics.tap()
                    }
                ))
                .labelsHidden()
                .tint(Theme.orange)
            }

            if isOn {
                HStack(spacing: 14) {
                    Text("par jour")
                        .font(.ui(12, .semibold))
                        .foregroundStyle(Theme.muted)
                    Spacer(minLength: 0)
                    StepButton(systemName: "minus", size: 40, enabled: goal > kind.goalStep) {
                        goals[kind] = max(1, goal - kind.goalStep)
                    }
                    Text("\(goal)")
                        .font(.display(20))
                        .foregroundStyle(Theme.orangeLight)
                        .frame(minWidth: 54)
                        .contentTransition(.numericText())
                    StepButton(systemName: "plus", size: 40, enabled: goal < kind.maxGoal) {
                        goals[kind] = min(kind.maxGoal, goal + kind.goalStep)
                    }
                }
            }
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isOn ? Theme.orange.opacity(0.35) : Theme.border, lineWidth: isOn ? 1.5 : 1)
        )
        .opacity(isOn ? 1 : 0.6)
    }

    private var startButton: some View {
        VStack(spacing: 8) {
            Button {
                showConfirmation = true
            } label: {
                Text("DÉMARRER LE DÉFI")
                    .font(.display(16))
                    .foregroundStyle(Theme.background)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(
                        enabled.isEmpty ? AnyShapeStyle(Theme.muted) : AnyShapeStyle(Theme.orange),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
            .disabled(enabled.isEmpty)

            Text(enabled.isEmpty
                 ? "Choisis au moins un exercice"
                 : "Remplace le défi en cours et efface son historique")
                .font(.ui(12))
                .foregroundStyle(Theme.muted)
        }
        .padding(.horizontal, 22)
        .padding(.top, 12)
        .padding(.bottom, 24)
        .background(Theme.background)
    }
}
