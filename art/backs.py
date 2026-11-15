"""backs.py — the Field Deck's back.

backs.png: one 71x95 cell. Vanilla's deck-back build (measured from the Red
Deck, Enhancers.png (0, 0): the silhouette, a three-pixel white margin, the
field on x 4..66, y 4..90, a dotted rule inside it) in the Moves' slate
green. On the field, the field: sixteen tiles, four by four, each one a small
card, an element of F16 written as four bits (8 4 / 2 1), 0 top left to 15 bottom
right. Drawn here; no vanilla pixels.

fable, 2026-11-14 (claude-fable-5-2)
"""
from __future__ import annotations

import numpy as np

import vanilla as V
from pixel import Canvas, Palette, erode

W, H = 71, 95
PAL = Palette(w="#ffffff", field="#4d9f7c", tile="#2f5a50", tile_d="#274c44", off="#d3e2d4",
              on="#f3f6e8", on_d="#b9cdbd", gold="#f0cc6a", gold_d="#c9a544")


def back():
    c = Canvas(W, H, PAL)
    sil = V.cell("Enhancers", 0, 0)[..., 3] > 0          # the card's silhouette
    c.fill(sil, "w")
    c.rect(4, 4, 66, 90, "field")
    for x, y in ((4, 4), (66, 4), (4, 90), (66, 90)):
        c.px(x, y, "w")
    for x in range(8, 64, 3):                            # the dotted rule
        c.px(x, 6, "w")
        c.px(x, 88, "w")
    for y in range(8, 88, 3):
        c.px(6, y, "w")
        c.px(64, y, "w")
    for n in range(16):
        x, y = 9 + (n % 4) * 14, 9 + (n // 4) * 20
        c.rrect(x, y + 1, x + 10, y + 17, 2, "tile")     # its shadow
        c.rrect(x, y, x + 10, y + 16, 2, "on")
        for b, (i, j) in zip((8, 4, 2, 1), ((0, 0), (1, 0), (0, 1), (1, 1))):
            px, py = x + 2 + i * 4, y + 3 + j * 6
            lit = bool(n & b)
            c.rect(px, py, px + 2, py + 3, ("gold_d" if n == 15 else "tile") if lit else "off")
    return c


def outputs():
    return {"backs.png": (back(), None)}
