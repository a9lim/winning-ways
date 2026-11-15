"""pixel.py — a small pixel-art engine.

The sibling of commons' brush.py, for the opposite medium: no bristles, no
blending, no anti-aliasing. A sprite is a Python program that sets palette
indices on a small grid. Every pixel is one of a handful of named colours, so
a whole sheet can be re-inked by swapping the palette (that is how the
high-contrast deck is made).

What is here:
  Palette   named colours -> hex; swap one for another at export time
  Canvas    an index grid with: px / hline / vline / line / rect / rrect /
            ellipse / polygon / flood, ASCII-mask stamping, blit, clip masks,
            flips and 180-degree rotation (court cards are double-headed),
            auto-outline, ordered (Bayer) dithering, banding helpers
  sheet()   lay cells out in a row/grid
  export()  write the 1x master and an exact nearest-neighbour 2x copy
  preview() big nearest-neighbour blow-up on a flat ground, for looking

Coordinates are integer pixels, origin top-left, and every rectangle is
inclusive of both corners (the way one counts pixels by eye).

numpy + PIL only.

fable, 2026-11-14 (claude-fable-5-2)
"""
from __future__ import annotations

from contextlib import contextmanager
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

BAYER4 = (np.array([[0, 8, 2, 10], [12, 4, 14, 6],
                    [3, 11, 1, 9], [15, 7, 13, 5]]) + 0.5) / 16.0


def hex_rgba(h):
    h = h.lstrip("#")
    if len(h) == 6:
        h += "ff"
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4, 6))


# --------------------------------------------------------------- palette ----
class Palette:
    """Named colours. Index 0 is always transparent."""

    def __init__(self, **colours):
        self.names = [None]
        self.rgba = [(0, 0, 0, 0)]
        for k, v in colours.items():
            self.add(k, v)

    def add(self, name, hexcol):
        if name in self.names:
            self.rgba[self.names.index(name)] = hex_rgba(hexcol)
        else:
            self.names.append(name)
            self.rgba.append(hex_rgba(hexcol))
        return self

    def index(self, name):
        if name is None or name == 0:
            return 0
        if isinstance(name, (int, np.integer)):
            return int(name)
        if name not in self.names and isinstance(name, str) and name.startswith("#"):
            self.add(name, name)             # literal hex colours join on demand
        return self.names.index(name)

    def swapped(self, **colours):
        """A copy with some names re-inked (same indices)."""
        p = Palette()
        p.names = list(self.names)
        p.rgba = list(self.rgba)
        for k, v in colours.items():
            p.add(k, v)
        return p

    def table(self):
        return np.array(self.rgba, np.uint8)


