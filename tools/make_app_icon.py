#!/usr/bin/env python3
"""Génère l'icône de l'app (1024x1024, sans canal alpha, comme l'exige iOS).

Le motif reprend les deux éléments signature de l'app : l'anneau de
progression du jour et l'étoile qui marque un jour validé.
Rendu analytique (pas de dépendance externe), anticrénelage par couverture.
"""

import math
import struct
import zlib

SIZE = 1024

# Palette, identique à Design/Theme.swift
BG_TOP = (0xFF, 0x8A, 0x3D)      # orangeLight
BG_BOTTOM = (0xDB, 0x3F, 0x06)   # celebrationGradient, fin
CREAM = (0xFF, 0xF3, 0xE6)       # creamOnOrange
INK = (0x2A, 0x12, 0x04)         # ink

CENTER = SIZE / 2
RADIUS = 330.0          # rayon de la ligne médiane de l'anneau
HALF_WIDTH = 50.0       # demi-épaisseur du trait
START_DEG = -90.0       # départ en haut
SWEEP_DEG = 288.0       # 80 % du tour
STAR_OUTER = 200.0
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


def star_polygon():
    points = []
    for index in range(10):
        radius = STAR_OUTER if index % 2 == 0 else STAR_OUTER * STAR_INNER_RATIO
        angle = math.radians(-90 + index * 36)
        points.append((CENTER + radius * math.cos(angle),
                       CENTER + radius * math.sin(angle)))
    return points


STAR = star_polygon()
STAR_BBOX = (
    min(p[0] for p in STAR) - 2, min(p[1] for p in STAR) - 2,
    max(p[0] for p in STAR) + 2, max(p[1] for p in STAR) + 2,
)


def in_star(x, y):
    inside = False
    count = len(STAR)
    j = count - 1
    for i in range(count):
        xi, yi = STAR[i]
        xj, yj = STAR[j]
        if (yi > y) != (yj > y):
            if x < (xj - xi) * (y - yi) / (yj - yi) + xi:
                inside = not inside
        j = i
    return inside


def star_coverage(px, py):
    """3x3 sous-échantillons, uniquement dans la boîte de l'étoile."""
    if not (STAR_BBOX[0] <= px <= STAR_BBOX[2] and STAR_BBOX[1] <= py <= STAR_BBOX[3]):
        return 0.0
    hits = 0
    for sy in range(3):
        for sx in range(3):
            if in_star(px + (sx + 0.5) / 3.0, py + (sy + 0.5) / 3.0):
                hits += 1
    return hits / 9.0


# Centres des deux extrémités arrondies de l'arc
CAPS = []
for degrees in (START_DEG, START_DEG + SWEEP_DEG):
    angle = math.radians(degrees)
    CAPS.append((CENTER + RADIUS * math.cos(angle), CENTER + RADIUS * math.sin(angle)))


def arc_covers_angle(degrees):
    delta = (degrees - START_DEG) % 360.0
    return delta <= SWEEP_DEG


def render_row(y):
    row = bytearray()
    py = y + 0.0
    for x in range(SIZE):
        px = x + 0.0
        cx, cy = px + 0.5, py + 0.5

        # Fond : dégradé diagonal
        t = (cx / SIZE * 0.55) + (cy / SIZE * 0.45)
        color = mix(BG_TOP, BG_BOTTOM, min(1.0, max(0.0, t)))

        dx, dy = cx - CENTER, cy - CENTER
        distance = math.hypot(dx, dy)
        ring_sd = abs(distance - RADIUS) - HALF_WIDTH

        # Rail de l'anneau (le tour complet, à peine plus sombre)
        track = coverage(ring_sd)
        if track > 0:
            color = over(color, INK, track * 0.16)

        # Arc de progression, avec extrémités arrondies
        arc = coverage(ring_sd) if arc_covers_angle(math.degrees(math.atan2(dy, dx))) else 0.0
        for cap_x, cap_y in CAPS:
            cap = coverage(math.hypot(cx - cap_x, cy - cap_y) - HALF_WIDTH)
            if cap > arc:
                arc = cap
        if arc > 0:
            color = over(color, CREAM, arc)

        # Étoile centrale
        star = star_coverage(px, py)
        if star > 0:
            color = over(color, CREAM, star)

        row.append(int(color[0] + 0.5))
        row.append(int(color[1] + 0.5))
        row.append(int(color[2] + 0.5))
    return row


def write_png(path, rows):
    raw = bytearray()
    for row in rows:
        raw.append(0)          # filtre "None"
        raw.extend(row)

    def chunk(tag, data):
        payload = tag + data
        return (struct.pack(">I", len(data)) + payload
                + struct.pack(">I", zlib.crc32(payload) & 0xFFFFFFFF))

    header = struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0)  # 8 bits, RGB
    with open(path, "wb") as handle:
        handle.write(b"\x89PNG\r\n\x1a\n")
        handle.write(chunk(b"IHDR", header))
        handle.write(chunk(b"IDAT", zlib.compress(bytes(raw), 9)))
        handle.write(chunk(b"IEND", b""))


if __name__ == "__main__":
    import sys
    output = sys.argv[1] if len(sys.argv) > 1 else "AppIcon.png"
    write_png(output, [render_row(y) for y in range(SIZE)])
    print("écrit", output)
