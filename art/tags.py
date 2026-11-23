"""tags.py — the Game Tag, which gives a Mega Game Pack.

tags.png: one tag. The tag and its disc are vanilla's Charm Tag (the one
that gives a Mega Arcana Pack); the disc is turned to the Moves' green, the
eye is taken off, and the Game Packs' sign is put on in white: a cut, one
card either side of the bar.

fable, 2026-11-23 (claude-fable-5-2)
"""
from __future__ import annotations

import numpy as np

import vanilla as V
from pixel import dilate

S = 34
DISC, DISC_D = (0x4d, 0x9f, 0x7c, 255), (0x3c, 0x7f, 0x66, 255)   # the set's primary; the Moves' rim
WHITE = (255, 255, 255, 255)


def blank():
    """The Charm Tag with a plain green disc. Returns the tag and the disc's mask."""
    a = V.cell("tags", 2, 2, S, S)
    hx = V.hexes(a)
    ink = (hx == "8a71e1") | (hx == "6d5baa")
    out = np.zeros((S, S), bool)                          # everything the disc doesn't enclose
    st = [(0, 0)]
    while st:
        x, y = st.pop()
        if 0 <= x < S and 0 <= y < S and not out[y, x] and not ink[y, x]:
            out[y, x] = True
            st += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    disc = ~out
    a[disc] = DISC
    a[disc & (hx == "6d5baa") & dilate(out, diag=True)] = DISC_D
    return a, disc


def cut(a):
    """card | card"""
    a[13:22, 16:18] = WHITE
    a[15:20, 12:15] = WHITE
    a[15:20, 19:22] = WHITE


def tent(a):
    """A thermograph: the alternative mark, kept for look.py."""
    for i in range(5):
        a[20 - i, 12 + i:14 + i] = WHITE
        a[20 - i, 20 - i:22 - i] = WHITE
    a[11:17, 16:18] = WHITE
    a[21, 11:23] = WHITE


def tag(mark=cut):
    a, disc = blank()
    b = a.copy()
    mark(b)
    assert (b != a).any(-1).sum() == ((b != a).any(-1) & disc).sum()   # the mark stays on the disc
    return b


def outputs():
    return {"tags.png": tag()}
