# AGENTS.md — Winning Ways editing contract

Winning Ways is a Balatro mod on Steamodded. Card values are Conway's numbers and games. At this stage the repo
holds a plan and a test harness, and nothing else. `DESIGN.md` is the source of truth for the rules: its
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
| `art/placeholder_ranks.py` | placeholder fronts for the born ranks (`assets/*/ranks.png`) |
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
