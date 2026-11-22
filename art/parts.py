"""parts.py — what a value-drawn card front is composed from, as data.

A card with a modifier draws its own front at run time (src/fronts.lua): the
corner index reads as the value (3+1/2, 7±2, *5, ω+14) in the rank's own
letterforms and ink, and the field shows the value's stops in pips. This
file gives the Lua side everything it needs, as assets/parts.lua (no texture):

  glyphs    the index alphabet, as masks. Rank glyphs are vanilla's own
            (2..9, 10, J, Q, K, A, and the 0 of its 10); C and the flagged 1
            are fronts.py's; ω + − ± * / ↑ ↓ are drawn here to match: seven
            or so pixels wide, eight rows, two-pixel strokes.
  suits     per suit: the pip (vanilla's, from the 3's centre) and the small
            corner pip (from the 10), and where pips go for 1..11 of them,
            in fill order. 2..10 are vanilla's own layouts, measured; 1 is
            the 3's centre pip; 11 is the 10 with that centre pip added.
  inks      per palette and suit, the index and pip ink by row: flat in the
            normal deck, a top-to-bottom ramp in the high-contrast one
            (fronts.ramp), and the courts' corner ink, which in clubs runs a
            shade off.

Fill order is the order pips turn solid: a value's Right stop counts solid
pips from the front of the list, its Left stop counts outlined ones after
them, and a fraction cuts the last. The orders are chosen so that prefixes
are a smaller rank's layout where one fits (the 6's first four are the 4's
corners; the 9's first five are the corners and the upper centre), and so
that the last pip, the one a fraction cuts, stands clear of both indices.

The Wild suit's parts are read from Quintessence's sheets (quint.py), as the
Wild row of the rank fronts is.

Pips, rank glyphs and layouts are LocalThunk's (or, for Wild, Quintessence's),
so the table is written to assets/, with the other built art, and
assets/NOTICE.md lists it; see NOTES.md.

fable, 2026-11-22 (claude-fable-5-2)
"""
from __future__ import annotations

import numpy as np

import fronts
import quint as Q
import vanilla as V
from pixel import components, sprite_rows

W, H = 71, 95
INDEX_X, INDEX_Y = 6, 7        # vanilla index glyphs start here
SUITS = ["Hearts", "Clubs", "Diamonds", "Spades", "quint_Wild"]
LETTER = dict(Hearts="H", Clubs="C", Diamonds="D", Spades="S")
RANK_COLS = {str(n): n - 2 for n in range(2, 11)} | {"J": 9, "Q": 10, "K": 11, "A": 12}

# Pips in reading order (top to bottom, left to right) -> fill order.
ORDER = {
    1: [0],
    2: [0, 1],
    3: [0, 2, 1],
    4: [0, 2, 3, 1],
    5: [0, 2, 4, 1, 3],
    6: [0, 1, 4, 5, 2, 3],
    7: [0, 1, 5, 6, 3, 4, 2],
    8: [0, 1, 6, 7, 3, 4, 2, 5],
    9: [0, 1, 7, 8, 2, 3, 4, 5, 6],
    10: [0, 1, 8, 9, 2, 7, 3, 4, 5, 6],
    11: [0, 1, 9, 10, 2, 8, 3, 4, 6, 7, 5],
}

DRAWN = {
    "+": """
......
..##..
..##..
######
######
..##..
..##..
......
""",
    "−": """
......
......
......
######
######
......
......
......
""",
    "±": """
..##..
..##..
######
######
..##..
..##..
......
######
######
""",
    "ω": """
........
........
.##..##.
##....##
##.##.##
##.##.##
########
.##..##.
""",
    "*": """
......
..##..
#.##.#
.####.
.####.
#.##.#
..##..
......
""",
    "/": """
...##
...##
..##.
..##.
.##..
.##..
##...
##...
""",
    "↑": """
..##..
.####.
######
..##..
..##..
..##..
..##..
..##..
""",
    "↓": """
..##..
..##..
..##..
..##..
..##..
######
.####.
..##..
""",
}


