"""fronts.py — card fronts for the three born ranks: 0, 1 and C, the Cavalier.

ranks.png / ranks_hc.png: columns 0, 1, C; rows Hearts, Clubs, Diamonds,
Spades (vanilla's 8BitDeck row order, which is Steamodded's rank-atlas
order), then Wild, Quintessence's fifth suit (see the Wild row below; read
through quint.py). Cells are 71x95 and composed exactly like vanilla's: transparent
except for the ink, so the card body shows through.

  0   {|}, the game with no moves. The field holds one pip, but only its
      outline: the place where a move would be, with nothing in it.
  1   one ordinary pip in the middle (the 3's centre pip). Not an Ace:
      the Ace's pip is three times the size.
  C   the Cavalier, tarot's knight, between Jack and Queen. Each suit's
      Cavalier rides in on the Jack of its sister suit (hearts <-> diamonds,
      clubs <-> spades), re-inked, with the hat and face replaced by a great
      helm and a plume.

Everything is built in vanilla's normal colours. The high-contrast sheet is
the same drawing passed through hc(): vanilla's high-contrast deck is not a
palette swap (suit ink is a top-to-bottom ramp, courts re-ink their accents
per suit), so hc() learns, per suit, what each (colour, row) turns into from
8BitDeck vs 8BitDeck_opt2 and applies that.

The index digits are the strokes of vanilla's "10"; the C, the outline pip,
the helm and the plume are drawn here. Pips and court bodies are
LocalThunk's pixels (see NOTES.md).

fable, 2026-11-14 (claude-fable-5-2)
"""
from __future__ import annotations

from collections import Counter, defaultdict
from functools import lru_cache

import numpy as np

import quint as Q
import vanilla as V
from pixel import Canvas, Palette, erode, sprite_rows

W, H = 71, 95
SUITS = ["H", "C", "D", "S"]                     # sheet rows
ROW = {s: i for i, s in enumerate(SUITS)}
INK = dict(H="f03464", C="235955", D="f06b3f", S="3c4368")   # index + pip colour
DARK = dict(H="374649", C="235955", D="374649", S="3c4368")  # court outline
ACCENT = dict(H="f03464", C="fe5f55", D="f06b3f", S="fe5f55")  # court cloth
SISTER = dict(H="D", D="H", C="S", S="C")
TEN, THREE, JACK = 8, 1, 9                       # 8BitDeck columns


def rgba(hexcol):
    return np.array([int(hexcol[i:i + 2], 16) for i in (0, 2, 4)] + [255], np.uint8)


def paint(cell, mask, hexcol):
    cell[mask] = rgba(hexcol)


def rot180(a):
    return a[::-1, ::-1].copy()


# ------------------------------------------------------------ the index ----
C_GLYPH = """
..####.
.##..##
##.....
##.....
##.....
##.....
.##..##
..####.
"""


@lru_cache(maxsize=None)
def index_mask(rank):
    """The corner glyph, 71x95 mask, top-left only. Vanilla glyphs live in
    x 6..13, y 7..14 and are centred on x = 9, over the small pip."""
    m = np.zeros((H, W), bool)
    ten = V.cell("8BitDeck", TEN, 0)[..., 3] > 0
    if rank == "0":
        m[7:15, 7:12] = ten[7:15, 9:14]          # the 10's nought, re-centred
    elif rank == "1":
        m[7:15, 8:10] = ten[7:15, 6:8]           # the 10's one, re-centred
    else:
        for j, r in enumerate(sprite_rows(C_GLYPH)):
            for i, ch in enumerate(r):
                m[7 + j, 6 + i] = ch == "#"
    return m


def small_pip(suit):
    m = np.zeros((H, W), bool)
    m[16:26, 4:16] = V.cell("8BitDeck", TEN, ROW[suit])[16:26, 4:16, 3] > 0
    return m


def centre_pip(suit):
    """The 3's middle pip, where it stands."""
    m = np.zeros((H, W), bool)
    m[34:61, 20:51] = V.cell("8BitDeck", THREE, ROW[suit])[34:61, 20:51, 3] > 0
    return m


