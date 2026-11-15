-- The Moves: a consumable set of operations on card values (DESIGN.md § 3), sold in Game Packs, plus the Omega
-- Spectral. Each Move's effect is a plain function of the selected cards, left to right (WW.MOVES[key].apply), so
-- the self-test can run it at the menu; use() wraps it in vanilla's flip animation.

local WW = WinningWays
local E = WW.engine
local N, Gm, nim = E.num, E.game, E.nim

local STAR = Gm.of({ N.zero }, { N.zero })

SMODS.Atlas { key = "moves", path = "moves.png", px = 71, py = 95 }
SMODS.Atlas { key = "omega", path = "omega.png", px = 71, py = 95 }
SMODS.Atlas { key = "packs", path = "packs.png", px = 71, py = 95 }

SMODS.ConsumableType {
  key = "Move",
  primary_colour = HEX("4d9f7c"), -- Fable's blackboard green
  secondary_colour = HEX("2f5a50"),
  collection_rows = { 5, 4 },
  shop_rate = 2,
  default = "c_ww_cut",
}

-- {C:ww_move} names a Move in text, as vanilla writes {C:tarot}Tarot. Steamodded's own {C:move} is the badge's dark
-- green, which doesn't read on a tooltip's white; this is the bright one.
local loc_colour_ref = loc_colour
function loc_colour(_c, _default)
  if _c == "ww_move" then return G.C.SET.Move end
  return loc_colour_ref(_c, _default)
end

-- effects -----------------------------------------------------------------------------------------------

-- Is this card one of ours (a value we can read)?
local function valued(card) return WW.value_of(card) ~= nil end
local function is_game(card)
  local v = WW.value_of(card)
  return v ~= nil and Gm.is_game(v)
end

-- The newborn of a fusion keeps the left parent and takes what it lacks from the right: enhancement, edition, seal.
-- (Sprouts uses it too.)
function WW.inherit(left, right)
  if left.config.center == G.P_CENTERS.c_base and right.config.center ~= G.P_CENTERS.c_base then
    left:set_ability(right.config.center, nil, true)
  end
  if not left.edition and right.edition then left:set_edition(right.edition, true, true) end
  if not left.seal and right.seal then left:set_seal(right.seal, true, true) end
end
local inherit = WW.inherit

-- Fuse two cards into one worth v: the left card becomes the newborn, and the right one is used up.
local function fuse(left, right, v)
  inherit(left, right)
  WW.set_value(left, v)
  return { destroy = { right } }
end

local SUIT_SWAP = { Spades = "Hearts", Hearts = "Spades", Clubs = "Diamonds", Diamonds = "Clubs" }
local SUITS = { "S", "H", "D", "C" }

