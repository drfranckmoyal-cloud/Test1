import SwiftUI

/// L'écran où Franck façonne son combattant. Les changements se voient
/// aussitôt sur le personnage affiché en haut.
struct AvatarEditorView: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.dismiss) private var dismiss

    @State private var draft = AvatarConfig()
    @State private var pose: AvatarPose = .idle

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    stage
                    poseRail
                    buildSection
                    hairSection
                    colorSection(title: "CHEVEUX",
                                 choices: AvatarConfig.hairChoices,
                                 selected: draft.hairColor) { draft.hairColor = $0 }
                    colorSection(title: "PEAU",
                                 choices: AvatarConfig.skinChoices,
                                 selected: draft.skin) { draft.skin = $0 }
                    colorSection(title: "YEUX",
                                 choices: AvatarConfig.eyeChoices,
                                 selected: draft.eye) { draft.eye = $0 }
                    outfitSection
                    beltSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
            .scrollIndicators(.hidden)
            .background(Theme.ground)
            .navigationTitle("Ton combattant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Garder") {
                        store.setAvatar(draft)
                        Haptics.tap()
                        dismiss()
                    }
                    .font(.ui(15, .bold))
                }
            }
        }
        .onAppear { draft = store.state.avatar }
    }

    // MARK: - Le personnage en scène

    private var stage: some View {
        ZStack {
            Text("一番")
                .font(.system(size: 150, weight: .black))
                .foregroundStyle(Theme.text.opacity(0.045))

            AvatarView(config: draft, pose: pose, belt: store.belt, width: 250)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 340)
        .background(
            RadialGradient(colors: [Theme.surfaceAlt, Theme.surface],
                           center: .init(x: 0.5, y: 0.22), startRadius: 0, endRadius: 300)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Theme.border, lineWidth: 1))
    }

    private var poseRail: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(AvatarPose.allCases) { candidate in
                    Button {
                        Haptics.tap()
                        pose = candidate
                    } label: {
                        VStack(spacing: 2) {
                            Text(candidate.label)
                                .font(.ui(12, .bold))
                            Text(candidate.japanese)
                                .font(.ui(10))
                                .opacity(0.7)
                        }
                        .foregroundStyle(pose == candidate ? Theme.cream : Theme.muted)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(pose == candidate ? AnyShapeStyle(Theme.crimson) : AnyShapeStyle(Theme.surface),
                                    in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(pose == candidate ? Color.clear : Theme.border, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Réglages

    private var buildSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "CARRURE")
            HStack(spacing: 8) {
                ForEach(AvatarBuild.allCases) { candidate in
                    Button {
                        Haptics.tap()
                        draft.build = candidate
                    } label: {
                        Text(candidate.label)
                            .font(.ui(13, .bold))
                            .foregroundStyle(draft.build == candidate ? Theme.cream : Theme.muted)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(draft.build == candidate ? AnyShapeStyle(Theme.crimson) : AnyShapeStyle(Theme.surface),
                                        in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .stroke(draft.build == candidate ? Color.clear : Theme.border, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    /// Le kimono blanc du débutant, puis les tenues des neuf maîtres.
    private var outfitSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "TENUE")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10)], spacing: 10) {
                ForEach(AvatarOutfit.all) { candidate in
                    let picked = draft.outfitID == candidate.id
                    Button {
                        Haptics.tap()
                        draft.outfitID = candidate.id
                    } label: {
                        VStack(spacing: 7) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(Color(hex: candidate.top))
                                    .frame(height: 26)
                                HStack(spacing: 0) {
                                    Rectangle().fill(Color(hex: candidate.accent))
                                    Rectangle().fill(Color(hex: candidate.bottom))
                                    if let cape = candidate.cape {
                                        Rectangle().fill(Color(hex: cape))
                                    }
                                }
                                .frame(height: 9)
                                .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
                                .padding(.horizontal, 10)
                                .offset(y: 6)
                            }
                            Text(candidate.name)
                                .font(.ui(11, .bold))
                                .foregroundStyle(picked ? Theme.text : Theme.muted)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .padding(8)
                        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(picked ? Theme.crimson : Theme.border, lineWidth: picked ? 2 : 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var hairSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "COIFFURE")
            HStack(spacing: 8) {
                ForEach(AvatarHair.allCases) { candidate in
                    Button {
                        Haptics.tap()
                        draft.hair = candidate
                    } label: {
                        Text(candidate.label)
                            .font(.ui(13, .bold))
                            .foregroundStyle(draft.hair == candidate ? Theme.cream : Theme.muted)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(draft.hair == candidate ? AnyShapeStyle(Theme.crimson) : AnyShapeStyle(Theme.surface),
                                        in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .stroke(draft.hair == candidate ? Color.clear : Theme.border, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func colorSection(title: String, choices: [UInt32], selected: UInt32,
                              pick: @escaping (UInt32) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: title)
            HStack(spacing: 10) {
                ForEach(choices.indices, id: \.self) { index in
                    let value = choices[index]
                    Button {
                        Haptics.tap()
                        pick(value)
                    } label: {
                        Circle()
                            .fill(Color(hex: value))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle().stroke(selected == value ? Theme.text : Theme.border,
                                                lineWidth: selected == value ? 3 : 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Les ceintures

    private var beltSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: "TA CEINTURE SUIT TA SÉRIE")
            VStack(spacing: 0) {
                ForEach(Belt.allCases) { candidate in
                    let earned = store.state.streak >= candidate.streakNeeded
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(Color(hex: candidate.color))
                            .frame(width: 26, height: 13)
                            .overlay(RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .stroke(Theme.border, lineWidth: 1))

                        VStack(alignment: .leading, spacing: 1) {
                            Text(candidate.label)
                                .font(.ui(13, .semibold))
                                .foregroundStyle(earned ? Theme.text : Theme.dim)
                            Text(candidate.japanese)
                                .font(.ui(10))
                                .foregroundStyle(Theme.muted)
                        }

                        Spacer(minLength: 8)

                        if candidate == store.belt {
                            Text("ACTUELLE")
                                .font(.ui(9, .bold))
                                .kerning(1.0)
                                .foregroundStyle(Theme.crimson)
                        } else {
                            Text("série \(candidate.streakNeeded)")
                                .font(.ui(11, .semibold))
                                .foregroundStyle(earned ? Theme.muted : Theme.dim)
                        }
                    }
                    .padding(.vertical, 10)
                    if candidate != Belt.allCases.last {
                        Rectangle().fill(Theme.border).frame(height: 1)
                    }
                }
            }
            .padding(.horizontal, 14)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Theme.border, lineWidth: 1))

            Text("La ceinture ne change pas qu'une couleur : elle allume l'aura, ajoute le bandeau, abîme le kimono et hérisse les cheveux.")
                .font(.ui(11))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
