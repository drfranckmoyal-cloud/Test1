#!/usr/bin/env python3
"""Prépare l'icône et la marque de Shuō à partir de la planche d'identité.

La planche livrée n'est pas utilisable telle quelle sur iOS, pour trois
raisons :

1. **Les coins sont déjà arrondis**, avec une ombre portée, sur une page plus
   claire. iOS applique son propre masque : un coin arrondi dans un coin
   arrondi se voit tout de suite, avec un liseré autour de l'icône.
2. **Le sceau touche le bord droit** (x = 996 sur 1024). Le masque d'iOS rogne
   les angles : le sceau y perdrait un coin.
3. **Le fichier sombre livré est inexploitable** : c'est un agrandissement
   d'une vignette de la planche, flou, mal cadré, avec la tuile voisine visible
   sur la gauche. La version sombre est donc reconstruite depuis la planche
   claire, qui, elle, est nette.

Le script produit aussi la marque **détourée**, à fond transparent, pour que
l'app affiche exactement la même calligraphie que l'icône.

    python3 tools/preparer_marque.py identite-source

Le détourage suppose un fond uni : on retrouve l'opacité réelle de chaque pixel
en « démélangeant » ce qui a été peint par-dessus l'ivoire.
"""

import sys
from pathlib import Path

import numpy as np
from PIL import Image

SOURCE = "icon_light_1024x1024.png"

# Repères mesurés sur la planche claire.
FOND_IVOIRE = (244, 240, 232)
FOND_SOMBRE = (18, 17, 16)
ENCRE_CLAIRE = (243, 238, 227)      # l'encre devient crème sur fond sombre
CALLIGRAPHIE = (130, 140, 997, 905)  # gauche, haut, droite, bas
SCEAU = (870, 728, 1002, 908)

ICON_SIZE = 1024
# Part de l'icône occupée par la marque. Le sceau tombant dans un angle, il
# faut lui laisser de quoi survivre à l'arrondi que iOS applique.
MARK_RATIO = 0.80

# En dessous de ce seuil, ce n'est plus de l'encre mais le grain du papier.
SEUIL_BAS = 0.05
SEUIL_HAUT = 0.13


def detourer(zone, fond):
    """Rend le fond transparent et retrouve la couleur réelle du tracé.

    Chaque pixel visible vaut `a × couleur + (1 - a) × fond`. On cherche le `a`
    le plus grand que chaque canal autorise, puis on en déduit la couleur. Les
    pixels *plus clairs* que le fond — le halo laissé par l'agrandissement de la
    planche — retombent naturellement à zéro et disparaissent.
    """
    pixels = zone.astype(float)
    fond = np.array(fond, dtype=float)

    part = (fond - pixels) / np.maximum(fond, 1)
    alpha = np.clip(part.max(axis=2), 0, 1)
    alpha = np.clip((alpha - SEUIL_BAS) / (SEUIL_HAUT - SEUIL_BAS), 0, 1)

    sur = alpha[..., None]
    couleur = np.where(sur > 0, (pixels - (1 - sur) * fond) / np.maximum(sur, 1e-6), 0)
    couleur = np.clip(couleur, 0, 255)

    return couleur.astype(np.uint8), (alpha * 255).astype(np.uint8)


def masque_sceau(zone_rgb):
    """L'empreinte pleine du sceau, caractère réservé compris.

    Le caractère creusé dans le sceau est de la couleur du papier. Détouré tel
    quel, il deviendrait un trou — invisible sur l'ivoire de l'app, mais béant
    sur fond sombre. On remplit donc chaque ligne entre son premier et son
    dernier pixel rouge, ce qui rend le caractère au sceau sans abîmer ses
    angles arrondis.
    """
    canaux = zone_rgb.astype(int)
    rouge = (canaux[..., 0] - np.maximum(canaux[..., 1], canaux[..., 2]) > 45) & (canaux[..., 0] > 110)
    plein = np.zeros(rouge.shape, bool)
    for y in range(rouge.shape[0]):
        xs = np.nonzero(rouge[y])[0]
        if len(xs):
            plein[y, xs.min():xs.max() + 1] = True
    return plein


