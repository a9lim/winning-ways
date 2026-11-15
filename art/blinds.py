"""blinds.py — The Heap and The Misère, Boss Blinds.

blinds.png: two rows of 21 frames of 34x34, each as one row of vanilla's
BlindChips.png: row 0 The Heap, row 1 The Misère. A vanilla chip does not
turn: frames 0..12 are the still chip (a flat disc, its rim light above and
dark below, a glyph in a darker tone of the body) and in frames 13..20 a
diagonal shine crosses it. The disc, its rim and the shine of every frame
are read from a vanilla boss chip (The Wall, row 8; the shine is the same on
every row) and re-inked; the glyph is taken off and ours put on.

The Heap: six counters, 1 + 2 + 3, the smallest Nim position that sums to
nothing. The Misère: a heap going down, three counters and then the last
one, which is a skull: whoever takes it loses.

fable, 2026-11-14 (claude-fable-5-2)
"""
from __future__ import annotations

import numpy as np

import vanilla as V
from pixel import hex_rgba

S, FRAMES, ROW = 34, 21, 8
COLOUR = "#2a9d8f"                                       # The Heap's boss colour
MISERE = "#a3b81c"                                       # The Misère's: an acid green
ORDER = ["heap", "misere"]


def _mix(h, to, t):
    a, b = hex_rgba(h), hex_rgba(to)
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3)) + (255,)


def tones(colour):
    """body, rim light (and shine), rim dark, glyph, glyph under the shine"""
    face = _mix(colour, "#000000", 0.44)
    return (hex_rgba(colour), _mix(colour, "#ffffff", 0.27), _mix(colour, "#000000", 0.24), face,
            tuple(round(face[i] + (255 - face[i]) * 0.25) for i in range(3)) + (255,))


COUNTER = [".####.", "######", "######", "######", "######", ".####."]
SMALL = [".##.", "####", "####", ".##."]
SKULL = ["...#########...",
         "..###########..",
         ".#############.",
         "###############",
         "###############",
         "###...###...###",
         "###...###...###",
         "###...###...###",
         "#######.#######",
         "######...######",
         ".#############.",
         "..###########..",
         "...#.##.##.#...",
         "...#.##.##.#...",
         "...#########..."]


def _stamp(m, art, x, y):
    for j, r in enumerate(art):
        for k, ch in enumerate(r):
            if ch == "#":
                m[y + j, x + k] = True


def face():
    """Six counters: one on two on three."""
    m = np.zeros((S, S), bool)
    for row, n in enumerate((1, 2, 3)):
        for i in range(n):
            _stamp(m, COUNTER, 17 - (7 * n - 1) // 2 + i * 7, 7 + row * 7)
    return m


def misere_face():
    """Three counters taken in turn, and the last one: a skull."""
    m = np.zeros((S, S), bool)
    for i in range(3):
        _stamp(m, SMALL, 9 + i * 6, 6)
    _stamp(m, SKULL, 10, 12)
    return m


FACES = dict(heap=(COLOUR, face), misere=(MISERE, misere_face))


def frame(i, which="heap"):
    colour, glyph = FACES[which]
    body, light, dark, ink, ink_lit = tones(colour)
    src = V.texture("BlindChips")[ROW * S:(ROW + 1) * S, i * S:(i + 1) * S]
    hx = V.hexes(src)
    out = np.zeros((S, S, 4), np.uint8)
    lit = (hx == "808080") | (hx == "b8b8b8")
    out[(hx == "575757") | (hx == "a2a2a2")] = body
    out[lit] = light
    out[hx == "424242"] = dark
    f = glyph()
    out[f & ~lit] = ink
    out[f & lit] = ink_lit
    assert not (hx[f] == "").any() and set(np.unique(hx)) <= {"", "575757", "a2a2a2", "808080", "b8b8b8", "424242"}
    return out


def sheet_rgba():
    return np.concatenate([np.concatenate([frame(i, w) for i in range(FRAMES)], 1) for w in ORDER], 0)


def outputs():
    return {"blinds.png": sheet_rgba()}
