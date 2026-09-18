import SwiftUI

/// L'accueil. Deux actions qui comptent, deux qui dépannent, et le tuteur du
/// jour. Volontairement pauvre en chiffres : ce n'est pas un tableau de bord.
struct HomeView: View {

    @EnvironmentObject private var store: LearnerStore

    @AppStorage("shuo.tutor.locked") private var lockedTutorID: String = ""
    @AppStorage("shuo.duration") private var duration: Int = 15
    @AppStorage("shuo.devmode") private var devMode: Bool = false

    @State private var session: SessionPlan?
    @State private var showDurationPicker = false
    @State private var showSettings = false
    @State private var returnTestDismissed = false

    private var tutor: Tutor {
        Tutor.next(after: store.state.lastTutorID, locked: lockedTutorID.isEmpty ? nil : lockedTutorID)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    tutorOfTheDay

                    if store.shouldOfferReturnTest(), !returnTestDismissed {
                        returnTestCard
                    }

                    primaryActions
                    secondaryActions
                    progressLine

                    if devMode {
                        NavigationLink {
                            DevModeView()
                        } label: {
                            Label("Mode développeur", systemImage: "wrench.and.screwdriver")
                                .font(Theme.caption)
                                .foregroundStyle(Theme.inkSoft)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(20)
            }
            .paperBackground()
            .navigationTitle("Shuō")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .tint(Theme.ink)
                }
            }
            .sheet(isPresented: $showSettings) { SettingsView() }
            .fullScreenCover(item: $session) { plan in
                SessionView(plan: plan)
            }
        }
    }

    // MARK: - Tuteur du jour

    private var tutorOfTheDay: some View {
        HStack(spacing: 16) {
            TutorAvatar(tutor: tutor, size: 60)
            VStack(alignment: .leading, spacing: 4) {
                Text(tutor.hanzi)
                    .font(Theme.title)
                    .foregroundStyle(Theme.ink)
                Text(tutor.pinyin)
                    .font(Theme.caption)
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
            if !lockedTutorID.isEmpty {
                Image(systemName: "lock.fill")
                    .foregroundStyle(Theme.inkSoft)
                    .font(.caption)
            }
        }
        .cartouche()
    }

    // MARK: - Actions

    private var primaryActions: some View {
        VStack(spacing: 12) {
            BigButton(
                title: "Continuer ma progression",
                subtitle: nextUpLabel,
                systemImage: "arrow.forward.circle.fill",
                tint: Theme.seal
            ) {
                showDurationPicker = true
            }
            .confirmationDialog("Combien de temps ?", isPresented: $showDurationPicker) {
                ForEach(SessionOrchestrator.offeredDurations, id: \.self) { minutes in
                    Button("\(minutes) minutes") {
                        duration = minutes
                        start(mode: .progression, minutes: minutes)
                    }
                }
                Button("Annuler", role: .cancel) {}
            }

            BigButton(
                title: "Révision",
                subtitle: dueLabel,
                systemImage: "arrow.triangle.2.circlepath",
                tint: Theme.ink
            ) {
                start(mode: .review, minutes: min(duration, 10))
            }
            .disabled(store.state.items.isEmpty)
            .opacity(store.state.items.isEmpty ? 0.4 : 1)
        }
    }

    private var secondaryActions: some View {
        VStack(spacing: 10) {
            if let interrupted = store.interruptedSession {
                SmallButton(
                    title: "Reprendre la séance interrompue",
                    detail: "\(interrupted.durationChoice) min, \(interrupted.mode.label.lowercased())"
                ) {
                    start(mode: interrupted.mode, minutes: interrupted.durationChoice)
                }
            }
            if store.lastSession != nil {
                SmallButton(title: "Revoir la leçon précédente", detail: nil) {
                    start(mode: .replay, minutes: 10)
                }
            }
        }
    }

    /// Le test de retour, proposé après trois jours d'absence. Court, et on
    /// peut dire non.
    private var returnTestCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ça fait quelques jours.")
                .font(Theme.body.weight(.semibold))
                .foregroundStyle(Theme.ink)
            Text("Deux minutes pour voir ce qui tient encore ?")
                .font(Theme.body)
                .foregroundStyle(Theme.inkSoft)
            HStack(spacing: 12) {
                Button("D'accord") { start(mode: .returnTest, minutes: 5) }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.seal)
                Button("Plus tard") { returnTestDismissed = true }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.inkSoft)
                    .font(Theme.caption)
            }
        }
        .cartouche()
    }

    // MARK: - Repères

    /// Une ligne, trois nombres. Le reste vit dans la séance, pas ici.
    private var progressLine: some View {
        let counts = store.statusCounts
        return HStack(spacing: 18) {
            StatusDot(color: Theme.green, count: counts.green, label: "acquis")
            StatusDot(color: Theme.orange, count: counts.orange, label: "à consolider")
            StatusDot(color: Theme.red, count: counts.red, label: "à apprendre")
            Spacer()
        }
        .cartouche(padding: 16)
    }

    private var nextUpLabel: String {
        guard let entry = ContentLibrary.shared.entry(at: store.state.cursor.entryIndex) else {
            return "Programme HSK 1 terminé"
        }
        return entry.displayTitle
    }

    private var dueLabel: String {
        let due = store.dueItems().count
        if store.state.items.isEmpty { return "Rien à revoir pour l'instant" }
        return due == 0 ? "Tout est frais — révision libre" : "\(due) à revoir"
    }

    // MARK: - Démarrage

    private func start(mode: SessionMode, minutes: Int) {
        let plan = SessionOrchestrator.buildPlan(
            mode: mode,
            durationMinutes: minutes,
            state: store.state,
            library: .shared,
            tutorID: tutor.id
        )
        guard SessionOrchestrator.isValid(plan) else {
            assertionFailure("Recette invalide : plus de trois mots nouveaux")
            return
        }
        session = plan
    }
}
