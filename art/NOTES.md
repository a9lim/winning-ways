# Winning Ways art notes

Pixel art as code. Engine: `art/pixel.py`. One program per sheet;
`~/.venv/bin/python -I art/build.py` regenerates everything into `assets/1x`
and `assets/2x` (2x = exact nearest-neighbour x2 of the 1x; build.py checks
it and every sheet size) and writes `assets/parts.lua`.
`art/look.py fronts|fronts_hc|wild|courts|courts_hc|glyphs|moves|packs|font|jokers|blinds|backs|icon [k]` renders
previews beside vanilla cells into `art/preview/` (gitignored). Composed
fronts are the Lua side's: `scripts/sheet <png> [lc|hc]` draws a sheet of
them without the game.

`art/vanilla.py` reads Balatro's textures at build time from the installed
game archive (`Balatro.love`, a zip; override with `BALATRO_LOVE`). Nothing
from the archive is stored in the repo as source, but built files
contain LocalThunk's pixels (the table's last column): see
`assets/NOTICE.md`. `art/quint.py` reads Quintessence's Wild suit sheets the
same way, from its checkout at `../quintessence/assets/1x` (override with
`QUINTESSENCE_ASSETS`); build.py stops with a message if either is missing.

| sheet | 1x size | program | vanilla pixels |
|---|---|---|---|
| `ranks.png`, `ranks_hc.png` | 284x475 (4x5 cells of 71x95) | `fronts.py` | yes (row 4 by way of Quintessence) |
| `parts.lua` | a Lua table, not a texture | `parts.py` | yes (pips, rank glyphs, layouts, as masks and numbers) |
| `icon.png` | 34x34 | `icon.py` | no |
| `moves.png` | 639x95 (9 cells of 71x95) | `moves.py` | no (frame geometry only) |
| `omega.png` | 71x95 | `moves.py` | yes |
| `packs.png` | 284x95 (4 cells of 71x95) | `packs.py` | yes |
| `jokers.png` | 1136x95 (16 cells of 71x95) | `jokers.py` | yes (JOKER lettering; the three legendary backgrounds) |
| `blinds.png` | 714x68 (2 rows of 21 frames of 34x34) | `blinds.py` | yes (disc, rim, shine) |
| `backs.png` | 142x95 (2 cells of 71x95) | `backs.py` | no (frame geometry only) |
| `fonts/ww_symbols.ttf` | 14 glyphs | `font.py` | no |

## Rank fronts (`fronts.py`)

Columns 0, 1, C, ω; rows Hearts, Clubs, Diamonds, Spades (the row order of
vanilla's `8BitDeck.png`). Cells are transparent except for ink, like
vanilla's. Vanilla cells below are (column, row), 0-based, in
`resources/textures/1x/8BitDeck.png`.

- **Index digits.** "0" is the nought of vanilla's "10", cell (8, 0), moved
  from x 9..13 to x 7..11 so it stands centred on x = 9 over the small pip,
  like every vanilla index. **"1" is drawn here** (4x8, a flagged one): it
  was the 10's bare stroke until 1.1, but a bare stroke reads as a bar once
  the index says 1±2 or 3+1/2. **"C" is drawn here** (7x8, two-pixel
  strokes, the Q's bowl without its tail).
- **Small corner pips:** each suit's own, from its 10, cell (8, row).
- **0** is {|}: an empty field. No pips, and the corners say whose nothing
  it is. Until 1.1 it was one outlined pip (an idea shared with UnStable);
  an outlined pip now means a pip still in play on a hot card (see Front
  parts), so the 0 gave it up. The old worry, that an empty field reads as
  a missing texture, doesn't hold beside the index.
- **1** is the 3's centre pip, cell (1, row), alone. The Ace's pip is three
  times the size, so the two don't confuse. (UnStable's 1 is the same
  solution.)
- **ω** is the card inside out. `inside_out()` multiplies vanilla's plain
  body, `Enhancers.png` (1, 0), by the suit's ink, so the cell covers the
  card to its edges, and leaves the marks white: the ω index and the corner
  pip in both corners, and one large ω in the middle, the index glyph x3,
  as the Ace's pip is a pip x3. This cell is what a plain ω shows before
  the Lua side takes over, and it is exactly what the Lua side composes on
  a plain body (build.py checks the silhouette). The high-contrast cell is
  built separately, the body multiplied row by row by `ramp()`: `hc()`
  would re-ink the white marks too.
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

### The Wild row (row 4, y 380..474)

For Quintessence (a9lim, MIT), whose fifth suit Wild (`quint_Wild`, pip
`*`) a 0, 1 or Cavalier can be moved into. Rows 0..3 are pixel-identical to
before (checked against the old sheets). The row derives from
Quintessence's built sheets `wild_deck.png` / `wild_deck_hc.png` (13 cells:
2..10, J, Q, K, A; its `art/NOTES.md` has their provenance) as rows 0..3
derive from vanilla's; cells below are columns of that sheet.

