import SwiftUI

@main
struct PompesChallengeApp: App {
    @StateObject private var store = ChallengeStore()

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
    }
}
