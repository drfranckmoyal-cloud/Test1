#!/usr/bin/env python3
"""Génère l'icône de Shuō : le caractère 说 à l'encre sur un fond papier.

Le motif reprend l'écran de lancement : un grand 说 sombre sur un fond
crème, et le petit sceau vermillon en bas à droite.

    python3 tools/make_app_icon.py sortie.png [taille]

Dépend de Pillow et d'une police CJK (WenQuanYi Zen Hei sur Linux,
PingFang / Songti sur macOS). Le script cherche la première disponible.
"""

import sys

from PIL import Image, ImageDraw, ImageFont

# Palette, identique à Design/Theme.swift
PAPER = (0xF7, 0xF1, 0xE6)
INK = (0x1C, 0x1A, 0x17)
SEAL = (0xC0, 0x39, 0x2B)

FONT_CANDIDATES = [
    "/System/Library/Fonts/Supplemental/Songti.ttc",
    "/System/Library/Fonts/PingFang.ttc",
    "/System/Library/Fonts/Supplemental/Hei.ttf",
    "/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc",
    "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
]


def find_font(size):
    for path in FONT_CANDIDATES:
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    raise SystemExit("Aucune police CJK trouvée : installer Noto Sans CJK ou WenQuanYi.")


def render(size):
    image = Image.new("RGB", (size, size), PAPER)
    draw = ImageDraw.Draw(image)

    font = find_font(int(size * 0.58))
    box = draw.textbbox((0, 0), "说", font=font)
    x = (size - (box[2] - box[0])) / 2 - box[0]
    y = (size - (box[3] - box[1])) / 2 - box[1]
    draw.text((x, y), "说", font=font, fill=INK)

    # Le sceau : un carré vermillon, posé en bas à droite comme sur un
    # rouleau. Purement décoratif, il ne porte aucun caractère.
    side = size * 0.10
    margin = size * 0.07
    draw.rounded_rectangle(
        [size - margin - side, size - margin - side, size - margin, size - margin],
        radius=side * 0.14,
        fill=SEAL,
    )
    return image


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "AppIcon.png"
    px = int(sys.argv[2]) if len(sys.argv) > 2 else 1024
    render(px).save(out, "PNG")
    print(f"{out} — {px}×{px}")
