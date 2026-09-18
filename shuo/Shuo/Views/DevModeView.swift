import SwiftUI

/// Le mode développeur. Tout ce qui permet de comprendre ce que la séance a
/// réellement fait : le modèle, la latence, les jetons, le coût, le journal.
///
/// Il n'y a rien ici qui coupe quoi que ce soit. Le dossier demande des
/// alertes, pas un robinet : la qualité passe avant le budget.
struct DevModeView: View {

    @EnvironmentObject private var store: LearnerStore
    @EnvironmentObject private var telemetry: Telemetry
    @EnvironmentObject private var voice: VoiceService
    @EnvironmentObject private var network: NetworkMonitor

    @AppStorage("shuo.routing") private var routingRaw: String = RoutingMode.automatic.rawValue
    @State private var apiKey: String = ""
    @State private var showKey = false
    @State private var showResetConfirm = false
    @State private var audit: [ContentAudit.Result] = []

    var body: some View {
        List {
            modelSection
            costSection
            voiceSection
            auditSection
            logSection
            stateSection
        }
        .navigationTitle("Mode développeur")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            apiKey = Keychain.anthropicAPIKey ?? ""
            audit = ContentAudit.run()
        }
    }

    // MARK: - Modèle

    private var modelSection: some View {
        Section("Modèle") {
            LabeledContent("Actif") {
                ModelBadge(
                    model: telemetry.activeModel,
                    justSwitched: telemetry.modelJustSwitched,
                    isLocal: Keychain.anthropicAPIKey == nil || !network.isOnline
                )
            }
            if let trigger = telemetry.lastTrigger {
                LabeledContent("Déclencheur", value: trigger.rawValue)
            }
            Picker("Routage", selection: $routingRaw) {
                ForEach(RoutingMode.allCases) { mode in
                    Text(mode.label).tag(mode.rawValue)
                }
            }
            LabeledContent("Léger", value: LanguageModel.light.id)
            LabeledContent("Fort", value: LanguageModel.strong.id)

            HStack {
                if showKey {
                    TextField("Clé API Anthropic", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(Theme.mono)
                } else {
                    SecureField("Clé API Anthropic", text: $apiKey)
                        .font(Theme.mono)
                }
                Button {
                    showKey.toggle()
                } label: {
                    Image(systemName: showKey ? "eye.slash" : "eye")
                }
                .buttonStyle(.plain)
            }
            Button("Enregistrer la clé") {
                Keychain.anthropicAPIKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .disabled(apiKey.isEmpty)
            Text("Sans clé, le tuteur local prend le relais : la séance tourne, hors ligne, en moins souple.")
                .font(Theme.caption)
                .foregroundStyle(Theme.inkSoft)
        }
    }

    // MARK: - Coût

    private var costSection: some View {
        Section("Coût et latence") {
            if let alert = telemetry.costAlert {
                Label(alert, systemImage: "exclamationmark.triangle")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.orange)
            }
            LabeledContent("Séance", value: String(format: "%.4f € (%.4f $)",
                                                   telemetry.sessionCostEUR, telemetry.sessionCostUSD))
            LabeledContent("Rythme", value: String(format: "%.2f €/h — cible %.2f €/h",
                                                   telemetry.costPerHourEUR, Telemetry.targetEURPerHour))
            LabeledContent("Cumulé", value: String(format: "%.3f € sur %.1f h",
                                                   store.cumulativeCostEUR, store.cumulativeHours))
            LabeledContent("Jetons", value: "\(telemetry.sessionInputTokens) → \(telemetry.sessionOutputTokens)")
            LabeledContent("Latence moyenne", value: String(format: "%.2f s", telemetry.averageLatency))
            LabeledContent("Appels", value: "\(telemetry.calls.count)")
        }
    }

    // MARK: - Voix

    private var voiceSection: some View {
        Section("Voix") {
            LabeledContent("Mode", value: voice.mode.label)
            LabeledContent("État", value: activityLabel)
            LabeledContent("Réseau", value: network.isOnline ? "en ligne" : "hors ligne")
            if let confidence = voice.lastConfidence {
                LabeledContent("Confiance ASR", value: String(format: "%.2f", confidence))
            } else {
                LabeledContent("Confiance ASR", value: "non fournie")
            }
        }
    }

    private var activityLabel: String {
        switch voice.activity {
        case .idle: return "au repos"
        case .speaking: return "le tuteur parle"
        case .listening: return "à l'écoute"
        case .paused: return "en pause"
        }
    }

    // MARK: - Contenu

    private var auditSection: some View {
        Section("Vérification du contenu embarqué") {
            ForEach(audit) { result in
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.octagon.fill")
                        .foregroundStyle(result.passed ? Theme.green : Theme.red)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(result.id) · \(result.title)")
                            .font(Theme.caption)
                            .foregroundStyle(Theme.ink)
                        Text(result.detail)
                            .font(Theme.mono)
                            .foregroundStyle(Theme.inkSoft)
                    }
                }
            }
            Button("Revérifier") { audit = ContentAudit.run() }
        }
    }

    // MARK: - Journal

    private var logSection: some View {
        Section("Journal technique") {
            if telemetry.sessionLog.isEmpty {
                Text("Aucune séance depuis le lancement.")
                    .font(Theme.caption)
                    .foregroundStyle(Theme.inkSoft)
            } else {
                ForEach(Array(telemetry.sessionLog.suffix(40).enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(Theme.mono)
                        .foregroundStyle(Theme.inkSoft)
                }
            }
            // Le journal exporté ne contient pas la clé : elle reste dans le
            // trousseau et n'en sort pas.
            ShareLink(item: telemetry.exportLog()) {
                Label("Exporter le journal", systemImage: "square.and.arrow.up")
            }
        }
    }

    // MARK: - État apprenant

    private var stateSection: some View {
        Section("État apprenant") {
            let counts = store.statusCounts
            LabeledContent("Mots rencontrés", value: "\(store.state.items.count)")
            LabeledContent("Acquis / à consolider / à apprendre",
                           value: "\(counts.green) / \(counts.orange) / \(counts.red)")
            LabeledContent("Vocabulaire actif", value: "\(store.activeVocabCount)")
            LabeledContent("Vocabulaire passif", value: "\(store.passiveVocabCount)")
            LabeledContent("Dus aujourd'hui", value: "\(store.dueItems().count)")
            LabeledContent("Séances", value: "\(store.state.sessions.count)")
            LabeledContent("Curseur",
                           value: "entrée \(store.state.cursor.entryIndex), mot \(store.state.cursor.itemOffset)")
            if !store.state.pendingRemediations.isEmpty {
                LabeledContent("À reprendre", value: store.state.pendingRemediations.joined(separator: ", "))
            }

            Button("Tout effacer", role: .destructive) { showResetConfirm = true }
                .confirmationDialog(
                    "Effacer toute la progression ?",
                    isPresented: $showResetConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Effacer", role: .destructive) { store.reset() }
                    Button("Annuler", role: .cancel) {}
                } message: {
                    Text("Statuts, historique et curseur repartent de zéro. Irréversible.")
                }
        }
    }
}
