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
    @State private var blocked: Set<Weekday> = []
    @State private var keyDay: Weekday?
    @State private var minutes = 45

    // — calibration
    @State private var pushLevel = 4
    @State private var pushReps = 10
    @State private var squatLevel = 3
    @State private var squatReps = 15
    @State private var coreLevel = 2
    @State private var coreReps = 10
    @State private var meters = 800
    @State private var runRatio = 0.5

    @State private var cursor = 0

    private var rules: ProgramSchedulingRules? { store.schedulingRules(of: program.id) }
    private var needsCalibration: Bool { program.id == .saitama }
    private var tint: Color { program.light }

    // MARK: - Les étapes

    private enum Stage: Hashable {
        case welcome, frequency, days, blocked, keyDay, duration, week
        case calibrationIntro, push, squat, core, endurance
        case summary
    }

    private var stages: [Stage] {
        var list: [Stage] = [.welcome]
        if rules != nil { list += [.frequency, .days, .blocked, .keyDay, .duration, .week] }
        if needsCalibration { list += [.calibrationIntro, .push, .squat, .core, .endurance] }
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
        case .blocked: blockedScreen
        case .keyDay: keyDayScreen
        case .duration: durationScreen
        case .week: weekScreen
        case .calibrationIntro: calibrationIntroScreen
        case .push: domainScreen(.push, SaitamaLibrary.push, level: $pushLevel,
                                 reps: $pushReps, max: 60,
                                 help: "Trouve la variante qui te permet 8 à 20 répétitions propres en gardant une ou deux répétitions en réserve.")
        case .squat: domainScreen(.squat, SaitamaLibrary.squat, level: $squatLevel,
                                  reps: $squatReps, max: 40,
                                  help: "Une série submaximale, arrêtée dès que la technique se dégrade.")
        case .core: domainScreen(.core, SaitamaLibrary.core, level: $coreLevel,
                                 reps: $coreReps, max: 30,
                                 help: "La variante que tu contrôles vraiment, puis une série propre.")
        case .endurance: enduranceScreen
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
        screen(eyebrow: "QUESTION 2", title: "Quels jours peux-tu ?",
               help: "Coches-en plus que de séances si tu veux : le planning choisira les meilleurs.") {
            dayGrid(selection: $available, tint: tint)
        }
    }

    private var blockedScreen: some View {
        screen(eyebrow: "QUESTION 3", title: "Des jours vraiment impossibles ?",
               help: "Un jour marqué ici ne sera jamais utilisé, quelle que soit la logique sportive. Laisse vide si tu n'en as pas.") {
            dayGrid(selection: $blocked, tint: Theme.crimson)
        }
    }

    private var keyDayScreen: some View {
        screen(eyebrow: "QUESTION 4",
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
        screen(eyebrow: "QUESTION 5", title: "Combien de temps par séance ?",
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
        screen(eyebrow: "TON POINT DE DÉPART", title: "Quatre mesures",
               help: "Ce ne sont pas des tests maximaux. On cherche ton niveau actuel pour que la première séance tombe juste — ni ridicule, ni hors de portée.") {
            VStack(alignment: .leading, spacing: 12) {
                bullet("figure.arms.open", "Poussée", "La variante de pompe que tu tiens proprement.")
                bullet("figure.strengthtraining.functional", "Jambes", "Ton squat, et combien tu en fais.")
                bullet("figure.core.training", "Tronc", "La variante d'abdominaux que tu contrôles.")
                bullet("figure.run", "Endurance", "Six minutes, en courant ou en marchant.")
            }
        }
    }

    private func domainScreen(_ domain: SaitamaDomain, _ family: ExerciseFamily,
                              level: Binding<Int>, reps: Binding<Int>, max: Int,
                              help: String) -> some View {
        screen(eyebrow: "MESURE \(domain == .push ? "1" : domain == .squat ? "2" : "3") SUR 4",
               title: domain.label, help: help) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel(text: "TA VARIANTE")
                    ForEach(family.ladder) { exercise in
                        bigChoice(title: exercise.name, subtitle: exercise.detail,
                                  picked: level.wrappedValue == exercise.level) {
                            level.wrappedValue = exercise.level
                        }
                    }
                }
                stepper("Répétitions propres", value: reps, range: 1...max)
            }
        }
    }

    private var enduranceScreen: some View {
        screen(eyebrow: "MESURE 4 SUR 4", title: "Endurance",
               help: "Six minutes de marche ou de course. On note la distance, et la part que tu as réellement courue.") {
            VStack(alignment: .leading, spacing: 20) {
                stepper("Distance en 6 minutes (mètres)", value: $meters, range: 200...2500, stride: 50)
                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel(text: "PART RÉELLEMENT COURUE")
                    HStack(spacing: 6) {
                        ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { value in
                            Button {
                                Haptics.tap()
                                runRatio = value
                            } label: {
                                Text("\(Int(value * 100)) %")
                                    .font(.ui(13, .bold))
                                    .foregroundStyle(runRatio == value ? Theme.cream : Theme.muted)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(runRatio == value ? AnyShapeStyle(tint) : AnyShapeStyle(Theme.surface),
                                                in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(runRatio == value ? Color.clear : Theme.border, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var summaryScreen: some View {
        screen(eyebrow: "TOUT EST PRÊT", title: "Récapitulatif", help: nil) {
            VStack(alignment: .leading, spacing: 14) {
                if case .success(let schedule) = plan {
                    recap("Rythme", "\(schedule.sessionsPerWeek) séances par semaine")
                    recap("Durée estimée", "environ \(schedule.estimatedWeeks) semaines")
                    recap("Jours", schedule.sessions.map { $0.day.label }.joined(separator: ", "))
                }
                if needsCalibration {
                    recap("Poussée", "\(SaitamaLibrary.exercise(family: "sai.push", level: pushLevel)?.name ?? "") · \(pushReps)")
                    recap("Jambes", "\(SaitamaLibrary.exercise(family: "sai.squat", level: squatLevel)?.name ?? "") · \(squatReps)")
                    recap("Tronc", "\(SaitamaLibrary.exercise(family: "sai.core", level: coreLevel)?.name ?? "") · \(coreReps)")
                    recap("Endurance", "\(meters) m en 6 minutes")
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
        case .days: return !available.subtracting(blocked).isEmpty
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
            blockedWeekdays: Array(blocked).sorted(),
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
        Haptics.success()
        onStart()
        dismiss()
    }
}
