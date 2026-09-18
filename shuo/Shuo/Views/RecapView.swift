import SwiftUI

/// Le récapitulatif. Ce qu'on a vu, ce qui tient, ce qui reviendra.
///
/// Trois choses qu'il ne fait pas, et c'est délibéré : pas de note scolaire,
/// pas de contenu nouveau, pas d'annonce de la leçon suivante (A17).
struct RecapView: View {

    let recap: SessionRecap
    let tutor: Tutor
    let onClose: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header

                if recap.lines.isEmpty {
                    Text("Rien de neuf aujourd'hui — on a consolidé.")
                        .font(Theme.body)
                        .foregroundStyle(Theme.inkSoft)
                        .cartouche()
                } else {
                    VStack(spacing: 10) {
                        ForEach(recap.lines) { line in
                            recapLine(line)
                        }
                    }
                }

                if let note = recap.pronunciationNote {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "waveform")
                            .foregroundStyle(Theme.seal)
                        Text(note)
                            .font(Theme.body)
                            .foregroundStyle(Theme.ink)
                    }
                    .cartouche()
                }

                if !recap.comingBack.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reviendra bientôt")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.inkSoft)
                        Text(recap.comingBack.joined(separator: "   "))
                            .font(Theme.hanzi(22))
                            .foregroundStyle(Theme.ink)
                    }
                    .cartouche()
                }

                Button("Terminer", action: onClose)
                    .font(Theme.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Theme.seal)
                    )
                    .foregroundStyle(Color.white)
                    .padding(.top, 8)
            }
            .padding(20)
        }
        .paperBackground()
    }

    private var header: some View {
        VStack(spacing: 10) {
            TutorAvatar(tutor: tutor, size: 54)
            Text("C'est fini pour aujourd'hui")
                .font(Theme.title)
                .foregroundStyle(Theme.ink)
            Text("\(recap.durationMinutes) minutes")
                .font(Theme.caption)
                .foregroundStyle(Theme.inkSoft)
        }
        .padding(.top, 20)
    }

    private func recapLine(_ line: SessionRecap.Line) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(line.hanzi)
                    .font(Theme.hanzi(30))
                    .foregroundStyle(Theme.ink)
                Text("\(line.pinyin) · \(line.fr)")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(line.verdict.label)
                    .font(Theme.caption)
                    .foregroundStyle(Theme.color(for: line.status))
                StatusPill(status: line.status)
            }
        }
        .cartouche(padding: 16)
    }
}
