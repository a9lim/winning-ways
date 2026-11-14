-- Values on playing cards, and how hands of them are read and scored (DESIGN.md § 2).
--
-- A card's value lives in card.ability.ww_value as its canonical notation; cards without one are worth
-- their rank as an integer. A valued card also has a host rank, its nearest rank, which is what it reports
-- whenever no hand is assigning it one. Changing a card's rank by other means (Strength, say) clears its
-- value, so vanilla rank effects turn it back into a plain card. Copies (Death, Cryptid) keep the value,
-- because copy_card copies the ability table.
--
-- Reading a hand: evaluate_poker_hand tries the rank assignments that src/engine/hands.lua proposes, runs the
-- game's own evaluator on each, and keeps the best by the hand list's order. While a hand is assigned, a
-- flexible card's get_id, get_nominal and is_face report the rank it plays as.
--
-- Scoring: when the played cards score, src/engine/play.lua plays out their values as one game, and each card
-- scores the number it ends on, in chips: a rank's own chips for 0–Knight (so J, Q and K still score 10),
-- otherwise the number's finite part (3½ scores 3.5).

local WW = WinningWays
local E = WW.engine
local N, Gm, P, H = E.num, E.game, E.play, E.hands

local KEYS = {
  [0] = "ww_0", [1] = "ww_1", [2] = "2", [3] = "3", [4] = "4", [5] = "5", [6] = "6", [7] = "7", [8] = "8",
  [9] = "9", [10] = "10", [11] = "Jack", [12] = "Queen", [13] = "King", [14] = "Ace", [15] = "ww_Knight",
}
local INTS = {}
for r, k in pairs(KEYS) do INTS[k] = r end
function WW.rank_key(r) return KEYS[r] end
function WW.rank_int(key) return INTS[key] end

-- values ------------------------------------------------------------------------------------------------

local parsed, rank_sets = {}, {}
local function parse(s)
  local v = parsed[s]
  if not v then v = Gm.parse(s); parsed[s] = v end
  return v
end
local function ranks_of_value(v)
  local k = Gm.encode(v)
  local r = rank_sets[k]
  if not r then r = P.ranks(v); rank_sets[k] = r end
  return r
end

local base_has_no_rank = SMODS.has_no_rank

function WW.has_value(card) return card.ability ~= nil and card.ability.ww_value ~= nil end

--- A card's value: the one it stores, or its rank as an integer. nil for a card with no rank (Stone) and for
--- other mods' ranks.
function WW.value_of(card)
  if WW.has_value(card) then return parse(card.ability.ww_value) end
  if base_has_no_rank(card) then return nil end
  local r = INTS[card.base.value]
  return r and N.new(r) or nil
end

--- The ranks a card can play as, as integers; nil when the card isn't one of ours.
function WW.ranks_of(card)
  if WW.has_value(card) then return ranks_of_value(parse(card.ability.ww_value)) end
  local v = WW.value_of(card)
  return v and { v.x } or nil
end

-- The rank nearest a value's mean among the ranks it plays as (any rank 0–15 when it plays as none). An
-- infinite mean picks the top.
local function host_rank(v)
  local mean = Gm.mean(v)
  local target = N.is_finite(mean) and N.finite(mean) or (mean.k > 0 and 1e9 or -1e9)
  local ranks = ranks_of_value(v)
  if #ranks == 0 then return math.max(0, math.min(15, math.floor(target + 0.5))) end
  local best = ranks[1]
  for _, r in ipairs(ranks) do
    if math.abs(r - target) < math.abs(best - target) then best = r end
  end
  return best
end
WW.host_rank = host_rank

local setting = false

--- Give a card a value (a canonical number or game). An integer from 0 to 15 makes it that plain rank.
function WW.set_value(card, v)
  if N.is(v) and N.is_integer(v) and v.x >= 0 and v.x <= 15 then
    assert(SMODS.change_base(card, nil, KEYS[v.x]))
    return card
  end
  setting = true
  local ok, changed = pcall(SMODS.change_base, card, nil, KEYS[host_rank(v)])
  setting = false
  assert(ok and changed, changed)
  card.ability.ww_value = Gm.encode(v)
  return card
end

-- which rank a card plays as ----------------------------------------------------------------------------

local active = setmetatable({}, { __mode = "k" }) -- flexible card -> rank key it plays as
local ties = setmetatable({}, { __mode = "k" })   -- rankless card -> tie token, while it pairs with an equal one

