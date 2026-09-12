import SwiftUI

// MARK: - La marque

/// Le trait unique de « ichi », tracé au pinceau : épais à l'attaque, effilé
/// vers la droite, gonflé par une brève pression finale. Mêmes constantes que
/// `tools/make_budokai_icon.py`, pour que l'écran et l'icône soient le même
/// dessin.
struct IchiStroke: Shape {
    private static let leftR = 232.0 / 1024.0
    private static let rightR = 792.0 / 1024.0
    private static let midR = 545.0 / 1024.0
    private static let riseR = 30.0 / 1024.0
    private static let baseR = 44.0 / 1024.0

    private func halfWidth(_ t: Double, base: Double) -> Double {
        let attack = 0.12 * exp(-pow((t - 0.05) / 0.09, 2))
        let press = 0.16 * exp(-pow((t - 0.90) / 0.11, 2))
        let body = 0.98 - 0.24 * t
        return base * max(0.30, body + attack + press)
    }

    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height)
        let x0 = rect.minX + Self.leftR * side
        let x1 = rect.minX + Self.rightR * side
        let yMid = rect.minY + Self.midR * side
        let rise = Self.riseR * side
        let base = Self.baseR * side

        let steps = 96
        var top: [CGPoint] = []
        var bottom: [CGPoint] = []
        for step in 0...steps {
            let t = Double(step) / Double(steps)
            let x = x0 + (x1 - x0) * t
            let y = yMid - rise * (t - 0.5) * 2
            let half = halfWidth(t, base: base)
            top.append(CGPoint(x: x, y: y - half))
            bottom.append(CGPoint(x: x, y: y + half))
        }

        var path = Path()
        path.move(to: top[0])
        for index in top.indices.dropFirst() { path.addLine(to: top[index]) }
        for index in bottom.indices.reversed() { path.addLine(to: bottom[index]) }
        path.closeSubpath()
        return path
    }
}

/// Le sceau vermillon incliné et son trait, la marque de l'app.
struct SealMark: View {
    var size: CGFloat = 92

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.10, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0xE02B20), Color(hex: 0xA8160E)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size * 0.674, height: size * 0.674)
                .rotationEffect(.degrees(-4))
                .shadow(color: Color(hex: 0xE02B20).opacity(0.35), radius: size * 0.18, y: size * 0.06)

            IchiStroke()
                .fill(Theme.cream)
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-4))
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Page d'accueil

struct HomeView: View {
    @EnvironmentObject private var store: GameStore
    /// Pour envoyer vers un autre onglet depuis l'accueil.
    var go: (Tab) -> Void

