-- The jokers (DESIGN.md § 4). "Rank" here means the rank a card plays as in the hand being scored (WW.rank_now):
-- a wild in a Pair of Kings is a King. Cards with no rank (Stone, 3½, ω) are invisible to nim-sums and to the mex,
-- the way a 0 is. In nim-sums a card is a heap: its rank, plus 1 for a * (5* is the heap 4).

local WW = WinningWays
local E = WW.engine
local N, Gm, nim = E.num, E.game, E.nim

-- Until Fable's sheet is in, the jokers wear vanilla's Joker as a placeholder.
local ART = NFS.getInfo(WW.path .. "assets/1x/jokers.png") ~= nil
if ART then SMODS.Atlas { key = "jokers", path = "jokers.png", px = 71, py = 95 } end
local function cell(i) return ART and { x = i, y = 0 } or { x = 0, y = 0 } end
local ATLAS = ART and "jokers" or nil

local function in_row(cards)
  local row = {}
  for i, c in ipairs(cards) do row[i] = c end
  table.sort(row, function(a, b) return a.T.x < b.T.x end)
  return row
end

--- A card's heap for nim-sums: the rank it plays as (r, or the one given), plus 1 for a *. nil with no rank.
function WW.heap(card, r)
  r = r or WW.rank_now(card)
  if not r then return nil end
  return WW.halo(card) and nim.add(r, 1) or r
end

--- The nim-sum of the cards' heaps.
function WW.nim_sum(cards)
  local x = 0
  for _, c in ipairs(cards) do
    local h = WW.heap(c)
    if h then x = nim.add(x, h) end
  end
  return x
end

-- A card's own rank as an integer, for the jokers that act on the rank itself: nil for Stone cards and other
-- mods' ranks.
local function base_rank(card)
  return WW.value_of(card) ~= nil and WW.rank_int(card.base.value) or nil
end

-- Bouton -------------------------------------------------------------------------------------------------

