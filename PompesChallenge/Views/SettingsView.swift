import SwiftUI
import UIKit
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject private var store: ChallengeStore
    @Environment(\.openURL) private var openURL
    @State private var notificationsAllowed = true
    @State private var showNewChallenge = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header

                SectionLabel(text: "MON DÉFI").padding(.top, 22)
                challengeCard.padding(.top, 10)
                newChallengeButton.padding(.top, 10)

                SectionLabel(text: "MES \(store.reminders.count) RAPPELS").padding(.top, 26)
                if !notificationsAllowed {
                    permissionBanner.padding(.top, 10)
                }
                midnightCard.padding(.top, 10)
                VStack(spacing: 10) {
                    ForEach(store.reminders.indices, id: \.self) { index in
                        ReminderRow(reminder: store.reminders[index], slot: index)
                    }
                }
                .padding(.top, 10)

                SectionLabel(text: "TON DES MESSAGES").padding(.top, 26)
                tonePicker.padding(.top, 10)

                SectionLabel(text: "APPARENCE").padding(.top, 26)
                appearancePicker.padding(.top, 10)
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(Theme.background)
        .task {
            let status = await NotificationManager.authorizationStatus()
            notificationsAllowed = (status == .authorized || status == .provisional || status == .ephemeral)
        }
        .sheet(isPresented: $showNewChallenge) {
            NewChallengeSheet(currentDuration: store.durationDays, current: store.exercises)
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("RÉGLAGES")
                .font(.display(24))
                .foregroundStyle(Theme.cream)
            Text("DÉFI, RAPPELS ET APPARENCE")
                .font(.ui(12, .semibold))
                .kerning(1.6)
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var challengeCard: some View {
        VStack(spacing: 14) {
            HStack {
                Text("Jour \(store.dayIndex) sur \(store.durationDays)")
                    .font(.ui(14, .bold))
                    .foregroundStyle(Theme.cream)
                Spacer()
                Text("\(store.validatedCount) validés")
                    .font(.ui(12, .semibold))
                    .foregroundStyle(Theme.muted)
            }

            ForEach(store.exercises) { exercise in
                HStack(spacing: 12) {
                    Image(systemName: exercise.kind.symbol)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.orangeLight)
                        .frame(width: 24)
                    Text(exercise.kind.name)
                        .font(.ui(14, .semibold))
                        .foregroundStyle(Theme.cream)
                    Spacer(minLength: 0)
                    HStack(spacing: 8) {
                        StepButton(systemName: "minus", size: 38) {
                            store.setGoal(exercise.dailyGoal - exercise.kind.goalStep, for: exercise.kind)
                        }
                        Text("\(exercise.dailyGoal)")
                            .font(.display(18))
                            .foregroundStyle(Theme.orangeLight)
                            .frame(minWidth: 44)
                            .contentTransition(.numericText())
                        StepButton(systemName: "plus", size: 38) {
                            store.setGoal(exercise.dailyGoal + exercise.kind.goalStep, for: exercise.kind)
                        }
                    }
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

    private var newChallengeButton: some View {
        Button {
            showNewChallenge = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("Créer un nouveau défi")
                    .font(.display(15))
            }
            .foregroundStyle(Theme.background)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(Theme.orange, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var permissionBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 17))
                .foregroundStyle(Theme.amber)
            VStack(alignment: .leading, spacing: 8) {
                Text("Les notifications sont désactivées pour cette app : les rappels ne partiront pas.")
                    .font(.ui(13, .medium))
                    .foregroundStyle(Theme.cream)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Ouvrir les réglages") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
                .font(.ui(13, .bold))
                .foregroundStyle(Theme.orangeLight)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.amber.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.amber.opacity(0.35), lineWidth: 1)
        )
    }

    private var midnightCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "clock")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.orangeLight)
            Text("La journée compte de minuit à minuit. À 00:00 les compteurs repartent à zéro et le jour est validé ou manqué.")
                .font(.ui(13, .medium))
                .foregroundStyle(Theme.cream.opacity(0.9))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.orange.opacity(0.24), lineWidth: 1)
        )
    }

    private var tonePicker: some View {
        HStack(spacing: 8) {
            ForEach(MotivationTone.allCases) { tone in
                SelectableChip(label: tone.label, selected: store.tone == tone) {
                    store.setTone(tone)
                }
            }
        }
    }

    private var appearancePicker: some View {
        HStack(spacing: 8) {
            ForEach(Appearance.allCases) { appearance in
                SelectableChip(label: appearance.label, selected: store.appearance == appearance) {
                    store.setAppearance(appearance)
                }
            }
        }
    }
}

/// Une pastille de choix, sélectionnée ou non.
struct SelectableChip: View {
    let label: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            action()
            Haptics.tap()
        } label: {
            Text(label)
                .font(.ui(13, selected ? .bold : .semibold))
                .foregroundStyle(selected ? Theme.background : Theme.cream.opacity(0.75))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(
                    selected ? AnyShapeStyle(Theme.orange) : AnyShapeStyle(Theme.surface),
                    in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(selected ? Color.clear : Theme.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Une ligne de rappel

struct ReminderRow: View {
    @EnvironmentObject private var store: ChallengeStore
    let reminder: Reminder
    let slot: Int

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(Theme.orangeLight)
                .frame(width: 46, height: 46)
                .background(Theme.orange.opacity(0.14), in: RoundedRectangle(cornerRadius: 15, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                DatePicker("", selection: timeBinding, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .tint(Theme.orangeLight)
                    .frame(width: 100, alignment: .leading)
                Text("\(reminder.title) · \(store.shareText(for: reminder))")
                    .font(.ui(12, .semibold))
                    .foregroundStyle(Theme.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            Spacer(minLength: 0)

            Toggle("", isOn: enabledBinding)
                .labelsHidden()
                .tint(Theme.orange)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Theme.border, lineWidth: 1)
        )
        .opacity(reminder.isEnabled ? 1 : 0.55)
    }

    private var icon: String {
        switch slot {
        case 0: return "sunrise.fill"
        case 1: return "sun.max.fill"
        default: return "moon.fill"
        }
    }

    private var timeBinding: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = reminder.hour
                components.minute = reminder.minute
                return Calendar.current.date(from: components) ?? Date()
            },
            set: { newValue in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                var updated = reminder
                updated.hour = components.hour ?? reminder.hour
                updated.minute = components.minute ?? reminder.minute
                store.update(updated)
            }
        )
    }

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { reminder.isEnabled },
            set: { newValue in
                var updated = reminder
                updated.isEnabled = newValue
                store.update(updated)
            }
        )
    }
}
