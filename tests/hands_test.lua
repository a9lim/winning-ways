-- The rank-assignment candidates (src/engine/hands.lua), without the game.
local E = dofile("tests/engine.lua")
local H = E.hands

local WILD = {}
for r = 2, 15 do WILD[#WILD + 1] = r end

local function fixed(r) return { ranks = { r }, key = "#" .. r .. math.random() } end
local function flex(set, key) return { ranks = set, key = key or ("f" .. math.random()) } end
local function rankless(key) return { ranks = {}, key = key } end

-- Does some candidate give card i rank r?
local function offers(cands, i, r)
  for _, a in ipairs(cands) do if a[i] == r then return true end end
  return false
end
local function offers_all(cands, want)
  for _, a in ipairs(cands) do
    local ok = true
    for i, r in pairs(want) do if a[i] ~= r then ok = false end end
    if ok then return true end
  end
  return false
end

return function(test)
  test("of a kind: a wild joins the Kings", function(eq)
    local c = H.candidates({ fixed(13), fixed(13), fixed(13), flex(WILD), fixed(2) })
    eq(offers(c, 4, 13), true, "wild as K")
  end)

  test("straights: the wild fills the gap, and runs reach the Knight", function(eq)
    local c = H.candidates({ fixed(4), flex(WILD), fixed(6), fixed(7), fixed(8) })
    eq(offers(c, 2, 5), true, "4 _ 6 7 8")
    c = H.candidates({ fixed(11), fixed(12), fixed(13), fixed(14), flex(WILD) })
    eq(offers(c, 5, 15), true, "J Q K A _ -> Knight")
    c = H.candidates({ flex({ 0, 1 }), fixed(1), fixed(2), fixed(3), fixed(4) })
    eq(offers(c, 1, 0), true, "0-1-2-3-4")
  end)

  test("windows follow the Ace rules", function(eq)
    local has = {}
    for _, w in ipairs(H.straight_windows(5, false)) do has[table.concat(w, " ")] = true end
    eq(has["14 2 3 4 5"], true, "A-2-3-4-5")
    eq(has["11 12 13 14 15"], true, "J-Q-K-A-Kn")
    eq(has["0 1 2 3 4"], true, "0-1-2-3-4")
    eq(has["12 13 14 2 3"], nil, "no wrapping through the Ace")
    eq(has["13 14 15 2 3"], nil, "nothing after the Knight")
    local skips = {}
    for _, w in ipairs(H.straight_windows(5, true)) do skips[table.concat(w, " ")] = true end
    eq(skips["2 4 6 8 10"], true, "Shortcut skips")
    local four = {}
    for _, w in ipairs(H.straight_windows(4, true)) do four[table.concat(w, " ")] = true end
    eq(four["12 13 14 15"], true, "Q-K-A-Kn, the Ace in the middle leading to the Knight")
    eq(four["11 12 13 15"], nil, "but a skip never jumps the Ace")
  end)

  test("full house and two pair use two ranks", function(eq)
    local c = H.candidates({ fixed(9), fixed(9), fixed(5), flex({ 5, 6, 7, 8, 9 }), flex({ 5, 6, 7, 8, 9 }) })
    eq(offers_all(c, { [4] = 9, [5] = 5 }) or offers_all(c, { [4] = 5, [5] = 9 }), true, "9 9 5 + two wilds -> house")
  end)

  test("equal rankless values tie", function(eq)
    local c = H.candidates({ rankless("7/2"), rankless("7/2"), fixed(7), rankless("w"), fixed(13) })
    eq(c[1][1], "tie1", "first 3½")
    eq(c[1][2], "tie1", "second 3½")
    eq(c[1][4], false, "a lone ω has no rank")
    eq(#c, 1, "no flexible cards, one candidate")
  end)
end
