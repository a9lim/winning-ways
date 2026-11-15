"""mods.py — the modifier overlays: four badge frames and the nimbus.

mods.png (and mods_hc.png, the same pixels): one row of 71x95 cells, each a
full-card overlay drawn over a card front.

  0  number    chips blue     a plain plate                (+½, −¼, +1)
  1  hot       mult red       the same plate, on fire       (±t)
  2  infinite  slate + gold   a dark plate with a gilt rim  (ω)
  3  game      purple         a plate with pointed ends     (anything else)
  4  nimbus    Spectral blue  a halo over each index, and a glint (*)

The badges sit top right, level with the rank index top left: the one
corner vanilla's fronts leave free (number cards' right pip column starts
below and to the left; courts only put the head of a sceptre there). All
four share one text box, TEXT, which is exactly the plate's fill: the Lua
side draws glyphs.png cells into it. The nimbus lives in the index corners
instead, so it combines with any badge.

Built the way vanilla builds its stickers (the Eternal sticker, the stake
chips): a `bfc7d5` outer ring, a ring of the colour's shade, a flat fill,
lettering in near-white. Drawn here; the colours are vanilla's, the pixels
are not.

fable, 2026-11-14 (claude-fable-5-2)
"""
from __future__ import annotations

import numpy as np

from pixel import Canvas, Palette, dilate, erode

W, H = 71, 95
TEXT = dict(x=48, y=7, w=17, h=9)                 # the shared text box, 1x
KINDS = ["number", "hot", "infinite", "game", "nimbus"]

PAL = Palette(
    ring="#bfc7d5",                               # every vanilla sticker's rim
    blue="#009dff", blue_d="#1685cb",             # chips; the blue stake chip's shade
    red="#fe5f55", red_d="#cc4846",               # mult; the red stake chip's shade
    gold="#eac058", gold_d="#c09533",             # gold; the gold stake chip's shade
    slate="#4f6367", slate_d="#445457",           # the black stake chip
    purple="#8867a5", purple_d="#6a4f85",
    spectral="#4584fa", spectral_d="#2f62c9",
    white="#fdfdfd",
)
# What the Lua side should tint the glyphs for each plate.
TEXT_COLOUR = dict(number="#fdfdfd", hot="#fdfdfd", infinite="#eac058", game="#fdfdfd")


def plate(c):
    """The plate's body: the text box plus a one-pixel rim, corners clipped."""
    x0, y0 = TEXT["x"] - 1, TEXT["y"] - 1
    x1, y1 = TEXT["x"] + TEXT["w"], TEXT["y"] + TEXT["h"]
    m = c.blank()
    m[y0:y1 + 1, x0:x1 + 1] = True
    for x, y in ((x0, y0), (x1, y0), (x0, y1), (x1, y1)):
        m[y, x] = False
    return m


def badge(fill, shade, extra=None, rim=None):
    """A sticker-style plate. `extra(c, body)` returns more body (flames,
    points) that takes the fill; the rim follows the whole outline."""
    c = Canvas(W, H, PAL)
    body = plate(c)
    whole = body | extra(c, body) if extra else body
    c.fill(dilate(whole) & ~whole, "ring")
    c.fill(whole, fill)
    c.fill(whole & ~erode(whole), shade)
    if rim:
        rim(c, body)
    return c


def flames(c, body):
    """Three tongues off the top edge."""
    m = c.blank()
    top = TEXT["y"] - 2                           # first row above the plate
    for x, h in ((51, 2), (52, 3), (53, 1), (56, 2), (57, 4), (58, 3), (59, 1),
                 (62, 1), (63, 3), (64, 2)):
        m[top - h + 1:top + 1, x] = True
    return m


def embers(c, body):
    """The flames' hearts, and the plate's top rim gone to fill where they
    join it."""
    top = TEXT["y"] - 1
    for x in (51, 52, 56, 57, 58, 63, 64):
        c.px(x, top, "red")
    for x, y in ((52, top - 1), (57, top - 1), (57, top - 2), (58, top - 1), (63, top - 1)):
        c.px(x, y, "gold")


def points(c, body):
    """Pointed ends, like the brackets of {L | R}."""
    m = c.blank()
    mid = TEXT["y"] + TEXT["h"] // 2
    for x in (TEXT["x"] - 2, TEXT["x"] + TEXT["w"] + 1):
        m[mid - 1:mid + 2, x] = True
    return m


