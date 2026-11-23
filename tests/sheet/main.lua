-- A sheet of composed card fronts, drawn without the game: `scripts/sheet <png> [lc|hc]`. For looking at what
-- src/fronts.lua makes of a value (the pips, the index line, ω and the splits) on a mock white body. Courts and
-- Aces show only what we add to them: their own art is the game's. Run from the repo root.

local out_path, palette = arg[2], arg[3] or "lc"
assert(out_path, "usage: love tests/sheet <png> [lc|hc]")

local E = dofile("tests/engine.lua")
local N, Gm = E.num, E.game
local F = assert(loadfile("src/fronts.lua"))(E)
local parts = dofile("assets/parts.lua")
local n = N.new
local function cut(a, b) return Gm.of(a and { a } or {}, b and { b } or {}) end
local STAR = cut(N.zero, N.zero)
local w = N.omega

local BASE = { Jack = 11, ww_C = 12, Queen = 13, King = 14, Ace = 15, ww_0 = 0, ww_1 = 1 }
local function base(rank) return rank == "ww_w" and w or n(BASE[rank] or tonumber(rank)) end

-- { rank, suit, modifier }: the card is worth rank + modifier.
local ROWS = {
  {
    { "ww_0", "Hearts" }, { "3", "Diamonds", n(1 / 2) }, { "5", "Clubs", n(3 / 4) }, { "10", "Hearts", n(3 / 8) },
    { "6", "Clubs", n(-1 / 4) }, { "ww_0", "Spades", n(1 / 2) }, { "2", "Hearts", n(5 / 16) }, { "9", "Diamonds", n(1 / 2) },
    { "ww_1", "Clubs", n(1 / 2) }, { "7", "Spades", n(1 / 2) },
  },
  {
    { "5", "Clubs", cut(n(1), n(-1)) }, { "7", "Hearts", cut(n(2), n(-2)) }, { "3", "Spades", cut(n(1), n(0)) },
    { "4", "Diamonds", Gm.sub(cut(cut(n(9), n(5)), n(3)), n(4)) }, { "8", "Spades", cut(n(6.5), n(-6.5)) },
    { "ww_1", "Spades", cut(n(2), n(-2)) }, { "9", "Hearts", cut(n(1), n(-1)) }, { "10", "Clubs", cut(n(3), n(-3)) },
    { "2", "Diamonds", cut(n(1), n(-1)) }, { "6", "Hearts", cut(n(3.5), n(-3.5)) },
  },
  {
    { "9", "Spades", STAR }, { "4", "Hearts", STAR }, { "5", "Diamonds", Gm.add(cut(n(1), n(-1)), STAR) },
    { "7", "Clubs", STAR }, { "6", "Hearts", cut(n(0), STAR) }, { "3", "quint_Wild", STAR },
    { "8", "quint_Wild", Gm.add(cut(n(2), n(-2)), STAR) }, { "2", "quint_Wild" }, { "10", "Diamonds", STAR },
    { "ww_1", "Hearts", STAR },
  },
  {
    { "8", "Hearts", cut(n(4), n(-4)) }, { "8", "Clubs", cut(n(5), n(-5)) }, { "9", "Diamonds", cut(n(5), n(-5)) },
    { "8", "Spades", Gm.add(n(1 / 2), cut(n(6.5), n(-6.5))) }, { "10", "Hearts", cut(n(6), n(-6)) },
    { "10", "Clubs", cut(n(7), n(-7)) }, { "9", "Hearts", n(4.5) }, { "9", "Spades", n(7) },
    { "8", "Diamonds", Gm.add(Gm.add(n(1 / 2), cut(n(6.5), n(-6.5))), STAR) }, { "8", "quint_Wild", cut(n(7), n(-7)) },
  },
  {
    { "Queen", "Spades", cut(n(1), n(-1)) }, { "Queen", "Diamonds", n(1 / 2) }, { "King", "Hearts", STAR },
    { "Ace", "Clubs", n(1) }, { "ww_C", "Spades", Gm.add(cut(n(2), n(-2)), STAR) }, { "Jack", "Clubs", cut(n(2.5), n(-2.5)) },
    { "Ace", "Hearts", n(13) }, { "4", "Stars", n(1 / 2) }, { "King", "Diamonds", cut(n(0), STAR) }, { "10", "Spades", n(20) },
  },
  {
    { "ww_w", "Spades" }, { "ww_w", "Hearts" }, { "ww_w", "Clubs", n(14) }, { "ww_w", "Diamonds", w },
    { "ww_w", "quint_Wild", STAR }, { "ww_w", "Spades", n(0, -1 / 2) }, { "ww_w", "Hearts", cut(n(1), n(-1)) },
    { "Ace", "Spades", Gm.sub(cut(w, n(0)), n(15)) }, { "Ace", "Diamonds", Gm.sub(cut(w, n(2)), n(15)) },
    { "Ace", "Clubs", Gm.sub(cut(w, n(11)), n(15)) },
  },
  {
    { "ww_w", "Spades", n(0, -1, 1) }, { "ww_w", "Hearts", n(0, 0, 1) }, { "ww_w", "Clubs", n(14, -1, 1) },
    { "ww_w", "Diamonds", n(5, 1) }, { "ww_w", "Spades", n(0, -1, 2) }, { "ww_w", "quint_Wild", Gm.add(n(0, -1, 1), STAR) },
    { "ww_w", "Hearts", n(3, 1, 1) },
  },
}

