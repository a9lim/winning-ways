-- Winning Ways: Conway's numbers and games as card values. DESIGN.md is the plan; AGENTS.md the map.
WinningWays = SMODS.current_mod

local function load(path, ...) return assert(SMODS.load_file(path))(...) end

local E = {}
for _, name in ipairs({ "num", "game", "nim", "play", "hands" }) do load("src/engine/" .. name .. ".lua", E) end
WinningWays.engine = E

WinningWays.fronts = load("src/fronts.lua", E)

if NFS.getInfo(WinningWays.path .. "assets/1x/icon.png") then
  SMODS.Atlas { key = "modicon", path = "icon.png", px = 34, py = 34 }
end

load("src/ranks.lua")
load("src/cards.lua")
load("src/omega.lua")
-- The faces need Fable's parts (assets/parts.lua).
if NFS.getInfo(WinningWays.path .. "assets/parts.lua") then load("src/faces.lua") end
if NFS.getInfo(WinningWays.path .. "assets/fonts/ww_symbols.ttf") then load("src/font.lua") end
load("src/lab.lua")
if NFS.getInfo(WinningWays.path .. "assets/1x/moves.png") then load("src/moves.lua") end
load("src/jokers.lua")
load("src/blinds.lua")
load("src/decks.lua")

if os.getenv("WINNINGWAYS_SELFTEST") then load("tests/ingame.lua") end
if os.getenv("WINNINGWAYS_SHOWCASE") then load("tests/showcase.lua") end
if os.getenv("WINNINGWAYS_RUNTEST") then load("tests/run.lua") end
