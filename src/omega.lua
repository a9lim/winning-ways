-- Infinity eats (DESIGN.md § 2.4). Reading the played row left to right is ordinal addition, where n + ω = ω: each
-- card worth a positive infinite number (ω + 14, 2ω, ω/2) eats the finite cards between it and the nearest infinite
-- card to its left. Eaten cards don't count toward the hand and are destroyed after it; twice their chips become
-- the eater's permanent bonus chips, the way Hiker's are, so it grows like Ceremonial Dagger (which also takes
-- double). Infinities don't eat each
-- other (ω + ω = ω·2), and an ω card always scores, like a Stone card.

local WW = WinningWays
local E = WW.engine
local N, Gm = E.num, E.game

--- Is this card's value infinite: an infinite number, or a game with an infinite stop (the wild)?
function WW.is_infinite(card)
  local v = WW.value_of(card)
  if not v then return false end
  if N.is(v) then return not N.is_finite(v) end
  return not (N.is_finite(Gm.left_stop(v)) and N.is_finite(Gm.right_stop(v)))
end

local STAR = Gm.of({ N.zero }, { N.zero })

--- Does this card eat: a positive infinite number, not debuffed? A * doesn't stop it: ω + * still eats.
function WW.is_eater(card)
  if card.debuff then return false end
  local v = WW.value_of(card)
  if v ~= nil and not N.is(v) and WW.halo(card) then v = Gm.add(v, STAR) end
  return v ~= nil and N.is(v) and v.k > 0
end

--- Who eats whom in a row of cards, left to right: {eaten card = its eater}. Any infinite card stops the run of
--- finite cards before it; only an eater eats that run.
function WW.eating(row)
  local eaten, run = {}, {}
  for _, c in ipairs(row) do
    if WW.is_infinite(c) then
      if WW.is_eater(c) then
        for _, f in ipairs(run) do eaten[f] = c end
      end
      run = {}
    else
      run[#run + 1] = c
    end
  end
  return eaten
end

local function in_row(cards)
  local row = {}
  for i, c in ipairs(cards) do row[i] = c end
  table.sort(row, function(a, b) return a.T.x < b.T.x end)
  return row
end

local eaten_now = setmetatable({}, { __mode = "k" }) -- cards eaten in the hand being read

-- The hand being read loses the cards infinity eats.
local evaluate = evaluate_poker_hand
function evaluate_poker_hand(hand)
  local main = (G.play and hand == G.play.cards) or (G.hand and hand == G.hand.highlighted)
  local eaten = WW.eating(in_row(hand))
  if main then
    for c in pairs(eaten_now) do eaten_now[c] = nil end
    for c in pairs(eaten) do eaten_now[c] = true end
  end
  if not next(eaten) then return evaluate(hand) end
  local kept = {}
  for _, c in ipairs(hand) do
    if not eaten[c] then kept[#kept + 1] = c end
  end
  WW.reading_main = main
  local results = evaluate(kept)
  WW.reading_main = nil
  return results
end

function WW.is_eaten(card) return eaten_now[card] == true end

local always_scores, never_scores = SMODS.always_scores, SMODS.never_scores
function SMODS.always_scores(card)
  if WW.is_eater(card) then return true end
  return always_scores(card)
end
function SMODS.never_scores(card)
  if eaten_now[card] then return true end
  return never_scores(card)
end

--- How much an eater grows per chip it eats (a balance number, not maths).
WW.EAT = 2

--- Feed the eaters in a played row: each one's bonus chips grow by WW.EAT times the chips of the cards it eats.
--- Returns the eaten cards and, per eater, how much it grew.
function WW.feed(row)
  local eaten = WW.eating(row)
  local food, growth = {}, {}
  for _, c in ipairs(row) do
    local eater = eaten[c]
    if eater then
      food[#food + 1] = c
      growth[eater] = (growth[eater] or 0) + WW.EAT * c:get_chip_bonus()
    end
  end
  for eater, chips in pairs(growth) do
    eater.ability.perma_bonus = (eater.ability.perma_bonus or 0) + chips
  end
  return food, growth
end

local meal -- the cards eaten in the hand being played, destroyed once it has scored

local intro = evaluate_play_intro
function evaluate_play_intro(...)
  local food, growth = WW.feed(in_row(G.play.cards))
  meal = #food > 0 and food or nil
  -- Jokers hear about it (Cantor's Paradise): context.ww_eaten is the list of cards eaten this hand.
  if meal then SMODS.calculate_context({ ww_eaten = food }) end
  for eater, chips in pairs(growth) do
    G.E_MANAGER:add_event(Event({ trigger = "after", delay = 0.2, func = function()
      eater:juice_up(0.7, 0.5)
      play_sound("crumple1", 0.8)
      return true
    end }))
    card_eval_status_text(eater, "extra", nil, nil, nil,
      { message = localize({ type = "variable", key = "a_chips", vars = { chips } }), colour = G.C.CHIPS })
  end
  return intro(...)
end

local after = evaluate_play_after
function evaluate_play_after(...)
  local r = { after(...) }
  if meal then
    local food = meal
    meal = nil
    G.E_MANAGER:add_event(Event({ trigger = "after", delay = 0.3, func = function()
      SMODS.destroy_cards(food)
      return true
    end }))
  end
  return unpack(r)
end
