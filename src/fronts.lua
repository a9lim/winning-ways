-- What a card's value looks like (DESIGN.md § 2.5), and that look composed as pixels. Pure Lua with no game
-- state, like the engine: src/faces.lua asks it what a card shows and puts the result on screen. The parts (index
-- glyphs, pips, layouts) are Fable's, assets/parts.lua.
--
-- Loading: `loadfile(path)(E)` returns the module; E is the engine.
--
-- A spec, which F.spec makes from a value and F.compose draws, is:
--   mode    "field": our corners, and the value's stops in pips
--           "base":  the card's own art (a court, an Ace, a suit we have no pips for) under our index
--           "omega": the card inside out, for an infinite number: the body in the suit's ink, the marks white
--           "split": {ω|x}, the ω card above the diagonal and the x card below it
--   suit    a key of parts.suits, or nil for a suit we have no parts for
--   index   what the corner says, as tokens: the rank, then its modifiers, all one ink ("*", "7", "±", "2"). A
--           token is a glyph's name, or a fraction "p/q", which is drawn stacked in small digits
--   low     in a split, the bottom-right corner's glyph names
--   right, left   in a field, the stops as Lua numbers: `right` pips are solid, on up to `left` in outline, and
--           a fraction cuts the last pip of each kind
--   checker in a field, pips are drawn as a checkerboard: the card carries a *
--
-- The result is { cells, tint, base }. cells[y * 71 + x + 1] is 0, INK (the suit's ink, which the caller knows by
-- row), WHITE or ERASE (clear the art underneath). tint[y + 1], when there is one, is how many columns of row y
-- show the body multiplied by the ink; base says the card's own art goes underneath.

local E = ...
local N, Gm = E.num, E.game

local F = {}

local W, H = 71, 95
F.W, F.H = W, H
F.INK, F.WHITE, F.ERASE = 1, 2, 3
local INK, WHITE, ERASE = F.INK, F.WHITE, F.ERASE

-- A box that holds any index glyph, with a pixel to spare: what "base" clears before writing its own index.
local BOX = { x = 5, y = 6, w = 10, h = 10 }
-- More pips than vanilla lays out go in rows of four small ones; past GRID_MAX the field is left to the rank.
local GRID = { per = 4, dx = 9, dy = 11 }
F.GRID_MAX = 28

local floor, ceil, min, max = math.floor, math.ceil, math.min, math.max

local function blank()
  local m = {}
  for i = 1, W * H do m[i] = false end
  return m
end

local function turn(m)
  local out = {}
  for i = 1, W * H do out[i] = m[W * H + 1 - i] end
  return out
end

-- Every cell touching a set cell, the eight neighbours included, less the set itself.
local function rim(m)
  local out = blank()
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      if m[y * W + x + 1] then
        for dy = -1, 1 do
          for dx = -1, 1 do
            local xx, yy = x + dx, y + dy
            if xx >= 0 and xx < W and yy >= 0 and yy < H and not m[yy * W + xx + 1] then out[yy * W + xx + 1] = true end
          end
        end
      end
    end
  end
  return out
end

-- sprites -----------------------------------------------------------------------------------------------
-- A sprite is { w, h, [j][i] = bool }, read from rows of "#".

