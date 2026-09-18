import SwiftUI

/// La marque : le cercle au pinceau, le disque rouge, 说.
///
/// C'est le tracé d'origine, découpé de l'icône livrée — le vrai grain du
/// pinceau, pas une approximation vectorielle. Le catalogue porte deux
/// versions, encre sur papier et encre claire sur fond sombre, et bascule de
/// l'une à l'autre tout seul : rien à gérer ici.
///
/// `tools/preparer_marque.py` fabrique ces deux images à partir des PNG
/// d'origine. Si le tracé change, relancer ce script plutôt que de retoucher
/// les fichiers à la main.
struct ShuoMark: View {
    var size: CGFloat = 220

    var body: some View {
        Image("ShuoMark")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityLabel("Shuō")
    }
}

/// Le sceau : un carré vermillon, le caractère réservé en clair dedans.
///
/// Celui-ci reste dessiné : il est trop petit pour qu'une image y gagne quoi
/// que ce soit, et il doit pouvoir porter n'importe quel caractère.
struct SealMark: View {
    var side: CGFloat = 34
    var glyph: String = "说"

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: side * 0.10, style: .continuous)
                .fill(Theme.seal)
            Text(glyph)
                .font(Theme.hanzi(side * 0.62))
                .foregroundStyle(Theme.paper)
        }
        .frame(width: side, height: side)
        .accessibilityHidden(true)
    }
}

/// Le logo horizontal : la marque, puis le nom et la signature.
struct HorizontalLogo: View {
    var markSize: CGFloat = 64

    var body: some View {
        HStack(spacing: markSize * 0.26) {
            ShuoMark(size: markSize)
            VStack(alignment: .leading, spacing: 4) {
                Text("Shuō")
                    .font(Theme.wordmark(markSize * 0.46))
                    .foregroundStyle(Theme.ink)
                Text(Theme.slogan)
                    .font(.system(size: markSize * 0.17, weight: .regular))
                    .tracking(markSize * 0.055)
                    .foregroundStyle(Theme.inkSoft)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Shuō — \(Theme.slogan)")
    }
}