def art(s):
    return np.array([[ch == "#" for ch in r] for r in sprite_rows(s)])


def crop(m):
    ys, xs = np.nonzero(m)
    return m[ys.min():ys.max() + 1, xs.min():xs.max() + 1]


def crop_x(m):
    xs = np.nonzero(m.any(0))[0]
    return m[:, xs.min():xs.max() + 1]


def glyphs():
    """{name: mask}, each eight rows (± nine) from the index's top row."""
    out = {}
    for name, col in RANK_COLS.items():
        out[name] = crop_x(V.cell("8BitDeck", col, 0)[INDEX_Y:INDEX_Y + 8, 3:17, 3] > 0)
    out["0"] = crop_x(fronts.index_mask("0")[INDEX_Y:INDEX_Y + 8])
    out["1"] = crop_x(fronts.index_mask("1")[INDEX_Y:INDEX_Y + 8])
    out["C"] = crop_x(fronts.index_mask("C")[INDEX_Y:INDEX_Y + 8])
    for name, s in DRAWN.items():
        out[name] = art(s)
    return out


BIG = "ω"                      # the ω rank's centre: its glyph ×3, as the Ace's pip is ×3 a pip
BIG_SCALE = 3


def big_mask():
    g = art(DRAWN[BIG])
    g = g[np.nonzero(g.any(1))[0].min():]
    g = np.kron(g, np.ones((BIG_SCALE, BIG_SCALE), bool))
    m = np.zeros((H, W), bool)
    h, w = g.shape
    y, x = (H - h) // 2, (W - w) // 2
    m[y:y + h, x:x + w] = g
    return m


# ---------------------------------------------------------------- suits ----
def _cells(suit):
    """(the 3, the 10, {n: cell} for 2..10) of a suit, as ink masks."""
    if suit == "quint_Wild":
        get = lambda col: Q.cell(col)[..., 3] > 0
    else:
        row = fronts.ROW[LETTER[suit]]
        get = lambda col: V.cell("8BitDeck", col, row)[..., 3] > 0
    return get(1), get(8), {n: get(n - 2) for n in range(2, 11)}


def suit_parts(suit):
    three, ten, cells = _cells(suit)
    corner = fronts._corner()
    centre = np.zeros((H, W), bool)
    centre[34:61, 20:51] = three[34:61, 20:51]
    pip = crop(centre)
    small = np.zeros((H, W), bool)
    small[16:26, 4:16] = ten[16:26, 4:16]
    ys, xs = np.nonzero(small)

    def places(mask):
        out = []
        for piece in components(mask & ~corner, diag=True):
            x0, y0, x1, y1 = _bbox(piece)
            sub = mask[y0:y1 + 1, x0:x1 + 1]
            assert sub.shape == pip.shape, (suit, sub.shape, pip.shape)
            up, down = np.array_equal(sub, pip), np.array_equal(sub, pip[::-1, ::-1])
            assert up or down, (suit, x0, y0)
            out.append((x0, y0, not up))
        return sorted(out, key=lambda p: (p[1], p[0]))

    one = places(centre)
    layouts = {1: one}
    for n, cell in cells.items():
        layouts[n] = places(cell)
        assert len(layouts[n]) == n, (suit, n, len(layouts[n]))
    layouts[11] = sorted(layouts[10] + one, key=lambda p: (p[1], p[0]))
    return dict(
        pip=pip, small=crop(small), small_at=(int(xs.min()), int(ys.min())),
        layouts={n: [layouts[n][i] for i in ORDER[n]] for n in sorted(layouts)},
    )


def _bbox(m):
    ys, xs = np.nonzero(m)
    return int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())


