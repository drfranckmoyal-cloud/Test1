import SwiftUI

/// Une séance manquée ne casse pas la série : elle ouvre une quête à faire
/// avant minuit. C'est un rattrapage, pas une sanction.
struct PenaltyView: View {
    @EnvironmentObject private var store: GameStore

    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(hex: 0x3D0A0A), Color(hex: 0x1A0405), Color(hex: 0x0B0A0C)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 60)

                ZStack {
                    Circle().fill(Theme.crimson.opacity(0.22)).frame(width: 126, height: 126)
                    Circle().fill(Theme.crimson.opacity(0.34)).frame(width: 96, height: 96)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 48, weight: .black))
                        .foregroundStyle(Color(hex: 0xFFE8E4))
                }

                Text("SÉRIE EN DANGER")
                    .font(.display(34))
                    .foregroundStyle(Color(hex: 0xFF4433))
                    .multilineTextAlignment(.center)
                    .padding(.top, 26)

                Text("Séance manquée. Ta série de \(store.state.streak) jours tient encore — elle tombe à minuit si la quête n'est pas accomplie.")
                    .font(.ui(15, .semibold))
                    .foregroundStyle(Color(hex: 0xE0BDB8))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 30)
                    .padding(.top, 14)

                VStack(spacing: 9) {
                    Text("QUÊTE DE PÉNALITÉ · RANG \(store.rank.label)")
                        .font(.ui(10, .bold))
                        .kerning(2.4)
                        .foregroundStyle(Color(hex: 0xB07A74))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(store.state.penalty?.tasks ?? []) { task in
                        HStack(spacing: 14) {
                            Text("\(task.target)")
                                .font(.display(22))
                                .foregroundStyle(Color(hex: 0xFFD9D2))
                                .frame(minWidth: 44, alignment: .leading)
                            Text(task.name)
                                .font(.ui(15, .bold))
                                .foregroundStyle(Color(hex: 0xFFD9D2))
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 60)
                        .background(Color.black.opacity(0.4), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Theme.crimson.opacity(0.3), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 26)
                .padding(.top, 28)

                Spacer(minLength: 24)

                VStack(spacing: 10) {
                    PrimaryButton(title: "ACCEPTER LA QUÊTE") {
                        store.acceptPenalty()
                    }
                    Button {
                        Haptics.warning()
                        store.abandonStreak()
                    } label: {
                        Text("Laisser tomber la série")
                            .font(.ui(14, .bold))
                            .foregroundStyle(Color(hex: 0x8A6560))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 26)
                .padding(.bottom, 32)
            }
        }
        .closeCross(label: "Fermer") { store.abandonStreak() }
    }
}
