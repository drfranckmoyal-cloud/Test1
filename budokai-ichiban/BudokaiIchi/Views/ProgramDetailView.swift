import SwiftUI

struct ProgramDetailView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss
    @State private var showContent = false
    @State private var showLaunch = false
    @State private var justLaunched = false
    @State private var showBoss = false
    @State private var confirmStop = false
    @State private var confirmDelete = false
    let program: Program

    var body: some View {
        ZStack(alignment: .top) {
            Theme.ground.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    programHeader

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
        .confirmationDialog("Quitter \(program.name) ?",
                            isPresented: $confirmStop, titleVisibility: .visible) {
            Button("Mettre en pause") {
                store.pauseProgram(program.id)
                dismiss()
            }
            Button("Supprimer le programme…", role: .destructive) {
                // même précaution : enchaîner deux dialogues sans laisser le
                // premier se refermer fait disparaître le second
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                    confirmDelete = true
                }
            }
            Button("Continuer le programme", role: .cancel) {}
        } message: {
            Text("En pause, rien n'est effacé : il quitte l'accueil mais reste en grisé dans l'onglet Séances, prêt à repartir où tu l'as laissé. Supprimer efface tout ce qu'il a produit.")
        }
        .confirmationDialog("Supprimer \(program.name) ?",
                            isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Tout supprimer", role: .destructive) {
                store.deleteProgram(program.id)
                dismiss()
            }
            Button("Annuler", role: .cancel) {}
        } message: {
            Text(deletionWarning)
        }
        .sheet(isPresented: $showBoss) {
            if let challenge = store.bossChallenge(of: program.id) {
                BossFightView(challenge: challenge)
            }
        }
    }

    /// Ce que la suppression emporte, en chiffres.
    private var deletionWarning: String {
        let impact = store.deletionImpact(program.id)
        var pieces: [String] = []
        if impact.sessions > 0 {
            pieces.append(impact.sessions > 1 ? "\(impact.sessions) séances faites" : "1 séance faite")
        }
        if impact.xp > 0 { pieces.append("\(impact.xp.grouped) XP") }
        if impact.rewards > 0 {
            pieces.append(impact.rewards > 1 ? "\(impact.rewards) vignettes" : "1 vignette")
        }
        guard !pieces.isEmpty else {
            return "\(program.name) n'a encore rien produit : il n'y a rien à perdre. Tes réglages et tes mesures de départ seront effacés."
        }
        let list = pieces.count == 1
            ? pieces[0]
            : pieces.dropLast().joined(separator: ", ") + " et " + pieces[pieces.count - 1]
        return "Tu perds \(list), ainsi que tes mesures de départ et tes caractéristiques gagnées ici. C'est définitif. Pour garder tout ça, mets-le plutôt en pause."
    }

    /// L'en-tête du programme : son illustration du moment, son logo, et
    /// l'étape où l'on se trouve.
    ///
    /// Quand le programme porte ses illustrations, le logo remplace le titre
    /// écrit — il est la signature. Le nom reste un vrai texte pour les
    /// lecteurs d'écran, jamais lu dans l'image.
    private var programHeader: some View {
        let status = store.stageStatus(program)
        let art = ProgramVisuals.stage(program.id, index: status.index)
        let narrative = art != nil
        let height: CGFloat = narrative ? 330 : 192

        return ZStack(alignment: .bottomLeading) {
            program.gradient.frame(height: height)
            if let art = art {
                StageArtwork(name: art, presentation: .hero,
                             label: "\(program.name), \(store.stageName(program))")
                    .frame(height: height)
            } else {
                ArtworkFill(name: program.stageImage(status.index)).frame(height: height)
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
                .frame(height: height, alignment: .top)
            }
            LinearGradient(colors: [.clear, Theme.ground], startPoint: .center, endPoint: .bottom)
                .frame(height: height)

            VStack(alignment: .leading, spacing: narrative ? 10 : 6) {
                if narrative {
                    ProgramLogo(program: program, height: 62)
                } else {
                    Text(program.family.uppercased())
                        .font(.ui(10, .bold))
                        .kerning(2.6)
                        .foregroundStyle(Theme.cream.opacity(0.9))
                    Text(program.name.uppercased())
                        .font(.display(38))
                        .foregroundStyle(Theme.cream)
                }
                if narrative, store.isActive(program.id) || store.isPaused(program.id) {
                    Text(store.stageName(program).uppercased())
                        .font(.display(22))
                        .foregroundStyle(Theme.cream)
                        .shadow(color: .black.opacity(0.55), radius: 8, y: 2)
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Étape \(status.index + 1) sur \(store.shape(of: program.id).stageCount)")
                        .font(.ui(12, .semibold))
                        .foregroundStyle(Theme.cream.opacity(0.9))
                        .shadow(color: .black.opacity(0.6), radius: 6, y: 1)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
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
        } else if store.isPaused(program.id) {
            // un programme en pause se reprend, ou se supprime pour de bon
            VStack(spacing: 8) {
                PrimaryButton(title: "REPRENDRE LE PROGRAMME", tint: program.light) {
                    store.resumeProgram(program.id)
                    dismiss()
                }
                Button {
                    Haptics.tap()
                    confirmDelete = true
                } label: {
                    Text("Supprimer ce programme")
                        .font(.ui(13, .semibold))
                        .foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                }
                .buttonStyle(.plain)
                Text("En pause depuis \(store.progress(program.id).completedSessions) séance\(store.progress(program.id).completedSessions > 1 ? "s" : "") faite\(store.progress(program.id).completedSessions > 1 ? "s" : ""). Rien n'est perdu tant que tu ne supprimes pas.")
                    .font(.ui(11))
                    .foregroundStyle(Theme.dim)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } else if store.isActive(program.id) {
            VStack(spacing: 8) {
                GhostButton(title: "Programme en cours") { dismiss() }
                Button {
                    Haptics.tap()
                    confirmStop = true
                } label: {
                    Text("Mettre en pause ou supprimer")
                        .font(.ui(13, .semibold))
                        .foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                }
                .buttonStyle(.plain)
                Text("En pause, ton avancée est gardée. Supprimer efface tout.")
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