def corners(cell, rank, suit):
    m = index_mask(rank) | small_pip(suit)
    paint(cell, m | m[::-1, ::-1], INK[suit])


def zero(suit):
    cell = np.zeros((H, W, 4), np.uint8)
    corners(cell, "0", suit)
    p = centre_pip(suit)
    paint(cell, p & ~erode(p), INK[suit])
    return cell


def one(suit):
    cell = np.zeros((H, W, 4), np.uint8)
    corners(cell, "1", suit)
    paint(cell, centre_pip(suit), INK[suit])
    return cell


# --------------------------------------------------------- the Cavalier ----
# A great helm seen from the front: eye slit, a gilt cross, breaths.
HELM = """
...kkkkkkk...
..kwweeeaak..
.kwweeeeeaak.
.kweeegeeeak.
.kweeegeeeak.
.kgggggggggk.
.kkkkkgkkkkk.
.kweeegeeeak.
.kwekegekeak.
.kweeegeeeak.
.kwekegekeak.
.kweeegeeaak.
.kkweegeeakk.
..kweegeaak..
..kkeeeaakk..
...kkaaakk...
.....kkk.....
"""
# The plume, springing from the crown and falling to the right.
PLUME = """
.........kkkkk...
......kkkpppppkk.
....kkpppwwwwpppk
...kppwwwpppppppk
..kppwppppppkkkk.
..kpwpppkkkk.....
..kpwpkk.........
..kpkk...........
...k.............
"""
# Per source Jack (the row it is read from): what to clear (hat, face),
# where the frame's top rule has to be made good, where the helm goes, and
# which way the plume falls. Coordinates are in the top half of the cell.
CAV = {
    "H": dict(clear=[(23, 4, 44, 15), (26, 16, 41, 17)], face=(26, 16, 39, 31),
              rule=(23, 44), helm=(26, 15), plume=+1),
    "C": dict(clear=[(23, 5, 43, 17)], face=(26, 17, 35, 29),
              rule=(23, 43), helm=(24, 15), plume=+1, darken=[(36, 17, 42, 19)]),
    "D": dict(clear=[(29, 5, 48, 17)], face=(36, 17, 45, 29),
              rule=(29, 48), helm=(34, 15), plume=-1),
    "S": dict(clear=[(27, 4, 48, 15)], face=(34, 16, 44, 31),
              rule=(27, 48), helm=(33, 15), plume=-1),
}


def stamp(cell, art, x, y, key, flip=False):
    for j, r in enumerate(sprite_rows(art)):
        if flip:
            r = r[::-1]
        for i, ch in enumerate(r):
            if ch in key and 0 <= x + i < W and 0 <= y + j < H:
                cell[y + j, x + i] = rgba(key[ch])


def cavalier(suit):
    src = SISTER[suit]
    a = V.cell("8BitDeck", JACK, ROW[src])
    hx = V.hexes(a)
    cell = a.copy()
    # re-ink the sister suit's cloth and outline as ours
    for old, new in ((ACCENT[src], ACCENT[suit]), (DARK[src], DARK[suit])):
        if old != new:
            paint(cell, hx == old, new)
    # vanilla's own corners go; ours come back at the end
    cell[_corner()] = 0
    top = cell[:48].copy()                       # work on the top half
    p = CAV[src]
    for x0, y0, x1, y1 in p["clear"]:
        top[y0:y1 + 1, x0:x1 + 1] = 0
    x0, y0, x1, y1 = p["face"]                   # the face becomes hair/mail
    face = np.zeros(top.shape[:2], bool)
    face[y0:y1 + 1, x0:x1 + 1] = np.isin(hx[y0:y1 + 1, x0:x1 + 1], ("e6e6e6", "acacac"))
    top[face] = rgba(DARK[suit])
    for x0, y0, x1, y1 in p.get("darken", ()):   # hat left over in the hair
        sub = top[y0:y1 + 1, x0:x1 + 1]
        sub[(sub[..., :3] == rgba(ACCENT[suit])[:3]).all(-1)] = rgba(DARK[suit])
    top[11:13, p["rule"][0]:p["rule"][1] + 1] = rgba(DARK[suit])
    key = dict(k=DARK[suit], w="ffffff", e="e6e6e6", a="acacac", g="ffa300", p=ACCENT[suit])
    hxx, hy = p["helm"]
    flip = p["plume"] < 0
    stamp(top, PLUME, hxx - 7 if flip else hxx + 3, hy - 8, key, flip=flip)
    stamp(top, HELM, hxx, hy, key)
    cell[:48] = top
    cell[47:] = rot180(cell)[47:]                # double-headed, like vanilla
    corners(cell, "C", suit)
    return cell


