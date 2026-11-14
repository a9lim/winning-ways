-- Winning Ways: Conway's numbers and games as card values. DESIGN.md is the plan; AGENTS.md the map.
WinningWays = SMODS.current_mod

local function load(path, ...) return assert(SMODS.load_file(path))(...) end

local E = {}
for _, name in ipairs({ "num", "game", "nim", "play", "hands" }) do load("src/engine/" .. name .. ".lua", E) end
WinningWays.engine = E

load("src/ranks.lua")
load("src/cards.lua")

if os.getenv("WINNINGWAYS_SELFTEST") then load("tests/ingame.lua") end
