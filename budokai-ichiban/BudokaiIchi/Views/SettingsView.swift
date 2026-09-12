import SwiftUI
import UIKit
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var notificationsAllowed = true
    @State private var showReset = false

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Theme.ground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("RÉGLAGES")
                        .font(.display(24))
                        .foregroundStyle(Theme.text)
                        .padding(.bottom, 22)

                    SectionLabel(text: "NIVEAU DE CALIBRAGE")
                    HStack(spacing: 8) {
                        ForEach(Tier.allCases) { tier in
                            Chip(label: tier.label, selected: store.state.tier == tier) {
                                store.setTier(tier)
                            }
                        }
                    }
                    .padding(.top, 10)
                    Text("Change les charges des séances à venir, pas celles déjà faites.")
                        .font(.ui(12))
                        .foregroundStyle(Theme.muted)
                        .padding(.top, 8)

                    SectionLabel(text: "TON DES MESSAGES").padding(.top, 26)
                    HStack(spacing: 8) {
                        ForEach(MotivationTone.allCases) { tone in
                            Chip(label: tone.label, selected: store.state.tone == tone) {
                                store.setTone(tone)
                            }
                        }
                    }
                    .padding(.top, 10)

                    SectionLabel(text: "APPARENCE").padding(.top, 26)
                    HStack(spacing: 8) {
                        ForEach(Appearance.allCases) { appearance in
                            Chip(label: appearance.label, selected: store.state.appearance == appearance) {
                                store.setAppearance(appearance)
                            }
                        }
                    }
                    .padding(.top, 10)

                    SectionLabel(text: "RAPPELS").padding(.top, 26)
                    if !notificationsAllowed {
                        permissionBanner.padding(.top, 10)
                    }
                    VStack(spacing: 9) {
                        ForEach(store.state.reminders) { reminder in
                            ReminderRow(reminder: reminder)
                        }
                    }
                    .padding(.top, 10)

                    GhostButton(title: "Tout remettre à zéro") { showReset = true }
                        .padding(.top, 26)
                }
                .padding(.horizontal, 20)
                .padding(.top, 22)
                .padding(.bottom, 34)
            }
            .scrollIndicators(.hidden)

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.muted)
                    .frame(width: 44, height: 44)
                    .background(Theme.surface, in: Circle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.top, 14)
        }
        .task {
            let status = await NotificationManager.authorizationStatus()
            notificationsAllowed = (status == .authorized || status == .provisional || status == .ephemeral)
        }
        .alert("Tout remettre à zéro ?", isPresented: $showReset) {
            Button("Annuler", role: .cancel) {}
            Button("Effacer", role: .destructive) {
                store.resetEverything()
                dismiss()
            }
        } message: {
            Text("Expérience, rangs, caractéristiques, historique : tout disparaît. C'est irréversible.")
        }
    }

    private var permissionBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.gold)
            VStack(alignment: .leading, spacing: 8) {
                Text("Les notifications sont désactivées : les rappels ne partiront pas.")
                    .font(.ui(13))
                    .foregroundStyle(Theme.text)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Ouvrir les réglages") {
                    if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                }
                .font(.ui(13, .bold))
                .foregroundStyle(Theme.crimson)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.gold.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct ReminderRow: View {
    @EnvironmentObject private var store: GameStore
    let reminder: Reminder

    var body: some View {
        HStack(spacing: 14) {
            DatePicker("", selection: timeBinding, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .datePickerStyle(.compact)
                .frame(width: 100, alignment: .leading)
            Text(reminder.title)
                .font(.ui(13, .semibold))
                .foregroundStyle(Theme.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Spacer(minLength: 0)
            Toggle("", isOn: enabledBinding)
                .labelsHidden()
                .tint(Theme.crimson)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous).stroke(Theme.border, lineWidth: 1))
        .opacity(reminder.isEnabled ? 1 : 0.55)
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
                let parts = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                var updated = reminder
                updated.hour = parts.hour ?? reminder.hour
                updated.minute = parts.minute ?? reminder.minute
                store.update(updated)
            })
    }

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { reminder.isEnabled },
            set: { newValue in
                var updated = reminder
                updated.isEnabled = newValue
                store.update(updated)
            })
    }
}
