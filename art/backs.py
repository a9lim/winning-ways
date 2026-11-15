"""backs.py — the deck backs: 0 the Field Deck, 1 the Ordinal Deck.

backs.png: two 71x95 cells. Vanilla's deck-back build (measured from the Red
Deck, Enhancers.png (0, 0): the silhouette, a three-pixel white margin, the
field on x 4..66, y 4..90, a dotted rule inside it) in the Moves' slate
green. On the field, the field: sixteen tiles, four by four, each one a small
card, an element of F16 written as four bits (8 4 / 2 1), 0 top left to 15 bottom
right. The Ordinal Deck is the same build in indigo, and on it the
ordinals as matchsticks: a row of sticks shrinking and crowding toward a
limit is omega, the next row starts again at omega (the gold stick) and runs
to omega 2, and the rows themselves shrink and crowd toward omega squared.
Drawn here; no vanilla pixels.

fable, 2026-11-14 (claude-fable-5-2)
"""
from __future__ import annotations

import numpy as np

import vanilla as V
from pixel import Canvas, Palette, erode

W, H = 71, 95
PAL = Palette(w="#ffffff", field="#4d9f7c", tile="#2f5a50", tile_d="#274c44", off="#d3e2d4",
              on="#f3f6e8", on_d="#b9cdbd", gold="#f0cc6a", gold_d="#c9a544",
              night="#4b4a9c", night_d="#3a3980", stick="#f3f1ff", stick_d="#b4b2e6")
ORDER = ["field", "ordinal"]


def blank(field):
    c = Canvas(W, H, PAL)
    sil = V.cell("Enhancers", 0, 0)[..., 3] > 0          # the card's silhouette
    c.fill(sil, "w")
    c.rect(4, 4, 66, 90, field)
    for x, y in ((4, 4), (66, 4), (4, 90), (66, 90)):
        c.px(x, y, "w")
    for x in range(8, 64, 3):                            # the dotted rule
        c.px(x, 6, "w")
        c.px(x, 88, "w")
    for y in range(8, 88, 3):
        c.px(6, y, "w")
        c.px(64, y, "w")
    return c


def back():
    c = blank("field")
    for n in range(16):
        x, y = 9 + (n % 4) * 14, 9 + (n // 4) * 20
        c.rrect(x, y + 1, x + 10, y + 17, 2, "tile")     # its shadow
        c.rrect(x, y, x + 10, y + 16, 2, "on")
        for b, (i, j) in zip((8, 4, 2, 1), ((0, 0), (1, 0), (0, 1), (1, 1))):
            px, py = x + 2 + i * 4, y + 3 + j * 6
            lit = bool(n & b)
            c.rect(px, py, px + 2, py + 3, ("gold_d" if n == 15 else "tile") if lit else "off")
    return c


def ordinal():
    """The ordinals up to omega squared, as matchsticks."""
    c = blank("night")
    y, h, k = 10.0, 21.0, 0
    while y + h <= 87.5:
        y0, y1 = int(round(y)), int(round(y + h)) - 1
        x, gap, n = 10.0, 8.0, 0
        while x <= 61.5:
            top = y1 - max(0, int(round((y1 - y0) * (0.4 + 0.6 * (1 - (x - 10) / 52.0) ** 1.5))))
            lead = k == 1 and n == 0                     # omega itself
            xi = int(round(x))
            wide = gap >= 4.5 and xi < 60                # two pixels thick while there is room
            if gap >= 3:
                c.vline(xi + 1 + wide, top + 1, y1 + 1, "night_d")   # and a shadow
            c.rect(xi, top, xi + wide, y1, "gold" if lead else "stick" if x < 57 else "stick_d")
            if lead and y1 - top >= 3:
                c.vline(xi + 1, top, y1, "gold_d")
            x, gap, n = x + (max(2, round(gap)) if x < 57 else 1), gap * 0.87, n + 1
        y, h, k = y + h + max(1.0, h * 0.2), h * 0.7, k + 1
    return c


CELLS = dict(field=back, ordinal=ordinal)


def sheet_canvas():
    out = Canvas(W * len(ORDER), H, PAL)
    for i, n in enumerate(ORDER):
        out.a[:, i * W:(i + 1) * W] = CELLS[n]().a
    return out


def outputs():
    return {"backs.png": (sheet_canvas(), None)}
