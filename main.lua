-- Winning Ways. The value engine lives in src/engine/; no cards use it yet (DESIGN.md is the plan).
WinningWays = SMODS.current_mod

local E = {}
for _, name in ipairs({ "num", "game", "nim", "play" }) do
  assert(SMODS.load_file("src/engine/" .. name .. ".lua"))(E)
end
WinningWays.engine = E

if os.getenv("WINNINGWAYS_SELFTEST") then assert(SMODS.load_file("tests/ingame.lua"))() end
