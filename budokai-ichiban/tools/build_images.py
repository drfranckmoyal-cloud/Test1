#!/usr/bin/env python3
"""Verse la banque d'images de Franck dans le catalogue de l'app.

Source principale : `~/Desktop/images-anime-HQ`, rangée par programme.
Source de secours : `~/Desktop/anime_bank`, rangée par univers — elle ne sert
que là où la première n'a rien.

Chaque étape d'un programme reçoit son image, chaque programme son décor et
son logo d'univers. Les fichiers sont redimensionnés à la taille utile d'un
iPhone : au-delà, c'est du poids pour rien.

    python3 tools/build_images.py [--dry]

Relancer la commande après avoir remplacé les images suffit à tout refaire :
le catalogue est réécrit de zéro.
"""

import json
import os
import re
import shutil
import sys
from glob import glob

from PIL import Image

HOME = os.path.expanduser("~")
MAIN = os.path.join(HOME, "Desktop", "images-anime-HQ")
SIDE = os.path.join(HOME, "Desktop", "anime_bank")
CATALOG = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                       "BudokaiIchi", "Assets.xcassets")

# Largeur maximale à l'écran, en pixels réels.
STAGE_WIDTH = 1200
ENV_WIDTH = 1200
LOGO_WIDTH = 600
QUALITY = 86

# dossier source -> (identifiant du programme, univers dans la banque de secours)
PROGRAMS = [
    ("01_saitama_transformation_physique", "saitama", "one_punch_man"),
    ("02_goku_progression_extreme", "goku", "dragon_ball"),
    ("03_rock_lee_explosivite", "rocklee", "naruto"),
    ("04_kenshiro_force_pure", "kenshiro", "hokuto_no_ken"),
    ("05_ichigo_objectifs_bankai", "ichigo", "bleach"),
    ("06_minato_vitesse", "minato", "naruto"),
    ("07_levi_gainage", "levi", "attack_on_titan"),
    ("08_luffy_souplesse_mobilite", "luffy", "one_piece"),
    ("09_naruto_resilience", "naruto", "naruto"),
]

# Les décors et les logos suivent l'ordre des programmes.
ENVIRONMENTS = ["201", "202", "203", "204", "205", "206", "207", "208", "209"]
LOGOS = ["101", "102", "103", "104", "105", "106", "107"]
LOGO_BY_UNIVERSE = {
    "one_punch_man": "101", "dragon_ball": "102", "naruto": "103",
    "hokuto_no_ken": "104", "bleach": "105", "attack_on_titan": "106",
    "one_piece": "107",
}

CONTENTS = {
    "images": [{"idiom": "universal", "filename": "image.jpg", "scale": "1x"},
               {"idiom": "universal", "scale": "2x"},
               {"idiom": "universal", "scale": "3x"}],
    "info": {"author": "xcode", "version": 1},
}


def emit(name, source, max_width, dry):
    """Écrit une image du catalogue, réduite si elle dépasse la taille utile."""
    folder = os.path.join(CATALOG, f"{name}.imageset")
    image = Image.open(source).convert("RGB")
    if image.width > max_width:
        height = round(image.height * max_width / image.width)
        image = image.resize((max_width, height), Image.LANCZOS)
    if dry:
        print(f"  {name:24s} {image.width}x{image.height}  <- {os.path.basename(source)}")
        return 0
    shutil.rmtree(folder, ignore_errors=True)
    os.makedirs(folder)
    path = os.path.join(folder, "image.jpg")
    image.save(path, "JPEG", quality=QUALITY, optimize=True, progressive=True)
    with open(os.path.join(folder, "Contents.json"), "w") as handle:
        json.dump(CONTENTS, handle, indent=2)
    return os.path.getsize(path)


def side_match(universe, character, index):
    """Cherche l'étape `index` du personnage dans la banque de secours."""
    for path in glob(os.path.join(SIDE, universe, "characters", f"{character}_*")):
        if re.search(rf"{character}_0*{index}(_|\.)", os.path.basename(path)):
            return path
    return None


def main():
    dry = "--dry" in sys.argv
    if not os.path.isdir(MAIN):
        sys.exit(f"Source principale introuvable : {MAIN}")

    # le catalogue est réécrit : on efface les images d'un import précédent
    if not dry:
        for old in glob(os.path.join(CATALOG, "stage_*.imageset")) \
                 + glob(os.path.join(CATALOG, "tile_*.imageset")) \
                 + glob(os.path.join(CATALOG, "env_*.imageset")) \
                 + glob(os.path.join(CATALOG, "logo_*.imageset")):
            shutil.rmtree(old, ignore_errors=True)

    total = 0
    written = 0
    fallback = 0

    for folder, pid, universe in PROGRAMS:
        steps = sorted(glob(os.path.join(MAIN, folder, "etapes", "*.jpg")))
        for index, step in enumerate(steps, start=1):
            source = step
            # la banque de secours ne sert que si la principale n'a rien
            if not os.path.exists(source):
                source = side_match(universe, pid, index)
                if source is None:
                    print(f"  MANQUE {pid} étape {index}")
                    continue
                fallback += 1
            total += emit(f"stage_{pid}_{index}", source, STAGE_WIDTH, dry)
            written += 1

    # Image de vignette : un fichier « vignette.* » posé à la racine d'un
    # dossier de programme remplace l'étape servant d'image de présentation.
    for folder, pid, _ in PROGRAMS:
        found = sorted(glob(os.path.join(MAIN, folder, "vignette.*")))
        if found:
            total += emit(f"tile_{pid}", found[0], STAGE_WIDTH, dry)
            written += 1

    envs = sorted(glob(os.path.join(MAIN, "11_environnements", "environnements", "*.jpg")))
    for (_, pid, _), env in zip(PROGRAMS, envs):
        total += emit(f"env_{pid}", env, ENV_WIDTH, dry)
        written += 1

    logos = sorted(glob(os.path.join(MAIN, "10_logos", "logos", "*.jpg")))
    by_number = {os.path.basename(p)[:3]: p for p in logos}
    for universe, number in LOGO_BY_UNIVERSE.items():
        if number in by_number:
            total += emit(f"logo_{universe}", by_number[number], LOGO_WIDTH, dry)
            written += 1

    print(f"\n{written} images écrites"
          + (f", dont {fallback} tirées de la banque de secours" if fallback else "")
          + (f" — {total / 1_048_576:.1f} Mo" if not dry else " (essai à blanc)"))


if __name__ == "__main__":
    main()