local set_base = Card.set_base
function Card:set_base(card, initial, manual_sprites)
  if not setting and self.ability then self.ability.ww_value = nil end
  active[self], ties[self] = nil, nil
  return set_base(self, card, initial, manual_sprites)
end

function SMODS.has_no_rank(card)
  if WW.has_value(card) and #ranks_of_value(parse(card.ability.ww_value)) == 0 then return true end
  return base_has_no_rank(card)
end

local get_id = Card.get_id
function Card:get_id()
  local key = active[self]
  if key then return SMODS.Ranks[key].id end
  return get_id(self)
end

-- Run f with the card's base dressed as the rank it plays as.
local function as_assigned(card, f, ...)
  local key = active[card]
  if not key or key == card.base.value then return f(card, ...) end
  local b, rank = card.base, SMODS.Ranks[key]
  local value, nominal, face_nominal = b.value, b.nominal, b.face_nominal
  b.value, b.nominal, b.face_nominal = key, rank.nominal, rank.face_nominal or 0
  local r = f(card, ...)
  b.value, b.nominal, b.face_nominal = value, nominal, face_nominal
  return r
end
local get_nominal, is_face = Card.get_nominal, Card.is_face
function Card:get_nominal(mod) return as_assigned(self, get_nominal, mod) end
function Card:is_face(from_boss) return as_assigned(self, is_face, from_boss) end