# ----------------------------------------------------------------- inks ----
def _corner_ink(cell):
    """The corner's ink by row: 95 hex strings, rows without ink taking the nearest row's."""
    hx = V.hexes(cell)
    hx[~fronts._corner()] = ""
    seen = {}
    for y in range(H):
        u = set(hx[y]) - {""}
        if u:
            assert len(u) == 1, (y, u)
            seen[y] = u.pop()
    return [seen[min(seen, key=lambda k: abs(k - y))] for y in range(H)]


def inks():
    """{palette: {suit: {num, court}}}: a hex string when flat, else 95 of them."""
    out = {"lc": {}, "hc": {}}
    for suit in SUITS:
        for pal, hc in (("lc", False), ("hc", True)):
            if suit == "quint_Wild":
                num, court = _corner_ink(Q.cell(Q.TEN, hc=hc)), _corner_ink(Q.cell(Q.JACK, hc=hc))
            else:
                s = LETTER[suit]
                tex = "8BitDeck_opt2" if hc else "8BitDeck"
                num = fronts.ramp(s, False) if hc else _corner_ink(V.cell(tex, 8, fronts.ROW[s]))
                court = fronts.ramp(s, True) if hc else _corner_ink(V.cell(tex, 9, fronts.ROW[s]))
            out[pal][suit] = {k: (v[0] if len(set(v)) == 1 else v) for k, v in (("num", num), ("court", court))}
    return out


# ------------------------------------------------------------------ lua ----
def _rows(m):
    return "{ " + ", ".join('"' + "".join("#" if v else "." for v in r) + '"' for r in m) + " }"


def lua():
    q = lambda s: '"' + s + '"'
    g = glyphs()
    glyph_lines = "\n".join(f"    [{q(n)}] = {_rows(m)}," for n, m in g.items())
    suit_lines = []
    for suit in SUITS:
        p = suit_parts(suit)
        lay = "\n".join(
            f"        [{n}] = {{ " + ", ".join(f"{{ {x}, {y}{', true' if t else ''} }}" for x, y, t in ps) + " },"
            for n, ps in p["layouts"].items())
        suit_lines.append(
            f"    {suit} = {{\n"
            f"      pip = {_rows(p['pip'])},\n"
            f"      small = {_rows(p['small'])},\n"
            f"      small_at = {{ {p['small_at'][0]}, {p['small_at'][1]} }},\n"
            f"      layouts = {{\n{lay}\n      }},\n"
            f"    }},")
    ink_lines = []
    for pal, suits in inks().items():
        rows = []
        for suit, kinds in suits.items():
            vals = ", ".join(
                f"{k} = " + (q(v) if isinstance(v, str) else "{ " + ", ".join(q(h) for h in v) + " }")
                for k, v in kinds.items())
            rows.append(f"      {suit} = {{ {vals} }},")
        ink_lines.append(f"    {pal} = {{\n" + "\n".join(rows) + "\n    },")
    return (
        "-- Generated by art/build.py from art/parts.py; do not edit. All px at 1x, from the card's top-left.\n"
        "-- glyphs: the index alphabet, rows of # from y = index.y; a line of them starts at x = index.x and\n"
        "--   advances by each glyph's width + 1.\n"
        "-- suits[s]: pip and small (the corner pip, drawn at small_at) as rows of #; layouts[n] is where n pips\n"
        "--   go, { x, y, turned }, in fill order (solid first, then outlined; a fraction cuts the last).\n"
        "-- inks[palette][s]: the ink of number cards (num) and of the courts' corners (court): one hex, or 95 by row.\n"
        "-- big: the ω rank's centre, a glyph scaled up and centred.\n"
        "return {\n"
        f"  size = {{ w = {W}, h = {H} }},\n"
        f"  index = {{ x = {INDEX_X}, y = {INDEX_Y} }},\n"
        f"  big = {{ glyph = {q(BIG)}, scale = {BIG_SCALE} }},\n"
        "  glyphs = {\n" + glyph_lines + "\n  },\n"
        "  suits = {\n" + "\n".join(suit_lines) + "\n  },\n"
        "  inks = {\n" + "\n".join(ink_lines) + "\n  },\n"
        "}\n")
