"""mods.py — the modifier overlays, and where modifier labels go.

mods.png (and mods_hc.png, the same pixels): one row of 71x95 full-card
overlays drawn over a card front.

  0  nimbus   the halo for the * modifier: a small ring over each corner
              index, in Spectral blue.
  1  wild     the wild rank's index: a stamp, a white ± on mult red, pasted
              over the rank glyph in both corners. It is solid, so it covers
              whatever rank is underneath (the 10 is widest) on any card
              body, and it leaves the suit pip alone.

Modifier *labels* are not in this sheet. They are coloured text, composed
by the Lua side out of glyphs.png and drawn straight onto the card beside
the corner index, so the corner reads as the value: 3+½, 7±2, K+ω. This
file owns their geometry and colours (ANCHORS, COLOURS -> art/layout.lua):
for each rank, where the first glyph cell goes so the text stands on the
index's baseline one pixel clear of it, and how far it can run before it
meets that rank's pips or portrait.

Drawn here; the colours are vanilla's families, the pixels are not. (The
anchors are measured from vanilla's fronts at build time.)

fable, 2026-11-14 (claude-fable-5-2)
"""
from __future__ import annotations

import numpy as np

from pixel import Canvas, Palette, dilate

W, H = 71, 95
KINDS = ["nimbus", "wild"]
INDEX_Y = 7                    # vanilla index glyphs: rows 7..14
LABEL_Y = INDEX_Y              # a glyph cell here stands on the index baseline
LABEL_ROWS = (7, 15)           # rows a label's cells cover
RIGHT_LIMIT = 66               # keep clear of the card's right edge

PAL = Palette(
    spectral="#4584fa", spectral_d="#2f62c9",
    red="#fe5f55", red_d="#cc4846", white="#ffffff",
)
# Label colours by role: chosen to read as bare text on the card's white.
COLOURS = dict(
    offset="#009dff",          # surreal offset: chips blue
    heat="#fe5f55",            # ±t: mult red
    infinite="#c8900f",        # ω: gold, deepened until it holds on white
    infinitesimal="#4584fa",   # ↑ ↓: Spectral blue, the halo's
    knockout="#ffffff",        # the card-white edge under a label (see NOTES)
)
RANKS = [str(n) for n in range(2, 11)] + ["Jack", "Queen", "King", "Ace", "ww_0", "ww_1", "ww_C"]


# -------------------------------------------------------------- nimbus ----
HALO = """
.sssssss.
s.......s
.ddddddd.
"""


def corners(t):
    c = Canvas(W, H, PAL)
    c.blit(t)
    c.blit(t.rot180())
    return c


def nimbus():
    """A halo over the index: x 5..13, y 3..5; and again, turned."""
    t = Canvas(W, H, PAL)
    t.stamp(HALO, 5, 3, {"s": "spectral", "d": "spectral_d"})
    return corners(t)


# ---------------------------------------------------------------- wild ----
# The stamp covers x 5..14, y 6..15: every vanilla index glyph (x 6..13,
# y 7..14) and a pixel round it. White on mult red, rimmed in the red stake
# chip's shade: ± is the heat sign, and white holds on red where it washes
# out on gold.
TILE = """
.dddddddd.
drrrWWrrrd
drrrWWrrrd
drWWWWWWrd
drWWWWWWrd
drrrWWrrrd
drrrWWrrrd
drrrrrrrrd
drWWWWWWrd
.dddddddd.
"""
WILD_BOX = dict(x=5, y=6, w=10, h=10)


def wild():
    t = Canvas(W, H, PAL)
    t.stamp(TILE, WILD_BOX["x"], WILD_BOX["y"], {"d": "red_d", "r": "red", "W": "white"})
    return corners(t)


def cells():
    return [nimbus(), wild()]


def sheet_canvas():
    out = Canvas(W * len(KINDS), H, PAL)
    for i, c in enumerate(cells()):
        out.blit(c, i * W, 0)
    return out


# ------------------------------------------------------- label anchors ----
def rank_masks(key):
    """The four suits' ink masks for a rank, normal contrast."""
    import fronts
    import vanilla as V
    if key.startswith("ww_"):
        f = {"ww_0": fronts.zero, "ww_1": fronts.one, "ww_C": fronts.cavalier}[key]
        return [f(s)[..., 3] > 0 for s in fronts.SUITS]
    col = RANKS.index(key)
    return [V.cell("8BitDeck", col, r)[..., 3] > 0 for r in range(4)]


def anchors():
    """{rank: (x, y, free, max)}. x, y: top-left of the label's first glyph
    cell (one clear column after the index, standing on its baseline).
    free: columns before the label would touch that rank's own art, the
    tightest of the four suits. max: columns to the right limit."""
    out = {}
    for key in RANKS:
        ms = rank_masks(key)
        right = max(int(np.nonzero(m[INDEX_Y:INDEX_Y + 8, 3:16].any(0))[0].max()) + 3 for m in ms)
        x = right + 2
        free = RIGHT_LIMIT - x
        for m in ms:
            cols = np.nonzero(m[LABEL_ROWS[0]:LABEL_ROWS[1] + 1, x:RIGHT_LIMIT].any(0))[0]
            if len(cols):
                free = min(free, int(cols[0]))
        out[key] = (x, LABEL_Y, free, RIGHT_LIMIT - x)
    return out


