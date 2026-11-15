"""packs.py — Game Packs, the Moves' boosters.

packs.png: normal_1, normal_2, jumbo, mega. Each is one of vanilla's
Celestial packs taken to the blackboard: the wrapper (crimps, foil, the
JUMBO and MEGA lettering) is vanilla's, turned green; the planet is covered
by a slate with one of the set's diagrams chalked on it; and the name band
is vanilla's with CELESTIAL re-lettered GAME in the band's own letterforms
(G and M are drawn to match; C, E, A are as vanilla letters them).

fable, 2026-11-14 (claude-fable-5-2)
"""
from __future__ import annotations

import colorsys

import numpy as np

import vanilla as V
from pixel import dilate

W, H = 71, 95
ORDER = ["normal_1", "normal_2", "jumbo", "mega"]
BAND = (56, 77)                                   # the name band's rows in a normal pack
WHITE, INK = (255, 255, 255, 255), (0x4f, 0x63, 0x67, 255)
BOARD, BOARD_D, RIM = (0x2f, 0x5a, 0x50, 255), (0x27, 0x4c, 0x44, 255), (0xa9, 0xdc, 0xc0, 255)
CHALK = dict(w=(0xf3, 0xf6, 0xe8, 255), b=(0x52, 0xb6, 0xff, 255), r=(0xfe, 0x6f, 0x66, 255),
             y=(0xf0, 0xcc, 0x6a, 255), g=(0xb9, 0xcd, 0xbd, 255))
LETTERS = dict(
    G=["####", "####", "#...", "#.##", "#..#", "####", "####"],
    A=[".##.", ".##.", "#..#", "####", "####", "#..#", "#..#"],
    M=["#...#", "#...#", "##.##", "#####", "#.#.#", "#...#", "#...#"],
    E=["####", "####", "#...", "##..", "#...", "####", "####"],
)


def green(a, hue, rows=(9, 86)):
    """Turn the wrapper's body to one family of greens, keeping its light
    and dark; whites, greys and the crimped ends stay."""
    out = a.copy()
    for y in range(rows[0], rows[1]):
        for x in range(W):
            r, g, b, al = a[y, x]
            if not al:
                continue
            h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
            if s < 0.10:
                continue
            h2 = hue + 0.12 * (((h - 0.6 + 0.5) % 1.0) - 0.5)
            out[y, x, :3] = [round(c * 255) for c in colorsys.hsv_to_rgb(h2 % 1.0, min(1.0, s * 0.9), v)]
    return out


def reletter(band):
    """CELESTIAL off the band, GAME on."""
    y0 = 58 - BAND[0]
    for y in range(y0, y0 + 9):                   # the band's own colour, from its clear left end
        band[y, 12:59] = band[y, 11]
    m = np.zeros(band.shape[:2], bool)
    x = 35 - (4 + 1 + 4 + 1 + 5 + 1 + 4) // 2 - 1
    for ch in "GAME":
        for j, row in enumerate(LETTERS[ch]):
            for i, p in enumerate(row):
                m[y0 + 1 + j, x + i] = p == "#"
        x += len(LETTERS[ch][0]) + 2
    band[dilate(m, diag=True)] = INK
    band[m] = WHITE
    return band


def slate(a, x0, y0, x1, y1):
    a[y0:y1 + 1, x0:x1 + 1] = RIM
    a[y0, x0] = a[y0, x1] = a[y1, x0] = a[y1, x1] = a[y0 - 1, x0 + 3]
    a[y0 + 1:y1, x0 + 1:x1] = INK
    a[y0 + 2:y1 - 1, x0 + 2:x1 - 1] = BOARD
    for y in range(y0 + 2, y1 - 1):
        for x in range(x0 + 2, x1 - 1):
            if (y in (y0 + 2, y1 - 2) or x in (x0 + 2, x1 - 2)) and (x + y) % 2 == 0:
                a[y, x] = BOARD_D


def px(a, pts, col):
    for x, y in pts:
        a[y, x] = CHALK[col]


def vline(a, x, y0, y1, col):
    a[y0:y1 + 1, x] = CHALK[col]


def hline(a, x0, x1, y, col):
    a[y, x0:x1 + 1] = CHALK[col]


def box(a, x, y, w, h, col):
    hline(a, x + 1, x + w - 2, y, col)
    hline(a, x + 1, x + w - 2, y + h - 1, col)
    vline(a, x, y + 1, y + h - 2, col)
    vline(a, x + w - 1, y + 1, y + h - 2, col)


def cut_mark(a, cx, cy, s=1.0):
    """{ card | card }: the set's sign."""
    h = int(9 * s)
    for sx, col in ((-1, "b"), (1, "r")):
        box(a, cx + sx * 9 - 4 + (sx > 0), cy - h, 8, 2 * h + 1 - 2, col)
        bx = cx + sx * 17
        vline(a, bx, cy - h, cy - 2, "w")
        vline(a, bx, cy + 1, cy + h - 2, "w")
        px(a, [(bx - sx, cy - h - 1), (bx + sx, cy - 1), (bx + sx, cy), (bx - sx, cy + h - 1)], "w")
    vline(a, cx, cy - h - 1, cy + h - 1, "y")
    vline(a, cx + 1, cy - h - 1, cy + h - 1, "y")


def tent(a, cx, base, half, top, col):
    """A thermograph."""
    hline(a, cx - half - 3, cx + half + 3, base, "g")
    for i in range(half + 1):
        px(a, [(cx - half + i, base - i), (cx + half - i, base - i),
               (cx - half + i, base - i - 1), (cx + half - i, base - i - 1)], col)
    vline(a, cx, top, base - half, col)


def star(a, cx, cy, col):
    px(a, [(cx + i, cy) for i in range(-4, 5)] + [(cx, cy + i) for i in range(-4, 5)]
       + [(cx + i, cy + i) for i in range(-3, 4)] + [(cx + i, cy - i) for i in range(-3, 4)], col)


def pack(kind):
    src = dict(normal_1=(0, 1), normal_2=(1, 1), jumbo=(0, 3), mega=(2, 3))[kind]
    hue = dict(normal_1=0.42, normal_2=0.47, jumbo=0.38, mega=0.44)[kind]
    a = green(V.cell("boosters", *src), hue)
    band = green(V.cell("boosters", 0, 1), hue)[BAND[0]:BAND[1] + 1].copy()
    if kind != "normal_1":
        keep = a[BAND[0]:BAND[1] + 1, :, 3] > 0
        a[BAND[0]:BAND[1] + 1][keep] = band[keep]
    a[BAND[0]:BAND[1] + 1] = reletter(a[BAND[0]:BAND[1] + 1])
    if kind == "normal_1":
        slate(a, 13, 15, 57, 53)
        cut_mark(a, 35, 35)
    elif kind == "normal_2":
        slate(a, 13, 15, 57, 53)
        tent(a, 35, 47, 14, 21, "r")
        tent(a, 35, 47, 5, 21, "b")
    elif kind == "jumbo":
        slate(a, 11, 26, 59, 53)
        cut_mark(a, 35, 40, 0.9)
    else:
        slate(a, 11, 37, 59, 54)
        star(a, 20, 46, "b")
        tent(a, 36, 50, 8, 41, "r")
        star(a, 51, 46, "y")
    return a


def sheet_rgba():
    return np.concatenate([pack(k) for k in ORDER], 1)


def outputs():
    return {"packs.png": sheet_rgba()}
