import SwiftUI

/// La calibration de Saitama : quatre domaines mesurés séparément.
///
/// Poussée, jambes, tronc et endurance ont chacun leur variante et leur
/// niveau. Rien ne les moyenne — c'est le premier point de la définition de
/// « Saitama terminé ».
struct SaitamaCalibrationView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    var onDone: () -> Void

    @State private var step = 0
    @State private var pushLevel = 4
    @State private var pushReps = 10
    @State private var squatLevel = 3
    @State private var squatReps = 15
    @State private var coreLevel = 2
    @State private var coreReps = 10
    @State private var meters = 800
    @State private var runRatio = 0.5

    private let program = Catalog.program(.saitama)
    private var tint: Color { program.light }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    intro
                    switch step {
                    case 0: pushStep
                    case 1: squatStep
                    case 2: coreStep
                    default: enduranceStep
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background(Theme.ground)
            .navigationTitle("Calibration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Plus tard") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) { bottomBar }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ForEach(0..<4) { index in
                    Capsule()
                        .fill(index <= step ? tint : Theme.surfaceAlt)
                        .frame(height: 4)
                }
            }
            Text(["POUSSÉE", "JAMBES", "TRONC", "ENDURANCE"][step])
                .font(.display(24))
                .foregroundStyle(Theme.text)
            Text(subtitle)
                .font(.ui(13))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 6)
    }

    private var subtitle: String {
        switch step {
        case 0: return "Trouve la variante qui te permet 8 à 20 répétitions propres en gardant une ou deux répétitions en réserve. Ce n'est pas un test maximal."
        case 1: return "Dix squats de qualification, puis une série submaximale. On s'arrête dès que la technique se dégrade."
        case 2: return "Choisis la variante que tu contrôles vraiment, puis compte une série propre."
        default: return "Six minutes, en courant, en marchant, ou en alternant. On note la distance et la part réellement courue."
        }
    }

    // MARK: - Les quatre domaines

    private var pushStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            ladder(SaitamaLibrary.push, level: $pushLevel)
            counter("Répétitions propres", value: $pushReps, range: 1...60)
        }
    }

    private var squatStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            ladder(SaitamaLibrary.squat, level: $squatLevel)
            counter("Répétitions propres", value: $squatReps, range: 1...40,
                    note: "Plafonné à 40 : au-delà, c'est de l'endurance, pas de la force.")
        }
    }

    private var coreStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            ladder(SaitamaLibrary.core, level: $coreLevel)
            counter("Répétitions propres", value: $coreReps, range: 1...30,
                    note: "Plafonné à 30.")
        }
    }

    private var enduranceStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            counter("Distance en 6 minutes (mètres)", value: $meters, range: 200...2500, stride: 50)

            VStack(alignment: .leading, spacing: 8) {
                SectionLabel(text: "PART RÉELLEMENT COURUE")
                HStack(spacing: 6) {
                    ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { value in
                        Button {
                            Haptics.tap()
                            runRatio = value
                        } label: {
                            Text("\(Int(value * 100)) %")
                                .font(.ui(13, .bold))
                                .foregroundStyle(runRatio == value ? Theme.cream : Theme.muted)
                                .frame(maxWidth: .infinity)
                                .frame(height: 46)
                                .background(runRatio == value ? AnyShapeStyle(tint) : AnyShapeStyle(Theme.surface),
                                            in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous)
                                    .stroke(runRatio == value ? Color.clear : Theme.border, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - Briques

    private func ladder(_ family: ExerciseFamily, level: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: "TA VARIANTE")
            VStack(spacing: 6) {
                ForEach(family.ladder) { exercise in
                    let picked = level.wrappedValue == exercise.level
                    Button {
                        Haptics.tap()
                        level.wrappedValue = exercise.level
                    } label: {
                        HStack(spacing: 10) {
                            Text("\(exercise.level)")
                                .font(.display(13))
                                .foregroundStyle(picked ? Theme.cream : Theme.dim)
                                .frame(width: 24, height: 24)
                                .background(picked ? Color.white.opacity(0.18) : Theme.surfaceAlt, in: Circle())
                            VStack(alignment: .leading, spacing: 1) {
                                Text(exercise.name)
                                    .font(.ui(14, .bold))
                                    .foregroundStyle(picked ? Theme.cream : Theme.text)
                                    .multilineTextAlignment(.leading)
                                if let detail = exercise.detail {
                                    Text(detail)
                                        .font(.ui(11))
                                        .foregroundStyle(picked ? Theme.cream.opacity(0.8) : Theme.muted)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(picked ? AnyShapeStyle(tint) : AnyShapeStyle(Theme.surface),
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(picked ? Color.clear : Theme.border, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func counter(_ title: String, value: Binding<Int>, range: ClosedRange<Int>,
                         stride: Int = 1, note: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionLabel(text: title.uppercased())
            HStack(spacing: 14) {
                StepButton(systemName: "minus", size: 48, enabled: value.wrappedValue > range.lowerBound) {
                    value.wrappedValue = max(range.lowerBound, value.wrappedValue - stride)
                }
                Text("\(value.wrappedValue)")
                    .font(.display(36))
                    .foregroundStyle(tint)
                    .frame(maxWidth: .infinity)
                StepButton(systemName: "plus", size: 48, enabled: value.wrappedValue < range.upperBound) {
                    value.wrappedValue = min(range.upperBound, value.wrappedValue + stride)
                }
            }
            if let note = note {
                Text(note)
                    .font(.ui(11))
                    .foregroundStyle(Theme.dim)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var bottomBar: some View {
        PrimaryButton(title: step < 3 ? "SUIVANT" : "ENREGISTRER LA CALIBRATION", tint: tint) {
            if step < 3 {
                withAnimation(.easeInOut(duration: 0.2)) { step += 1 }
            } else {
                commit()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Theme.groundDeep
                .overlay(Rectangle().frame(height: 1).foregroundStyle(Theme.border), alignment: .top)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func commit() {
        var calibration = SaitamaCalibration()
        calibration.level = ["push": pushLevel, "squat": squatLevel, "core": coreLevel]
        calibration.cleanReps = ["push": pushReps, "squat": squatReps, "core": coreReps]
        calibration.sixMinuteMeters = meters
        calibration.runRatio = runRatio
        store.setSaitamaCalibration(calibration)
        Haptics.success()
        onDone()
        dismiss()
    }
}
