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