- **Index digits**: "0" is the nought of Wild's "10", cell 8, moved as for
  the other suits. Quintessence's glyphs are vanilla's spades glyphs
  re-inked, so it is LocalThunk's stroke at one remove. "1" and "C" are
  ours, the same glyphs as rows 0..3.
- **Small corner pip**: Wild's own 9x9 asterisk, from its 10, cell 8
  (x 4..15, y 16..25). Quintessence's drawing, not vanilla's.
- **0**: empty, like the others. **1**: the centre asterisk of Wild's 3,
  cell 1. **ω**: the body in Wild purple (green in high contrast, flat),
  with Wild's own corner asterisk.
- **Cavalier**: Wild has no sister suit, so it rides in on **Wild's own
  Jack**, cell 9. That Jack is itself a collage (head of vanilla's Jack of
  Hearts, robes and frame of the Jack of Diamonds in Wild purple), and the
  head stands where the Jack of Hearts' does, so `CAV["H"]` fits it
  unchanged: hat cleared, top rule made good, face filled in `374649`, the
  same helm, the plume in Wild purple `8b64b4`. What red is left of the hat
  goes to purple. So the Wild Cavalier has the Hearts Cavalier's pose (both
  are the Jack of Diamonds' body) in purple, and no pose appears twice
  *within* Wild. Alternatives considered: Wild's Queen or King under the
  helm (a Cavalier should be Jack-sized, and the helm covers the one thing
  that tells them apart); a fresh collage of two vanilla Jacks (then the row
  would not derive from Quintessence's art at all).
- **Colours**: `8b64b4`, outline `374649`. **High contrast**:
  Quintessence's HC Wild is not ramped (flat green `1fa84f`), so
  `wild_hc()` does not use `ramp()`; it learns (normal colour, row) ->
  HC colour from Quintessence's own three Wild courts, normal against HC,
  and applies it to the whole cell. Check: purple -> `1fa84f` everywhere,
  and the Cavalier's gold and blue go as the Wild Jack's do.

Preview: `look.py wild` -> `preview/wild.png` (ours beside Wild's 2, 10 and
J; normal above, high contrast below).

## Front parts (`parts.py` -> `assets/parts.lua`)

Round 5 (1.1): no labels, no overlays. A card with a modifier draws its
**whole front** at run time, and this program gives the Lua side
(`src/fronts.lua`) what it composes from, as a table of masks and numbers.
There is no texture: the Lua side fills rows of pixels.

### The index alphabet

One line, from x = 6, y = 7 (where every vanilla index starts), each glyph
advancing by its width + 1, all in the suit's ink: **the corner reads as
the value**, 3+1/2, 7±2, \*5, ω+14.

- Rank glyphs are vanilla's own, cut from `8BitDeck.png` row 0: 2..9, the
  10 (one glyph, 8 wide), J, Q, K, A. The 0, 1 and C are `fronts.py`'s.
  Used after a sign they are the digits of a modifier too.
- Drawn here, to stand beside them (two-pixel strokes, 8 rows): `+ −`
  (6x6 and 6x2, on the middle rows), `±` (6x9: the plus, a clear row, a
  two-row bar; it runs one row under the baseline), `ω` (8x6, on the
  baseline: x-height), `*` (6x6), `/` (5x8), `↑ ↓` (6x8).
- Fractions are written out, 1/2, in the same heavy digits. The old label
  font's one-cell ½ can't be drawn in two-pixel strokes at this height.
- A narrow first glyph is centred over the corner pip, as vanilla's are
  (the 0 and the 1 start at x = 7).

### Pips and layouts

Per suit: the pip (the 3's centre pip; 11x10 for hearts and spades, 11x11
for clubs and diamonds), the small corner pip (from the 10; 7x8 at (6, 17)),
and where n pips stand for n = 1..11, measured from vanilla's own cells:
x is 19, 30 or 41, and a pip in the lower half is turned. 1 is the 3's
centre; 11 is the 10 plus that centre. Past 11 the Lua side sets small pips
in rows of four (9 px apart, rows 11 px apart, centred), up to 28.

The Wild suit's are measured from Quintessence's sheet the same way.

**Fill order** (`ORDER`) is the order pips turn solid. The Lua side draws a
value's stops: the Right stop's worth of pips solid from the front of the
list, then outlined ones up to the Left stop, a fraction cutting the last
of each. The orders are chosen so that:

- prefixes are a smaller rank's layout where one fits: 6..11 start with the
  4's corners, the 7 and 8 start with the 6, the 9's first five are the
  corners and the upper centre. So 7±2 = {9|5} is a 9 whose four inner pips
  are the outlined ones;
- the last pip, the one a fraction cuts, is never the one under the index
  (top left) or under the turned index (bottom right).

A cut pip keeps its left columns: `round(width x fraction)`, but never none
and never all. An outlined pip is the pip minus its erosion, as the old 0
was. With a \*, a filled pip is a one-pixel checkerboard, and a bare
outline is dashed on `(u + 2v) mod 4 < 2`: a checkerboard can't draw a
one-pixel diagonal, which lies wholly on one colour (a diamond's outline
would vanish), and this pattern breaks along rows, columns and both
diagonals. Both patterns are the pip's own, so they turn with a turned pip.

Check: the Lua side composing a plain 2..10 from these parts reproduces
vanilla's cell exactly, every suit (`tests/ingame.lua`, in the game).

### Inks

The index and pip ink by row, per palette and suit. Normal contrast is
flat. High contrast is `fronts.ramp()`: 95 colours a suit, and a second
ramp for the courts' corners (clubs' run a shade off). The Lua side inks
every row of a composed front from these, so a pip it puts anywhere takes
the colour vanilla's would have there, and an ω's body is the same ramp.

