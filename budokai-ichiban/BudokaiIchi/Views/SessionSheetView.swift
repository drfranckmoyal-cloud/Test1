import SwiftUI

/// La fiche d'entraînement du jour : tout le contenu de la séance, lisible
/// d'un coup d'œil, à garder ouverte pendant l'effort.
///
/// C'est le chemin normal. Le guidage minuté reste possible pour les séances
/// en salle, mais il n'est plus obligatoire : personne ne va sortir courir en
/// suivant son téléphone minute par minute.
struct SessionSheetView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    let session: PlannedSession

    private enum Step { case card, feedback, abandon, outcome }
    /// Vrai quand le guidage a déjà enregistré la séance : le ressenti ne
    /// doit alors rien enregistrer de plus.
    @State private var alreadyRecorded = false
    @State private var step: Step = .card
    @State private var outcome: SessionOutcome?
    @State private var report = SessionReport()
    /// Pourquoi la séance s'arrête, le temps de le demander.
    @State private var abandonReason: AbandonReason?
    /// Les exercices obligatoires que le pratiquant n'a pas réussis.
    @State private var failed: Set<String> = []
    /// De combien alléger la suite : le moteur propose, le pratiquant règle.
    @State private var dose: AdaptationEngine.Dose = .asProposed
    /// Le héros qui intervient, avant la séance ou après elle.
    @State private var hero: HeroPopupAsset?
    /// Ce qu'on fait une fois le héros parti : ouvrir la séance, ou passer au
    /// bilan. Le popup ne décide de rien, il ne fait que retarder.
    @State private var afterHero: () -> Void = {}
    /// La séance n'est ouverte qu'une fois le héros parti : tant qu'il parle,
    /// rien n'est enregistré.
    @State private var started = false
    /// Le récit de la séance est replié par défaut : il ne doit plus repousser
    /// les exercices hors de l'écran.
    @State private var storyOpen = false
    /// Vrai le temps de choisir une autre séance de la semaine.
    @State private var swapping = false

    private var program: Program { Catalog.program(session.programID) }
    /// La séance telle qu'elle sera faite, curseur d'intensité compris.
    /// La séance telle qu'elle sera faite.
    ///
    /// Une séance prescrite porte déjà son dosage : on la prend telle quelle.
    /// Seuls les anciens programmes, qui n'expriment qu'un volume, se
    /// recalculent avec le curseur d'intensité.
    private var tuned: PlannedSession {
        if session.prescribed != nil { return session }
        return Catalog.session(for: session.programID, index: session.index - 1,
                               tier: store.state.tier,
                               intensity: store.intensity(session.programID)) ?? session
    }

    var body: some View {
        ZStack {
            Theme.ground.ignoresSafeArea()
            switch step {
            case .card: card
            case .feedback: feedbackScreen
            case .abandon: abandonScreen
            case .outcome:
                if let outcome = outcome {
                    OutcomeView(outcome: outcome, closing: narrative?.closingMessage) { dismiss() }
                }
            }
        }
        .heroPopup($hero) { afterHero(); afterHero = {} }
        .onAppear {
            guard !started else { return }
            // le héros d'abord, la séance ensuite : rien ne s'enregistre
            // pendant qu'il parle
            if let asset = store.heroPopup(for: session.programID) {
                store.rememberHeroPopup(asset)
                afterHero = begin
                hero = asset
            } else {
                begin()
            }
        }
    }

    /// Ouvre réellement la séance.
    ///
    /// Toujours appeler `beginSession` : elle retrouve la séance du jour si
    /// elle correspond, et la reconstruit sinon. Ne l'appeler qu'en l'absence
    /// de séance ouverte laissait une séance périmée en place — et sans
    /// compteurs, aucune case à cocher n'apparaît.
    private func begin() {
        guard !started else { return }
        started = true
        store.beginSession(tuned)
        // le visuel de fin est choisi et décodé pendant la séance : au moment
        // de valider, il est déjà prêt
        store.prepareHeroPopup(for: session.programID, phase: .sessionComplete)
    }

    // MARK: - La fiche

    private var card: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 18) {
                    if let note = engineNote { engineCard(note) }
                    // le travail du jour d'abord : c'est pour lui qu'on ouvre
                    // la séance, il ne doit pas se mériter par un défilement
                    exercises
                    swapRow
                    if let story = narrative {
                        narrativeCard(story)
                        narrativeBody(story)
                    }
                    if tuned.prescribed == nil { intensityDial }
                    if !program.equipment.isEmpty && program.equipment != "Aucun" {
                        note("Matériel : \(program.equipment)")
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            actions
        }
    }

    private var header: some View {
        ZStack(alignment: .bottomLeading) {
            program.gradient
            ArtworkFill(name: program.environmentImage).opacity(0.42)
            LinearGradient(colors: [Color.black.opacity(0.25), Color.black.opacity(0.72)],
                           startPoint: .top, endPoint: .bottom)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text((narrative?.arc ?? program.name).uppercased())
                        .font(.ui(10, .bold))
                        .kerning(2.4)
                        .foregroundStyle(Theme.cream.opacity(0.85))
                    Text(session.title)
                        .font(.display(22))
                        .foregroundStyle(Theme.cream)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(positionLabel)
                        .font(.ui(11, .semibold))
                        .foregroundStyle(Theme.cream.opacity(0.85))
                }
                Spacer(minLength: 8)
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.cream)
                        .frame(width: 36, height: 36)
                        .background(Color.black.opacity(0.32), in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 13)
            .padding(.top, 52)
        }
        .frame(height: 148)
        .ignoresSafeArea(edges: .top)
    }

    /// Le récit de la séance, quand il existe et que le réglage de spoilers
    /// l'autorise.
    private var narrative: NarrativeContent? {
        let index = store.progress(session.programID).completedSessions
        guard let content = NarrativeCatalog.content(program: session.programID,
                                                     sessionIndex: index),
              content.isVisible(at: store.state.spoilerLevel) else { return nil }
        return content
    }

    /// Le récit de la séance, replié.
    ///
    /// Il occupait un grand cadre en tête de page et repoussait les exercices
    /// sous la ligne de flottaison. Il est maintenant sous eux, et fermé : une
    /// ligne qu'on ouvre si on veut lire, pas un passage obligé.
    private func narrativeCard(_ story: NarrativeContent) -> some View {
        Button {
            Haptics.tap()
            withAnimation(.easeInOut(duration: 0.22)) { storyOpen.toggle() }
        } label: {
            HStack(spacing: 11) {
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(program.light)
                VStack(alignment: .leading, spacing: 1) {
                    Text(story.arc.uppercased())
                        .font(.ui(9, .bold))
                        .kerning(1.8)
                        .foregroundStyle(Theme.dim)
                    Text(story.narrativeTitle)
                        .font(.ui(14, .bold))
                        .foregroundStyle(Theme.text)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 6)
                Image(systemName: storyOpen ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Theme.dim)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.border, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            if storyOpen { EmptyView() }
        }
    }

    /// Le récit déplié, sous la ligne.
    @ViewBuilder
    private func narrativeBody(_ story: NarrativeContent) -> some View {
        if storyOpen { legacyNarrativeCard(story) }
    }

    private func legacyNarrativeCard(_ story: NarrativeContent) -> some View {
        let stage = store.saitamaBlock.map { $0.index - 1 } ?? 0

        return VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                program.gradient
                ArtworkFill(name: program.stageImage(stage))
                LinearGradient(colors: [Color.black.opacity(0.10), Color.black.opacity(0.80)],
                               startPoint: .center, endPoint: .bottom)
                Text(story.arc.uppercased())
                    .font(.ui(9, .bold))
                    .kerning(2.2)
                    .foregroundStyle(Theme.cream.opacity(0.9))
                    .padding(.horizontal, 18)
                    .padding(.bottom, 12)
            }
            .frame(height: 130)

            VStack(alignment: .leading, spacing: 11) {
                Text(story.narrativeTitle)
                    .font(.display(20))
                    .foregroundStyle(Theme.text)
                    .fixedSize(horizontal: false, vertical: true)

                Text(story.storyRecap)
                    .font(.system(size: 15, weight: .regular, design: .serif))
                    .lineSpacing(3)
                    .foregroundStyle(Theme.text.opacity(0.88))
                    .fixedSize(horizontal: false, vertical: true)

                if let opening = story.openingMessage, opening != story.senseiMessage {
                    Text(opening)
                        .font(.ui(13, .semibold))
                        .foregroundStyle(program.light)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }

                if !(story.references ?? []).isEmpty {
                    HStack(spacing: 6) {
                        ForEach(story.references, id: \.self) { reference in
                            Text(reference)
                                .font(.ui(10, .semibold))
                                .foregroundStyle(Theme.muted)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Theme.surfaceAlt, in: Capsule())
                        }
                    }
                    .padding(.top, 2)
                }

                if let sensei = story.senseiMessage {
                    HStack(alignment: .top, spacing: 10) {
                        Rectangle().fill(program.light).frame(width: 2)
                        Text(sensei)
                            .font(.system(size: 13, weight: .regular, design: .serif))
                            .italic()
                            .foregroundStyle(Theme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 3)
                }
            }
            .padding(18)
        }
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.border, lineWidth: 1))
    }

    /// Où se situe cette séance dans le parcours.
    private var positionLabel: String {
        if session.programID == .saitama, let block = store.saitamaBlock {
            return "\(session.title) · jalon \(block.index) sur 8 · \(tuned.estimatedMinutes) min"
        }
        return "Séance \(session.index) sur \(store.shape(of: session.programID).totalSessions) · environ \(tuned.estimatedMinutes) min"
    }

    /// Ce que le moteur a décidé, dit en clair. Le cadrage veut que le
    /// pratiquant voie **pourquoi** l'exercice change, jamais les
    /// coefficients qui le décident.
    /// Ce que le moteur a décidé à partir de ton dernier retour.
    ///
    /// Sans cette carte, dire « très difficile » ne se voyait nulle part : la
    /// séance suivante était plus légère sans que rien ne l'explique. Elle
    /// vaut pour les neuf programmes, pas seulement pour Saitama.
    private var engineNote: (icon: String, title: String, body: String)? {
        let id = session.programID
        guard store.progress(id).completedSessions > 0 else { return nil }

        if id == .saitama, let consolidation = store.saitamaConsolidation {
            let names = consolidation.domains.map { $0.label.lowercased() }.joined(separator: " et ")
            return ("arrow.triangle.2.circlepath",
                    "Microcycle de consolidation",
                    "Le jalon n'est pas encore tenu sur \(names). \(consolidation.remaining) séance\(consolidation.remaining > 1 ? "s" : "") ciblée\(consolidation.remaining > 1 ? "s" : "") avant de le rejuger. Rien n'est perdu, l'histoire continue.")
        }
        if tuned.title.contains("décharge") {
            return ("moon.zzz.fill", "Semaine allégée",
                    "Volume réduit exprès. C'est pendant ces semaines que l'adaptation se fait.")
        }
        if let move = store.lastMove(of: id), move != .hold {
            return (move.isProgression ? "arrow.up.right" : "arrow.down.right",
                    move.label, move.explanation)
        }
        return nil
    }

    private func engineCard(_ note: (icon: String, title: String, body: String)) -> some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: note.icon)
                .font(.system(size: 15))
                .foregroundStyle(program.light)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 3) {
                Text(note.title)
                    .font(.ui(13, .bold))
                    .foregroundStyle(Theme.text)
                Text(note.body)
                    .font(.ui(12))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(15)
        .frame(maxWidth: .infinity)
        .background(program.light.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(program.light.opacity(0.32), lineWidth: 1))
    }

    // MARK: - Le curseur d'intensité

    private var intensityDial: some View {
        let value = store.intensity(session.programID)
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionLabel(text: "INTENSITÉ")
                Text(percentLabel(value))
                    .font(.ui(13, .bold))
                    .foregroundStyle(value == 1 ? Theme.muted : program.light)
            }

            HStack(spacing: 12) {
                dialButton(systemName: "minus", enabled: value > 0.5) {
                    store.setIntensity(value - 0.05, for: session.programID)
                }
                ProgressBar(value: (value - 0.5) / 2.0, height: 8, tint: program.light)
                dialButton(systemName: "plus", enabled: value < 2.5) {
                    store.setIntensity(value + 0.05, for: session.programID)
                }
            }

            Text("À lire avant de commencer : si la séance te paraît déjà inutile ou hors de portée, ajuste-la ici. Elle se règle aussi toute seule, d'après ce que tu répondras en fin de séance.")
                .font(.ui(11))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.border, lineWidth: 1))
    }

    private func dialButton(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            guard enabled else { return }
            Haptics.tap()
            action()
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(enabled ? Theme.text : Theme.dim)
                .frame(width: 42, height: 42)
                .background(Theme.surfaceAlt, in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    private func percentLabel(_ value: Double) -> String {
        let percent = Int((value * 100).rounded())
        if percent == 100 { return "Comme prévu" }
        return percent > 100 ? "+\(percent - 100) %" : "−\(100 - percent) %"
    }

    // MARK: - Le contenu de la séance

    private var exercises: some View {
        let open = store.openSession(of: session.programID)
        let all = tuned.prescriptions
        let required = all.filter(\.isRequired)
        let warmup = all.filter { $0.isWarmup }
        let extras = all.filter { !$0.isRequired && !$0.isWarmup }

        return VStack(alignment: .leading, spacing: 22) {
            if !warmup.isEmpty {
                group("ÉCHAUFFEMENT", warmup, open: open, compact: true)
            }
            VStack(alignment: .leading, spacing: 10) {
                if let open = open {
                    let ratio = open.ratio(against: all)
                    HStack {
                        Text("LE TRAVAIL DU JOUR")
                            .font(.ui(12, .bold))
                            .kerning(2.2)
                            .foregroundStyle(program.light)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(required.filter { open.objectives[$0.id]?.status.isDone ?? false }.count) / \(required.count)")
                            .font(.ui(12, .bold))
                            .foregroundStyle(program.light)
                    }
                    ProgressBar(value: ratio, height: 6, tint: program.light)
                } else {
                    Text("LE TRAVAIL DU JOUR")
                        .font(.ui(12, .bold))
                        .kerning(2.2)
                        .foregroundStyle(program.light)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                ForEach(required) { item in card(item, open: open, compact: false) }
            }
            if !extras.isEmpty {
                group("EN COMPLÉMENT", extras, open: open, compact: true)
            }
        }
    }

    private func group(_ title: String, _ items: [ExercisePrescription],
                       open: OpenSession?, compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: title)
            ForEach(items) { item in card(item, open: open, compact: compact) }
        }
    }

    @ViewBuilder
    private func card(_ item: ExercisePrescription, open: OpenSession?, compact: Bool) -> some View {
        if let progress = open?.objectives[item.id] {
            DailyProgressObjective(
                prescription: item, progress: progress, tint: program.light,
                onAdd: { store.addProgress($0, to: item.id, of: session.programID) },
                onDeclareComplete: { store.declareComplete(item.id, of: session.programID) },
                onRemoveEntry: { store.removeProgress($0, from: item.id, of: session.programID) },
                onEditEntry: { store.updateProgress($0, to: $1, in: item.id, of: session.programID) },
                onUncheck: { store.resetObjective(item.id, of: session.programID) },
                compact: compact)
        } else {
            staticRow(item)
        }
    }

    /// La ligne simple, avant que la séance ne soit ouverte.
    private func staticRow(_ item: ExercisePrescription) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.ui(15, .bold))
                    .foregroundStyle(Theme.text)
                if let intensity = item.intensityLabel {
                    Text(intensity)
                        .font(.ui(11, .bold))
                        .foregroundStyle(program.light)
                }
                if let detail = item.detail {
                    Text(detail)
                        .font(.ui(12))
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            Text(item.amountLabel)
                .font(.ui(15, .bold))
                .foregroundStyle(program.light)
                .multilineTextAlignment(.trailing)
        }
        .padding(14)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.border, lineWidth: 1))
    }

    private func row(_ line: Line, number: Int) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.display(14))
                .foregroundStyle(program.light)
                .frame(width: 26, height: 26)
                .background(program.light.opacity(0.14), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(line.name)
                    .font(.ui(15, .bold))
                    .foregroundStyle(Theme.text)
                if !line.detail.isEmpty {
                    Text(line.detail)
                        .font(.ui(12))
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 8)

            Text(line.amount)
                .font(.ui(15, .bold))
                .foregroundStyle(program.light)
                .multilineTextAlignment(.trailing)
        }
        .padding(14)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Theme.border, lineWidth: 1))
    }

    private func note(_ text: String) -> some View {
        Text(text)
            .font(.ui(12, .semibold))
            .foregroundStyle(Theme.muted)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Changer de séance

    /// De quoi prendre une autre séance de la semaine à la place de celle-ci.
    ///
    /// Un jour où la séance prévue ne tombe pas bien, mieux vaut en faire une
    /// autre que rien. Le programme n'avance pas plus vite : c'est un échange
    /// dans la semaine, pas un raccourci.
    @ViewBuilder
    private var swapRow: some View {
        let others = store.alternativeSessions(of: session.programID)
        if !others.isEmpty {
            VStack(spacing: 8) {
                Button {
                    Haptics.tap()
                    withAnimation(.easeInOut(duration: 0.2)) { swapping.toggle() }
                } label: {
                    HStack(spacing: 9) {
                        Image(systemName: "arrow.triangle.swap")
                            .font(.system(size: 12, weight: .bold))
                        Text(store.hasSwappedToday(session.programID)
                             ? "Changer encore de séance"
                             : "Faire une autre séance de la semaine")
                            .font(.ui(13, .semibold))
                        Spacer(minLength: 0)
                        Image(systemName: swapping ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(Theme.muted)
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .frame(maxWidth: .infinity)
                    .background(Theme.surfaceAlt, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if swapping {
                    VStack(spacing: 7) {
                        ForEach(others, id: \.slot) { other in
                            swapChoice(other)
                        }
                        if store.hasSwappedToday(session.programID) {
                            Button {
                                Haptics.tap()
                                store.restoreTodaySession(of: session.programID)
                                swapping = false
                                started = false
                                begin()
                            } label: {
                                Text("Revenir à la séance prévue")
                                    .font(.ui(12, .bold))
                                    .foregroundStyle(program.light)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 38)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .transition(.opacity)
                }
            }
        }
    }

    private func swapChoice(_ other: (slot: Int, title: String, minutes: Int)) -> some View {
        Button {
            Haptics.tap()
            store.swapTodaySession(of: session.programID, to: other.slot)
            swapping = false
            started = false
            begin()
        } label: {
            HStack(spacing: 11) {
                Image(systemName: "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.dim)
                VStack(alignment: .leading, spacing: 1) {
                    Text(other.title)
                        .font(.ui(14, .semibold))
                        .foregroundStyle(Theme.text)
                        .multilineTextAlignment(.leading)
                    Text("environ \(other.minutes) min")
                        .font(.ui(11, .semibold))
                        .foregroundStyle(Theme.muted)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Les boutons du bas

    /// Tout le travail principal est-il coché ?
    private var requiredDone: Bool {
        guard let open = store.openSession(of: session.programID) else { return false }
        let required = tuned.prescriptions.filter(\.isRequired)
        guard !required.isEmpty else { return true }
        return required.allSatisfy { open.objectives[$0.id]?.status.isDone ?? false }
    }

    private var actions: some View {
        VStack(spacing: 7) {
            PrimaryButton(title: "SÉANCE TERMINÉE", tint: program.light, enabled: requiredDone) {
                step = .feedback
            }
            Button {
                Haptics.tap()
                withAnimation(.easeInOut(duration: 0.2)) { step = .abandon }
            } label: {
                Text("Abandonner la séance")
                    .font(.ui(13, .semibold))
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(
            Theme.groundDeep
                .overlay(Rectangle().frame(height: 1).foregroundStyle(Theme.border), alignment: .top)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Le ressenti

    // MARK: - Séance arrêtée en cours

    /// Pourquoi on s'arrête, et ce qui a bloqué.
    ///
    /// Une séance abandonnée ne compte pas : elle reste à faire. La distinction
    /// entre « j'ai dû arrêter » et « c'était trop dur » n'est pas cosmétique —
    /// seule la seconde allège la prochaine tentative.
    private var abandonScreen: some View {
        let required = blockingCandidates
        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ON S'ARRÊTE LÀ")
                        .font(.display(26))
                        .foregroundStyle(Theme.text)
                    Text("La séance ne comptera pas et restera à faire. Dis-moi juste pourquoi.")
                        .font(.ui(14))
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 34)

                VStack(spacing: 9) {
                    ForEach(AbandonReason.allCases) { candidate in
                        reasonRow(candidate)
                    }
                }

                // ce qui a bloqué : seulement le travail principal, et
                // seulement quand c'est la difficulté qui a eu raison
                if abandonReason == .tooHard, !required.isEmpty {
                    VStack(alignment: .leading, spacing: 9) {
                        SectionLabel(text: "QU'EST-CE QUI N'EST PAS PASSÉ ?")
                        Text("Coche ce que tu n'as pas réussi à faire. Ces mouvements-là redescendront d'un cran.")
                            .font(.ui(12))
                            .foregroundStyle(Theme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                        ForEach(required) { item in
                            failedRow(item)
                        }
                    }
                    .transition(.opacity)
                }

                if abandonReason == .tooHard {
                    adaptationCard(
                        proposed: AdaptationEngine.volumeFactor(
                            for: failed.isEmpty ? .reduceVolume : .easierVariant),
                        explanation: failed.isEmpty
                            ? "La prochaine tentative sera moins chargée."
                            : "Les mouvements cochés redescendent aussi d'un cran.")
                }

                VStack(spacing: 9) {
                    PrimaryButton(title: "ARRÊTER LA SÉANCE", tint: Theme.crimson,
                                  enabled: abandonReason != nil) {
                        let ids = Array(failed)
                        store.abandonSession(tuned, reason: abandonReason ?? .hadToStop,
                                             failed: ids, dose: dose)
                        dismiss()
                    }
                    Button {
                        Haptics.tap()
                        withAnimation(.easeInOut(duration: 0.2)) { step = .card }
                    } label: {
                        Text("Reprendre la séance")
                            .font(.ui(13, .semibold))
                            .foregroundStyle(Theme.muted)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
    }

    /// Les mouvements qu'on peut déclarer bloquants : le travail principal,
    /// une ligne par mouvement. Une séance qui répète cinq fois le même
    /// exercice ne doit pas le proposer cinq fois.
    private var blockingCandidates: [ExercisePrescription] {
        var seen = Set<String>()
        return tuned.prescriptions.filter(\.isRequired).filter { item in
            seen.insert(item.variantId ?? item.name).inserted
        }
    }

    private func reasonRow(_ candidate: AbandonReason) -> some View {
        let picked = abandonReason == candidate
        return Button {
            Haptics.tap()
            withAnimation(.easeInOut(duration: 0.2)) {
                abandonReason = candidate
                if candidate != .tooHard { failed.removeAll() }
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: candidate.icon)
                    .font(.system(size: 17))
                    .foregroundStyle(picked ? Theme.crimson : Theme.muted)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 3) {
                    Text(candidate.label)
                        .font(.ui(15, .bold))
                        .foregroundStyle(Theme.text)
                    Text(candidate.detail)
                        .font(.ui(12))
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
            }
            .padding(15)
            .frame(maxWidth: .infinity)
            .background(picked ? Theme.crimson.opacity(0.10) : Theme.surface,
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(picked ? Theme.crimson : Theme.border, lineWidth: picked ? 2 : 1))
        }
        .buttonStyle(.plain)
    }

    private func failedRow(_ item: ExercisePrescription) -> some View {
        let key = item.variantId ?? item.name
        let picked = failed.contains(key)
        return Button {
            Haptics.tap()
            if picked { failed.remove(key) } else { failed.insert(key) }
        } label: {
            HStack(spacing: 11) {
                Image(systemName: picked ? "xmark.circle.fill" : "circle")
                    .font(.system(size: 19))
                    .foregroundStyle(picked ? Theme.crimson : Theme.dim)
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.name)
                        .font(.ui(14, .semibold))
                        .foregroundStyle(Theme.text)
                        .multilineTextAlignment(.leading)
                    Text(item.amountLabel)
                        .font(.ui(11, .semibold))
                        .foregroundStyle(Theme.muted)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(picked ? Theme.crimson.opacity(0.6) : Theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    /// La seule question posée après une séance : comment c'était.
    ///
    /// Trois questions étaient deux de trop. « As-tu terminé ? » ne se pose
    /// plus : arriver ici, c'est avoir terminé — sinon on abandonne, et c'est
    /// un autre chemin. La qualité d'exécution se lit dans les exercices
    /// obligatoires qu'on n'a pas cochés, ce qui est plus précis qu'une
    /// appréciation globale.
    private var feedbackScreen: some View {
        let heroFace = BudokaiHero(program: session.programID)
        return ScrollView {
            VStack(spacing: 22) {
                VStack(spacing: 8) {
                    Text("C'EST FAIT")
                        .font(.display(27))
                        .foregroundStyle(Theme.text)
                    Text("Comment c'était ?")
                        .font(.ui(15))
                        .foregroundStyle(Theme.muted)
                }
                .padding(.top, 34)

                HStack(spacing: 6) {
                    ForEach(PerceivedEffort.faces) { candidate in
                        Button {
                            Haptics.tap()
                            // changer d'avis repart du réglage conseillé :
                            // « nettement » ne veut pas dire la même chose
                            // dans un sens et dans l'autre
                            if report.effort != candidate { dose = .asProposed }
                            report.effort = candidate
                        } label: {
                            HeroFace(hero: heroFace, effort: candidate,
                                     selected: report.effort == candidate, size: 58)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(candidate.label)
                        .accessibilityAddTraits(report.effort == candidate ? [.isSelected] : [])
                    }
                }
                .frame(maxWidth: .infinity)

                // la légende, qui dit en toutes lettres ce que le visage montre
                Text(report.effort?.caption ?? "Touche le visage qui correspond")
                    .font(.ui(14, report.effort == nil ? .semibold : .bold))
                    .foregroundStyle(report.effort == nil ? Theme.dim : Theme.text)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .animation(.easeOut(duration: 0.15), value: report.effort)

                // ce que ça change pour la suite, annoncé avant de valider
                if let effort = report.effort { adaptationNote(for: effort) }

                VStack(spacing: 9) {
                    PrimaryButton(title: "VALIDER LA SÉANCE", tint: program.light) {
                        finish(with: report)
                    }
                    Button {
                        Haptics.tap()
                        finish(with: SessionReport())
                    } label: {
                        Text("Je préfère ne pas répondre")
                            .font(.ui(13, .semibold))
                            .foregroundStyle(Theme.muted)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .scrollIndicators(.hidden)
    }

    /// « La prochaine séance sera allégée de 10 %. »
    ///
    /// Le moteur décidait déjà ; il le disait après coup, en tête de la séance
    /// suivante. Le dire avant de valider, c'est rendre le réglage lisible au
    /// moment où on le déclenche.
    @ViewBuilder
    private func adaptationNote(for effort: PerceivedEffort) -> some View {
        let move = AdaptationEngine.decide(AdaptationInput(
            report: SessionReport(effort: effort, completion: .entirely),
            completedRatio: 1.0))
        adaptationCard(proposed: AdaptationEngine.volumeFactor(for: move),
                       explanation: move.explanation)
    }

    /// Ce que la prochaine séance devient, et de combien.
    ///
    /// Quand il s'agit d'alléger, le pratiquant règle l'ampleur : lui seul
    /// sait si la séance était un peu au-dessus ou très au-dessus. Le moteur
    /// garde la direction et les bornes.
    @ViewBuilder
    private func adaptationCard(proposed: Double, explanation: String) -> some View {
        let percent = dose.percent(from: proposed)
        let up = proposed > 1

        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 11) {
                Image(systemName: proposed == 1 ? "equal.circle"
                                                : (up ? "arrow.up.right" : "arrow.down.right"))
                    .font(.system(size: 15))
                    .foregroundStyle(proposed == 1 ? Theme.muted : (up ? program.light : Theme.crimson))
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 3) {
                    Text(proposed == 1
                         ? "La prochaine séance garde ce volume."
                         : (up ? "La prochaine séance sera renforcée de \(percent) %."
                               : "La prochaine séance sera allégée de \(percent) %."))
                        .font(.ui(13, .bold))
                        .foregroundStyle(Theme.text)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(explanation)
                        .font(.ui(12))
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            // le réglage vaut dans les deux sens, avec les mêmes bornes
            if AdaptationEngine.Dose.isAdjustable(proposed) {
                Text("Tu peux doser :")
                    .font(.ui(11, .semibold))
                    .foregroundStyle(Theme.dim)
                HStack(spacing: 7) {
                    ForEach(AdaptationEngine.Dose.choices(for: proposed)) { candidate in
                        doseRow(candidate, proposed: proposed)
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(Theme.border, lineWidth: 1))
        .transition(.opacity)
    }

    private func doseRow(_ candidate: AdaptationEngine.Dose, proposed: Double) -> some View {
        let percent = candidate.percent(from: proposed)
        let picked = dose.percent(from: proposed) == percent
        let up = proposed > 1
        let tint = up ? program.light : Theme.crimson
        return Button {
            Haptics.tap()
            withAnimation(.easeOut(duration: 0.15)) { dose = candidate }
        } label: {
            VStack(spacing: 1) {
                Text("\(up ? "+" : "−")\(percent) %")
                    .font(.display(17))
                    .foregroundStyle(picked ? tint : Theme.text)
                Text(candidate.label)
                    .font(.ui(10, .bold))
                    .foregroundStyle(Theme.muted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background(picked ? tint.opacity(0.12) : Theme.surfaceAlt,
                        in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(picked ? tint : Color.clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(up ? "Renforcer" : "Alléger") de \(percent) pour cent, \(candidate.label.lowercased())")
    }

    private func question<Content: View>(_ title: String,
                                         @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: title)
            VStack(spacing: 7) { content() }
        }
    }

    private func choice(_ label: String, icon: String?, picked: Bool,
                        _ action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 17))
                        .foregroundStyle(picked ? Theme.cream : program.light)
                        .frame(width: 24)
                }
                Text(label)
                    .font(.ui(14, .bold))
                    .foregroundStyle(picked ? Theme.cream : Theme.text)
                Spacer(minLength: 0)
                if picked {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.cream)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(picked ? AnyShapeStyle(program.light) : AnyShapeStyle(Theme.surface),
                        in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(picked ? Color.clear : Theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    /// Enregistre la séance comme faite, au niveau où elle était prévue,
    /// puis laisse le moteur décider de la suivante.
    private func finish(with report: SessionReport) {
        let done = tuned
        let openRatio = store.openSession(of: done.programID)?
            .ratio(against: done.prescriptions)
        let ratio = openRatio ?? 1.0

        store.record(report, for: done.programID, completedRatio: ratio, dose: dose)

        if alreadyRecorded {
            store.closeSession(of: done.programID)
            congratulate { dismiss() }
            return
        }
        var achieved: [Int: Int] = [:]
        for item in done.steps { achieved[item.id] = item.goal.value }
        // l'enregistrement lit les contributions : la séance se referme après
        outcome = store.complete(session: done, achieved: achieved)
        store.closeSession(of: done.programID)

        // tout est enregistré : le héros peut venir féliciter, puis le bilan
        congratulate { step = .outcome }
    }

    /// Fait revenir le héros après l'effort, puis passe à la suite.
    ///
    /// Le popup n'est qu'une couche de présentation : la séance est déjà
    /// enregistrée quand il s'affiche. S'il n'y a pas de visuel — héros sans
    /// image, interventions coupées — on enchaîne directement.
    private func congratulate(then next: @escaping () -> Void) {
        guard let asset = store.heroPopup(for: session.programID, phase: .sessionComplete) else {
            next()
            return
        }
        store.rememberHeroPopup(asset)
        afterHero = next
        hero = asset
    }

    // MARK: - Regroupement des étapes

    private struct Line {
        var name: String
        var detail: String
        var amount: String
    }

    /// « Pompes · 4 × 12 » plutôt que quatre lignes identiques.
    private var grouped: [Line] {
        var order: [String] = []
        var counts: [String: Int] = [:]
        var goals: [String: Goal] = [:]
        var details: [String: String] = [:]
        for item in tuned.steps {
            if counts[item.name] == nil {
                order.append(item.name)
                details[item.name] = item.detail
            }
            counts[item.name, default: 0] += 1
            goals[item.name] = item.goal
        }
        return order.map { name in
            let count = counts[name] ?? 1
            let goal = goals[name] ?? Goal(unit: .reps, value: 0)
            return Line(name: name,
                        detail: count > 1 ? "" : (details[name] ?? ""),
                        amount: count > 1 ? "\(count) × \(goal.short)" : goal.short)
        }
    }
}
