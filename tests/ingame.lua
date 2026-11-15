-- In-game self-test. `WINNINGWAYS_SELFTEST=<file> balala` boots the game and, at the main menu, checks the
-- engine on the game's own LuaJIT, then builds cards with values and reads and scores hands with the game's
-- real evaluator. It writes PASS/FAIL lines to <file> and quits. It never starts a run.
local out_path = os.getenv("WINNINGWAYS_SELFTEST")
local WW = WinningWays
local E = WW.engine
local lines, failed = {}, 0

local function check(name, ok, detail)
  if not ok then failed = failed + 1 end
  lines[#lines + 1] = (ok and "PASS " or "FAIL ") .. name .. (detail and (" (" .. tostring(detail) .. ")") or "")
end

local N, Gm, P = E.num, E.game, E.play
local n = N.new
local function cut(a, b) return Gm.of(a and { a } or {}, b and { b } or {}) end

local made = {}
-- "H_K", "S_T", "D_0", "C_C"; an optional value makes the card worth it.
local function card(code, value)
  -- Steamodded prefixes a mod rank's card key: the Cavalier of Hearts is H_ww_C.
  local suit, rank = code:match("^(%a)_(%w+)$")
  if rank == "0" or rank == "1" or rank == "C" then code = suit .. "_ww_" .. rank end
  assert(G.P_CARDS[code], "no card " .. code)
  local c = Card(0, 0, G.CARD_W, G.CARD_H, G.P_CARDS[code], G.P_CENTERS.c_base)
  made[#made + 1] = c
  if value then WW.set_value(c, value) end
  return c
end

local function hand_name(cards)
  local results = evaluate_poker_hand(cards)
  for _, name in ipairs(G.handlist) do
    if next(results[name]) then return name end
  end
  return "NULL"
end

local function expect(name, cards, want)
  local got = hand_name(cards)
  check(name, got == want, ("got %s, want %s"):format(got, want))
end

local function engine()
  check("the engine loaded", N and Gm and P and E.nim and E.hands)
  check("{3|4} = 3½", Gm.encode(cut(n(3), n(4))) == "7/2")
  check("{J|Q} = C", Gm.encode(cut(n(11), n(13))) == "12")
  local ranks = table.concat(P.ranks(cut(N.omega, n(2))), ",")
  check("{ω|2} plays as every rank from 2", ranks == "2,3,4,5,6,7,8,9,10,11,12,13,14,15", ranks)
  local r = P.resolve({ cut(n(6), n(4)), cut(n(14), n(2)), n(7) })
  check("the hotstrat scores 25", N.encode(r.total) == "25", N.encode(r.total))
  check("Q ⊗ K = 1 in nim arithmetic", E.nim.mul(13, 14) == 1)
end

local function ranks()
  for _, k in ipairs({ "ww_0", "ww_1", "ww_C" }) do check("rank " .. k .. " registered", SMODS.Ranks[k] ~= nil) end
  local c = card("H_C")
  check("the Cavalier is a face card", c:is_face() == true)
  check("the Cavalier scores 10", c:get_chip_bonus() == 10, c:get_chip_bonus())
  check("Strength still turns a Jack into a Queen", SMODS.Ranks.Jack.next[1] == "Queen")
  expect("J C Q K A is a straight", { card("H_J"), card("S_C"), card("D_Q"), card("C_K"), card("H_A") }, "Straight")
  expect("9 10 J C Q is a straight", { card("H_9"), card("S_T"), card("D_J"), card("C_C"), card("H_Q") }, "Straight")
  expect("10 J Q K A is still a straight", { card("H_T"), card("S_J"), card("D_Q"), card("C_K"), card("H_A") }, "Straight")
  expect("0 1 2 3 4 is a straight", { card("H_0"), card("S_1"), card("D_2"), card("C_3"), card("H_4") }, "Straight")
  expect("A 2 3 4 5 is still a straight", { card("H_A"), card("S_2"), card("D_3"), card("C_4"), card("H_5") }, "Straight")
  expect("K A 2 3 4 still isn't", { card("H_K"), card("S_A"), card("D_2"), card("C_3"), card("H_4") }, "High Card")
  expect("J C K A 2 isn't either", { card("H_J"), card("S_C"), card("D_K"), card("C_A"), card("H_2") }, "High Card")
end

local function values()
  local wild = cut(N.omega, n(2))
  local w = card("S_A", wild)
  check("the wild sits on the Ace", w.base.value == "Ace", w.base.value)
  check("its modifier is the rest of the value", w.ability.ww_mod == "{w-15|-13}", w.ability.ww_mod)
  check("rank + modifier gives the value back", Gm.encode(WW.value_of(w)) == "{w|2}", Gm.encode(WW.value_of(w)))
  local hand = { card("H_K"), card("S_K"), card("D_K"), w, card("C_2") }
  expect("three Kings and a wild are Four of a Kind", hand, "Four of a Kind")
  check("the wild plays as a King", WW.playing_as(w) == "King", WW.playing_as(w))
  check("and reports a King's id", w:get_id() == SMODS.Ranks.King.id, w:get_id())
  expect("4 _ 6 7 8 with a wild is a straight",
    { card("H_4"), card("S_A", wild), card("D_6"), card("C_7"), card("H_8") }, "Straight")
  expect("K K Q Q + wild, all hearts, is a Flush House",
    { card("H_K"), card("H_K"), card("H_Q"), card("H_Q"), card("H_A", wild) }, "Flush House")
  local h9 = cut(n(9), n(5))
  local hot = card("D_3", h9)
  check("{9|5} is a 7 with ±2", hot.base.value == "7" and hot.ability.ww_mod == "{2|-2}", hot.base.value .. " " .. tostring(hot.ability.ww_mod))
  expect("9 9 + two {9|5}s: the hot cards join the 9s", { card("H_9"), card("S_9"), hot, card("C_3", h9) }, "Four of a Kind")
  local half = cut(n(3), n(4))
  local a = card("H_3", half)
  check("3½ is a 3 with +½", a.base.value == "3" and a.ability.ww_mod == "1/2", a.base.value .. " " .. tostring(a.ability.ww_mod))
  check("3½ has no rank", SMODS.has_no_rank(a) == true)
  local b = card("S_4")
  WW.add_mod(b, n(-0.5))
  expect("a 3 with +½ and a 4 with −½ are equal, so a Pair", { a, b, card("D_7"), card("C_9"), card("H_K") }, "Pair")
  expect("one 3½ is not", { card("H_3", half), card("D_7"), card("C_9"), card("H_K") }, "High Card")
  local s = card("H_9", h9)
  assert(SMODS.change_base(s, nil, "8"))
  check("Strength-style rank changes keep the modifier: 7±2 on an 8 is 8±2",
    Gm.encode(WW.value_of(s)) == "{10|6}", Gm.encode(WW.value_of(s)))
  local c5 = card("H_5", cut(n(5), n(5)))
  check("5* is a 5 with *, and plays as a 5", c5.ability.ww_mod == "{0|0}" and c5:get_id() == SMODS.Ranks["5"].id)
  local copy = copy_card(card("H_8", h9))
  made[#made + 1] = copy
  check("copies keep the modifier", copy.ability.ww_mod == "{2|-2}", copy.ability.ww_mod)
  local omega_k = WW.add_mod(card("H_K"), N.omega)
  check("adding ω to a King gives ω + 14", Gm.encode(WW.value_of(omega_k)) == "w+14", Gm.encode(WW.value_of(omega_k)))
  local w13, w2, w2b, ww = card("H_K"), card("S_2"), card("D_2"), card("C_5")
  WW.add_mod(w13, N.omega); WW.add_mod(w2, N.omega); WW.add_mod(w2b, n(0, 2)); WW.add_mod(ww, n(0, 2))
  expect("ω + 14 and ω + 2 are in one galaxy, so a Pair", { w13, w2, card("D_7"), card("C_9") }, "Pair")
  expect("ω + 14 and 2ω + 2 are not", { card("H_K"), w2b, card("D_7"), card("C_9") }, "High Card")
  local plain = card("H_6", n(6))
  check("an integer value is a plain card", plain.ability.ww_mod == nil and plain.base.value == "6")
end

local function scoring()
  local hot, wide, seven = card("H_6", cut(n(6), n(4))), card("S_8", cut(n(15), n(2))), card("D_7")
  local r = WW.resolve({ hot, wide, seven })
  check("the hand plays out to 26", N.encode(r.total) == "26", N.encode(r.total))
  for i, c in ipairs(r.cards) do WW._finals[c] = r.finals[i] end
  local chips = { hot:get_chip_bonus(), wide:get_chip_bonus(), seven:get_chip_bonus() }
  for _, c in ipairs(r.cards) do WW._finals[c] = nil end
  check("chips: the Blind took 4, you took an Ace's 11, the 7 is a 7",
    chips[1] == 4 and chips[2] == 11 and chips[3] == 7, table.concat(chips, " "))
  check("a plain hand isn't resolved at all", WW.resolve({ card("H_K"), card("S_K") }) == nil)
  check("J, C, Q and K still score 10", WW.chips_of(n(11)) == 10 and WW.chips_of(n(12)) == 10
    and WW.chips_of(n(13)) == 10 and WW.chips_of(n(14)) == 10)
  check("3½ scores 3.5", WW.chips_of(n(3.5)) == 3.5)
  check("ω scores nothing, ω + 14 a King's 10", WW.chips_of(N.omega) == 0 and WW.chips_of(n(14, 1)) == 10)
end

local function faces()
  if not WW.badge_of then
    check("the faces loaded (Fable's art is present)", false)
    return
  end
  local cards = {}
  for _, code in ipairs({ "D_3", "C_6", "H_T", "H_7", "C_5", "S_Q", "S_9", "H_4", "S_A", "D_8", "C_K" }) do
    cards[#cards + 1] = card(code)
  end
  WW.apply_lab(cards)
  local want = {
    "offset:+ offset:½", "offset:− offset:¼", "offset:+ offset:⅜", "heat:± heat:2", "heat:± heat:1",
    "heat:± heat:1", " *", " *", "wild", "heat:5 heat:| heat:3", "infinite:+ infinite:ω",
  }
  for i, c in ipairs(cards) do
    local got = WW.look_text(WW.badge_of(c))
    check("look of lab card " .. i, got == want[i], ("got %s, want %s"):format(got, want[i]))
  end
  local ui = cards[1]:generate_UIBox_ability_table()
  local last = ui.info and ui.info[#ui.info]
  check("the tooltip has a Modifier box", last and last.name == "Modifier", last and last.name)
  local sixteenth = card("H_5")
  WW.add_mod(sixteenth, n(5 / 16))
  local got = WW.look_text(WW.badge_of(sixteenth))
  check("other fractions use small digits", got == "offset:+ offset:s5 offset:s/ offset:s1 offset:s6", got)
  local up = card("H_6")
  WW.add_mod(up, Gm.of({ N.zero }, { Gm.of({ N.zero }, { N.zero }) }))
  check("↑ shows as an arrow", WW.look_text(WW.badge_of(up)) == "infinitesimal:↑", WW.look_text(WW.badge_of(up)))
end

local function moves()
  if not WW.MOVES then check("the Moves loaded", false); return end
  local M = WW.MOVES
  local function v(c) return Gm.encode(WW.value_of(c)) end
  local a, b = card("H_3"), card("S_7")
  local r = M.cut.apply({ a, b })
  check("Cut 3, 7 makes a 4 and uses up the 7", v(a) == "4" and r.destroy and r.destroy[1] == b, v(a))
  a, b = card("H_9"), card("S_5")
  M.cut.apply({ a, b })
  check("Cut 9, 5 makes 7±2", v(a) == "{9|5}" and a.base.value == "7", v(a) .. " on " .. a.base.value)
  a = card("H_K")
  M.cut.apply({ a })
  check("Cut on one card rounds up: K becomes A", v(a) == "15" and a.base.value == "Ace", v(a))
  r = M.cut.apply({})
  check("Cut on nothing makes a 0", r.create and r.create.rank == "ww_0")
  a, b = card("H_J"), card("S_Q")
  M.cut.apply({ a, b })
  check("Cut J, Q makes a Cavalier", a.base.value == "ww_C" and not WW.has_mod(a), a.base.value)
  a, b = card("H_3"), card("S_4")
  b:set_ability(G.P_CENTERS.m_glass, nil, true)
  M.sum.apply({ a, b })
  check("Sum 3 + 4 is a 7, and the newborn takes the Glass", v(a) == "7" and a.config.center.key == "m_glass",
    v(a) .. " " .. a.config.center.key)
  local hot = card("H_7")
  WW.add_mod(hot, Gm.of({ n(2) }, { n(-2) }))
  M.heat.apply({ hot })
  check("Heat: 7±2 becomes 7±3", v(hot) == "{10|4}", v(hot))
  M.cool.apply({ hot }); M.cool.apply({ hot })
  check("Cool twice: 7±1", v(hot) == "{8|6}", v(hot))
  M.cool.apply({ hot })
  check("Cool again: 7*", v(hot) == "{7|7}", v(hot))
  M.cool.apply({ hot })
  check("and once more: a plain 7", v(hot) == "7" and not WW.has_mod(hot), v(hot))
  local j, e = card("H_J"), card("S_8")
  M.frobenius.apply({ j, e })
  check("Frobenius: J becomes A, 8 becomes Q", j.base.value == "Ace" and e.base.value == "Queen", j.base.value .. " " .. e.base.value)
  local s = card("S_5")
  M.repaint.apply({ s })
  check("Repaint: Spades become Hearts", s.base.suit == "Hearts", s.base.suit)
  local x, z, o = card("H_9"), card("S_0"), card("D_1")
  M.mex.apply({ x, z, o })
  check("Mex beside a 0 and a 1 makes a 2", x.base.value == "2", x.base.value)
  local h = card("H_5")
  M.nimbus.apply({ h })
  check("Nimbus: 5*", v(h) == "{5|5}", v(h))
  M.nimbus.apply({ h })
  check("two halos cancel: * + * = 0", v(h) == "5" and not WW.has_mod(h), v(h))
  local k = card("C_K")
  M.omega.apply({ k })
  check("Omega: K + ω", v(k) == "w+14" and k.base.value == "King", v(k))
  check("the Move set is registered", SMODS.ConsumableTypes and SMODS.ConsumableTypes.Move ~= nil)
  for _, key in ipairs({ "cut", "sum", "heat", "cool", "frobenius", "tweedledum", "repaint", "nimbus", "mex", "omega" }) do
    check("c_ww_" .. key .. " exists", G.P_CENTERS["c_ww_" .. key] ~= nil)
  end
  check("the Game Packs exist", G.P_CENTERS.p_ww_game_normal_1 ~= nil and G.P_CENTERS.p_ww_game_mega_1 ~= nil)
end

local function eating()
  local function omega(code) return WW.add_mod(card(code), N.omega) end
  local j1, w1, j2, w2, j3 = card("H_3"), omega("S_K"), card("D_5"), omega("C_2"), card("H_9")
  local eaten = WW.eating({ j1, w1, j2, w2, j3 })
  check("ω eats the finite card to its left", eaten[j1] == w1)
  check("the next ω eats only back to the first", eaten[j2] == w2 and eaten[w1] == nil)
  check("nothing eats to the right", eaten[j3] == nil)
  local junk, wild, w3 = card("H_4"), card("S_A", Gm.of({ N.omega }, { n(2) })), omega("D_K")
  eaten = WW.eating({ junk, wild, w3 })
  check("an infinite card (the wild) blocks: nothing is eaten", next(eaten) == nil)
  local a, b, w4, c, d = card("H_7"), card("S_7"), omega("D_K"), card("C_9"), card("H_9")
  local function place(cards) for i, x in ipairs(cards) do x.T.x = i end end
  local hand = { a, b, w4, c, d }
  place(hand)
  expect("7 7 ω 9 9: the 7s are eaten, so a Pair of 9s", hand, "Pair")
  local food, growth = WW.feed(hand)
  check("feeding: the two 7s go", #food == 2)
  check("the eater grows by their chips", growth[w4] == 14 and w4.ability.perma_bonus == 14, growth[w4])
  check("an ω card always scores", SMODS.always_scores(w4) == true)
end

local function jokers()
  for _, k in ipairs({ "bouton", "generator", "grundy", "hotstrat", "thermograph", "sprouts", "cantor", "paradise",
    "conway" }) do
    check("j_ww_" .. k .. " exists", G.P_CENTERS["j_ww_" .. k] ~= nil)
  end
  check("The Heap exists", G.P_BLINDS.bl_ww_heap ~= nil)
  check("the Field Deck exists", G.P_CENTERS.b_ww_field ~= nil)

  -- Bouton and The Heap read nim-sums of the ranks cards play as.
  local one, two, three = card("H_1"), card("S_2"), card("D_3")
  check("1 ⊕ 2 ⊕ 3 = 0", WW.nim_sum({ one, two, three }) == 0)
  check("Bouton: 1 2 3", WW.bouton({ one, two, three }, { three }))
  local k1, k2, z, f1, f2 = card("H_K"), card("S_K"), card("D_0"), card("C_5"), card("H_5")
  check("a Pair nim-sums to 0 (The Heap)", WW.nim_sum({ k1, k2 }) == 0)
  check("Bouton: K K 5 5 with a 0 kicker has three ranks", WW.bouton({ k1, k2, z, f1, f2 }, { k1, k2, f1, f2 }))
  check("but K K 5 5 alone has two", not WW.bouton({ k1, k2, f1, f2 }, { k1, k2, f1, f2 }))
  local q, w, four = card("S_Q"), card("C_A", cut(N.omega, n(2))), card("C_4")
  check("Bouton: a wild kicker plays as K ⊕ Q = 3", WW.bouton({ k1, q, w }, { k1 }))
  check("Bouton: a 4 kicker can't", not WW.bouton({ k1, q, four }, { k1 }))
  check("Bouton: a scoring wild plays as its assigned rank, not any", not WW.bouton({ k1, q, w }, { k1, w }))

  -- Grundy's mex.
  check("mex of 0 1 2 4 is 3", WW.mex_of({ card("H_0"), card("S_1"), card("D_2"), card("C_4") }) == 3)
  check("mex without a 0 is 0", WW.mex_of({ card("H_9"), card("S_1") }) == 0)

  -- Hot cards (Hotstrat, Thermograph).
  local hot, star, up = card("H_7", cut(n(9), n(5))), card("S_5", cut(N.zero, N.zero)), card("D_6")
  WW.add_mod(up, Gm.of({ N.zero }, { Gm.of({ N.zero }, { N.zero }) }))
  check("7±2 is hot", WW.is_hot(WW.value_of(hot)))
  check("5* and 6↑ are not", not WW.is_hot(WW.value_of(star)) and not WW.is_hot(WW.value_of(up)))
  check("7±2's temperature is 2", WW.finite_temperature(hot) == 2, WW.finite_temperature(hot))
  check("the wild's never freezes", WW.finite_temperature(w) == nil)
  local held = WW.thermograph_held
  WW.thermograph_held = function() return true end
  local ok, r = pcall(WW.resolve, { hot, card("S_7") })
  WW.thermograph_held = held
  check("Thermograph: 7±2 scores its mean, 7", ok and N.encode(r.finals[1]) == "7", ok and N.encode(r.finals[1]) or r)

  -- Generator's cycle.
  check("the Ace steps to a 9 and pays 1", E.nim.step(15) == 9 and E.nim.log15(15) == 1)
  check("the 1 steps to the Ace and pays 15", E.nim.step(1) == 15 and E.nim.log15(1) == 15)

  -- Conway: each card can also play as {left | right}.
  local find = SMODS.find_card
  SMODS.find_card = function(key, ...)
    if key == "j_ww_conway" then return { {} } end
    return find(key, ...)
  end
  WW.reading_main = true
  local function row(codes)
    local cards = {}
    for i, code in ipairs(codes) do cards[i] = card(code); cards[i].T.x = i end
    return cards
  end
  local ok2, err = pcall(function()
    local kxk = row({ "H_K", "S_5", "D_K" })
    expect("Conway: K 5 K is Three of a Kind", kxk, "Three of a Kind")
    check("the 5 plays as {K|K} = K*, a King", WW.playing_as(kxk[2]) == "King", WW.playing_as(kxk[2]))
    expect("Conway: 3 4 K 6 7 is a Straight (the K is {4|6} = 5)", row({ "H_3", "S_4", "D_K", "C_6", "H_7" }), "Straight")
    expect("Conway: the right end is {L|}: 2 3 4 5 K is a Straight", row({ "H_2", "S_3", "D_4", "C_5", "H_K" }), "Straight")
    expect("Conway: Q 2 K gives the 2 13½, no rank", row({ "H_Q", "S_2", "D_K" }), "High Card")
  end)
  WW.reading_main = nil
  SMODS.find_card = find
  check("Conway's checks ran", ok2, err)
  WW.reading_main = true
  expect("without Conway, K 5 K is a Pair", row({ "H_K", "S_5", "D_K" }), "Pair")
  WW.reading_main = nil

  -- Cantor's diagonal.
  local deck = G.playing_cards
  G.playing_cards = { card("H_A"), card("S_A"), card("D_A"), card("C_A") }
  local missing = WW.missing_pairs()
  check("Cantor: with only the Aces, 48 pairs are missing", #missing == 48, #missing)
  local all = {}
  for _, s in ipairs({ "H", "S", "D", "C" }) do
    for _, r in ipairs({ "2", "3", "4", "5", "6", "7", "8", "9", "T", "J", "Q", "K", "A" }) do all[#all + 1] = card(s .. "_" .. r) end
  end
  G.playing_cards = all
  missing = WW.missing_pairs()
  check("with all 52, the born ranks are next: 12 pairs", #missing == 12 and missing[1].rank:sub(1, 3) == "ww_", #missing)
  G.playing_cards = deck
end

local function speed()
  local wild = cut(N.omega, n(2))
  local hand = { card("H_K", wild), card("S_9"), card("D_A", wild), card("C_7"), card("H_8", cut(n(9), n(5))) }
  local t0 = love.timer.getTime()
  for _ = 1, 20 do evaluate_poker_hand(hand) end
  local ms = (love.timer.getTime() - t0) * 1000 / 20
  check("reading a hand with two wilds and a hot card takes under 20 ms", ms < 20, ("%.2f ms"):format(ms))
end

local function run()
  engine()
  ranks()
  values()
  scoring()
  faces()
  moves()
  eating()
  jokers()
  speed()
end

local update = Game.update
local done, frames = false, 0
function Game:update(dt)
  update(self, dt)
  if done then return end
  if G.STATE == G.STATES.MENU and G.MAIN_MENU_UI then frames = frames + 1 end
  if frames < 30 then return end
  done = true
  local ok, err = pcall(run)
  if not ok then check("self-test ran to the end", false, err) end
  for _, c in ipairs(made) do c:remove() end
  lines[#lines + 1] = ("%d checks, %d failed"):format(#lines, failed)
  local f = io.open(out_path, "w")
  if f then f:write(table.concat(lines, "\n"), "\n"); f:close() end
  print("WINNINGWAYS SELFTEST\n" .. table.concat(lines, "\n"))
  love.event.quit()
end
