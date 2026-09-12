import SwiftUI

enum Tab: String, CaseIterable, Identifiable {
    case home, session, programs, profile
    var id: String { rawValue }
    var title: String {
        switch self {
        case .home: return "Accueil"
        case .session: return "Séance"
        case .programs: return "Programmes"
        case .profile: return "Profil"
        }
    }
    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .session: return "bolt.heart"
        case .programs: return "square.grid.2x2"
        case .profile: return "person.crop.circle"
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab: Tab = .home

    private let ticker = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Theme.ground.ignoresSafeArea()
            if store.state.onboarded {
                Group {
                    switch tab {
                    case .home: HomeView { destination in tab = destination }
                    case .session: TodayView()
                    case .programs: ProgramsView()
                    case .profile: ProfileView()
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) { TabBar(selection: $tab) }
            } else {
                OnboardingView()
            }
        }
        .preferredColorScheme(store.state.appearance.colorScheme)
        .onReceive(ticker) { _ in store.refreshDate() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.refreshDate() }
        }
        .fullScreenCover(isPresented: penaltyPresented) { PenaltyView() }
    }

    /// La quête s'impose tant qu'elle n'est pas acceptée ou abandonnée.
    private var penaltyPresented: Binding<Bool> {
        Binding(
            get: { store.state.penalty.map { !$0.accepted } ?? false },
            set: { _ in }
        )
    }
}

struct TabBar: View {
    @Binding var selection: Tab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases) { tab in
                Button {
                    selection = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 19, weight: .semibold))
                        Text(tab.title).font(.ui(10, .bold))
                    }
                    .foregroundStyle(selection == tab ? Theme.crimson : Theme.dim)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .background(
            Theme.groundDeep
                .overlay(Rectangle().frame(height: 1).foregroundStyle(Theme.border), alignment: .top)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}
