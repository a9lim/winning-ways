# Notice: art derived from Balatro

Winning Ways is MIT-licensed, but some of the built textures in this folder
are derived from Balatro's own sprites and contain pixels that are
(c) LocalThunk. They are **not** covered by the MIT licence:

- `1x/ranks.png`, `2x/ranks.png`, `1x/ranks_hc.png`, `2x/ranks_hc.png`
- `1x/omega.png`, `2x/omega.png`
- `1x/packs.png`, `2x/packs.png`
- `1x/jokers.png`, `2x/jokers.png`
- `1x/blinds.png`, `2x/blinds.png`

What in them is Balatro's:

- **ranks**: the suit pips, the strokes of the "0" and "1" index digits
  (from vanilla's "10"), the bodies of the four Cavaliers (the vanilla
  Jacks, re-inked), and the high-contrast shading. Ours: the "C" index, the
  outline pip of the 0, the helms and plumes, the composition.
  **Row 4 (Wild)** is derived from Quintessence's Wild suit fronts
  (a9lim, MIT): the asterisk pips are Quintessence's own drawing; the "0"
  and "1" strokes and the body of the Wild Cavalier (Quintessence's Wild
  Jack, a collage of vanilla's Jacks of Hearts and Diamonds) are
  LocalThunk's pixels by way of Quintessence, as its own NOTICE says of its
  rank glyphs and courts.
- **omega**: the Spectral frame, name plate and vortex of vanilla's Trance.
  Ours: the ω, the cards, the OMEGA lettering (set in the plate's
  letterforms).
- **packs**: the Celestial packs' wrappers, foil, name band and the JUMBO,
  MEGA and PACK lettering, recoloured. Ours: the slates and their diagrams,
  the GAME lettering.

- **jokers**: the JOKER corner lettering on cells 0..7, 10 and 11 (from
  vanilla's plain Joker), and the marbled background and name plate of
  cells 8, 12 and 14 (vanilla's Triboulet, hue turned). Ours: every
  picture, the signs on the three plates, and the whole of cells 9, 13 and
  15 (the portraits of John Horton Conway, Elwyn Berlekamp and Richard
  Guy).
- **blinds**: both chips' disc, rim and shine animation (vanilla's The
  Wall, re-inked). Ours: the heap of counters, the counters and skull, and
  the colours.

Everything else contains no pixels from the game and is MIT like the code:

- `1x/mods.png`, `2x/mods.png`, `1x/mods_hc.png`, `2x/mods_hc.png`
- `1x/glyphs.png`, `2x/glyphs.png`
- `1x/moves.png`, `2x/moves.png` (the frame follows the Tarot frame's
  measurements; no Tarot pixel is copied)
- `1x/backs.png`, `2x/backs.png` (both backs; the frame follows vanilla's
  deck backs' measurements; no pixel is copied)
- `fonts/ww_symbols.ttf`: wholly original outlines. Its em, ascent, descent
  and pixel size are set equal to those of the game's font, m6x11plus by
  Daniel Linssen, so the two can be mixed; no glyph is taken from it.

These use Balatro's interface colours, and the label anchors in
`art/layout.lua` are measured from its card fronts.

The 0 as a hollow pip and the 1 as a single small pip are solutions shared
with UnStable (kirbio, MIT); no UnStable pixels are used. The Tweedledum
card quotes the pose of John Tenniel's illustration (public domain).

Provenance in full: `art/NOTES.md`. The sprites are rebuilt from an
installed copy of the game by `art/build.py`; nothing from the game archive
is stored in this repository as source.
