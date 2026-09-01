import SwiftUI

struct CalendarScreen: View {
    @EnvironmentObject private var store: ChallengeStore
    @State private var editedDay: DayCell?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 9), count: 5)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                monthProgress.padding(.top, 18)
                legend.padding(.top, 18)
                grid.padding(.top, 14)
                stats.padding(.top, 22)
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(Theme.background)
        .sheet(item: $editedDay) { day in
            CountSheet(
                title: "Jour \(day.id)",
                subtitle: dateLabel(for: day.date),
                goal: store.goal,
                initialValue: day.count
            ) { value in
                store.setCount(value, for: day.date)
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(rangeLabel.uppercased())
                .font(.display(24))
                .foregroundStyle(Theme.cream)
            Text("DÉFI \(store.goal) POMPES · \(store.durationDays) JOURS")
                .font(.ui(12, .semibold))
                .kerning(1.6)
                .foregroundStyle(Theme.muted)
        }
    }

    private var monthProgress: some View {
        VStack(spacing: 9) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("\(store.validatedCount)")
                    .font(.display(17))
                    .foregroundStyle(Theme.orangeLight)
                Text("jours validés")
                    .font(.ui(13, .semibold))
                    .foregroundStyle(Theme.muted)
                Spacer()
                Text("\(Int((store.monthProgress * 100).rounded())) %")
                    .font(.ui(13, .bold))
                    .foregroundStyle(Theme.muted)
            }
            ProgressBarView(value: store.monthProgress, height: 12)
        }
    }

    private var legend: some View {
        HStack(spacing: 16) {
            legendItem(label: "Validé") {
                RoundedRectangle(cornerRadius: 5, style: .continuous).fill(Theme.starGradient)
            }
            legendItem(label: "Manqué") {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Theme.missedFill)
                    .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).stroke(Theme.border, lineWidth: 1))
            }
            legendItem(label: "En cours") {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Theme.surfaceAlt)
                    .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).stroke(Theme.orange, lineWidth: 2))
            }
            Spacer(minLength: 0)
        }
    }

    private func legendItem<Swatch: View>(label: String, @ViewBuilder swatch: () -> Swatch) -> some View {
        HStack(spacing: 6) {
            swatch().frame(width: 14, height: 14)
            Text(label)
                .font(.ui(11))
                .foregroundStyle(Theme.muted)
        }
    }

    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 9) {
            ForEach(store.days) { day in
                DayCellView(day: day)
                    .onTapGesture {
                        guard day.status != .upcoming else { return }
                        editedDay = day
                    }
            }
        }
    }

    private var stats: some View {
        HStack(spacing: 10) {
            StatCard(value: "\(store.currentStreak)", label: "SÉRIE EN COURS", highlighted: true)
            StatCard(value: "\(store.bestStreak)", label: "MEILLEURE SÉRIE")
            StatCard(value: store.totalPushups.formattedPushups, label: "POMPES AU TOTAL")
        }
    }

    // MARK: - Libellés

    private var rangeLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "LLLL"
        let start = store.state.startDate
        let end = Calendar.current.date(byAdding: .day, value: store.durationDays - 1, to: start) ?? start
        let startMonth = formatter.string(from: start)
        let endMonth = formatter.string(from: end)
        return startMonth == endMonth ? startMonth : "\(startMonth) – \(endMonth)"
    }

    private func dateLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_FR")
        formatter.dateFormat = "EEEE d MMMM"
        return formatter.string(from: date).capitalized
    }
}

// MARK: - Une case du calendrier

struct DayCellView: View {
    let day: DayCell

    var body: some View {
        ZStack {
            switch day.status {
            case .validated:
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.starGradient)
                VStack(spacing: 1) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 19))
                        .foregroundStyle(Theme.creamOnOrange)
                    Text("\(day.id)")
                        .font(.ui(10, .bold))
                        .foregroundStyle(Theme.ink.opacity(0.7))
                }

            case .today:
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.surfaceAlt)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Theme.orange, lineWidth: 2)
                    )
                VStack(spacing: 2) {
                    Text("\(day.id)")
                        .font(.display(17))
                        .foregroundStyle(Theme.orangeLight)
                    Text("\(Int((day.progress * 100).rounded())) %")
                        .font(.ui(9, .bold))
                        .foregroundStyle(Theme.muted)
                }
                VStack {
                    Spacer()
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle().fill(Theme.border)
                            Rectangle()
                                .fill(Theme.orange)
                                .frame(width: geometry.size.width * min(max(day.progress, 0), 1))
                        }
                    }
                    .frame(height: 4)
                }

            case .missed:
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.missedFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Theme.border, lineWidth: 1)
                    )
                Text("\(day.id)")
                    .font(.ui(15, .bold))
                    .foregroundStyle(Theme.missedText)

            case .upcoming:
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.upcomingFill)
                Text("\(day.id)")
                    .font(.ui(15, .semibold))
                    .foregroundStyle(Theme.upcomingText)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        switch day.status {
        case .validated: return "Jour \(day.id), validé, \(day.count) pompes"
        case .today: return "Jour \(day.id), en cours, \(day.count) pompes"
        case .missed: return "Jour \(day.id), manqué, \(day.count) pompes"
        case .upcoming: return "Jour \(day.id), à venir"
        }
    }
}
