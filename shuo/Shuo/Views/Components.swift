import SwiftUI

/// L'avatar d'un tuteur : un disque, une couleur, un caractère. Pas de
/// portrait — un signe suffit à le reconnaître d'une séance à l'autre.
struct TutorAvatar: View {
    let tutor: Tutor
    var size: CGFloat = 48

    var body: some View {
        ZStack {
            Circle()
                .fill(tutor.accent.opacity(0.16))
            Circle()
                .stroke(tutor.accent.opacity(0.5), lineWidth: 1.5)
            Text(tutor.initial)
                .font(Theme.hanzi(size * 0.46))
                .foregroundStyle(tutor.accent)
        }
        .frame(width: size, height: size)
        .accessibilityLabel(tutor.pinyin)
    }
}

/// Le bouton des deux actions principales de l'accueil.
struct BigButton: View {
    let title: String
    let subtitle: String?
    let systemImage: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 24))
                    .foregroundStyle(tint)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(Theme.body.weight(.semibold))
                        .foregroundStyle(Theme.ink)
                    if let subtitle {
                        Text(subtitle)
                            .font(Theme.caption)
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.inkSoft)
            }
            .cartouche()
        }
        .buttonStyle(.plain)
    }
}

/// Le bouton des actions de dépannage : plus discret, même matière.
struct SmallButton: View {
    let title: String
    let detail: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(Theme.caption)
                    .foregroundStyle(Theme.ink)
                if let detail {
                    Text("· \(detail)")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.inkSoft)
                }
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Theme.hairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Un compte par statut, avec sa pastille.
struct StatusDot: View {
    let color: Color
    let count: Int
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 9, height: 9)
            Text("\(count)")
                .font(Theme.body.weight(.semibold))
                .foregroundStyle(Theme.ink)
        }
        .accessibilityLabel("\(count) \(label)")
    }
}

/// Le badge du modèle actif, visible en permanence pendant la séance.
///
/// Le dossier y tient : on doit pouvoir lire, à tout moment, quel modèle
/// parle réellement — pas une catégorie, le nom.
struct ModelBadge: View {
    let model: LanguageModel
    let justSwitched: Bool
    let isLocal: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isLocal ? Theme.inkSoft : model.complexity.color)
                .frame(width: 7, height: 7)
            Text(isLocal ? "Local" : model.displayName)
                .font(Theme.mono)
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(Theme.card)
        )
        .overlay(
            Capsule().stroke(justSwitched ? model.complexity.color : Theme.hairline, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.3), value: justSwitched)
        .accessibilityLabel("Modèle actif : \(isLocal ? "local" : model.displayName)")
    }
}

/// L'onde du micro. Elle ne mesure rien d'utile — elle dit seulement « je
/// t'entends », ce qui est déjà l'essentiel quand on parle à un téléphone.
struct InputWave: View {
    let level: Float
    let active: Bool

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<9, id: \.self) { index in
                Capsule()
                    .fill(active ? Theme.seal : Theme.hairline)
                    .frame(width: 3, height: height(for: index))
            }
        }
        .animation(.easeOut(duration: 0.12), value: level)
        .frame(height: 26)
    }

    private func height(for index: Int) -> CGFloat {
        let distance = abs(Double(index) - 4) / 4
        let base = 4.0
        let amplitude = Double(min(max(level * 9, 0), 1)) * 22
        return CGFloat(base + amplitude * (1 - distance * 0.7))
    }
}

/// La pastille de statut d'un mot.
struct StatusPill: View {
    let status: MasteryStatus

    var body: some View {
        Text(status.label)
            .font(Theme.caption)
            .foregroundStyle(Theme.color(for: status))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule().fill(Theme.color(for: status).opacity(0.14))
            )
    }
}