--- Can the played cards nim-sum to 0 with at least three distinct ranks among them? Scoring cards count as the
--- rank they play as. A flexible kicker (one that doesn't score) can play as any of its ranks, Conway's included:
--- you move first in a confused position, so you choose. Cards with no rank, and cards infinity ate, don't count.
--- Ranks are what count as distinct; heaps (a * adds 1) are what nim-sum.
function WW.bouton(full_hand, scoring_hand)
  local scores = {}
  for _, c in ipairs(scoring_hand) do scores[c] = true end
  local kept = {}
  for _, c in ipairs(full_hand) do
    if not WW.is_eaten(c) then kept[#kept + 1] = c end
  end
  local extra = WW.extra_ranks(kept) or {}
  local fixed, seen, distinct, free = 0, {}, 0, {}
  for _, c in ipairs(kept) do
    local own = WW.ranks_of(c)
    local options = own and WW.widen(own, extra[c])
    local r = WW.rank_now(c)
    if not scores[c] and options and #options > 0 and not (#options == 1 and options[1] == r) then
      -- A kicker with a choice. One whose own value has no rank (3½) may also stay rankless: false.
      local choices = {}
      for i, o in ipairs(options) do choices[i] = o end
      if #own == 0 then choices[#choices + 1] = false end
      free[#free + 1] = { card = c, ranks = choices }
    elseif r then
      fixed = nim.add(fixed, WW.heap(c, r))
      if not seen[r] then seen[r], distinct = true, distinct + 1 end
    end
  end
  local function search(i, x, d)
    if i > #free then return x == 0 and d >= 3 end
    for _, r in ipairs(free[i].ranks) do
      local ok
      if r == false then
        ok = search(i + 1, x, d)
      else
        local new = not seen[r]
        if new then seen[r] = true end
        ok = search(i + 1, nim.add(x, WW.heap(free[i].card, r)), d + (new and 1 or 0))
        if new then seen[r] = nil end
      end
      if ok then return true end
    end
    return false
  end
  return search(1, fixed, distinct)
end

SMODS.Joker {
  key = "bouton",
  atlas = ATLAS, pos = cell(0),
  rarity = 3, cost = 8,
  blueprint_compat = true,
  config = { extra = { xmult = 3 } },
  loc_vars = function(self, info_queue, card)
    info_queue[#info_queue + 1] = { set = "Other", key = "ww_nim_sum" }
    return { vars = { card.ability.extra.xmult } }
  end,
  calculate = function(self, card, context)
    if context.joker_main and WW.bouton(context.full_hand, context.scoring_hand) then
      return { xmult = card.ability.extra.xmult }
    end
  end,
}

-- Generator ----------------------------------------------------------------------------------------------

SMODS.Joker {
  key = "generator",
  atlas = ATLAS, pos = cell(1),
  rarity = 2, cost = 7,
  blueprint_compat = true,
  config = { extra = { chips = 2 } },
  loc_vars = function(self, info_queue, card)
    info_queue[#info_queue + 1] = { set = "Other", key = "ww_ace_cycle" }
    return { vars = { card.ability.extra.chips } }
  end,
  calculate = function(self, card, context)
    -- Each scored card pays its place on the Ace's cycle (its discrete log to base 15)…
    if context.individual and context.cardarea == G.play then
      local r = base_rank(context.other_card)
      if r and r > 0 then return { chips = card.ability.extra.chips * nim.log15(r) } end
    end
    -- …and then takes one step along it: its rank is nim-multiplied by the Ace. The modifier stays.
    if context.after and not context.blueprint then
      local turning = {}
      for _, c in ipairs(context.scoring_hand) do
        if not c.debuff and (base_rank(c) or 0) > 0 then turning[#turning + 1] = c end
      end
      if #turning == 0 then return end
      G.E_MANAGER:add_event(Event({ trigger = "after", delay = 0.2, func = function()
        for _, c in ipairs(turning) do
          local r = base_rank(c)
          if r and r > 0 and not c.removed then
            assert(SMODS.change_base(c, nil, WW.rank_key(nim.step(r))))
            c:juice_up(0.3, 0.3)
          end
        end
        play_sound("tarot2", 1.1, 0.6)
        return true
      end }))
      return { message = localize("k_ww_generated"), colour = G.C.CHIPS }
    end
  end,
}

-- Grundy -------------------------------------------------------------------------------------------------

--- The mex of the ranks the cards play as: the smallest rank, counting from 0, that none of them plays as.
function WW.mex_of(cards)
  local ranks = {}
  for _, c in ipairs(cards) do
    local r = WW.rank_now(c)
    if r then ranks[#ranks + 1] = r end
  end
  return nim.mex(ranks)
end

SMODS.Joker {
  key = "grundy",
  atlas = ATLAS, pos = cell(2),
  rarity = 2, cost = 6,
  blueprint_compat = true,
  perishable_compat = false,
  config = { extra = { mult = 0 } },
  loc_vars = function(self, info_queue, card)
    info_queue[#info_queue + 1] = { set = "Other", key = "ww_mex" }
    return { vars = { card.ability.extra.mult } }
  end,
  calculate = function(self, card, context)
    if context.before and not context.blueprint then
      local m = WW.mex_of(context.scoring_hand)
      if m > 0 then
        card.ability.extra.mult = card.ability.extra.mult + m
        return { message = localize("k_upgrade_ex"), colour = G.C.MULT }
      end
    end
    if context.joker_main and card.ability.extra.mult > 0 then
      return { mult = card.ability.extra.mult }
    end
  end,
}

-- Hotstrat -----------------------------------------------------------------------------------------------

SMODS.Joker {
  key = "hotstrat",
  atlas = ATLAS, pos = cell(3),
  rarity = 1, cost = 5,
  blueprint_compat = true,
  loc_vars = function(self, info_queue, card)
    info_queue[#info_queue + 1] = { set = "Other", key = "ww_hot" }
  end,
  calculate = function(self, card, context)
    if context.repetition and context.cardarea == G.play and WW.is_hot(WW.value_of(context.other_card)) then
      return { repetitions = 1 }
    end
  end,
}

-- Thermograph --------------------------------------------------------------------------------------------

--- Is a Thermograph in play? While one is, hot cards score their mean (WW.resolve, src/cards.lua).
function WW.thermograph_held() return next(SMODS.find_card("j_ww_thermograph")) ~= nil end

-- A hot card's temperature, when it's finite (the wild's never freezes).
local function finite_temperature(card)
  local v = WW.value_of(card)
  if not WW.is_hot(v) then return nil end
  local t = Gm.temperature(v)
  return N.is_finite(t) and N.finite(t) or nil
end
WW.finite_temperature = finite_temperature

SMODS.Joker {
  key = "thermograph",
  atlas = ATLAS, pos = cell(4),
  rarity = 3, cost = 8,
  blueprint_compat = true,
  config = { extra = { mult = 3 } },
  loc_vars = function(self, info_queue, card)
    info_queue[#info_queue + 1] = { set = "Other", key = "ww_hot" }
    return { vars = { card.ability.extra.mult } }
  end,
  calculate = function(self, card, context)
    if context.individual and context.cardarea == G.play then
      local t = finite_temperature(context.other_card)
      if t then return { mult = card.ability.extra.mult * t } end
    end
  end,
}

-- Sprouts ------------------------------------------------------------------------------------------------

SMODS.Joker {
  key = "sprouts",
  atlas = ATLAS, pos = cell(5),
  rarity = 3, cost = 8,
  blueprint_compat = true,
  loc_vars = function(self, info_queue, card)
    info_queue[#info_queue + 1] = G.P_CENTERS.c_ww_cut
  end,
  calculate = function(self, card, context)
    if context.before and G.GAME.current_round.hands_played == 0 and #context.full_hand == 2 then
      local row = in_row(context.full_hand)
      local l, r = row[1], row[2]
      local vl, vr = WW.value_of(l), WW.value_of(r)
      if not (vl and vr) then return end
      -- A new spot on the line between them: the left card's copy, worth {left | right}, with what it lacks
      -- (enhancement, edition, seal) from the right, as Cut makes it. The parents stay.
      G.playing_card = (G.playing_card and G.playing_card + 1) or 1
      local born = copy_card(l, nil, nil, G.playing_card)
      WW.inherit(born, r)
      WW.set_value(born, Gm.of({ vl }, { vr }))
      born:add_to_deck()
      G.deck.config.card_limit = G.deck.config.card_limit + 1
      table.insert(G.playing_cards, born)
      G.hand:emplace(born)
      born.states.visible = nil
      G.E_MANAGER:add_event(Event({ func = function()
        born:start_materialize()
        return true
      end }))
      return { message = localize("k_ww_sprouted"), colour = G.C.SET.Move, playing_cards_created = { born } }
    end
  end,
}

-- Cantor -------------------------------------------------------------------------------------------------

local SUITS = { "Spades", "Hearts", "Clubs", "Diamonds" }
local STANDARD = { "2", "3", "4", "5", "6", "7", "8", "9", "10", "Jack", "Queen", "King", "Ace" }
local BORN = { "ww_0", "ww_1", "ww_C" }

--- The diagonal: the rank-and-suit pairs no card in the deck has, among the standard ranks, or, once every one
--- of those is there, among the born ranks. A card counts when it has that rank and suit (a Stone card, or a 3
--- worth 3½, has no rank).
function WW.missing_pairs()
  local have = {}
  for _, c in ipairs(G.playing_cards or {}) do
    if not SMODS.has_no_rank(c) and not SMODS.has_no_suit(c) then have[c.base.suit .. "|" .. c.base.value] = true end
  end
  for _, ranks in ipairs({ STANDARD, BORN }) do
    local out = {}
    for _, s in ipairs(SUITS) do
      for _, r in ipairs(ranks) do
        if not have[s .. "|" .. r] then out[#out + 1] = { suit = s, rank = r } end
      end
    end
    if #out > 0 then return out end
  end
  return {}
end

SMODS.Joker {
  key = "cantor",
  atlas = ATLAS, pos = cell(6),
  rarity = 2, cost = 6,
  blueprint_compat = true,
  calculate = function(self, card, context)
    if context.setting_blind and not card.getting_sliced and #WW.missing_pairs() > 0 then
      G.E_MANAGER:add_event(Event({ func = function()
        -- Chosen when it's added, so a copy (Blueprint) adds a second missing pair, not the same one twice.
        local missing = WW.missing_pairs()
        if #missing == 0 then return true end
        local pick = pseudorandom_element(missing, pseudoseed("ww_cantor"))
        local front = G.P_CARDS[SMODS.Suits[pick.suit].card_key .. "_" .. SMODS.Ranks[pick.rank].card_key]
        local c = create_playing_card({ front = front, center = G.P_CENTERS.c_base }, G.deck, nil, nil,
          { G.C.SECONDARY_SET.Enhanced })
        G.deck.config.card_limit = G.deck.config.card_limit + 1
        playing_card_joker_effects({ c })
        return true
      end }))
      return { message = localize("k_ww_diagonal"), colour = G.C.FILTER }
    end
  end,
}

-- Cantor's Paradise --------------------------------------------------------------------------------------

SMODS.Joker {
  key = "paradise",
  atlas = ATLAS, pos = cell(7),
  rarity = 2, cost = 7,
  blueprint_compat = true,
  perishable_compat = false,
  config = { extra = { gain = 0.1, xmult = 1 } },
  loc_vars = function(self, info_queue, card)
    info_queue[#info_queue + 1] = { set = "Other", key = "ww_omega" }
    return { vars = { card.ability.extra.gain, card.ability.extra.xmult } }
  end,
  calculate = function(self, card, context)
    -- src/omega.lua sends context.ww_eaten, the cards eaten this hand, before the hand scores.
    if context.ww_eaten and not context.blueprint then
      local x = card.ability.extra
      x.xmult = math.floor((x.xmult + x.gain * #context.ww_eaten) * 100 + 0.5) / 100
      return { message = localize({ type = "variable", key = "a_xmult", vars = { x.xmult } }), colour = G.C.MULT }
    end
    if context.joker_main and card.ability.extra.xmult > 1 then
      return { xmult = card.ability.extra.xmult }
    end
  end,
}

-- Conway -------------------------------------------------------------------------------------------------

--- With Conway in play, each card in the hand being read can also play as {left neighbour | right neighbour},
--- the game whose options are the values beside it: [4, x, 6] lets x be 5, [K, x, K] lets it be K (K*), and
--- [A, x, 2] lets it be any rank. An end card has one side empty: {|R} is 0 and {L|} is L rounded up. Values
--- don't change; this only widens the ranks cards play as (src/cards.lua). Stone cards are neither given ranks
--- nor neighbours.
function WW.extra_ranks(hand)
  if not next(SMODS.find_card("j_ww_conway")) then return nil end
  local row, out = in_row(hand), {}
  for i, c in ipairs(row) do
    if WW.value_of(c) then
      local l = row[i - 1] and WW.value_of(row[i - 1])
      local r = row[i + 1] and WW.value_of(row[i + 1])
      out[c] = WW.ranks_of_value(Gm.of(l and { l } or {}, r and { r } or {}))
    end
  end
  return out
end

SMODS.Joker {
  key = "conway",
  atlas = ATLAS, pos = cell(8), soul_pos = ART and { x = 9, y = 0 } or nil,
  rarity = 4, cost = 20,
  blueprint_compat = false,
  loc_vars = function(self, info_queue, card)
    info_queue[#info_queue + 1] = G.P_CENTERS.c_ww_cut
  end,
}

-- Birthday -----------------------------------------------------------------------------------------------

--- How many days after its integer part a value was born: 3½ = ++++− (day 5) is 2 days after 3, 3¼ (day 6) 3
--- days, 5* (day 6) 1 day, 7±2 = {9|5} (day 10) 3 days after 7. A game's integer part is its mean's, rounded toward 0; the
--- integer n is born on day |n|. nil for a value born on an infinite day (ω + 14, the wild).
function WW.days_after(v)
  local b = Gm.birthday(v)
  if b.m ~= 0 then return nil end
  local mean = Gm.mean(v)
  if not N.is_finite(mean) then return nil end
  local x = N.finite(mean)
  local int = x >= 0 and math.floor(x) or -math.floor(-x)
  return b.n - math.abs(int)
end

SMODS.Joker {
  key = "birthday",
  atlas = ATLAS, pos = cell(10),
  rarity = 2, cost = 6,
  blueprint_compat = true,
  config = { extra = { mult = 3 } },
  loc_vars = function(self, info_queue, card) return { vars = { card.ability.extra.mult } } end,
  calculate = function(self, card, context)
    if context.individual and context.cardarea == G.play then
      local v = WW.value_of(context.other_card)
      local days = v and WW.days_after(v)
      if days and days > 0 then return { mult = card.ability.extra.mult * days } end
    end
  end,
}

-- Hilbert's Hotel ----------------------------------------------------------------------------------------

-- There's always room for one more: it takes no Joker slot and adds another. Steamodded counts each card's
-- card_limit toward its area's slots, so 2 here is its own slot plus one more (a Negative edition is 1); vanilla's
-- h_size takes the hand size, and gives it back while it's debuffed, as Juggler's does.
SMODS.Joker {
  key = "hilbert",
  atlas = ATLAS, pos = cell(11),
  rarity = 3, cost = 8,
  blueprint_compat = false,
  config = { card_limit = 2, h_size = -1, extra = { slots = 2, hand = 1 } },
  loc_vars = function(self, info_queue, card)
    return { vars = { card.ability.extra.slots, card.ability.extra.hand } }
  end,
}

-- Berlekamp and Guy: the other two authors -----------------------------------------------------------------

SMODS.Joker {
  key = "berlekamp",
  atlas = ATLAS, pos = cell(12), soul_pos = ART and { x = 13, y = 0 } or nil,
  rarity = 4, cost = 20,
  blueprint_compat = true,
  config = { extra = { xmult = 1.5 } },
  loc_vars = function(self, info_queue, card)
    info_queue[#info_queue + 1] = { set = "Other", key = "ww_hot" }
    return { vars = { card.ability.extra.xmult } }
  end,
  calculate = function(self, card, context)
    if context.individual and context.cardarea == G.play and WW.is_hot(WW.value_of(context.other_card)) then
      return { xmult = card.ability.extra.xmult }
    end
  end,
}

SMODS.Joker {
  key = "guy",
  atlas = ATLAS, pos = cell(14), soul_pos = ART and { x = 15, y = 0 } or nil,
  rarity = 4, cost = 20,
  blueprint_compat = true,
  config = { extra = { xmult = 1.5, top = 5 } },
  loc_vars = function(self, info_queue, card)
    return { vars = { card.ability.extra.xmult, card.ability.extra.top } }
  end,
  calculate = function(self, card, context)
    if context.individual and context.cardarea == G.play then
      local r = WW.rank_now(context.other_card)
      if r and r <= card.ability.extra.top then return { xmult = card.ability.extra.xmult } end
    end
  end,
}
