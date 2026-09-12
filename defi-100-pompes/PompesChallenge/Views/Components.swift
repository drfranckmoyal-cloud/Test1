import SwiftUI
import UIKit

// MARK: - Anneau de progression

struct ProgressRing: View {
    var progress: Double
    var lineWidth: CGFloat = 20

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.surfaceAlt, style: StrokeStyle(lineWidth: lineWidth))
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [Theme.orangeDeep, Theme.orange, Theme.amber, Theme.orangeDeep]),
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .animation(.spring(response: 0.55, dampingFraction: 0.85), value: progress)
    }
}

/// L'anneau d'un exercice, avec son compteur au centre et son nom dessous.
/// La taille est décidée par l'appelant selon le nombre d'exercices.
struct ExerciseRing: View {
    let kind: ExerciseKind
    let count: Int
    let goal: Int
    let size: CGFloat

    private var progress: Double {
        goal > 0 ? min(1.0, Double(count) / Double(goal)) : 1
    }

    private var lineWidth: CGFloat {
        if size >= 220 { return 20 }
        if size >= 150 { return 15 }
        return 12
    }

    private var numberSize: CGFloat {
        if size >= 220 { return 82 }
        if size >= 150 { return 44 }
        return 30
    }

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                ProgressRing(progress: progress, lineWidth: lineWidth)
                VStack(spacing: 0) {
                    Text("\(count)")
                        .font(.display(numberSize))
                        .foregroundStyle(Theme.orange)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: count)
                    Text("/ \(goal)")
                        .font(.ui(size >= 220 ? 15 : 12, .bold))
                        .foregroundStyle(Theme.muted)
                }
            }
            .frame(width: size, height: size)

            Text(kind.name.uppercased())
                .font(.ui(size >= 220 ? 13 : 11, .bold))
                .kerning(size >= 220 ? 2.4 : 1.2)
                .foregroundStyle(Theme.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
}

// MARK: - Barre de progression

struct ProgressBarView: View {
    var value: Double
    var height: CGFloat = 10

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.surfaceAlt)
                Capsule()
                    .fill(Theme.progressGradient)
                    .frame(width: min(max(value, 0), 1) * geometry.size.width)
            }
        }
        .frame(height: height)
        .animation(.spring(response: 0.5, dampingFraction: 0.9), value: value)
    }
}

// MARK: - Petits éléments réutilisés

struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.ui(11, .bold))
            .kerning(1.8)
            .foregroundStyle(Theme.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct StatCard: View {
    let value: String
    let label: String
    var highlighted: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.display(20))
                .foregroundStyle(highlighted ? Theme.orangeLight : Theme.cream)
            Text(label)
                .font(.ui(10, .bold))
                .kerning(0.6)
                .foregroundStyle(Theme.muted)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.border, lineWidth: 1)
        )
    }
}

struct StreakBadge: View {
    let streak: Int

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Theme.orangeLight)
            Text("\(streak)")
                .font(.display(14))
                .foregroundStyle(Theme.orangeLight)
            Text(streak > 1 ? "jours" : "jour")
                .font(.ui(11))
                .foregroundStyle(Theme.muted)
        }
        .padding(.horizontal, 12)
        .frame(height: 34)
        .background(Theme.orange.opacity(0.14), in: Capsule())
        .overlay(Capsule().stroke(Theme.orange.opacity(0.32), lineWidth: 1))
    }
}

/// Petit bouton rectangulaire réutilisé pour les ajouts rapides.
struct QuickChip: View {
    let label: String
    var height: CGFloat = 46
    let action: () -> Void

