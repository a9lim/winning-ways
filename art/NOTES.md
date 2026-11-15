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
| `mods.png`, `mods_hc.png` | 142x95 (2 cells of 71x95) | `mods.py` | no |
| `glyphs.png` | 266x9 (38 cells of 7x9) | `glyphs.py` | no |
| `moves.png` | 639x95 (9 cells of 71x95) | `moves.py` | no (frame geometry only) |
| `omega.png` | 71x95 | `moves.py` | yes |
| `packs.png` | 284x95 (4 cells of 71x95) | `packs.py` | yes |
| `fonts/ww_symbols.ttf` | 14 glyphs | `font.py` | no |

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

## Modifiers (`mods.py`)

Round 2: no plates. A modifier is **coloured text on the card's white,
beside the corner index**, so the corner reads as the value (3+½, 7±2,
K+ω). The Lua side composes it from `glyphs.png`; `mods.py` owns only its
geometry and colours, written to `art/layout.lua`.

### Labels

- **Anchor** (`label[rank]`, keyed by Steamodded rank key): the top-left of
  the label's first glyph cell. y = 7 for every rank: a 7x9 cell there puts
  cap-height glyphs on y 8..14, bottoms level with the index (y 7..14).
  x = the index's last inked column + 2 (one clear column): 14 for most,
  15 for `10` and `King`, 13 for `ww_0`, 11 for `ww_1`. Measured from the
  fronts at build time.
- **free**: columns before the label meets that rank's own art (tightest
  suit). Ace, `ww_0`, `ww_1`: 52+ (the whole top). 2, 3: 16. 4..9: 5; 10: 4
  (the left pip column's lobes, rows 13..14). Courts and `ww_C`: 2..3 (the
  frame). **max** (51..55) is the run to x = 66.
- **Knockout.** Most labels are 11..17 px, so on 4..10 and the courts they
  run over art. Bare colour on a pip or a court is not legible
  (`look.py mods` writes `mods_a_bare.png` to show it); with a one-pixel
  card-white edge it is. So: draw the label in `colours.knockout`
  (`#ffffff`) at the eight one-pixel offsets, then the label itself. With
  that, any overlap up to `max` is fine: it reads like a vanilla sticker
  laid over the art. Within `free` the knockout is invisible, so it can
  simply always be drawn. On enhanced bodies (Gold, Steel...) the knockout
  shows as a thin white edge.
- **Second copy:** the composed label, knockout included, turned 180
  degrees about (35.5, 47.5), i.e. pixel (x, y) -> (70 - x, 94 - y). That
  is exactly how vanilla's own corners relate; nothing else is needed.
  `mods.label()` is the reference implementation.
- **Colours** (`colours`), chosen to hold as bare text on white:

  | role | hex | |
  |---|---|---|
  | offset | `009dff` | chips blue |
  | heat | `fe5f55` | mult red |
  | infinite | `c8900f` | gold, deepened: `eac058` washes out on white |
  | infinitesimal | `4584fa` | Spectral blue, the halo's |
  | knockout | `ffffff` | vanilla's card white |

### Overlay cells (`mods.png`; `mods_hc.png` is identical)

- **0 nimbus** (the `*`): a 9x3 halo over the index (x 5..13, y 3..5), in
  `4584fa` with a `2f62c9` lower arc, and again turned bottom right. The
  round-1 glint is gone: labels start where it sat.
- **1 wild**: the wild rank's index, a **stamp**: a white ± (8x8,
  two-pixel strokes) on mult red `fe5f55`, rimmed `cc4846` (the red stake
  chip's shade), covering x 5..14, y 6..15 in the top-left corner
  (`wild_box`) and the same turned bottom right. Every vanilla index glyph
  lies inside x 6..13, y 7..14, so it hides any rank on any card body; the
  suit pip (from y 16) is untouched. Red, not gold: ± is the heat sign, and
  white holds on red where it washes out on gold.

## The Moves and Omega (`moves.py`)

**The Moves' identity is the blackboard.** Every Move is a diagram chalked
on green slate, the way *Winning Ways* draws its games. Set colours for the
badge and UI: **primary `4d9f7c`, secondary `2f5a50`** (`moves.SET_COLOURS`).

- Frame: vanilla's Tarot geometry, measured from the Fool, `Tarots.png`
  (0, 0): its silhouette, three one-pixel rings (`3c7f66`, `7cc7a2`, the
  outline `4f6367`), the picture window x 7..63, y 4..81 and the name strip
  y 83..90. No Tarot pixel is copied. Where a Tarot has its name a Move has
  the board's ledge, with four chalks on it (no lettering to localise).
- Palette: slate `2f5a50` (`376a5c` dust, `274c44` edge), chalk `f3f6e8`
  (`b9cdbd` rubbed thin), Left blue `52b6ff`, Right red `fe6f66`, yellow
  `f0cc6a` for the thing the card is about, ledge `a9dcc0`. Numerals on the
  boards are `glyphs.png`'s.

| cell | picture |
|---|---|
| `cut` | `{ 0 \| 1 }` as two cards in braces with a bar between; an arrow; one card, ½ |
| `sum` | a 2 and a 3 with a plus, a rule under them, a 5 |
| `heat` | a thermograph (tent on the number line, mast above) in red, wide, arrows up |
| `cool` | the same in blue, sunk small inside its old dotted outline, arrows down, a snowflake |
| `frobenius` | three cards on a ring of arrows, a `*` with a small 2 in the middle |
| `tweedledum` | the twins arm in arm (after Tenniel), one capped blue and one red: G + (-G), with a + over them and a 0 under |
| `repaint` | two Hackenbush stalks on the dotted ground, the second the first with blue and red exchanged; swap arrows |
| `nimbus` | a card under a halo, a blue `*` on it |
| `mex` | cards 0 1 2 4 struck through, the 3 a dotted yellow gap with an arrow at it |

**Omega** (`omega.png`, a Spectral) is vanilla's Trance, `Tarots.png`
(3, 5): frame, plate and vortex, the vortex mirrored so it winds in from the
left. The plate is re-lettered OMEGA in the plate's own letterforms (typed
out in `moves.PLATE` after ECTOPLASM, GRIM and TRANCE), a white ω sits in
the eye, and two cards are going in from the left: infinity eats what is to
its left.

