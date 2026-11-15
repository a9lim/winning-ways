"""look.py — preview tool. Not part of the build; nothing it makes ships.

Renders big nearest-neighbour blow-ups into art/preview/ (gitignored). Card
fronts and overlays are shown on a mock white card body, with vanilla cells
(read from the installed game, only ever looked at) beside ours.

    python -I art/look.py fronts|fronts_hc|courts|courts_hc|mods|glyphs [k]

fable, 2026-11-14 (claude-fable-5-2)
"""
from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))

import vanilla as V  # noqa: E402
from pixel import Canvas, Palette, hex_rgba, hstack, upscale, vstack  # noqa: E402

OUT = HERE / "preview"


def card_body(n=1):
    p = Palette(w="#ffffff", e="#c8d0d0")
    c = Canvas(71, 95, p)
    c.rrect(1, 1, 69, 93, 4, "w")
    c.rrect(1, 1, 69, 93, 4, "e", fill=False)
    im = c.image()
    out = Image.new("RGBA", (71 * n, 95), (0, 0, 0, 0))
    for i in range(n):
        out.alpha_composite(im, (71 * i, 0))
    return out


def on_cards(a):
    im = Image.fromarray(a) if isinstance(a, np.ndarray) else a
    b = card_body(im.width // 71)
    b.alpha_composite(im)
    return b


def save(im, name, k, bg="#5b7a68"):
    b = Image.new("RGBA", im.size, hex_rgba(bg))
    b.alpha_composite(im)
    OUT.mkdir(exist_ok=True)
    upscale(b, k).save(OUT / name)
    print(OUT / name, b.size, "x", k)


def row(cells):
    return np.concatenate(cells, 1)


def main():
    what = sys.argv[1]
    k = int(sys.argv[2]) if len(sys.argv) > 2 else 4
    hc = what.endswith("_hc")
    tex = "8BitDeck_opt2" if hc else "8BitDeck"
    if what.startswith("fronts"):
        import fronts
        s = fronts.sheet_rgba(hc)
        rows = []
        for r in range(4):
            ours = [s[r * 95:(r + 1) * 95, c * 71:(c + 1) * 71] for c in range(3)]
            ref = [V.cell(tex, c, r) for c in (0, 12, 9, 10)]
            rows.append(on_cards(row(ours[:2] + ref[:2] + ours[2:] + ref[2:])))
        save(vstack(rows[:2], gap=2), f"{what}_a.png", k)
        save(vstack(rows[2:], gap=2), f"{what}_b.png", k)
    elif what.startswith("courts"):
        import fronts
        s = fronts.sheet_rgba(hc)
        for nm, rr in (("a", (0, 1)), ("b", (2, 3))):
            cs = []
            for r in rr:
                cs += [s[r * 95:r * 95 + 50, 2 * 71:3 * 71], V.cell(tex, 9, r)[:50]]
            b = Image.new("RGBA", (71 * 4, 50), (255, 255, 255, 255))
            b.alpha_composite(Image.fromarray(row(cs)))
            save(b, f"{what}_{nm}.png", k if len(sys.argv) > 2 else 7)
    elif what == "mods":
        import mods
        mods.preview(save, on_cards, k)
    elif what == "glyphs":
        import glyphs
        save(glyphs.sheet_canvas().image(), "glyphs.png", 7, bg="#009dff")


if __name__ == "__main__":
    main()
