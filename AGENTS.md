# AGENTS.md — Winning Ways editing contract

Winning Ways is a Balatro mod on Steamodded. Card values are Conway's numbers and games. The engine, values, Moves, ω eating,
the jokers, The Heap and the Field Deck are built. `DESIGN.md` is the source of truth for the rules: its
**Decided** sections are agreed, and its **Candidates** wait on a9. Git history records what changed.

## Stance

- **The maths is exact.** Every value a card holds is a real surreal number or short game, and every rule is a
  theorem or definition from the literature. Where a mechanic is Balatro-layer rather than maths (ω's bonus chips),
  `DESIGN.md` says so. Never approximate a game by its mean or its stops unless a rule calls for it.
- **ogdoad is the oracle, not a dependency.** `~/Work/ogdoad` and its Python bindings generate fixtures and check
  claims. ogdoad is AGPL, so none of its code ships in this MIT mod; the runtime is pure Lua.
- **Check a fact before writing it down.** Add each one to `DESIGN.md` § 10 with how it was checked, or mark it
  standard.
- **Credit sources in the README.** UnStable's ranks inspired this mod, and its code is never copied.

## Map

| path | role |
| --- | --- |
| `main.lua` | entry point; the `WinningWays` global; loads the engine as `WinningWays.engine` |
| `src/engine/num.lua` | numbers k·ω + x: order, arithmetic, sign expansions, simplest numbers, notation |
| `src/engine/game.lua` | short games over those numbers: canonical form, order, sums, stops, thermographs, heat, cool |
| `src/engine/nim.lua` | nim arithmetic on the ranks 0–15 (F₁₆) |
| `src/engine/play.lua` | how a hand of values scores, and the ranks a value plays as |
| `src/engine/hands.lua` | which rank each card plays as: the candidate assignments for a hand |
| `src/ranks.lua` | the born ranks 0, 1 and the Cavalier (C, between J and Q) |
| `src/cards.lua` | values on cards (rank + modifier), hand reading (evaluate, get_id, get_X_same), chips |
| `src/faces.lua` | how modifiers show: badge frames, runtime-composed labels, the nimbus halo, the tooltip |
| `src/omega.lua` | infinity eating: who eats whom in the played row, growth, destruction, always-scores |
| `src/moves.lua` | the Move consumables, the Omega Spectral and the Game Packs; each effect is `WW.MOVES[key].apply` |
| `src/jokers.lua` | the jokers; their rules are plain functions (`WW.bouton`, `WW.mex_of`, `WW.missing_pairs`, `WW.extra_ranks`) |
| `src/blinds.lua` | The Heap, a Boss Blind |
| `src/decks.lua` | the Field Deck |
| `src/font.lua` | attaches Fable's symbol font (ω ½ ↑ …) as a fallback to Balatro's pixel font |
| `src/lab.lua` | the Laboratory Deck, a development deck with a sample of every modifier (remove before release) |
| `localization/en-us.lua` | all text |
| `art/` | Fable's sheet programs on `art/pixel.py`; `art/build.py` rebuilds `assets/`; `art/NOTES.md` has provenance |
| `tools/fixtures.py` | regenerates `tests/fixtures/ogdoad.lua` from ogdoad |
| `tests/` | unit tests on LuaJIT (`known_test.lua`, `ogdoad_test.lua`, `hands_test.lua`); `ingame.lua` |
| `DESIGN.md` | the rules; § 11 is the engine |

Engine modules (`src/engine/`) are pure Lua with no game state; `src/cards.lua` is where they meet the game.
Inside it, `Gm` is the engine's game module: never name it `G`, which is Balatro's global.
Engine modules Each one takes the shared engine table as its chunk argument
(`loadfile(path)(E)` in tests, `SMODS.load_file(path)(E)` in the game), and they load in the order num, game, nim,
play, hands. Values print and parse in one ASCII notation (`3`, `-7/2`, `w/2-1`, `{9|5}`), which doubles as the save
format.

## Verify

- `scripts/test` runs the unit tests on LuaJIT. It uses `luajit` from PATH, or borrows an unfused copy of the LÖVE
  runtime from the local Balatro install. Nothing gets installed on the Mac, which is deliberately Homebrew-free.
- `tests/main.lua` lists the suites; each suite file returns a function that takes `test(name, body)`.
- `scripts/runtest` plays a real run on the Field Deck through the game's own code: it picks the Small Blind, plays
  scripted hands, uses a Move, tries each joker and The Heap, and checks every score to the chip. `G.F_NO_SAVING` is set, and the script also backs up and
  restores the save files. It is the only test of the scoring path as the game runs it, so run it after any change
  to scoring, eating or the Moves. If the game crashes, close it (`pkill -f Balatro.app/Contents/MacOS`) before the
  next run.
- `WINNINGWAYS_SHOWCASE=<png> balala` lays out the born ranks and every kind of modifier beside vanilla cards,
  screenshots them and quits; add `WINNINGWAYS_SHOWCASE_PALETTE=lc|hc` to force the palette (the settings are put
  back). Use it after any art or drawing change.
- After changing the engine, the ogdoad fixtures must still pass. Regenerate them with
  `~/.venv/bin/python -I tools/fixtures.py` (about 2.5 minutes, deterministic) only when the fixture script itself
  changes.
- `scripts/selftest` boots the game with `tests/ingame.lua`, checks at the main menu that the engine loaded and
  works on the game's own LuaJIT, and quits. It needs Steam running (`open -g -a Steam`) and the mod in `Mods/`.
  Grow it as content arrives, following Quintessence's self-test (`~/Work/quintessence/tests/ingame.lua`).

## Dev setup

`~/Library/Application Support/Balatro/Mods/WinningWays` is a symlink to this repo; balala leaves symlinked checkouts
alone. `balala` launches the game, and `balala logs -f` follows its log.

## Release

Bump `version` in `WinningWays.json`, add a `CHANGELOG.md` entry, run the tests, then tag `vX.Y.Z` and publish a
GitHub release.

## Art

Fable (run as a subagent with `model: fable`) draws the art as code, derived from or traced from Balatro's own
sprites so it reads as vanilla. That's the same approach as Quintessence (`~/Work/quintessence/art/NOTES.md`).
- `art/vanilla.py` reads the game's textures from the installed `Balatro.love`. Nothing from the archive is stored as
  source, but built PNGs can contain LocalThunk's pixels, and `assets/NOTICE.md` lists which.
- UnStable (MIT) is a second reference; its sheets go in `art/ref/`, which is gitignored.
- 1x is the master and 2x its exact nearest-neighbour double.
- The high-contrast deck comes from vanilla's `8BitDeck_opt2`, not from re-inking the normal one.
- The Lua side depends on the sheet sizes and cell orders listed in `art/NOTES.md`, and on `art/layout.lua` (the
  badge text box) and `art/glyphs.lua` (the glyph order and widths).
