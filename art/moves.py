"""moves.py — the Moves, a consumable set, and Omega, a Spectral.

moves.png: nine cards in a row (cut, sum, heat, cool, frobenius,
tweedledum, repaint, nimbus, mex). The set's identity is the blackboard:
every Move is a diagram chalked on green slate, the way Winning Ways draws
its games, in a frame with vanilla's Tarot geometry (the silhouette and the
three rings are measured from the Fool; the pixels are not copied). Where a
Tarot carries its name, a Move has the board's ledge, with the chalk on it.
Left is blue and Right is red, as in Hackenbush.

omega.png: one Spectral. The frame, name plate and vortex are vanilla's
Trance, mirrored so the spiral winds in from the left; the plate is
re-lettered OMEGA in the plate's own letterforms, and an ω sits in the eye
with two cards going in.

fable, 2026-11-14 (claude-fable-5-2)
"""
from __future__ import annotations

import numpy as np

import glyphs
import vanilla as V
from pixel import Canvas, Palette, erode

W, H = 71, 95
ORDER = ["cut", "sum", "heat", "cool", "frobenius", "tweedledum", "repaint", "nimbus", "mex"]
# The set's colours for badges and UI.
SET_COLOURS = dict(primary="#4d9f7c", secondary="#2f5a50")

PAL = Palette(
    rim="#3c7f66", rim_l="#7cc7a2", line="#4f6367",      # frame rings, vanilla outline
    board="#2f5a50", board_l="#376a5c", board_d="#274c44",
    ledge="#a9dcc0", ledge_d="#7cc7a2",
    w="#f3f6e8", g="#b9cdbd",                             # chalk, and chalk rubbed thin
    b="#52b6ff", r="#fe6f66", y="#f0cc6a",                # Left, Right, the marked thing
)
AX0, AY0, AX1, AY1 = 7, 4, 63, 81                        # the board (the Fool's picture window)
CX = 35


def blank():
    """Frame, board and ledge."""
    c = Canvas(W, H, PAL)
    sil = V.cell("Tarots", 0, 0)[..., 3] > 0             # vanilla's card silhouette
    r1 = sil & ~erode(sil)
    in1 = erode(sil)
    r2 = in1 & ~erode(in1)
    in2 = erode(in1)
    c.fill(r1, "rim")
    c.fill(r2, "rim_l")
    c.fill(in2, "line")
    c.rect(AX0, AY0, AX1, AY1, "board")
    yy, xx = c.grid()
    board = (xx >= AX0) & (xx <= AX1) & (yy >= AY0) & (yy <= AY1)
    c.fill(board & ~erode(erode(board)) & ((xx + yy) % 2 == 0), "board_d")
    rng = np.random.default_rng(7)                       # chalk dust, the same on every card
    for _ in range(60):
        x, y = int(rng.integers(AX0 + 2, AX1 - 1)), int(rng.integers(AY0 + 2, AY1 - 1))
        c.px(x, y, "board_l")
        if rng.random() < 0.4:
            c.px(x + 1, y, "board_l")
    c.rect(AX0, 83, AX1, 90, "ledge")                    # the ledge, where a Tarot has its name
    c.hline(AX0, AX1, 83, "ledge_d")
    for x, col, n in ((14, "w", 7), (27, "b", 5), (38, "r", 6), (50, "y", 4)):
        c.rect(x, 86, x + n, 87, col)
        c.hline(x, x + n, 88, "ledge_d")
    return c


def card(c, x, y, edge="w", fill=None, w=11, h=15):
    """A playing card in chalk outline, top-left at (x, y)."""
    if fill:
        c.rect(x + 1, y + 1, x + w - 2, y + h - 2, fill)
    c.hline(x + 1, x + w - 2, y, edge)
    c.hline(x + 1, x + w - 2, y + h - 1, edge)
    c.vline(x, y + 1, y + h - 2, edge)
    c.vline(x + w - 1, y + 1, y + h - 2, edge)


def arrow_down(c, x, y0, y1, col="w"):
    c.vline(x, y0, y1, col)
    c.pxs([(x - 1, y1 - 1), (x + 1, y1 - 1), (x - 2, y1 - 2), (x + 2, y1 - 2)], col)