    /// Le programme dont on demande l'arrêt, le temps de confirmer.
    @State private var stopping: Program?
    @State private var journey: Program?

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                banner
                rankCard
                currentProgramSection
                recordSection
                openProgramsSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)
            .padding(.bottom, 26)
        }
        .scrollIndicators(.hidden)
        .background(Theme.ground)
        .sheet(item: $journey) { program in
            ProgramJourneyView(program: program)
        }
        .confirmationDialog("Arrêter ce programme ?",
                            isPresented: Binding(get: { stopping != nil },
                                                 set: { if !$0 { stopping = nil } }),
                            titleVisibility: .visible) {
            if let program = stopping {
                Button("Arrêter \(program.name)", role: .destructive) {
                    store.stopProgram(program.id)
                    stopping = nil
                }
            }
            Button("Continuer le programme", role: .cancel) { stopping = nil }
        } message: {
            Text("Ton avancée est gardée. Tu pourras le reprendre là où tu l'as laissé.")
        }
    }

    // MARK: Bandeau de marque

    private var banner: some View {
        VStack(spacing: 14) {
            // La calligraphie 武道会, tracée au pinceau. Elle porte la marque à
            // elle seule : pas de titre en lettres par-dessus.
            Image("LogoBudokai")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 300)
                .frame(height: 116)
                .accessibilityLabel("Budokai Ichiban")

            Text("BUDOKAÏ ICHIBAN")
                .font(.display(15))
                .kerning(3.5)
                .foregroundStyle(Theme.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text("Neuf maîtres, une seule échelle.")
                .font(.ui(14))
                .foregroundStyle(Theme.muted)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 14)
        .padding(.bottom, 20)
    }

    // MARK: Où j'en suis

    private var rankCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                RankBadge(rank: store.rank, size: 58)

                VStack(alignment: .leading, spacing: 4) {
                    Text("NIVEAU \(store.level)")
                        .font(.display(21))
                        .foregroundStyle(Theme.text)
                    Text("RANG \(store.rank.label) · \(store.state.xp.grouped) XP")
                        .font(.ui(11, .bold))
                        .kerning(1.2)
                        .foregroundStyle(Theme.muted)
                }

                Spacer(minLength: 8)

                VStack(spacing: 2) {
                    Text("\(store.state.streak)")
                        .font(.display(24))
                        .foregroundStyle(store.state.streak > 0 ? Theme.crimson : Theme.dim)
                    Text(store.state.streak > 1 ? "JOURS" : "JOUR")
                        .font(.ui(9, .bold))
                        .kerning(1.0)
                        .foregroundStyle(Theme.muted)
                }
            }

            VStack(spacing: 10) {
                VStack(spacing: 5) {
                    ProgressBar(value: store.levelProgress, height: 6, tint: Theme.gold)
                    Text("Encore \(store.xpToNextLevel.grouped) XP pour le niveau \(store.level + 1).")
                        .font(.ui(11, .semibold))
                        .foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if let next = store.nextRank {
                    VStack(spacing: 5) {
                        ProgressBar(value: store.rankProgress, height: 6, tint: Theme.rankColor(next.rank))
                        Text("Rang \(next.rank.label) dans \(next.missing.grouped) XP — environ \(programsLeft(next.missing)).")
                            .font(.ui(11, .semibold))
                            .foregroundStyle(Theme.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(18)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.border, lineWidth: 1))
    }

    // MARK: Le programme en cours

    @ViewBuilder
    private var currentProgramSection: some View {
        if !store.activePrograms.isEmpty {
            let programs = store.activePrograms
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: programs.count > 1 ? "TES \(programs.count) PROGRAMMES" : "TON PROGRAMME")
                ForEach(programs) { program in
                    activeCard(program)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: "PAR OÙ COMMENCER")
                noProgramCard
            }
        }
    }

    private func activeCard(_ program: Program) -> some View {
        let status = store.stageStatus(program)
        let stageName = store.stageName(program)
        let ratio = status.total > 0 ? Double(status.done) / Double(status.total) : 0
        let finished = store.session(of: program.id) == nil

        return VStack(spacing: 0) {
            ZStack {
                program.gradient
                ArtworkFill(name: program.stageImage(status.index))
                LinearGradient(colors: [Color.black.opacity(0.62), Color.black.opacity(0.18)],
                               startPoint: .leading, endPoint: .trailing)
                HStack(spacing: 14) {
                    ZStack {
                        ProgressRing(progress: ratio, lineWidth: 7, tint: Theme.cream)
                        Text("\(Int(ratio * 100))%")
                            .font(.display(16))
                            .foregroundStyle(Theme.cream)
                    }
                    .frame(width: 62, height: 62)

                    VStack(alignment: .leading, spacing: 4) {
                        Button {
                            Haptics.tap()
                            journey = program
                        } label: {
                            HStack(spacing: 5) {
                                Text(program.name.uppercased())
                                    .font(.display(21))
                                    .foregroundStyle(Theme.cream)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                Image(systemName: "map")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(Theme.cream.opacity(0.75))
                            }
                        }
                        .buttonStyle(.plain)
                        Text(stageName.uppercased())
                            .font(.ui(10, .bold))
                            .kerning(1.4)
                            .foregroundStyle(Theme.cream.opacity(0.85))
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                    }
                    Spacer(minLength: 0)

                    Button {
                        Haptics.tap()
                        stopping = program
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.cream)
                            .frame(width: 34, height: 34)
                            .background(Color.black.opacity(0.30), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Arrêter \(program.name)")
                }
                .padding(.horizontal, 18)
            }
            .frame(height: 108)

            VStack(spacing: 12) {
                HStack {
                    Text("\(status.done) séances sur \(status.total)")
                        .font(.ui(13, .semibold))
                        .foregroundStyle(Theme.muted)
                    Spacer()
                    Text(rhythmLabel(program))
                        .font(.ui(13, .bold))
                        .foregroundStyle(program.light)
                }

                PrimaryButton(title: buttonTitle(program, finished: finished), tint: program.light) {
                    go(.session)
                }
            }
            .padding(16)
        }
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.border, lineWidth: 1))
    }

    private func buttonTitle(_ program: Program, finished: Bool) -> String {
        if finished { return "PROGRAMME TERMINÉ" }
        if store.needsSetup(program.id) { return "RÉGLER LE PROGRAMME" }
        if store.isResting(program.id) { return "VOIR LE JOUR DE REPOS" }
        // le programme est pris : ce bouton mène à la séance, il le dit
        return store.progress(program.id).notStarted ? "OUVRIR LA PREMIÈRE SÉANCE" : "CONTINUER"
    }

    private func rhythmLabel(_ program: Program) -> String {
        if store.session(of: program.id) == nil { return "Terminé" }
        if store.isResting(program.id) {
            guard let due = store.nextDueDay(of: program.id) else { return "Repos" }
            return "Repos · reprise \(dayLabel(due))"
        }
        return "Séance du jour"
    }

    private var noProgramCard: some View {
        VStack(spacing: 14) {
            Text("Aucun programme en cours")
                .font(.display(19))
                .foregroundStyle(Theme.text)
            Text("Choisis ton maître. Saitama pour la transformation brute, Naruto pour la course : les deux sont ouverts dès maintenant.")
                .font(.ui(14))
                .foregroundStyle(Theme.muted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: "CHOISIR UN MAÎTRE") {
                go(.programs)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.border, lineWidth: 1))
    }

    // MARK: Ce qui est déjà fait

    private var recordSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "À TON COMPTEUR")
            HStack(spacing: 10) {
                tally(value: "\(store.sessionsDone)", label: store.sessionsDone > 1 ? "SÉANCES" : "SÉANCE")
                tally(value: store.totalReps.grouped, label: "RÉPÉTITIONS")
                tally(value: "\(unlockedCount)/\(Catalog.programs.count)", label: "OUVERTS")
            }
        }
    }

    private func tally(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.display(23))
                .foregroundStyle(Theme.text)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.ui(9, .bold))
                .kerning(1.0)
                .foregroundStyle(Theme.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.border, lineWidth: 1))
    }

    // MARK: Les autres maîtres

    private var openProgramsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                SectionLabel(text: "LES NEUF MAÎTRES")
                Button {
                    Haptics.tap()
                    go(.programs)
                } label: {
                    Text("TOUT VOIR")
                        .font(.ui(10, .bold))
                        .kerning(1.2)
                        .foregroundStyle(Theme.crimson)
                }
                .buttonStyle(.plain)
            }

            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(Catalog.programs) { program in
                        Button {
                            Haptics.tap()
                            go(.programs)
                        } label: {
                            ProgramTile(program: program,
                                        progress: ratio(program),
                                        locked: !store.isUnlocked(program),
                                        height: 132,
                                        tile: program.tileImage)
                                .frame(width: 128)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: Outils

    /// Traduit un reste d'expérience en programmes, la seule échelle
    /// parlante : « il te reste deux programmes » se comprend, « 45 000 XP »
    /// non.
    private func programsLeft(_ missing: Int) -> String {
        let programs = Double(missing) / Double(GameEngine.programXPReference)
        if programs < 0.25 { return "la fin de ce jalon" }
        if programs < 0.75 { return "un demi-programme" }
        if programs < 1.25 { return "un programme complet" }
        return "\(Int(programs.rounded())) programmes complets"
    }

    private var unlockedCount: Int {
        Catalog.programs.filter { store.isUnlocked($0) }.count
    }

    private func ratio(_ program: Program) -> Double {
        store.completion(of: program.id)
    }

    private func dayLabel(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInTomorrow(date) { return "demain" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
}
