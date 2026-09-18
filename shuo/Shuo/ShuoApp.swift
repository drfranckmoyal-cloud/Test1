import SwiftUI

@main
struct ShuoApp: App {
    @StateObject private var store = LearnerStore()
    @StateObject private var voice = VoiceService()
    @StateObject private var telemetry = Telemetry()
    @StateObject private var network = NetworkMonitor()
    @AppStorage("shuo.appearance") private var appearance: String = Appearance.system.rawValue

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(voice)
                .environmentObject(telemetry)
                .environmentObject(network)
                .preferredColorScheme(Appearance(rawValue: appearance)?.colorScheme)
                .task {
                    await voice.requestPermissions()
                }
        }
    }
}
