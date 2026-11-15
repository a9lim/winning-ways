"""font.py — ww_symbols.ttf, a fallback font for the signs m6x11plus lacks.

Balatro's text font (m6x11plus, Daniel Linssen) has ± and × but no ω, ∞,
vulgar fractions, arrows or circled operators, and LÖVE silently drops what
a font lacks. This builds a second font to hang behind it with
Font:setFallbacks: the same em (1024), the same pixel (64 units, 16 to the
em), the same ascent and descent (768 / -256), glyphs standing on the same
line (the font's letters sit two pixels below the baseline, at y = -128,
and rise eleven pixels to y = 576), drawn hard left with one pixel of
advance after them, as square-pixel outlines.

The metrics are read from the game's font at build time and checked; no
outline is taken from it. Every glyph here is drawn in this file.

Rows are given top (y = 576) to bottom (y = -128), eleven of them.

fable, 2026-11-14 (claude-fable-5-2)
"""
from __future__ import annotations

import io
import zipfile
from pathlib import Path

from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.ttLib import TTFont

import glyphs as G
import vanilla as V

PX, TOP, ROWS = 64, 576, 11


def rows(*r, top=0):
    out = ["."] * top + list(r)
    return out + ["."] * (ROWS - len(out))


def fraction(n, d):
    """Small digits either side of a slash: the card labels' fractions, at
    the font's pixel. One-pixel strokes; two would not fit eleven rows."""
    grid = [[" "] * 9 for _ in range(ROWS)]
    for j, row in enumerate(G.SMALL[n]):
        for i, p in enumerate(row):
            grid[j][i] = p
    for j, row in enumerate(G.SMALL[d]):
        for i, p in enumerate(row):
            grid[6 + j][6 + i] = p
    for x, y in ((6, 1), (6, 2), (5, 3), (5, 4), (4, 5), (3, 6), (3, 7), (2, 8), (2, 9)):
        grid[y][x] = "#"
    return ["".join(r).replace(" ", ".") for r in grid]


GLYPHS = {
    "ω": ("omega", rows(".##..##.", "##....##", "##....##", "##.##.##", "##.##.##", "##.##.##",
                        "########", ".##..##.", top=3)),
    "∞": ("infinity", rows(".###..###.", "##.####.##", "##..##..##", "##..##..##", "##.####.##",
                           ".###..###.", top=3)),
    "↑": ("arrowup", rows("..##..", ".####.", "######", "..##..", "..##..", "..##..",
                          "..##..", "..##..", "..##..", "..##..", top=1)),
    "↓": ("arrowdown", rows("..##..", "..##..", "..##..", "..##..", "..##..", "..##..", "..##..",
                            "######", ".####.", "..##..", top=1)),
    "⊕": ("circleplus", rows("..######..", ".##.##.##.", "##..##..##", "##..##..##", "##########",
                             "##########", "##..##..##", "##..##..##", ".##.##.##.", "..######..", top=1)),
    "⊗": ("circlemultiply", rows("..######..", ".##....##.", "####..####", "##.####.##", "##..##..##",
                                 "##..##..##", "##.####.##", "####..####", ".##....##.", "..######..",
                                 top=1)),
    "−": ("minus", rows("######", "######", top=5)),
    "½": ("onehalf", fraction("1", "2")),
    "¼": ("onequarter", fraction("1", "4")),
    "¾": ("threequarters", fraction("3", "4")),
    "⅛": ("oneeighth", fraction("1", "8")),
    "⅜": ("threeeighths", fraction("3", "8")),
    "⅝": ("fiveeighths", fraction("5", "8")),
    "⅞": ("seveneighths", fraction("7", "8")),
}


def outline(grid):
    """The pixel mask's boundary as closed loops (clockwise outside, the
    TrueType way), in font units."""
    on = {(x, r) for r, row in enumerate(grid) for x, ch in enumerate(row) if ch == "#"}
    edges = set()
    for x, r in on:
        x0, x1, y1, y0 = x * PX, (x + 1) * PX, TOP - r * PX, TOP - (r + 1) * PX
        for e in (((x0, y0), (x0, y1)), ((x0, y1), (x1, y1)), ((x1, y1), (x1, y0)), ((x1, y0), (x0, y0))):
            if (e[1], e[0]) in edges:
                edges.remove((e[1], e[0]))
            else:
                edges.add(e)
    nxt = {}
    for a, b in edges:
        nxt.setdefault(a, []).append(b)
    loops = []
    while nxt:
        start = next(iter(nxt))
        loop, p, d = [start], start, None
        while True:
            outs = nxt[p]
            q = outs[0]
            if len(outs) > 1 and d is not None:           # at a pinch, turn right
                q = min(outs, key=lambda o: ((o[0] - p[0]) * d[1] - (o[1] - p[1]) * d[0]))
            outs.remove(q)
            if not outs:
                del nxt[p]
            d = (q[0] - p[0], q[1] - p[1])
            if q == start:
                break
            loop.append(q)
            p = q
        keep = [pt for i, pt in enumerate(loop)            # drop points on straight runs
                if (pt[0] - loop[i - 1][0]) * (loop[(i + 1) % len(loop)][1] - pt[1])
                != (pt[1] - loop[i - 1][1]) * (loop[(i + 1) % len(loop)][0] - pt[0])]
        loops.append(keep)
    return loops


