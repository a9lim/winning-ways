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
  if rank == "0" or rank == "1" or rank == "C" or rank == "w" then code = suit .. "_ww_" .. rank end
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
  for _, k in ipairs({ "ww_0", "ww_1", "ww_C", "ww_w" }) do check("rank " .. k .. " registered", SMODS.Ranks[k] ~= nil) end
  local om = card("S_w")
  check("an ω is worth ω", Gm.encode(WW.value_of(om)) == "w" and not WW.has_mod(om), Gm.encode(WW.value_of(om)))
  check("ω plays as no rank", SMODS.has_no_rank(om) == true and #WW.ranks_of(om) == 0 and WW.rank_int("ww_w") == nil)
  check("ω scores no chips of its own", om:get_chip_bonus() == 0, om:get_chip_bonus())
  check("ω sorts after the Ace", SMODS.Ranks.ww_w.sort_nominal > SMODS.Ranks.Ace.sort_nominal)
  check("Strength leaves ω alone", SMODS.Ranks.ww_w.strength_effect.ignore == true and #SMODS.Ranks.ww_w.next == 0)
  check("the mod icon is registered", G.ASSET_ATLAS.ww_modicon ~= nil)
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
  -- Infinite cards go first in these rows, so nothing is to their left to eat.
  local function row(cards) for i, x in ipairs(cards) do x.T.x = i end return cards end
  local w13 = card("H_K", n(14, 1))
  check("ω + 14 is an ω with +14", w13.base.value == "ww_w" and w13.ability.ww_mod == "14",
    w13.base.value .. " " .. tostring(w13.ability.ww_mod))
  check("rank + modifier gives ω + 14 back", Gm.encode(WW.value_of(w13)) == "w+14", Gm.encode(WW.value_of(w13)))
  -- Two infinities of one degree never meet in a hand: the left one merges into the right (src/omega.lua).
  expect("ω + 14 then ω + 2: the left merges into the right, so no Pair",
    row({ w13, card("S_2", n(2, 1)), card("D_7"), card("C_9") }), "High Card")
  expect("two ωs merge too", row({ card("S_w"), card("H_w"), card("D_7"), card("C_9") }), "High Card")
  -- A * changes nothing for hands: n* plays as n, with or without a rank.
  local star = cut(n(0), n(0))
  expect("and so do ω and ω*",
    row({ card("S_w"), card("H_w", Gm.add(N.omega, star)), card("D_7"), card("C_9") }), "High Card")
  expect("3½ and 3½* are still a Pair",
    { card("H_3", n(3.5)), card("S_3", Gm.add(n(3.5), star)), card("D_7"), card("C_9") }, "Pair")
  -- An ω is past every rank, but it is no High Card: the King is, and the ω scores beside it.
  local wk = row({ card("S_w"), card("H_K"), card("D_5") })
  local high = evaluate_poker_hand(wk)["High Card"][1]
  check("ω K 5: the High Card is the King", #high == 1 and high[1] == wk[2])
  -- Sorting a row is another matter: there a card stands by the rank it sits on.
  local function place_of(c) return c:get_nominal() end
  check("an ω sorts past the Ace", place_of(card("S_w")) > place_of(card("S_A")), place_of(card("S_w")))
  check("a 3½ sorts among the 3s",
    place_of(card("S_3", n(3.5))) > place_of(card("S_2")) and place_of(card("S_3", n(3.5))) < place_of(card("S_4")))
  -- Which rank a made value sits on (DESIGN.md § 2.3½).
  local function sits(v) local c = card("H_2", v) return c.base.value .. " " .. tostring(c.ability.ww_mod) end
  check("3¾ sits on the 3 with +¾: a fraction counts up", sits(n(3.75)) == "3 3/4", sits(n(3.75)))
  check("{7±2|3} has mean 5 but plays as 3 or 4, so it sits on the 4",
    sits(cut(cut(n(9), n(5)), n(3))):match("^4 ") ~= nil, sits(cut(cut(n(9), n(5)), n(3))))
  check("13¼±4 sits on the Queen", sits(cut(n(17.25), n(9.25))):match("^Queen ") ~= nil, sits(cut(n(17.25), n(9.25))))
  check("28 sits on the Ace with +13", sits(n(28)) == "Ace 13", sits(n(28)))
  check("−1½ sits on the 0", sits(n(-1.5)) == "ww_0 -3/2", sits(n(-1.5)))
  check("ω/2 sits on ω", sits(n(0, 0.5)):match("^ww_w ") ~= nil, sits(n(0, 0.5)))
  check("ω±1 is infinite either way, so it sits on ω",
    sits(cut(n(1, 1), n(-1, 1))):match("^ww_w ") ~= nil, sits(cut(n(1, 1), n(-1, 1))))
  check("{ω|16} plays as no rank but can end on 16, so it sits on the Ace, not on ω",
    sits(cut(N.omega, n(16))):match("^Ace ") ~= nil, sits(cut(N.omega, n(16))))
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
  -- The tiers: a·ω² + k·ω + x scores x in chips, +k Mult and ×(1 + a) Mult.
  check("ω: +1 Mult, no ×Mult", WW.mult_of(N.omega) == 1 and WW.x_mult_of(N.omega) == 1)
  check("2ω + 5: +2 Mult", WW.mult_of(n(5, 2)) == 2 and WW.chips_of(n(5, 2)) == 5)
  check("ω²: ×2 Mult, and 2ω²: ×3", WW.x_mult_of(N.omega2) == 2 and WW.x_mult_of(n(0, 0, 2)) == 3
    and WW.mult_of(N.omega2) == 0)
  local w2, glass = card("S_w", N.omega2), card("H_w", n(0, 1, 1))
  glass:set_ability(G.P_CENTERS.m_glass, nil, true)
  for _, c in ipairs({ w2, glass }) do WW._finals[c] = WW.value_of(c) end
  local got = { w2:get_chip_mult(), w2:get_chip_x_mult({}), glass:get_chip_mult(), glass:get_chip_x_mult({}) }
  for _, c in ipairs({ w2, glass }) do WW._finals[c] = nil end
  check("an ω² card scores ×2; a Glass ω² + ω scores +1 and ×2·2", got[1] == 0 and got[2] == 2 and got[3] == 1
    and got[4] == 4, table.concat(got, " "))
  check("off the scoring path it gives nothing", w2:get_chip_x_mult({}) == 0 and w2:get_chip_mult() == 0)
end

local function faces()
  if not WW.look_of then
    check("the faces loaded (Fable's parts are present)", false)
    return
  end
  local cards = {}
  for _, code in ipairs({ "D_3", "C_6", "H_T", "H_7", "C_5", "S_Q", "S_9", "H_4", "S_A", "D_8", "C_K" }) do
    cards[#cards + 1] = card(code)
  end
  WW.apply_lab(cards)
  local want = {
    "field Diamonds 3(1/2) 3.5..3.5", "field Clubs 6−(1/4) 5.75..5.75", "field Hearts 10(3/8) 10.375..10.375",
    "field Hearts 7±2 5..9", "field Clubs 5±1 4..6", "base Spades Q±1 court", "field Spades *9 9..9 checker",
    "field Hearts *4 4..4 checker", "split Spades ω over 2", "field Diamonds 4± 3..5", "omega Clubs ω+14",
  }
  for i, c in ipairs(cards) do
    local got = WW.look_text(c)
    check("look of lab card " .. i, got == want[i], ("got %s, want %s"):format(got, want[i]))
  end
  check("a plain card keeps its own front", WW.look_text(card("H_7")) == "none")
  check("a plain ω draws itself", WW.look_text(card("S_w")) == "omega Spades ω", WW.look_text(card("S_w")))
  check("the wild {ω|0}", WW.look_text(card("H_A", cut(N.omega, n(0)))) == "split Hearts ω over 0")
  local ui = cards[1]:generate_UIBox_ability_table()
  local last = ui.info and ui.info[#ui.info]
  check("the tooltip has a Modifier box", last and last.name == "Modifier", last and last.name)
  local sixteenth = card("H_5")
  WW.add_mod(sixteenth, n(5 / 16))
  local got = WW.look_text(sixteenth)
  check("a fraction is one stacked token", got == "field Hearts 5(5/16) 5.3125..5.3125", got)
  local up = card("H_6")
  WW.add_mod(up, Gm.of({ N.zero }, { Gm.of({ N.zero }, { N.zero }) }))
  check("↑ shows as an arrow", WW.look_text(up) == "field Hearts 6↑ 6..6", WW.look_text(up))

  -- A number card's composed front, with no modifier, is vanilla's own card, pixel for pixel: every suit, 2 to 10.
  local F, parts, atlas = WW.fronts, WW.parts, G.ASSET_ATLAS.cards_1
  local scale = G.SETTINGS.GRAPHICS.texture_scaling
  local canvas = love.graphics.newCanvas(F.W, F.H, { dpiscale = scale })
  local wrong, seen = 0, 0
  for letter, suit in pairs({ H = "Hearts", C = "Clubs", D = "Diamonds", S = "Spades" }) do
    for r = 2, 10 do
      local pos = G.P_CARDS[letter .. "_" .. (r == 10 and "T" or r)].pos
      love.graphics.push("all")
      love.graphics.setCanvas(canvas)
      love.graphics.origin()
      love.graphics.clear(0, 0, 0, 0)
      love.graphics.setBlendMode("replace")
      love.graphics.draw(atlas.image,
        love.graphics.newQuad(pos.x * atlas.px, pos.y * atlas.py, F.W, F.H, atlas.image:getDimensions()), 0, 0)
      love.graphics.pop()
      local data = canvas:newImageData()
      local layer = F.compose(parts, { mode = "field", suit = suit, index = { tostring(r) }, right = r, left = r })
      for y = 0, F.H - 1 do
        for x = 0, F.W - 1 do
          local _, _, _, alpha = data:getPixel(x * scale, y * scale)
          if (alpha > 0.5) ~= (layer.cells[y * F.W + x + 1] == F.INK) then wrong = wrong + 1 end
          seen = seen + 1
        end
      end
    end
  end
  check("composed 2 to 10 match vanilla's fronts, every suit", wrong == 0 and seen == 36 * F.W * F.H, wrong .. " pixels differ")

  -- The composed front takes the place of the card's front sprite, and gives it back.
  local step = SMODS.DrawSteps.ww_value_front
  local hot = card("H_7")
  local own = hot.children.front.atlas
  WW.add_mod(hot, cut(n(2), n(-2)))
  step.func(hot)
  local ours = hot.children.front.atlas
  check("a 7±2 draws a composed front", ours ~= own and ours.name:find("ww_front_", 1, true) ~= nil, ours.name)
  local twin = card("H_7")
  WW.add_mod(twin, cut(n(2), n(-2)))
  step.func(twin)
  check("equal looks share one texture", twin.children.front.atlas == ours)
  WW.set_mod(hot, N.zero)
  step.func(hot)
  check("a card that loses its modifier gets its own front back", hot.children.front.atlas == own, hot.children.front.atlas.name)
  local gold = card("S_w")
  step.func(gold)
  local plain_w = gold.children.front.atlas
  gold:set_ability(G.P_CENTERS.m_gold)
  step.func(gold)
  check("an ω is redrawn for its body: Gold shows through", gold.children.front.atlas ~= plain_w)
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
  check("two stars cancel: * + * = 0", v(h) == "5" and not WW.has_mod(h), v(h))
  local k = card("C_K")
  M.omega.apply({ k })
  check("Omega: a King becomes an ω (n + ω = ω)", v(k) == "w" and k.base.value == "ww_w" and not WW.has_mod(k), v(k))
  M.omega.apply({ k })
  check("Omega on an ω makes ω² (ω + ω² = ω²)", v(k) == "w^2" and k.base.value == "ww_w", v(k))
  check("and no further: Balatro has three tiers", WW.omega_lift(k) == nil and not M.omega.need(k))
  local k14 = card("C_K", n(14, 1))
  check("Omega on ω + 14 makes ω² too", WW.omega_lift(k14) == 2)
  check("Omega on the wild {ω|2} makes ω²", WW.omega_lift(card("S_A", cut(N.omega, n(2)))) == 2)
  k = card("D_7", cut(n(9), n(5)))
  M.omega.apply({ k })
  check("Omega on a hot card makes an ω too", v(k) == "w", v(k))
  a, b = card("H_K"), card("S_w")
  M.sum.apply({ a, b })
  check("Sum K + ω is ω + 14, an ω with +14", v(a) == "w+14" and a.base.value == "ww_w", v(a) .. " on " .. a.base.value)
  check("the Move set is registered", SMODS.ConsumableTypes and SMODS.ConsumableTypes.Move ~= nil)
  for _, key in ipairs({ "cut", "sum", "heat", "cool", "frobenius", "tweedledum", "repaint", "nimbus", "mex", "omega" }) do
    check("c_ww_" .. key .. " exists", G.P_CENTERS["c_ww_" .. key] ~= nil)
  end
  check("the Game Packs exist", G.P_CENTERS.p_ww_game_normal_1 ~= nil and G.P_CENTERS.p_ww_game_mega_1 ~= nil)
end

local function eating()
  local function omega(code, v) return card(code, v or N.omega) end
  local j1, w1, j2, w2, j3 = card("H_3"), omega("S_K"), card("D_5"), omega("C_2"), card("H_9")
  local eaten, grown = WW.eating({ j1, w1, j2, w2, j3 })
  check("ω eats the finite card to its left", eaten[j1] == w1)
  check("the next ω eats back past the first, which merges into it", eaten[j2] == w2 and eaten[w1] == w2)
  check("and becomes 2ω", grown[w2] and Gm.encode(grown[w2]) == "2w", grown[w2] and Gm.encode(grown[w2]))
  check("nothing eats to the right", eaten[j3] == nil)
  local junk, wild, w3 = card("H_4"), card("S_A", Gm.of({ N.omega }, { n(2) })), omega("D_K")
  eaten = WW.eating({ junk, wild, w3 })
  check("the wild is a wall: nothing is eaten", next(eaten) == nil)
  -- The row adds up as ordinals: (ω + 3) + (ω + 5) = 2ω + 5, the left card's 3 swallowed.
  local a3, a5 = omega("H_3", n(3, 1)), omega("S_5", n(5, 1))
  eaten, grown = WW.eating({ a3, a5 })
  check("(ω + 3) + (ω + 5) = 2ω + 5", eaten[a3] == a5 and Gm.encode(grown[a5]) == "2w+5", grown[a5] and Gm.encode(grown[a5]))
  -- ω + ω² = ω², and ω² + ω keeps both.
  local x, sq, y = omega("H_K"), omega("S_K", N.omega2), omega("D_K")
  eaten, grown = WW.eating({ x, sq, y })
  check("ω then ω² then ω: the first vanishes into ω², the last stays", eaten[x] == sq and eaten[sq] == nil
    and eaten[y] == nil and not grown[sq])
  -- ω² ω ω²: the ω vanishes, and then the two ω² are side by side and merge into 2ω².
  local p, m, q = omega("H_Q", N.omega2), omega("S_Q"), omega("D_Q", N.omega2)
  eaten, grown = WW.eating({ p, m, q })
  check("ω² ω ω² comes to 2ω²", eaten[p] == q and eaten[m] == q and Gm.encode(grown[q]) == "2w^2",
    grown[q] and Gm.encode(grown[q]))
  local dead, live = omega("H_J"), omega("S_J")
  dead.debuff = true
  eaten = WW.eating({ live, dead })
  check("a debuffed ω eats nothing", next(eaten) == nil)
  eaten = WW.eating({ dead, live })
  check("but can be eaten", eaten[dead] == live)
  dead.debuff = false

  local a, b, w4, c, d = card("H_7"), card("S_7"), omega("D_K"), card("C_9"), card("H_9")
  local function place(cards) for i, z in ipairs(cards) do z.T.x = i end end
  local hand = { a, b, w4, c, d }
  place(hand)
  expect("7 7 ω 9 9: the 7s are eaten, so a Pair of 9s", hand, "Pair")
  local food, growth = WW.feed(hand)
  check("feeding: the two 7s go", #food == 2)
  check("the eater grows by twice their chips", growth[w4] == 28 and w4.ability.perma_bonus == 28, growth[w4])
  check("an ω card always scores", SMODS.always_scores(w4) == true)
  -- 7 ω 7 ω: the second ω takes in the first, and with it what the first ate, all doubled again.
  local f1, o1, f2, o2 = card("H_7"), omega("S_K"), card("D_7"), omega("C_K")
  local row2 = { f1, o1, f2, o2 }
  place(row2)
  local grown2
  food, growth, grown2 = WW.feed(row2)
  check("7 ω 7 ω: three cards eaten", #food == 3, #food)
  check("the last ω grows by 2·7 + 2·(2·7)", growth[o2] == 42 and o2.ability.perma_bonus == 42, growth[o2])
  check("its value waits for the scoring", Gm.encode(WW.value_of(o2)) == "w")
  WW.grow(grown2)
  check("then it is worth 2ω", Gm.encode(WW.value_of(o2)) == "2w" and o2.base.value == "ww_w", Gm.encode(WW.value_of(o2)))
  -- An eaten card feeds what it would score alone, not its rank's chips.
  check("a 3½ feeds 3.5, ω + 14 a King's 10, 7±2 its 9", WW.lone_chips(card("H_3", n(3.5))) == 3.5
    and WW.lone_chips(card("S_K", n(14, 1))) == 10 and WW.lone_chips(card("D_7", cut(n(9), n(5)))) == 9)
  check("2ω draws itself", WW.look_text(o2) == "omega Clubs 2ω", WW.look_text(o2))
end

local function jokers()
  for _, k in ipairs({ "bouton", "generator", "grundy", "hotstrat", "thermograph", "sprouts", "cantor", "paradise",
    "conway", "birthday", "hilbert", "berlekamp", "guy" }) do
    check("j_ww_" .. k .. " exists", G.P_CENTERS["j_ww_" .. k] ~= nil)
  end
  check("The Heap and The Misère exist", G.P_BLINDS.bl_ww_heap ~= nil and G.P_BLINDS.bl_ww_misere ~= nil)
  check("the Field Deck and the Ordinal Deck exist", G.P_CENTERS.b_ww_field ~= nil and G.P_CENTERS.b_ww_ordinal ~= nil)

  -- Birthday counts the days a value was born after its whole number.
  local days = {
    { n(3), 0 }, { n(3.5), 2 }, { n(3.25), 3 }, { cut(n(5), n(5)), 1 }, { cut(n(9), n(5)), 3 }, { n(-0.5), 2 },
    { n(12), 0 },
  }
  for _, d in ipairs(days) do
    local got = WW.days_after(d[1])
    check(("Birthday: %s is %d days after its whole number"):format(Gm.encode(d[1]), d[2]), got == d[2], got)
  end
  check("Birthday: ω + 14, ω² and the wild were born on infinite days",
    WW.days_after(n(14, 1)) == nil and WW.days_after(N.omega2) == nil and WW.days_after(cut(N.omega, n(2))) == nil)

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
  -- An infinite ordinal is a heap of its own value; nim-addition goes digit by digit.
  local o3, o5 = card("H_3", n(3, 1)), card("S_5", n(5, 1))
  check("(ω + 3) ⊕ (ω + 5) = 6: the ωs cancel", WW.nim_sum({ o3, o5 }) == 6, tostring(WW.nim_sum({ o3, o5 })))
  local om, kk = card("D_w"), card("C_K")
  local sum = WW.nim_sum({ om, kk, card("H_K") })
  check("ω K K nim-sums to ω, not 0, so it gets past The Heap", N.is(sum) and N.encode(sum) == "w", tostring(sum))
  check("ω² ⊕ ω ⊕ 1 = ω² + ω + 1", N.encode(WW.nim_sum({ card("H_w", N.omega2), card("S_w"), card("D_1") })) == "w^2+w+1")
  check("Bouton: 1 2 3 with an ω never cancels", not WW.bouton({ one, two, three, om }, { three, om }))
  check("ω/2 is no ordinal, so no heap", WW.ordinal_heap(card("C_w", n(0, 1 / 2))) == nil)

  -- A * adds 1 to a heap (DESIGN.md § 3, Nimbus): 5* plays as a 5 but nim-sums as a 4.
  local star = cut(n(0), n(0))
  local s5 = card("D_5", Gm.add(n(5), star))
  check("5* is the heap 4", WW.heap(s5) == 4, WW.heap(s5))
  check("so a Pair with one 5* escapes The Heap", WW.nim_sum({ f1, s5 }) == 1, WW.nim_sum({ f1, s5 }))
  check("Bouton: 5* 4 and a 0 kicker", WW.bouton({ s5, four, z }, { s5, four }))
  check("a bare * reads *, not +0*", WW.pretty(star, true) == "*", WW.pretty(star, true))
  local hs = card("S_5", Gm.add(cut(n(6), n(4)), star))
  check("5±1* shows its star before the rank, and checkered pips",
    WW.halo(hs) and WW.look_text(hs) == "field Spades *5±1 4..6 checker", WW.look_text(hs))
  -- The * closes a hot card's range at both ends: 5±1* = {6*|4*} plays only as 5 (±1* − 1 = {*|−2*} ≤ 0).
  check("5±1* plays only as 5", table.concat(WW.ranks_of(hs), ",") == "5", table.concat(WW.ranks_of(hs), ","))
  -- K K 4 0 nim-sum to 4, so Bouton needs the 5±1* kicker to be the heap 5 ⊕ 1 = 4; as a plain 5 it would be 5.
  local sk, dk = card("S_K"), card("D_K")
  check("Bouton: a 5±1* kicker is the heap 4", WW.bouton({ hs, sk, dk, card("H_4"), card("C_0") }, { sk, dk }))

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
    -- Widening never takes a reading away (Codex's review).
    local halves = row({ "H_3", "S_4" })
    WW.add_mod(halves[1], n(1 / 2)); WW.add_mod(halves[2], n(-1 / 2))
    expect("Conway: two 3½s still pair as equal values", halves, "Pair")
    local threes = row({ "H_3", "S_3", "D_3" })
    WW.add_mod(threes[2], n(1 / 2))
    expect("Conway: 3 3½ 3 is Three of a Kind (the 3½ is {3|3} = 3*)", threes, "Three of a Kind")
    local nim_row = row({ "H_0", "S_2", "D_4", "C_3" })
    local results = evaluate_poker_hand(nim_row)
    check("Conway: 0 2 4 3 reads the 3 as {4|} = 5", WW.rank_now(nim_row[4]) == 5, WW.rank_now(nim_row[4]))
    check("Bouton with Conway: the 2 kicker can be {0|4} = 1, and 0 ⊕ 1 ⊕ 4 ⊕ 5 = 0",
      WW.bouton(nim_row, results["High Card"][1]))
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

-- With Quintessence (a9's suit mod) installed: its Wild suit is a fifth suit, so the born ranks need Wild fronts,
-- values have to work in its Spectrum hands, and Repaint leaves Wild alone (a green Hackenbush edge is its own
-- negative).
local function quintessence()
  if not (SMODS.Suits.quint_Wild and G.P_CARDS.quint_W_7) then
    check("Quintessence isn't loaded; its checks are skipped", true)
    return
  end
  for _, r in ipairs({ "0", "1", "C" }) do
    local front = G.P_CARDS["quint_W_ww_" .. r]
    check("the Wild " .. r .. " draws from our sheet's Wild row",
      front and front.lc_atlas == "ww_ranks" and front.hc_atlas == "ww_ranks_hc" and front.pos.y == 4,
      front and (tostring(front.lc_atlas) .. " y " .. tostring(front.pos.y)))
  end
  local hot = card("quint_W_7", Gm.add(n(7), cut(n(2), n(-2))))
  expect("a Wild 7±2 plays as the 7 of a Straight Spectrum", { card("S_5"), card("H_6"), hot, card("D_8"), card("C_9") },
    "spa_Straight_Spectrum")
  local born = card("quint_W_ww_0")
  expect("a Wild 0 joins 0 1 2 3 4 as a Straight Spectrum",
    { born, card("S_1"), card("H_2"), card("D_3"), card("C_4") }, "spa_Straight_Spectrum")
  WW.MOVES.repaint.apply({ hot })
  check("Repaint leaves a Wild card Wild", hot.base.suit == "quint_Wild", hot.base.suit)

  -- A Wild card is a green Hackenbush edge, worth *: a Wild 5 is 5*. The * is the suit's, not stored.
  local g5 = card("quint_W_5")
  check("a Wild 5 is worth 5*", WW.pretty(WW.value_of(g5)) == "5*", WW.pretty(WW.value_of(g5)))
  check("and plays as a 5", g5:get_id() == SMODS.Ranks["5"].id and g5.ability.ww_mod == nil)
  check("it shows its star", WW.look_text(g5) == "field quint_Wild *5 5..5 checker", WW.look_text(g5))
  check("a Pair with a Wild 5 nim-sums to 1, so it escapes The Heap", WW.nim_sum({ g5, card("H_5") }) == 1)
  WW.MOVES.nimbus.apply({ g5 })
  check("Nimbus on a Wild 5 makes a plain 5 (* + * = 0)",
    WW.pretty(WW.value_of(g5)) == "5" and not WW.halo(g5) and WW.look_of(g5) == nil,
    WW.pretty(WW.value_of(g5)) .. " " .. tostring(WW.halo(g5)) .. " " .. WW.look_text(g5))
  assert(SMODS.change_base(g5, "Hearts"))
  check("which is a 5* again off the Wild suit", WW.pretty(WW.value_of(g5)) == "5*", WW.pretty(WW.value_of(g5)))
  assert(SMODS.change_base(g5, "quint_Wild"))
  check("and a 5 back on it", WW.pretty(WW.value_of(g5)) == "5", WW.pretty(WW.value_of(g5)))
  local h5 = card("quint_W_5")
  WW.MOVES.heat.apply({ h5 })
  check("Heat on a Wild 5 heats its *: 5±1", WW.pretty(WW.value_of(h5)) == "5±1", WW.pretty(WW.value_of(h5)))
  local c6 = card("quint_W_6")
  WW.MOVES.cut.apply({ c6 })
  -- {6*|} is the simplest number not ≤ 6*, which is 6 itself ({*|} = 0: whoever moves first loses).
  check("Cut on a Wild 6 (6*) makes exactly {6*|} = 6, storing the * that cancels the suit's",
    WW.pretty(WW.value_of(c6)) == "6" and c6.ability.ww_mod == "{0|0}", WW.pretty(WW.value_of(c6)))
  local om = card("quint_W_K")
  WW.MOVES.omega.apply({ om })
  check("Omega on a Wild King makes exactly ω, storing the * that cancels the suit's",
    WW.pretty(WW.value_of(om)) == "ω" and om.ability.ww_mod == "{0|0}", WW.pretty(WW.value_of(om)))
  WW.MOVES.nimbus.apply({ om })
  check("a Wild ω with its * still eats", WW.halo(om) and WW.is_eater(om) and WW.look_text(om) == "omega quint_Wild *ω",
    WW.look_text(om))
  local flush = {}
  for i, r in ipairs({ "2", "3", "4", "5", "6" }) do flush[i] = card("quint_W_" .. r) end
  local r = WW.resolve(flush)
  check("a Wild Straight Flush scores its ranks, 20, the *s cancelling out", r and N.encode(r.total) == "20",
    r and N.encode(r.total))
  local born = 0
  for _, c in ipairs(flush) do born = born + (WW.days_after(WW.value_of(c)) or 0) end
  check("Birthday: each Wild card is a day younger than its rank", born == 5, born)
end

-- Every string a UI definition shows: text nodes, and the strings of the DynaTexts in names.
local function strings_of(node, out, seen)
  out, seen = out or {}, seen or {}
  if type(node) ~= "table" or seen[node] then return out end
  seen[node] = true
  local cfg = node.config
  if type(cfg) == "table" then
    if type(cfg.text) == "string" then out[#out + 1] = cfg.text end
    local o = cfg.object
    if type(o) == "table" and type(o.config) == "table" and type(o.config.string) == "table" then
      for _, s in ipairs(o.config.string) do out[#out + 1] = type(s) == "table" and tostring(s.string) or tostring(s) end
    end
  end
  for _, v in ipairs(node) do strings_of(v, out, seen) end
  for _, k in ipairs({ "nodes", "main", "info", "name", "main_end" }) do strings_of(node[k], out, seen) end
  return out
end

-- Every tooltip renders in full: no #1# left unfilled, no missing key, and each term of art brings its box.
local function tooltips()
  local want_info = {
    j_ww_bouton = 1, j_ww_generator = 1, j_ww_grundy = 1, j_ww_hotstrat = 1, j_ww_thermograph = 1,
    j_ww_sprouts = 2, j_ww_paradise = 1, j_ww_conway = 2, j_ww_berlekamp = 1, j_ww_cantor = 0, j_ww_birthday = 0,
    j_ww_hilbert = 1, j_ww_guy = 0, c_ww_cut = 1, c_ww_heat = 1, c_ww_cool = 1, c_ww_mex = 1, c_ww_omega = 2,
    v_ww_lessons = 0, v_ww_onag = 0,
    c_ww_sum = 0, c_ww_frobenius = 0, c_ww_repaint = 0, c_ww_nimbus = 1, c_ww_tweedledum = 0,
    p_ww_game_normal_1 = 0, p_ww_game_jumbo_1 = 0, p_ww_game_mega_1 = 0,
  }
  local params = { bypass_discovery_center = true, bypass_discovery_ui = true }
  for key, n_info in pairs(want_info) do
    local c = Card(0, 0, G.CARD_W, G.CARD_H, G.P_CARDS.empty, G.P_CENTERS[key], params)
    made[#made + 1] = c
    local ok, ui = pcall(c.generate_UIBox_ability_table, c)
    if not ok then
      check(key .. "'s tooltip renders", false, ui)
    else
      local text = table.concat(strings_of(ui), " / ")
      check(key .. "'s tooltip fills every #n#", not text:find("#%d+#"), text)
      check(key .. "'s tooltip has no missing text", not text:find("ERROR"), text)
      local names = {}
      for i, box in ipairs(ui.info or {}) do names[i] = tostring(box.name) end
      check(key .. " shows " .. n_info .. " info box(es)", #names == n_info, table.concat(names, ", "))
    end
  end
  -- Tweedledum names the last Move in The Fool's box: none yet, then Cut.
  local tw = Card(0, 0, G.CARD_W, G.CARD_H, G.P_CARDS.empty, G.P_CENTERS.c_ww_tweedledum, params)
  made[#made + 1] = tw
  G.GAME.ww_last_move = nil
  local none = table.concat(strings_of(tw:generate_UIBox_ability_table()), " ")
  G.GAME.ww_last_move = "c_ww_cut"
  local ui = tw:generate_UIBox_ability_table()
  local cut = table.concat(strings_of(ui), " ")
  G.GAME.ww_last_move = nil
  check("Tweedledum's box says None before any Move", none:find(localize("k_none"), 1, true) ~= nil, none)
  local names = {}
  for i, box in ipairs(ui.info or {}) do names[i] = tostring(box.name) end
  check("Tweedledum's box names the last Move", cut:find(" Cut ", 1, true) ~= nil, cut)
  check("Tweedledum shows the last Move's tooltip", #names >= 1, table.concat(names, ", "))
  -- Decks and Blinds have no loc_vars: their text only has to exist, and the Cut the Ordinal Deck names must too.
  for set, keys in pairs({ Back = { "b_ww_field", "b_ww_ordinal" }, Blind = { "bl_ww_heap", "bl_ww_misere" } }) do
    for _, key in ipairs(keys) do
      local d = G.localization.descriptions[set][key]
      check(key .. " has its text", d and d.text_parsed and #d.text_parsed > 0)
    end
  end
  check("{C:ww_move} names the Moves' bright green", loc_colour("ww_move") == G.C.SET.Move)
  local tag = G.localization.descriptions.Tag.tag_ww_game
  check("the Game Tag has its text", G.P_TAGS.tag_ww_game ~= nil and tag and tag.text_parsed and #tag.text_parsed > 0)
  local ok, tag_ui = pcall(function()
    local t = Tag("tag_ww_game")
    local _, sprite = t:generate_UI()
    local ui = t:get_uibox_table(sprite).ability_UIBox_table
    sprite:remove() -- Tag:remove wants the run's HUD; this tag was never in a run
    return ui
  end)
  local tag_text = ok and table.concat(strings_of(tag_ui), " / ") or tostring(tag_ui)
  check("the Game Tag's tooltip names the Mega Game Pack", ok and tag_text:find("Mega Game Pack", 1, true) ~= nil, tag_text)
  local w = card("S_w")
  local wtext = table.concat(strings_of(w:generate_UIBox_ability_table()), " / ")
  check("an ω's tooltip: what it's worth, that it eats, and what it pays",
    wtext:find("Worth", 1, true) and wtext:find("no rank", 1, true) and wtext:find("Eats", 1, true)
      and wtext:find("X2", 1, true), wtext)
  local sq = card("S_w", N.omega2)
  local sqtext = table.concat(strings_of(sq:generate_UIBox_ability_table()), " / ")
  check("ω²'s tooltip writes ω², and only what it's worth", sqtext:find("ω²", 1, true) ~= nil
    and not sqtext:find("Modifier", 1, true) and not sqtext:find("−ω", 1, true), sqtext)
  -- With Quintessence, a Wild card's tooltip says what its * is.
  if G.P_CARDS.quint_W_5 then
    local g = card("quint_W_5")
    local text = table.concat(strings_of(g:generate_UIBox_ability_table()), " / ")
    check("a Wild 5's tooltip: worth 5*, and why", text:find("5*", 1, true) and text:find("Wild cards carry", 1, true), text)
  end
end

local function shop()
  check("the vouchers exist, Lessons in Play first",
    G.P_CENTERS.v_ww_lessons ~= nil and G.P_CENTERS.v_ww_onag and G.P_CENTERS.v_ww_onag.requires[1] == "v_ww_lessons")
  check("Moves start at half the Tarots' shop rate", G.GAME.move_rate == 2, G.GAME.move_rate)
  local rate = WW.MOD_RATE
  WW.MOD_RATE = 2 -- every roll lands
  local seen = {}
  for i = 1, 30 do
    local c = card(({ "H_2", "S_7", "D_9", "C_K" })[i % 4 + 1])
    WW.roll_mod(c, "test")
    seen[c.ability.ww_mod or "none"] = true
  end
  local stone = card("H_5")
  stone:set_ability(G.P_CENTERS.m_stone, nil, true)
  WW.roll_mod(stone, "test")
  local half = card("H_3", n(3.5))
  WW.roll_mod(half, "test")
  WW.MOD_RATE = 0
  local none = card("H_4")
  WW.roll_mod(none, "test")
  WW.MOD_RATE = rate
  check("a rolled modifier is ½, * or ±1", seen["1/2"] and seen["{0|0}"] and seen["{1|-1}"] and not seen.none)
  check("a Stone card gets none", stone.ability.ww_mod == nil)
  check("nor a card that has one", half.ability.ww_mod == "1/2", half.ability.ww_mod)
  check("and a missed roll leaves the card plain", none.ability.ww_mod == nil)
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
  quintessence()
  tooltips()
  shop()
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
