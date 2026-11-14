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

## Map (planned)

| path | role |
| --- | --- |
| `main.lua` | entry point; the `WinningWays` global |
| `src/` | the value engine (dyadics, games, nim arithmetic) and the content |
| `tools/` | ogdoad scripts that generate test fixtures |
| `tests/` | unit tests on LuaJIT; an in-game self-test later |
| `DESIGN.md` | the rules |

## Verify

- `scripts/test` runs the unit tests on LuaJIT. It uses `luajit` from PATH, or borrows an unfused copy of the LÖVE
  runtime from the local Balatro install. Nothing gets installed on the Mac, which is deliberately Homebrew-free.
- `tests/main.lua` lists the suites; each suite file returns a function that takes `test(name, body)`.
- For in-game checks, follow Quintessence's pattern (`~/Work/quintessence/AGENTS.md`): env-var hooks that run checks
  or take a screenshot and quit. The game needs Steam running.

## Dev setup

Once there's code, symlink this repo into `~/Library/Application Support/Balatro/Mods/WinningWays`. balala leaves
symlinked checkouts alone. `balala` launches the game, and `balala logs -f` follows its log.

## Release

Bump `version` in `WinningWays.json`, add a `CHANGELOG.md` entry, run the tests, then tag `vX.Y.Z` and publish a
GitHub release.
