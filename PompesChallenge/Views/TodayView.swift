import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var store: ChallengeStore
    @State private var showSetSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                ring.padding(.top, 16)
                quickAdd.padding(.top, 22)
                actionRow.padding(.top, 10)
                motivationCard.padding(.top, 18)
                monthProgress.padding(.top, 26)
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(Theme.background)
        .sheet(isPresented: $showSetSheet) {
            CountSheet(
                title: "Total du jour",
                subtitle: "Objectif : \(store.goal) pompes",
                goal: store.goal,
                initialValue: store.todayCount
            ) { value in
                store.setCount(value, for: store.today)
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("JOUR \(store.dayIndex)")
                    .font(.display(22))
                    .foregroundStyle(Theme.cream)
                Text("SUR \(store.durationDays) · \(store.goal) POMPES / JOUR")
                    .font(.ui(12, .semibold))
                    .kerning(1.6)
                    .foregroundStyle(Theme.muted)
            }
            Spacer(minLength: 8)
            StreakBadge(streak: store.currentStreak)
        }
    }

    private var ring: some View {
        ZStack {
            ProgressRing(progress: store.todayProgress, lineWidth: 20)
            VStack(spacing: 2) {
                Text("\(store.todayCount)")
                    .font(.display(84))
                    .foregroundStyle(Theme.orange)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: store.todayCount)
                Text("SUR \(store.goal) POMPES")
                    .font(.ui(13, .bold))
                    .kerning(2.4)
                    .foregroundStyle(Theme.muted)
                Text(store.remainingToday == 0
                     ? "Objectif atteint"
                     : "\(store.remainingToday) pompes restantes")
                    .font(.ui(13, .semibold))
                    .foregroundStyle(Theme.cream)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Theme.surfaceAlt, in: Capsule())
                    .padding(.top, 10)
            }
        }
        .frame(width: 268, height: 268)
    }

    private var quickAdd: some View {
        HStack(spacing: 10) {
            ForEach([1, 5, 10, 20], id: \.self) { amount in
                QuickAddButton(amount: amount) {
                    store.add(amount)
                    Haptics.tap()
                }
            }
        }
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            Button {
                showSetSheet = true
            } label: {
                Text("ENREGISTRER UNE SÉRIE")
                    .font(.display(16))
                    .foregroundStyle(Theme.background)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(Theme.orange, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
                store.resetToday()
                Haptics.tap()
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.muted)
                    .frame(width: 58, height: 58)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Theme.border, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Remettre le compteur du jour à zéro")
        }
    }

    private var motivationCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("MOTIVATION DU JOUR")
                .font(.ui(10, .bold))
                .kerning(2)
                .foregroundStyle(Theme.orangeLight)
            Text(Motivation.daily(
                tone: store.tone,
                remaining: store.remainingToday,
                count: store.todayCount,
                goal: store.goal,
                dayIndex: store.dayIndex,
                duration: store.durationDays
            ))
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

    private var monthProgress: some View {
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
            ProgressBarView(value: store.monthProgress)
        }
    }
}