## Game Packs (`packs.py`)

`normal_1`, `normal_2`, `jumbo`, `mega`. Each is a vanilla Celestial pack,
`boosters.png` cells (0, 1), (1, 1), (0, 3), (2, 3): the wrapper, crimps,
foil and the JUMBO / MEGA lettering are vanilla's, the body's hue turned to
green (0.38..0.47; light and dark kept). The planet is covered by a slate
with one of the set's signs (`{ card | card }`; two thermographs; stars).
The name band is the normal pack's (rows 56..77), with CELESTIAL filled
over in the band's own colour and re-lettered GAME in the band's letterforms
(E, A as vanilla letters them; G, M drawn to match); PACK is vanilla's.

## Symbol font (`font.py` -> `assets/fonts/ww_symbols.ttf`)

A fallback for `m6x11plus.ttf`, which lacks every one of these. Wholly
drawn here; only the metrics are read from the game's font (and checked by
build.py):

- em 1024, pixel 64 units (16 px to the em), hhea/typo ascent 768, descent
  -256, line gap 0
- letters stand at y = -128 (two pixels under the baseline, as m6x11plus's
  do) and caps reach y = 576: eleven rows. x-height is eight rows.
- glyphs start at x = 0; advance = inked width + 1 px (m6x11plus's digits:
  6 + 1 = 448)
- two-pixel strokes, square-pixel outlines traced from the masks

| glyph | px wide | rows |
|---|---|---|
| ω | 8 | x-height (8) |
| ∞ | 10 | 6, centred like + |
| ↑ ↓ | 6 | 10 |
| ⊕ ⊗ | 10 | 10 |
| − (U+2212) | 6 | 2 |
| ½ ¼ ¾ ⅛ ⅜ ⅝ ⅞ | 9 | 11 |

The fractions are the card labels' small digits (3x5, one-pixel strokes)
either side of a slash: two-pixel strokes do not fit a numerator and a
denominator into eleven rows, so they are lighter than the text round them.
`look.py font` renders `preview/font_check.png`: "Worth ω+14, ±½, ↑ ↓ ∞ ⊕ ⊗
−¼ ¾ ⅛ ⅜ ⅝ ⅞ x2" at 16 and 32 px, the game's font in white and ours in gold,
falling back glyph by glyph.

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
- `|` (1 wide) and the vulgar fractions (7 wide) use all of rows 0..8. The
  fractions are the small digits composed exactly as below (round 2: the
  round-1 hand-drawn 3x4 numerators were too tight in eighths), so `⅜` in
  one cell and `s3 s/ s8` composed are pixel-identical
- advance = inked width + 1 (`spacing = 1`)

**Arbitrary fractions** (⁵⁄₁₆): numerator in small digits raised 3 px
(`num_dy = -3`, rows 0..4), then `s/`, then the denominator in small digits
dropped 1 px (`den_dy = 1`, rows 4..8). Around the slash the gap is -1
(`slash_gap`): it tucks one pixel under the numerator and over the
denominator. `glyphs.layout()` is the reference implementation. Widths:
`+½` 13, `±2` 11, `±10` 15, `+ω` 13, `+1⅞` 17, `+⁵⁄₁₆` 17, `+½±½` 27.

## Open

- Labels on 4..10 and the courts overlap art (see knockout). The other
  place with room on every rank is the strip above the pips (cell y = 2,
  glyphs on y 3..9: a superscript, 51 px free on number cards, 7..12 on
  courts).
- In the high-contrast deck clubs are chips blue and hearts are close to
  mult red, so an offset on a club or a heat on a heart shares its index's
  colour. It still reads (thin strokes vs the index's heavy ones).
- Moves have no name on the card (a ledge instead); vanilla consumables do.
- Font fractions are one-pixel strokes; text like "1/2" in the game font
  is the heavier alternative.
