import SwiftUI

/// La séance, étape par étape. Le chrono tourne pour les blocs minutés et
/// pour les temps de repos ; les répétitions se valident à la main, avec le
/// nombre réellement effectué, pas le nombre visé.
struct GuidedSessionView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    let session: PlannedSession

    @State private var index = 0
    @State private var achieved: [Int: Int] = [:]
    @State private var value = 0
    @State private var remaining = 0
    @State private var resting = false
    @State private var outcome: SessionOutcome?

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var program: Program { Catalog.program(session.programID) }
    private var step: SessionStep { session.steps[min(index, session.steps.count - 1)] }

    var body: some View {
        ZStack {
            Theme.ground.ignoresSafeArea()
            if let outcome = outcome {
                OutcomeView(outcome: outcome) { dismiss() }
            } else {
                running
            }
        }
        .onAppear { prepare(0) }
        .onReceive(ticker) { _ in tick() }
    }

    // MARK: - Déroulé

    private var running: some View {
        VStack(spacing: 0) {
            progressHeader

            Spacer(minLength: 10)

            VStack(spacing: 6) {
                Text(resting ? "REPOS" : step.name.uppercased())
                    .font(.display(resting ? 22 : 30))
                    .foregroundStyle(resting ? Theme.muted : Theme.text)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                Text(resting ? "Étape suivante : \(nextName)" : step.detail)
                    .font(.ui(14))
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 26)

            Spacer(minLength: 10)

            dial

            Spacer(minLength: 10)

            controls
                .padding(.horizontal, 22)
                .padding(.bottom, 28)
        }
    }

    private var progressHeader: some View {
        HStack(spacing: 12) {
            ForEach(session.steps.indices, id: \.self) { position in
                Capsule()
                    .fill(position < index ? program.light : (position == index ? program.light.opacity(0.55) : Theme.surfaceAlt))
                    .frame(height: 4)
            }
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
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
    }

    private var dial: some View {
        ZStack {
            ProgressRing(progress: dialProgress, lineWidth: 14,
                         tint: resting ? Theme.muted : program.light)
            VStack(spacing: 4) {
                if resting || step.goal.unit == .seconds {
                    Text(clock(remaining))
                        .font(.display(58))
                        .foregroundStyle(resting ? Theme.text : program.light)
                        .monospacedDigit()
                } else {
                    Text("\(value)")
                        .font(.display(66))
                        .foregroundStyle(program.light)
                        .contentTransition(.numericText())
                    Text(step.goal.unit == .meters ? "mètres" : "répétitions")
                        .font(.ui(11, .bold))
                        .kerning(1.6)
                        .foregroundStyle(Theme.muted)
                }
            }
        }
        .frame(width: 236, height: 236)
    }

    @ViewBuilder
    private var controls: some View {
        if resting {
            VStack(spacing: 10) {
                PrimaryButton(title: "PASSER LE REPOS", tint: program.light) { advance() }
                Text("La récupération fait partie de la séance.")
                    .font(.ui(12))
                    .foregroundStyle(Theme.muted)
            }
        } else if step.goal.unit == .seconds {
            VStack(spacing: 10) {
                PrimaryButton(title: "C'EST FAIT", tint: program.light) { validate() }
                Text("Objectif : \(step.goal.short)")
                    .font(.ui(12))
                    .foregroundStyle(Theme.muted)
            }
        } else {
            VStack(spacing: 14) {
                HStack(spacing: 18) {
                    StepButton(systemName: "minus", enabled: value > 0) {
                        value = max(0, value - stepAmount)
                    }
                    Text("objectif \(step.goal.short)")
                        .font(.ui(12, .bold))
                        .foregroundStyle(Theme.muted)
                        .frame(minWidth: 96)
                    StepButton(systemName: "plus") { value += stepAmount }
                }
                PrimaryButton(title: "VALIDER", tint: program.light) { validate() }
            }
        }
    }

    // MARK: - Mécanique

    private var stepAmount: Int { step.goal.unit == .meters ? 100 : 1 }

    private var nextName: String {
        index + 1 < session.steps.count ? session.steps[index + 1].name : "fin de séance"
    }

    private var dialProgress: Double {
        if resting {
            let total = max(1, session.steps[max(0, index)].restSeconds)
            return 1 - Double(remaining) / Double(total)
        }
        if step.goal.unit == .seconds {
            let total = max(1, step.goal.value)
            return 1 - Double(remaining) / Double(total)
        }
        return step.goal.value > 0 ? min(1, Double(value) / Double(step.goal.value)) : 1
    }

    private func prepare(_ position: Int) {
        guard position < session.steps.count else { return }
        let next = session.steps[position]
        value = next.goal.value
        remaining = next.goal.unit == .seconds ? next.goal.value : 0
        resting = false
    }

    private func validate() {
        achieved[step.id] = step.goal.unit == .seconds ? step.goal.value : value
        Haptics.tap()
        if step.restSeconds > 0 && index + 1 < session.steps.count {
            resting = true
            remaining = step.restSeconds
        } else {
            advance()
        }
    }

    private func advance() {
        if index + 1 < session.steps.count {
            index += 1
            prepare(index)
        } else {
            finish()
        }
    }

    private func finish() {
        Haptics.success()
        outcome = store.complete(session: session, achieved: achieved)
    }

    private func tick() {
        guard outcome == nil else { return }
        if resting {
            if remaining > 1 { remaining -= 1 } else { advance() }
        } else if step.goal.unit == .seconds && remaining > 0 {
            remaining -= 1
            if remaining == 0 { validate() }
        }
    }

    private func clock(_ seconds: Int) -> String {
        String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