def arrow_up(c, x, y0, y1, col="w"):
    c.vline(x, y0, y1, col)
    c.pxs([(x - 1, y0 + 1), (x + 1, y0 + 1), (x - 2, y0 + 2), (x + 2, y0 + 2)], col)


def brace(c, x, y0, y1, left, col="w"):
    """A curly bracket, 3 px wide."""
    s = 1 if left else -1
    mid = (y0 + y1) // 2
    c.vline(x + s, y0 + 1, mid - 1, col)
    c.vline(x + s, mid + 1, y1 - 1, col)
    c.pxs([(x + 2 * s, y0), (x, mid), (x + 2 * s, y1)], col)


def write(c, names, x, y, col):
    return glyphs.text(c, names, x, y, col)


# ------------------------------------------------------------ the cards ----
def cut():
    """{ L | R }: two cards, a bar between; one card comes out between them."""
    c = blank()
    card(c, 15, 14, "b")
    card(c, 45, 14, "r")
    write(c, ["0"], 18, 17, "b")
    write(c, ["1"], 49, 17, "r")
    c.vline(CX, 11, 31, "y")
    c.vline(CX + 1, 11, 31, "y")
    brace(c, 9, 11, 31, True)
    brace(c, 61, 11, 31, False)
    arrow_down(c, CX, 37, 47)
    card(c, 30, 53, "w", w=12, h=17)
    write(c, ["½"], 33, 57, "y")                         # { 0 | 1 } = ½
    return c


def sum_():
    """Two cards and a plus; under the line, one card."""
    c = blank()
    card(c, 14, 13, "w")
    card(c, 46, 13, "w")
    write(c, ["2"], 17, 16, "g")
    write(c, ["3"], 49, 16, "g")
    c.rect(34, 16, 36, 24, "y")
    c.rect(31, 19, 39, 21, "y")
    c.hline(13, 57, 36, "w")
    c.hline(13, 57, 37, "w")
    card(c, 30, 46, "w", w=12, h=17)
    write(c, ["5"], 33, 49, "y")
    return c


def thermograph(c, base_y, half, mast_top, col):
    """Conway's thermograph: a tent on the number line, a mast above it."""
    c.hline(12, 58, base_y, "g")
    for i in range(half + 1):
        c.px(CX - half + i, base_y - i, col)
        c.px(CX + half - i, base_y - i, col)
        c.px(CX - half + i, base_y - i - 1, col)
        c.px(CX + half - i, base_y - i - 1, col)
    c.vline(CX, mast_top, base_y - half, col)
    for x in (CX - half, CX + half):
        c.vline(x, base_y + 1, base_y + 2, "g")


def heat():
    """The thermograph grows: a wide tent, a tall mast, the arrow up."""
    c = blank()
    thermograph(c, 66, 20, 14, "r")
    for x, y in ((14, 22), (54, 26)):                    # sparks
        c.pxs([(x, y), (x + 1, y - 1), (x + 1, y - 2), (x + 2, y), (x + 1, y + 1), (x + 1, y)], "y")
    arrow_up(c, 20, 30, 44, "y")
    arrow_up(c, 50, 30, 44, "y")
    write(c, ["±"], 33, 70, "r")
    return c


def cool():
    """The tent sinks toward a plain number: small tent, long cold mast."""
    c = blank()
    thermograph(c, 66, 8, 30, "b")
    for i in range(0, 21, 2):                            # where it used to reach
        c.px(CX - 20 + i, 66 - i, "g")
        c.px(CX + 20 - i, 66 - i, "g")
    arrow_down(c, 20, 20, 34, "w")
    arrow_down(c, 50, 20, 34, "w")
    c.pxs([(CX, 14), (CX, 15), (CX, 16), (CX, 18), (CX, 19), (CX, 20), (CX - 3, 17), (CX - 2, 17),
           (CX - 1, 17), (CX + 1, 17), (CX + 2, 17), (CX + 3, 17), (CX - 2, 15), (CX + 2, 15),
           (CX - 2, 19), (CX + 2, 19), (CX, 17)], "w")   # a snowflake
    return c


