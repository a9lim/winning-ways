-- The engine against ogdoad: every case in tests/fixtures/ogdoad.lua (made by tools/fixtures.py).
local E = dofile("tests/engine.lua")
local N, G, P, nim = E.num, E.game, E.play, E.nim
local F = dofile("tests/fixtures/ogdoad.lua")

local function s(v) return G.encode(v) end
local half = N.new(1 / 2)

return function(test)
  test("games: canonical form, stops, temperature, mean, birthday", function(eq)
    for i, c in ipairs(F.games) do
      local g = G.parse(c.raw)
      local label = ("game %d %s"):format(i, c.raw)
      eq(s(g), c.canon, label .. " canon")
      eq(s(G.left_stop(g)), c.ls, label .. " LS")
      eq(s(G.right_stop(g)), c.rs, label .. " RS")
      eq(s(G.temperature(g)), c.temp, label .. " temperature")
      eq(s(G.mean(g)), c.mean, label .. " mean")
      local b = G.birthday(g)
      eq(b.m, 0, label .. " birthday is finite")
      eq(b.n, c.bday, label .. " birthday")
    end
  end)

  test("games: heating and cooling", function(eq)
    for i, c in ipairs(F.games) do
      local g = G.parse(c.raw)
      local label = ("game %d %s"):format(i, c.raw)
      eq(s(G.heat(g, N.one)), c.heat, label .. " heat 1")
      local c1, ch = G.cool(g, N.one), G.cool(g, half)
      eq(s(G.left_stop(c1)) .. " " .. s(G.right_stop(c1)), c.cool1[1] .. " " .. c.cool1[2], label .. " cool 1")
      eq(s(G.left_stop(ch)) .. " " .. s(G.right_stop(ch)), c.coolh[1] .. " " .. c.coolh[2], label .. " cool 1/2")
    end
  end)

  test("games: the ranks each one plays as", function(eq)
    for i, c in ipairs(F.games) do
      local g = G.parse(c.raw)
      eq(table.concat(P.ranks(g), ","), table.concat(c.acts, ","), ("game %d %s ranks"):format(i, c.raw))
    end
  end)

  test("pairs: sums and order", function(eq)
    for i, c in ipairs(F.pairs) do
      local a, b = G.parse(c.a), G.parse(c.b)
      local label = ("pair %d %s, %s"):format(i, c.a, c.b)
      eq(s(G.add(a, b)), c.sum, label .. " sum")
      eq(G.le(a, b), c.le, label .. " a <= b")
      eq(G.le(b, a), c.ge, label .. " b <= a")
    end
  end)

  test("hands: Left stop of the whole hand", function(eq)
    for i, c in ipairs(F.hands) do
      local cards = {}
      for j, e in ipairs(c.cards) do cards[j] = G.parse(e) end
      local label = ("hand %d %s"):format(i, table.concat(c.cards, " + "))
      local r = P.resolve(cards)
      eq(s(r.total), c.ls, label .. " resolved total")
      local sum = N.zero
      for _, v in ipairs(r.finals) do sum = N.add(sum, v) end
      eq(s(sum), c.ls, label .. " per-card finals add up")
      eq(s(G.right_stop(G.sum(cards))), c.rs, label .. " RS of the sum")
    end
  end)

  test("nim multiplication table", function(eq)
    for a = 0, 15 do
      for b = 0, 15 do eq(nim.mul(a, b), F.nim[a + 1][b + 1], ("%d x %d"):format(a, b)) end
    end
  end)

  test("simplest number between finite dyadics", function(eq)
    for _, c in ipairs(F.simplest) do
      eq(s(N.simplest_between(N.parse(c.a), N.parse(c.b))), c.s, ("{%s|%s}"):format(c.a, c.b))
    end
  end)

  test("order of transfinite numbers", function(eq)
    for _, c in ipairs(F.order) do
      local a, b = N.parse(c.a), N.parse(c.b)
      eq(N.lt(a, b), c.lt, c.a .. " < " .. c.b)
      eq(N.eq(a, b), c.eq, c.a .. " = " .. c.b)
    end
  end)
end
