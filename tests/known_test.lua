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
    eq(table.concat(P.ranks(wild), ","), "2,3,4,5,6,7,8,9,10,11,12,13,14,15", "plays as 2 through Knight")
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
    local ks = { 0, 0, 1, -1, 2, 1 / 2, -1 / 2, 3 / 4, 3 / 2 }
    local xs = {}
    for p = -24, 24 do xs[#xs + 1] = p / 4 end
    local rng = 12345
    local function pick(t)
      rng = (rng * 1103515245 + 12345) % 2147483648
      return t[rng % #t + 1]
    end
    local function prefixes(runs)
      -- Every finite cut, and cuts at ω·j + t (t < 6) inside infinite runs.
      local out, acc = {}, {}
      for _, r in ipairs(runs) do
        for j = 0, r.m - 1 do
          for t = 0, 5 do
            local p = {}
            for _, a in ipairs(acc) do p[#p + 1] = { s = a.s, m = a.m, n = a.n } end
            if j > 0 or t > 0 then p[#p + 1] = { s = r.s, m = j, n = t } end
            out[#out + 1] = p
          end
        end
        for t = 0, r.n - 1 do
          local p = {}
          for _, a in ipairs(acc) do p[#p + 1] = { s = a.s, m = a.m, n = a.n } end
          if r.m > 0 or t > 0 then p[#p + 1] = { s = r.s, m = r.m, n = t } end
          out[#out + 1] = p
        end
        acc[#acc + 1] = { s = r.s, m = r.m, n = r.n }
      end
      return out
    end
    for _ = 1, 400 do
      local a, b = n(pick(xs), pick(ks)), n(pick(xs), pick(ks))
      eq(s(N.from_signs(N.signs(a))), s(a), "round trip " .. s(a))
      if N.lt(b, a) then a, b = b, a end
      if N.lt(a, b) then
        local m = N.simplest_between(a, b)
        local label = ("{%s|%s} = %s"):format(s(a), s(b), s(m))
        eq(N.lt(a, m) and N.lt(m, b), true, label .. " lies between")
        for _, p in ipairs(prefixes(N.signs(m))) do
          local ok, v = pcall(N.from_signs, p)
          if ok and not N.eq(v, m) then
            eq(N.lt(a, v) and N.lt(v, b), false, label .. ": simpler " .. s(v) .. " also lies between")
          end
        end
      end
    end
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

  test("nim facts from the design", function(eq)
    local names = { [11] = "J", [12] = "Q", [13] = "K", [14] = "A", [15] = "Kn" }
    local function r(x) return names[x] or tostring(x) end
    local cycle, x = {}, 15
    for i = 1, 16 do cycle[i] = r(x); x = nim.step(x) end
    eq(table.concat(cycle, " "), "Kn 9 K Q 3 10 7 J 8 2 5 A 6 4 1 Kn", "15's cycle")
    eq(nim.log15(15) .. " " .. nim.log15(9) .. " " .. nim.log15(4) .. " " .. nim.log15(1), "1 2 14 15", "discrete logs")
    local sq = {}
    for v = 0, 15 do sq[#sq + 1] = r(v) .. ">" .. r(nim.square(v)) end
    eq(table.concat(sq, " "), "0>0 1>1 2>3 3>2 4>6 5>7 6>5 7>4 8>K 9>Q 10>A J>Kn Q>J K>10 A>8 Kn>9", "Frobenius")
    local cubes = {}
    for v = 1, 15 do cubes[nim.pow(v, 3)] = true end
    local list = {}
    for v = 0, 15 do if cubes[v] then list[#list + 1] = r(v) end end
    eq(table.concat(list, " "), "1 8 10 K A", "the nim-cubes, so no finite rank cubes to 2")
    eq(nim.sum({ 2, 4, 6 }), 0, "a zero-sum triple")
    eq(nim.mex({ 0, 1, 2, 4 }), 3, "mex")
  end)
end