-- has_star, as src/cards.lua has it (it needs the game only for its cache).
local function halo(m) return m ~= nil and F.has_star(m) end

local K = 4
local GAP = 6
local W, H = F.W, F.H
local cols = 0
for _, r in ipairs(ROWS) do cols = math.max(cols, #r) end
local img = love.image.newImageData((cols * (W + GAP) + GAP) * K, (#ROWS * (H + GAP) + GAP) * K)
local function rgb(hex) return tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255 end
local function put(x, y, r, g, b)
  for v = 0, K - 1 do for u = 0, K - 1 do img:setPixel(x * K + u, y * K + v, r, g, b, 1) end end
end
img:mapPixel(function() return rgb("5b7a68"), select(2, rgb("5b7a68")), select(3, rgb("5b7a68")), 1 end)

-- The plain body: a rounded rectangle, white with a pale edge.
local function in_body(x, y)
  if x < 1 or x > 69 or y < 1 or y > 93 then return false end
  local cx, cy = math.max(5 - x, x - 65, 0), math.max(5 - y, y - 89, 0)
  return cx * cx + cy * cy <= 4.6 * 4.6
end
local function on_edge(x, y)
  return in_body(x, y) and not (in_body(x - 1, y) and in_body(x + 1, y) and in_body(x, y - 1) and in_body(x, y + 1))
end

local function ink_of(suit, kind, y)
  local s = parts.inks[palette][suit] or { num = "9a6fb0", court = "9a6fb0" }
  local c = s[kind]
  return rgb(type(c) == "table" and c[y + 1] or c)
end

for j, row in ipairs(ROWS) do
  for i, c in ipairs(row) do
    local rank, suit, mod = c[1], c[2], c[3]
    local value = mod and Gm.add(base(rank), mod) or base(rank)
    local spec = F.spec(parts, rank, suit, value, mod, halo(mod))
    local layer = F.compose(parts, spec)
    print(("%-9s %-11s %s"):format(rank, suit, F.describe(spec)))
    local ox, oy = GAP + (i - 1) * (W + GAP), GAP + (j - 1) * (H + GAP)
    for y = 0, H - 1 do
      for x = 0, W - 1 do
        if in_body(x, y) then
          local r, g, b = 1, 1, 1
          if on_edge(x, y) then r, g, b = rgb("c8d0d0") end
          if layer.tint and x < layer.tint[y + 1] then
            local tr, tg, tb = ink_of(suit, spec.ink, y)
            r, g, b = r * tr, g * tg, b * tb
          elseif layer.base and x >= 17 and x <= 53 and y >= 12 and y <= 82 then
            r, g, b = rgb("e3e6ea") -- where a court's portrait or an Ace's pip would be
          end
          local code = layer.cells[y * W + x + 1]
          if code == F.INK then r, g, b = ink_of(suit, spec.ink, y)
          elseif code == F.WHITE then r, g, b = 1, 1, 1
          elseif code == F.ERASE and layer.base then r, g, b = 1, 1, 1 end
          put(ox + x, oy + y, r, g, b)
        end
      end
    end
  end
end

local f = assert(io.open(out_path, "wb"))
f:write(img:encode("png"):getString())
f:close()
io.stdout:flush()
os.exit(0)
