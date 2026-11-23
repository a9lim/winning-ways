"""vouchers.py — the Moves' vouchers, a tier-1 and tier-2 pair named for books.

vouchers.png: Lessons in Play, On Numbers and Games. Each is one of
vanilla's Tarot vouchers (Tarot Merchant, Tarot Tycoon) taken to the
blackboard: the ticket (stub, VOUCHER lettering, perforation, rings, the
Tycoon's streak and sparks) is vanilla's, its gold turned to the Moves' green
and the Tycoon's purple to chalk gold; the Tarot card in the window is
replaced by a book bound in slate, drawn here.

The pair counts the way the Merchant and the Tycoon count arrows. Lessons in
Play has one cut on its cover: a game, a Left option in blue and a Right
option in red. On Numbers and Games has the tree that grows from it, three
days of numbers, on its way down to a gold ω, with gilt corners, bands and
page edges.

fable, 2026-11-23 (claude-fable-5-2)
"""
from __future__ import annotations

import numpy as np

import vanilla as V
from pixel import erode

W, H = 71, 95
ORDER = ["lessons", "onag"]


def rgb(h):
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)


BODY_L, BODY_D = rgb("4d9f7c"), rgb("3c7f66")            # the set's primary, and the Moves' rim
LINE, EDGE = rgb("4f6367"), rgb("7cc7a2")
COVER, SPINE = rgb("2f5a50"), rgb("274c44")              # the Moves' board and its shade
PAPER, PAPER_D = rgb("f3f6e8"), rgb("b9cdbd")            # chalk, and chalk rubbed thin
BLUE, RED, GOLD, GOLD_D = rgb("52b6ff"), rgb("fe6f66"), rgb("f0cc6a"), rgb("c9a24a")
# vanilla's inks -> ours
INKS = {
    "lessons": {"f3b92f": BODY_L, "b78b20": BODY_D},
    "onag": {"f3b92f": BODY_L, "b78b20": BODY_D, "ae65ff": GOLD, "924be0": GOLD_D, "efe1ff": PAPER},
}
RING = {"lessons": "efe1ff", "onag": "efe1ff"}           # the white ring round the window
FACE = (27, 32, 49, 69)                                  # the cover's face: x0, y0, x1, y1
CX = 38
OMEGA = [".##...##.", "##.....##", "##..#..##", "##..#..##", "##..#..##", "##.###.##", ".###.###."]


def window(hx, ring):
    """The picture window: what the white ring encloses, flooded from its middle."""
    m = np.zeros(hx.shape, bool)
    st = [(35, 54)]
    while st:
        x, y = st.pop()
        if 0 <= x < W and 0 <= y < H and not m[y, x] and hx[y, x] != ring:
            m[y, x] = True
            st += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    assert 1200 < m.sum() < 1500, m.sum()                # a leak would flood the card
    return m


def node(a, x, y, col):
    a[y - 1:y + 2, x - 1:x + 2] = col


def branch(a, x, y, dx, n, col):
    """n pixels down a diagonal from (x, y), two wide."""
    for i in range(n):
        a[y + i, x + dx * i] = col
        a[y + i, x + dx * i - dx] = col


def book(a, m, rich):
    trim = GOLD if rich else EDGE
    x0, y0, x1, y1 = FACE
    yy, xx = np.mgrid[0:H, 0:W]
    a[m] = COVER
    a[m & ~erode(m)] = EDGE
    inner = erode(m)
    a[inner & (xx < x0 - 1)] = SPINE                     # the spine and its bands
    a[inner & (xx == x0 - 1)] = LINE
    for y in (36, 37, 65, 66):
        a[y][inner[y] & (xx[y] < x0 - 1)] = trim
    pages = m & (xx >= x0) & (yy > y1) & (yy <= y1 + 5)  # the page edges, open to the right
    a[pages] = LINE
    for y, col in ((y1 + 2, PAPER), (y1 + 3, GOLD if rich else PAPER_D), (y1 + 4, PAPER)):
        a[y][pages[y]] = col
    if rich:                                             # gilt corners
        for i in range(5):
            for j in range(5 - i):
                for x, y in ((x0 + i, y0 + j), (x1 - i, y0 + j), (x0 + i, y1 - j), (x1 - i, y1 - j)):
                    a[y, x] = GOLD_D if i + j == 4 else GOLD
        y = 36                                           # 0; -1, 1; -2, -1/2, 1/2, 2
        branch(a, CX - 2, y + 2, -1, 4, BLUE)
        branch(a, CX + 2, y + 2, 1, 4, RED)
        for cx in (CX - 6, CX + 6):
            branch(a, cx - 2, y + 8, -1, 2, BLUE)
            branch(a, cx + 2, y + 8, 1, 2, RED)
            node(a, cx - 3, y + 11, PAPER)
            node(a, cx + 3, y + 11, PAPER)
            node(a, cx, y + 6, PAPER)
        node(a, CX, y, GOLD)
        for y in (51, 53, 55):                           # and so on, down to
            a[y, CX] = PAPER_D
        for j, row in enumerate(OMEGA):
            for i, p in enumerate(row):
                if p == "#":
                    a[58 + j, CX - 4 + i] = GOLD
    else:
        y = 42                                           # { Left | Right }
        branch(a, CX - 2, y + 2, -1, 6, BLUE)
        branch(a, CX + 2, y + 2, 1, 6, RED)
        node(a, CX - 8, y + 9, PAPER)
        node(a, CX + 8, y + 9, PAPER)
        node(a, CX, y, GOLD)
        a[59, CX - 7:CX + 8] = PAPER                     # a title, in two rules
        a[62, CX - 4:CX + 5] = PAPER_D


def voucher(kind):
    a = V.cell("Vouchers", 1, 0 if kind == "lessons" else 1)
    hx = V.hexes(a)
    m = window(hx, RING[kind])
    for h, col in INKS[kind].items():
        a[(hx == h) & ~m] = col
    book(a, m, kind == "onag")
    return a


def sheet_rgba():
    return np.concatenate([voucher(k) for k in ORDER], 1)


def outputs():
    return {"vouchers.png": sheet_rgba()}
