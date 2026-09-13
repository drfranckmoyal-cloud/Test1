import SwiftUI

@main
struct BudokaiIchiApp: App {
    @StateObject private var store = GameStore()
    /// Vrai au premier affichage du processus, et jamais rétabli ensuite :
    /// l'ouverture se montre au lancement à froid, pas à chaque retour depuis
    /// l'arrière-plan.
    @State private var opening = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()
                    .environmentObject(store)
                    .task {
                        _ = await NotificationManager.requestAuthorization()
                        store.refreshDate()
                        store.issuePenaltyIfNeeded()
                        store.syncNotifications()
                    }

                if opening {
                    BudokaiOpeningView {
                        withAnimation(.easeOut(duration: 0.2)) { opening = false }
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
        }
    }
}
