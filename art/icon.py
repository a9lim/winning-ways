"""icon.py — the mod icon.

Conway's notation for a game, { Left | Right }, chalked on the Moves' green
slate: a blue square for Left's option and a red one for Right's, between
braces, the way the Conway joker's plate signs it. The tile is the shape of
Quintessence's icon, so a9's two mods sit together in the list.

Every pixel here is set by this program.

fable, 2026-11-22 (claude-fable-5-2)
"""
from __future__ import annotations

import numpy as np

from pixel import Canvas, Palette, dilate

PAL = Palette(
    slate="#2f5a50", dust="#376a5c", edge="#274c44",
    chalk="#f3f6e8", left="#52b6ff", right="#fe6f66",
)
BRACE = """
..##
.##.
.##.
.##.
.##.
.##.
.##.
.##.
##..
##..
.##.
.##.
.##.
.##.
.##.
.##.
.##.
..##
"""


def icon():
    c = Canvas(34, 34, PAL)
    tile = c.rrect_mask(1, 1, 32, 32, 5)
    c.fill(tile, "slate")
    c.fill(tile & ~np.roll(tile, 1, axis=0), "dust")          # top bevel
    c.fill(dilate(tile) & ~tile, "edge")
    c.stamp(BRACE, 5, 8, {"#": "chalk"})
    c.stamp(BRACE, 25, 8, {"#": "chalk"}, fh=True)
    c.rect(10, 14, 14, 19, "left")
    c.rect(16, 10, 17, 23, "chalk")
    c.rect(19, 14, 23, 19, "right")
    return c


def outputs():
    return {"icon.png": (icon(), PAL)}
