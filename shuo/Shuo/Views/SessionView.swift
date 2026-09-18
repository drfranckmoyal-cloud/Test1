import SwiftUI

/// L'écran de séance. Il ne fait qu'une chose : créer le chef d'orchestre et
/// le garder en vie. Tout ce qui s'affiche vit dans `SessionContentView`, qui
/// l'observe — un `@State` ne suffirait pas à réveiller la vue à chaque tour
/// de parole.
struct SessionView: View {

    let plan: SessionPlan

    @EnvironmentObject private var store: LearnerStore
    @EnvironmentObject private var voice: VoiceService
    @EnvironmentObject private var telemetry: Telemetry
    @EnvironmentObject private var network: NetworkMonitor

    @State private var runner: SessionRunner?

    var body: some View {
        ZStack {
            Theme.paper.ignoresSafeArea()
            if let runner {
                SessionContentView(runner: runner, plan: plan)
            } else {
                ProgressView().tint(Theme.ink)
            }
        }
        .onAppear(perform: startIfNeeded)
    }

    private func startIfNeeded() {
        guard runner == nil else { return }
        let created = SessionRunner(
            plan: plan,
            store: store,
            voice: voice,
            telemetry: telemetry,
            network: network
        )
        runner = created
        created.start()
    }
}

/// Le contenu de la séance, réveillé à chaque changement du chef d'orchestre.
struct SessionContentView: View {

    @ObservedObject var runner: SessionRunner
    let plan: SessionPlan

    @EnvironmentObject private var store: LearnerStore
    @EnvironmentObject private var telemetry: Telemetry
    @EnvironmentObject private var network: NetworkMonitor
    @Environment(\.dismiss) private var dismiss

    @State private var showQuitConfirm = false

    var body: some View {
        Group {
            if runner.isFinished, let recap = runner.recap {
                RecapView(recap: recap, tutor: runner.tutor) { dismiss() }
            } else {
                running(runner)
            }
        }
        .onChange(of: network.isOnline) { _, online in
            runner.networkChanged(isOnline: online)
        }
        .confirmationDialog(
            "Arrêter la séance ?",
            isPresented: $showQuitConfirm,
            titleVisibility: .visible
        ) {
            Button("Mettre en pause et sortir") {
                runner.suspend()
                dismiss()
            }
            Button("Terminer maintenant") {
                runner.finish()
            }
            Button("Continuer", role: .cancel) {}
        } message: {
            Text("Une séance mise en pause se reprend depuis l'accueil.")
        }
    }

    // MARK: - Séance en cours

    private func running(_ runner: SessionRunner) -> some View {
        VStack(spacing: 0) {
            header(runner)

            ScrollView {
                VStack(spacing: 16) {
                    if runner.isPausedForNetwork {
                        networkPause
                    }

                    if let phase = runner.currentPhase {
                        if let item = runner.currentItem, phase.kind == .newItem || phase.kind == .recall {
                            WordCardView(item: item, status: store.status(item.officialKey))
                        } else {
                            PhaseCardView(
                                phase: phase,
                                items: ContentLibrary.shared.items(ids: phase.itemIDs)
                            )
                        }
                    }

                    tutorSpeech(runner)

                    if !runner.learnerSaid.isEmpty {
                        learnerSpeech(runner)
                    }

                    if runner.helpLevel != .none {
                        Text("Aide en cours : \(runner.helpLevel.label)")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.orange)
                    }
                }
                .padding(20)
            }

            VoiceControls(runner: runner)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
        }
    }

    private func header(_ runner: SessionRunner) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                Button {
                    showQuitConfirm = true
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.inkSoft)
                }

                TutorAvatar(tutor: runner.tutor, size: 32)

                VStack(alignment: .leading, spacing: 1) {
                    Text(runner.currentPhase?.kind.label ?? "Séance")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.ink)
                    Text("\(plan.durationMinutes) min · \(plan.mode.label.lowercased())")
                        .font(Theme.mono)
                        .foregroundStyle(Theme.inkSoft)
                }

                Spacer()

                ModelBadge(
                    model: telemetry.activeModel,
                    justSwitched: telemetry.modelJustSwitched,
                    isLocal: Keychain.anthropicAPIKey == nil || !network.isOnline
                )
            }

            ProgressView(value: runner.progress)
                .tint(Theme.seal)
                .scaleEffect(x: 1, y: 0.6, anchor: .center)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .background(Theme.paper)
    }

    private func tutorSpeech(_ runner: SessionRunner) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if runner.isThinking, let transition = runner.transition {
                // Une courte phrase en mandarin plutôt qu'un silence : le
                // tuteur ne disparaît pas pendant qu'il réfléchit.
                HStack(spacing: 8) {
                    Text(transition)
                        .font(Theme.hanzi(18))
                        .foregroundStyle(Theme.inkSoft)
                    ProgressView().scaleEffect(0.6).tint(Theme.inkSoft)
                }
            }
            if !runner.tutorMandarin.isEmpty {
                Text(runner.tutorMandarin)
                    .font(Theme.hanzi(24))
                    .foregroundStyle(Theme.ink)
            }
            if !runner.tutorFrench.isEmpty {
                Text(runner.tutorFrench)
                    .font(Theme.body)
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 2)
    }

    private func learnerSpeech(_ runner: SessionRunner) -> some View {
        Text(runner.learnerSaid)
            .font(Theme.body)
            .foregroundStyle(Theme.ink)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Theme.seal.opacity(0.10))
            )
    }

    private var networkPause: some View {
        HStack(spacing: 10) {
            Image(systemName: "wifi.slash")
            Text("Réseau perdu. La séance reprend toute seule.")
                .font(Theme.caption)
        }
        .foregroundStyle(Theme.orange)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.orange.opacity(0.12))
        )
    }

}

