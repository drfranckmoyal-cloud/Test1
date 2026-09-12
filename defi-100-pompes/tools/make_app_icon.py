#!/usr/bin/env python3
"""Génère l'icône du défi, à n'importe quelle taille.

Le motif reprend les deux éléments signature de l'app : l'anneau de
progression du jour et l'étoile qui marque un jour validé.
Rendu analytique (aucune dépendance), anticrénelage par couverture,
encodage PNG écrit à la main. Pas de canal alpha : iOS l'exige.

    python3 tools/make_app_icon.py sortie.png [taille]
"""

import math
import struct
import sys
import zlib

# Palette, identique à Design/Theme.swift
BG_TOP = (0xFF, 0x8A, 0x3D)
BG_BOTTOM = (0xDB, 0x3F, 0x06)
CREAM = (0xFF, 0xF3, 0xE6)
INK = (0x2A, 0x12, 0x04)

# Proportions, exprimées pour une icône de 1024 px
REF = 1024.0
RADIUS_R = 330.0
HALF_WIDTH_R = 50.0
STAR_OUTER_R = 200.0
START_DEG = -90.0        # départ en haut
SWEEP_DEG = 288.0        # 80 % du tour
STAR_INNER_RATIO = 0.48


def lerp(a, b, t):
    return a + (b - a) * t


def mix(c1, c2, t):
    return tuple(lerp(c1[i], c2[i], t) for i in range(3))


def over(dst, src, alpha):
    return tuple(lerp(dst[i], src[i], alpha) for i in range(3))


def coverage(signed_distance):
    """Couverture d'un pixel à partir d'une distance signée (négatif = dedans)."""
    return min(1.0, max(0.0, 0.5 - signed_distance))


def render(size):
    scale = size / REF
    center = size / 2.0
    radius = RADIUS_R * scale
    half_width = HALF_WIDTH_R * scale
    star_outer = STAR_OUTER_R * scale

    star = []
    for index in range(10):
        r = star_outer if index % 2 == 0 else star_outer * STAR_INNER_RATIO
        angle = math.radians(-90 + index * 36)
        star.append((center + r * math.cos(angle), center + r * math.sin(angle)))
    star_box = (min(p[0] for p in star) - 2, min(p[1] for p in star) - 2,
                max(p[0] for p in star) + 2, max(p[1] for p in star) + 2)

    def in_star(x, y):
        inside = False
        j = len(star) - 1
        for i in range(len(star)):
            xi, yi = star[i]
            xj, yj = star[j]
            if (yi > y) != (yj > y) and x < (xj - xi) * (y - yi) / (yj - yi) + xi:
                inside = not inside
            j = i
        return inside

    def star_coverage(px, py):
        if not (star_box[0] <= px <= star_box[2] and star_box[1] <= py <= star_box[3]):
            return 0.0
        hits = 0
        for sy in range(3):
            for sx in range(3):
                if in_star(px + (sx + 0.5) / 3.0, py + (sy + 0.5) / 3.0):
                    hits += 1
        return hits / 9.0

    caps = []
    for degrees in (START_DEG, START_DEG + SWEEP_DEG):
        angle = math.radians(degrees)
        caps.append((center + radius * math.cos(angle), center + radius * math.sin(angle)))

    rows = []
    for y in range(size):
        row = bytearray()
        for x in range(size):
            cx, cy = x + 0.5, y + 0.5

            t = (cx / size * 0.55) + (cy / size * 0.45)
            color = mix(BG_TOP, BG_BOTTOM, min(1.0, max(0.0, t)))

            dx, dy = cx - center, cy - center
            ring_sd = abs(math.hypot(dx, dy) - radius) - half_width

            track = coverage(ring_sd)
            if track > 0:
                color = over(color, INK, track * 0.16)

            delta = (math.degrees(math.atan2(dy, dx)) - START_DEG) % 360.0
            arc = coverage(ring_sd) if delta <= SWEEP_DEG else 0.0
            for cap_x, cap_y in caps:
                cap = coverage(math.hypot(cx - cap_x, cy - cap_y) - half_width)
                if cap > arc:
                    arc = cap
            if arc > 0:
                color = over(color, CREAM, arc)

            star_alpha = star_coverage(float(x), float(y))
            if star_alpha > 0:
                color = over(color, CREAM, star_alpha)

            row.append(int(color[0] + 0.5))
            row.append(int(color[1] + 0.5))
            row.append(int(color[2] + 0.5))
        rows.append(row)
    return rows


def write_png(path, rows, size):
    raw = bytearray()
    for row in rows:
        raw.append(0)          # filtre "None"
        raw.extend(row)

    def chunk(tag, data):
        payload = tag + data
        return (struct.pack(">I", len(data)) + payload
                + struct.pack(">I", zlib.crc32(payload) & 0xFFFFFFFF))

    header = struct.pack(">IIBBBBB", size, size, 8, 2, 0, 0, 0)  # 8 bits, RGB
    with open(path, "wb") as handle:
        handle.write(b"\x89PNG\r\n\x1a\n")
        handle.write(chunk(b"IHDR", header))
        handle.write(chunk(b"IDAT", zlib.compress(bytes(raw), 9)))
        handle.write(chunk(b"IEND", b""))


if __name__ == "__main__":
    output = sys.argv[1] if len(sys.argv) > 1 else "AppIcon.png"
    size = int(sys.argv[2]) if len(sys.argv) > 2 else 1024
    write_png(output, render(size), size)
    print("écrit", output, f"{size}x{size}")
