import SwiftUI

/// Le parcours de lancement d'un programme, une question à la fois.
///
/// Tout ce que le moteur réclame est demandé — fréquence, jours, séance clé,
/// durée, puis les quatre mesures de calibration — mais **jamais deux choses
/// sur le même écran**. Le pratiquant voit où il en est, peut revenir, et ne
/// fait jamais défiler un formulaire.
struct ProgramLaunchView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    let program: Program
    var onStart: () -> Void

    // — planning
    @State private var frequency = 0
    @State private var available: Set<Weekday> = Set(Weekday.allCases)
    @State private var keyDay: Weekday?
    @State private var minutes = 45

    // — calibration
    @State private var pushLevel = 4   // pompe au sol
    @State private var pushReps = 10
    @State private var squatLevel = 3  // squat au poids du corps
    @State private var squatReps = 15
    @State private var coreLevel = 5   // sit-up contrôlé
    @State private var coreReps = 10
    @State private var meters = 800
    @State private var runRatio = 0.5

    @State private var cursor = 0
    @State private var showJourney = false

    private var rules: ProgramSchedulingRules? { store.schedulingRules(of: program.id) }
    /// Saitama a sa calibration à quatre domaines ; les autres suivent les
    /// tests que leur coach a écrits.
    private var needsCalibration: Bool { program.id == .saitama }
    private var coachTests: [SessionLibrary.CalibrationTest] {
        program.id == .saitama ? [] : SessionLibrary.calibration(program.id)
    }
    /// Les réponses aux tests du coach, par identifiant.
    @State private var coachAnswers: [String: Int] = [:]
    private var tint: Color { program.light }

    // MARK: - Les étapes

    private enum Stage: Hashable {
        case welcome, frequency, days, keyDay, duration, week
        case calibrationIntro, push, squat, core, endurance
        case coachTest(Int)
        case summary
    }

    private var stages: [Stage] {
        var list: [Stage] = [.welcome]
        if rules != nil { list += [.frequency, .days, .keyDay, .duration, .week] }
        if needsCalibration { list += [.calibrationIntro, .push, .squat, .core, .endurance] }
        if !coachTests.isEmpty {
            list.append(.calibrationIntro)
            list += coachTests.indices.map { Stage.coachTest($0) }
        }
        list.append(.summary)
        return list
    }

    private var stage: Stage { stages[min(cursor, stages.count - 1)] }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressBar
                ScrollView {
                    content
                        .padding(.horizontal, 22)
                        .padding(.top, 26)
                        .padding(.bottom, 20)
                }
                .scrollIndicators(.hidden)
                bottomBar
            }
            .background(Theme.ground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(program.name.uppercased())
                        .font(.ui(12, .bold))
                        .kerning(2.0)
                        .foregroundStyle(Theme.muted)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
            }
        }
        .onAppear(perform: prepare)
        .fullScreenCover(isPresented: $showJourney) {
            ProgramJourneyView(program: program, isIntroduction: true)
        }
        .onChange(of: showJourney) { _, presented in
            if !presented { dismiss() }
        }
    }

    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach(stages.indices, id: \.self) { index in
                Capsule()
                    .fill(index <= cursor ? tint : Theme.surfaceAlt)
                    .frame(height: 3)
            }
        }
        .padding(.horizontal, 22)
        .padding(.top, 6)
    }

    // MARK: - Le contenu, écran par écran

    @ViewBuilder
    private var content: some View {
        switch stage {
        case .welcome: welcomeScreen
        case .frequency: frequencyScreen
        case .days: daysScreen
        case .keyDay: keyDayScreen
        case .duration: durationScreen
        case .week: weekScreen
        case .calibrationIntro: calibrationIntroScreen
        case .push: domainScreen(.push, SaitamaLibrary.push, reference: 4, number: 1,
                                 level: $pushLevel, reps: $pushReps, max: 60,
                                 cue: "Corps gréé, poitrine près du sol, coudes vers l'arrière. Compte ce que tu fais proprement, en gardant une ou deux répétitions en réserve.")
        case .squat: domainScreen(.squat, SaitamaLibrary.squat, reference: 3, number: 2,
                                  level: $squatLevel, reps: $squatReps, max: 40,
                                  cue: "Descends jusqu'à ce que les cuisses soient parallèles au sol, talons ancrés. Arrête-toi dès que la technique se dégrade.")
        case .core: domainScreen(.core, SaitamaLibrary.core, reference: 5, number: 3,
                                 level: $coreLevel, reps: $coreReps, max: 30,
                                 cue: "Remontée contrôlée, sans tirer sur la nuque ni s'aider d'un élan.")
        case .endurance: enduranceScreen
        case .coachTest(let index): coachTestScreen(index)
        case .summary: summaryScreen
        }
    }

    // MARK: Écrans

    private var welcomeScreen: some View {
        screen(eyebrow: "AVANT DE COMMENCER",
               title: "On règle ton programme",
               help: needsCalibration
                   ? "Deux minutes. D'abord quand tu peux t'entraîner, ensuite où tu en es physiquement. Le programme se construit autour de tes réponses."
                   : "Quelques questions sur tes disponibilités, et le programme se construit autour.") {
            VStack(alignment: .leading, spacing: 12) {
                bullet("calendar", "Tes disponibilités", "Fréquence, jours possibles et impossibles, durée.")
                if needsCalibration {
                    bullet("figure.strengthtraining.traditional", "Ton point de départ",
                           "Poussée, jambes, tronc et endurance, mesurés séparément.")
                }
                bullet("checkmark.seal", "Ta semaine",
                       "Tu la vois avant de valider. Rien n'est figé : tout se change ensuite.")
            }
        }
    }

    private var frequencyScreen: some View {
        screen(eyebrow: "QUESTION 1", title: "Combien de fois par semaine ?",
               help: rules.map { "Ce programme demande au moins \($0.minimumSessionsPerWeek) séances. En dessous, il ne tient plus debout." } ?? "") {
            VStack(spacing: 10) {
                ForEach(rules?.allowedFrequencies ?? [], id: \.self) { count in
                    bigChoice(title: "\(count) séances",
                              subtitle: count == rules?.recommendedSessionsPerWeek
                                  ? "Conseillé — c'est le rythme de référence"
                                  : (count < (rules?.recommendedSessionsPerWeek ?? 0)
                                     ? "Tenable, mais la progression est plus lente"
                                     : "Le maximum utile pour ce programme"),
                              picked: frequency == count) { frequency = count }
                }
            }
        }
    }

    private var daysScreen: some View {
        screen(eyebrow: "QUESTION 2", title: "Quels jours peux-tu t'entraîner ?",
               help: "Coche tous les jours possibles, même plus que de séances : le planning retiendra les meilleurs. Les jours non cochés ne seront jamais utilisés.") {
            dayGrid(selection: $available, tint: tint)
        }
    }

    private var keyDayScreen: some View {
        screen(eyebrow: "QUESTION 3",
               title: rules?.requiresLongSession == true ? "Quel jour pour la sortie longue ?" : "Quel jour pour la séance clé ?",
               help: "Une préférence, pas une garantie : si la récupération l'interdit, le planning la déplacera et te dira pourquoi.") {
            VStack(spacing: 10) {
                dayGrid(selection: Binding(
                    get: { keyDay.map { [$0] } ?? [] },
                    set: { keyDay = $0.first }), tint: Theme.gold, single: true)
                Button {
                    Haptics.tap()
                    keyDay = nil
                } label: {
                    Text("Peu importe")
                        .font(.ui(13, .semibold))
                        .foregroundStyle(keyDay == nil ? tint : Theme.muted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var durationScreen: some View {
        screen(eyebrow: "QUESTION 4", title: "Combien de temps par séance ?",
               help: "La sortie longue peut dépasser cette durée.") {
            VStack(spacing: 10) {
                ForEach([20, 30, 45, 60, 75], id: \.self) { value in
                    bigChoice(title: value == 75 ? "75 minutes ou plus" : "\(value) minutes",
                              subtitle: nil, picked: minutes == value) { minutes = value }
                }
            }
        }
    }

    private var weekScreen: some View {
        screen(eyebrow: "VOILÀ CE QUE ÇA DONNE", title: "Ta semaine",
               help: nil) {
            Group {
                switch plan {
                case .success(let schedule): weekTable(schedule)
                case .failure(let refusal): refusalBox(refusal)
                }
            }
        }
    }

    private var calibrationIntroScreen: some View {
        let tests = coachTests
        return screen(eyebrow: "TON POINT DE DÉPART",
               title: tests.isEmpty ? "Quatre mesures" : "\(tests.count) mesures",
               help: "Ce ne sont pas des tests maximaux. On cherche ton niveau actuel pour que la première séance tombe juste — ni ridicule, ni hors de portée.") {
            VStack(alignment: .leading, spacing: 12) {
                if tests.isEmpty {
                    bullet("figure.arms.open", "Poussée", "La variante de pompe que tu tiens proprement.")
                    bullet("figure.strengthtraining.functional", "Jambes", "Ton squat, et combien tu en fais.")
                    bullet("figure.core.training", "Tronc", "La variante d'abdominaux que tu contrôles.")
                    bullet("figure.run", "Endurance", "Six minutes, en courant ou en marchant.")
                } else {
                    ForEach(tests) { test in
                        bullet("target", test.label, test.cue)
                    }
                }
            }
        }
    }

    /// Un test écrit par le coach : son intitulé, sa consigne, une valeur.
    private func coachTestScreen(_ index: Int) -> some View {
        let tests = coachTests
        guard index < tests.count else { return AnyView(EmptyView()) }
        let test = tests[index]
        let step = test.objectiveUnit == .meters ? 100 : (test.objectiveUnit == .seconds ? 30 : 1)

        return AnyView(screen(eyebrow: "MESURE \(index + 1) SUR \(tests.count)",
                              title: test.label, help: nil) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("CE QU'ON MESURE")
                        .font(.ui(9, .bold))
                        .kerning(1.8)
                        .foregroundStyle(tint)
                    Text(test.cue)
                        .font(.ui(14))
                        .foregroundStyle(Theme.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(Theme.border, lineWidth: 1))

                stepper(unitLabel(test.objectiveUnit),
                        value: Binding(
                            get: { coachAnswers[test.id] ?? defaultAnswer(test) },
                            set: { coachAnswers[test.id] = $0 }),
                        range: 0...test.max, stride: step)

                Button {
                    Haptics.tap()
                    coachAnswers[test.id] = 0
                } label: {
                    Text("Je ne sais pas / je n'ai pas cette donnée")
                        .font(.ui(12, .semibold))
                        .foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                }
                .buttonStyle(.plain)
            }
        })
    }

    private func unitLabel(_ unit: ObjectiveUnit) -> String {
        switch unit {
        case .reps: return "Répétitions"
        case .seconds: return "Secondes"
        case .meters: return "Mètres"
        case .kg: return "Kilos"
        }
    }

    private func defaultAnswer(_ test: SessionLibrary.CalibrationTest) -> Int {
        switch test.objectiveUnit {
        case .seconds: return min(test.max, 1800)
        case .meters: return min(test.max, 5000)
        default: return min(test.max, 10)
        }
    }

    /// Un domaine : le mouvement attendu est **nommé**, pas choisi dans une
    /// liste. Le programme le fixe déjà — on demande seulement combien, et
    /// on n'ouvre une alternative que si le mouvement n'est pas tenable.
    private func domainScreen(_ domain: SaitamaDomain, _ family: ExerciseFamily,
                              reference: Int, number: Int,
                              level: Binding<Int>, reps: Binding<Int>, max: Int,
                              cue: String) -> some View {
        let exercise = SaitamaLibrary.exercise(family: family.id, level: level.wrappedValue)
        let isReference = level.wrappedValue >= reference
        let easier = SaitamaLibrary.exercise(family: family.id, level: level.wrappedValue - 1)

        return screen(eyebrow: "MESURE \(number) SUR 4", title: domain.label, help: nil) {
            VStack(alignment: .leading, spacing: 20) {
                // le mouvement attendu, énoncé
                VStack(alignment: .leading, spacing: 7) {
                    Text("L'EXERCICE")
                        .font(.ui(9, .bold))
                        .kerning(1.8)
                        .foregroundStyle(tint)
                    Text(exercise?.name ?? domain.label)
                        .font(.display(24))
                        .foregroundStyle(Theme.text)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(cue)
                        .font(.ui(13))
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    if !isReference {
                        Text("Version allégée. Le programme te ramènera au mouvement complet dès que tu le tiendras.")
                            .font(.ui(11, .semibold))
                            .foregroundStyle(Theme.gold)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(isReference ? Theme.border : Theme.gold.opacity(0.45), lineWidth: 1))

                stepper("Combien en fais-tu proprement", value: reps, range: 1...max)

                // la seule porte de sortie : je n'y arrive pas
                VStack(spacing: 6) {
                    if let easier = easier {
                        Button {
                            Haptics.tap()
                            level.wrappedValue -= 1
                            reps.wrappedValue = Swift.max(reps.wrappedValue, 5)
                        } label: {
                            Text("Je n'arrive pas à ce mouvement — passer à « \(easier.name.lowercased()) »")
                                .font(.ui(12, .semibold))
                                .foregroundStyle(Theme.muted)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 44)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .buttonStyle(.plain)
                    }
                    if !isReference,
                       let back = SaitamaLibrary.exercise(family: family.id, level: level.wrappedValue + 1) {
                        Button {
                            Haptics.tap()
                            level.wrappedValue += 1
                        } label: {
                            Text("Finalement, je tiens « \(back.name.lowercased()) »")
                                .font(.ui(12, .semibold))
                                .foregroundStyle(tint)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 40)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var enduranceScreen: some View {
        screen(eyebrow: "MESURE 4 SUR 4", title: "Endurance", help: nil) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("L'EXERCICE")
                        .font(.ui(9, .bold))
                        .kerning(1.8)
                        .foregroundStyle(tint)
                    Text("Six minutes de course")
                        .font(.display(24))
                        .foregroundStyle(Theme.text)
                    Text("Quelle distance peux-tu couvrir en six minutes ? Si tu dois marcher une partie du temps, marche : c'est aussi une réponse.")
                        .font(.ui(13))
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(Theme.border, lineWidth: 1))

                stepper("Distance en six minutes (mètres)", value: $meters,
                        range: 200...2500, stride: 50)

                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel(text: "COMMENT L'AS-TU FAIT ?")
                    ForEach(paceChoices, id: \.ratio) { choice in
                        bigChoice(title: choice.title, subtitle: choice.subtitle,
                                  picked: runRatio == choice.ratio) { runRatio = choice.ratio }
                    }
                }
            }
        }
    }

    /// Trois réponses concrètes plutôt qu'un pourcentage à estimer.
    private var paceChoices: [(ratio: Double, title: String, subtitle: String?)] {
        [(1.0, "J'ai couru sans m'arrêter", nil),
         (0.5, "J'ai alterné course et marche", nil),
         (0.15, "J'ai surtout marché", "C'est le point de départ de beaucoup de gens.")]
    }

    private var summaryScreen: some View {
        screen(eyebrow: "TOUT EST PRÊT", title: "Récapitulatif", help: nil) {
            VStack(alignment: .leading, spacing: 14) {
                if case .success(let schedule) = plan {
                    recap("Rythme", "\(schedule.sessionsPerWeek) séances par semaine")
                    recap("Durée estimée", "environ \(schedule.estimatedWeeks) semaines")
                    recap("Jours", schedule.sessions.map { $0.day.label }.joined(separator: ", "))
                }
                ForEach(coachTests) { test in
                    let value = coachAnswers[test.id] ?? 0
                    recap(test.label, value == 0 ? "non renseigné" : test.objectiveUnit.format(value))
                }
                if needsCalibration {
                    recap("Poussée", "\(SaitamaLibrary.exercise(family: "sai.push", level: pushLevel)?.name ?? "") · \(pushReps)")
                    recap("Jambes", "\(SaitamaLibrary.exercise(family: "sai.squat", level: squatLevel)?.name ?? "") · \(squatReps)")
                    recap("Tronc", "\(SaitamaLibrary.exercise(family: "sai.core", level: coreLevel)?.name ?? "") · \(coreReps)")
                    recap("Endurance", "\(meters) m en 6 minutes · "
                          + (paceChoices.first { $0.ratio == runRatio }?.title.lowercased() ?? ""))
                }
                Text("Tout cela se modifie ensuite, et le programme se recalcule à mesure que tu avances.")
                    .font(.ui(12))
                    .foregroundStyle(Theme.dim)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: - Briques

    private func screen<Content: View>(eyebrow: String, title: String, help: String?,
                                       @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 7) {
                Text(eyebrow)
                    .font(.ui(10, .bold))
                    .kerning(2.2)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.display(28))
                    .foregroundStyle(Theme.text)
                    .fixedSize(horizontal: false, vertical: true)
                if let help = help {
                    Text(help)
                        .font(.ui(14))
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func bullet(_ icon: String, _ title: String, _ body: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(tint)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.ui(14, .bold)).foregroundStyle(Theme.text)
                Text(body).font(.ui(12)).foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private func bigChoice(title: String, subtitle: String?, picked: Bool,
                           _ action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.ui(15, .bold))
                        .foregroundStyle(picked ? Theme.cream : Theme.text)
                        .multilineTextAlignment(.leading)
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.ui(11))
                            .foregroundStyle(picked ? Theme.cream.opacity(0.85) : Theme.muted)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
                if picked {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(Theme.cream)
                }
            }
            .padding(15)
            .frame(maxWidth: .infinity)
            .background(picked ? AnyShapeStyle(tint) : AnyShapeStyle(Theme.surface),
                        in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(picked ? Color.clear : Theme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func dayGrid(selection: Binding<Set<Weekday>>, tint: Color,
                         single: Bool = false) -> some View {
        VStack(spacing: 8) {
            ForEach(Weekday.allCases) { day in
                let picked = selection.wrappedValue.contains(day)
                Button {
                    Haptics.tap()
                    if single {
                        selection.wrappedValue = picked ? [] : [day]
                    } else if picked {
                        selection.wrappedValue.remove(day)
                    } else {
                        selection.wrappedValue.insert(day)
                    }
                } label: {
                    HStack {
                        Text(day.label)
                            .font(.ui(15, .bold))
                            .foregroundStyle(picked ? Theme.cream : Theme.text)
                        Spacer()
                        if picked {
                            Image(systemName: "checkmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(Theme.cream)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 50)
                    .background(picked ? AnyShapeStyle(tint) : AnyShapeStyle(Theme.surface),
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(picked ? Color.clear : Theme.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func stepper(_ title: String, value: Binding<Int>, range: ClosedRange<Int>,
                         stride: Int = 1) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: title.uppercased())
            HStack(spacing: 16) {
                StepButton(systemName: "minus", size: 52, enabled: value.wrappedValue > range.lowerBound) {
                    value.wrappedValue = Swift.max(range.lowerBound, value.wrappedValue - stride)
                }
                Text("\(value.wrappedValue)")
                    .font(.display(40))
                    .foregroundStyle(tint)
                    .frame(maxWidth: .infinity)
                StepButton(systemName: "plus", size: 52, enabled: value.wrappedValue < range.upperBound) {
                    value.wrappedValue = Swift.min(range.upperBound, value.wrappedValue + stride)
                }
            }
        }
    }

    private func recap(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label.uppercased())
                .font(.ui(10, .bold))
                .kerning(1.2)
                .foregroundStyle(Theme.muted)
                .frame(width: 96, alignment: .leading)
            Text(value)
                .font(.ui(14, .semibold))
                .foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private func weekTable(_ schedule: ProgramSchedule) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(spacing: 5) {
                ForEach(Weekday.allCases) { day in
                    HStack(spacing: 10) {
                        Text(day.label)
                            .font(.ui(13, .bold))
                            .foregroundStyle(Theme.text)
                            .frame(width: 88, alignment: .leading)
                        if let session = schedule.session(on: day) {
                            Text(session.metadata.displayTitle)
                                .font(.ui(13, .semibold))
                                .foregroundStyle(tint)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Spacer(minLength: 4)
                            Text("\(session.metadata.estimatedDurationMinutes) min")
                                .font(.ui(11, .semibold))
                                .foregroundStyle(Theme.muted)
                        } else {
                            Text("Repos").font(.ui(13)).foregroundStyle(Theme.dim)
                            Spacer(minLength: 0)
                        }
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 42)
                    .background(schedule.session(on: day) == nil ? Theme.ground : Theme.surface,
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
            Text("Environ \(schedule.estimatedWeeks) semaines, \(schedule.weeklyMinutes / 60) h \(schedule.weeklyMinutes % 60) par semaine.")
                .font(.ui(12, .semibold))
                .foregroundStyle(Theme.muted)
            ForEach(schedule.notes.indices, id: \.self) { index in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.muted)
                    Text(schedule.notes[index])
                        .font(.ui(11))
                        .foregroundStyle(Theme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func refusalBox(_ refusal: SchedulingRefusal) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Theme.crimson)
            Text(refusal.message)
                .font(.ui(13, .semibold))
                .foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.crimson.opacity(0.10), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }

    // MARK: - Navigation

    private var bottomBar: some View {
        HStack(spacing: 10) {
            if cursor > 0 {
                Button {
                    Haptics.tap()
                    withAnimation(.easeInOut(duration: 0.18)) { cursor -= 1 }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.muted)
                        .frame(width: 58, height: 58)
                        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Theme.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            PrimaryButton(title: stage == .summary ? "COMMENCER LE PROGRAMME" : "CONTINUER",
                          tint: tint, enabled: canContinue) {
                advance()
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 12)
        .background(
            Theme.groundDeep
                .overlay(Rectangle().frame(height: 1).foregroundStyle(Theme.border), alignment: .top)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var canContinue: Bool {
        switch stage {
        case .frequency: return frequency > 0
        case .days: return available.count >= frequency
        case .week: if case .failure = plan { return false }; return true
        default: return true
        }
    }

    private func advance() {
        if stage == .summary {
            commit()
            return
        }
        withAnimation(.easeInOut(duration: 0.18)) { cursor += 1 }
    }

    // MARK: - Données

    private var draft: TrainingAvailability {
        TrainingAvailability(
            targetSessionsPerWeek: frequency,
            availableWeekdays: Array(available).sorted(),
            blockedWeekdays: [],
            preferredWeekdays: [],
            preferredKeySessionDay: keyDay,
            preferredLongSessionDay: keyDay,
            defaultSessionMinutes: minutes)
    }

    private var plan: Result<ProgramSchedule, SchedulingRefusal> {
        guard let rules = rules else { return .failure(.belowMinimum(minimum: 1)) }
        return CalendarPlanner.plan(rules: rules, availability: draft,
                                    structure: store.structure(of: program.id))
    }

    private func prepare() {
        guard frequency == 0 else { return }
        frequency = rules?.recommendedSessionsPerWeek ?? 0
    }

    private func commit() {
        if rules != nil {
            guard case .success = store.applyAvailability(draft, to: program.id) else { return }
        }
        if needsCalibration {
            var calibration = SaitamaCalibration()
            calibration.level = ["push": pushLevel, "squat": squatLevel, "core": coreLevel]
            calibration.cleanReps = ["push": pushReps, "squat": squatReps, "core": coreReps]
            calibration.sixMinuteMeters = meters
            calibration.runRatio = runRatio
            store.setSaitamaCalibration(calibration)
        }
        if !coachTests.isEmpty {
            store.setCoachCalibration(coachAnswers, tests: coachTests, for: program.id)
        }
        Haptics.success()
        onStart()
        showJourney = true
    }
}
