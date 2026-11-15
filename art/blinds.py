"""blinds.py — The Heap, a Boss Blind.

blinds.png: 21 frames of 34x34 in a row, as one row of vanilla's
BlindChips.png. A vanilla chip does not turn: frames 0..12 are the still
chip (a flat disc, its rim light above and dark below, a glyph in a darker
tone of the body) and in frames 13..20 a diagonal shine crosses it. The
disc, its rim and the shine of every frame are read from a vanilla boss chip
(The Wall, row 8; the shine is the same on every row) and re-inked; the
glyph is taken off and ours put on: a heap of six counters, 1 + 2 + 3, the
smallest Nim position that sums to nothing.

fable, 2026-11-14 (claude-fable-5-2)
"""
from __future__ import annotations

import numpy as np

import vanilla as V
from pixel import hex_rgba

S, FRAMES, ROW = 34, 21, 8
COLOUR = "#2a9d8f"                                       # the boss colour


def _mix(h, to, t):
    a, b = hex_rgba(h), hex_rgba(to)
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3)) + (255,)


BODY = hex_rgba(COLOUR)
LIGHT = _mix(COLOUR, "#ffffff", 0.27)                    # rim above, and the shine
DARK = _mix(COLOUR, "#000000", 0.24)                     # rim below
FACE = _mix(COLOUR, "#000000", 0.44)                     # the glyph
FACE_LIT = tuple(round(FACE[i] + (255 - FACE[i]) * 0.25) for i in range(3)) + (255,)

COUNTER = [".####.", "######", "######", "######", "######", ".####."]


def face():
    """Six counters: one on two on three."""
    m = np.zeros((S, S), bool)
    for row, n in enumerate((1, 2, 3)):
        y = 7 + row * 7
        for i in range(n):
            x = 17 - (7 * n - 1) // 2 + i * 7
            for j, r in enumerate(COUNTER):
                for k, ch in enumerate(r):
                    m[y + j, x + k] = ch == "#"
    return m


def frame(i):
    src = V.texture("BlindChips")[ROW * S:(ROW + 1) * S, i * S:(i + 1) * S]
    hx = V.hexes(src)
    out = np.zeros((S, S, 4), np.uint8)
    lit = (hx == "808080") | (hx == "b8b8b8")
    out[(hx == "575757") | (hx == "a2a2a2")] = BODY
    out[lit] = LIGHT
    out[hx == "424242"] = DARK
    f = face()
    out[f & ~lit] = FACE
    out[f & lit] = FACE_LIT
    assert not (hx[f] == "").any() and set(np.unique(hx)) <= {"", "575757", "a2a2a2", "808080", "b8b8b8", "424242"}
    return out


def sheet_rgba():
    return np.concatenate([frame(i) for i in range(FRAMES)], 1)


def outputs():
    return {"blinds.png": sheet_rgba()}
