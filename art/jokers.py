"""jokers.py — the Winning Ways jokers.

jokers.png: sixteen 71x95 cells in a row:

    0 bouton   1 generator   2 grundy   3 hotstrat   4 thermograph
    5 sprouts  6 cantor      7 paradise 8 conway (background)  9 conway (soul)
    10 birthday  11 hilbert  12 berlekamp (background)  13 berlekamp (soul)
    14 guy (background)  15 guy (soul)

Cells 0..7 are drawn here in vanilla's joker build: the card silhouette and
its one-pixel `bfc7d5` edge, the white margin, the picture window (x 4..66,
y 4..90) and the two-tone object shading under a `4f6367` outline are all
measured from vanilla's Jokers.png. The JOKER corner lettering is vanilla's
own (read from the plain Joker at build time), as on almost every vanilla
joker. Cell 8 is a vanilla legendary's background card (Triboulet's), its
hue turned to violet and its plate re-signed { | }; cell 9, the soul, is a
bust of John Horton Conway, drawn here. Cells 10 and 11 are built like 0..7.
Berlekamp (12, 13) and Guy (14, 15) are built like Conway: the same marble
turned rose and green, the plates signed with a Dots-and-Boxes position and
with the small numbers, and a bust each. The three authors are a set.

fable, 2026-11-14 (claude-fable-5-2)
"""
from __future__ import annotations

import colorsys

import numpy as np

import glyphs
import vanilla as V
from pixel import Canvas, Palette, dilate, erode

W, H = 71, 95
ORDER = ["bouton", "generator", "grundy", "hotstrat", "thermograph",
         "sprouts", "cantor", "paradise", "conway", "conway_soul",
         "birthday", "hilbert", "berlekamp", "berlekamp_soul", "guy", "guy_soul"]
CX = 35

# vanilla's joker colours
EDGE, WHITE, LINE = "#bfc7d5", "#ffffff", "#4f6367"
RED, RED_D, RED_L = "#fd5f55", "#dd463c", "#ff9a92"
BLUE, BLUE_D, BLUE_L = "#009cfd", "#008be3", "#81cefd"
GOLD, GOLD_D, GOLD_L = "#fda200", "#df940e", "#ffd37a"
GREEN, GREEN_D, GREEN_L = "#56a786", "#508e76", "#8fd0b0"
GREY, GREY_D, GREY_L = "#c0c0c0", "#a0a8b0", "#dcdcdc"

PAL = Palette()


def new():
    return Canvas(W, H, PAL)


def silhouette():
    return V.cell("Jokers", 0, 0)[..., 3] > 0


def lettering():
    """Vanilla's JOKER, top-left, as a mask; the other corner is its turn."""
    hx = V.hexes(V.cell("Jokers", 0, 0))
    m = np.zeros((H, W), bool)
    m[7:51, 5:14] = hx[7:51, 5:14] == "4f6367"
    return m | m[::-1, ::-1]


def window():
    m = np.zeros((H, W), bool)
    m[4:91, 4:67] = True
    for y, x in ((4, 4), (4, 66), (90, 4), (90, 66)):
        m[y, x] = False
    return m


def card(bg=None):
    """A joker blank: edge, white, and (with bg) a filled picture window."""
    c = new()
    sil = silhouette()
    c.fill(sil, WHITE)
    c.fill(sil & ~erode(sil), EDGE)
    if bg:
        c.fill(window(), bg)
    return c


def finish(c, ink=LINE, edge=None):
    """Put JOKER in both corners, over the picture."""
    m = lettering()
    if edge:
        c.fill(dilate(m, diag=True) & window(), edge)
    c.fill(m, ink)
    return c


def layer():
    return new()


def put(c, l, line=LINE, diag=False):
    """Outline a layer's drawing and lay it on the card."""
    if line:
        l.outline(line, diag=diag)
    c.a = np.where(l.a > 0, l.a, c.a)


def disc(c, cx, cy, r, col):
    yy, xx = c.grid()
    c.fill((xx - cx) ** 2 + (yy - cy) ** 2 <= r * r, col)


def ring_mask(c, cx, cy, r0, r1):
    yy, xx = c.grid()
    d = np.hypot(xx - cx, yy - cy)
    return (d >= r0) & (d <= r1)


def text(c, names, x, y, col):
    return glyphs.text(c, names, x, y, col)


# -------------------------------------------------------------- bouton ----
def match(l, x, y, n=12):
    """A match, head up: 7 wide, 6 + n tall, top-left of the head at (x, y)."""
    l.rect(x + 1, y + 6, x + 5, y + 5 + n, "#f3dcae")
    l.rect(x + 4, y + 6, x + 5, y + 5 + n, "#d2b07c")
    l.vline(x + 1, y + 7, y + 4 + n, "#fff3d6")
    l.rect(x, y + 1, x + 6, y + 4, RED)
    l.rect(x + 1, y, x + 5, y + 5, RED)
    l.rect(x + 4, y + 3, x + 5, y + 5, RED_D)
    l.pxs([(x + 6, y + 2), (x + 6, y + 3), (x + 6, y + 4), (x + 3, y + 5), (x + 5, y + 2)], RED_D)
    l.pxs([(x + 1, y + 1), (x + 2, y + 1), (x + 1, y + 2)], RED_L)


