# Winning Ways art notes

Pixel art as code. Engine: `art/pixel.py`. One program per sheet;
`~/.venv/bin/python -I art/build.py` regenerates everything into `assets/1x`
and `assets/2x` (2x = exact nearest-neighbour x2 of the 1x; build.py checks
it and every sheet size) and writes `art/glyphs.lua` and `art/layout.lua`.
`art/look.py fronts|fronts_hc|courts|courts_hc|mods|glyphs [k]` renders
previews beside vanilla cells into `art/preview/` (gitignored).

`art/vanilla.py` reads Balatro's textures at build time from the installed
game archive (`Balatro.love`, a zip; override with `BALATRO_LOVE`). Nothing
from the archive is stored in the repo as source, but two built sheets
contain LocalThunk's pixels: see `assets/NOTICE.md`.

| sheet | 1x size | program | vanilla pixels |
|---|---|---|---|
| `ranks.png`, `ranks_hc.png` | 213x380 (3x4 cells of 71x95) | `fronts.py` | yes |
| `mods.png`, `mods_hc.png` | 355x95 (5 cells of 71x95) | `mods.py` | no |
| `glyphs.png` | 266x9 (38 cells of 7x9) | `glyphs.py` | no |

## Rank fronts (`fronts.py`)

Columns 0, 1, C; rows Hearts, Clubs, Diamonds, Spades (the row order of
vanilla's `8BitDeck.png`). Cells are transparent except for ink, like
vanilla's. Vanilla cells below are (column, row), 0-based, in
`resources/textures/1x/8BitDeck.png`.

- **Index digits.** "0" and "1" are the two strokes of vanilla's "10",
  cell (8, 0): the nought from x 9..13 moved to x 7..11, the one from
  x 6..7 moved to x 8..9, both centred on x = 9 over the small pip like
  every vanilla index. **"C" is drawn here** (7x8, two-pixel strokes, the
  Q's bowl without its tail).
- **Small corner pips:** each suit's own, from its 10, cell (8, row).
- **0** is {|}: one pip in the middle of the field, outline only (the 3's
  centre pip, cell (1, row), minus its one-pixel erosion). The move that
  isn't there. *Idea shared with UnStable* (kirbio, MIT), whose 0 is also a
  hollow pip; no UnStable pixels are used, the outline is computed from
  vanilla's pip. Alternative considered: a wholly empty field (reads as a
  missing texture).
- **1** is the 3's centre pip, cell (1, row), alone. The Ace's pip is three
  times the size, so the two don't confuse. (UnStable's 1 is the same
  solution.)