def frobenius():
    """Squaring in nim arithmetic sends ranks round in cycles."""
    c = blank()
    cy, r = 38, 20
    yy, xx = c.grid()
    d = np.hypot(xx - CX, yy - cy)
    ang = np.degrees(np.arctan2(yy - cy, xx - CX)) % 360
    ring = (d >= r - 0.5) & (d < r + 0.6)
    for k, a0 in enumerate((270, 30, 150)):
        gap = (ang - a0) % 360
        c.fill(ring & (gap > 24) & (gap < 96), "w")
    for (x, y), col, n in (((CX, cy - r), "b", "2"), ((CX + 17, cy + 10), "r", "3"), ((CX - 17, cy + 10), "y", "4")):
        c.rect(x - 5, y - 6, x + 5, y + 6, "board")
        card(c, x - 5, y - 7, col, w=11, h=14)
        write(c, [n], x - 2, y - 5, col)
    for x, y, pts in ((CX + 13, cy - 14, [(0, 0), (1, 1), (2, 2), (2, 1), (2, 0), (1, 2), (0, 2)]),
                      (CX - 2, cy + 20, [(0, 0), (0, 1), (0, -1), (1, 0), (1, -1), (1, 1), (2, 0)]),
                      (CX - 15, cy - 13, [(0, 2), (1, 1), (2, 0), (0, 1), (0, 0), (1, 0), (2, 1)])):
        c.pxs([(x + i, y + j) for i, j in pts], "w")
    write(c, ["*"], CX - 5, cy - 5, "g")
    c.pxs([(CX + 2, cy - 5), (CX + 3, cy - 6), (CX + 4, cy - 5), (CX + 3, cy - 4), (CX + 2, cy - 3),
           (CX + 3, cy - 3), (CX + 4, cy - 3)], "y")     # a little 2: squared
    return c


BOY = """
....ccc.....
...ccccc....
..ccccccc...
..ooooooo...
.o.......o..
.o..o.o..o..
.o.......o..
.o...o...o..
..o.....o...
.wwooooowwww
ww.wwwww..ww
o...o.o....o
o...o.o....o
o....o.....o
o...o.o....o
.o.o...o..o.
.o.........o
..o.......o.
...ooooooo..
...oo...oo..
...oo...oo..
..ccc...ccc.
"""


def tweedledum():
    """Tweedledum and Tweedledee: the same game twice, one of them turned
    round; G and -G, arm in arm (after Tenniel)."""
    c = blank()
    big = [("".join(ch * 2 for ch in row)) for row in BOY.strip("\n").split("\n") for _ in (0, 1)]
    c.stamp(big, 9, 20, {"o": "w", "c": "b", "w": "w"})
    c.stamp(big, 38, 20, {"o": "w", "c": "r", "w": "w"}, fh=True)
    c.rect(31, 38, 39, 39, "w")                          # arm in arm
    c.hline(10, 60, 66, "g")
    write(c, ["+"], 33, 9, "y")
    write(c, ["0"], 33, 70, "y")
    return c


def stalk(c, x, base, cols):
    """A Hackenbush stalk with two leaves."""
    y = base
    for i, col in enumerate(cols):
        c.vline(x, y - 9, y - 1, col)
        c.vline(x + 1, y - 9, y - 1, col)
        y -= 10
        c.rect(x - 1, y - 1, x + 2, y + 1, "w")
        if i == 1:
            for j in range(7):
                c.px(x - 2 - j, y - 2 - j, cols[2])
                c.px(x - 3 - j, y - 2 - j, cols[2])
            c.rect(x - 10, y - 10, x - 8, y - 8, "w")
    c.rect(x - 1, base - 1, x + 2, base + 1, "w")


def repaint():
    """Hackenbush, repainted: every blue edge red and every red edge blue."""
    c = blank()
    stalk(c, 21, 66, ["b", "r", "b"])
    stalk(c, 51, 66, ["r", "b", "r"])
    for i in range(AX0 + 3, AX1 - 2, 3):
        c.hline(i, i + 1, 68, "g")
    c.hline(29, 39, 22, "y")
    c.pxs([(38, 21), (38, 23), (37, 20), (37, 24)], "y")
    c.hline(31, 41, 28, "y")
    c.pxs([(32, 27), (32, 29), (33, 26), (33, 30)], "y")
    return c


