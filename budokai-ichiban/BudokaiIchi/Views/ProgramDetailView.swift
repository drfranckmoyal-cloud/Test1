import SwiftUI

struct ProgramDetailView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    @State private var showContent = false
    @State private var showScheduling = false
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
                            fact("\(program.totalSessions) séances")
                        }

                        Text(program.pitch)
                            .font(.ui(14))
                            .foregroundStyle(Theme.muted)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack {
                            SectionLabel(text: "LES \(program.stages.count) ÉTAPES")
                            Button {
                                Haptics.tap()
                                showContent = true
                            } label: {
                                Text("TOUT LE CONTENU")
                                    .font(.ui(10, .bold))
                                    .kerning(1.2)
                                    .foregroundStyle(program.light)
                            }
                            .buttonStyle(.plain)
                        }

                        VStack(spacing: 7) {
                            ForEach(program.stages.indices, id: \.self) { index in
                                stageRow(index)
                            }
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
        .sheet(isPresented: $showScheduling) {
            SchedulingSetupView(program: program) {
                store.startProgram(program.id)
                dismiss()
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

    private var suiviLabel: String {
        let names = store.activePrograms.map(\.name)
        return names.count == 1 ? names[0] : "tes \(names.count) programmes"
    }

    private func stageRow(_ index: Int) -> some View {
        let status = store.stageStatus(program)
        let isActive = store.isActive(program.id) && index == status.index
        let isDone = store.progress(program.id).completedSessions >= program.firstSession(ofStage: index + 1)

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
            Text(program.stages[index])
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
                    store.stopProgram(program.id)
                    dismiss()
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
                    if store.needsScheduling(program.id) {
                        showScheduling = true
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
