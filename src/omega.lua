-- Infinity eats (DESIGN.md § 2.4). Reading the played row left to right is ordinal addition, and the row adds up.
-- A card below a power of ω vanishes into it from the left (α + ω^β = ω^β whenever α < ω^β, so n + ω = ω and
-- ω + ω² = ω²), and a card of the same degree adds its leading term to it (ω + ω = ω·2, and (ω + 3) + (ω + 5) is
-- ω·2 + 5). So a card worth a positive infinite number (an eater: ω + 14, 2ω, ω²) eats the cards to its left back
-- to the nearest one of a higher degree, and grows by the leading terms of those of its own degree. The row's sum
-- never changes; only the count of cards does. Eaten cards don't count toward the hand and are destroyed after it;
-- twice the chips each would score alone become the eater's permanent bonus chips, the way Hiker's are, so it grows
-- like Ceremonial Dagger (which also takes double). An ω card always scores, like a Stone card.

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

-- The number a card is worth with its * set aside (ω + * reads ω); nil when it isn't a number.
local function number_of(card)
  local v = WW.value_of(card)
  if v ~= nil and not N.is(v) and WW.halo(card) then v = Gm.add(v, STAR) end
  return v ~= nil and N.is(v) and v or nil
end

--- The degree of the positive infinite number a card is worth, its * aside (1 for ω + 14, 2 for ω²); nil for a
--- finite card, a game such as the wild, or a negative infinity.
function WW.omega_degree(card)
  local v = number_of(card)
  if v and N.infinite_sign(v) > 0 then return N.degree(v) end
  return nil
end
local degree_of = WW.omega_degree

--- Does this card eat: a positive infinite number, not debuffed? A * doesn't stop it: ω + * still eats.
function WW.is_eater(card)
  return not card.debuff and degree_of(card) ~= nil
end

--- Who eats whom in a row of cards, left to right: {eaten card = its eater}, and the value each eater grows to
--- when it took in cards of its own degree: {eater = value}. Finite cards and positive infinite numbers can be
--- eaten; any other infinite value (the wild) is a wall nothing to its left gets past.
function WW.eating(row)
  local eaten, grown, stack = {}, {}, {}
  for _, c in ipairs(row) do
    local d = degree_of(c)
    if d then
      local num = number_of(c)
      if not c.debuff then
        local v, gain = WW.value_of(c), nil
        while #stack > 0 and stack[#stack].d <= d do
          local p = table.remove(stack)
          eaten[p.card] = c
          if p.d == d then gain = gain and N.add(gain, N.lead(p.num)) or N.lead(p.num) end
        end
        if gain then
          grown[c] = Gm.add(v, gain)
          num = N.add(num, gain)
        end
      end
      stack[#stack + 1] = { card = c, d = d, num = num }
    elseif WW.is_infinite(c) then
      stack = {}
    else
      stack[#stack + 1] = { card = c, d = 0 }
    end
  end
  return eaten, grown
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

--- Feed the eaters in a played row: each one's bonus chips grow by WW.EAT times the chips each card it eats would
--- score alone (what an eaten eater had grown by comes along). Returns the eaten cards, per eater how much it grew,
--- and the values the eaters that took in their own degree grow to; WW.grow gives them those.
function WW.feed(row)
  local eaten, grown = WW.eating(row)
  local food, growth = {}, {}
  for _, c in ipairs(row) do
    local eater = eaten[c]
    if eater then
      food[#food + 1] = c
      growth[eater] = (growth[eater] or 0) + WW.EAT * (WW.lone_chips(c) + (growth[c] or 0))
    end
  end
  for eater, chips in pairs(growth) do
    eater.ability.perma_bonus = (eater.ability.perma_bonus or 0) + chips
  end
  for eater in pairs(growth) do
    if eaten[eater] then growth[eater] = nil end
  end
  for eater in pairs(grown) do
    if eaten[eater] then grown[eater] = nil end
  end
  return food, growth, grown
end

--- Give the eaters that took in their own degree their new values (2ω, 2ω²).
function WW.grow(grown)
  for eater, v in pairs(grown or {}) do WW.set_value(eater, v) end
end

local meal -- the cards eaten in the hand being played, destroyed once it has scored
-- The values the hand's eaters grow to. They take them once the hand has been read and the Blind has judged it, as
-- the cards start to score: so the hand and the Blind read the same row in the preview and in play, and the cards
-- score their new values.
local growing

local intro = evaluate_play_intro
function evaluate_play_intro(...)
  local food, growth, grown = WW.feed(in_row(G.play.cards))
  meal = #food > 0 and food or nil
  growing = next(grown) and grown or nil
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
  -- An eater that took in its own kind says what it has become (2ω), in mult's red: that's the tier it pays in.
  for eater, v in pairs(grown) do
    card_eval_status_text(eater, "extra", nil, nil, nil, { message = WW.pretty(v), colour = G.C.MULT })
  end
  return intro(...)
end

local main = evaluate_play_main
function evaluate_play_main(...)
  WW.grow(growing)
  growing = nil
  return main(...)
end

local after = evaluate_play_after
function evaluate_play_after(...)
  -- A hand the Blind debuffed never reached the scoring, but the row still added up.
  WW.grow(growing)
  growing = nil
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