### What the Lua side does with courts, ω and {ω|x}

- **Courts and the Ace** keep their art. The Lua side clears their own
  index (a 10x10 box at (5, 6), which holds any vanilla index glyph) and
  writes the line in its place, then clears a one-pixel gap round the line
  where it runs over the portrait. The gap is a true knockout: the body
  shows through, so there is no white edge on Gold or Steel.
- **ω** is `fronts.inside_out()` done on whatever body the card has.
- **{ω|x}** is the same body tint above the diagonal from bottom left to top
  right (row y is tinted for `ceil(71 (1 - (y + ½)/95) - ½)` columns), with
  the ω corner in white above and x's corner in ink below.

Alternatives considered: role colours for the label, as in round 2 (a9:
the corner should be the rank's own ink); a halo for \*, as in rounds 1..4
(a9: a star in the index); turning the pips for \* (vanilla's diamond is
unchanged by any quarter turn); small-pip grids for values above 10 on the
courts (a9: courts keep their faces); an opaque flood for ω (hides the
enhancement; the multiply shows it).

## The mod icon (`icon.py`)

34x34, on a rounded tile the shape of Quintessence's. Conway's notation for
a game, `{ Left | Right }`, chalked on the Moves' slate `2f5a50` (bevel
`376a5c`, edge `274c44`): chalk braces and bar `f3f6e8`, a blue square
`52b6ff` for Left's option and a red one `fe6f66` for Right's, the way the
Conway joker's plate is signed. No vanilla pixel.

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
  boards are `glyphs.py`'s.

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

## Jokers (`jokers.py`)

Cells, left to right: `bouton generator grundy hotstrat thermograph sprouts
cantor paradise conway conway_soul birthday hilbert berlekamp berlekamp_soul
guy guy_soul` (`jokers.ORDER`). Legendaries: Conway `pos` 8, `soul_pos` 9;
Berlekamp 12, 13; Guy 14, 15. Round 3 appended cells 10..15; cells 0..9 are
pixel-identical to round 2 (checked against the old sheet).

Measured from vanilla's `Jokers.png` (cells are (column, row)):