def gilt(c, body):
    """Four sparks off the corners of the infinite plate."""
    x0, y0 = TEXT["x"] - 3, TEXT["y"] - 3
    x1, y1 = TEXT["x"] + TEXT["w"] + 2, TEXT["y"] + TEXT["h"] + 2
    for x, y in ((x0, y0), (x1, y0), (x0, y1), (x1, y1)):
        c.px(x, y, "gold")


HALO = """
.sssssss.
s.......s
.ddddddd.
"""
GLINT = """
.s.
sss
.s.
"""


def nimbus():
    """A halo over the index (x 5..13, y 3..5) and a glint beside it; the
    same turned, bottom right, like everything else in a card's corners."""
    t = Canvas(W, H, PAL)
    key = {"s": "spectral", "d": "spectral_d"}
    t.stamp(HALO, 5, 3, key)
    t.stamp(GLINT, 15, 6, key)
    c = Canvas(W, H, PAL)
    c.blit(t)
    c.blit(t.rot180())
    return c


def cells():
    return [
        badge("blue", "blue_d"),
        badge("red", "red_d", extra=flames, rim=embers),
        badge("slate", "gold", rim=gilt),
        badge("purple", "purple_d", extra=points),
        nimbus(),
    ]


def sheet_canvas():
    out = Canvas(W * len(KINDS), H, PAL)
    for i, c in enumerate(cells()):
        out.blit(c, i * W, 0)
    return out


def lua():
    t = TEXT
    cols = ", ".join(f'{k} = "{v}"' for k, v in TEXT_COLOUR.items())
    order = ", ".join(f'"{k}"' for k in KINDS)
    return (
        "-- Generated by art/build.py from art/mods.py; do not edit.\n"
        "-- assets/{1x,2x}/mods.png: one row of 71x95 overlays, in `cells` order.\n"
        "-- text: the box (1x px, from the cell's top-left) the badge frames leave for glyphs.\n"
        "-- text_colour: the tint each frame's lettering is drawn for.\n"
        "return {\n"
        f"  text = {{ x = {t['x']}, y = {t['y']}, w = {t['w']}, h = {t['h']} }},\n"
        f"  cells = {{ {order} }},\n"
        f"  text_colour = {{ {cols} }},\n"
        "}\n")


def outputs():
    s = sheet_canvas()
    return {"mods.png": (s, None), "mods_hc.png": (s, None)}


# ------------------------------------------------------------- preview ----
def lettered(i, names):
    """Cell i with a string of glyph names centred in the text box."""
    import glyphs
    c = cells()[i]
    wd = glyphs.layout(names)[1]
    x = TEXT["x"] + (TEXT["w"] - wd) // 2
    glyphs.text(c, names, x, TEXT["y"], TEXT_COLOUR[KINDS[i]])
    return c


def preview(save, on_cards, k):
    import vanilla as V
    from PIL import Image

    def over(col, row, layers, hc=False):
        im = on_cards(V.cell("8BitDeck_opt2" if hc else "8BitDeck", col, row))
        for c in layers:
            im.alpha_composite(c.image())
        return im

    def strip(ims):
        out = Image.new("RGBA", (W * len(ims), H), (0, 0, 0, 0))
        for i, im in enumerate(ims):
            out.alpha_composite(im, (i * W, 0))
        return out

    nb = cells()[4]
    save(strip([
        over(1, 0, [lettered(0, ["+", "½"])]),
        over(5, 3, [lettered(1, ["±", "2"])]),
        over(8, 2, [lettered(2, ["+", "ω"])]),
        over(3, 1, [lettered(3, ["↑"]), nb]),
        over(6, 0, [nb]),
    ]), "mods_a.png", k)
    save(strip([
        over(9, 0, [lettered(0, ["−", "¼"])]),
        over(11, 1, [lettered(1, ["±", "1", "0"]), nb]),
        over(10, 2, [lettered(2, ["ω"])]),
        over(11, 3, [lettered(3, ["+", "s5", "s/", "s1", "s6"])], hc=True),
        over(12, 3, [lettered(0, ["+", "1", "⅞"]), nb], hc=True),
    ]), "mods_b.png", k)
    save(sheet_canvas().image(), "mods_sheet.png", k, bg="#ffffff")
