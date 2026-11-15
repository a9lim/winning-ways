"""vanilla.py — read Balatro's own textures out of the game archive.

The Winning Ways rank fronts derive from the base game's sprites (pips,
index digits, the Jacks the Cavaliers ride in on, the high-contrast deck's
shading), so the build needs the game installed.
Nothing from the archive is stored in this repository; it is read at build
time. Sprites derived this way are (c) LocalThunk, not MIT: see NOTES.md for
the exact list.

The archive is a zip. Set BALATRO_LOVE to point somewhere else.

fable, 2026-11-14 (claude-fable-5-2)
"""
from __future__ import annotations

import io
import os
import zipfile
from functools import lru_cache
from pathlib import Path

import numpy as np
from PIL import Image

DEFAULT = (Path.home() / "Library/Application Support/Steam/steamapps/common"
           / "Balatro/Balatro.app/Contents/Resources/Balatro.love")
CW, CH = 71, 95


class MissingGame(RuntimeError):
    pass


def archive_path():
    return Path(os.environ.get("BALATRO_LOVE") or DEFAULT)


@lru_cache(maxsize=None)
def texture(name):
    """RGBA array of resources/textures/1x/<name>.png."""
    p = archive_path()
    if not p.is_file():
        raise MissingGame(
            f"Balatro's game archive was not found at:\n  {p}\n"
            "The Winning Ways art is derived from the base game's textures, so the\n"
            "build needs the game installed. Set BALATRO_LOVE to the path of\n"
            "Balatro.love (or the game executable that contains it) and rerun.")
    with zipfile.ZipFile(p) as z:
        data = z.read(f"resources/textures/1x/{name}.png")
    return np.array(Image.open(io.BytesIO(data)).convert("RGBA"))


def cell(name, col, row, w=CW, h=CH):
    return texture(name)[row * h:(row + 1) * h, col * w:(col + 1) * w].copy()


def hexes(a):
    """(h, w) array of 'rrggbb' strings; '' where transparent."""
    out = np.full(a.shape[:2], "", dtype="U6")
    op = a[..., 3] > 0
    v = (a[..., 0].astype(int) << 16) | (a[..., 1].astype(int) << 8) | a[..., 2]
    for u in np.unique(v[op]):
        out[op & (v == u)] = f"{u:06x}"
    return out
