-- Winning Ways: Conway's numbers and games as card values. DESIGN.md is the plan; AGENTS.md the map.
WinningWays = SMODS.current_mod

local function load(path, ...) return assert(SMODS.load_file(path))(...) end

local E = {}
for _, name in ipairs({ "num", "game", "nim", "play", "hands" }) do load("src/engine/" .. name .. ".lua", E) end
WinningWays.engine = E

load("src/ranks.lua")
load("src/cards.lua")
-- The faces need Fable's art (art/glyphs.lua, art/layout.lua, assets/*/mods*.png, glyphs.png).
if NFS.getInfo(WinningWays.path .. "art/glyphs.lua") then load("src/faces.lua") end
load("src/lab.lua")

if os.getenv("WINNINGWAYS_SELFTEST") then load("tests/ingame.lua") end
if os.getenv("WINNINGWAYS_SHOWCASE") then load("tests/showcase.lua") end
