-- Run test. `WINNINGWAYS_RUNTEST=<file> balala` starts a real run on the Field Deck (saving switched off), picks the
-- Small Blind and plays scripted hands through the game's own code: a hot card's bite, infinity eating, a Move used
-- for real, each joker in turn, and The Heap. The blind's target is raised out of reach so the round never ends.
-- It writes PASS/FAIL lines to <file> and quits. scripts/runtest also backs up and restores the save files.
local out_path = os.getenv("WINNINGWAYS_RUNTEST")
local WW = WinningWays
local E = WW.engine
local N, Gm = E.num, E.game
local n = N.new
local lines, failed = {}, 0

local function check(name, ok, detail)
  if not ok then failed = failed + 1 end
  lines[#lines + 1] = (ok and "PASS " or "FAIL ") .. name .. (detail ~= nil and (" (" .. tostring(detail) .. ")") or "")
end
local function num(x) return type(x) == "number" and x or (to_number and to_number(x)) or tonumber(tostring(x)) end
local function score() return num(G.GAME.chips) end

-- Turn hand card i into rank `rank` of `suit` with an optional modifier.
local function make(i, suit, rank, mod)
  local c = G.hand.cards[i]
  WW.set_mod(c, N.zero)
  c.ability.perma_bonus = 0
  assert(SMODS.change_base(c, suit, rank))
  if mod then WW.add_mod(c, mod) end
  return c
end
local function play(cards)
  G.hand:unhighlight_all()
  for _, c in ipairs(cards) do G.hand:add_to_highlighted(c, true) end
  G.FUNCS.play_cards_from_highlighted()
end
local function alive(card)
  for _, c in ipairs(G.playing_cards) do if c == card then return true end end
  return false
end

local steps, step, frames, before = {}, 1, 0, 0
local ate, eater, cut, left, right

-- The jokers in play: hold({"bouton"}) sells nothing, it just swaps the test's jokers.
local held = {}
local function hold(keys)
  for _, j in ipairs(held) do j:remove() end
  held = {}
  for _, k in ipairs(keys) do held[#held + 1] = SMODS.add_card({ key = "j_ww_" .. k }) end
  return held[1]
end
local function gained() return score() - before end
local function nominal(key) return SMODS.Ranks[key].nominal end
local function count_born()
  local born = 0
  for _, c in ipairs(G.playing_cards) do
    if c.base.value == "ww_0" or c.base.value == "ww_1" or c.base.value == "ww_C" then born = born + 1 end
  end
  return born
end

steps[1] = { wait = function() return G.STATE == G.STATES.MENU and G.MAIN_MENU_UI end, run = function()
  G.F_NO_SAVING = true
  G.GAME.viewed_back = Back(G.P_CENTERS.b_ww_field)
  G.FUNCS.start_run(nil, { stake = 1, seed = "WWRUNTEST" })
end }
steps[2] = { wait = function() return G.STATE == G.STATES.BLIND_SELECT and G.blind_select end, run = function()
  -- The button's UI box only matters for a skip tag; a stub with no tag container will do.
  G.FUNCS.select_blind({
    config = { ref_table = G.P_BLINDS[G.GAME.round_resets.blind_choices.Small] },
    UIBox = { get_UIE_by_ID = function() return nil end },
  })
end }
steps[3] = { wait = function() return G.STATE == G.STATES.SELECTING_HAND and #G.hand.cards >= 5 end, run = function()
  check("the run is on the Field Deck", G.GAME.selected_back and G.GAME.selected_back.effect.center.key == "b_ww_field",
    G.GAME.selected_back and G.GAME.selected_back.effect.center.key)
  check("which has 64 cards", #G.playing_cards == 64 and G.GAME.starting_deck_size == 64, #G.playing_cards)
  check("12 of them born ranks: 0, 1 and C in every suit", count_born() == 12, count_born())
  G.GAME.blind.chips = 1e12
  G.GAME.current_round.hands_left = 30
  -- 7 7 and a 7 with ±2: Three of a Kind. You move first and take the hot card's 9, so the cards score 7 + 7 + 9.
  before = score()
  play({ make(1, "Hearts", "7"), make(2, "Spades", "7"), make(3, "Diamonds", "7", Gm.of({ n(2) }, { n(-2) })) })
end }
steps[4] = { wait = function() return G.STATE == G.STATES.SELECTING_HAND end, run = function()
  check("the hot hand was Three of a Kind", G.GAME.last_hand_played == "Three of a Kind", G.GAME.last_hand_played)
  check("it scored (30 + 7 + 7 + 9) × 3 = 159", score() - before == 159, score() - before)
  -- 7 7 ω+14 9 9: the ω eats both 7s and grows by twice their 14; a Pair of 9s, and the ω always scores (its +14
  -- scores a King's 10).
  before = score()
  local a, b = make(1, "Hearts", "7"), make(2, "Clubs", "7")
  eater = make(3, "Spades", "ww_w", n(14))
  ate = { a, b }
  play({ a, b, eater, make(4, "Diamonds", "9"), make(5, "Spades", "9") })
end }
steps[5] = { wait = function() return G.STATE == G.STATES.SELECTING_HAND end, run = function()
  check("with the 7s eaten, the hand was a Pair", G.GAME.last_hand_played == "Pair", G.GAME.last_hand_played)
  check("it scored (10 + 9 + 9 + 10 + 28) × 2 = 132", score() - before == 132, score() - before)
  check("the eaten 7s are gone", not alive(ate[1]) and not alive(ate[2]))
  check("the ω kept 28 bonus chips", eater.ability.perma_bonus == 28, eater.ability.perma_bonus)
  -- A Move, used through the game's own button: Cut on a 3 and a 7 makes a 4.
  left, right = make(1, "Hearts", "3"), make(2, "Spades", "7")
  cut = SMODS.add_card({ key = "c_ww_cut", area = G.consumeables })
  G.hand:unhighlight_all()
  G.hand:add_to_highlighted(left, true)
  G.hand:add_to_highlighted(right, true)
  check("Cut can be used on two cards", cut.config.center:can_use(cut))
  G.FUNCS.use_card({ config = { ref_table = cut, button = "use_card" } })
end }
steps[6] = { frames = 240, run = function()
  check("Cut 3, 7 made a 4", WW.value_of(left) and Gm.encode(WW.value_of(left)) == "4", WW.value_of(left) and Gm.encode(WW.value_of(left)))
  check("and used up the 7", not alive(right))
  check("the Cut card is spent", cut.removed or not cut.area or cut.area ~= G.consumeables)
end }

-- The jokers, one at a time. High Card is 5 chips × 1 mult, a Straight 30 × 4, a Pair 10 × 2, Three of a Kind 30 × 3.
local subject, extra -- what the next step looks at
local function after_hand(f) steps[#steps + 1] = { wait = function() return G.STATE == G.STATES.SELECTING_HAND end, run = f } end

after_hand(function()
  -- Bouton: 1 2 3 nim-sum to 0. High Card of the 3: (5 + 3) × 1, then × 3.
  hold({ "bouton" })
  before = score()
  play({ make(1, "Hearts", "ww_1"), make(2, "Spades", "2"), make(3, "Diamonds", "3") })
end)
after_hand(function()
  check("Bouton: 1 2 3 scored (5 + 3) × 1 × 3 = 24", gained() == 24, gained())
  -- Generator: a lone Ace pays its place on the cycle (1st) at 2 chips a place, then steps to a 9.
  hold({ "generator" })
  before = score()
  subject = make(1, "Spades", "Ace")
  play({ subject })
end)
after_hand(function()
  check("Generator: the Ace scored 5 + 11 + 2 = 18", gained() == 18, gained())
  check("and stepped to a 9", subject.base.value == "9", subject.base.value)
  -- Grundy: 0 1 2 3 4 is a Straight whose mex is 5.
  subject = hold({ "grundy" })
  before = score()
  play({ make(1, "Hearts", "ww_0"), make(2, "Spades", "ww_1"), make(3, "Diamonds", "2"), make(4, "Clubs", "3"),
    make(5, "Hearts", "4") })
end)
after_hand(function()
  local chips = 30 + nominal("ww_0") + nominal("ww_1") + 2 + 3 + 4
  check("Grundy gained the mex, 5", subject.ability.extra.mult == 5, subject.ability.extra.mult)
  check(("and the Straight scored %d × (4 + 5)"):format(chips), gained() == chips * 9, gained())
  -- Hotstrat: a lone 7±2 takes its 9 and is retriggered: 5 + 9 + 9.
  hold({ "hotstrat" })
  before = score()
  play({ make(1, "Hearts", "7", Gm.of({ n(2) }, { n(-2) })) })
end)
after_hand(function()
  check("Hotstrat: 7±2 scored twice, 5 + 9 + 9 = 23", gained() == 23, gained())
  -- Thermograph: a lone 7±2 scores its mean, 7, and 3 Mult per degree of its temperature, 2: (5 + 7) × (1 + 6).
  hold({ "thermograph" })
  before = score()
  play({ make(1, "Hearts", "7", Gm.of({ n(2) }, { n(-2) })) })
end)
after_hand(function()
  check("Thermograph: 7±2 scored (5 + 7) × (1 + 6) = 84", gained() == 84, gained())
  -- Sprouts: a first hand of exactly 3 and 7 adds their Cut, a 4. (The test makes this the round's first hand.)
  hold({ "sprouts" })
  before = score()
  extra = {}
  for _, c in ipairs(G.playing_cards) do extra[c] = true end
  G.GAME.current_round.hands_played = 0
  play({ make(1, "Hearts", "3"), make(2, "Spades", "7") })
end)
after_hand(function()
  local new = {}
  for _, c in ipairs(G.playing_cards) do if not extra[c] then new[#new + 1] = c end end
  local v = new[1] and WW.value_of(new[1])
  check("Sprouts added one card", #new == 1, #new)
  check("worth {3|7} = 4", v and Gm.encode(v) == "4", v and Gm.encode(v))
  check("and the hand scored High Card 5 + 7 = 12", gained() == 12, gained())
  -- Cantor: selecting a Blind adds a card whose rank and suit pair was missing.
  hold({ "cantor" })
  extra = {}
  for _, p in ipairs(WW.missing_pairs()) do extra[p.suit .. "|" .. p.rank] = true end
  subject = #G.playing_cards
  SMODS.calculate_context({ setting_blind = true, blind = G.GAME.blind })
end)
steps[#steps + 1] = { frames = 120, run = function()
  local c = G.playing_cards[#G.playing_cards]
  check("Cantor added a card", #G.playing_cards == subject + 1, #G.playing_cards - subject)
  check("whose pair was missing", c and extra[c.base.suit .. "|" .. c.base.value], c and (c.base.suit .. " " .. c.base.value))
end }
after_hand(function()
  -- Cantor's Paradise: 7 7 ω+14 9 9; the ω eats both 7s, so the Paradise gains ×0.2.
  subject = hold({ "paradise" })
  before = score()
  play({ make(1, "Hearts", "7"), make(2, "Clubs", "7"), make(3, "Spades", "ww_w", n(14)), make(4, "Diamonds", "9"),
    make(5, "Spades", "9") })
end)
after_hand(function()
  check("Cantor's Paradise gained ×0.1 per eaten card: ×1.2", subject.ability.extra.xmult == 1.2, subject.ability.extra.xmult)
  check("the Pair scored ⌊(10 + 9 + 9 + 10 + 28) × 2 × 1.2⌋ = 158", gained() == 158, gained())
  -- Conway: K 5 K, where the 5 can play as {K|K} = K*, is Three of a Kind; the 5 still scores 5.
  hold({ "conway" })
  before = score()
  play({ make(1, "Hearts", "King"), make(2, "Spades", "5"), make(3, "Diamonds", "King") })
end)
after_hand(function()
  check("Conway: K 5 K was Three of a Kind", G.GAME.last_hand_played == "Three of a Kind", G.GAME.last_hand_played)
  check("scoring (30 + 10 + 5 + 10) × 3 = 165", gained() == 165, gained())
  -- The Heap: a Pair nim-sums to 0, so it scores nothing.
  hold({})
  G.GAME.blind:set_blind(G.P_BLINDS.bl_ww_heap)
  G.GAME.blind.chips = 1e12
  before = score()
  play({ make(1, "Hearts", "9"), make(2, "Spades", "9") })
end)
after_hand(function()
  check("The Heap is the blind", G.GAME.blind.config.blind.key == "bl_ww_heap", G.GAME.blind.config.blind.key)
  check("under The Heap a Pair scores nothing", gained() == 0, gained())
  -- Three 9s nim-sum to 9: (30 + 27) × 3.
  before = score()
  play({ make(1, "Hearts", "9"), make(2, "Spades", "9"), make(3, "Clubs", "9") })
end)
after_hand(function()
  check("but Three of a Kind (9 ⊕ 9 ⊕ 9 = 9) scores 171", gained() == 171, gained())
  -- Birthday: two 3½s (a 3 with +½, a 4 with −½) pair; each was born two days after 3 (3½ is ++++−, day 5),
  -- so +6 Mult each.
  G.GAME.blind:set_blind(G.P_BLINDS.bl_small)
  G.GAME.blind.chips = 1e12
  hold({ "birthday" })
  before = score()
  play({ make(1, "Hearts", "3", n(1 / 2)), make(2, "Spades", "4", n(-1 / 2)) })
end)
after_hand(function()
  check("Birthday: the 3½s scored (10 + 3.5 + 3.5) × (2 + 6 + 6) = 238", gained() == 238, gained())
  -- Hilbert's Hotel: two more Joker slots (its own and one more), one less hand size. Steamodded recounts the
  -- slots on the next frame.
  extra = { G.jokers.config.card_limit, G.hand.config.card_limit }
  hold({ "hilbert" })
end)
steps[#steps + 1] = { frames = 30, run = function()
  check("Hilbert's Hotel: +2 Joker slots while held", G.jokers.config.card_limit == extra[1] + 2, G.jokers.config.card_limit - extra[1])
  check("and -1 hand size", G.hand.config.card_limit == extra[2] - 1, G.hand.config.card_limit - extra[2])
  hold({})
end }
steps[#steps + 1] = { frames = 30, run = function()
  check("selling it gives both back", G.jokers.config.card_limit == extra[1] and G.hand.config.card_limit == extra[2],
    G.jokers.config.card_limit .. " " .. G.hand.config.card_limit)
end }
after_hand(function()
  -- Berlekamp: a lone 7±2 takes its 9 and gives ×1.5.
  hold({ "berlekamp" })
  before = score()
  play({ make(1, "Hearts", "7", Gm.of({ n(2) }, { n(-2) })) })
end)
after_hand(function()
  check("Berlekamp: 7±2 scored (5 + 9) × 1.5 = 21", gained() == 21, gained())
  -- Guy: a Pair of 3s, each ×1.5.
  hold({ "guy" })
  before = score()
  play({ make(1, "Hearts", "3"), make(2, "Spades", "3") })
end)
after_hand(function()
  check("Guy: 3 3 scored (10 + 3 + 3) × 2 × 1.5 × 1.5 = 72", gained() == 72, gained())
  hold({})
end)

-- WINNINGWAYS_RUNTEST_SHOT=<prefix> saves two screenshots of the run as it stands (The Heap's chip, the Field Deck's
-- back, the jokers in their slots): <prefix>-1.png with the first five jokers, <prefix>-2.png with the rest.
local shot = os.getenv("WINNINGWAYS_RUNTEST_SHOT")
if shot then
  local function capture(i)
    love.graphics.captureScreenshot(function(image)
      local f = io.open(("%s-%d.png"):format(shot, i), "wb")
      if f then f:write(image:encode("png"):getString()); f:close() end
    end)
  end
  steps[#steps + 1] = { frames = 30, run = function()
    hold({ "bouton", "generator", "grundy", "hotstrat", "thermograph" })
  end }
  steps[#steps + 1] = { frames = 120, run = function() capture(1) end }
  steps[#steps + 1] = { frames = 30, run = function()
    hold({ "sprouts", "cantor", "paradise", "conway" })
  end }
  steps[#steps + 1] = { frames = 120, run = function() capture(2) end }
  steps[#steps + 1] = { frames = 30, run = function() end }
end

-- The Misère: your last hand scores nothing. The preview says so while one hand is left; a played hand is the last
-- when none are left. Playing it ends the run.
after_hand(function()
  hold({})
  G.GAME.blind:set_blind(G.P_BLINDS.bl_ww_misere)
  G.GAME.blind.chips = 1e12
  local pair = { G.hand.cards[1], G.hand.cards[2] }
  local function previews(left)
    G.GAME.current_round.hands_left = left
    local text, _, poker_hands = G.FUNCS.get_poker_hand_info(pair)
    return G.GAME.blind:debuff_hand(pair, poker_hands, text, true)
  end
  check("The Misère: with 2 hands left, the preview is clear", not previews(2))
  check("with 1 left, the preview says it scores nothing", previews(1) == true)
  G.GAME.current_round.hands_left = 3
  before = score()
  play({ make(1, "Hearts", "9"), make(2, "Spades", "9"), make(3, "Clubs", "9") })
end)
after_hand(function()
  check("a hand that isn't the last scores (171)", gained() == 171, gained())
  G.GAME.current_round.hands_left = 1
  before = score()
  play({ make(1, "Hearts", "9"), make(2, "Spades", "9"), make(3, "Clubs", "9") })
end)
steps[#steps + 1] = { wait = function() return G.STATE == G.STATES.GAME_OVER end, run = function()
  check("the last hand scored nothing, and the run is lost", gained() == 0, gained())
  -- The Ordinal Deck, in a second run.
  G.GAME.viewed_back = Back(G.P_CENTERS.b_ww_ordinal)
  G.FUNCS.start_run(nil, { stake = 1, seed = "WWORDINAL" })
end }
steps[#steps + 1] = { wait = function() return G.STATE == G.STATES.BLIND_SELECT and G.blind_select end, run = function()
  local omegas = 0
  for _, c in ipairs(G.playing_cards) do
    local v = WW.value_of(c)
    if v and Gm.encode(v) == "w" and c.base.value == "ww_w" and c.base.suit == "Spades" then omegas = omegas + 1 end
  end
  check("the Ordinal Deck has 53 cards", #G.playing_cards == 53, #G.playing_cards)
  check("one of them the ω of Spades", omegas == 1, omegas)
  local cut_held = G.consumeables.cards[1] and G.consumeables.cards[1].config.center.key
  check("and starts with a Cut", cut_held == "c_ww_cut", cut_held)
end }

local update = Game.update
local done = false
local since = love.timer.getTime()
function Game:update(dt)
  update(self, dt)
  if done then return end
  frames = frames + 1
  local s = steps[step]
  local waited = love.timer.getTime() - since
  -- Each step waits for its state, then a moment more (1.5 s) for the game's events to settle.
  local ready = s and (s.wait and s.wait() and frames > 90 and waited > 1.5 or (s.frames and frames > s.frames))
  if s and ready then
    local ok, err = pcall(s.run)
    if not ok then check("step " .. step .. " ran", false, err); step = #steps + 1 else step = step + 1 end
    frames, since = 0, love.timer.getTime()
  elseif s and waited > (step == 1 and 120 or 60) then
    check("step " .. step .. " started in time", false, "state " .. tostring(G.STATE))
    step = #steps + 1
  end
  if step > #steps then
    done = true
    lines[#lines + 1] = ("%d checks, %d failed"):format(#lines, failed)
    local f = io.open(out_path, "w")
    if f then f:write(table.concat(lines, "\n"), "\n"); f:close() end
    print("WINNINGWAYS RUNTEST\n" .. table.concat(lines, "\n"))
    love.event.quit()
  end
end