/// Les commandes de voix, toujours à portée de pouce.
///
/// Le passage mains libres ↔ appui pour parler se fait ici, en pleine séance,
/// sans rien perdre de l'état (A10).
struct VoiceControls: View {

    @ObservedObject var runner: SessionRunner
    @EnvironmentObject private var voice: VoiceService
    @State private var pressing = false

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ForEach(VoiceMode.allCases) { mode in
                    Button {
                        voice.mode = mode
                    } label: {
                        Label(mode.label, systemImage: mode.systemImage)
                            .font(Theme.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(voice.mode == mode ? Theme.seal.opacity(0.16) : Color.clear)
                            )
                            .overlay(
                                Capsule().stroke(
                                    voice.mode == mode ? Theme.seal : Theme.hairline,
                                    lineWidth: 1
                                )
                            )
                            .foregroundStyle(voice.mode == mode ? Theme.seal : Theme.inkSoft)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Button {
                    runner.skipPhase()
                } label: {
                    Image(systemName: "forward.end")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.inkSoft)
                }
                .accessibilityLabel("Passer cette étape")
            }

            if voice.mode == .pushToTalk {
                pushToTalkButton
            } else {
                handsFreeIndicator
            }

            HelpCommandsBar()
        }
    }

    private var pushToTalkButton: some View {
        Text(pressing ? "Parle…" : "Appuie pour parler")
            .font(Theme.body.weight(.semibold))
            .foregroundStyle(pressing ? Color.white : Theme.ink)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(pressing ? Theme.seal : Theme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Theme.hairline, lineWidth: 1)
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !pressing else { return }
                        pressing = true
                        voice.beginPushToTalk()
                    }
                    .onEnded { _ in
                        pressing = false
                        voice.endPushToTalk()
                    }
            )
    }

    private var handsFreeIndicator: some View {
        HStack(spacing: 12) {
            InputWave(level: voice.inputLevel, active: voice.activity == .listening)
            Text(indicatorLabel)
                .font(Theme.caption)
                .foregroundStyle(Theme.inkSoft)
            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Theme.hairline, lineWidth: 1)
        )
    }

    private var indicatorLabel: String {
        switch voice.activity {
        case .speaking: return "Le tuteur parle — parle pour l'interrompre"
        case .listening: return "Je t'écoute"
        case .paused: return "En pause"
        case .idle: return "À toi quand tu veux"
        }
    }
}

/// Les trois mots à dire quand ça coince. Affichés, parce qu'on les oublie
/// exactement au moment où on en a besoin.
struct HelpCommandsBar: View {
    var body: some View {
        HStack(spacing: 14) {
            ForEach(HelpCommand.allCases, id: \.self) { command in
                Text("« \(command.label) »")
                    .font(Theme.mono)
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
        }
    }
}
