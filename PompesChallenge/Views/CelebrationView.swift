import SwiftUI

struct CelebrationView: View {
    @EnvironmentObject private var store: ChallengeStore
    @Environment(\.dismiss) private var dismiss

    let celebration: Celebration

    @State private var starScale: CGFloat = 0.6
    @State private var starOpacity: Double = 0

    var body: some View {
        ZStack {
            Theme.celebrationGradient.ignoresSafeArea()
            SunburstView()
                .opacity(0.16)
                .offset(y: -140)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 24)

                starBadge
                    .scaleEffect(starScale)
                    .opacity(starOpacity)

                VStack(spacing: 4) {
                    Text("JOUR \(celebration.dayIndex) SUR \(celebration.durationDays)")
                        .font(.ui(13, .bold))
                        .kerning(3)
                        .foregroundStyle(Theme.ink.opacity(0.62))
                    Text("VALIDÉ")
                        .font(.display(60))
                        .foregroundStyle(Theme.ink)
                }
                .padding(.top, 26)

                HStack(spacing: 12) {
                    celebrationStat(value: "\(celebration.count)", label: "POMPES AUJOURD'HUI")
                    celebrationStat(value: "\(celebration.streak)", label: celebration.streak > 1 ? "JOURS D'AFFILÉE" : "JOUR D'AFFILÉE")
                }
                .padding(.top, 26)

                Text(Motivation.celebration(
                    tone: store.tone,
                    dayIndex: celebration.dayIndex,
                    duration: celebration.durationDays,
                    total: celebration.total
                ))
                .font(.ui(17, .semibold))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .foregroundStyle(Theme.ink.opacity(0.86))
                .padding(.horizontal, 34)
                .padding(.top, 22)

                Spacer(minLength: 20)

                weekStrip

                Button {
                    dismiss()
                } label: {
                    Text("CONTINUER")
                        .font(.display(16))
                        .foregroundStyle(Theme.creamOnOrange)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(Theme.ink, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 26)
                .padding(.top, 20)

                Text(nextReminderLabel)
                    .font(.ui(13, .semibold))
                    .foregroundStyle(Theme.ink.opacity(0.66))
                    .padding(.top, 12)
                    .padding(.bottom, 24)
            }
        }
        .onAppear {
            Haptics.success()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                starScale = 1
                starOpacity = 1
            }
        }
    }

    // MARK: - Morceaux

    private var starBadge: some View {
        ZStack {
            Circle().fill(Theme.creamOnOrange.opacity(0.20)).frame(width: 168, height: 168)
            Circle().fill(Theme.creamOnOrange.opacity(0.28)).frame(width: 136, height: 136)
            Image(systemName: "star.fill")
                .font(.system(size: 76))
                .foregroundStyle(Theme.creamOnOrange)
        }
    }

    private func celebrationStat(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.display(30))
                .foregroundStyle(Theme.ink)
            Text(label)
                .font(.ui(11, .bold))
                .kerning(1.2)
                .foregroundStyle(Theme.ink.opacity(0.68))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(Theme.creamOnOrange.opacity(0.24), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var weekStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TA SEMAINE")
                .font(.ui(11, .bold))
                .kerning(1.8)
                .foregroundStyle(Theme.ink.opacity(0.62))
            HStack(spacing: 7) {
                ForEach(store.lastSevenDays) { day in
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(day.status == .validated
                                  ? AnyShapeStyle(Theme.creamOnOrange)
                                  : AnyShapeStyle(Theme.ink.opacity(0.16)))
                        if day.status == .validated {
                            Image(systemName: "star.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(Theme.orangeDeep)
                        } else {
                            Text("\(day.id)")
                                .font(.ui(11, .bold))
                                .foregroundStyle(Theme.ink.opacity(0.5))
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(day.id == celebration.dayIndex ? Theme.ink : Color.clear, lineWidth: 2)
                    )
                }
            }
        }
        .padding(.horizontal, 26)
    }

    private var nextReminderLabel: String {
        guard let next = store.reminders.first(where: { $0.isEnabled }) else {
            return "Aucun rappel actif"
        }
        return "Prochain rappel demain à \(String(format: "%02d:%02d", next.hour, next.minute))"
    }
}

/// Les rayons derrière l'étoile.
struct SunburstView: View {
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = max(size.width, size.height)
            let rays = 18
            for index in 0..<rays where index % 2 == 0 {
                let start = Double(index) / Double(rays) * 2 * .pi
                let end = Double(index + 1) / Double(rays) * 2 * .pi
                var path = Path()
                path.move(to: center)
                path.addLine(to: CGPoint(x: center.x + cos(start) * radius, y: center.y + sin(start) * radius))
                path.addLine(to: CGPoint(x: center.x + cos(end) * radius, y: center.y + sin(end) * radius))
                path.closeSubpath()
                context.fill(path, with: .color(Theme.creamOnOrange))
            }
        }
    }
}
