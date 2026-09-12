#!/usr/bin/env python3
"""Icône de Budokai Ichi : le sceau et le trait 一.

Un carré vermillon incliné, comme un sceau japonais, et dedans le trait
unique de « ichi » tracé au pinceau — épais à l'attaque, gonflé à la
pression finale, effilé entre les deux.

Rendu analytique, anticrénelage par couverture, encodage PNG écrit à la
main : aucune dépendance, et l'icône reste modifiable depuis les
constantes ci-dessous.

    python3 tools/make_budokai_icon.py sortie.png [taille]
"""

import math
import struct
import sys
import zlib

REF = 1024.0
GROUND = (0x0B, 0x0A, 0x0C)
SEAL = (0xE0, 0x2B, 0x20)
SEAL_DEEP = (0xA8, 0x16, 0x0E)
CREAM = (0xFF, 0xF3, 0xE6)

SEAL_SIDE_R = 690.0
SEAL_ANGLE = math.radians(-4.0)
STROKE_LEFT_R = 232.0
STROKE_RIGHT_R = 792.0
STROKE_Y_R = 545.0
STROKE_RISE_R = 30.0        # le trait monte légèrement vers la droite
STROKE_BASE_R = 44.0        # demi-épaisseur de référence


def lerp(a, b, t):
    return a + (b - a) * t


def mix(c1, c2, t):
    return tuple(lerp(c1[i], c2[i], t) for i in range(3))


def over(dst, src, alpha):
    return tuple(lerp(dst[i], src[i], alpha) for i in range(3))


def coverage(distance):
    """Couverture d'un pixel : 1 dedans, 0 dehors, dégradé sur un pixel."""
    return min(1.0, max(0.0, 0.5 - distance))


def stroke_half_width(t, base):
    """Épaisseur du trait le long de sa course.

    Un 一 de calligraphie est presque d'épaisseur constante : il s'affine à
    peine vers la droite, et se termine par une brève pression. Trop de
    renflement et le trait devient un os.
    """
    attack = 0.12 * math.exp(-(((t - 0.05) / 0.09) ** 2))
    press = 0.16 * math.exp(-(((t - 0.90) / 0.11) ** 2))
    body = 0.98 - 0.24 * t
    return base * max(0.30, body + attack + press)


def render(size):
    scale = size / REF
    center = size / 2.0
    half_side = SEAL_SIDE_R * scale / 2.0
    cos_a, sin_a = math.cos(SEAL_ANGLE), math.sin(SEAL_ANGLE)

    x0 = STROKE_LEFT_R * scale
    x1 = STROKE_RIGHT_R * scale
    y_mid = STROKE_Y_R * scale
    rise = STROKE_RISE_R * scale
    base = STROKE_BASE_R * scale

    rows = []
    for y in range(size):
        row = bytearray()
        py = y + 0.5
        for x in range(size):
            px = x + 0.5

            # fond : très sombre, réchauffé vers le centre
            radius = math.hypot(px - center, py - center) / (size * 0.7)
            color = mix((0x17, 0x12, 0x14), GROUND, min(1.0, radius))

            # le sceau, carré incliné à dégradé
            dx, dy = px - center, py - center
            rx = dx * cos_a + dy * sin_a
            ry = -dx * sin_a + dy * cos_a
            seal_distance = max(abs(rx), abs(ry)) - half_side
            seal = coverage(seal_distance)
            if seal > 0:
                shade = min(1.0, max(0.0, (rx + ry) / (4 * half_side) + 0.5))
                color = over(color, mix(SEAL, SEAL_DEEP, shade), seal)

            # le trait : distance au segment, épaisseur variable
            if x0 - base <= px <= x1 + base:
                t = min(1.0, max(0.0, (px - x0) / (x1 - x0)))
                line_y = y_mid + rise * (0.5 - t) * 2.0
                half = stroke_half_width(t, base)
                distance = abs(py - line_y) - half
                # extrémités franches à gauche, arrondies à droite
                if px < x0:
                    distance = max(distance, x0 - px)
                if px > x1:
                    distance = max(distance, px - x1)
                ink = coverage(distance)
                if ink > 0:
                    color = over(color, CREAM, ink)

            row.append(int(color[0] + 0.5))
            row.append(int(color[1] + 0.5))
            row.append(int(color[2] + 0.5))
        rows.append(row)
    return rows


def write_png(path, rows, size):
    raw = bytearray()
    for row in rows:
        raw.append(0)
        raw.extend(row)

    def chunk(tag, data):
        payload = tag + data
        return (struct.pack(">I", len(data)) + payload
                + struct.pack(">I", zlib.crc32(payload) & 0xFFFFFFFF))

    with open(path, "wb") as handle:
        handle.write(b"\x89PNG\r\n\x1a\n")
        handle.write(chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 2, 0, 0, 0)))
        handle.write(chunk(b"IDAT", zlib.compress(bytes(raw), 9)))
        handle.write(chunk(b"IEND", b""))


if __name__ == "__main__":
    output = sys.argv[1] if len(sys.argv) > 1 else "AppIcon.png"
    size = int(sys.argv[2]) if len(sys.argv) > 2 else 1024
    write_png(output, render(size), size)
    print("écrit", output, f"{size}x{size}")
