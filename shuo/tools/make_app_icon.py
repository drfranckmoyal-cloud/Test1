#!/usr/bin/env python3
"""Génère l'icône de Shuō, claire et sombre, à n'importe quelle taille.

Le motif reprend la planche d'identité : le cercle tracé au pinceau, le disque
rouge posé en haut à droite, et 说 au centre.

    python3 tools/make_app_icon.py

    python3 tools/make_app_icon.py sortie.png 1024 --dark

La géométrie est la même que celle de `Shuo/Views/BrandMarks.swift` — si l'une
change, changer l'autre. Rendu quatre fois trop grand puis réduit : c'est ce qui
donne des bords propres sans bibliothèque de dessin vectoriel.

Dépend de Pillow et d'une police CJK (PingFang ou Songti sur macOS, WenQuanYi
sur Linux). Le script cherche la première disponible.
"""

import math
import sys

from PIL import Image, ImageDraw, ImageFont

# Palette, identique à Design/Theme.swift
PAPER = (0xF5, 0xF0, 0xE6)
INK = (0x1A, 0x19, 0x17)
PAPER_DARK = (0x12, 0x11, 0x10)
INK_DARK = (0xF3, 0xEE, 0xE3)
SEAL = (0xCC, 0x2E, 0x26)
SEAL_DEEP = (0xA8, 0x1F, 0x18)

# Géométrie, en fraction du côté — les mêmes nombres que dans BrandMarks.swift
GAP = 0.09
START_ANGLE = -58.0
THICKNESS = 0.085
RADIUS_RATIO = 0.86
MARK_RATIO = 0.70      # la marque n'occupe pas toute l'icône
SUN_RATIO = 0.34       # diamètre du disque, en fraction de la marque
SUN_OFFSET = 0.30      # décalage du disque, en fraction de la marque
GLYPH_RATIO = 0.41

SUPERSAMPLE = 4

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


def width_profile(t):
    """Le profil d'épaisseur du trait, de l'attaque à la fuite."""
    attack = min(t / 0.10, 1)
    release = min((1 - t) / 0.24, 1)
    body = 0.70 + 0.30 * math.sin(t * math.pi)
    return max(0.06, attack * (release ** 1.7) * body)


def enso_polygon(center, side):
    """Le contour fermé du cercle au pinceau : bord extérieur puis intérieur."""
    radius = side / 2 * RADIUS_RATIO
    sweep = (1 - GAP) * 2 * math.pi
    max_width = side * THICKNESS
    steps = 400

    outer, inner = [], []
    for step in range(steps + 1):
        t = step / steps
        angle = math.radians(START_ANGLE) + t * sweep
        width = max_width * width_profile(t)
        wobble = radius * 0.013 * math.sin(t * 9.4 + 0.7)
        r = radius + wobble
        outer.append((
            center[0] + math.cos(angle) * (r + width / 2),
            center[1] + math.sin(angle) * (r + width / 2),
        ))
        inner.append((
            center[0] + math.cos(angle) * (r - width / 2),
            center[1] + math.sin(angle) * (r - width / 2),
        ))
    return outer + inner[::-1]


def draw_sun(draw, center, diameter):
    """Le disque rouge : de l'encre posée à plat.

    Seul le bord extérieur fonce un peu, là où le pigment s'accumule en
    séchant. Un dégradé plus marqué donnerait une bille en trois dimensions,
    ce qui n'a rien à faire sur une planche à l'encre.
    """
    steps = 40
    for index in range(steps, 0, -1):
        ratio = index / steps
        r = diameter / 2 * ratio
        # Plat sur 90 % du rayon, puis l'accumulation du bord.
        edge = max(0.0, (ratio - 0.90) / 0.10)
        color = tuple(
            round(SEAL[c] + (SEAL_DEEP[c] - SEAL[c]) * edge) for c in range(3)
        )
        draw.ellipse(
            [center[0] - r, center[1] - r, center[0] + r, center[1] + r],
            fill=color,
        )


def render(size, dark=False):
    scale = size * SUPERSAMPLE
    background = PAPER_DARK if dark else PAPER
    ink = INK_DARK if dark else INK

    image = Image.new("RGB", (scale, scale), background)
    draw = ImageDraw.Draw(image)

    mark = scale * MARK_RATIO
    center = (scale / 2, scale / 2)

    draw.polygon(enso_polygon(center, mark), fill=ink)

    sun_center = (center[0] + mark * SUN_OFFSET, center[1] - mark * SUN_OFFSET)
    draw_sun(draw, sun_center, mark * SUN_RATIO)

    font = find_font(int(mark * GLYPH_RATIO))
    box = draw.textbbox((0, 0), "说", font=font)
    x = center[0] - (box[2] - box[0]) / 2 - box[0]
    y = center[1] - (box[3] - box[1]) / 2 - box[1]
    draw.text((x, y), "说", font=font, fill=ink)

    return image.resize((size, size), Image.LANCZOS)


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    dark = "--dark" in sys.argv

    if not args:
        # Sans argument : les deux icônes, à leur place dans le catalogue.
        base = "Shuo/Assets.xcassets/AppIcon.appiconset"
        for name, is_dark in (("AppIcon.png", False), ("AppIcon-Dark.png", True)):
            render(1024, dark=is_dark).save(f"{base}/{name}", "PNG")
            print(f"{base}/{name} — 1024×1024")
    else:
        out = args[0]
        px = int(args[1]) if len(args) > 1 else 1024
        render(px, dark=dark).save(out, "PNG")
        print(f"{out} — {px}×{px}{' (sombre)' if dark else ''}")
