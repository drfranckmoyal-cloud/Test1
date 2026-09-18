import SwiftUI

/// La carte de mot : hanzi en grand, pinyin, sens en français.
///
/// Le caractère est montré dès le premier jour, mais le lire n'est pas une
/// condition pour valider l'oral — c'est ce que dit le dossier, et c'est ce
/// que fait l'app : rien ici ne bloque la suite.
struct WordCardView: View {
    let item: VocabItem
    let status: MasteryStatus
    /// Le masquage progressif, pour plus tard. Rien n'en dépend aujourd'hui.
    var hidePinyin: Bool = false
    var hideMeaning: Bool = false

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                StatusPill(status: status)
                Spacer()
                Text(item.posFr)
                    .font(Theme.caption)
                    .foregroundStyle(Theme.inkSoft)
            }

            Text(item.hanzi)
                .font(Theme.hanzi(item.hanzi.count > 2 ? 64 : 96))
                .foregroundStyle(Theme.ink)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            if !hidePinyin {
                Text(item.pinyin)
                    .font(Theme.pinyin)
                    .foregroundStyle(Theme.inkSoft)
            }

            if !hideMeaning {
                Text(item.fr)
                    .font(Theme.meaning)
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
            }

            Divider().overlay(Theme.hairline)

            VStack(spacing: 4) {
                Text(item.exampleZh)
                    .font(Theme.hanzi(22))
                    .foregroundStyle(Theme.ink)
                Text(item.exampleFr)
                    .font(Theme.caption)
                    .foregroundStyle(Theme.inkSoft)
            }
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .cartouche(padding: 22)
    }
}

/// La carte des phases sans mot : rappel groupé, écoute, conversation.
struct PhaseCardView: View {
    let phase: SessionPhase
    let items: [VocabItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(phase.kind.label)
                .font(Theme.caption)
                .foregroundStyle(Theme.seal)

            if let text = phase.text {
                Text(text)
                    .font(Theme.body)
                    .foregroundStyle(Theme.ink)
            }

            if let dialogue = phase.dialogue, !dialogue.zh.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(dialogue.zh.enumerated()), id: \.offset) { index, line in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(line)
                                .font(Theme.hanzi(20))
                                .foregroundStyle(Theme.ink)
                            if dialogue.fr.indices.contains(index) {
                                Text(dialogue.fr[index])
                                    .font(Theme.caption)
                                    .foregroundStyle(Theme.inkSoft)
                            }
                        }
                    }
                }
            }

            if !items.isEmpty {
                // Les mots en jeu, en petit : de quoi se raccrocher sans que
                // l'écran devienne une liste à réviser des yeux.
                FlowRow(items: items.map(\.hanzi))
            }
        }
        .cartouche()
    }
}

/// Une rangée de petites étiquettes qui passe à la ligne toute seule.
struct FlowRow: View {
    let items: [String]

    var body: some View {
        // Trois par ligne : au-delà, ça devient une liste, et une liste
        // n'appelle pas à parler.
        let rows = stride(from: 0, to: items.count, by: 3).map {
            Array(items[$0..<min($0 + 3, items.count)])
        }
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 6) {
                    ForEach(row, id: \.self) { label in
                        Text(label)
                            .font(Theme.hanzi(16))
                            .foregroundStyle(Theme.inkSoft)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Theme.paper))
                    }
                }
            }
        }
    }
}
