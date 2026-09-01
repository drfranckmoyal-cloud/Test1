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

/// Bouton d'ajout rapide (+1, +5, +10, +20).
struct QuickAddButton: View {
    let amount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("+\(amount)")
                .font(.ui(16, .bold))
                .foregroundStyle(Theme.cream)
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

// MARK: - Saisie d'un total

/// Feuille de saisie utilisée pour enregistrer une série et pour corriger
/// un jour passé depuis le calendrier.
struct CountSheet: View {
    let title: String
    let subtitle: String
    let goal: Int
    let initialValue: Int
    let onSave: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var value: Int

    init(title: String, subtitle: String, goal: Int, initialValue: Int, onSave: @escaping (Int) -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.goal = goal
        self.initialValue = initialValue
        self.onSave = onSave
        _value = State(initialValue: initialValue)
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
            .padding(.top, 26)

            HStack(spacing: 22) {
                stepButton(systemName: "minus", enabled: value > 0) {
                    value = max(0, value - 1)
                }
                Text("\(value)")
                    .font(.display(64))
                    .foregroundStyle(Theme.orangeLight)
                    .frame(minWidth: 130)
                    .contentTransition(.numericText())
                stepButton(systemName: "plus", enabled: value < 999) {
                    value = min(999, value + 1)
                }
            }
            .padding(.top, 20)

            HStack(spacing: 10) {
                ForEach([5, 10, 20], id: \.self) { amount in
                    Button {
                        value = min(999, value + amount)
                        Haptics.tap()
                    } label: {
                        Text("+\(amount)")
                            .font(.ui(15, .bold))
                            .foregroundStyle(Theme.cream)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Theme.border, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
                Button {
                    value = goal
                    Haptics.tap()
                } label: {
                    Text("Objectif")
                        .font(.ui(15, .bold))
                        .foregroundStyle(Theme.cream)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Theme.border, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 22)
            .padding(.top, 22)

            Spacer(minLength: 16)

            Button {
                onSave(value)
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
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.background)
        .presentationDetents([.height(400)])
        .presentationDragIndicator(.visible)
        .presentationBackground(Theme.background)
    }

    private func stepButton(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            action()
            Haptics.tap()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(enabled ? Theme.cream : Theme.upcomingText)
                .frame(width: 56, height: 56)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Theme.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
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
