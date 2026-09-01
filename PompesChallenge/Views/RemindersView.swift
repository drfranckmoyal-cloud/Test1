import SwiftUI
import UIKit
import UserNotifications

struct RemindersView: View {
    @EnvironmentObject private var store: ChallengeStore
    @State private var notificationsAllowed = true
    @State private var showRestartAlert = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                if !notificationsAllowed {
                    permissionBanner.padding(.top, 16)
                }
                midnightCard.padding(.top, 18)

                SectionLabel(text: "MES \(store.reminders.count) RAPPELS").padding(.top, 22)
                VStack(spacing: 10) {
                    ForEach(store.reminders.indices, id: \.self) { index in
                        ReminderRow(reminder: store.reminders[index], slot: index)
                    }
                }
                .padding(.top, 10)

                SectionLabel(text: "TON DES MESSAGES").padding(.top, 22)
                tonePicker.padding(.top, 10)

                goalRow.padding(.top, 14)

                restartButton.padding(.top, 22)
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
        .alert("Recommencer le défi ?", isPresented: $showRestartAlert) {
            Button("Annuler", role: .cancel) {}
            Button("Recommencer", role: .destructive) {
                store.restart()
                Haptics.success()
            }
        } message: {
            Text("Le compteur repart au jour 1 aujourd'hui. Les \(store.durationDays) jours déjà enregistrés seront effacés.")
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("RAPPELS")
                .font(.display(24))
                .foregroundStyle(Theme.cream)
            Text("\(store.reminders.count) PAR JOUR · \(store.goal) POMPES AU TOTAL")
                .font(.ui(12, .semibold))
                .kerning(1.6)
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                        UIApplication.shared.open(url)
                    }
                }
                .font(.ui(13, .bold))
                .foregroundStyle(Theme.orangeLight)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.amber.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.amber.opacity(0.3), lineWidth: 1)
        )
    }

    private var midnightCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "clock")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.orangeLight)
            Text("La journée compte de minuit à minuit. À 00:00 le compteur repart à zéro et le jour est validé ou manqué.")
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
                Button {
                    store.setTone(tone)
                    Haptics.tap()
                } label: {
                    Text(tone.label)
                        .font(.ui(13, store.tone == tone ? .bold : .semibold))
                        .foregroundStyle(store.tone == tone ? Theme.background : Theme.cream.opacity(0.75))
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(
                            store.tone == tone ? AnyShapeStyle(Theme.orange) : AnyShapeStyle(Theme.surface),
                            in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 15, style: .continuous)
                                .stroke(store.tone == tone ? Color.clear : Theme.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var goalRow: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Objectif quotidien")
                    .font(.ui(14, .bold))
                    .foregroundStyle(Theme.cream)
                Text("Réparti sur les \(store.reminders.count) rappels")
                    .font(.ui(12, .semibold))
                    .foregroundStyle(Theme.muted)
            }
            Spacer(minLength: 0)
            HStack(spacing: 10) {
                stepper(systemName: "minus") { store.setGoal(store.goal - 10) }
                Text("\(store.goal)")
                    .font(.display(20))
                    .foregroundStyle(Theme.orangeLight)
                    .frame(minWidth: 46)
                    .contentTransition(.numericText())
                stepper(systemName: "plus") { store.setGoal(store.goal + 10) }
            }
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.border, lineWidth: 1)
        )
    }

    private func stepper(systemName: String, action: @escaping () -> Void) -> some View {
        Button {
            action()
            Haptics.tap()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Theme.cream.opacity(0.8))
                .frame(width: 44, height: 44)
                .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var restartButton: some View {
        Button {
            showRestartAlert = true
        } label: {
            Text("Recommencer le défi")
                .font(.ui(14, .bold))
                .foregroundStyle(Theme.missedText)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Theme.border, lineWidth: 1)
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
                Text("\(reminder.title) · \(reminder.share) pompes")
                    .font(.ui(12, .semibold))
                    .foregroundStyle(Theme.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
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