# ------------------------------------------------------- high contrast ----
def _corner():
    m = np.zeros((H, W), bool)
    m[5:27, 3:16] = True
    return m | m[::-1, ::-1]


@lru_cache(maxsize=None)
def ramp(suit, court=False):
    """Vanilla's high-contrast ink for this suit, by row: pips and indices
    of the number cards, or the corner indices of the courts (the clubs
    courts' corners run a shade off the number cards')."""
    out = {}
    for c in ((9, 10, 11) if court else list(range(9)) + [12]):
        hx = V.hexes(V.cell("8BitDeck_opt2", c, ROW[suit]))
        if court:
            hx[~_corner()] = ""
        for y in range(H):
            u = set(hx[y]) - {""}
            if u:
                out[y] = u.pop()
    return [out[min(out, key=lambda k: abs(k - y))] for y in range(H)]


@lru_cache(maxsize=None)
def court_map(suit):
    """(normal colour, row) -> high-contrast colour, learned from this suit's
    three vanilla courts with their corner indices masked off."""
    votes = defaultdict(Counter)
    corner = _corner()
    for c in (9, 10, 11):
        a = V.hexes(V.cell("8BitDeck", c, ROW[suit]))
        b = V.hexes(V.cell("8BitDeck_opt2", c, ROW[suit]))
        for y, x in zip(*np.nonzero((a != "") & ~corner)):
            votes[(a[y, x], y)][b[y, x]] += 1
    by_colour = defaultdict(dict)
    for (h, y), v in votes.items():
        by_colour[h][y] = v.most_common(1)[0][0]
    return by_colour


def hc(cell, suit, court):
    """The high-contrast version of a normal-contrast cell."""
    out = cell.copy()
    hx = V.hexes(cell)
    r = ramp(suit, court)
    corner = _corner()
    cm = court_map(suit) if court else {}
    for y, x in zip(*np.nonzero(hx != "")):
        h = hx[y, x]
        if not court or corner[y, x]:
            new = r[y]
        else:
            rows = cm.get(h)
            new = rows[min(rows, key=lambda k: abs(k - y))] if rows else h
        out[y, x] = rgba(new)
    return out


# ------------------------------------------------------------- the Wild row ----
# Quintessence's Wild suit: an asterisk for a pip, muted purple (green in the
# high-contrast deck), courts collaged from vanilla's. This row is derived
# from Quintessence's built sheets exactly as rows 0..3 are from vanilla's:
# the index digits from its 10, the corner pip from its 10, the 0 and 1 from
# its 3's centre pip, the Cavalier from its Jack.
WILD, WILD_HC, WILD_DARK = "8b64b4", "1fa84f", "374649"


def wild_index(rank):
    m = np.zeros((H, W), bool)
    ten = Q.cell(Q.TEN)[..., 3] > 0
    if rank == "0":
        m[7:15, 7:12] = ten[7:15, 9:14]
    elif rank == "1":
        m[7:15, 8:10] = ten[7:15, 6:8]
    else:
        m = index_mask("C").copy()
    return m


def wild_corners(cell, rank):
    m = wild_index(rank)
    m[16:26, 4:16] = Q.cell(Q.TEN)[16:26, 4:16, 3] > 0   # the small asterisk
    paint(cell, m | m[::-1, ::-1], WILD)


def wild_pip():
    m = np.zeros((H, W), bool)
    m[34:61, 20:51] = Q.cell(Q.THREE)[34:61, 20:51, 3] > 0
    return m


