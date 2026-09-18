import SwiftUI

/// Les réglages. Court : l'app a peu de boutons, et c'est voulu.
struct SettingsView: View {

    @EnvironmentObject private var voice: VoiceService
    @Environment(\.dismiss) private var dismiss

    @AppStorage("shuo.appearance") private var appearance: String = Appearance.system.rawValue
    @AppStorage("shuo.tutor.locked") private var lockedTutorID: String = ""
    @AppStorage("shuo.devmode") private var devMode: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Tuteur") {
                    Picker("Tuteur", selection: $lockedTutorID) {
                        Text("Rotation").tag("")
                        ForEach(Tutor.all) { tutor in
                            Text("\(tutor.hanzi) · \(tutor.pinyin)").tag(tutor.id)
                        }
                    }
                    Text("En rotation, un tuteur différent à chaque séance. La pédagogie ne change pas.")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.inkSoft)
                }

                Section("Voix") {
                    Picker("Mode", selection: $voice.mode) {
                        ForEach(VoiceMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    if voice.permissionDenied {
                        Label(
                            "Micro ou reconnaissance vocale refusés. Réglages iPhone → Shuō.",
                            systemImage: "exclamationmark.triangle"
                        )
                        .font(Theme.caption)
                        .foregroundStyle(Theme.orange)
                    }
                }

                Section("Apparence") {
                    Picker("Thème", selection: $appearance) {
                        ForEach(Appearance.allCases) { option in
                            Text(option.label).tag(option.rawValue)
                        }
                    }
                }

                Section {
                    Toggle("Mode développeur", isOn: $devMode)
                } footer: {
                    Text("Affiche le modèle actif, la latence, les jetons et le coût.")
                }
            }
            .navigationTitle("Réglages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}
