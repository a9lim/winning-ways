"""build.py — regenerate every texture.

    ~/.venv/bin/python -I art/build.py

Runs each sheet program and writes assets/1x/<name> and assets/2x/<name>,
the 2x being the 1x upscaled by exact nearest-neighbour x2; writes the Lua
table the mod composes card fronts from (assets/parts.lua) and the symbol font
(assets/fonts/ww_symbols.ttf); then checks the sizes and metrics the Lua
side depends on.

The rank fronts, the front parts, Omega, the packs, the jokers, the blind chips, the vouchers and the tag are derived from Balatro's own
textures, read from the installed game archive (override its path with BALATRO_LOVE). Without the
game the build stops with a message saying so. The Wild row of the rank
fronts and the Wild suit's parts are derived from Quintessence's Wild sheets, read from its checkout
beside this one (override with QUINTESSENCE_ASSETS); without it the build
stops the same way.

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
import icon    # noqa: E402
import jokers  # noqa: E402
import moves   # noqa: E402
import packs   # noqa: E402
import parts   # noqa: E402
import tags    # noqa: E402
import vouchers  # noqa: E402
from pixel import upscale  # noqa: E402

ASSETS = HERE.parent / "assets"

EXPECT = {
    "ranks.png": (284, 475), "ranks_hc.png": (284, 475),      # 4 x 5 cells of 71x95 (row 4: Quintessence's Wild)
    "icon.png": (34, 34),                                     # the mod icon
    "moves.png": (639, 95), "omega.png": (71, 95),            # 9 Moves; one Spectral
    "packs.png": (284, 95),                                   # 4 Game Packs
    "jokers.png": (1136, 95),                                 # 16 cells of 71x95 (souls: 9, 13, 15)
    "blinds.png": (714, 68),                                  # The Heap, The Misère: 21 frames of 34x34 each
    "backs.png": (142, 95),                                   # the Field Deck, the Ordinal Deck
    "vouchers.png": (142, 95),                                # Lessons in Play, On Numbers and Games
    "tags.png": (34, 34),                                     # the Game Tag
}


def write(name, art):
    """art is an RGBA array, or (canvas, palette)."""
    im = Image.fromarray(art) if isinstance(art, np.ndarray) else art[0].image(art[1])
    for k in (1, 2):
        d = ASSETS / f"{k}x"
        d.mkdir(parents=True, exist_ok=True)
        upscale(im, k).save(d / name)


def main():
    import quint
    import vanilla
    try:
        vanilla.texture("8BitDeck")
        quint.texture("wild_deck")
        quint.texture("wild_deck_hc")
    except (vanilla.MissingGame, quint.MissingQuintessence) as e:
        print(f"build.py: {e}", file=sys.stderr)
        return 2
    made = set()
    for mod in (fronts, moves, packs, jokers, blinds, backs, icon, vouchers, tags):
        for name, art in mod.outputs().items():
            write(name, art)
            made.add(name)
    (ASSETS / "parts.lua").write_text(parts.lua(), encoding="utf-8")
    ok = True
    for name, size in EXPECT.items():
        one = Image.open(ASSETS / "1x" / name)
        two = Image.open(ASSETS / "2x" / name)
        a, b = np.asarray(one.convert("RGBA")), np.asarray(two.convert("RGBA"))
        good = (one.size == size and two.size == (size[0] * 2, size[1] * 2)
                and np.array_equal(np.repeat(np.repeat(a, 2, 0), 2, 1), b))
        ok &= good
        print(f"{'ok ' if good else 'BAD'} {name:14s} {one.size} -> {two.size}")
    # the ω front is what the Lua side composes on a plain body: the body times the ink, the marks white
    for name, hc in (("ranks.png", False), ("ranks_hc.png", True)):
        sheet = np.asarray(Image.open(ASSETS / "1x" / name).convert("RGBA"))
        cell = sheet[3 * 95:4 * 95, fronts.OMEGA_COL * 71:(fronts.OMEGA_COL + 1) * 71]
        body = fronts.body()
        good = np.array_equal(cell[..., 3], body[..., 3]) and bool((cell[parts.ace_mask("Spades")][:, :3] == 255).all())
        print(f"{'ok ' if good else 'BAD'} {name}: the ω of Spades fills the plain body's silhouette")
        ok &= good
    # the symbol font: the game font's em, line and pixel; only glyphs the game font lacks
    from fontTools.ttLib import TTFont
    m = font.build(ASSETS / "fonts" / "ww_symbols.ttf")
    f = TTFont(ASSETS / "fonts" / "ww_symbols.ttf")
    cm = f.getBestCmap()
    coords = [v for n in f.getGlyphOrder() if f["glyf"][n].numberOfContours > 0
              for pt in f["glyf"][n].getCoordinates(f["glyf"])[0] for v in pt]
    good = ((f["head"].unitsPerEm, f["hhea"].ascent, f["hhea"].descent) == (m["upm"], m["ascent"], m["descent"])
            and all(v % font.PX == 0 for v in coords) and min(coords[1::2]) >= -2 * font.PX
            and all(ord(ch) in cm for ch in "ω∞½¼¾⅛⅜⅝⅞↑↓⊕⊗²") and sorted(m["missing"]) == sorted(font.GLYPHS))
    print(f"{'ok ' if good else 'BAD'} ww_symbols.ttf: {len(cm)} glyphs, em {m['upm']}, "
          f"ascent {m['ascent']}, descent {m['descent']}, on the {font.PX}-unit grid")
    ok &= good
    if set(EXPECT) ^ made:
        ok = False
        print("unexpected/missing:", set(EXPECT) ^ made)
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