def bouton():
    """Nim: rows of 1, 2 and 3 matches, and what they add up to."""
    c = card()
    l = layer()
    for row, n in enumerate((1, 2, 3)):
        y = 9 + row * 21
        for i in range(n):
            match(l, CX - 3 - (n - 1) * 6 + i * 12, y)
    put(c, l)
    x, y = 23, 74                                        # (+) = 0, in nim
    e = layer()
    e.stamp([".#####.", "#..#..#", "#..#..#", "#######", "#..#..#", "#..#..#", ".#####."], x, y, {"#": LINE})
    e.rect(x + 10, y + 1, x + 14, y + 2, LINE)
    e.rect(x + 10, y + 4, x + 14, y + 5, LINE)
    e.stamp([".####.", "##..##", "##..##", "##..##", "##..##", "##..##", ".####."], x + 18, y, {"#": RED})
    c.a = np.where(e.a > 0, e.a, c.a)
    return finish(c)


# ----------------------------------------------------------- generator ----
A5 = [".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"]
BOLT = ["...##", "..##.", ".##..", "####.", "..##.", ".##..", "##...", "#...."]


def generator():
    """A dynamo whose wheel is the Ace's 15-cycle: fifteen studs, the Ace's
    lit, and the Ace on the hub."""
    c = card("#4f6367")
    yy, xx = c.grid()
    c.fill(window() & ((xx + yy) % 8 == 0), "#5b7177")
    cy = 47
    l = layer()
    l.fill(ring_mask(l, CX, cy, 14.5, 21.5), GOLD)
    d = np.hypot(xx - CX, yy - cy)
    l.fill(ring_mask(l, CX, cy, 14.5, 21.5) & ((xx - CX) + (yy - cy) > 14), GOLD_D)
    l.fill(ring_mask(l, CX, cy, 20.5, 21.5) & ((xx - CX) + (yy - cy) < -12), GOLD_L)
    for k in range(5):                                   # spokes
        a = np.radians(-90 + 36 + k * 72)
        l.line(CX, cy, int(round(CX + 14 * np.cos(a))), int(round(cy + 14 * np.sin(a))), "#a0a8b0", w=2)
    disc(l, CX, cy, 7, GREY_L)
    l.fill((d <= 7) & (d > 5.5) & ((xx - CX) + (yy - cy) > 0), GREY)
    put(c, l)
    for k in range(15):                                  # the cycle
        a = np.radians(-90 + k * 24)
        x, y = int(round(CX + 18 * np.cos(a))), int(round(cy + 18 * np.sin(a)))
        c.rect(x - 1, y - 1, x + 1, y + 1, RED if k == 0 else WHITE)
        c.pxs([(x + 1, y + 1), (x, y + 1), (x + 1, y)], RED_D if k == 0 else GREY)
    c.stamp(A5, CX - 2, cy - 3, {"#": RED})
    for x, y, f in ((49, 9, False), (56, 20, False), (17, 78, True), (10, 66, True)):
        b = layer()
        b.stamp(BOLT, x, y, {"#": "#ffe36e"}, fh=f)
        put(c, b)
    # which way it turns
    c.fill(ring_mask(c, CX, cy, 24.5, 25.5) & (xx > CX + 4) & (yy < cy - 8), WHITE)
    c.pxs([(53, 38), (54, 38), (56, 38), (57, 38), (55, 39), (54, 37), (56, 37), (55, 38), (55, 40)], WHITE)
    return finish(c, WHITE)


# -------------------------------------------------------------- grundy ----
def grundy():
    """Solomon Grundy's stone. Carved on it: 0 1 2, then a gap, then 4 5.
    The gap is the mex."""
    c = card()
    l = layer()
    yy, xx = l.grid()
    mound = l.ellipse_mask(CX - 1, 73, 20, 9) & (yy <= 74)
    stone = l.rrect_mask(21, 18, 49, 70, 11)
    l.fill(stone, "#c9d1dd")
    l.fill(stone & (xx >= 46), "#a3aebd")
    l.fill(stone & ~erode(stone) & (xx < 30) & (yy < 40), "#e6ebf2")
    l.fill(stone & ~erode(stone) & (yy < 22), "#e6ebf2")
    l.fill(mound, GREEN)
    l.fill(mound & (yy >= 71), GREEN_D)
    for x, y in ((24, 66), (43, 67), (50, 69), (33, 66)):
        l.pxs([(x, y), (x + 1, y - 1)], GREEN_L)
    put(c, l)
    for i, n in enumerate("012"):
        text(c, [n], 26 + i * 7 + (n == "1"), 27, LINE)
    c.hline(25, 45, 38, "#a3aebd")
    for i in range(0, 7, 2):                             # the missing 3
        c.pxs([(25 + i, 42), (25 + i, 50), (25, 42 + i), (31, 42 + i)], RED)
    c.pxs([(31, 50), (25, 50)], RED)
    text(c, ["4"], 33, 42, LINE)
    text(c, ["5"], 40, 42, LINE)
    f = layer()                                          # a flower left on it
    f.vline(17, 58, 67, GREEN_D)
    f.pxs([(18, 63), (16, 61)], GREEN_D)
    f.stamp([".##.", "#oo#", "#oo#", ".##."], 16, 54, {"#": RED, "o": GOLD})
    put(c, f)
    return finish(c)