-- Groups of equal ranks; tie groups (two 3½s) group by their token and come after the ranked ones. Without
-- ties this is the game's own function.
local base_get_X_same = get_X_same
function get_X_same(num, hand, or_more)
  local any_tie = false
  for _, c in ipairs(hand) do if ties[c] then any_tie = true; break end end
  if not any_tie then return base_get_X_same(num, hand, or_more) end
  local groups, ids, tokens = {}, {}, {}
  for _, c in ipairs(hand) do
    local k = ties[c]
    if not k then
      local id = c:get_id()
      if id > 0 then k = id end
    end
    if k then
      if not groups[k] then
        groups[k] = {}
        if type(k) == "number" then ids[#ids + 1] = k else tokens[#tokens + 1] = k end
      end
      table.insert(groups[k], c)
    end
  end
  table.sort(ids, function(a, b) return a > b end)
  table.sort(tokens)
  local out = {}
  for _, list in ipairs({ ids, tokens }) do
    for _, k in ipairs(list) do
      local g = groups[k]
      if #g == num or (or_more and #g >= num) then out[#out + 1] = g end
    end
  end
  return out
end

-- Straights, written for the ranks' next lists as Steamodded's are, with one addition: an Ace may lead into
-- the Knight from anywhere in a straight. An Ace (or any straight_edge rank) is otherwise only allowed at
-- either end, and a Shortcut skip may not jump over one.
local function straight_steps(key, at_start, wrap)
  local rank = SMODS.Ranks[key]
  local out = {}
  if at_start or wrap or not rank.straight_edge then
    for _, n in ipairs(rank.next) do out[#out + 1] = n end
  end
  if key == "Ace" and SMODS.Ranks.ww_Knight then out[#out + 1] = "ww_Knight" end
  return out
end

function WW.get_straight(hand, min_length, skip, wrap)
  min_length = math.max(2, min_length or 5)
  if #hand < min_length then return {} end
  local by_key, key_of_id = {}, {}
  for _, k in ipairs(SMODS.Rank.obj_buffer) do key_of_id[SMODS.Ranks[k].id] = k end
  for _, c in ipairs(hand) do
    local id = c:get_id()
    local k = id and id > 0 and key_of_id[id]
    if k then
      by_key[k] = by_key[k] or {}
      table.insert(by_key[k], c)
    end
  end
  local runs = {}
  local function extend(run, used)
    local last = run[#run]
    local nexts = {}
    for _, n in ipairs(straight_steps(last, #run == 1, wrap)) do
      nexts[#nexts + 1] = n
      if skip and (wrap or not SMODS.Ranks[n].straight_edge) then
        for _, m in ipairs(straight_steps(n, false, wrap)) do nexts[#nexts + 1] = m end
      end
    end
    local extended = false
    for _, n in ipairs(nexts) do
      if by_key[n] and not used[n] then
        extended = true
        run[#run + 1], used[n] = n, true
        extend(run, used)
        run[#run], used[n] = nil, nil
      end
    end
    if not extended and #run >= min_length then
      local cards = {}
      for _, k in ipairs(run) do
        for _, c in ipairs(by_key[k]) do cards[#cards + 1] = c end
      end
      runs[#runs + 1] = cards
    end
  end
  for _, k in ipairs(SMODS.Rank.obj_buffer) do
    if by_key[k] then extend({ k }, { [k] = true }) end
  end
  table.sort(runs, function(a, b) return #a > #b end)
  return runs
end

SMODS.PokerHandPart:take_ownership("_straight", {
  func = function(hand)
    return WW.get_straight(hand, SMODS.four_fingers("straight"), SMODS.shortcut(), SMODS.wrap_around_straight())
  end,
}, true)

-- The best hand in G.handlist that these results contain: its position, and its name.
local function top_of(results)
  for i, name in ipairs(G.handlist) do
    if results[name] and next(results[name]) then return i, name end
  end
  return #G.handlist + 1, nil
end

local evaluate = evaluate_poker_hand
function evaluate_poker_hand(hand)
  local main = (G.play and hand == G.play.cards) or (G.hand and hand == G.hand.highlighted)
  if main then
    -- Cards not in the hand being read report their own ranks again.
    local inside = {}
    for _, c in ipairs(hand) do inside[c] = true end
    for c in pairs(active) do if not inside[c] then active[c] = nil end end
    for c in pairs(ties) do if not inside[c] then ties[c] = nil end end
  end
  local cards, any = {}, false
  for i, c in ipairs(hand) do
    active[c], ties[c] = nil, nil
    local ranks = WW.ranks_of(c)
    if WW.has_value(c) then any = true end
    cards[i] = { ranks = ranks or {}, key = WW.has_value(c) and c.ability.ww_value or ("#" .. i) }
  end
  if not any then return evaluate(hand) end

  local function apply(a)
    for i, c in ipairs(hand) do
      local v = a[i]
      active[c], ties[c] = nil, nil
      if type(v) == "string" then ties[c] = v
      elseif v and #cards[i].ranks >= 2 then active[c] = KEYS[v] end
    end
  end
  local best, best_a, best_i, best_n
  for _, a in ipairs(H.candidates(cards, { straight = SMODS.four_fingers("straight"), skip = SMODS.shortcut() })) do
    apply(a)
    local results = evaluate(hand)
    local i, name = top_of(results)
    local n = name and #results[name][1] or 0
    if not best or i < best_i or (i == best_i and n > best_n) then
      best, best_a, best_i, best_n = results, a, i, n
    end
  end
  apply(best_a)
  return best
end

-- scoring -----------------------------------------------------------------------------------------------

--- The chips a card scores for ending on the number x.
function WW.chips_of(x)
  if N.is_integer(x) and x.x >= 0 and x.x <= 15 then return SMODS.Ranks[KEYS[x.x]].nominal end
  return N.finite(x)
end

--- Play out the scoring cards' values: {total, finals, moves, cards}, or nil when none of them has a value
--- (then everything scores exactly as vanilla). Debuffed cards don't take part.
function WW.resolve(scoring_hand)
  local cards, values, any = {}, {}, false
  for _, c in ipairs(scoring_hand) do
    if not c.debuff then
      local v = WW.value_of(c)
      if v then
        cards[#cards + 1], values[#values + 1] = c, v
        if WW.has_value(c) then any = true end
      end
    end
  end
  if not any then return nil end
  local r = P.resolve(values)
  r.cards = cards
  return r
end

local finals = setmetatable({}, { __mode = "k" })

local main_scoring = SMODS.calculate_main_scoring
function SMODS.calculate_main_scoring(context, scoring_hand)
  local r = scoring_hand and context.cardarea == G.play and WW.resolve(scoring_hand)
  if r then
    for i, c in ipairs(r.cards) do finals[c] = r.finals[i] end
  end
  local a, b = main_scoring(context, scoring_hand)
  if r then
    for _, c in ipairs(r.cards) do finals[c] = nil end
  end
  return a, b
end

local get_chip_bonus = Card.get_chip_bonus
function Card:get_chip_bonus()
  local f = finals[self]
  if not f then return get_chip_bonus(self) end
  local b = self.base
  local nominal = b.nominal
  b.nominal = WW.chips_of(f)
  local chips = get_chip_bonus(self)
  b.nominal = nominal
  return chips
end

-- For tests: what a card currently plays as.
function WW.playing_as(card) return active[card] or ties[card] end
WW._finals = finals