def game_metrics():
    with zipfile.ZipFile(V.archive_path()) as z:
        f = TTFont(io.BytesIO(z.read("resources/fonts/m6x11plus.ttf")))
    cm = f.getBestCmap()
    return dict(upm=f["head"].unitsPerEm, ascent=f["hhea"].ascent, descent=f["hhea"].descent,
                gap=f["hhea"].lineGap, zero=f["hmtx"][cm[ord("0")]][0],
                missing=[ch for ch in GLYPHS if ord(ch) not in cm])


def build(path):
    m = game_metrics()
    assert (m["upm"], m["ascent"], m["descent"], m["zero"]) == (16 * PX, 12 * PX, -4 * PX, 7 * PX), m
    order, cmap, glyf, hmtx = [".notdef"], {}, {}, {}
    pen = TTGlyphPen(None)
    glyf[".notdef"] = pen.glyph()
    hmtx[".notdef"] = (7 * PX, 0)
    for ch, (name, grid) in GLYPHS.items():
        pen = TTGlyphPen(None)
        for loop in outline(grid):
            pen.moveTo(loop[0])
            for pt in loop[1:]:
                pen.lineTo(pt)
            pen.closePath()
        order.append(name)
        cmap[ord(ch)] = name
        glyf[name] = pen.glyph()
        width = max(len(r.rstrip(".")) for r in grid)
        hmtx[name] = ((width + 1) * PX, 0)
    fb = FontBuilder(m["upm"], isTTF=True)
    fb.setupGlyphOrder(order)
    fb.setupCharacterMap(cmap)
    fb.setupGlyf(glyf)
    fb.setupHorizontalMetrics(hmtx)
    fb.setupHorizontalHeader(ascent=m["ascent"], descent=m["descent"], lineGap=m["gap"])
    fb.setupOS2(sTypoAscender=m["ascent"], sTypoDescender=m["descent"], sTypoLineGap=m["gap"],
                usWinAscent=m["ascent"], usWinDescent=-m["descent"], sxHeight=6 * PX, sCapHeight=9 * PX)
    fb.setupNameTable(dict(familyName="WW Symbols", styleName="Regular",
                           uniqueFontIdentifier="WW Symbols: Winning Ways",
                           fullName="WW Symbols", psName="WWSymbols-Regular", version="Version 1.0",
                           copyright="(c) 2026 a9lim and Claude. MIT licence.",
                           licenseDescription="MIT"))
    fb.setupPost()
    fb.setupDummyDSIG() if hasattr(fb, "setupDummyDSIG") else None
    path = Path(path)
    path.parent.mkdir(parents=True, exist_ok=True)
    fb.save(str(path))
    return m


def check_strip(path, out, text="Worth ω+14, ±½, ↑ ↓ ∞ ⊕ ⊗ −¼ ¾ ⅛ ⅜ ⅝ ⅞ x2", sizes=(16, 32)):
    """Render a line mixing the game's font and ours, falling back glyph by
    glyph the way LÖVE will; one strip per size, stacked."""
    from PIL import Image, ImageDraw, ImageFont
    with zipfile.ZipFile(V.archive_path()) as z:
        data = z.read("resources/fonts/m6x11plus.ttf")
    have = TTFont(io.BytesIO(data)).getBestCmap()
    strips = []
    for size in sizes:
        main = ImageFont.truetype(io.BytesIO(data), size)
        ours = ImageFont.truetype(str(path), size)
        im = Image.new("RGB", (len(text) * size, size + size // 2), (55, 70, 73))
        d = ImageDraw.Draw(im)
        d.fontmode = "1"
        x = size // 4
        for ch in text:
            f = main if ord(ch) in have else ours
            d.text((x, size // 4), ch, (255, 255, 255) if f is main else (234, 192, 88), font=f)
            x += round(f.getlength(ch))
        strips.append(im.crop((0, 0, x + size // 4, im.height)))
    w = max(s.width for s in strips)
    sheet = Image.new("RGB", (w, sum(s.height for s in strips)), (55, 70, 73))
    y = 0
    for s in strips:
        sheet.paste(s, (0, y))
        y += s.height
    Path(out).parent.mkdir(exist_ok=True)
    sheet.resize((sheet.width * 3, sheet.height * 3), Image.NEAREST).save(out)
    return out
