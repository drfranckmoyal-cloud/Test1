import SwiftUI

@main
struct PompesChallengeApp: App {
    @StateObject private var store = ChallengeStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .task {
                    _ = await NotificationManager.requestAuthorization()
                    store.refreshDate()
                    store.syncNotifications()
                }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                store.refreshDate()
            }
        }
    }
}