def nimbus():
    """A card, and over it the halo: the star."""
    c = blank()
    card(c, 26, 34, "w", w=19, h=27)
    write(c, ["7"], 29, 37, "g")
    yy, xx = c.grid()
    e = ((xx - 35) / 12.0) ** 2 + ((yy - 24) / 4.0) ** 2
    c.fill((e <= 1.0) & (e > 0.55), "b")
    c.fill((e <= 1.0) & (e > 0.55) & (yy > 24), "w")
    for x, y in ((14, 16), (55, 14), (52, 34), (17, 38)):
        c.pxs([(x, y - 2), (x, y - 1), (x, y), (x, y + 1), (x, y + 2), (x - 1, y), (x - 2, y),
               (x + 1, y), (x + 2, y)], "y")
    c.stamp(["#.#.#", ".###.", "#####", ".###.", "#.#.#"], 33, 45, {"#": "b"})
    return c


def mex():
    """The minimum excludant: 0, 1, 2 are taken, 4 is taken; 3 is the gap."""
    c = blank()
    for i, n in enumerate("01234"):
        x = 10 + i * 11
        if n == "3":
            for j in range(0, 9, 2):
                c.pxs([(x + j, 40), (x + j, 54), (x, 40 + j + (j > 6) * 0), (x + 8, 40 + j)], "y")
            c.pxs([(x, 46), (x, 50), (x, 54), (x + 8, 54)], "y")
            write(c, ["3"], x + 2, 43, "y")
        else:
            card(c, x, 40, "w", fill=None, w=9, h=15)
            write(c, [n], x + 2 + (n == "1"), 43, "g")
            c.line(x + 1, 53, x + 7, 41, "r")            # struck through: taken
    arrow_down(c, 47, 20, 35, "y")
    c.hline(12, 58, 62, "g")
    for i in range(5):
        c.vline(14 + i * 11, 61, 63, "g")
    return c


CARDS = dict(cut=cut, sum=sum_, heat=heat, cool=cool, frobenius=frobenius,
             tweedledum=tweedledum, repaint=repaint, nimbus=nimbus, mex=mex)


def sheet_canvas():
    out = Canvas(W * len(ORDER), H, PAL)
    for i, n in enumerate(ORDER):
        out.blit(CARDS[n](), i * W, 0)
    return out


# ---------------------------------------------------------------- Omega ----
# The plate's letterforms, as vanilla letters its Spectrals (six rows).
PLATE = dict(
    O=[".##.", "##.#", "##.#", "##.#", "##.#", ".##."],
    M=["##..##.", "###.##.", "#######", "##.##.#", "##.##.#", "##.##.#"],
    E=["####", "##..", "##..", "###.", "##..", "####"],
    G=[".###.", "##...", "##...", "##.##", "##..#", ".###."],
    A=[".##.", "###.", "##.#", "####", "##.#", "##.#"],
)
BIG_OMEGA = """
..ww.........ww..
.ww...........ww.
ww.............ww
ww......w......ww
ww.....www.....ww
ww.....www.....ww
ww.....www.....ww
www...wwwww...www
.wwwwwww.wwwwwww.
..wwwww...wwwww..
"""


def omega():
    a = V.cell("Tarots", 3, 5).copy()                    # Trance
    a[6:78, 9:62] = a[6:78, 9:62][:, ::-1]               # the vortex, wound the other way
    ink, paper = (0x4f, 0x63, 0x67, 255), (0xe2, 0xeb, 0xf9, 255)
    a[83:89, 12:59] = paper                              # TRANCE off the plate
    x = 21
    for ch in "OMEGA":
        for j, row in enumerate(PLATE[ch]):
            for i, p in enumerate(row):
                if p == "#":
                    a[83 + j, x + i] = ink
        x += len(PLATE[ch][0]) + 1
    m = np.zeros((H, W), bool)                           # the ω, in the eye
    for j, row in enumerate(BIG_OMEGA.strip("\n").split("\n")):
        for i, p in enumerate(row):
            m[37 + j, 27 + i] = p == "w"
    from pixel import dilate
    a[dilate(dilate(m, diag=True))] = ink
    a[m] = (255, 255, 255, 255)
    for cx, cy in ((11, 24), (14, 52)):                  # two cards, going in from the left
        a[cy:cy + 11, cx:cx + 8] = ink
        a[cy + 1:cy + 10, cx + 1:cx + 7] = (255, 255, 255, 255)
        a[cy + 2:cy + 4, cx + 2:cx + 4] = (0xc7, 0xb2, 0x4a, 255)
    return a


def outputs():
    return {"moves.png": (sheet_canvas(), None), "omega.png": omega()}