# ------------------------------------------------------------ hotstrat ----
def flame_mask(c, cx, base, h, w, lean=0.0):
    yy, xx = c.grid()
    t = (yy - (base - h)) / float(h)                      # 0 at the tip, 1 at the base
    t = np.clip(t, 0, 1)
    hw = np.where(t < 0.68, (t / 0.68) ** 1.25, np.sqrt(np.clip(1 - ((t - 0.68) / 0.34) ** 2, 0, 1)))
    off = lean * (1 - t) ** 2
    return (np.abs(xx - cx - off) <= hw * w / 2.0) & (yy > base - h) & (yy <= base)


def flame(l, cx, base, h, w, lean):
    l.fill(flame_mask(l, cx, base, h, w, lean), RED)
    l.fill(flame_mask(l, cx, base, h * 0.68, w * 0.62, lean * 0.5), GOLD)
    l.fill(flame_mask(l, cx, base, h * 0.38, w * 0.32, 0), "#ffe36e")


def hotstrat():
    """Three fires, and the move: in the hottest."""
    c = card()
    l = layer()
    for cx, h, w, lean in ((17, 15, 10, 1), (29, 26, 14, -2), (43, 44, 20, 3)):
        flame(l, cx, 74, h, w, lean)
        l.rect(cx - w // 2, 75, cx + w // 2, 77, "#864b1c")
        l.hline(cx - w // 2, cx + w // 2, 75, "#a8642c")
    put(c, l)
    a = layer()                                          # the move
    a.rect(41, 8, 45, 17, BLUE)
    for i in range(7):
        a.hline(43 - (6 - i), 43 + (6 - i), 18 + i, BLUE)
    a.rect(44, 8, 45, 17, BLUE_D)
    a.vline(41, 8, 16, BLUE_L)
    put(c, a)
    return finish(c)


# --------------------------------------------------------- thermograph ----
def thermograph():
    """A thermograph on graph paper: the walls meet at the temperature and
    the mast stands over the mean."""
    c = card("#f7f1e4")
    yy, xx = c.grid()
    win = window()
    c.fill(win & ((xx % 6 == 5) | (yy % 6 == 2)), "#d3e3ec")
    base, half, top = 74, 19, 13
    tent = c.poly_mask([(CX - half, base), (CX, base - half), (CX + half, base)])
    c.fill(tent & (yy < base), "#ffc9c4")
    c.fill(tent & (yy < base) & ((xx + yy) % 3 == 0), "#ff9a92")
    c.hline(11, 59, base, LINE)                          # the number line
    c.hline(11, 59, base + 1, LINE)
    for x in range(CX - 24, CX + 25, 6):
        c.vline(x, base + 2, base + 3, LINE)
    for y in range(base - half, base, 2):                # the mean, dropped to the line
        c.px(CX, y + 1, LINE)
    for x in range(12, CX - 1, 2):                       # the temperature, read off the side
        c.px(x, base - half, BLUE)
    l = layer()
    for i in range(half + 1):
        for s in (-1, 1):
            l.rect(CX + s * (half - i), base - i - 2, CX + s * (half - i), base - i, RED)
    l.rect(CX - 1, top, CX + 1, base - half, RED)
    l.pxs([(CX - 2, top + 2), (CX + 2, top + 2), (CX - 3, top + 3), (CX + 3, top + 3), (CX - 2, top + 3),
           (CX + 2, top + 3), (CX, top - 1)], RED)
    l.fill(l.mask() & (yy >= base), 0)
    put(c, l)
    c.hline(11, 59, base, LINE)
    t = layer()                                          # a thermometer, for the name
    t.rect(52, 12, 54, 27, WHITE)
    t.vline(53, 17, 27, RED)
    disc(t, 53, 30, 3, RED)
    t.px(52, 29, RED_L)
    put(c, t)
    for y in (15, 19, 23):
        c.px(56, y, LINE)
        c.px(57, y, LINE)
    return finish(c)


# ------------------------------------------------------------- sprouts ----
LEAF = ["......####..",
        "....###l###.",
        "..####l####d",
        ".####l####dd",
        "####l####dd.",
        "###l###ddd..",
        "#######d....",
        ".####......."]


def sprouts():
    """Sprouts: two spots, a curve between them, and on the curve a new
    spot. This one has come up."""
    c = card()
    a, b, n, m = (19, 72), (50, 36), (34, 50), (45, 66)
    t = np.linspace(0, 1, 240)

    def bez(p0, p1, p2, p3):
        q = [(1 - t) ** 3 * p0[k] + 3 * (1 - t) ** 2 * t * p1[k] + 3 * (1 - t) * t * t * p2[k] + t ** 3 * p3[k]
             for k in (0, 1)]
        return list(zip(np.round(q[0]).astype(int), np.round(q[1]).astype(int)))

    for pts in (bez(a, (14, 50), (22, 48), n), bez(n, (44, 52), (50, 48), b),
                bez(a, (26, 88), (46, 84), m), bez(m, (44, 54), (58, 50), b)):
        for x, y in pts:
            c.rect(x - 1, y - 1, x + 1, y + 1, LINE)
    s = layer()                                          # the seedling
    for x, y in bez(n, (33, 42), (37, 34), (35, 22)):
        s.rect(x - 1, y, x + 1, y, GREEN)
        s.px(x + 1, y, GREEN_D)
    for x, y, fh, col in ((36, 12, False, GREEN), (22, 18, True, GREEN)):
        s.stamp(LEAF, x, y, {"#": col, "d": GREEN_D, "l": GREEN_L if col == GREEN else WHITE}, fh=fh)
    put(c, s)
    for (x, y), col, hi, sh in ((a, BLUE, BLUE_L, BLUE_D), (b, RED, RED_L, RED_D), (n, GOLD, GOLD_L, GOLD_D),
                                (m, GREY_L, WHITE, GREY)):
        d = layer()
        disc(d, x, y, 4.3, col)
        yy, xx = d.grid()
        d.fill(d.mask() & ((xx - x) + (yy - y) >= 4), sh)
        d.pxs([(x - 1, y - 3), (x - 2, y - 2), (x - 3, y - 1), (x - 2, y - 3)], hi)
        put(c, d)
    return finish(c)


# -------------------------------------------------------------- cantor ----
BITS = ["01101", "10010", "11100", "00111", "10101"]


def cantor():
    """The diagonal argument: five rows of digits, the diagonal marked, and
    under the line the row that differs from every one of them."""
    c = card()
    x0, y0 = 18, 15
    for j, row in enumerate(BITS):
        for i, ch in enumerate(row):
            x, y = x0 + 7 * i, y0 + 9 * j
            if i == j:
                c.rect(x - 1, y, x + 5, y + 8, RED)
                c.rect(x - 1, y + 8, x + 5, y + 8, RED_D)
            text(c, [ch], x + (ch == "1"), y, WHITE if i == j else "#7d8c97")
    for i in range(5):                                   # down the diagonal
        x, y = x0 + 7 * i, y0 + 9 * i
        if i:
            c.pxs([(x - 2, y - 1), (x - 3, y - 2)], RED_D)
    c.hline(x0 - 2, x0 + 34, 62, LINE)
    c.hline(x0 - 2, x0 + 34, 63, LINE)
    for i in range(5):
        ch = "1" if BITS[i][i] == "0" else "0"
        text(c, [ch], x0 + 7 * i + (ch == "1"), 66, BLUE)
    return finish(c)


# ------------------------------------------------------------ paradise ----
def paradise():
    """The paradise that Cantor created: an island, and omegas on the wing."""
    c = card("#8fd3ff")
    yy, xx = c.grid()
    win = window()
    t = np.clip((yy - 4) / 52.0, 0, 1)
    c.bands(win & (yy < 58), t, ["#3f9be8", "#55abf0", "#6fbcf6", "#8fcdfb", "#b5e0ff"], dither=0.12)
    c.fill(win & (yy >= 58), BLUE)
    for y, x0, n in ((60, 8, 9), (60, 30, 14), (63, 18, 8), (63, 44, 10), (67, 6, 6), (70, 40, 12),
                     (74, 12, 10), (79, 30, 9), (84, 10, 12), (86, 44, 8)):
        c.fill(win & (yy == y) & (xx >= x0) & (xx < x0 + n), BLUE_L)
    c.fill(win & (yy >= 78) & ((xx + yy) % 2 == 0), BLUE_D)
    s = layer()                                          # the sun
    disc(s, 49, 20, 8, "#ffe36e")
    c.a = np.where(s.a > 0, s.a, c.a)
    c.fill(ring_mask(c, 49, 20, 9.5, 10.6) & win & ((xx + yy) % 2 == 0), "#fff6c4")
    text(c, ["ω"], 46, 15, GOLD)
    l = layer()                                          # the island
    isl = l.ellipse_mask(30, 66, 19, 7) & (yy <= 66)
    l.fill(isl, "#f6dfa0")
    l.fill(isl & (yy >= 64), "#e2c27a")
    put(c, l)
    c.fill(win & (yy == 67) & (xx >= 9) & (xx <= 51), WHITE)
    p = layer()                                          # the palm
    for i, y in enumerate(range(60, 33, -1)):
        x = 27 + int(round(5 * np.sin((60 - y) / 27.0 * 1.3)))
        p.rect(x, y, x + 2, y, "#a8642c" if i % 4 else "#864b1c")
    put(c, p)
    f = layer()
    for dx, dy, n in ((-1, 0.25, 14), (1, 0.25, 14), (-1, 0.75, 11), (1, 0.75, 11), (-1, -0.35, 10), (1, -0.35, 10)):
        for i in range(n):
            x = 32 + dx * i
            y = int(round(32 + dy * i + 0.035 * i * i * (1 if dy > 0 else 2.0) - (2 if dy < 0 else 0)))
            f.rect(x, y, x, y + 1 + (i > 2 and i < n - 3), GREEN if dy != 0.75 else GREEN_D)
    put(c, f)
    c.pxs([(33, 33), (31, 34), (34, 35)], "#864b1c")       # coconuts
    for x, y in ((14, 16), (22, 26), (52, 34)):          # omegas, flying
        text(c, ["ω"], x, y - 3, LINE)
    return finish(c, WHITE)


# -------------------------------------------------------------- conway ----
def turn_hue(a, hue, sat=1.0):
    out = a.copy()
    for rgb in {tuple(p) for p in a[a[..., 3] > 0][:, :3]}:
        h, l, s = colorsys.rgb_to_hls(*(v / 255.0 for v in rgb))
        r, g, b = colorsys.hls_to_rgb(hue, l, min(1.0, s * sat))
        m = (a[..., :3] == rgb).all(-1) & (a[..., 3] > 0)
        out[m, :3] = [round(r * 255), round(g * 255), round(b * 255)]
    return out


PLATE_INK, PLATE_PAPER = "#4f6367", "#f7f1e4"


def legend(hue, sat):
    """A legendary's background card: Triboulet's marble with its hue
    turned, the plate kept and wiped clean for a sign."""
    src = V.cell("Jokers", 4, 8)
    hx = V.hexes(src)
    plate = np.isin(hx, ["f7f1e4", "ffffff", "4f6367", "e3dac8", "b7a88a"])
    plate[:76] = False
    a = np.where(plate[..., None], src, turn_hue(src, hue, sat))
    c = Canvas(W, H, PAL)
    v = (a[..., 0].astype(int) << 16) | (a[..., 1].astype(int) << 8) | a[..., 2]
    for u in np.unique(v[a[..., 3] > 0]):
        c.a[(a[..., 3] > 0) & (v == u)] = PAL.index(f"#{u:06x}")
    c.rect(12, 80, 58, 85, PLATE_PAPER)                  # TRIBOULET off the plate
    c.pxs([(10, 82), (60, 82)], PLATE_INK)
    return c


HUES = dict(conway=(0.74, 0.9), berlekamp=(0.915, 0.8), guy=(0.29, 0.62))


def conway():
    """Triboulet's marble turned violet, the plate signed { | } with a blue
    Left and a red Right."""
    c = legend(*HUES["conway"])
    brace = [".##", ".#.", "#..", "#..", ".#.", ".##"]
    c.stamp(brace, 23, 80, {"#": PLATE_INK})
    c.stamp(brace, 45, 80, {"#": PLATE_INK}, fh=True)
    c.rect(35, 80, 36, 85, PLATE_INK)                    # |
    c.rect(28, 81, 32, 84, BLUE)                         # Left
    c.rect(39, 81, 43, 84, RED)                          # Right
    return c


SKIN, SKIN_D, SKIN_L = "#f3c7a3", "#dba27d", "#fbdcc0"
HAIR, HAIR_D, HAIR_L = "#cfd3da", "#a9afba", "#eef0f3"
GLIDER = [".#.", "..#", "###"]


def conway_soul():
    """John Horton Conway: the long grey hair, the beard, the grin, and a
    Life glider on his jumper."""
    c = new()
    yy, xx = c.grid()
    wave = 1.6 * np.sin(yy / 3.0) + 0.8 * np.sin(yy / 1.3 + 1)
    hw = 12.5 + 7.5 * np.clip((yy - 20) / 30.0, 0, 1) + wave * np.clip((yy - 24) / 10.0, 0, 1)
    hair = ((np.abs(xx - CX) <= hw) & (yy >= 22) & (yy <= 55 - (np.abs(xx - CX) % 5 == 2) - 2 * (np.abs(xx - CX) % 7 == 4))
            ) | (c.ellipse_mask(CX, 26, 13, 13) & (yy <= 26))
    body = c.ellipse_mask(CX, 70, 23, 19) & (yy >= 51) & (yy <= 68)
    face = c.ellipse_mask(CX, 29, 10.5, 12.5)
    beard = (c.ellipse_mask(CX, 45, 12, 12) & (yy >= 36)) | c.ellipse_mask(CX, 39, 11.5, 4.5)
    c.fill(body, GREEN)
    c.fill(body & (((xx - CX) > 16) | (yy >= 67)), GREEN_D)
    c.fill(body & (yy == 52) & (xx < CX + 10), GREEN_L)
    c.fill(hair, HAIR)
    c.fill(hair & (xx >= 48), HAIR_D)
    for x0 in (17, 20, 23, 26, 44, 47, 50, 53):         # strands
        for y in range(18, 56):
            x = x0 + int(round(1.2 * np.sin(y / 4.0 + x0)))
            if hair[y, x] and not face[y, x] and (y + x0) % 9:
                c.px(x, y, HAIR_L if x0 < CX else HAIR_D)
    c.fill(hair & (yy <= 16) & (xx < CX + 4), HAIR_L)
    c.fill(face, SKIN)
    c.fill(face & (xx >= CX + 7), SKIN_D)
    c.fill(face & (yy <= 21) & (xx < CX + 3) & (xx > CX - 7), SKIN_L)   # the high forehead
    c.fill(beard, HAIR_L)
    c.fill(beard & ((xx - CX) > 7), HAIR)
    for x in (26, 29, 32, 35, 38, 41, 44):               # beard strands
        for y in range(45, 58):
            if beard[y, x] and (y + 2 * x) % 6:
                c.px(x, y, HAIR if x < 42 else HAIR_D)
    for x0 in (28, 38):                                  # eyes, under heavy brows
        c.rect(x0, 28, x0 + 3, 30, WHITE)
        c.rect(x0 + 1, 28, x0 + 2, 30, LINE)
        c.hline(x0 - 1, x0 + 4, 26, HAIR_D)
        c.hline(x0, x0 + 3, 25, HAIR)
        c.px(x0 + 1, 28, BLUE)
    c.pxs([(27, 27), (43, 27)], HAIR_D)
    c.pxs([(34, 30), (34, 31), (34, 32), (34, 33), (33, 34), (36, 34), (37, 34)], SKIN_D)
    c.rect(35, 31, 36, 33, SKIN_L)
    c.pxs([(26, 33), (27, 33), (27, 34), (43, 33), (44, 33), (43, 34)], "#f0a090")   # cheeks
    c.pxs([(34, 35), (35, 35), (36, 35)], HAIR)
    c.fill(c.ellipse_mask(CX, 37.5, 8.5, 2.6), HAIR)       # moustache
    c.hline(28, 42, 39, HAIR)
    c.hline(31, 39, 39, WHITE)                           # the grin
    c.hline(31, 39, 40, WHITE)
    c.pxs([(33, 40), (35, 40), (37, 40)], HAIR_L)
    c.hline(32, 38, 41, RED_D)
    c.hline(33, 37, 42, RED)
    c.pxs([(30, 39), (40, 39), (31, 41), (39, 41)], LINE)
    for j, row in enumerate(GLIDER):                     # Life, on the jumper
        for i, ch in enumerate(row):
            if ch == "#":
                c.rect(46 + 2 * i, 59 + 2 * j, 47 + 2 * i, 60 + 2 * j, WHITE)
    c.outline(LINE)
    c.fill(dilate(beard | hair) & ~(beard | hair) & body, GREEN_D)
    return c


# ------------------------------------------------------------ birthday ----
FLAME = [".#.", ".#.", "#o#", "#o#", ".#."]


def birthday():
    """A cake with a candle a day: three whole ones for the 3, then a half
    and a quarter. 3 1/4 is five days old."""
    c = card()
    l = layer()
    yy, xx = l.grid()
    plate = l.ellipse_mask(CX, 78, 24, 5)
    l.fill(plate, GREY_L)
    l.fill(plate & (yy >= 80), GREY)
    side = (l.ellipse_mask(CX, 73, 19, 5) & (yy >= 73)) | ((np.abs(xx - CX) <= 19) & (yy >= 54) & (yy <= 73))
    l.fill(side, "#f3dcae")                              # sponge
    l.fill(side & (xx >= CX + 13), "#d2b07c")
    jam = (l.ellipse_mask(CX, 65, 19, 5) & ~l.ellipse_mask(CX, 63, 19, 5)) & side
    l.fill(jam, RED)
    l.fill(jam & (xx >= CX + 13), RED_D)
    top = l.ellipse_mask(CX, 54, 19, 5)
    drip = side & (yy <= 57 + 2 * ((xx % 7) < 3) + ((xx % 7) == 1)) | (l.ellipse_mask(CX, 57, 19, 5) & side)
    l.fill(drip, "#ffc9c4")                              # icing, run down the side
    l.fill(drip & (xx >= CX + 13), "#ff9a92")
    l.fill(top, WHITE)
    l.fill(top & ~erode(top) & (yy > 54), "#ffc9c4")
    l.a = np.roll(l.a, -3, 0)                            # centre the picture on the card
    put(c, l)
    k = layer()                                          # the candles
    for x, h, col, hi, sh in ((20, 24, BLUE, BLUE_L, BLUE_D), (27, 24, BLUE, BLUE_L, BLUE_D),
                              (34, 24, BLUE, BLUE_L, BLUE_D), (41, 12, RED, RED_L, RED_D),
                              (48, 6, GOLD, GOLD_L, GOLD_D)):
        base = 54 + (1 if x in (27, 41) else 0) - (1 if x in (20, 48) else 0)
        k.rect(x, base - h, x + 2, base, col)
        k.vline(x + 2, base - h, base, sh)
        for y in range(base - h + 2, base, 4):
            k.pxs([(x, y), (x + 1, y + 1)], hi)
        k.px(x + 1, base - h - 1, LINE)                  # wick
        k.stamp(FLAME, x, base - h - 6, {"#": GOLD, "o": "#ffe36e"})
    k.a = np.roll(k.a, -3, 0)
    put(c, k)
    return finish(c)


# ------------------------------------------------------------- hilbert ----
def hilbert():
    """Hilbert's Hotel: floors without end, every window lit, and the sign
    says there is room for one more."""
    c = card("#3c4368")
    yy, xx = c.grid()
    win = window()
    c.bands(win, np.clip((yy - 4) / 86.0, 0, 1), ["#2c3252", "#343a5e", "#3c4368", "#48507a"], dither=0.1)
    for x, y in ((17, 9), (24, 22), (11, 58), (52, 36), (60, 8), (44, 7), (19, 40), (61, 30), (13, 74)):
        c.px(x, y, "#dfe6f5")
    half = lambda y: 5.0 + (y - 4) * 15.5 / 86.0         # the tower narrows as it climbs
    l = layer()
    tower = (np.abs(xx - CX) <= half(yy)) & win
    l.fill(tower, "#8a9ab0")
    l.fill(tower & ((xx - CX) > half(yy) * 0.72), "#6d7c93")
    l.fill(tower & (yy <= 12), "#7887a0")
    l.fill(tower & (yy <= 7), "#66758f")
    put(c, l)
    y, h = 77.0, 7.0
    while y - h > 3:                                     # floor on floor
        y0, y1 = int(round(y - h)), int(round(y)) - 1
        for i in range(5):
            f = -0.78 + 0.39 * i
            x0 = int(round(CX + f * half(y1) - half(y1) * 0.12))
            x1 = max(x0, int(round(CX + f * half(y1) + half(y1) * 0.12)))
            c.rect(x0, max(y0, 5), x1, max(y1, y0), "#ffe36e" if h >= 2 else "#e6d283")
            if h >= 4:
                c.hline(x0, x1, max(y1, y0), GOLD)
        gap = max(1.0, h * 0.38)
        y, h = y - h - gap, max(1.0, h * 0.86)
    d = layer()                                          # the door, and its awning
    d.rect(CX - 4, 81, CX + 4, 90, "#ffe36e")
    d.vline(CX, 82, 90, GOLD)
    d.rect(CX - 7, 78, CX + 7, 80, RED)
    d.hline(CX - 7, CX + 7, 80, RED_D)
    put(c, d)
    c.px(CX - 2, 86, LINE)
    c.px(CX + 2, 86, LINE)
    s = layer()                                          # the sign: + 1
    s.rect(45, 14, 61, 28, "#1e2b2d")
    put(c, s, line="#ffe36e")
    c.rect(41, 19, 43, 20, "#6d7c93")
    text(c, ["+"], 48, 17, "#ffe36e")
    text(c, ["1"], 56, 17, RED_L)
    return finish(c, WHITE)


# ----------------------------------------------------------- berlekamp ----
def berlekamp():
    """The marble turned rose; the plate signed with Dots and Boxes: a box
    to Left, a box to Right, and a third with two sides still to draw, and dots beyond."""
    c = legend(*HUES["berlekamp"])
    c.rect(24, 81, 28, 84, BLUE)
    c.rect(30, 81, 34, 84, RED)
    c.hline(23, 41, 80, PLATE_INK)
    c.hline(23, 35, 85, PLATE_INK)
    for x in (23, 29, 35):
        c.vline(x, 80, 85, PLATE_INK)
    c.pxs([(41, 85), (47, 80), (47, 85)], PLATE_INK)     # dots nobody has joined yet
    return c


def specs(c, y, lens="#dff1fb", rim=LINE):
    """Spectacles: two lenses, x 27..33 and 37..43, on rows y..y+5."""
    for x0 in (27, 37):
        c.rect(x0 + 1, y, x0 + 5, y + 5, rim)
        c.rect(x0, y + 1, x0 + 6, y + 4, rim)
        c.rect(x0 + 1, y + 1, x0 + 5, y + 4, lens)
        c.rect(x0 + 2, y + 2, x0 + 3, y + 3, LINE)       # the eye
        c.px(x0 + 2, y + 2, BLUE)
        c.px(x0 + 5, y + 1, WHITE)
    c.hline(34, 36, y + 2, rim)
    c.pxs([(26, y + 2), (25, y + 2), (44, y + 2), (45, y + 2)], rim)


def berlekamp_soul():
    """Elwyn Berlekamp: white hair combed across, big spectacles, a smile,
    jacket and tie, and a thermometer in the breast pocket."""
    c = new()
    yy, xx = c.grid()
    body = c.ellipse_mask(CX, 70, 23, 20) & (yy >= 50) & (yy <= 68)
    face = c.ellipse_mask(CX, 34, 11, 13.5)
    neck = (np.abs(xx - CX) <= 6) & (yy >= 44) & (yy <= 52)
    crown = c.ellipse_mask(CX, 29, 12, 12) & (yy <= 29)
    hair = (crown & ~(c.ellipse_mask(CX + 3, 33, 9.5, 10) & (yy >= 23))) | c.ellipse_mask(CX - 2, 21, 9, 4)
    ears = c.ellipse_mask(CX - 11.5, 35, 2, 3) | c.ellipse_mask(CX + 11.5, 35, 2, 3)
    c.fill(body, BLUE)
    c.fill(body & (((xx - CX) > 16) | (yy >= 67)), BLUE_D)
    shirt = c.poly_mask([(CX - 9, 49), (CX + 9, 49), (CX, 63)]) & (body | neck)
    c.fill(neck, SKIN_D)
    c.fill(shirt, WHITE)
    c.fill(ears, SKIN)
    c.fill(face, SKIN)
    c.fill(face & (xx >= CX + 8), SKIN_D)
    c.fill(face & (yy >= 25) & (yy <= 27) & (xx > CX - 3) & (xx < CX + 7), SKIN_L)
    c.fill(hair, HAIR_L)
    c.fill(hair & (xx >= CX + 8), HAIR)
    c.fill(hair & ~erode(hair) & (yy >= 23) & (xx < CX + 8), HAIR)
    for x, y in ((29, 20), (32, 19), (35, 19), (26, 23), (38, 20), (30, 22)):
        c.pxs([(x, y), (x + 1, y)], HAIR_D)
    for x0 in (28, 38):                                  # brows
        c.hline(x0, x0 + 4, 28, HAIR_D)
    specs(c, 30)
    c.pxs([(35, 36), (35, 37), (34, 38), (35, 38), (36, 38)], SKIN_D)   # nose
    c.pxs([(27, 38), (28, 38), (42, 38), (43, 38)], "#f0a090")
    c.hline(31, 39, 41, "#b5654f")                       # the smile
    c.pxs([(30, 40), (40, 40), (29, 39), (41, 39)], "#b5654f")
    c.hline(32, 38, 42, WHITE)
    c.hline(33, 37, 43, "#b5654f")
    c.hline(33, 37, 46, SKIN_D)                          # chin
    c.pxs([(CX - 7, 50), (CX - 6, 51), (CX + 7, 50), (CX + 6, 51)], GREY_L)   # collar
    for i in range(13):                                  # lapels
        c.px(CX - 10 + i * 10 // 13, 51 + i, BLUE_D)
        c.px(CX + 10 - i * 10 // 13, 51 + i, BLUE_D)
    c.rect(CX - 1, 50, CX + 1, 52, RED_D)                # the tie
    c.rect(CX - 1, 53, CX + 1, 60, RED)
    c.px(CX, 61, RED)
    c.vline(CX + 1, 53, 60, RED_D)
    c.rect(46, 60, 51, 61, BLUE_L)                       # the pocket
    c.rect(48, 55, 49, 60, WHITE)                        # and a thermometer in it
    c.vline(48, 57, 60, RED)
    c.outline(LINE)
    return c


# ----------------------------------------------------------------- guy ----
def guy():
    """The marble turned green; the plate signed with the small numbers."""
    c = legend(*HUES["guy"])
    for i, n in enumerate("012345"):
        text(c, ["s" + n], 21 + i * 5, 78, PLATE_INK)
    return c


def guy_soul():
    """Richard Guy: white hair and beard, wire spectacles, an anorak, a
    rucksack's straps and a hill walker's stick."""
    c = new()
    yy, xx = c.grid()
    body = c.ellipse_mask(CX, 70, 22, 19) & (yy >= 51) & (yy <= 68)
    face = c.ellipse_mask(CX, 30, 9.5, 13)
    hair = (c.ellipse_mask(CX, 27, 12.5, 12) & (yy <= 36)) & ~(c.ellipse_mask(CX, 24, 8, 9) & (yy >= 14))
    hair |= c.ellipse_mask(CX - 10, 28, 4, 6) | c.ellipse_mask(CX + 10, 28, 4, 6)
    beard = (c.ellipse_mask(CX, 40, 10.5, 11) & (yy >= 36)) | (c.ellipse_mask(CX, 38, 10.5, 4))
    c.fill(body, RED)
    c.fill(body & (((xx - CX) > 15) | (yy >= 67)), RED_D)
    c.fill(body & (yy == 52) & (xx < CX + 8), RED_L)
    for s in (-1, 1):                                    # rucksack straps
        c.rect(CX + s * 13 - 1, 53, CX + s * 13 + 1, 68, "#864b1c")
        c.px(CX + s * 13, 59, GOLD)
    c.fill(hair, HAIR_L)
    c.fill(hair & (xx >= CX + 9), HAIR)
    c.fill(face, SKIN)
    c.fill(face & (xx >= CX + 6), SKIN_D)
    c.fill(face & (yy <= 21) & (np.abs(xx - CX) < 5), SKIN_L)
    for x, y in ((24, 24), (23, 28), (46, 25), (47, 29), (25, 31)):
        c.px(x, y, HAIR_D)
    c.fill(beard, HAIR_L)
    c.fill(beard & ((xx - CX) > 6), HAIR)
    for x in (28, 31, 34, 37, 40):
        for y in range(43, 52):
            if beard[y, x] and (y + 2 * x) % 5:
                c.px(x, y, HAIR)
    for x0 in (28, 38):
        c.hline(x0, x0 + 4, 25, HAIR)
    specs(c, 27, lens=SKIN_L, rim="#8a94a0")
    c.pxs([(35, 32), (35, 33), (35, 34), (34, 35), (36, 35)], SKIN_D)
    c.pxs([(28, 35), (42, 35)], "#f0a090")
    c.fill(c.ellipse_mask(CX, 37.5, 7.5, 2.2), HAIR)     # moustache
    c.hline(32, 38, 40, RED_D)                           # a smile in the beard
    c.pxs([(31, 39), (39, 39)], RED_D)
    k = layer()                                          # the stick
    k.rect(55, 30, 56, 68, "#a8642c")
    k.vline(56, 30, 68, "#864b1c")
    k.rect(53, 28, 57, 30, "#a8642c")
    k.rect(53, 48, 58, 52, SKIN)                         # and the hand on it
    k.hline(53, 58, 52, SKIN_D)
    k.outline(LINE)
    c.outline(LINE)
    c.a = np.where(k.a > 0, k.a, c.a)
    c.fill(dilate(beard | hair) & ~(beard | hair) & body, RED_D)
    return c


CELLS = dict(bouton=bouton, generator=generator, grundy=grundy, hotstrat=hotstrat,
             thermograph=thermograph, sprouts=sprouts, cantor=cantor, paradise=paradise,
             conway=conway, conway_soul=conway_soul, birthday=birthday, hilbert=hilbert,
             berlekamp=berlekamp, berlekamp_soul=berlekamp_soul, guy=guy, guy_soul=guy_soul)


def sheet_canvas():
    out = Canvas(W * len(ORDER), H, PAL)
    for i, n in enumerate(ORDER):
        out.a[:, i * W:(i + 1) * W] = CELLS[n]().a
    return out


def outputs():
    return {"jokers.png": (sheet_canvas(), None)}
