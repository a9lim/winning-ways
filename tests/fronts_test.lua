-- What a value looks like, and its front as pixels (src/fronts.lua), on Fable's parts (assets/parts.lua).
local E = dofile("tests/engine.lua")
local N, G = E.num, E.game
local F = assert(loadfile("src/fronts.lua"))(E)
local parts = dofile("assets/parts.lua")

local n, w = N.new, N.omega
local function cut(a, b) return G.of(a and { a } or {}, b and { b } or {}) end
local STAR = cut(N.zero, N.zero)
local UP = cut(N.zero, STAR)
local BASE = { Jack = 11, ww_C = 12, Queen = 13, King = 14, Ace = 15, ww_0 = 0, ww_1 = 1 }

-- The look of a card of this rank and suit with this modifier, as text.
local function look(rank, suit, mod)
  local base = rank == "ww_w" and w or n(BASE[rank] or tonumber(rank))
  local value = mod and G.add(base, mod) or base
  return F.describe(F.spec(parts, rank, suit, value, mod, mod ~= nil and F.has_star(mod)))
end

local function count(m, code)
  local c = 0
  for i = 1, F.W * F.H do
    if (code and m[i] == code) or (not code and m[i]) then c = c + 1 end
  end
  return c
end

local function area(rows)
  local c = 0
  for _, r in ipairs(rows) do c = c + select(2, r:gsub("#", "")) end
  return c
end

