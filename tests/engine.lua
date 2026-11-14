-- Loads the engine outside the game, the way main.lua does inside it.
local E = {}
for _, name in ipairs({ "num", "game", "nim", "play" }) do
  assert(loadfile("src/engine/" .. name .. ".lua"))(E)
end
return E