WW.MOVES = {
  cut = {
    min = 0, max = 2,
    apply = function(cards)
      if #cards == 0 then return { create = { rank = "ww_0" } } end
      if #cards == 1 then
        WW.set_value(cards[1], Gm.of({ WW.value_of(cards[1]) }, {}))
        return {}
      end
      return fuse(cards[1], cards[2], Gm.of({ WW.value_of(cards[1]) }, { WW.value_of(cards[2]) }))
    end,
  },
  sum = {
    min = 2, max = 2,
    apply = function(cards)
      return fuse(cards[1], cards[2], Gm.add(WW.value_of(cards[1]), WW.value_of(cards[2])))
    end,
  },
  heat = {
    min = 1, max = 2, need = is_game,
    apply = function(cards)
      for _, c in ipairs(cards) do
        if is_game(c) then WW.set_mod(c, Gm.heat(WW.mod_of(c), N.one)) end
      end
      return {}
    end,
  },
  cool = {
    min = 1, max = 2, need = is_game,
    apply = function(cards)
      for _, c in ipairs(cards) do
        if is_game(c) then WW.set_mod(c, Gm.cool(WW.mod_of(c), N.one)) end
      end
      return {}
    end,
  },
  frobenius = {
    min = 1, max = 3,
    apply = function(cards)
      for _, c in ipairs(cards) do
        local r = WW.rank_int(c.base.value)
        if r then assert(SMODS.change_base(c, nil, WW.rank_key(nim.square(r)))) end
      end
      return {}
    end,
  },
  repaint = {
    min = 1, max = 3,
    apply = function(cards)
      for _, c in ipairs(cards) do
        local to = SUIT_SWAP[c.base.suit]
        if to then assert(SMODS.change_base(c, to)) end
      end
      return {}
    end,
  },
  nimbus = {
    min = 1, max = 2,
    apply = function(cards)
      for _, c in ipairs(cards) do WW.add_mod(c, STAR) end
      return {}
    end,
  },
  mex = {
    min = 1, max = 4,
    apply = function(cards)
      local others = {}
      for i = 2, #cards do
        local r = WW.rank_int(cards[i].base.value)
        if r then others[#others + 1] = r end
      end
      local m = nim.mex(others)
      if m <= 15 then assert(SMODS.change_base(cards[1], nil, WW.rank_key(m))) end
      return {}
    end,
  },
  omega = {
    min = 1, max = 1,
    apply = function(cards)
      WW.add_mod(cards[1], N.omega)
      return {}
    end,
  },
}

-- using a Move ------------------------------------------------------------------------------------------

local function selected()
  local cards = {}
  for _, c in ipairs(G.hand and G.hand.highlighted or {}) do cards[#cards + 1] = c end
  table.sort(cards, function(a, b) return a.T.x < b.T.x end)
  return cards
end

local function can_use(move)
  if not G.hand or not G.hand.cards or #G.hand.cards == 0 then return false end
  local cards = selected()
  if #cards < move.min or #cards > move.max then return false end
  for _, c in ipairs(cards) do
    if c.ability.set ~= "Default" and c.ability.set ~= "Enhanced" then return false end
  end
  if move.need then
    for _, c in ipairs(cards) do if move.need(c) then return true end end
    return false
  end
  for _, c in ipairs(cards) do if not valued(c) then return false end end
  return true
end

-- Vanilla's Tarot rhythm: flip the cards, change them, flip them back.
local function use(move, consumable)
  local cards = selected()
  G.E_MANAGER:add_event(Event({ trigger = "after", delay = 0.4, func = function()
    play_sound("tarot1")
    consumable:juice_up(0.3, 0.5)
    return true
  end }))
  for i, c in ipairs(cards) do
    local pitch = 1.15 - (i - 0.999) / (#cards - 0.998) * 0.3
    G.E_MANAGER:add_event(Event({ trigger = "after", delay = 0.15, func = function()
      c:flip(); play_sound("card1", pitch); c:juice_up(0.3, 0.3)
      return true
    end }))
  end
  delay(0.2)
  local result = {}
  G.E_MANAGER:add_event(Event({ trigger = "after", delay = 0.1, func = function()
    result = move.apply(cards) or {}
    return true
  end }))
  G.E_MANAGER:add_event(Event({ trigger = "after", delay = 0.1, func = function()
    if result.destroy then SMODS.destroy_cards(result.destroy) end
    if result.create then
      local suit = pseudorandom_element(SUITS, pseudoseed("ww_cut"))
      local born = create_playing_card({ front = G.P_CARDS[suit .. "_" .. result.create.rank], center = G.P_CENTERS.c_base },
        G.hand, nil, nil, { G.C.SET.Move })
      playing_card_joker_effects({ born })
    end
    return true
  end }))
  for i, c in ipairs(cards) do
    local pitch = 0.85 + (i - 0.999) / (#cards - 0.998) * 0.3
    G.E_MANAGER:add_event(Event({ trigger = "after", delay = 0.15, func = function()
      if not c.removed and not c.destroyed then c:flip(); play_sound("tarot2", pitch, 0.6); c:juice_up(0.3, 0.3) end
      return true
    end }))
  end
  G.E_MANAGER:add_event(Event({ trigger = "after", delay = 0.2, func = function()
    G.hand:unhighlight_all()
    return true
  end }))
  delay(0.5)
end

local ORDER = { "cut", "sum", "heat", "cool", "frobenius", "tweedledum", "repaint", "nimbus", "mex" }
-- The info box each Move's text leans on, as vanilla's Tarots show the enhancement they give.
local INFO = { cut = "ww_hot", heat = "ww_hot", cool = "ww_hot", mex = "ww_mex", nimbus = "ww_nim_sum" }
for i, key in ipairs(ORDER) do
  local move = WW.MOVES[key]
  SMODS.Consumable {
    key = key,
    set = "Move",
    atlas = "moves",
    pos = { x = i - 1, y = 0 },
    cost = 3,
    config = move and { max_highlighted = move.max, min_highlighted = move.min } or {},
    loc_vars = function(self, info_queue, card)
      if key == "tweedledum" then
        -- The Fool's box: the last Move's name, green, or red when there's none yet.
        local last = G.GAME and G.GAME.ww_last_move and G.P_CENTERS[G.GAME.ww_last_move]
        local name = last and localize({ type = "name_text", key = last.key, set = "Move" }) or localize("k_none")
        if last then info_queue[#info_queue + 1] = last end
        return { main_end = { { n = G.UIT.C, config = { align = "bm", padding = 0.02 }, nodes = {
          { n = G.UIT.C, config = { align = "m", colour = last and G.C.GREEN or G.C.RED, r = 0.05, padding = 0.05 }, nodes = {
            { n = G.UIT.T, config = { text = " " .. name .. " ", colour = G.C.UI.TEXT_LIGHT, scale = 0.3, shadow = true } },
          } },
        } } } }
      end
      local term = INFO[key]
      if term then info_queue[#info_queue + 1] = { set = "Other", key = term } end
      return { vars = { move and move.max or 0 } }
    end,
    can_use = function(self, card)
      if key == "tweedledum" then
        local last = G.GAME.ww_last_move
        return last ~= nil and last ~= "c_ww_tweedledum"
          and (#G.consumeables.cards < G.consumeables.config.card_limit or card.area == G.consumeables)
      end
      return can_use(move)
    end,
    use = function(self, card, area, copier)
      if key == "tweedledum" then
        G.E_MANAGER:add_event(Event({ trigger = "after", delay = 0.4, func = function()
          if G.consumeables.config.card_limit > #G.consumeables.cards then
            play_sound("timpani")
            SMODS.add_card({ key = G.GAME.ww_last_move, area = G.consumeables })
            card:juice_up(0.3, 0.5)
          end
          return true
        end }))
        delay(0.6)
        return
      end
      G.GAME.ww_last_move = "c_ww_" .. key
      use(move, card)
    end,
  }
end

SMODS.Consumable {
  key = "omega",
  set = "Spectral",
  atlas = "omega",
  pos = { x = 0, y = 0 },
  cost = 4,
  config = { max_highlighted = 1 },
  loc_vars = function(self, info_queue, card)
    info_queue[#info_queue + 1] = { set = "Other", key = "ww_omega" }
  end,
  can_use = function(self, card) return can_use(WW.MOVES.omega) end,
  use = function(self, card, area, copier) use(WW.MOVES.omega, card) end,
}

-- Game Packs ---------------------------------------------------------------------------------------------

local PACKS = {
  { key = "game_normal_1", pos = 0, extra = 3, choose = 1, cost = 4, weight = 0.5 },
  { key = "game_normal_2", pos = 1, extra = 3, choose = 1, cost = 4, weight = 0.5 },
  { key = "game_jumbo_1", pos = 2, extra = 5, choose = 1, cost = 6, weight = 0.4 },
  { key = "game_mega_1", pos = 3, extra = 5, choose = 2, cost = 8, weight = 0.1 },
}
for _, p in ipairs(PACKS) do
  SMODS.Booster {
    key = p.key,
    kind = "Move",
    atlas = "packs",
    pos = { x = p.pos, y = 0 },
    config = { extra = p.extra, choose = p.choose },
    cost = p.cost,
    weight = p.weight,
    draw_hand = true,
    group_key = "k_ww_game_pack",
    loc_vars = function(self, info_queue, card)
      return { vars = { card.ability.choose, card.ability.extra } }
    end,
    create_card = function(self, card, i)
      return { set = "Move", area = G.pack_cards, skip_materialize = true, soulable = true, key_append = "ww_game" }
    end,
    ease_background_colour = function(self)
      ease_colour(G.C.DYN_UI.MAIN, G.C.SET.Move)
      ease_background_colour({ new_colour = G.C.SET.Move, special_colour = G.C.BLACK, contrast = 2 })
    end,
  }
end
