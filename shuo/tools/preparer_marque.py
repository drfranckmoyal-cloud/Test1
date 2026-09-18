#!/usr/bin/env python3
"""Prépare l'icône et la marque de Shuō à partir des PNG d'origine.

Les fichiers livrés ne sont pas directement utilisables sur iOS, pour deux
raisons :

1. **Les coins sont déjà arrondis**, sur un fond gris clair. iOS applique son
   propre masque : un coin arrondi dans un coin arrondi se voit tout de suite,
   avec un liseré clair autour de l'icône. Il faut donc du fond jusqu'au bord.
2. **Le mot « Shuō » est dans l'icône.** À 40 px c'est une tache illisible, et
   Apple déconseille le texte dans une icône. Il est retiré ; le nom s'affiche
   déjà sous l'icône, écrit par iOS.

Le script produit aussi la marque **détourée**, à fond transparent, pour que
l'app affiche exactement le même tracé que l'icône — le vrai grain de pinceau,
pas une approximation vectorielle.

    python3 tools/preparer_marque.py <dossier des PNG d'origine>

Le détourage suppose un fond uni : on retrouve l'opacité et la couleur réelle
de chaque pixel en « démélangeant » ce qui a été peint par-dessus le fond.
"""

import sys
from pathlib import Path

from PIL import Image

# Repères mesurés sur les fichiers 1024 d'origine.
# (gauche, haut, droite, bas) de la marque seule, sans le mot « Shuō ».
SOURCES = {
    "light": {
        "fichier": "icon_light_1024x1024.png",
        "fond": (243, 239, 231),
        "marque": (80, 62, 934, 814),
        "clair": True,
    },
    "dark": {
        "fichier": "icon_dark_1024x1024.png",
        "fond": (12, 12, 12),
        "marque": (93, 62, 907, 802),
        "clair": False,
    },
}

# En dessous de ce seuil, ce n'est plus de l'encre mais le grain du papier.
SEUIL_BAS = 0.055
SEUIL_HAUT = 0.14

ICON_SIZE = 1024
# Part de l'icône occupée par la marque. En dessous l'icône paraît timide,
# au-dessus elle touche l'arrondi que iOS applique.
MARK_RATIO = 0.84


def detourer(image, fond, sur_fond_clair):
    """Rend le fond transparent et retrouve la couleur réelle du tracé.

    Chaque pixel visible vaut `a × couleur + (1 - a) × fond`. On cherche le `a`
    le plus grand que chaque canal autorise, puis on en déduit la couleur.
    """
    source = image.convert("RGB")
    largeur, hauteur = source.size
    sortie = Image.new("RGBA", (largeur, hauteur))
    pixels_source = source.load()
    pixels_sortie = sortie.load()

    for y in range(hauteur):
        for x in range(largeur):
            pixel = pixels_source[x, y]
            alpha = 0.0
            for canal in range(3):
                fond_c = fond[canal]
                if sur_fond_clair:
                    # Le tracé est plus sombre que le papier.
                    denom = fond_c if fond_c > 0 else 1
                    part = (fond_c - pixel[canal]) / denom
                else:
                    # Le tracé est plus clair que le fond.
                    denom = 255 - fond_c if fond_c < 255 else 1
                    part = (pixel[canal] - fond_c) / denom
                alpha = max(alpha, part)

            # Le papier n'est pas parfaitement uni : son grain ressort en
            # opacités très faibles, et laisse un rectangle fantôme autour de la
            # marque. On plancher ce bruit à zéro, en remontant en douceur pour
            # ne pas hacher le bord des traits secs.
            alpha = min(max((alpha - SEUIL_BAS) / (SEUIL_HAUT - SEUIL_BAS), 0.0), 1.0)
            if alpha <= 0.0:
                pixels_sortie[x, y] = (0, 0, 0, 0)
                continue

            couleur = []
            for canal in range(3):
                valeur = (pixel[canal] - (1 - alpha) * fond[canal]) / alpha
                couleur.append(int(min(max(valeur, 0), 255)))
            pixels_sortie[x, y] = (couleur[0], couleur[1], couleur[2], int(alpha * 255))

    return sortie


def icone(marque_detouree, fond):
    """L'icône d'app : fond jusqu'au bord, marque centrée, sans le mot.

    On repose la marque **détourée** sur un fond uni plutôt que de recoller le
    rectangle d'origine : le grain du papier ne se raccorde jamais exactement
    d'un bord à l'autre, et la couture se verrait comme une bande en haut et en
    bas de l'icône.
    """
    cible = int(ICON_SIZE * MARK_RATIO)
    echelle = cible / max(marque_detouree.size)
    taille = (
        max(1, round(marque_detouree.size[0] * echelle)),
        max(1, round(marque_detouree.size[1] * echelle)),
    )
    marque = marque_detouree.resize(taille, Image.LANCZOS)

    canevas = Image.new("RGBA", (ICON_SIZE, ICON_SIZE), fond + (255,))
    canevas.alpha_composite(
        marque,
        ((ICON_SIZE - taille[0]) // 2, (ICON_SIZE - taille[1]) // 2),
    )
    return canevas.convert("RGB")


def main(dossier_source):
    racine = Path(__file__).resolve().parent.parent
    assets = racine / "Shuo/Assets.xcassets"
    icones = assets / "AppIcon.appiconset"
    marques = assets / "ShuoMark.imageset"
    marques.mkdir(parents=True, exist_ok=True)

    for variante, reglage in SOURCES.items():
        chemin = Path(dossier_source) / reglage["fichier"]
        if not chemin.exists():
            raise SystemExit(f"Fichier introuvable : {chemin}")
        source = Image.open(chemin).convert("RGB")
        fond = reglage["fond"]
        boite = reglage["marque"]

        detouree = detourer(source.crop(boite), fond, reglage["clair"])

        suffixe = "" if variante == "light" else "-Dark"
        sortie_icone = icones / f"AppIcon{suffixe}.png"
        icone(detouree, fond).save(sortie_icone, "PNG")
        print(f"{sortie_icone.relative_to(racine)} — {ICON_SIZE}×{ICON_SIZE}")

        sortie_marque = marques / f"mark-{variante}.png"
        detouree.save(sortie_marque, "PNG")
        print(f"{sortie_marque.relative_to(racine)} — {detouree.size[0]}×{detouree.size[1]}, fond transparent")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise SystemExit("Usage : python3 tools/preparer_marque.py <dossier des PNG d'origine>")
    main(sys.argv[1])
