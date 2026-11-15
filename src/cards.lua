-- Values on playing cards, and how hands of them are read and scored (DESIGN.md § 2).
--
-- A card's value is its rank plus a modifier. Ranks are integers (2–10, J 11, C 12, Q 13, K 14, A 15, and the
-- born 0 and 1); the modifier is any game, kept in card.ability.ww_mod as canonical notation. 3½ is a 3 with
-- +½ (or a 4 with −½: equal values play alike), 5* is a 5 with *, 7±2 a 7 with ±2. The modifier is its own
-- slot, beside enhancement, edition and seal, so a card can be Glass and +½. Rank changes from anywhere
-- (Strength, Ouija, Generator) keep the modifier and shift the value with the rank; copies keep it too.
--
-- Reading a hand: evaluate_poker_hand tries the rank assignments that src/engine/hands.lua proposes, runs the
-- game's own evaluator on each, and keeps the best by the hand list's order. While a hand is assigned, a
-- flexible card's get_id, get_nominal and is_face report the rank it plays as.
--
-- Scoring: when the played cards score, src/engine/play.lua plays out their values as one game, and each card
-- scores the number it ends on, in chips: a finite part from 0 to 15 scores that rank's chips (so J, C, Q and K
-- still score 10, and taking ω + 14 scores a King's 10); any other finite part scores itself (3½ scores 3.5).

local WW = WinningWays
local E = WW.engine
local N, Gm, P, H = E.num, E.game, E.play, E.hands

local KEYS = {
  [0] = "ww_0", [1] = "ww_1", [2] = "2", [3] = "3", [4] = "4", [5] = "5", [6] = "6", [7] = "7", [8] = "8",
  [9] = "9", [10] = "10", [11] = "Jack", [12] = "ww_C", [13] = "Queen", [14] = "King", [15] = "Ace",
}
local INTS = {}
for r, k in pairs(KEYS) do INTS[k] = r end
function WW.rank_key(r) return KEYS[r] end
function WW.rank_int(key) return INTS[key] end

-- values ------------------------------------------------------------------------------------------------

local parsed, rank_sets, sums = {}, {}, {}
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

function WW.has_mod(card) return card.ability ~= nil and card.ability.ww_mod ~= nil end
function WW.mod_of(card) return WW.has_mod(card) and parse(card.ability.ww_mod) or nil end

--- A card's value, rank + modifier. nil for a card without one of our ranks (Stone, another mod's rank): a
--- modifier on such a card lies dormant until it has a rank again.
function WW.value_of(card)
  if base_has_no_rank(card) then return nil end
  local r = INTS[card.base.value]
  if not r then return nil end
  if not WW.has_mod(card) then return N.new(r) end
  local key = r .. "|" .. card.ability.ww_mod
  local v = sums[key]
  if not v then v = Gm.add(N.new(r), parse(card.ability.ww_mod)); sums[key] = v end
  return v
end

--- The ranks a card can play as, as integers; nil when it has no value.
function WW.ranks_of(card)
  local v = WW.value_of(card)
  if not v then return nil end
  if not WW.has_mod(card) then return { v.x } end
  return ranks_of_value(v)
end

--- The rank a card made with value v sits on: the rank nearest v's mean among those it plays as (the lower on
--- a tie), or the nearest rank to the mean when it plays as none. An infinite mean picks the top or bottom.
function WW.rank_for(v)
  local mean = Gm.mean(v)
  local target = N.is_finite(mean) and N.finite(mean) or (mean.k > 0 and 1e9 or -1e9)
  local ranks = ranks_of_value(v)
  if #ranks == 0 then return math.max(0, math.min(15, math.ceil(target - 0.5))) end
  local best = ranks[1]
  for _, r in ipairs(ranks) do
    if math.abs(r - target) < math.abs(best - target) then best = r end
  end
  return best
end

local function store_mod(card, m)
  if N.is(m) and N.eq(m, N.zero) then card.ability.ww_mod = nil else card.ability.ww_mod = Gm.encode(m) end
end

--- Make a card worth v (a canonical number or game): it moves to rank_for(v) and keeps v − rank as its
--- modifier. An integer from 0 to 15 is that plain rank.
function WW.set_value(card, v)
  local r = WW.rank_for(v)
  assert(SMODS.change_base(card, nil, KEYS[r]))
  store_mod(card, Gm.sub(v, N.new(r)))
  return card
end

--- Replace a card's modifier (Heat and Cool act on the modifier: heating and cooling commute with adding the rank).
function WW.set_mod(card, m)
  store_mod(card, m)
  return card
end

--- Add a game to a card's modifier (Nimbus adds *, Omega adds ω). The rank stays.
function WW.add_mod(card, m)
  store_mod(card, Gm.add(WW.mod_of(card) or N.zero, m))
  return card
end

-- which rank a card plays as ----------------------------------------------------------------------------

local active = setmetatable({}, { __mode = "k" }) -- flexible card -> rank key it plays as
local ties = setmetatable({}, { __mode = "k" })   -- rankless card -> tie token, while it pairs with an equal one

local set_base = Card.set_base
function Card:set_base(card, initial, manual_sprites)
  active[self], ties[self] = nil, nil
  return set_base(self, card, initial, manual_sprites)
end

function SMODS.has_no_rank(card)
  if base_has_no_rank(card) then return true end
  if WW.has_mod(card) then
    local v = WW.value_of(card)
    if v and #ranks_of_value(v) == 0 then return true end
  end
  return false
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
      if id and id > 0 then k = id end
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

--- Which rankless values pair. Finite ones pair when equal, so a 3 with +½ pairs with a 4 with −½. Infinite numbers
--- pair when they lie in the same galaxy, a finite distance apart (nonstandard analysis's word): ω + 13 pairs with
--- ω + 2, but not with 2ω. Seen from the finite ranks, everything in a galaxy is equally far away.
function WW.tie_key(v)
  if N.is(v) and not N.is_finite(v) then return "galaxy " .. N.encode(N.new(0, v.k)) end
  return Gm.encode(v)
end

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
    local v = WW.value_of(c)
    local modded = v ~= nil and WW.has_mod(c)
    if modded then any = true end
    cards[i] = { ranks = WW.ranks_of(c) or {}, key = modded and WW.tie_key(v) or ("#" .. i) }
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
  local f = N.finite(x)
  if f == math.floor(f) and f >= 0 and f <= 15 then return SMODS.Ranks[KEYS[f]].nominal end
  return f
end

--- Play out the scoring cards' values: {total, finals, moves, cards}, or nil when none of them has a
--- modifier (then everything scores exactly as vanilla). Debuffed cards don't take part.
function WW.resolve(scoring_hand)
  local cards, values, any = {}, {}, false
  for _, c in ipairs(scoring_hand) do
    if not c.debuff then
      local v = WW.value_of(c)
      if v then
        cards[#cards + 1], values[#values + 1] = c, v
        if WW.has_mod(c) then any = true end
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
