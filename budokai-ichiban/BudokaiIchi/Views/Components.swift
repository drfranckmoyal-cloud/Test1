import SwiftUI
import UIKit

// MARK: - Anneaux et barres

struct ProgressRing: View {
    var progress: Double
    var lineWidth: CGFloat = 18
    var tint: Color = Theme.crimson

    var body: some View {
        ZStack {
            Circle().stroke(Theme.surfaceAlt, style: StrokeStyle(lineWidth: lineWidth))
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .animation(.spring(response: 0.55, dampingFraction: 0.85), value: progress)
    }
}

struct ProgressBar: View {
    var value: Double
    var height: CGFloat = 8
    var tint: Color = Theme.crimson

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.surfaceAlt)
                Capsule().fill(tint).frame(width: min(max(value, 0), 1) * geometry.size.width)
            }
        }
        .frame(height: height)
        .animation(.spring(response: 0.5, dampingFraction: 0.9), value: value)
    }
}

// MARK: - Rang

struct RankBadge: View {
    var rank: Rank
    var size: CGFloat = 48

    var body: some View {
        Text(rank.label)
            .font(.display(size * 0.44))
            .foregroundStyle(rank == .sPlus ? Theme.ground : Theme.ink)
            .frame(width: size, height: size)
            .background(Theme.rankColor(rank), in: RoundedRectangle(cornerRadius: size * 0.12, style: .continuous))
    }
}

// MARK: - Petits éléments

struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.ui(10, .bold))
            .kerning(2.4)
            .foregroundStyle(Theme.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PrimaryButton: View {
    let title: String
    var tint: Color = Theme.crimson
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button {
            guard enabled else { return }
            Haptics.tap()
            action()
        } label: {
            Text(title)
                .font(.display(17))
                .foregroundStyle(enabled ? Theme.cream : Theme.muted)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(enabled ? AnyShapeStyle(tint) : AnyShapeStyle(Theme.surfaceAlt),
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

struct GhostButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Text(title)
                .font(.ui(14, .bold))
                .foregroundStyle(Theme.muted)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

struct StepButton: View {
    let systemName: String
    var size: CGFloat = 52
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button {
            guard enabled else { return }
            Haptics.tap()
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: size > 46 ? 20 : 15, weight: .bold))
                .foregroundStyle(enabled ? Theme.text : Theme.dim)
                .frame(width: size, height: size)
                .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: size * 0.32, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

struct Chip: View {
    let label: String
    var selected: Bool = false
    var tint: Color = Theme.crimson
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Text(label)
                .font(.ui(13, selected ? .bold : .semibold))
                .foregroundStyle(selected ? Theme.cream : Theme.text.opacity(0.75))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(selected ? AnyShapeStyle(tint) : AnyShapeStyle(Theme.surface),
                            in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(selected ? Color.clear : Theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Radar des caractéristiques

struct StatRadar: View {
    /// Valeurs par caractéristique, dans l'ordre Force, Vitesse, Endurance.
    var values: [StatKind: Int]
    var size: CGFloat = 170
    var tint: Color = Theme.gold

    private var maxValue: Double {
        max(20.0, Double(values.values.max() ?? 0) * 1.15)
    }

    private func point(_ kind: StatKind, index: Int, ratio: Double) -> CGPoint {
        let center = size / 2
        let radius = (size / 2 - 12) * ratio
        let angle = Double(index) * 2 * .pi / 3 - .pi / 2
        return CGPoint(x: center + radius * cos(angle), y: center + radius * sin(angle))
    }

    private func polygon(ratio: Double) -> Path {
        var path = Path()
        for index in 0..<3 {
            let p = point(StatKind.allCases[index], index: index, ratio: ratio)
            if index == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }

    private var valuePath: Path {
        var path = Path()
        for index in 0..<3 {
            let kind = StatKind.allCases[index]
            let ratio = min(1.0, Double(values[kind] ?? 0) / maxValue)
            let p = point(kind, index: index, ratio: max(0.06, ratio))
            if index == 0 { path.move(to: p) } else { path.addLine(to: p) }
        }
        path.closeSubpath()
        return path
    }

    var body: some View {
        ZStack {
            polygon(ratio: 1).stroke(Theme.border, lineWidth: 1)
            polygon(ratio: 0.66).stroke(Theme.border, lineWidth: 1)
            polygon(ratio: 0.33).stroke(Theme.border, lineWidth: 1)
            valuePath.fill(tint.opacity(0.28))
            valuePath.stroke(tint, style: StrokeStyle(lineWidth: 2, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Tuile de programme

/// Une image qui remplit son cadre sans le faire grandir.
///
/// `scaledToFill` seul laisse l'image imposer sa taille au conteneur ; on la
/// pose donc en surcouche d'un fond transparent, puis on rogne.
struct ArtworkFill: View {
    let name: String
    /// Par où l'image est retenue quand elle déborde. Le haut par défaut :
    /// une image plus haute que son cadre perdrait sinon la tête du
    /// personnage, coupée au profit du buste.
    var anchor: Alignment = .top

    var body: some View {
        Color.clear
            .overlay(alignment: anchor) { Image(name).resizable().scaledToFill() }
            .clipped()
    }
}

struct ProgramTile: View {
    let program: Program
    var progress: Double
    var locked: Bool
    var height: CGFloat = 152
    /// L'image à montrer. Par défaut celle de présentation du programme.
    var tile: String?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            program.gradient
            ArtworkFill(name: tile ?? program.tileImage)
                .opacity(0.92)
            // le texte du bas doit rester lisible sur n'importe quelle image
            LinearGradient(colors: [Color.black.opacity(0.10), Color.clear, Color.black.opacity(0.78)],
                           startPoint: .top, endPoint: .bottom)

            VStack(alignment: .leading, spacing: 6) {
                Text(program.name.uppercased())
                    .font(.display(17))
                    .foregroundStyle(Theme.cream)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text(program.family.uppercased())
                    .font(.ui(9, .bold))
                    .kerning(1.4)
                    .foregroundStyle(Theme.cream.opacity(0.78))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                ProgressBar(value: progress, height: 4, tint: Theme.cream)
            }
            .padding(12)

            if locked {
                ZStack {
                    Color.black.opacity(0.74)
                    VStack(spacing: 6) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 17))
                            .foregroundStyle(Theme.muted)
                        Text(program.unlock.label.uppercased())
                            .font(.ui(9, .bold))
                            .kerning(0.8)
                            .foregroundStyle(Theme.muted)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                            .padding(.horizontal, 8)
                    }
                }
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Retour haptique

enum Haptics {
    static func tap() { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
}
