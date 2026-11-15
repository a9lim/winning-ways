"""build.py — regenerate every texture.

    ~/.venv/bin/python -I art/build.py

Runs each sheet program and writes assets/1x/<name> and assets/2x/<name>,
the 2x being the 1x upscaled by exact nearest-neighbour x2; writes the two
small Lua tables the mod reads (art/glyphs.lua, art/layout.lua) and the
symbol font (assets/fonts/ww_symbols.ttf); then checks the sizes and metrics
the Lua side depends on.

The rank fronts, Omega, the packs, the jokers and the blind chip are derived from Balatro's own textures, read from the
installed game archive (override its path with BALATRO_LOVE). Without the
game the build stops with a message saying so.

fable, 2026-11-14 (claude-fable-5-2)
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import backs   # noqa: E402
import blinds  # noqa: E402
import font    # noqa: E402
import fronts  # noqa: E402
import glyphs  # noqa: E402
import jokers  # noqa: E402
import mods    # noqa: E402
import moves   # noqa: E402
import packs   # noqa: E402
from pixel import upscale  # noqa: E402

ASSETS = HERE.parent / "assets"

EXPECT = {
    "ranks.png": (213, 380), "ranks_hc.png": (213, 380),      # 3 x 4 cells of 71x95
    "mods.png": (142, 95), "mods_hc.png": (142, 95),          # 2 cells of 71x95
    "glyphs.png": (266, 9),                                   # 38 cells of 7x9
    "moves.png": (639, 95), "omega.png": (71, 95),            # 9 Moves; one Spectral
    "packs.png": (284, 95),                                   # 4 Game Packs
    "jokers.png": (710, 95),                                  # 10 cells of 71x95 (8 is Conway, 9 his soul)
    "blinds.png": (714, 34),                                  # The Heap: 21 frames of 34x34
    "backs.png": (71, 95),                                    # the Field Deck
}


def write(name, art):
    """art is an RGBA array, or (canvas, palette)."""
    im = Image.fromarray(art) if isinstance(art, np.ndarray) else art[0].image(art[1])
    for k in (1, 2):
        d = ASSETS / f"{k}x"
        d.mkdir(parents=True, exist_ok=True)
        upscale(im, k).save(d / name)


def main():
    import vanilla
    try:
        vanilla.texture("8BitDeck")
    except vanilla.MissingGame as e:
        print(f"build.py: {e}", file=sys.stderr)
        return 2
    made = set()
    for mod in (fronts, mods, glyphs, moves, packs, jokers, blinds, backs):
        for name, art in mod.outputs().items():
            write(name, art)
            made.add(name)
    (HERE / "glyphs.lua").write_text(glyphs.lua(), encoding="utf-8")
    (HERE / "layout.lua").write_text(mods.lua(), encoding="utf-8")
    ok = True
    for name, size in EXPECT.items():
        one = Image.open(ASSETS / "1x" / name)
        two = Image.open(ASSETS / "2x" / name)
        a, b = np.asarray(one.convert("RGBA")), np.asarray(two.convert("RGBA"))
        good = (one.size == size and two.size == (size[0] * 2, size[1] * 2)
                and np.array_equal(np.repeat(np.repeat(a, 2, 0), 2, 1), b))
        ok &= good
        print(f"{'ok ' if good else 'BAD'} {name:14s} {one.size} -> {two.size}")
    # the glyph sheet is pure white on transparent, every glyph hard left in its cell
    g = np.asarray(Image.open(ASSETS / "1x" / "glyphs.png").convert("RGBA"))
    ink = g[..., 3] > 0
    white = bool((g[ink][:, :3] == 255).all()) and set(np.unique(g[..., 3])) <= {0, 255}
    left = all(ink[:, i * glyphs.CW].any() for i in range(len(glyphs.ORDER)))
    count = len(glyphs.ORDER) == 38
    print(f"{'ok ' if white and left and count else 'BAD'} glyphs: 38 cells, white, left-aligned")
    ok &= white and left and count
    # the symbol font: the game font's em, line and pixel; only glyphs the game font lacks
    from fontTools.ttLib import TTFont
    m = font.build(ASSETS / "fonts" / "ww_symbols.ttf")
    f = TTFont(ASSETS / "fonts" / "ww_symbols.ttf")
    cm = f.getBestCmap()
    coords = [v for n in f.getGlyphOrder() if f["glyf"][n].numberOfContours > 0
              for pt in f["glyf"][n].getCoordinates(f["glyf"])[0] for v in pt]
    good = ((f["head"].unitsPerEm, f["hhea"].ascent, f["hhea"].descent) == (m["upm"], m["ascent"], m["descent"])
            and all(v % font.PX == 0 for v in coords) and min(coords[1::2]) >= -2 * font.PX
            and all(ord(ch) in cm for ch in "ω∞½¼¾⅛⅜⅝⅞↑↓⊕⊗") and sorted(m["missing"]) == sorted(font.GLYPHS))
    print(f"{'ok ' if good else 'BAD'} ww_symbols.ttf: {len(cm)} glyphs, em {m['upm']}, "
          f"ascent {m['ascent']}, descent {m['descent']}, on the {font.PX}-unit grid")
    ok &= good
    if set(EXPECT) ^ made:
        ok = False
        print("unexpected/missing:", set(EXPECT) ^ made)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