return function(test)
  test("what a value shows", function(eq)
    for _, c in ipairs({
      -- A fraction is one token, drawn stacked; after a rank written as a number it makes a mixed number.
      { "3", "Diamonds", n(1 / 2), "field Diamonds 3(1/2) 3.5..3.5" },
      { "6", "Clubs", n(-1 / 4), "field Clubs 6−(1/4) 5.75..5.75" },
      { "9", "Clubs", n(1.5), "field Clubs 9+1(1/2) 10.5..10.5" },
      { "7", "Hearts", cut(n(2), n(-2)), "field Hearts 7±2 5..9" },
      { "8", "Spades", cut(n(6.5), n(-6.5)), "field Spades 8±6(1/2) 1.5..14.5" },
      { "8", "Spades", G.add(n(1 / 2), cut(n(6.5), n(-6.5))), "field Spades 8(1/2)±6(1/2) 2..15" },
      { "8", "Spades", G.add(n(1 / 2), cut(n(1 / 2), n(-1 / 2))), "field Spades 8(1/2)±(1/2) 8..9" },
      { "5", "Hearts", n(127 / 128), "field Hearts 5(127/128) 5.9921875..5.9921875" },
      { "ww_w", "Hearts", n(1023 / 1024), "omega Hearts ω+(1023/1024)" },
      -- A line too long for the card drops numbers off its end, leaving their sign.
      { "10", "Hearts", G.add(n(1023 / 1024), cut(n(1023 / 1024), n(-1023 / 1024))),
        "field Hearts 10(1023/1024)± 10..11.998046875" },
      { "3", "Spades", cut(n(1), n(0)), "field Spades 3(1/2)±(1/2) 3..4" },
      { "4", "Diamonds", G.sub(cut(cut(n(9), n(5)), n(3)), n(4)), "field Diamonds 4± 3..5" },
      { "ww_1", "Spades", cut(n(2), n(-2)), "field Spades 1±2 -1..3" },
      { "5", "Hearts", STAR, "field Hearts *5 5..5 checker" },
      { "5", "Hearts", G.add(cut(n(1), n(-1)), STAR), "field Hearts *5±1 4..6 checker" },
      { "6", "Hearts", UP, "field Hearts 6↑ 6..6" },
      { "6", "Hearts", G.add(UP, STAR), "field Hearts *6↑ 6..6 checker" },
      { "Queen", "Spades", cut(n(1), n(-1)), "base Spades Q±1 court" },
      { "ww_C", "Hearts", STAR, "base Hearts *C court" },
      { "Ace", "Hearts", n(13), "base Hearts A+13" },
      { "10", "Spades", n(20), "base Spades 10+20" },
      -- A card holds 17 pips. Past that it keeps its rank's own.
      { "10", "Clubs", cut(n(7), n(-7)), "field Clubs 10±7 3..17" },
      { "10", "Clubs", cut(n(8), n(-8)), "base Clubs 10±8" },
      { "4", "Stars", n(1 / 2), "base - 4(1/2)" },
      { "Queen", "Diamonds", n(1 / 2), "base Diamonds Q+(1/2) court" },
      { "Jack", "Clubs", cut(n(2.5), n(-2.5)), "base Clubs J±2(1/2) court" },
      { "ww_w", "Spades", nil, "omega Spades ω" },
      { "ww_w", "Clubs", n(14), "omega Clubs ω+14" },
      { "ww_w", "Diamonds", w, "omega Diamonds 2ω" },
      { "ww_w", "Spades", n(0, -1 / 2), "omega Spades (1/2)ω" },
      { "ww_w", "Hearts", n(-3, 1 / 4), "omega Hearts 1(1/4)ω−3" },
      { "ww_w", "Hearts", STAR, "omega Hearts *ω" },
      { "ww_w", "Hearts", cut(n(1), n(-1)), "omega Hearts ω±1" },
      { "ww_w", "Spades", n(0, -1, 1), "omega Spades ω^2" },
      { "ww_w", "Clubs", n(14, -1, 1), "omega Clubs ω^2+14" },
      { "ww_w", "Hearts", n(0, 0, 1), "omega Hearts ω^2+ω" },
      { "ww_w", "Diamonds", n(5, 1), "omega Diamonds 2ω+5" },
      { "ww_w", "Spades", n(0, -1, 2), "omega Spades 2ω^2" },
      { "King", "Clubs", w, "omega Clubs ω+14 court" }, -- a King with +ω reads by its value all the same
      { "Ace", "Spades", G.sub(cut(w, n(2)), n(15)), "split Spades ω over 2" },
      { "Ace", "Spades", G.sub(cut(w, n(0)), n(15)), "split Spades ω over 0" },
      { "Ace", "Clubs", G.sub(cut(w, n(11)), n(15)), "split Clubs ω over J" },
      { "Ace", "Clubs", G.sub(cut(N.add(w, w), n(3.5)), n(15)), "split Clubs 2ω over 3(1/2)" },
      { "Ace", "Clubs", G.sub(cut(w, n(-1.5)), n(15)), "split Clubs ω over −1−(1/2)" },
      { "Ace", "Clubs", G.sub(cut(w, n(-0.5)), n(15)), "split Clubs ω over 0−(1/2)" },
      { "Ace", "Clubs", G.sub(cut(w, n(20)), n(15)), "split Clubs ω over 20" },
      { "Ace", "Clubs", G.sub(cut(w, n(3839 / 256)), n(15)), "split Clubs ω over K+(255/256)" },
      -- A corner too long for its side of the diagonal ends on a sign, never on a wrong number.
      { "Ace", "Clubs", G.sub(cut(w, n(15 - 2 ^ -20)), n(15)), "split Clubs ω over K+" },
    }) do
      eq(look(c[1], c[2], c[3]), c[4], c[1] .. " of " .. c[2])
    end
  end)

  test("a * is x + *, for the shapes a card draws", function(eq)
    eq(F.has_star(STAR), true, "*")
    eq(F.has_star(G.add(cut(n(1), n(-1)), STAR)), true, "±1*")
    eq(F.has_star(G.add(UP, STAR)), true, "↑*")
    eq(F.has_star(n(1 / 2)), false, "a number")
    eq(F.has_star(cut(n(1), n(-1))), false, "±1")
    eq(F.has_star(UP), false, "↑")
  end)

  test("the field counts the stops in pips", function(eq)
    for _, suit in ipairs({ "Hearts", "Clubs", "Diamonds", "Spades", "quint_Wild" }) do
      local p = parts.suits[suit]
      local pip, small = area(p.pip), area(p.small)
      for k = 1, 17 do
        eq(count(F.field(parts, suit, k, k)), k * pip, suit .. ": " .. k .. " solid pips, none overlapping")
      end
      eq(count(F.field(parts, suit, 0, 0)), 0, suit .. ": a zero is empty")
      eq(count(F.field(parts, suit, -1, 0)), 0, suit .. ": nothing below zero")
      eq(count(F.field(parts, suit, 18, 18)), 0, suit .. ": a card holds 17 pips and no more")
      eq(small > 0, true, suit .. ": a corner pip")
      local five, hot = count(F.field(parts, suit, 5, 5)), count(F.field(parts, suit, 5, 9))
      local nine = count(F.field(parts, suit, 9, 9))
      eq(five < hot and hot < nine, true, suit .. ": 5 solid < 5 solid and 4 outlined < 9 solid")
      -- A fraction cuts the last pip: never to nothing, never to the whole.
      local last = 3 * pip
      for _, f in ipairs({ 1 / 64, 1 / 4, 1 / 2, 3 / 4, 63 / 64 }) do
        local c = count(F.field(parts, suit, 3 + f, 3 + f))
        eq(c > last and c < 4 * pip, true, suit .. ": 3 + " .. f .. " is between 3 and 4 pips")
        last = c - 1
      end
      -- A checkerboard keeps about half of each pip, and only cells the plain pip has.
      local plain, check = F.field(parts, suit, 9, 9), F.field(parts, suit, 9, 9, true)
      local inside = true
      for i = 1, F.W * F.H do inside = inside and (not check[i] or plain[i]) end
      eq(inside, true, suit .. ": the checkerboard stays inside the pips")
      local half = count(check) / count(plain)
      eq(half > 0.4 and half < 0.6, true, suit .. ": and keeps about half")
      local dashed = count(F.field(parts, suit, 0, 9, true)) / count(F.field(parts, suit, 0, 9))
      eq(dashed > 0.3 and dashed < 0.7, true, suit .. ": a starred outline is dashed, not gone")
    end
  end)

  test("fill order: a smaller rank's layout comes first where one fits", function(eq)
    local l = parts.suits.Hearts.layouts
    local function has(n, k, x, y)
      for i = 1, k do if l[n][i][1] == x and l[n][i][2] == y then return true end end
      return false
    end
    for n = 6, 11 do
      for _, p in ipairs(l[4]) do eq(has(n, 4, p[1], p[2]), true, n .. " starts with the 4's corners") end
    end
    for _, n in ipairs({ 7, 8 }) do
      for _, p in ipairs(l[6]) do eq(has(n, 6, p[1], p[2]), true, n .. " starts with the 6") end
    end
    -- Past the 11: two columns of six, and the middle column filling in. Each holds the ones before it.
    local function within(a, b)
      for _, p in ipairs(l[a]) do
        local found = false
        for _, q in ipairs(l[b]) do found = found or (p[1] == q[1] and p[2] == q[2] and p[3] == q[3]) end
        if not found then return false end
      end
      return true
    end
    for _, pair in ipairs({ { 12, 13 }, { 12, 14 }, { 13, 15 }, { 14, 15 }, { 14, 16 }, { 15, 17 }, { 16, 17 } }) do
      eq(within(pair[1], pair[2]), true, pair[2] .. " holds the " .. pair[1])
    end
    for n = 12, 17 do
      for k = 1, 12 do eq(l[n][k][1] ~= 30, true, n .. ": the side columns fill first") end
      for k = 13, n do eq(l[n][k][1], 30, n .. ": then the middle column") end
      for _, p in ipairs(l[4]) do eq(has(n, 4, p[1], p[2]), true, n .. " starts with the 4's corners") end
    end
    -- And each is its own half-turn in where its pips stand, as vanilla's even cards are (the middle pip aside).
    for _, suit in ipairs({ "Hearts", "Clubs", "Diamonds", "Spades" }) do
      local s = parts.suits[suit]
      local h, w = #s.pip, #s.pip[1]
      for n = 12, 17 do
        local ok = true
        for _, p in ipairs(s.layouts[n]) do
          local found = p[1] == 30 and p[2] == s.layouts[1][1][2] -- the middle pip
          for _, q in ipairs(s.layouts[n]) do
            found = found or (q[1] == F.W - w - p[1] and q[2] == F.H - h - p[2] and (q[3] or false) ~= (p[3] or false))
          end
          ok = ok and found
        end
        eq(ok, true, suit .. " " .. n .. " is its own half-turn")
      end
    end
    -- The pip a fraction cuts stands clear of both indices: not top-left, not bottom-right.
    for n = 2, 17 do
      local p = l[n][n]
      eq(p[1] == 19 and p[2] == 13, false, n .. ": the last pip isn't under the index")
      eq(p[1] == 41 and p[2] >= 70, false, n .. ": nor under the turned one")
    end
  end)

  test("composing: corners, turns and layers", function(eq)
    local function compose(spec) return F.compose(parts, spec) end
    local function turned(layer)
      for i = 1, F.W * F.H do
        if layer.cells[i] ~= layer.cells[F.W * F.H + 1 - i] then return false end
      end
      return true
    end
    -- The 2 and the 4 are their own half-turn, as vanilla's are (the others have a pip that stands one way up,
    -- or, like the 10, sit a pixel off).
    for _, k in ipairs({ 2, 4 }) do
      local layer = compose({ mode = "field", suit = "Spades", index = { tostring(k) }, right = k, left = k })
      eq(turned(layer), true, "a plain " .. k .. " is its own half-turn")
      eq(layer.base, false, "and has no art underneath")
    end
    -- The index line knocks a gap out of the pips it runs over, so it reads.
    local bare = compose({ mode = "field", suit = "Hearts", index = { "7" }, right = 5, left = 9 })
    local long = compose({ mode = "field", suit = "Hearts", index = { "7", "±", "2" }, right = 5, left = 9 })
    local line = count((F.line(parts, { "7", "±", "2" }))) - count((F.line(parts, { "7" })))
    eq(count(long.cells, F.INK) < count(bare.cells, F.INK) + 2 * line, true, "the label costs the pips under it")
    -- ω: an Ace inside out. The whole body tinted, the marks white, nothing in the suit's ink.
    local om = compose({ mode = "omega", suit = "Clubs", index = { "ω" } })
    eq(count(om.cells, F.INK), 0, "an ω has no ink of its own")
    local club = parts.suits.Clubs
    eq(count(om.cells, F.WHITE), area(club.ace) + 2 * (area(club.small) + area(parts.glyphs["ω"])),
      "its white is the Ace's pip and the two corners")
    eq(count(compose({ mode = "omega", index = { "ω" } }).cells, F.WHITE), 2 * area(parts.glyphs["ω"]),
      "with no parts for the suit, only the index")
    -- A power: ω then a small 2 raised beside it.
    local sq = F.line(parts, { "ω", "^2" })
    eq(count(sq), area(parts.glyphs["ω"]) + area(parts.glyphs.s2), "ω² is an ω and a small 2")
    local top
    for y = 0, F.H - 1 do
      for x = 0, F.W - 1 do if sq[y * F.W + x + 1] and not top then top = y end end
    end
    eq(top, parts.index.y - 1, "the 2 stands a row above the line")
    -- A stacked fraction: numerator, bar, denominator, thirteen rows from three above the line.
    local half = F.line(parts, { "1/2" })
    eq(count(half), area(parts.glyphs.s1) + area(parts.glyphs.s2) + 5, "1/2 is a small 1, a bar five wide and a small 2")
    eq(select(2, F.line(parts, { "3", "1/2" })), 7 + 1 + 5, "3½ is thirteen pixels wide")
    eq(select(2, F.line(parts, { "5", "5/16" })), 7 + 1 + 10, "a two-digit denominator sets the width")
    local top, bottom
    for y = 0, F.H - 1 do
      for x = 0, F.W - 1 do
        if half[y * F.W + x + 1] then top, bottom = top or y, y end
      end
    end
    eq(top, parts.index.y - 3, "it starts three rows above the line")
    eq(bottom, parts.index.y + 9, "and ends two below")
    local full = true
    for y = 1, F.H do full = full and om.tint[y] == F.W end
    eq(full, true, "every row of an ω is tinted to the edge")
    -- {ω|x}: the diagonal runs from the bottom-left corner to the top-right.
    local sp = compose({ mode = "split", suit = "Spades", index = { "ω" }, low = { "0" } })
    eq(sp.tint[1], F.W, "the top row is all ω")
    eq(sp.tint[F.H], 0, "the bottom row is all the low card")
    local falling, total = true, 0
    for y = 1, F.H do
      falling = falling and (y == 1 or sp.tint[y] <= sp.tint[y - 1])
      total = total + sp.tint[y]
    end
    eq(falling, true, "the ω side narrows going down")
    eq(math.abs(total - F.W * F.H / 2) < F.W, true, "and is half the card")
    eq(count(sp.cells, F.WHITE) > 0 and count(sp.cells, F.INK) > 0, true, "white marks above, ink below")
    -- Each corner keeps to its own side of the diagonal, however long its line: every {ω·k + a | b} a few Cuts
    -- deep, the longest lines that fit included.
    local function sides(layer, what)
      local ok = true
      for y = 0, F.H - 1 do
        for x = 0, F.W - 1 do
          local c = layer.cells[y * F.W + x + 1]
          if c == F.WHITE and x >= layer.tint[y + 1] then ok = false end
          if c == F.INK and x < layer.tint[y + 1] then ok = false end
        end
      end
      eq(ok, true, what .. ": white on the ω side, ink on the low side")
    end
    sides(sp, "{ω|0}")
    for _, top in ipairs({ w, N.add(w, w), n(14, 1), n(0, 5 / 4), n(119 / 8, 3 / 4) }) do
      for _, low in ipairs({ 0, 11, 3.5, 119 / 8, 959 / 64, 3839 / 256, 15 - 2 ^ -14, 15 - 2 ^ -20, -1.5, 20, 100000 }) do
        local value = cut(top, n(low))
        local spec = F.spec(parts, "Ace", "Hearts", value, G.sub(value, n(15)), false)
        eq(spec.mode, "split", "{" .. N.encode(top) .. "|" .. low .. "} is a split")
        sides(compose(spec), F.describe(spec))
      end
    end
    -- A court keeps its art: we clear its index, write ours, and leave a gap round it.
    local q = compose({ mode = "base", suit = "Spades", index = { "*", "Q", "±", "1" }, ink = "court" })
    eq(q.base, true, "a court's own art goes underneath")
    eq(count(q.cells, F.ERASE) >= 2 * 100, true, "its own index is cleared in both corners")
    eq(count(q.cells, F.INK), 2 * count((F.line(parts, { "*", "Q", "±", "1" }))), "and ours written twice")
    eq(turned(q), true, "the same both ways up")
  end)

  test("every glyph a number can need exists", function(eq)
    for _, name in ipairs({ "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "C", "Q", "K", "A", "ω",
      "+", "−", "±", "*", "↑", "↓", "s0", "s1", "s2", "s3", "s4", "s5", "s6", "s7", "s8", "s9" }) do
      eq(type(parts.glyphs[name]), "table", "glyph " .. name)
    end
    for _, suit in ipairs({ "Hearts", "Clubs", "Diamonds", "Spades", "quint_Wild" }) do
      eq(type(parts.suits[suit].ace), "table", suit .. ": the Ace's pip, for its ω")
    end
  end)
end