def lua():
    a = anchors()
    rows = "\n".join(
        f'    ["{k}"] = {{ x = {x}, y = {y}, free = {f}, max = {m} }},' for k, (x, y, f, m) in a.items())
    cols = "\n".join(f'    {k} = "{v}",' for k, v in COLOURS.items())
    b = WILD_BOX
    return (
        "-- Generated by art/build.py from art/mods.py; do not edit. All px at 1x, from the cell's top-left.\n"
        "-- cells: assets/{1x,2x}/mods.png, one row of 71x95 overlays, in this order.\n"
        "-- label[rank]: x, y = top-left of the label's first glyph cell (glyphs.png cells), one clear\n"
        "--   column after that rank's index and on its baseline. free = columns before the label touches\n"
        "--   that rank's own pips/portrait; max = columns to the right limit. Past `free`, draw the\n"
        "--   knockout first (the label in colours.knockout at the 8 one-pixel offsets), then the label.\n"
        "-- The second copy is the composed label (knockout included) turned 180 degrees about `turn`.\n"
        "-- wild_box: what the wild tile covers in the top-left corner (the index, not the suit pip).\n"
        "return {\n"
        f'  cells = {{ {", ".join(chr(34) + k + chr(34) for k in KINDS)} }},\n'
        "  label = {\n" + rows + "\n  },\n"
        "  colours = {\n" + cols + "\n  },\n"
        "  turn = { x = 35.5, y = 47.5 },\n"
        f"  wild_box = {{ x = {b['x']}, y = {b['y']}, w = {b['w']}, h = {b['h']} }},\n"
        "}\n")


def outputs():
    s = sheet_canvas()
    return {"mods.png": (s, None), "mods_hc.png": (s, None)}


# ------------------------------------------------------------- preview ----
def label(parts, key, knockout=True):
    """A 71x95 RGBA overlay: a label (list of (glyph names, role)) at a
    rank's anchor, with its turned copy. The reference for the Lua side."""
    import glyphs
    names = [n for ns, _ in parts for n in ns]
    roles = [r for ns, r in parts for _ in ns]
    placed, _ = glyphs.layout(names)
    x0, y0, _, _ = anchors()[key]
    pal = Palette(**COLOURS)
    c = Canvas(W, H, pal)
    ink = c.blank()
    for (n, gx, dy), role in zip(placed, roles):
        m = glyphs.glyph(n).mask()
        for j, i in zip(*np.nonzero(m)):
            c.px(x0 + gx + i, y0 + dy + j, role)
            ink[y0 + dy + j, x0 + gx + i] = True
    if knockout:
        c.fill(dilate(ink, diag=True) & ~ink, "knockout")
    out = Canvas(W, H, pal)
    out.blit(c)
    out.blit(c.rot180())
    return out


def preview(save, on_cards, k):
    import fronts
    import vanilla as V
    from PIL import Image

    def over(key, row, layers, hc=False, knockout=True):
        if key.startswith("ww_"):
            a = {"ww_0": fronts.zero, "ww_1": fronts.one, "ww_C": fronts.cavalier}[key](fronts.SUITS[row])
            a = fronts.hc(a, fronts.SUITS[row], key == "ww_C") if hc else a
        else:
            a = V.cell("8BitDeck_opt2" if hc else "8BitDeck", RANKS.index(key), row)
        im = on_cards(a)
        for c in layers:
            c = label(c, key, knockout) if isinstance(c, list) else c
            im.alpha_composite(c.image())
        return im

    def strip(ims):
        out = Image.new("RGBA", (W * len(ims), H), (0, 0, 0, 0))
        for i, im in enumerate(ims):
            out.alpha_composite(im, (i * W, 0))
        return out

    nb, wd = cells()
    half, heat2 = [(["+", "½"], "offset")], [(["±", "2"], "heat")]
    om, up = [(["+", "ω"], "infinite")], [(["↑"], "infinitesimal")]
    mixed = [(["+", "½"], "offset"), (["±", "½"], "heat")]
    for nm, ko in (("a", True), ("a_bare", False)):
        save(strip([
            over("3", 0, [half], knockout=ko), over("7", 3, [heat2], knockout=ko),
            over("King", 1, [om], knockout=ko), over("5", 2, [up, nb], knockout=ko),
            over("10", 0, [mixed], knockout=ko), over("ww_C", 3, [heat2], knockout=ko),
        ]), f"mods_{nm}.png", k)
    save(strip([
        over("Ace", 3, [[(["−", "s5", "s/", "s1", "s6"], "offset")]]), over("ww_0", 0, [om, nb]),
        over("Queen", 2, [half], hc=True), over("9", 1, [heat2], hc=True),
        over("10", 3, [wd]), over("King", 0, [wd, nb]), over("4", 2, [wd], hc=True),
    ]), "mods_b.png", k)
    save(sheet_canvas().image(), "mods_sheet.png", k, bg="#ffffff")
