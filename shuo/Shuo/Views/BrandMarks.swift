import SwiftUI

/// La marque : 说 calligraphié, avec son petit sceau cinabre.
///
/// C'est le tracé d'origine, découpé de la planche d'identité — la vraie
/// calligraphie, pas une police. Le catalogue porte deux versions, encre sur
/// ivoire et encre claire sur fond sombre, et bascule de l'une à l'autre tout
/// seul : rien à gérer ici.
///
/// `tools/preparer_marque.py` fabrique ces deux images à partir de la planche.
/// Si le tracé change, relancer ce script plutôt que de retoucher les fichiers
/// à la main.
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

/// La colonne chinoise de l'écran de lancement : le texte vertical, puis un
/// filet qui descend, comme la marge d'un rouleau.
struct InkColumn: View {
    var body: some View {
        VStack(spacing: 12) {
            Text(Theme.tagline)
                .font(Theme.hanzi(15))
                .tracking(6)
                .foregroundStyle(Theme.inkSoft)
                // Une colonne, pas une ligne : la largeur d'un seul caractère
                // suffit à la faire descendre.
                .lineLimit(nil)
                .frame(width: 20)
            Rectangle()
                .fill(Theme.inkSoft.opacity(0.45))
                .frame(width: 1, height: 54)
        }
        .accessibilityHidden(true)
    }
}
