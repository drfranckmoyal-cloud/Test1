import SwiftUI

struct ProgramDetailView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    @State private var showContent = false
    @State private var showLaunch = false
    @State private var justLaunched = false
    @State private var showBoss = false
    @State private var confirmStop = false
    let program: Program

    var body: some View {
        ZStack(alignment: .top) {
            Theme.ground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ZStack(alignment: .bottomLeading) {
                        program.gradient.frame(height: 192)
                        ArtworkFill(name: program.stageImage(store.stageStatus(program).index))
                            .frame(height: 192)
                        // le logo de l'univers, en filigrane dans le coin
                        HStack {
                            Spacer()
                            Image(program.logoImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 92)
                                .opacity(0.5)
                                .blendMode(.screen)
                                .padding(.trailing, 16)
                                .padding(.top, 14)
                        }
                        .frame(height: 192, alignment: .top)
                        LinearGradient(colors: [.clear, Theme.ground], startPoint: .center, endPoint: .bottom)
                            .frame(height: 192)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(program.family.uppercased())
                                .font(.ui(10, .bold))
                                .kerning(2.6)
                                .foregroundStyle(Theme.cream.opacity(0.9))
                            Text(program.name.uppercased())
                                .font(.display(38))
                                .foregroundStyle(Theme.cream)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    }

                    VStack(alignment: .leading, spacing: 18) {
                        HStack(spacing: 16) {
                            fact(program.rhythm)
                            fact(program.equipment)
                            fact("\(store.shape(of: program.id).totalSessions) séances")
                        }

                        Text(program.pitch)
                            .font(.ui(14))
                            .foregroundStyle(Theme.muted)
                            .fixedSize(horizontal: false, vertical: true)

                        SectionLabel(text: "LES \(store.shape(of: program.id).stageCount) ÉTAPES")

                        // l'accès au contenu complet était une mention en
                        // petit à côté du titre : personne ne la voyait
                        Button {
                            Haptics.tap()
                            showContent = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "list.bullet.rectangle")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(program.light)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Voir le détail du programme")
                                        .font(.ui(14, .bold))
                                        .foregroundStyle(Theme.text)
                                    Text("Toutes les séances, étape par étape.")
                                        .font(.ui(11))
                                        .foregroundStyle(Theme.muted)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(Theme.dim)
                            }
                            .padding(15)
                            .frame(maxWidth: .infinity)
                            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(program.light.opacity(0.45), lineWidth: 1))
                        }
                        .buttonStyle(.plain)

                        VStack(spacing: 7) {
                            ForEach(store.shape(of: program.id).stageTitles.indices, id: \.self) { index in
                                stageRow(index)
                            }
                        }

                        if store.isActive(program.id), store.bossChallenge(of: program.id) != nil {
                            bossEntry
                        }
                        action
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .padding(.bottom, 34)
                }
            }
            .scrollIndicators(.hidden)

            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.cream)
                        .frame(width: 44, height: 44)
                        .background(Color.black.opacity(0.32), in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
        }
        .sheet(isPresented: $showContent) {
            ProgramContentView(program: program)
        }
        .sheet(isPresented: $showLaunch) {
            ProgramLaunchView(program: program) {
                store.startProgram(program.id)
                justLaunched = true
            }
        }
        .onChange(of: showLaunch) { _, presented in
            guard !presented, justLaunched else { return }
            justLaunched = false
            dismiss()
        }
        .confirmationDialog("Ne plus suivre \(program.name) ?",
                            isPresented: $confirmStop, titleVisibility: .visible) {
            Button("Ne plus suivre", role: .destructive) {
                store.stopProgram(program.id)
                dismiss()
            }
            Button("Continuer le programme", role: .cancel) {}
        } message: {
            Text("Rien n'est effacé : tes séances faites, ton expérience et tes caractéristiques restent. Le programme sort juste de tes suivis, et tu pourras le reprendre là où tu l'as laissé.")
        }
        .sheet(isPresented: $showBoss) {
            if let challenge = store.bossChallenge(of: program.id) {
                BossFightView(challenge: challenge)
            }
        }
    }

    private func fact(_ text: String) -> some View {
        Text(text)
            .font(.ui(12, .semibold))
            .foregroundStyle(Theme.muted)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
    }

    /// L'entrée vers le combat final. Visible dès que le programme tourne :
    /// verrouillée, elle dit ce qu'il reste à tenir.
    private var bossEntry: some View {
        let eligible = store.bossIsOpen(program.id)
        let missing = store.bossMissing(program.id)
        let won = store.progress(program.id).bossDefeated
        return Button {
            Haptics.tap()
            showBoss = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: won ? "crown.fill" : (eligible ? "flame.fill" : "lock.fill"))
                    .font(.system(size: 17))
                    .foregroundStyle(eligible ? Theme.gold : Theme.muted)
                VStack(alignment: .leading, spacing: 2) {
                    Text("COMBAT FINAL")
                        .font(.display(15))
                        .foregroundStyle(Theme.text)
                    Text(won
                         ? "Gagné. \(ProgramStructures.superRankName(for: program.id) ?? "Le mode supérieur") est ouvert."
                         : (eligible
                            ? (ProgramLibrary.bossSummary(program.id) ?? "Le standard qui valide le programme.")
                            : (missing.count == 1
                               ? "Il te reste un prérequis à tenir."
                               : "Il te reste \(missing.count) prérequis à tenir.")))
                        .font(.ui(11, .semibold))
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.dim)
            }
            .padding(15)
            .frame(maxWidth: .infinity)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(eligible || won ? Theme.gold.opacity(0.55) : Theme.border,
                        lineWidth: eligible || won ? 2 : 1))
        }
        .buttonStyle(.plain)
    }

    private var suiviLabel: String {
        let names = store.activePrograms.map(\.name)
        return names.count == 1 ? names[0] : "tes \(names.count) programmes"
    }

    private func stageRow(_ index: Int) -> some View {
        let status = store.stageStatus(program)
        let isActive = store.isActive(program.id) && index == status.index
        let isDone = store.progress(program.id).completedSessions
            >= store.shape(of: program.id).firstSession(ofStage: index + 1)

        return HStack(spacing: 13) {
            ZStack {
                Circle()
                    .fill(isDone ? program.light : (isActive ? program.light.opacity(0.25) : Theme.surfaceAlt))
                    .frame(width: 30, height: 30)
                if isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .black))
                        .foregroundStyle(Theme.ink)
                } else {
                    Text("\(index + 1)")
                        .font(.display(13))
                        .foregroundStyle(isActive ? program.light : Theme.dim)
                }
            }
            Text(store.shape(of: program.id).title(ofStage: index))
                .font(.ui(14, isActive ? .bold : .semibold))
                .foregroundStyle(isDone || isActive ? Theme.text : Theme.muted)
            Spacer(minLength: 6)
            if isActive {
                Text("\(status.done) / \(status.total)")
                    .font(.ui(12, .bold))
                    .foregroundStyle(program.light)
            }
        }
        .padding(.horizontal, 14)
        .frame(height: isActive ? 58 : 48)
        .background(isActive ? program.light.opacity(0.10) : Theme.surface,
                    in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous)
            .stroke(isActive ? program.light.opacity(0.5) : Theme.border, lineWidth: isActive ? 1.5 : 1))
    }

    @ViewBuilder
    private var action: some View {
        if !store.isUnlocked(program) {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                    Text(program.unlock.label)
                }
                .font(.ui(14, .bold))
                .foregroundStyle(Theme.muted)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                Text("Continue à progresser : ce programme s'ouvrira de lui-même.")
                    .font(.ui(12))
                    .foregroundStyle(Theme.muted)
            }
        } else if !program.playable {
            VStack(spacing: 8) {
                Text("CONTENU À VENIR")
                    .font(.display(15))
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                Text("Les séances de ce programme ne sont pas encore écrites.")
                    .font(.ui(12))
                    .foregroundStyle(Theme.muted)
            }
        } else if store.isActive(program.id) {
            VStack(spacing: 8) {
                GhostButton(title: "Programme en cours") { dismiss() }
                Button {
                    Haptics.tap()
                    confirmStop = true
                } label: {
                    Text("Ne plus suivre")
                        .font(.ui(13, .semibold))
                        .foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                }
                .buttonStyle(.plain)
                Text("Ton avancée est gardée : tu peux le reprendre où tu l'as laissé.")
                    .font(.ui(11))
                    .foregroundStyle(Theme.dim)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } else {
            VStack(spacing: 8) {
                PrimaryButton(title: store.progress(program.id).completedSessions > 0 ? "REPRENDRE" : "COMMENCER",
                              tint: program.light) {
                    // le planning se règle avant de démarrer, quand le
                    // programme sait le construire
                    // le parcours de lancement pose les questions une à une
                    if store.needsScheduling(program.id)
                        || (program.id == .saitama && store.saitamaNeedsCalibration) {
                        showLaunch = true
                    } else {
                        store.startProgram(program.id)
                        dismiss()
                    }
                }
                if !store.activePrograms.isEmpty {
                    Text("Il s'ajoutera à \(suiviLabel) — les programmes avancent en parallèle.")
                        .font(.ui(11))
                        .foregroundStyle(Theme.dim)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