def wild_zero():
    cell = np.zeros((H, W, 4), np.uint8)
    wild_corners(cell, "0")
    p = wild_pip()
    paint(cell, p & ~erode(p), WILD)
    return cell


def wild_one():
    cell = np.zeros((H, W, 4), np.uint8)
    wild_corners(cell, "1")
    paint(cell, wild_pip(), WILD)
    return cell


def wild_cavalier():
    """Wild has no sister suit, so its Cavalier rides in on its own Jack.
    That Jack's head is the Jack of Hearts' (where it stands in vanilla), so
    the Hearts entry of CAV fits it; what is left of the red hat goes to
    Wild purple, and the helm's plume is purple too."""
    a = Q.cell(Q.JACK)
    hx = V.hexes(a)
    cell = a.copy()
    cell[_corner()] = 0
    top = cell[:48].copy()
    p = CAV["H"]
    for x0, y0, x1, y1 in p["clear"]:
        top[y0:y1 + 1, x0:x1 + 1] = 0
    x0, y0, x1, y1 = p["face"]
    face = np.zeros(top.shape[:2], bool)
    face[y0:y1 + 1, x0:x1 + 1] = np.isin(hx[y0:y1 + 1, x0:x1 + 1], ("e6e6e6", "acacac"))
    top[face] = rgba(WILD_DARK)
    top[(top[..., :3] == rgba(INK["H"])[:3]).all(-1) & (top[..., 3] > 0)] = rgba(WILD)
    top[11:13, p["rule"][0]:p["rule"][1] + 1] = rgba(WILD_DARK)
    key = dict(k=WILD_DARK, w="ffffff", e="e6e6e6", a="acacac", g="ffa300", p=WILD)
    hxx, hy = p["helm"]
    stamp(top, PLUME, hxx + 3, hy - 8, key)
    stamp(top, HELM, hxx, hy, key)
    cell[:48] = top
    cell[47:] = rot180(cell)[47:]
    wild_corners(cell, "C")
    return cell


@lru_cache(maxsize=None)
def wild_court_map():
    """(normal colour, row) -> high-contrast colour, learned from
    Quintessence's three Wild courts, normal against high contrast."""
    votes = defaultdict(Counter)
    for c in (Q.JACK, Q.QUEEN, Q.KING):
        a, b = V.hexes(Q.cell(c)), V.hexes(Q.cell(c, hc=True))
        for y, x in zip(*np.nonzero(a != "")):
            votes[(a[y, x], y)][b[y, x]] += 1
    by_colour = defaultdict(dict)
    for (h, y), v in votes.items():
        by_colour[h][y] = v.most_common(1)[0][0]
    return by_colour


def wild_hc(cell):
    """Quintessence's high-contrast Wild: purple goes to green, flat (its
    pips and indices have no ramp); the courts' accents go as its own
    courts' do, row by row."""
    out = cell.copy()
    hx = V.hexes(cell)
    cm = wild_court_map()
    for y, x in zip(*np.nonzero(hx != "")):
        rows = cm.get(hx[y, x])
        out[y, x] = rgba(rows[min(rows, key=lambda k: abs(k - y))] if rows else hx[y, x])
    return out


WILD_ROW = 4


# ---------------------------------------------------------------- sheet ----
def cells():
    """{(col, row): normal-contrast RGBA cell}."""
    return {(c, ROW[s]): f(s) for s in SUITS for c, f in enumerate((zero, one, cavalier))}


def sheet_rgba(high_contrast=False):
    out = np.zeros((H * 5, W * 3, 4), np.uint8)
    for (c, r), cell in cells().items():
        if high_contrast:
            cell = hc(cell, SUITS[r], court=(c == 2))
        out[r * H:(r + 1) * H, c * W:(c + 1) * W] = cell
    for c, f in enumerate((wild_zero, wild_one, wild_cavalier)):
        cell = wild_hc(f()) if high_contrast else f()
        out[WILD_ROW * H:, c * W:(c + 1) * W] = cell
    return out


def outputs():
    return {"ranks.png": sheet_rgba(False), "ranks_hc.png": sheet_rgba(True)}