- **Frame**, the plain Joker (0, 0): the silhouette (its alpha), a
  one-pixel `bfc7d5` edge, white inside. A joker with a ground (Greedy
  Joker (6, 1), Splash (6, 10)) fills the window x 4..66, y 4..90 less its
  four corner pixels, leaving a two-pixel white margin.
- **JOKER lettering**: vanilla's own pixels, the `4f6367` ink of (0, 0) in
  x 5..13, y 7..50, and its half-turn in the other corner; dark on white
  and cream, white on a dark or blue ground, as vanilla does it. Nearly
  every vanilla joker carries it, and a card without it reads as a
  consumable. Alternative considered: no lettering (brief: no words): the
  cards stopped looking like jokers beside DNA and Splash.
- **Picture**: flat colour, one lighter and one darker tone, under a
  one-pixel `4f6367` outline (`put()` outlines a layer and lays it down),
  in vanilla's joker colours (`fd5f55 009cfd fda200 56a786` and their
  shades as measured on the Joker and Perkeo).

| cell | picture | drawn |
|---|---|---|
| `bouton` | Nim: rows of 1, 2 and 3 matches (1 ⊕ 2 ⊕ 3 = 0), and under them ⊕ = 0 | here |
| `generator` | a dynamo on slate: a gold wheel with fifteen studs (the Ace's 15-cycle), the first stud red, a red A on the hub, an arrow for the turn, sparks | here |
| `grundy` | Solomon Grundy's headstone, carved 0 1 2 and, under a rule, a dotted red gap, 4 5: the gap is the mex; a flower | here |
| `hotstrat` | three fires, small to large, and an arrow coming down on the hottest | here |
| `thermograph` | graph paper; the tent in red on the number line, the mast and its arrow, the mean dropped in dots, the temperature read off in blue; a thermometer | here |
| `sprouts` | a blue spot and a red spot joined by two curves; the new spot on one is gold and has sprouted two leaves, the new spot on the other is plain | here |
| `cantor` | five rows of binary digits, the diagonal in red boxes, a rule, and in blue the row that differs from each | here |
| `paradise` | sky, sea, an island with a palm; an ω in the sun and three ω on the wing | here |
| `conway` | legendary background: Triboulet's (4, 8), hue turned to 0.74 (violet, the one hue vanilla's five don't use), plate kept and re-signed | vanilla + here |
| `conway_soul` | Conway, head and shoulders | here |
| `birthday` | a cake with five candles: three whole (blue), a half (red), a quarter (gold) | here |
| `hilbert` | night; a tower of lit windows narrowing up out of the card, a lit door, a `+1` sign | here |
| `berlekamp` | legendary background: the same marble, hue 0.915 (rose); plate signed with Dots and Boxes | vanilla + here |
| `berlekamp_soul` | Berlekamp, head and shoulders | here |
| `guy` | legendary background: the same marble, hue 0.29 (green); plate signed `012345` | vanilla + here |
| `guy_soul` | Guy, head and shoulders, with his stick | here |

Digits and ω on the cards are `glyphs.py`'s. Alternatives considered:
Bouton as stacks of counters (kept for the blind chip instead); Grundy as
a week calendar (unreadable at this size); Hotstrat as a jester strategist
(a face in 40 px says nothing about heat).

**Conway.** Built as vanilla builds a legendary: a marbled background card
with a plate, and the figure in a second cell that the game floats over it.
The plate (rows 78..87) is vanilla's; TRIBOULET is filled over in the
plate's paper `f7f1e4` and replaced by `{ ▪ | ▪ }`, a blue Left and a red
Right between braces: his notation for a game, where vanilla has the
name. (Alternative: CONWAY in the plate's blackletter. Not done: no words
on the cards.) **The soul is a figure, not an emblem**: John Horton Conway
as he looked late in life, bald forehead, long grey hair to the shoulders,
full beard, a grin, a green jumper with a Life glider on it. It sits where
vanilla's souls sit (x 12..58, y 12..69; vanilla's span x 14..56, y 10..69) and is drawn with their means
(flat tones, a `4f6367` outline, eyes and mouth in a few pixels), but with
a person's skin rather than a clown's white face. No vanilla pixels.

