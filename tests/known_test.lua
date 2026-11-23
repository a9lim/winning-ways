-- Known values from DESIGN.md, and self-checks where ogdoad has no oracle (transfinite numbers).
local E = dofile("tests/engine.lua")
local N, G, P, nim = E.num, E.game, E.play, E.nim

local n, w = N.new, N.omega
local function s(v) return G.encode(v) end
local function cut(a, b) return G.of(a and { a } or {}, b and { b } or {}) end

return function(test)
  test("Cut values from the design", function(eq)
    for _, c in ipairs({
      { cut(n(3), n(7)), "4" }, { cut(n(3), n(4)), "7/2" }, { cut(n(3), nil), "4" }, { cut(nil, n(2)), "0" },
      { cut(nil, nil), "0" }, { cut(nil, n(0)), "-1" }, { cut(n(5), n(5)), "{5|5}" }, { cut(n(9), n(5)), "{9|5}" },
      { cut(n(14), nil), "15" }, { cut(n(7 / 2), nil), "4" },
      { cut(n(14), w), "15" }, { cut(w, nil), "w+1" }, { cut(w, n(0, 2)), "w+1" }, { cut(n(0, 1 / 2), w), "w-1" },
      { cut(N.neg(w), w), "0" }, { cut(w, N.add(w, N.one)), "w+1/2" }, { cut(n(0), n(0, 1 / 2)), "1" },
      { cut(w, n(2)), "{w|2}" },
    }) do
      eq(s(c[1]), c[2], c[2])
    end
  end)

  test("the wild rank", function(eq)
    local wild = cut(w, n(2))
    eq(table.concat(P.ranks(wild), ","), "2,3,4,5,6,7,8,9,10,11,12,13,14,15", "plays as 2 through Ace")
    eq(s(G.temperature(wild)), "w/2-1", "infinitely hot")
    eq(s(G.left_stop(wild)), "w", "you take ω")
    eq(N.finite(G.left_stop(wild)), 0, "which scores no chips")
    eq(s(G.heat(wild, N.one)), "{w+1|1}", "heats like any switch")
    eq(s(G.cool(wild, N.one)), "{w-1|3}", "cooling by a finite amount never freezes it")
  end)

  test("Sum, Heat and Cool from the design", function(eq)
    local s51 = cut(n(6), n(4))
    eq(s(G.add(n(3), n(4))), "7", "3 + 4")
    eq(s(G.add(s51, s51)), "10", "5±1 + 5±1")
    eq(s(G.add(n(13), w)), "w+13", "K + ω")
    eq(s(G.add(w, w)), "2w", "ω + ω")
    eq(s(G.add(cut(n(5), n(5)), cut(n(5), n(5)))), "10", "5* + 5*")
    eq(s(G.heat(s51, N.one)), "{7|3}", "heat")
    eq(s(G.heat(n(5), N.one)), "5", "numbers don't heat")
    eq(s(G.cool(s51, N.one)), "{5|5}", "cool to 5*")
    eq(s(G.cool(s51, n(2))), "5", "frozen at the mean")
    eq(table.concat(P.ranks(cut(n(5), n(5))), ","), "5", "5* plays as 5")
    eq(table.concat(P.ranks(cut(n(14), n(2))), ","), "2,3,4,5,6,7,8,9,10,11,12,13,14", "8±6")
    eq(#P.ranks(cut(n(3), n(4))), 0, "3½ plays as nothing")
  end)

  test("hands score by the hotstrat", function(eq)
    -- 5±1, 8±6, 7: you take 14 from the hotter card, the Blind takes 4 from the other.
    local r = P.resolve({ cut(n(6), n(4)), cut(n(14), n(2)), n(7) })
    eq(s(r.total), "25", "total")
    eq(s(r.finals[1]) .. " " .. s(r.finals[2]) .. " " .. s(r.finals[3]), "4 14 7", "per card")
    eq(#r.moves, 2, "two moves")
    eq(r.moves[1].card .. r.moves[1].by .. r.moves[2].card .. r.moves[2].by, "2L1R", "who took what")
    local plain = P.resolve({ n(2), n(14), n(11) })
    eq(s(plain.total), "27", "numbers score as vanilla")
    eq(#plain.moves, 0, "and nobody moves")
  end)

  test("sign expansions round-trip, and simplest numbers are simplest", function(eq)
    local as = { 0, 0, 0, 1, -1, 2, 1 / 2 }
    local ks = { 0, 0, 1, -1, 2, 1 / 2, -1 / 2, 3 / 4, 3 / 2 }
    local xs = {}
    for p = -24, 24 do xs[#xs + 1] = p / 4 end
    local rng = 12345
    local function pick(t)
      rng = (rng * 1103515245 + 12345) % 2147483648
      return t[rng % #t + 1]
    end
    local function copy(acc)
      local p = {}
      for _, a in ipairs(acc) do p[#p + 1] = { s = a.s, l = a.l, m = a.m, n = a.n } end
      return p
    end
    local function prefixes(runs)
      -- Every finite cut, and cuts at ω²·i + ω·j + t (j, t < 4) inside infinite runs.
      local out, acc = {}, {}
      for _, r in ipairs(runs) do
        local cuts = {}
        for i = 0, r.l - 1 do
          for j = 0, 3 do for t = 0, 3 do cuts[#cuts + 1] = { i, j, t } end end
        end
        for j = 0, r.m - 1 do
          for t = 0, 5 do cuts[#cuts + 1] = { r.l, j, t } end
        end
        for t = 0, r.n - 1 do cuts[#cuts + 1] = { r.l, r.m, t } end
        for _, c in ipairs(cuts) do
          local p = copy(acc)
          if c[1] > 0 or c[2] > 0 or c[3] > 0 then p[#p + 1] = { s = r.s, l = c[1], m = c[2], n = c[3] } end
          out[#out + 1] = p
        end
        acc[#acc + 1] = { s = r.s, l = r.l, m = r.m, n = r.n }
      end
      return out
    end
    local checked = 0
    for _ = 1, 600 do
      local a, b = n(pick(xs), pick(ks), pick(as)), n(pick(xs), pick(ks), pick(as))
      eq(s(N.from_signs(N.signs(a))), s(a), "round trip " .. s(a))
      if N.lt(b, a) then a, b = b, a end
      if N.lt(a, b) then
        local m = N.simplest_between(a, b)
        local label = ("{%s|%s} = %s"):format(s(a), s(b), s(m))
        eq(N.lt(a, m) and N.lt(m, b), true, label .. " lies between")
        for _, p in ipairs(prefixes(N.signs(m))) do
          local ok, v = pcall(N.from_signs, p)
          if ok and not N.eq(v, m) then
            checked = checked + 1
            eq(N.lt(a, v) and N.lt(v, b), false, label .. ": simpler " .. s(v) .. " also lies between")
          end
        end
      end
    end
    eq(checked > 2000, true, "the prefixes were read (" .. checked .. ")")
  end)

  test("ω²: order, sums, cuts and birthdays", function(eq)
    local w2 = N.omega2
    local function day(v)
      local b = N.birthday(v)
      return ("%d,%d,%d"):format(b.l, b.m, b.n)
    end
    eq(N.lt(n(0, 1000), w2), true, "ω² is above every ω-multiple")
    eq(N.lt(n(0, 0, 1 / 2), w2) and N.lt(n(0, 1000), n(0, 0, 1 / 2)), true, "ω²/2 lies between")
    eq(s(N.add(w2, w2)), "2w^2", "ω² + ω² = 2ω²")
    eq(s(N.add(n(14, 1), w2)), "w^2+w+14", "the sum commutes")
    eq(day(w2), "1,0,0", "ω² is born on day ω²")
    eq(day(n(3, 2, 1)), "1,2,3", "ω² + 2ω + 3 on day ω² + ω·2 + 3")
    eq(day(n(0, -1, 1)), "1,1,0", "ω² − ω on day ω² + ω")
    -- In a positive interval that holds an ordinal, the least ordinal there is the simplest number.
    for _, c in ipairs({
      { cut(w, w2), "w+1" }, { cut(n(0, 2), w2), "2w+1" }, { cut(n(0), w2), "1" }, { cut(w2, nil), "w^2+1" },
      { cut(nil, w2), "0" }, { cut(w2, n(0, 0, 2)), "w^2+1" }, { cut(w2, n(4, 0, 1)), "w^2+1" },
      { cut(n(3, 0, 1), n(4, 0, 1)), "w^2+7/2" }, { cut(n(0, 5, 1), n(0, 0, 2)), "w^2+5w+1" },
      { cut(w2, n(0, 1, 1)), "w^2+1" }, { cut(n(0, -1, 1), w2), "w^2-1" }, { cut(n(0, 1 / 2), w2), "w" },
      { cut(w2, n(0)), "{w^2|0}" },
    }) do
      eq(s(c[1]), c[2], c[2])
    end
    local l, r = N.options(w2)
    eq(tostring(l) .. " " .. tostring(r), "inf nil", "ω²'s Left options are every ω·m + n")
    l, r = N.options(N.add(w2, N.one))
    eq(s(l) .. " " .. tostring(r), "w^2 nil", "ω² + 1 = {ω²|}")
    for _, t in ipairs({ "w^2", "-w^2", "2w^2+w-3", "w^2/2", "-3w^2/4+5w/8-1/2", "w^2+14", "w^2-w" }) do
      eq(s(N.parse(t)), t, "notation " .. t)
    end
    eq(pcall(N.parse, "w^2/3"), false, "w^2/3 is not dyadic")
  end)

  test("number options", function(eq)
    local function opts(v)
      local l, r = N.options(v)
      local function f(o) return o == nil and "-" or (o == "inf" and "inf" or s(o)) end
      return f(l) .. " " .. f(r)
    end
    eq(opts(n(7 / 2)), "3 4", "3½")
    eq(opts(n(3 / 4)), "1/2 1", "¾")
    eq(opts(n(4)), "3 -", "4")
    eq(opts(n(-2)), "- -1", "-2")
    eq(opts(w), "inf -", "ω")
    eq(opts(N.add(w, N.one)), "w -", "ω+1")
    eq(opts(N.sub(w, N.one)), "inf w", "ω-1")
    eq(opts(n(0, 1 / 2)), "inf inf", "ω/2")
  end)

  test("the grid: exact or refused, never rounded", function(eq)
    local function refuses(f, label) eq(pcall(f), false, label) end
    refuses(function() return N.parse("1/3") end, "1/3 is not a dyadic")
    refuses(function() return N.parse("w/3") end, "nor is w/3")
    refuses(function() return N.parse("0.5") end, "decimals are not notation")
    refuses(function() return N.new(2 ^ -33) end, "finer than the grain")
    refuses(function() return N.new(2 ^ 20) end, "outside the range")
    refuses(function() return N.half(N.new(2 ^ -32)) end, "halving the finest value")
    refuses(function() return N.simplest_between(N.one, N.new(1 + 2 ^ -32)) end, "a cut that needs 33 bits")
    eq(s(N.new(2 ^ -32)), "1/4294967296", "the finest value encodes")
    eq(s(N.parse("-3w/4+5/8")), "-3w/4+5/8", "notation round-trips")
    eq(s(N.simplest_between(N.one, N.new(1 + 2 ^ -31))), "4294967297/4294967296", "the finest cut that fits")
  end)

  test("nim facts from the design", function(eq)
    local names = { [11] = "J", [12] = "C", [13] = "Q", [14] = "K", [15] = "A" }
    local function r(x) return names[x] or tostring(x) end
    local cycle, x = {}, 15
    for i = 1, 16 do cycle[i] = r(x); x = nim.step(x) end
    eq(table.concat(cycle, " "), "A 9 Q C 3 10 7 J 8 2 5 K 6 4 1 A", "15's cycle, from the Ace")
    eq(nim.log15(15) .. " " .. nim.log15(9) .. " " .. nim.log15(4) .. " " .. nim.log15(1), "1 2 14 15", "discrete logs")
    local sq = {}
    for v = 0, 15 do sq[#sq + 1] = r(v) .. ">" .. r(nim.square(v)) end
    eq(table.concat(sq, " "), "0>0 1>1 2>3 3>2 4>6 5>7 6>5 7>4 8>Q 9>C 10>K J>A C>J Q>10 K>8 A>9", "Frobenius")
    local cubes = {}
    for v = 1, 15 do cubes[nim.pow(v, 3)] = true end
    local list = {}
    for v = 0, 15 do if cubes[v] then list[#list + 1] = r(v) end end
    eq(table.concat(list, " "), "1 8 10 Q K", "the nim-cubes, so no finite rank cubes to 2")
    eq(nim.sum({ 2, 4, 6 }), 0, "a zero-sum triple")
    eq(nim.mex({ 0, 1, 2, 4 }), 3, "mex")
  end)
end
