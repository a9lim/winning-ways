"""quint.py — read Quintessence's Wild suit fronts at build time.

Quintessence (a9lim, MIT) adds a fifth suit, Wild, whose pip is an asterisk.
Under it a 0, 1 or Cavalier can become a Wild card, so ranks.png carries a
Wild row, derived from Quintessence's built sheets `wild_deck.png` and
`wild_deck_hc.png` (13 cells of 71x95: 2..10, J, Q, K, A) the way the other
rows derive from vanilla's deck. Nothing of Quintessence's is stored in this
repository as source; the sheets are read from its checkout:

    <this repo>/../quintessence/assets/1x      (the default)
    QUINTESSENCE_ASSETS=/path/to/assets/1x     (to point somewhere else)

fable, 2026-11-14 (claude-fable-5-2)
"""
from __future__ import annotations

import os
from functools import lru_cache
from pathlib import Path

import numpy as np
from PIL import Image

DEFAULT = Path(__file__).resolve().parent.parent.parent / "quintessence" / "assets" / "1x"
CW, CH = 71, 95
TEN, THREE, JACK, QUEEN, KING = 8, 1, 9, 10, 11          # columns of wild_deck.png


class MissingQuintessence(RuntimeError):
    pass


def assets_path():
    return Path(os.environ.get("QUINTESSENCE_ASSETS") or DEFAULT)


@lru_cache(maxsize=None)
def texture(name):
    """RGBA array of Quintessence's assets/1x/<name>.png."""
    p = assets_path() / f"{name}.png"
    if not p.is_file():
        raise MissingQuintessence(
            f"Quintessence's Wild suit sheet was not found at:\n  {p}\n"
            "The Wild row of the Winning Ways rank fronts is derived from it, so the\n"
            "build needs a checkout of Quintessence (a9lim's other mod)\n"
            "beside this repository, or QUINTESSENCE_ASSETS set to its assets/1x\n"
            "folder. Then rerun.")
    a = np.array(Image.open(p).convert("RGBA"))
    if a.shape[:2] != (CH, CW * 13):
        raise MissingQuintessence(f"{p} is {a.shape[1]}x{a.shape[0]}, not the 923x95 Wild sheet this build expects.")
    return a


def cell(col, hc=False):
    return texture("wild_deck_hc" if hc else "wild_deck")[:, col * CW:(col + 1) * CW].copy()