    var body: some View {
        Button {
            action()
            Haptics.tap()
        } label: {
            Text(label)
                .font(.ui(15, .bold))
                .foregroundStyle(Theme.cream)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

/// Bouton rond « − » / « + ».
struct StepButton: View {
    let systemName: String
    var size: CGFloat = 44
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button {
            action()
            Haptics.tap()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: size > 48 ? 20 : 15, weight: .bold))
                .foregroundStyle(enabled ? Theme.cream : Theme.upcomingText)
                .frame(width: size, height: size)
                .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: size > 48 ? 18 : 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

// MARK: - Carte d'un exercice sur l'écran du jour

struct ExerciseCard: View {
    let exercise: Exercise
    let count: Int
    let onAdd: (Int) -> Void
    let onEdit: () -> Void

    private var progress: Double {
        exercise.dailyGoal > 0 ? min(1.0, Double(count) / Double(exercise.dailyGoal)) : 1
    }

    private var isDone: Bool { count >= exercise.dailyGoal }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: exercise.kind.symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.orangeLight)
                Text(exercise.kind.name)
                    .font(.ui(15, .bold))
                    .foregroundStyle(Theme.cream)
                if isDone {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Theme.orange)
                }
                Spacer(minLength: 0)
                Button(action: onEdit) {
                    HStack(spacing: 4) {
                        Text("\(count)")
                            .font(.display(17))
                            .foregroundStyle(Theme.orangeLight)
                            .contentTransition(.numericText())
                        Text("/ \(exercise.dailyGoal)")
                            .font(.ui(13, .semibold))
                            .foregroundStyle(Theme.muted)
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.muted)
                    }
                    .padding(.horizontal, 10)
                    .frame(height: 34)
                    .background(Theme.surfaceAlt, in: Capsule())
                }
                .buttonStyle(.plain)
            }

            ProgressBarView(value: progress, height: 8)

            HStack(spacing: 8) {
                ForEach(exercise.kind.quickAdds, id: \.self) { amount in
                    QuickChip(label: "+\(amount)") { onAdd(amount) }
                }
            }
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Theme.border, lineWidth: 1)
        )
    }
}

// MARK: - Saisie des totaux d'une journée

/// Feuille de saisie : un compteur par exercice. Sert aussi bien à corriger
/// aujourd'hui qu'un jour passé depuis le calendrier.
struct DayEditSheet: View {
    let title: String
    let subtitle: String
    let exercises: [Exercise]
    let onSave: ([ExerciseKind: Int]) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var values: [ExerciseKind: Int]

    init(title: String, subtitle: String, exercises: [Exercise],
         initial: [ExerciseKind: Int], onSave: @escaping ([ExerciseKind: Int]) -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.exercises = exercises
        self.onSave = onSave
        _values = State(initialValue: initial)
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.display(20))
                    .foregroundStyle(Theme.cream)
                Text(subtitle)
                    .font(.ui(13))
                    .foregroundStyle(Theme.muted)
            }
            .padding(.top, 24)

            ScrollView {
                VStack(spacing: 14) {
                    ForEach(exercises) { exercise in
                        exerciseRow(exercise)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 20)
            }
            .scrollIndicators(.hidden)

            Button {
                onSave(values)
                dismiss()
            } label: {
                Text("ENREGISTRER")
                    .font(.display(16))
                    .foregroundStyle(Theme.background)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(Theme.orange, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 22)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
        .presentationDetents([.height(CGFloat(230 + 150 * min(exercises.count, 3)))])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.background)
    }

    private func exerciseRow(_ exercise: Exercise) -> some View {
        let value = values[exercise.kind] ?? 0
        return VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: exercise.kind.symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.orangeLight)
                Text(exercise.kind.name)
                    .font(.ui(14, .bold))
                    .foregroundStyle(Theme.cream)
                Spacer(minLength: 0)
                Text("objectif \(exercise.dailyGoal)")
                    .font(.ui(12))
                    .foregroundStyle(Theme.muted)
            }

            HStack(spacing: 18) {
                StepButton(systemName: "minus", size: 52, enabled: value > 0) {
                    values[exercise.kind] = max(0, value - 1)
                }
                Text("\(value)")
                    .font(.display(46))
                    .foregroundStyle(Theme.orange)
                    .frame(minWidth: 110)
                    .contentTransition(.numericText())
                StepButton(systemName: "plus", size: 52, enabled: value < 9999) {
                    values[exercise.kind] = min(9999, value + 1)
                }
            }

            HStack(spacing: 8) {
                ForEach(exercise.kind.quickAdds, id: \.self) { amount in
                    QuickChip(label: "+\(amount)", height: 40) {
                        values[exercise.kind] = min(9999, value + amount)
                    }
                }
                QuickChip(label: "Objectif", height: 40) {
                    values[exercise.kind] = exercise.dailyGoal
                }
            }
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Theme.border, lineWidth: 1)
        )
    }
}

// MARK: - Retour haptique

enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