local sprites = setmetatable({}, { __mode = "k" })
local function sprite(rows)
  local s = sprites[rows]
  if not s then
    s = { w = #rows[1], h = #rows }
    for j, r in ipairs(rows) do
      s[j] = {}
      for i = 1, s.w do s[j][i] = r:sub(i, i) == "#" end
    end
    sprites[rows] = s
  end
  return s
end

local function stamp(m, s, x, y, scale)
  scale = scale or 1
  for j = 1, s.h do
    for i = 1, s.w do
      if s[j][i] then
        for v = 0, scale - 1 do
          for u = 0, scale - 1 do
            local xx, yy = x + (i - 1) * scale + u, y + (j - 1) * scale + v
            if xx >= 0 and xx < W and yy >= 0 and yy < H then m[yy * W + xx + 1] = true end
          end
        end
      end
    end
  end
end

-- A fraction is stacked: its numerator over a bar over its denominator, in the small digits. It stands taller
-- than the line (thirteen rows to the line's eight), centred on it: three rows above the rank and two below.
local FRACTION = { up = 3, gap = 1, bar = 1 }

-- A row of small digits: its sprites, and its width.
local function small(parts, text)
  local row, w = {}, -1
  for d in text:gmatch("%d") do
    local s = sprite(assert(parts.glyphs["s" .. d], "no small digit " .. d))
    row[#row + 1] = s
    w = w + s.w + 1
  end
  return row, w
end

local function stamp_row(m, row, x, y)
  for _, s in ipairs(row) do
    stamp(m, s, x, y)
    x = x + s.w + 1
  end
end

--- A line of tokens from the index's corner: its mask, and its width.
function F.line(parts, names)
  local m = blank()
  local x = parts.index.x
  for k, name in ipairs(names) do
    local p, q = name:match("^(%d+)/(%d+)$")
    if p then
      local top, tw = small(parts, p)
      local bottom, bw = small(parts, q)
      local w = max(tw, bw)
      if k == 1 then x = x + max(0, floor((7 - w) / 2)) end
      local y = parts.index.y - FRACTION.up
      local h = top[1].h
      stamp_row(m, top, x + floor((w - tw) / 2), y)
      y = y + h + FRACTION.gap
      for v = 0, FRACTION.bar - 1 do
        for u = 0, w - 1 do m[(y + v) * W + x + u + 1] = true end
      end
      stamp_row(m, bottom, x + floor((w - bw) / 2), y + FRACTION.bar + FRACTION.gap)
      x = x + w + 1
    else
      local s = sprite(assert(parts.glyphs[name], "no glyph " .. tostring(name)))
      -- A narrow rank stands centred over the corner pip, as vanilla's do.
      if k == 1 then x = x + max(0, floor((7 - s.w) / 2)) end
      stamp(m, s, x, parts.index.y)
      x = x + s.w + 1
    end
  end
  return m, x - 1 - parts.index.x
end

-- pips --------------------------------------------------------------------------------------------------

-- How many columns of a w-wide pip a fraction f keeps: never none of it, never all of it.
local function columns(w, f)
  if f >= 1 then return w end
  if f <= 0 then return 0 end
  return max(1, min(w - 1, floor(w * f + 0.5)))
end

-- One pip at (x, y): its left `line` part in outline, its left `solid` part filled (both fractions of the pip).
local function pip(m, s, x, y, turned, solid, line, checker)
  local keep, fill = columns(s.w, line), columns(s.w, solid)
  local function at(i, j) -- the pip's own pixel under card-space column i, row j (1-based, inside the clip)
    if i < 1 or i > keep or j < 1 or j > s.h then return false end
    if turned then return s[s.h + 1 - j][s.w + 1 - i] end
    return s[j][i]
  end
  for j = 1, s.h do
    for i = 1, keep do
      if at(i, j) then
        local edge = not (at(i - 1, j) and at(i + 1, j) and at(i, j - 1) and at(i, j + 1))
        local on = edge or i <= fill
        if on and checker then
          -- The pattern is the pip's own: it turns with a turned pip, so every pip is the same. Filled pips are a
          -- checkerboard. A bare outline can't be: a one-pixel diagonal lies wholly on one colour of the board,
          -- so it is dashed instead, on a pattern that breaks along rows, columns and both diagonals.
          local u, v = turned and s.w + 1 - i or i, turned and s.h + 1 - j or j
          if i <= fill then on = (u + v) % 2 == 0 else on = (u + 2 * v) % 4 < 2 end
        end
        if on then m[(y + j - 1) * W + x + i] = true end
      end
    end
  end
end

--- Where n pips go: a list of { x, y, turned }, and the sprite they use. nil when there is no layout for n.
function F.places(parts, suit, n)
  local p = parts.suits[suit]
  if n < 1 or n > F.GRID_MAX then return nil end
  if p.layouts[n] then return p.layouts[n], sprite(p.pip) end
  local s = sprite(p.small)
  local rows = ceil(n / GRID.per)
  local y0 = floor((H - ((rows - 1) * GRID.dy + s.h)) / 2)
  local out = {}
  for k = 0, n - 1 do
    local r, c = floor(k / GRID.per), k % GRID.per
    local across = min(GRID.per, n - r * GRID.per)
    local x0 = floor((W - ((across - 1) * GRID.dx + s.w)) / 2)
    out[#out + 1] = { x0 + c * GRID.dx, y0 + r * GRID.dy }
  end
  return out, s
end

--- The field's mask: `right` solid pips, on up to `left` outlined.
function F.field(parts, suit, right, left, checker)
  local m = blank()
  local places, s = F.places(parts, suit, ceil(left))
  if not places then return m end
  for k, p in ipairs(places) do
    pip(m, s, p[1], p[2], p[3], right - (k - 1), left - (k - 1), checker)
  end
  return m
end

-- composing ---------------------------------------------------------------------------------------------

local function corner(parts, suit, names)
  local m = F.line(parts, names)
  local p = suit and parts.suits[suit]
  if p then stamp(m, sprite(p.small), p.small_at[1], p.small_at[2]) end
  return m
end

local function paint(cells, m, code)
  for i = 1, W * H do if m[i] then cells[i] = code end end
end

--- How many columns of row y (0-based) lie above the diagonal from bottom-left to top-right.
function F.above(y)
  return max(0, min(W, ceil(W * (1 - (y + 0.5) / H) - 0.5)))
end

function F.compose(parts, spec)
  local cells = {}
  for i = 1, W * H do cells[i] = 0 end
  local out = { cells = cells, base = spec.mode == "base" }
  if spec.mode == "omega" then
    -- An Ace inside out: the corners and the suit's large pip, all white.
    local marks = corner(parts, spec.suit, spec.index)
    paint(cells, marks, WHITE)
    paint(cells, turn(marks), WHITE)
    local p = spec.suit and parts.suits[spec.suit]
    if p then
      local ace = blank()
      stamp(ace, sprite(p.ace), p.ace_at[1], p.ace_at[2])
      paint(cells, ace, WHITE)
    end
    out.tint = {}
    for y = 1, H do out.tint[y] = W end
  elseif spec.mode == "split" then
    paint(cells, corner(parts, spec.suit, spec.index), WHITE)
    paint(cells, turn(corner(parts, spec.suit, spec.low)), INK)
    out.tint = {}
    for y = 1, H do out.tint[y] = F.above(y - 1) end
  elseif spec.mode == "base" then
    -- The card's own index goes, with a one-pixel gap round ours where it runs over the art.
    local line = F.line(parts, spec.index)
    local gone = rim(line)
    for y = BOX.y, BOX.y + BOX.h - 1 do
      for x = BOX.x, BOX.x + BOX.w - 1 do gone[y * W + x + 1] = true end
    end
    paint(cells, gone, ERASE)
    paint(cells, turn(gone), ERASE)
    paint(cells, line, INK)
    paint(cells, turn(line), INK)
  else
    local line = F.line(parts, spec.index)
    local gap, back = rim(line), nil
    back = turn(gap)
    local field = F.field(parts, spec.suit, spec.right, spec.left, spec.checker)
    for i = 1, W * H do
      if field[i] and not gap[i] and not back[i] then cells[i] = INK end
    end
    local marks = corner(parts, spec.suit, spec.index)
    paint(cells, marks, INK)
    paint(cells, turn(marks), INK)
  end
  return out
end

-- what a value shows -----------------------------------------------------------------------------------

local STAR = Gm.of({ N.zero }, { N.zero })
local UP = Gm.of({ N.zero }, { STAR })
local DOWN = Gm.neg(UP)

local GLYPH = {
  ["2"] = "2", ["3"] = "3", ["4"] = "4", ["5"] = "5", ["6"] = "6", ["7"] = "7", ["8"] = "8", ["9"] = "9",
  ["10"] = "10", Jack = "J", Queen = "Q", King = "K", Ace = "A", ww_0 = "0", ww_1 = "1", ww_C = "C", ww_w = "ω",
}
-- Ranks whose field is pips, so it can show the value. The courts, the Ace and ω keep their own art.
local PIPS = { ww_0 = true, ww_1 = true }
for r = 2, 10 do PIPS[tostring(r)] = true end
local COURT = { Jack = true, Queen = true, King = true, ww_C = true }
local BY_INT = { [0] = "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "C", "Q", "K", "A" }
-- Ranks that are written as numbers: a fraction right after one makes a mixed number, 3½.
local DIGIT = {}
for r = 0, 10 do DIGIT[BY_INT[r]] = true end

local function digits(n, out)
  for d in ("%.0f"):format(n):gmatch("%d") do out[#out + 1] = d end
end

-- A dyadic as a mixed number: its whole part in digits, then its fraction as one stacked token (6½, ½, 13).
local function dyadic(x, signed, out)
  if x < 0 then out[#out + 1] = "−" elseif signed then out[#out + 1] = "+" end
  local a = math.abs(x)
  local whole = floor(a)
  local p, q = a - whole, 1
  while p ~= floor(p) do p, q = p * 2, q * 2 end
  if whole > 0 or q == 1 then digits(whole, out) end
  if q > 1 then out[#out + 1] = ("%.0f/%.0f"):format(p, q) end
  return out
end

-- k·ω + x: 2ω, ½ω, 1¼ω, then the finite part.
local function number(v, signed, out)
  out = out or {}
  if v.k == 0 then return dyadic(v.x, signed, out) end
  if v.k < 0 then out[#out + 1] = "−" elseif signed then out[#out + 1] = "+" end
  if math.abs(v.k) ~= 1 then dyadic(math.abs(v.k), false, out) end
  out[#out + 1] = "ω"
  if v.x ~= 0 then dyadic(v.x, true, out) end
  return out
end

-- A number added to a rank. After a rank written as a number, a fraction needs no sign: 3½, not 3+½. After a
-- letter it keeps it (Q+½), and so does anything else (6−¼, A+13, 9+1½).
local function offset(v, out, mixed)
  if mixed and v.k == 0 and v.x > 0 and v.x < 1 then return dyadic(v.x, false, out) end
  return number(v, true, out)
end

local function is_switch(g)
  return Gm.is_game(g) and #g.L == 1 and #g.R == 1 and N.is(g.L[1]) and N.is(g.R[1])
    and N.eq(g.L[1], N.neg(g.R[1]))
end

--- Does a modifier carry a *: is it x + *, where x is a number plus nothing, ↑, ↓ or a switch ±t? Those are the
--- shapes a card draws, so this is exactly when it shows its star, and nim-sums read the same test (src/cards.lua).
function F.has_star(m)
  if N.is(m) then return false end
  local rest = Gm.sub(m, Gm.mean(m))
  local plain = Gm.add(rest, STAR)
  return Gm.eq(rest, STAR) or Gm.eq(plain, UP) or Gm.eq(plain, DOWN) or is_switch(plain)
end

-- A modifier, its * already taken off, as it reads after the rank: ½, ±2, ½±6½, ↑, or a bare ± for a game that
-- is none of those (the pips show its stops, the tooltip its value). `mixed` says the rank is written as a number.
local function modifier(m, out, mixed)
  if N.is(m) then
    if not N.eq(m, N.zero) then offset(m, out, mixed) end
    return out
  end
  local mean = Gm.mean(m)
  local rest = Gm.sub(m, mean)
  local arrow = Gm.eq(rest, UP) and "↑" or Gm.eq(rest, DOWN) and "↓"
  if arrow or is_switch(rest) then
    if not N.eq(mean, N.zero) then offset(mean, out, mixed) end
    if arrow then
      out[#out + 1] = arrow
    else
      out[#out + 1] = "±"
      number(rest.L[1], false, out)
    end
    return out
  end
  out[#out + 1] = "±"
  return out
end

-- A finite number as a card's corner would say it: the whole part as a rank where there is one (J, not 11), then
-- the fraction, as after a rank (3½, K+½).
local function as_card(x, out)
  local whole = x >= 0 and floor(x) or ceil(x)
  if BY_INT[whole] then out[#out + 1] = BY_INT[whole] else dyadic(whole, false, out) end
  if whole ~= x then offset(N.new(x - whole), out, DIGIT[BY_INT[whole] or ""]) end
  return out
end

-- A stop as a Lua number, ±∞ for an infinite one.
local function plain_number(n)
  if n.k ~= 0 then return n.k > 0 and math.huge or -math.huge end
  return n.x
end

-- The index has the top of the card to itself, up to the far corner's margin. Stacked fractions keep lines
-- short (8½±6½ is 34 pixels), but a value many Cuts deep can still outrun it. A line too long drops numbers off
-- its end until it fits, leaving their sign: a hot 10 with 1023/1024ths in its mean and its heat reads
-- 10 1023/1024 ±. The pips and the tooltip say the rest.
local LINE_MAX = 59
-- A split card's two corners each have their own side of the diagonal, which is narrower.
local SPLIT_MAX = 53
local SIGN = { ["+"] = true, ["−"] = true, ["±"] = true }
local function fit(parts, names, limit)
  while select(2, F.line(parts, names)) > (limit or LINE_MAX) and #names > 1 do
    local before = #names
    -- A bare sign that still doesn't fit goes too, and the number before it follows.
    if SIGN[names[#names]] and #names > 2 then names[#names] = nil end
    while #names > 1 and not SIGN[names[#names]] do names[#names] = nil end
    if #names == before then break end
  end
  return names
end

--- What a card shows: the spec for a card of this rank and suit (Steamodded keys) worth `value`, where `mod` is
--- its modifier (value − rank; nil for none) and `halo` says the modifier carries a * (WW.has_star).
function F.spec(parts, rank, suit, value, mod, halo)
  local have = parts.suits[suit] ~= nil
  local index = halo and { "*" } or {}
  local whole = halo and Gm.add(value, STAR) or value -- the value without its *
  local left, right = Gm.left_stop(value), Gm.right_stop(value)
  local spec = { suit = have and suit or nil, index = index, ink = COURT[rank] and "court" or "num" }
  if right.k > 0 then
    -- Infinite whichever way it's played. A number reads whole (2ω, ω+14); a game as its rank and modifier.
    spec.mode = "omega"
    if N.is(whole) then
      number(whole, false, index)
    else
      index[#index + 1] = GLYPH[rank]
      modifier(halo and Gm.add(mod, STAR) or mod, index, DIGIT[GLYPH[rank]])
    end
    fit(parts, index)
    return spec
  end
  if left.k > 0 then
    spec.mode = "split"
    number(left, false, index)
    fit(parts, index, SPLIT_MAX)
    spec.low = fit(parts, N.is_finite(right) and as_card(right.x, {}) or number(right, false), SPLIT_MAX)
    return spec
  end
  index[#index + 1] = GLYPH[rank]
  if mod then modifier(halo and Gm.add(mod, STAR) or mod, index, DIGIT[GLYPH[rank]]) end
  fit(parts, index)
  spec.right, spec.left = plain_number(right), plain_number(left)
  spec.checker = halo or nil
  spec.mode = (PIPS[rank] and have and ceil(spec.left) <= F.GRID_MAX) and "field" or "base"
  return spec
end

-- A line as text: its tokens run together, a fraction in brackets ("3(1/2)", "8(1/2)±6(1/2)").
local function said(names)
  local out = {}
  for i, name in ipairs(names) do out[i] = name:find("/", 1, true) and ("(" .. name .. ")") or name end
  return table.concat(out)
end

--- A spec as text, for tests and cache keys: "field Hearts *7±2 5..9 checker".
function F.describe(spec)
  local parts = { spec.mode, spec.suit or "-", said(spec.index) }
  if spec.low then parts[#parts + 1] = "over " .. said(spec.low) end
  if spec.mode == "field" then
    parts[#parts + 1] = ("%s..%s"):format(tostring(spec.right), tostring(spec.left))
    if spec.checker then parts[#parts + 1] = "checker" end
  end
  if spec.ink == "court" then parts[#parts + 1] = "court" end
  return table.concat(parts, " ")
end

--- A composed front as text, one character a cell (". # o x", and "~" for tinted body), for tests and for looking.
function F.text(layer)
  local rows = {}
  for y = 0, H - 1 do
    local r = {}
    for x = 0, W - 1 do
      local c = layer.cells[y * W + x + 1]
      r[x + 1] = c == INK and "#" or c == WHITE and "o" or c == ERASE and "x"
        or (layer.tint and x < layer.tint[y + 1]) and "~" or "."
    end
    rows[y + 1] = table.concat(r)
  end
  return table.concat(rows, "\n")
end

return F
