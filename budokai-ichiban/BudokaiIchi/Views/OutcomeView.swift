import SwiftUI

/// Le bilan de fin de séance. Il montre le détail de l'expérience gagnée :
/// un total opaque n'apprend rien sur ce qui a rapporté.
struct OutcomeView: View {
    @EnvironmentObject private var store: GameStore
    let outcome: SessionOutcome
    /// Le mot de fin de séance, quand le pack éditorial en fournit un.
    var closing: String?
    let onContinue: () -> Void

    @State private var appeared = false

    private var program: Program { Catalog.program(outcome.programID) }

    var body: some View {
        ZStack {
            program.gradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    Spacer(minLength: 46)

                    ZStack {
                        Circle().fill(Theme.cream.opacity(0.18)).frame(width: 150, height: 150)
                        Circle().fill(Theme.cream.opacity(0.26)).frame(width: 118, height: 118)
                        Image(systemName: outcome.stageCompleted != nil ? "star.fill" : "checkmark")
                            .font(.system(size: 56, weight: .black))
                            .foregroundStyle(Theme.cream)
                    }
                    .scaleEffect(appeared ? 1 : 0.6)
                    .opacity(appeared ? 1 : 0)

                    VStack(spacing: 6) {
                        Text(outcome.stageCompleted != nil ? "ÉTAPE FRANCHIE" : "SÉANCE TERMINÉE")
                            .font(.ui(12, .bold))
                            .kerning(3)
                            .foregroundStyle(Theme.ink.opacity(0.6))
                        Text((outcome.stageCompleted ?? outcome.sessionTitle).uppercased())
                            .font(.display(outcome.stageCompleted != nil ? 34 : 27))
                            .foregroundStyle(Theme.ink)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .minimumScaleFactor(0.7)

                        if let closing = closing {
                            Text(closing)
                                .font(.system(size: 14, weight: .regular, design: .serif))
                                .foregroundStyle(Theme.ink.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal, 26)
                                .padding(.top, 6)
                        }
                    }
                    .padding(.horizontal, 26)
                    .padding(.top, 24)

                    Text(Motivation.outcomeLine(tone: store.state.tone,
                                                stage: outcome.stageCompleted,
                                                streak: outcome.streak))
                        .font(.ui(15, .semibold))
                        .foregroundStyle(Theme.ink.opacity(0.82))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 30)
                        .padding(.top, 16)

                    // détail de l'expérience
                    VStack(spacing: 0) {
                        xpRow("Séance terminée", outcome.breakdown.base)
                        if outcome.breakdown.overshoot > 0 { xpRow("Dépassement", outcome.breakdown.overshoot) }
                        if outcome.breakdown.record > 0 { xpRow("Record personnel", outcome.breakdown.record) }
                        if outcome.breakdown.streakBonus > 0 {
                            xpRow("Série de \(outcome.streak) jours", outcome.breakdown.streakBonus)
                        }
                        if outcome.stageCompleted != nil { xpRow("Étape franchie", GameEngine.stageXP) }
                        if outcome.programCompleted { xpRow("Programme bouclé", GameEngine.programXP) }
                        Divider().overlay(Theme.ink.opacity(0.2))
                        HStack {
                            Text("TOTAL").font(.ui(12, .bold)).kerning(1.6)
                            Spacer()
                            Text("+\(outcome.totalXP.grouped) XP").font(.display(20))
                        }
                        .foregroundStyle(Theme.ink)
                        .padding(.vertical, 12)
                    }
                    .padding(.horizontal, 18)
                    .background(Theme.cream.opacity(0.22), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 26)
                    .padding(.top, 24)

                    if !outcome.statGains.isEmpty {
                        HStack(spacing: 9) {
                            ForEach(StatKind.allCases) { kind in
                                if let gain = outcome.statGains[kind], gain > 0 {
                                    VStack(spacing: 2) {
                                        Text("+\(gain)").font(.display(20)).foregroundStyle(Theme.ink)
                                        Text(kind.label.uppercased())
                                            .font(.ui(9, .bold)).kerning(1)
                                            .foregroundStyle(Theme.ink.opacity(0.68))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Theme.cream.opacity(0.22),
                                                in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                }
                            }
                        }
                        .padding(.horizontal, 26)
                        .padding(.top, 12)
                    }

                    if let rank = outcome.newRank {
                        HStack(spacing: 12) {
                            Text("NOUVEAU RANG")
                                .font(.ui(12, .bold)).kerning(1.6)
                                .foregroundStyle(Theme.ink.opacity(0.7))
                            RankBadge(rank: rank, size: 42)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(Theme.ink.opacity(0.14), in: Capsule())
                        .padding(.top, 16)
                    }

                    Spacer(minLength: 28)

                    Button {
                        Haptics.tap()
                        onContinue()
                    } label: {
                        Text("CONTINUER")
                            .font(.display(17))
                            .foregroundStyle(Theme.cream)
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                            .background(Theme.ink, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 26)
                    .padding(.bottom, 34)
                }
            }
            .scrollIndicators(.hidden)
        }
        .closeCross(action: onContinue)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) { appeared = true }
        }
    }

    private func xpRow(_ label: String, _ amount: Int) -> some View {
        HStack {
            Text(label).font(.ui(13, .semibold))
            Spacer()
            Text("+\(amount)").font(.ui(14, .bold))
        }
        .foregroundStyle(Theme.ink.opacity(0.85))
        .padding(.vertical, 9)
    }
}