# ---------------------------------------------------------------- canvas ----
class Canvas:
    def __init__(self, w, h, pal: Palette):
        self.w, self.h, self.pal = w, h, pal
        self.a = np.zeros((h, w), np.uint8)
        self._clip = None

    # -- basics
    def copy(self):
        c = Canvas(self.w, self.h, self.pal)
        c.a = self.a.copy()
        return c

    def _put(self, m, colour):
        """Set every pixel of boolean mask m (canvas-sized) to colour."""
        if self._clip is not None:
            m = m & self._clip
        self.a[m] = self.pal.index(colour)

    @contextmanager
    def clip(self, mask):
        """Restrict drawing to a boolean mask for the duration."""
        old = self._clip
        self._clip = mask if old is None else (mask & old)
        try:
            yield
        finally:
            self._clip = old

    def mask(self, *colours):
        """Pixels that are opaque (no args) or one of the named colours."""
        if not colours:
            return self.a > 0
        m = np.zeros_like(self.a, bool)
        for c in colours:
            m |= self.a == self.pal.index(c)
        return m

    def blank(self):
        return np.zeros((self.h, self.w), bool)

    def grid(self):
        return np.mgrid[0:self.h, 0:self.w]  # yy, xx

    # -- primitives
    def px(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h:
            if self._clip is None or self._clip[y, x]:
                self.a[y, x] = self.pal.index(c)

    def pxs(self, pts, c):
        for x, y in pts:
            self.px(x, y, c)

    def rect(self, x0, y0, x1, y1, c, fill=True):
        x0, x1 = sorted((x0, x1))
        y0, y1 = sorted((y0, y1))
        m = self.blank()
        m[max(y0, 0):y1 + 1, max(x0, 0):x1 + 1] = True
        if not fill:
            m[y0 + 1:y1, x0 + 1:x1] = False
        self._put(m, c)

    def hline(self, x0, x1, y, c):
        self.rect(x0, y, x1, y, c)

    def vline(self, x, y0, y1, c):
        self.rect(x, y0, x, y1, c)

    def line(self, x0, y0, x1, y1, c, w=1):
        """Bresenham; w>1 thickens with a w*w square nib."""
        dx, dy = abs(x1 - x0), -abs(y1 - y0)
        sx = 1 if x0 < x1 else -1
        sy = 1 if y0 < y1 else -1
        err = dx + dy
        x, y = x0, y0
        while True:
            if w == 1:
                self.px(x, y, c)
            else:
                o = (w - 1) // 2
                self.rect(x - o, y - o, x - o + w - 1, y - o + w - 1, c)
            if x == x1 and y == y1:
                break
            e2 = 2 * err
            if e2 >= dy:
                err += dy
                x += sx
            if e2 <= dx:
                err += dx
                y += sy

    def path(self, pts, c, w=1, close=False):
        pts = list(pts)
        if close:
            pts.append(pts[0])
        for (ax, ay), (bx, by) in zip(pts, pts[1:]):
            self.line(ax, ay, bx, by, c, w)

    def ellipse_mask(self, cx, cy, rx, ry):
        """Filled ellipse about a (possibly half-integer) centre."""
        yy, xx = self.grid()
        return ((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2 <= 1.0

    def ellipse(self, cx, cy, rx, ry, c, fill=True):
        m = self.ellipse_mask(cx, cy, rx, ry)
        if not fill:
            m = m & ~erode(m)
        self._put(m, c)

    def poly_mask(self, pts):
        im = Image.new("1", (self.w, self.h), 0)
        ImageDraw.Draw(im).polygon([tuple(p) for p in pts], fill=1, outline=1)
        return np.array(im, bool)

    def polygon(self, pts, c, fill=True):
        if fill:
            self._put(self.poly_mask(pts), c)
        else:
            self.path(pts, c, close=True)

    def rrect_mask(self, x0, y0, x1, y1, r):
        """Rounded rectangle with a stepped pixel corner of radius r."""
        m = self.blank()
        m[y0:y1 + 1, x0:x1 + 1] = True
        for i in range(r):
            for j in range(r):
                if (r - i - 0.5) ** 2 + (r - j - 0.5) ** 2 > r * r + 0.5:
                    for X, Y in ((x0 + i, y0 + j), (x1 - i, y0 + j),
                                 (x0 + i, y1 - j), (x1 - i, y1 - j)):
                        m[Y, X] = False
        return m

    def rrect(self, x0, y0, x1, y1, r, c, fill=True):
        m = self.rrect_mask(x0, y0, x1, y1, r)
        if not fill:
            m = m & ~erode(m)
        self._put(m, c)

    def fill(self, m, c):
        self._put(m, c)

    def flood(self, x, y, c):
        tgt = self.a[y, x]
        new = self.pal.index(c)
        if tgt == new:
            return
        m = self.blank()
        st = [(x, y)]
        while st:
            px, py = st.pop()
            if 0 <= px < self.w and 0 <= py < self.h and not m[py, px] \
                    and self.a[py, px] == tgt:
                m[py, px] = True
                st += [(px + 1, py), (px - 1, py), (px, py + 1), (px, py - 1)]
        self._put(m, c)

    # -- sprites
    def stamp(self, art, x, y, key, fh=False, fv=False, rot=False):
        """Stamp an ASCII mask. `art` is a string (lines) or list of rows;
        `key` maps characters to colour names. Unmapped chars are skipped.
        fh/fv flip; rot = 180 degrees."""
        rows = sprite_rows(art)
        if rot:
            fh, fv = not fh, not fv
        if fv:
            rows = rows[::-1]
        if fh:
            rows = [r[::-1] for r in rows]
        for j, r in enumerate(rows):
            for i, ch in enumerate(r):
                if ch in key and key[ch] is not None:
                    self.px(x + i, y + j, key[ch])

    def blit(self, other, x=0, y=0, over=True):
        """Paste another canvas' opaque pixels at (x, y)."""
        for j in range(other.h):
            for i in range(other.w):
                v = other.a[j, i]
                if v and (over or self.a[y + j, x + i] == 0):
                    self.px(x + i, y + j, int(v))

    # -- transforms (return new canvases)
    def rot180(self):
        c = self.copy()
        c.a = self.a[::-1, ::-1].copy()
        return c

    def flip_h(self):
        c = self.copy()
        c.a = self.a[:, ::-1].copy()
        return c

    def flip_v(self):
        c = self.copy()
        c.a = self.a[::-1, :].copy()
        return c

    def mirror_h(self, axis=None):
        """Copy the left half onto the right (in place)."""
        w = self.w
        half = w // 2
        self.a[:, w - half:] = self.a[:, :half][:, ::-1]

    def double_head(self, top_mask):
        """Court-card symmetry: keep pixels where top_mask, and fill the rest
        with the 180-degree rotation of the kept part (in place)."""
        keep = np.where(top_mask, self.a, 0)
        rot = keep[::-1, ::-1]
        self.a = np.where(top_mask, keep, rot).astype(np.uint8)

    # -- finishing
    def outline(self, c, of=None, diag=False, only_empty=True):
        """Draw a 1-px outline around mask `of` (default: all opaque)."""
        m = self.mask() if of is None else of
        ring = dilate(m, diag) & ~m
        if only_empty:
            ring &= self.a == 0
        self._put(ring, c)

    def dither(self, m, c, level=0.5, ox=0, oy=0):
        """Ordered-dither colour c into mask m at coverage `level`
        (a number or a canvas-sized array in 0..1)."""
        yy, xx = self.grid()
        thr = BAYER4[(yy + oy) % 4, (xx + ox) % 4]
        self._put(m & (np.broadcast_to(level, m.shape) > thr), c)

    def checker(self, m, c, phase=0):
        yy, xx = self.grid()
        self._put(m & (((xx + yy + phase) & 1) == 0), c)

    def bands(self, m, t, colours, dither=0.0):
        """Fill mask m by quantising field t (0..1) into colour bands, with
        an optional dithered transition of the given width (in t units)."""
        n = len(colours)
        yy, xx = self.grid()
        thr = (BAYER4[yy % 4, xx % 4] - 0.5) * dither
        q = np.clip(((t + thr) * n).astype(int), 0, n - 1)
        for i, col in enumerate(colours):
            self._put(m & (q == i), col)

    def replace(self, a, b, where=None):
        m = self.mask(a)
        if where is not None:
            m &= where
        self._put(m, b)

    # -- output
    def rgba(self, pal=None):
        return (pal or self.pal).table()[self.a]

    def image(self, pal=None):
        return Image.fromarray(self.rgba(pal), "RGBA")


# --------------------------------------------------------------- helpers ----
def sprite_rows(art):
    if isinstance(art, str):
        rows = [r for r in art.split("\n")]
        while rows and not rows[0].strip():
            rows.pop(0)
        while rows and not rows[-1].strip():
            rows.pop()
        ind = min(len(r) - len(r.lstrip(" ")) for r in rows if r.strip())
        rows = [r[ind:] for r in rows]
    else:
        rows = list(art)
    w = max(len(r) for r in rows)
    return [r.ljust(w) for r in rows]


def sprite_size(art):
    rows = sprite_rows(art)
    return len(rows[0]), len(rows)


def dilate(m, diag=False):
    o = m.copy()
    o[1:] |= m[:-1]
    o[:-1] |= m[1:]
    o[:, 1:] |= m[:, :-1]
    o[:, :-1] |= m[:, 1:]
    if diag:
        o[1:, 1:] |= m[:-1, :-1]
        o[1:, :-1] |= m[:-1, 1:]
        o[:-1, 1:] |= m[1:, :-1]
        o[:-1, :-1] |= m[1:, 1:]
    return o


def erode(m, diag=False):
    p = np.pad(m, 1, constant_values=False)
    return ~dilate(~p, diag)[1:-1, 1:-1]


def from_rgba(a):
    """An RGBA array as a canvas whose colours are named by their hex
    ('#rrggbb'), for re-inking existing pixel art."""
    a = np.asarray(a)
    pal = Palette()
    c = Canvas(a.shape[1], a.shape[0], pal)
    v = (a[..., 0].astype(int) << 16) | (a[..., 1].astype(int) << 8) | a[..., 2]
    op = a[..., 3] > 0
    for u in np.unique(v[op]):
        c.a[op & (v == u)] = pal.index(f"#{u:06x}")
    return c


def components(m, diag=False):
    """Connected pieces of a mask, largest first."""
    m = m.copy()
    out = []
    h, w = m.shape
    nb = [(1, 0), (-1, 0), (0, 1), (0, -1)]
    if diag:
        nb += [(1, 1), (1, -1), (-1, 1), (-1, -1)]
    for y0, x0 in zip(*np.nonzero(m)):
        if not m[y0, x0]:
            continue
        piece = np.zeros_like(m)
        st = [(y0, x0)]
        m[y0, x0] = False
        while st:
            y, x = st.pop()
            piece[y, x] = True
            for dy, dx in nb:
                yy, xx = y + dy, x + dx
                if 0 <= yy < h and 0 <= xx < w and m[yy, xx]:
                    m[yy, xx] = False
                    st.append((yy, xx))
        out.append(piece)
    return sorted(out, key=lambda q: -int(q.sum()))


def sheet(cells, cols=None):
    """Lay equal-sized canvases out left-to-right, top-to-bottom."""
    cols = cols or len(cells)
    rows = -(-len(cells) // cols)
    cw, ch = cells[0].w, cells[0].h
    out = Canvas(cw * cols, ch * rows, cells[0].pal)
    for i, c in enumerate(cells):
        x, y = (i % cols) * cw, (i // cols) * ch
        if c.pal is out.pal:
            out.a[y:y + ch, x:x + cw] = c.a
        else:                                # cells with palettes of their own
            for j, name in enumerate(c.pal.names[1:], 1):
                if name not in out.pal.names:
                    out.pal.add(name, "#%02x%02x%02x%02x" % c.pal.rgba[j])
                out.a[y:y + ch, x:x + cw][c.a == j] = out.pal.index(name)
    return out


def upscale(im, k):
    """Exact nearest-neighbour integer upscale."""
    a = np.asarray(im)
    return Image.fromarray(np.repeat(np.repeat(a, k, axis=0), k, axis=1), im.mode)


def export(canvas, name, root, pal=None):
    """Write root/1x/name and root/2x/name (2x = exact NN x2 of the 1x)."""
    root = Path(root)
    im = canvas.image(pal)
    for k in (1, 2):
        d = root / f"{k}x"
        d.mkdir(parents=True, exist_ok=True)
        upscale(im, k).save(d / name)
    return im


def preview(im, path, k=6, bg="#5b7a68"):
    """Blow an RGBA image up k times onto a flat ground and save it."""
    if isinstance(im, Canvas):
        im = im.image()
    b = Image.new("RGBA", im.size, hex_rgba(bg))
    b.alpha_composite(im)
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    upscale(b, k).save(path)


def hstack(ims, gap=4):
    h = max(i.height for i in ims)
    w = sum(i.width for i in ims) + gap * (len(ims) - 1)
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    x = 0
    for i in ims:
        out.alpha_composite(i, (x, 0))
        x += i.width + gap
    return out


def vstack(ims, gap=4):
    w = max(i.width for i in ims)
    h = sum(i.height for i in ims) + gap * (len(ims) - 1)
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    y = 0
    for i in ims:
        out.alpha_composite(i, (0, y))
        y += i.height + gap
    return out
