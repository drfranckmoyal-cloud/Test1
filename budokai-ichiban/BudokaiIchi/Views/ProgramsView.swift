import SwiftUI

struct ProgramsView: View {
    @EnvironmentObject private var store: GameStore
    @State private var selected: Program?
    @State private var journey: Program?

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PROGRAMMES")
                            .font(.display(24))
                            .foregroundStyle(Theme.text)
                        Text(openCount == Catalog.programs.count
                             ? "LES \(openCount) SONT OUVERTS"
                             : "\(openCount) OUVERTS · \(Catalog.programs.count - openCount) VERROUILLÉS")
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
                            // un programme lancé s'ouvre sur sa route ; les
                            // autres sur leur présentation
                            if store.isActive(program.id), program.id == .saitama,
                               store.saitamaCalibration?.isComplete == true {
                                journey = program
                            } else {
                                selected = program
                            }
                        } label: {
                            ProgramTile(program: program,
                                        progress: ratio(program),
                                        locked: !store.isUnlocked(program),
                                        tile: program.tileImage)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text(openCount == Catalog.programs.count
                     ? "Tous les maîtres sont accessibles, le temps d'éprouver le contenu. Tu peux en suivre plusieurs à la fois."
                     : "Les programmes verrouillés s'ouvrent en montant tes caractéristiques et ton rang.")
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
        .sheet(item: $journey) { program in
            ProgramJourneyView(program: program)
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
