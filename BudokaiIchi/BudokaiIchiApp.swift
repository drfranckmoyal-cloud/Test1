import SwiftUI

@main
struct BudokaiIchiApp: App {
    @StateObject private var store = GameStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .task {
                    _ = await NotificationManager.requestAuthorization()
                    store.refreshDate()
                    store.issuePenaltyIfNeeded()
                    store.syncNotifications()
                }
        }
    }
}