**Birthday.** Derives from nothing in vanilla but the frame and lettering.
The candles count days: three whole ones are the 3 (born on day 3), the
half-height one makes 3½ (day 4), the quarter-height one 3¼ (day 5). Whole
candles are blue and the fractions red and gold, so the count of *extra*
days (what the joker pays for) is the count of candles that aren't blue.
Sponge, jam and icing are the match's wood and the thermograph's pinks.
Alternatives considered: a number tree with its days as rows (a diagram, and
the Moves already own diagrams); a calendar page (needs lettering).

**Hilbert's Hotel.** A ground card (`3c4368`, banded darker upward, a few
stars), white lettering as on Generator and Paradise. The tower's half-width
runs from 20.5 px at the foot to 5 at the top of the window and it leaves
the card still going; each floor is 0.86 of the one below, five windows a
floor, every one lit (the hotel is full). The vacancy sign is `+1` in
`glyphs.py`'s digits on a dark board with a lit rim: room for one more, and
also what the joker does to the slots. Alternatives considered: a corridor
of doors receding to a point (the JOKER lettering sits on both walls); a
guest stepping from door n to n+1 (two doors and a figure at this size say
"hotel" less than one tower does); a key on a fob (reads as a generic key).

**The three authors.** `jokers.legend(hue, sat)` is the one builder:
Triboulet's marble (4, 8) with its hue turned, plate kept and wiped.
`jokers.HUES`: Conway 0.74 (violet), Berlekamp 0.915 (rose: the hot
colour that isn't Chicot's coral 0.00 or Yorick's gold 0.105), Guy 0.29
(a leaf green; Perkeo's is a greyer teal at 0.46).
Vanilla's five sit at 0.56, 0.56, 0.105, 0.00 and 0.46, so the three are
clear of them and of each other. Plates: Conway `{ ▪ | ▪ }`; Berlekamp a
Dots-and-Boxes row, a box to Left (blue), a box to Right (red), a third
with two sides drawn, then loose dots; Guy the small numbers `0 1 2 3 4 5`
in the label font's small digits, which are also exactly the ranks he pays
on. (Alternatives: a thermograph on Berlekamp's plate: the Thermograph
joker and Heat already carry it; a coupon stack: unreadable in six rows.
For Guy, `1 2 4 8 16 31`, his own example of the Strong Law: needs two-digit
numbers and an explanation.)

**Berlekamp's soul**: a figure. White hair combed across from a parting,
large dark-rimmed spectacles, a smile, blue jacket, white shirt, red tie,
and a thermometer in the breast pocket (the one nod to thermography).
**Guy's soul**: a figure. Bald crown with white hair at the sides, a
trimmed white beard, wire spectacles, a red anorak with a rucksack's
straps, and a walking stick in his hand: the hill walker. Both use
Conway's skin and hair tones, `specs()` for the glasses, and sit in the
same box (x 12..58, y 12..69), so the three busts are one family; they are
told apart by silhouette (long hair and beard / clean-shaven with glasses /
beard and stick) and by jumper colour (green, blue, red). No vanilla
pixels. I worked from memory of how the two men looked, not from a
photograph, so these are likenesses in the loose sense only. Alternative if
a figure is unwanted: emblems (a thermograph mast; a rucksack).

## The Heap and The Misère (`blinds.py`)

Vanilla's "turn" is not a turn: in `BlindChips.png` frames 0..12 of a row
are one still chip and in 13..20 a diagonal shine crosses it (the lit
pixels are the same on every row). A boss chip is four tones: body, rim
light above (also the shine), rim dark below, and a glyph in a darker tone
of the body (lighter where the shine crosses it).

`blinds.png` takes disc, rim and shine, frame by frame, from The Wall
(row 8), removes its glyph and re-inks: body **`2a9d8f`** (the boss
colour, `blinds.COLOUR`; a teal no vanilla boss has), light `64b7ad`, dark
`20776d`, glyph `185850`, glyph under shine `52827c` (the same ratios as
vanilla's `4b71e4` chip). The glyph is drawn here: six counters, one on two
on three, both a heap and the Nim position 1 + 2 + 3 that sums to nothing.
**The Misère** is row 1 (y 34..67), the same build (`blinds.frame(i,
"misere")`, `blinds.tones()` gives the five tones from the boss colour by
the same ratios). Boss colour **`a3b81c`** (`blinds.MISERE`), an acid
yellow-green: poison. No vanilla boss has it (nearest: The Club `b9cb92`,
pale; The Needle `5c6e31`, dark olive; The Wheel `50bf7c`, mint). The glyph
is drawn here: a heap going down, three small counters in a row, and under
them the last counter, which is a skull. Whoever takes it loses.
Alternatives considered: the last counter crossed out (an X on a 6 px
counter is a blot); The Heap's pyramid with its top counter hollow (too
close to The Heap at a glance).

Previews: `blinds.png` (ours over vanilla rows, frames 10..20),
`blinds_grounds.png` (each chip on its own colour and on dark grounds).

## Deck backs (`backs.py`)

Cells: `field ordinal` (`backs.ORDER`). `blank(colour)` is the shared
frame. Measured from the Red Deck, `Enhancers.png` (0, 0): the
silhouette, a three-pixel white margin, the field on x 4..66, y 4..90 less
its corners, a dotted white rule two pixels inside it. No vanilla pixel is
copied. The field is the Moves' green `4d9f7c`; on it sixteen small cards,
four by four (16 = 2^4), each an element of F16 as four bits (8 4 over
2 1), 0 top left to 15 bottom right in reading order; 15, the Ace, in
gold. Alternatives considered: dark tiles with lit bits (read as a block of
flats at night), numerals on the tiles (two-digit numbers don't fit 11 px).

**Ordinal Deck** (cell 1). The same frame on indigo `4b4a9c` (toward
violet from the Spectral blue; compared by eye with vanilla's backs in
`preview/backs.png`, not measured against all of them). On it the textbook picture of the ordinals as
matchsticks, as rows: in a row the sticks shrink (to 0.4 of the first) and
crowd (each gap 0.87 of the last) until they run together, which is the
limit; the first row is 0, 1, 2, ... toward ω, the second starts at ω
itself, **the gold stick** (the deck's starting card), and runs to ω·2, and
so on; and the rows themselves shrink (each 0.7 of the last) and crowd
toward the bottom, which is ω². Sticks are two pixels thick with a shadow
while there is room, then one, then solid. No vanilla pixel. Alternative
considered: the same as a spiral (at 63 px the inner turns are mush after
ω·3; rows keep seven of them legible).

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

The fractions are `glyphs.py`'s small digits (3x5, one-pixel strokes)
either side of a slash: two-pixel strokes do not fit a numerator and a
denominator into eleven rows, so they are lighter than the text round them.
`look.py font` renders `preview/font_check.png`: "Worth ω+14, ±½, ↑ ↓ ∞ ⊕ ⊗
−¼ ¾ ⅛ ⅜ ⅝ ⅞ x2" at 16 and 32 px, the game's font in white and ours in gold,
falling back glyph by glyph.

## Glyphs (`glyphs.py`)

The art's own small font: the numerals on the Moves' boards and the jokers,
and the digits the symbol font's fractions are built from. It was also the
card labels' font until 1.1; `glyphs.png` no longer ships (card fronts use
the index alphabet in Front parts).

38 cells of 7x9, white `ffffff` on transparent, each glyph hard left in its
cell. One-pixel strokes with clipped corners (the Eternal sticker's ∞ is the
model; proportions after the game font: open-topped 4, flagged 1). Drawn
here.

Order: `0 1 2 3 4 5 6 7 8 9 + − ± / * ω | ↑ ↓ ? ½ ¼ ¾ ⅛ ⅜ ⅝ ⅞`, then small
`0..9` and a small `/`, keyed `"s0".."s9"` and `"s/"` (the minus is U+2212).

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

- An index line runs over the top pips of a 4..10 and over a court's crown
  (the gap keeps it legible). Fractions make it long: 3+1/2 is 33 px, and
  past 59 px the Lua side drops numbers off the end.
- A long line on a hot card can cover most of an outlined pip in the top
  row (3+1/2±1/2 on a 4).
- Gold under a red or orange suit nearly vanishes when an ω multiplies it.
- In the high-contrast deck an ω's body is the suit's ramp, so it shades
  from top to bottom. Wild's is flat.
- Moves have no name on the card (a ledge instead); vanilla consumables do.
- Jokers carry vanilla's JOKER lettering although the brief said no words;
  `jokers.finish()` is the one place to take it off.
- `build.py` rewrites `ww_symbols.ttf` with a new `head.modified` stamp on
  every run (the outlines are identical); `git checkout` it or pin the stamp.
- Font fractions are one-pixel strokes; text like "1/2" in the game font
  is the heavier alternative.
