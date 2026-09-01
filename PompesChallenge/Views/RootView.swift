import SwiftUI

enum Tab: String, CaseIterable, Identifiable {
    case today
    case calendar
    case reminders

    var id: String { rawValue }

    var title: String {
        switch self {
        case .today: return "Aujourd'hui"
        case .calendar: return "Calendrier"
        case .reminders: return "Rappels"
        }
    }

    var icon: String {
        switch self {
        case .today: return "chart.line.uptrend.xyaxis"
        case .calendar: return "calendar"
        case .reminders: return "bell.fill"
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var store: ChallengeStore
    @State private var tab: Tab = .today

    private let midnightTicker = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            Group {
                switch tab {
                case .today: TodayView()
                case .calendar: CalendarScreen()
                case .reminders: RemindersView()
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                TabBar(selection: $tab)
            }
        }
        .preferredColorScheme(.dark)
        .onReceive(midnightTicker) { _ in
            store.refreshDate()
        }
        .fullScreenCover(item: $store.celebration) { celebration in
            CelebrationView(celebration: celebration)
        }
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
                        Text(tab.title)
                            .font(.ui(10, .bold))
                    }
                    .foregroundStyle(selection == tab ? Theme.orange : Theme.tabInactive)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .background(
            Theme.backgroundDeep
                .overlay(Rectangle().frame(height: 1).foregroundStyle(Theme.surfaceAlt), alignment: .top)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}
