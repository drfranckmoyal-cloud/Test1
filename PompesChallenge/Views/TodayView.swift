import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: ChallengeStore
    @State private var showDaySheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                rings.padding(.top, 18)
                motivationCard.padding(.top, 24)
                SectionLabel(text: store.exercises.count > 1 ? "MES EXERCICES" : "AUJOURD'HUI")
                    .padding(.top, 24)
                exerciseCards.padding(.top, 10)
                resetButton.padding(.top, 14)
                challengeProgress.padding(.top, 24)
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(Theme.background)
        .sheet(isPresented: $showDaySheet) {
            DayEditSheet(
                title: "Jour \(store.dayIndex)",
                subtitle: "Corrige les totaux d'aujourd'hui",
                exercises: store.exercises,
                initial: currentValues
            ) { values in
                for exercise in store.exercises {
                    store.setCount(values[exercise.kind] ?? 0, kind: exercise.kind, for: store.today)
                }
            }
        }
    }

    private var currentValues: [ExerciseKind: Int] {
        var result: [ExerciseKind: Int] = [:]
        for exercise in store.exercises {
            result[exercise.kind] = store.todayCount(exercise.kind)
        }
        return result
    }

    // MARK: - Sections

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("JOUR \(store.dayIndex)")
                    .font(.display(22))
                    .foregroundStyle(Theme.cream)
                Text("SUR \(store.durationDays)")
                    .font(.ui(12, .semibold))
                    .kerning(1.6)
                    .foregroundStyle(Theme.muted)
            }
            Spacer(minLength: 8)
            StreakBadge(streak: store.currentStreak)
        }
    }

    private var rings: some View {
        let count = max(store.exercises.count, 1)
        let size: CGFloat = count == 1 ? 250 : (count == 2 ? 158 : 104)
        return HStack(alignment: .top, spacing: count == 1 ? 0 : 12) {
            ForEach(store.exercises) { exercise in
                ExerciseRing(
                    kind: exercise.kind,
                    count: store.todayCount(exercise.kind),
                    goal: exercise.dailyGoal,
                    size: size
                )
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var exerciseCards: some View {
        VStack(spacing: 10) {
            ForEach(store.exercises) { exercise in
                ExerciseCard(
                    exercise: exercise,
                    count: store.todayCount(exercise.kind),
                    onAdd: { amount in store.add(amount, to: exercise.kind) },
                    onEdit: { showDaySheet = true }
                )
            }
        }
    }

    private var motivationCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("MOTIVATION DU JOUR")
                .font(.ui(10, .bold))
                .kerning(2)
                .foregroundStyle(Theme.orangeLight)
            Text(motivationLine)
                .font(.ui(15, .semibold))
                .foregroundStyle(Theme.cream)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            LinearGradient(colors: [Theme.orange.opacity(0.16), Theme.amber.opacity(0.06)],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Theme.orange.opacity(0.22), lineWidth: 1)
        )
    }

    private var motivationLine: String {
        guard let focus = store.focusExercise else {
            return Motivation.daily(tone: store.tone, unit: "", remaining: 0, count: 0, dayIndex: store.dayIndex)
        }
        return Motivation.daily(
            tone: store.tone,
            unit: focus.kind.unit,
            remaining: store.remaining(focus, on: store.today),
            count: store.todayCount(focus.kind),
            dayIndex: store.dayIndex
        )
    }

    private var resetButton: some View {
        Button {
            store.resetToday()
            Haptics.tap()
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 12, weight: .semibold))
                Text("Remettre la journée à zéro")
                    .font(.ui(13, .semibold))
            }
            .foregroundStyle(Theme.muted)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
        }
        .buttonStyle(.plain)
    }

    private var challengeProgress: some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text("DÉFI \(store.durationDays) JOURS")
                    .font(.ui(11, .bold))
                    .kerning(1.6)
                    .foregroundStyle(Theme.muted)
                Spacer()
                HStack(spacing: 4) {
                    Text("\(store.validatedCount)")
                        .font(.ui(13, .bold))
                        .foregroundStyle(Theme.cream)
                    Text("/ \(store.durationDays) jours validés")
                        .font(.ui(13, .semibold))
                        .foregroundStyle(Theme.muted)
                }
            }
            ProgressBarView(value: store.challengeProgress)
        }
    }
}
