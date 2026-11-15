-- Balatro's pixel font (m6x11plus) has ± but no ω, ½, ⅜ or arrows, and silently drops them. Fable drew the missing
-- symbols on the same pixel grid (assets/fonts/ww_symbols.ttf); LÖVE uses it as a fallback for the game's font, at
-- the size the game renders it, so ω and friends show up in every text, ours and anyone else's.

local path = WinningWays.path .. "assets/fonts/ww_symbols.ttf"
local data

local function attach()
  if not G.FONTS then return end
  data = data or love.filesystem.newFileData(assert(NFS.read(path)), "ww_symbols.ttf")
  for _, v in ipairs(G.FONTS) do
    if v.FONT and v.file:find("m6x11plus", 1, true) and not v.ww_fallback then
      v.ww_fallback = love.graphics.newFont(data, v.render_scale)
      v.FONT:setFallbacks(v.ww_fallback)
    end
  end
end

local set_language = Game.set_language
function Game:set_language(...)
  local r = set_language(self, ...)
  attach()
  return r
end
attach()
