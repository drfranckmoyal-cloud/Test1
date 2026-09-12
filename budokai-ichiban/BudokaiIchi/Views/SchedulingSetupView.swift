import SwiftUI

/// Les questions posées au lancement d'un programme, avant de construire son
/// calendrier.
///
/// L'idée du chapitre 3.3 tient en une phrase : ce n'est pas le pratiquant
/// qui s'adapte au planning, c'est le planning qui se construit autour de sa
/// vie — sans jamais descendre sous le minimum sportif du programme.
struct SchedulingSetupView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    let program: Program
    /// Appelé une fois le calendrier accepté.
    var onDone: () -> Void

    @State private var frequency: Int = 0
    @State private var available: Set<Weekday> = Set(Weekday.allCases)
    @State private var blocked: Set<Weekday> = []
    @State private var preferred: Set<Weekday> = []
    @State private var keyDay: Weekday?
    @State private var minutes: Int = 45
    @State private var refusal: SchedulingRefusal?
    @State private var preview: ProgramSchedule?

    private var rules: ProgramSchedulingRules? { store.schedulingRules(of: program.id) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if let rules = rules {
                        intro(rules)
                        frequencySection(rules)
                        daysSection
                        blockedSection
                        keySection(rules)
                        minutesSection
                        if let refusal = refusal { refusalBox(refusal) }
                        if let preview = preview { previewBox(preview) }
                    } else {
                        unavailable
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background(Theme.ground)
            .navigationTitle("Ton planning")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if rules != nil { validateBar }
            }
        }
        .onAppear(perform: prepare)
        .onChange(of: frequency) { _, _ in rebuild() }
        .onChange(of: available) { _, _ in rebuild() }
        .onChange(of: blocked) { _, _ in rebuild() }
        .onChange(of: keyDay) { _, _ in rebuild() }
    }

    // MARK: - Intro

    private func intro(_ rules: ProgramSchedulingRules) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(program.name.uppercased())
                .font(.display(24))
                .foregroundStyle(Theme.text)
            Text("Avant de commencer, dis-moi quand tu peux t'entraîner. Le programme se construira autour, sans descendre sous ce qu'il exige pour rester sérieux.")
                .font(.ui(14))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 6)
    }

    private var unavailable: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Ce programme n'a pas encore ses règles de planning")
                .font(.display(19))
                .foregroundStyle(Theme.text)
            Text("Il démarre avec son rythme d'origine. Seuls Saitama et Naruto savent aujourd'hui construire un calendrier sur mesure.")
                .font(.ui(14))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
            PrimaryButton(title: "COMMENCER QUAND MÊME", tint: program.light) {
                onDone()
                dismiss()
            }
        }
        .padding(.top, 20)
    }

    // MARK: - 1. Combien de séances

    private func frequencySection(_ rules: ProgramSchedulingRules) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "COMBIEN DE FOIS PAR SEMAINE")
            HStack(spacing: 8) {
                ForEach(rules.allowedFrequencies, id: \.self) { count in
                    Button {
                        Haptics.tap()
                        frequency = count
                    } label: {
                        VStack(spacing: 2) {
                            Text("\(count)")
                                .font(.display(22))
                            if count == rules.recommendedSessionsPerWeek {
                                Text("CONSEILLÉ")
                                    .font(.ui(8, .bold))
                                    .kerning(0.8)
                            }
                        }
                        .foregroundStyle(frequency == count ? Theme.cream : Theme.muted)
                        .frame(maxWidth: .infinity)
                        .frame(height: 62)
                        .background(frequency == count ? AnyShapeStyle(program.light) : AnyShapeStyle(Theme.surface),
                                    in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .stroke(frequency == count ? Color.clear : Theme.border, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            Text("Minimum \(rules.minimumSessionsPerWeek) · conseillé \(rules.recommendedSessionsPerWeek) · au-delà de \(rules.maximumStructuredSessionsPerWeek), ce programme n'ajoute rien d'utile.")
                .font(.ui(11))
                .foregroundStyle(Theme.dim)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - 2 et 3. Les jours

    private var daysSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "QUELS JOURS SONT POSSIBLES")
            dayRow(selection: $available, excluded: blocked, tint: program.light)
            Text("Tu peux en cocher plus que de séances : le planning choisira les meilleurs.")
                .font(.ui(11))
                .foregroundStyle(Theme.dim)
        }
    }

    private var blockedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "QUELS JOURS SONT IMPOSSIBLES")
            dayRow(selection: $blocked, excluded: [], tint: Theme.crimson)
            Text("Un jour impossible ne sera jamais utilisé, quelle que soit la logique sportive.")
                .font(.ui(11))
                .foregroundStyle(Theme.dim)
        }
    }

    private func dayRow(selection: Binding<Set<Weekday>>, excluded: Set<Weekday>,
                        tint: Color) -> some View {
        HStack(spacing: 6) {
            ForEach(Weekday.allCases) { day in
                let picked = selection.wrappedValue.contains(day)
                let dimmed = excluded.contains(day)
                Button {
                    Haptics.tap()
                    if picked { selection.wrappedValue.remove(day) }
                    else { selection.wrappedValue.insert(day) }
                } label: {
                    Text(day.short)
                        .font(.ui(14, .bold))
                        .foregroundStyle(picked ? Theme.cream : (dimmed ? Theme.dim : Theme.muted))
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .background(picked ? AnyShapeStyle(tint) : AnyShapeStyle(Theme.surface),
                                    in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .stroke(picked ? Color.clear : Theme.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(day.label)
            }
        }
    }

    // MARK: - 5. La séance clé

    private func keySection(_ rules: ProgramSchedulingRules) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: keyTitle(rules))
            HStack(spacing: 6) {
                ForEach(Weekday.allCases) { day in
                    let picked = keyDay == day
                    Button {
                        Haptics.tap()
                        keyDay = picked ? nil : day
                    } label: {
                        Text(day.short)
                            .font(.ui(14, .bold))
                            .foregroundStyle(picked ? Theme.ink : Theme.muted)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(picked ? AnyShapeStyle(Theme.gold) : AnyShapeStyle(Theme.surface),
                                        in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .stroke(picked ? Color.clear : Theme.border, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            Text("Une préférence, pas une garantie : si la récupération l'interdit, le planning déplacera et te dira pourquoi.")
                .font(.ui(11))
                .foregroundStyle(Theme.dim)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func keyTitle(_ rules: ProgramSchedulingRules) -> String {
        rules.requiresLongSession ? "QUEL JOUR POUR LA SORTIE LONGUE" : "QUEL JOUR POUR LA SÉANCE CLÉ"
    }

    // MARK: - 6. La durée

    private var minutesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "COMBIEN DE TEMPS PAR SÉANCE")
            HStack(spacing: 6) {
                ForEach([20, 30, 45, 60, 75], id: \.self) { value in
                    Button {
                        Haptics.tap()
                        minutes = value
                    } label: {
                        Text(value == 75 ? "75+" : "\(value)")
                            .font(.ui(14, .bold))
                            .foregroundStyle(minutes == value ? Theme.cream : Theme.muted)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(minutes == value ? AnyShapeStyle(program.light) : AnyShapeStyle(Theme.surface),
                                        in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .stroke(minutes == value ? Color.clear : Theme.border, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            Text("En minutes. La sortie longue peut dépasser cette durée.")
                .font(.ui(11))
                .foregroundStyle(Theme.dim)
        }
    }

    // MARK: - Le résultat

    private func refusalBox(_ refusal: SchedulingRefusal) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 15))
                .foregroundStyle(Theme.crimson)
            Text(refusal.message)
                .font(.ui(13, .semibold))
                .foregroundStyle(Theme.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.crimson.opacity(0.10), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
            .stroke(Theme.crimson.opacity(0.35), lineWidth: 1))
    }

    private func previewBox(_ schedule: ProgramSchedule) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionLabel(text: "TA SEMAINE")

            VStack(spacing: 5) {
                ForEach(Weekday.allCases) { day in
                    HStack(spacing: 10) {
                        Text(day.label)
                            .font(.ui(13, .bold))
                            .foregroundStyle(Theme.text)
                            .frame(width: 84, alignment: .leading)
                        if let session = schedule.session(on: day) {
                            Text(session.metadata.displayTitle)
                                .font(.ui(13, .semibold))
                                .foregroundStyle(program.light)
                            Spacer(minLength: 6)
                            Text("\(session.metadata.estimatedDurationMinutes) min")
                                .font(.ui(11, .semibold))
                                .foregroundStyle(Theme.muted)
                        } else {
                            Text("Repos")
                                .font(.ui(13))
                                .foregroundStyle(Theme.dim)
                            Spacer(minLength: 0)
                        }
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 40)
                    .background(schedule.session(on: day) == nil ? Theme.ground : Theme.surfaceAlt,
                                in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
            }

            HStack(spacing: 14) {
                estimate("\(schedule.estimatedWeeks)", "SEMAINES ESTIMÉES")
                estimate("\(schedule.weeklyMinutes / 60) h \(schedule.weeklyMinutes % 60)", "PAR SEMAINE")
            }

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
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Theme.border, lineWidth: 1))
    }

    private func estimate(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.display(20))
                .foregroundStyle(Theme.text)
            Text(label)
                .font(.ui(8, .bold))
                .kerning(0.8)
                .foregroundStyle(Theme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var validateBar: some View {
        PrimaryButton(title: "COMMENCER LE PROGRAMME", tint: program.light,
                      enabled: preview != nil) {
            commit()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Theme.groundDeep
                .overlay(Rectangle().frame(height: 1).foregroundStyle(Theme.border), alignment: .top)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Construction

    private func prepare() {
        guard let rules = rules, frequency == 0 else { return }
        frequency = rules.recommendedSessionsPerWeek
        rebuild()
    }

    private var draft: TrainingAvailability {
        TrainingAvailability(
            targetSessionsPerWeek: frequency,
            availableWeekdays: Array(available).sorted(),
            blockedWeekdays: Array(blocked).sorted(),
            preferredWeekdays: Array(preferred).sorted(),
            preferredKeySessionDay: keyDay,
            preferredLongSessionDay: keyDay,
            defaultSessionMinutes: minutes)
    }

    private func rebuild() {
        guard let rules = rules, frequency > 0 else { return }
        switch CalendarPlanner.plan(rules: rules, availability: draft,
                                    structure: store.structure(of: program.id)) {
        case .success(let schedule):
            preview = schedule
            refusal = nil
        case .failure(let error):
            preview = nil
            refusal = error
        }
    }

    private func commit() {
        guard case .success = store.applyAvailability(draft, to: program.id) else { return }
        Haptics.success()
        onDone()
        dismiss()
    }
}