def poser(marque, fond):
    """Centre la marque sur le fond, à la taille d'une icône."""
    cible = int(ICON_SIZE * MARK_RATIO)
    echelle = cible / max(marque.size)
    taille = (max(1, round(marque.width * echelle)), max(1, round(marque.height * echelle)))
    redimensionnee = marque.resize(taille, Image.LANCZOS)

    canevas = fond.convert("RGBA")
    canevas.alpha_composite(
        redimensionnee,
        ((ICON_SIZE - taille[0]) // 2, (ICON_SIZE - taille[1]) // 2),
    )
    return canevas.convert("RGB")


def main(dossier_source):
    racine = Path(__file__).resolve().parent.parent
    icones = racine / "Shuo/Assets.xcassets/AppIcon.appiconset"
    marques = racine / "Shuo/Assets.xcassets/ShuoMark.imageset"
    marques.mkdir(parents=True, exist_ok=True)

    chemin = Path(dossier_source) / SOURCE
    if not chemin.exists():
        raise SystemExit(f"Fichier introuvable : {chemin}")
    source = Image.open(chemin).convert("RGB")

    zone = np.asarray(source.crop(CALLIGRAPHIE))
    couleur, alpha = detourer(zone, FOND_IVOIRE)

    # Le sceau, repéré dans le repère de la calligraphie découpée.
    gx, gy = CALLIGRAPHIE[0], CALLIGRAPHIE[1]
    sx0, sy0, sx1, sy1 = SCEAU[0] - gx, SCEAU[1] - gy, SCEAU[2] - gx, SCEAU[3] - gy
    sx0, sy0 = max(sx0, 0), max(sy0, 0)
    sx1, sy1 = min(sx1, zone.shape[1]), min(sy1, zone.shape[0])
    empreinte = masque_sceau(zone[sy0:sy1, sx0:sx1])

    # Version claire : le détourage brut suffit. Le caractère réservé du sceau
    # laisse voir le papier de l'app, qui est le même ivoire.
    claire = Image.fromarray(np.dstack([couleur, alpha]), "RGBA")

    # Version sombre : l'encre devient crème, le sceau garde ses couleurs et
    # son caractère réservé.
    couleur_sombre = couleur.copy()
    alpha_sombre = alpha.copy()
    hors_sceau = np.ones(alpha.shape, bool)
    hors_sceau[sy0:sy1, sx0:sx1] &= ~empreinte
    couleur_sombre[hors_sceau] = ENCRE_CLAIRE
    bloc = couleur_sombre[sy0:sy1, sx0:sx1]
    bloc[empreinte] = zone[sy0:sy1, sx0:sx1][empreinte]
    couleur_sombre[sy0:sy1, sx0:sx1] = bloc
    bloc_alpha = alpha_sombre[sy0:sy1, sx0:sx1]
    bloc_alpha[empreinte] = 255
    alpha_sombre[sy0:sy1, sx0:sx1] = bloc_alpha
    sombre = Image.fromarray(np.dstack([couleur_sombre, alpha_sombre]), "RGBA")

    claire.save(marques / "mark-light.png", "PNG")
    sombre.save(marques / "mark-dark.png", "PNG")
    print(f"ShuoMark.imageset/mark-light.png — {claire.width}×{claire.height}, fond transparent")
    print(f"ShuoMark.imageset/mark-dark.png  — {sombre.width}×{sombre.height}, fond transparent")

    poser(claire, Image.new("RGB", (ICON_SIZE, ICON_SIZE), FOND_IVOIRE)).save(icones / "AppIcon.png", "PNG")
    poser(sombre, Image.new("RGB", (ICON_SIZE, ICON_SIZE), FOND_SOMBRE)).save(icones / "AppIcon-Dark.png", "PNG")
    print(f"AppIcon.png      — {ICON_SIZE}×{ICON_SIZE}, ivoire jusqu'au bord")
    print(f"AppIcon-Dark.png — {ICON_SIZE}×{ICON_SIZE}, reconstruite depuis la planche claire")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise SystemExit("Usage : python3 tools/preparer_marque.py <dossier de la planche>")
    main(sys.argv[1])
