#!/usr/bin/env python3
"""Placeholder card fronts for the born ranks 0, 1 and C (the Cavalier), until the real faces are drawn.

One column per rank (0, 1, C) and one row per suit in Steamodded's rank-atlas order (Hearts, Clubs,
Diamonds, Spades). Each cell is a plain card with the rank in a small pixel font, in the suit's colour. Writes
assets/1x/ranks.png and its exact nearest-neighbour double assets/2x/ranks.png.

    ~/.venv/bin/python -I art/placeholder_ranks.py
"""
from pathlib import Path

from PIL import Image

W, H = 71, 95
SUITS = [("Hearts", (240, 52, 100)), ("Clubs", (35, 89, 85)), ("Diamonds", (240, 107, 63)), ("Spades", (64, 57, 149))]
# 3x5 glyphs.
GLYPHS = {
    "0": ["###", "#.#", "#.#", "#.#", "###"],
    "1": [".#.", "##.", ".#.", ".#.", "###"],
    "C": [".##", "#..", "#..", "#..", ".##"],
}
RANKS = ["0", "1", "C"]
CARD, EDGE = (255, 255, 255), (78, 86, 95)


def text(img, s, x, y, scale, colour):
    for ch in s:
        for row, line in enumerate(GLYPHS[ch]):
            for col, c in enumerate(line):
                if c == "#":
                    for dy in range(scale):
                        for dx in range(scale):
                            img.putpixel((x + col * scale + dx, y + row * scale + dy), colour)
        x += 4 * scale


def cell(rank, colour):
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    for y in range(H):
        for x in range(W):
            corner = (x < 2 or x > W - 3) and (y < 2 or y > H - 3)
            if corner and not ((x in (1, W - 2)) and (y in (1, H - 2))):
                continue
            edge = x in (0, W - 1) or y in (0, H - 1) or ((x in (1, W - 2)) and (y in (1, H - 2)))
            img.putpixel((x, y), EDGE + (255,) if edge else CARD + (255,))
    text(img, rank, 4, 4, 1, colour + (255,))
    big = 6
    width = len(rank) * 4 * big - big
    text(img, rank, (W - width) // 2, (H - 5 * big) // 2, big, colour + (255,))
    return img


def main():
    root = Path(__file__).resolve().parent.parent
    sheet = Image.new("RGBA", (W * len(RANKS), H * len(SUITS)), (0, 0, 0, 0))
    for row, (_, colour) in enumerate(SUITS):
        for col, rank in enumerate(RANKS):
            sheet.paste(cell(rank, colour), (col * W, row * H))
    sheet.save(root / "assets" / "1x" / "ranks.png")
    sheet.resize((sheet.width * 2, sheet.height * 2), Image.NEAREST).save(root / "assets" / "2x" / "ranks.png")


if __name__ == "__main__":
    main()
