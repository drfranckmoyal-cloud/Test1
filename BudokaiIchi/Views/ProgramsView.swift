import SwiftUI

struct ProgramsView: View {
    @EnvironmentObject private var store: GameStore
    @State private var selected: Program?

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PROGRAMMES")
                            .font(.display(24))
                            .foregroundStyle(Theme.text)
                        Text("\(openCount) OUVERTS · \(Catalog.programs.count - openCount) VERROUILLÉS")
                            .font(.ui(11, .bold))
                            .kerning(1.8)
                            .foregroundStyle(Theme.muted)
                    }
                    Spacer()
                    RankBadge(rank: store.rank, size: 44)
                }
                .padding(.bottom, 18)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Catalog.programs) { program in
                        Button {
                            Haptics.tap()
                            selected = program
                        } label: {
                            ProgramTile(program: program,
                                        progress: ratio(program),
                                        locked: !store.isUnlocked(program))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text("Sept programmes attendent leur contenu sportif. Ils apparaissent ici pour qu'on voie où l'on va.")
                    .font(.ui(12))
                    .foregroundStyle(Theme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 16)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 26)
        }
        .scrollIndicators(.hidden)
        .background(Theme.ground)
        .sheet(item: $selected) { program in
            ProgramDetailView(program: program)
        }
    }

    private var openCount: Int {
        Catalog.programs.filter { store.isUnlocked($0) }.count
    }

    private func ratio(_ program: Program) -> Double {
        let done = store.progress(program.id).completedSessions
        return program.totalSessions > 0 ? Double(done) / Double(program.totalSessions) : 0
    }
}