- **C, the Cavalier.** Each suit's Cavalier is the Jack of its *sister*
  suit, re-inked, with a helm for a head:

  | Cavalier of | body from | re-ink |
  |---|---|---|
  | Hearts | Jack of Diamonds (9, 2) | `f06b3f` -> `f03464` |
  | Clubs | Jack of Spades (9, 3) | `3c4368` -> `235955` |
  | Diamonds | Jack of Hearts (9, 0) | `f03464` -> `f06b3f` |
  | Spades | Jack of Clubs (9, 1) | `235955` -> `3c4368` |

  So no suit holds two courts in the same pose. The Jack's hat is cleared
  (and the frame's top rule made good behind it), the face is filled in as
  hair/mail, and a **great helm** (13x17: eye slit, gilt cross, breaths) and
  a **plume** (17x9, in the suit's cloth colour) are stamped on: both drawn
  here, in the courts' own colours (`ffffff e6e6e6 acacac ffa300` + the
  suit's outline and cloth). The top half is then turned to make the bottom,
  as vanilla courts are. The `CAV` table in `fronts.py` holds the per-Jack
  rectangles. Alternatives considered: a mounted knight (no room in a
  double-headed half-cell), a horse's head (reads as chess, not as a court).

### High contrast

`ranks_hc.png` is the same drawing passed through `fronts.hc()`. Vanilla's
`8BitDeck_opt2.png` is not a palette swap: suit ink is a top-to-bottom ramp
that depends only on the row of the cell, and the courts re-ink their
accents per suit (clubs' red cloth goes blue and its blue goes red, spades'
red goes `8a71e1`, diamonds' cloth goes `ffb533`, ...). `hc()` learns both
from vanilla, per suit: `ramp()` is the ink by row (from cells 0..8 and 12,
or from the courts' corners, which in clubs run a shade off), `court_map()`
is (normal colour, row) -> high-contrast colour from the three courts.
Check: `hc()` applied to vanilla's own 2, 10, A, J, Q, K reproduces
`8BitDeck_opt2` exactly, all four suits.

## Modifier overlays (`mods.py`)

One row of full-card overlays: `number`, `hot`, `infinite`, `game`,
`nimbus`. `mods_hc.png` is identical (the badge colours are UI colours, not
suit colours).

- **Where.** Badges sit top right, level with the index top left. Outer
  rim x 46..66, y 5..17 (game: x 45..67; hot: flames up to y 2). Number
  cards' right pip column (x 41..51, from y 13) is overlapped by a corner of
  the badge, as vanilla's seals and stickers overlap art; courts lose only
  the head of a sceptre.
- **Text box: x = 48, y = 7, w = 17, h = 9** (1x px from the cell's
  top-left; also in `art/layout.lua`). It is exactly the plate's fill. A
  glyph cell placed at y = 7 puts cap-height digits on y 8..14, bottoms
  level with the rank index (y 7..14).
- **Construction** follows vanilla's stickers (Eternal, the stake chips):
  outer ring `bfc7d5`, a ring of the colour's shade, flat fill, lettering
  `fdfdfd`.

  | cell | fill | shade ring | text | shape |
  |---|---|---|---|---|
  | number | `009dff` chips blue | `1685cb` | `fdfdfd` | plain plate |
  | hot | `fe5f55` mult red | `cc4846` | `fdfdfd` | plate with three flames, `eac058` hearts |
  | infinite | `4f6367` slate | `eac058` gold | `eac058` | dark plate, gilt rim, four gold sparks |
  | game | `8867a5` purple | `6a4f85` | `fdfdfd` | plate with pointed ends, after {L\|R} |

  Infinite is gold-on-slate rather than a gold plate because white
  lettering on `eac058` is hard to read; the slate is the black stake
  chip's.
- **Nimbus** (the `*`): a 9x3 halo over the index (x 5..13, y 3..5) and a
  3x3 glint beside it (x 15..17, y 6..8), in Spectral blue `4584fa` (shade
  `2f62c9`), repeated turned in the bottom-right corner. It touches neither
  the index nor any badge.

## Glyphs (`glyphs.py`)

38 cells of 7x9, white `ffffff` on transparent, each glyph hard left in its
cell. One-pixel strokes with clipped corners (the Eternal sticker's ∞ is the
model; proportions after the game font: open-topped 4, flagged 1). Drawn
here.

Order: `0 1 2 3 4 5 6 7 8 9 + − ± / * ω | ↑ ↓ ? ½ ¼ ¾ ⅛ ⅜ ⅝ ⅞`, then small
`0..9` and a small `/`. In `art/glyphs.lua` the small ones are keyed
`"s0".."s9"` and `"s/"` (the minus is U+2212).

Rows of the cell, 0..8:

- cap height rows 1..7: digits, `/ ↑ ↓ ?`, 5 wide (1 is 3 wide)
- baseline row 7; `ω` (7 wide) and the small digits (3x5) stand on it,
  rows 3..7
- `+` and `*` are 5x5 on rows 2..6, `−` is row 4, `±` is rows 1..5 with its
  bar on row 7
- `|` (1 wide) and the vulgar fractions (7 wide) use all of rows 0..8: a
  3x4 numerator top left, a 3x5 denominator bottom right, a slash between
- advance = inked width + 1 (`spacing = 1`)

**Arbitrary fractions** (⁵⁄₁₆): numerator in small digits raised 3 px
(`num_dy = -3`, rows 0..4), then `s/`, then the denominator in small digits
dropped 1 px (`den_dy = 1`, rows 4..8). Around the slash the gap is -1
(`slash_gap`): it tucks one pixel under the numerator and over the
denominator. `glyphs.layout()` is the reference implementation. Widths:
`+½` 13, `±2` 11, `±10` 15, `+ω` 13, `+1⅞` 17, `+⁵⁄₁₆` 17: all inside the
17 px box. `−¹⁵⁄₁₆` is 21 and would overflow.

## Open

- Badge position: top right overlaps the top-right pip of 4..10. The other
  free spot is nowhere; a narrower box (13 px) would clear the pip but not
  fit `±10` or sixteenths.
- `infinite` as slate + gold vs a solid gold plate.
- Nimbus in Spectral blue vs gold.
