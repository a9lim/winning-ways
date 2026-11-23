-- Where a run meets the mod (DESIGN.md § 5⅞). Values come out of vanilla's own card sources, so a run meets 3½ and
-- 7±1 without buying a Move, and the Moves get the voucher pair and the tag that Tarots have.

local WW = WinningWays
local E = WW.engine
local N, Gm = E.num, E.game

-- modifiers in the wild ---------------------------------------------------------------------------------

--- The chance a playing card from a pack, or from the shop under Illusion, comes with a modifier (a balance number,
--- not maths: the Standard Pack's seal rate).
WW.MOD_RATE = 1 / 5
--- The modifiers it can come with, equally likely: a half (3½), a star (5*) and a switch (7±1).
WW.WILD_MODS = { N.new(1 / 2), Gm.of({ N.zero }, { N.zero }), Gm.of({ N.one }, { N.neg(N.one) }) }

--- Roll a modifier onto a card dealt from one of vanilla's sources, in its own slot beside the enhancement, edition
--- and seal vanilla rolled. A Stone card, another mod's rank, or a card that already has a modifier stays as it is.
function WW.roll_mod(card, source)
  if not (card and card.base and card.ability) or card.ability.ww_mod or WW.value_of(card) == nil then return end
  local ante = G.GAME and G.GAME.round_resets and G.GAME.round_resets.ante or 1
  if pseudorandom(pseudoseed("ww_mod_" .. source .. ante)) >= WW.MOD_RATE then return end
  local m = WW.WILD_MODS[pseudorandom(pseudoseed("ww_modtype_" .. source .. ante), 1, #WW.WILD_MODS)]
  WW.add_mod(card, m)
end

-- Every random playing card vanilla deals into a pack (the Standard Packs) or, with Illusion, onto the shop's shelf.
local create = create_card
function create_card(_type, area, ...)
  local card = create(_type, area, ...)
  -- Asked of the card made, not the type asked for: Steamodded's weighted shop asks for an enhancement by key.
  local set = card and card.ability and card.ability.set
  if set == "Default" or set == "Enhanced" then
    if area == G.pack_cards then
      WW.roll_mod(card, "pack")
    elseif area == G.shop_jokers and G.GAME.used_vouchers and G.GAME.used_vouchers.v_illusion then
      WW.roll_mod(card, "shop")
    end
  end
  return card
end

-- vouchers ----------------------------------------------------------------------------------------------

local ART = NFS.getInfo(WW.path .. "assets/1x/vouchers.png") ~= nil
if ART then SMODS.Atlas { key = "vouchers", path = "vouchers.png", px = 71, py = 95 } end

-- Tarot Merchant and Tarot Tycoon for Moves, with their multipliers: the shop's Move rate goes to 2.4 times its
-- own, then 8 times (shown as 2X and 4X, as vanilla shows its own). Named for two books: the textbook that starts
-- you on combinatorial games, and Conway's own, where the surreal numbers start.
for i, v in ipairs({
  { key = "lessons", extra = 9.6 / 4, disp = 2 },
  { key = "onag", extra = 32 / 4, disp = 4, requires = { "v_ww_lessons" } },
}) do
  SMODS.Voucher {
    key = v.key,
    atlas = ART and "vouchers" or nil,
    pos = { x = ART and i - 1 or 0, y = 0 },
    config = { extra = v.extra, extra_disp = v.disp },
    requires = v.requires,
    loc_vars = function(self, info_queue, card) return { vars = { self.config.extra_disp } } end,
    redeem = function(self, card)
      local extra = self.config.extra
      G.E_MANAGER:add_event(Event({ func = function()
        G.GAME.move_rate = SMODS.ConsumableTypes.Move.shop_rate * extra
        return true
      end }))
    end,
  }
end

-- the Game Tag ------------------------------------------------------------------------------------------

if NFS.getInfo(WW.path .. "assets/1x/tags.png") then
  SMODS.Atlas { key = "tags", path = "tags.png", px = 34, py = 34 }
end

-- Charm Tag's twin: a free Mega Game Pack, opened as soon as the next Blind is to be chosen.
SMODS.Tag {
  key = "game",
  atlas = NFS.getInfo(WW.path .. "assets/1x/tags.png") and "tags" or nil,
  pos = { x = 0, y = 0 },
  config = { type = "new_blind_choice" },
  loc_vars = function(self, info_queue, tag)
    info_queue[#info_queue + 1] = G.P_CENTERS.p_ww_game_mega_1
    return {}
  end,
  apply = function(self, tag, context)
    if context.type ~= "new_blind_choice" then return end
    local lock = tag.ID
    G.CONTROLLER.locks[lock] = true
    tag:yep("+", G.C.SET.Move, function()
      local card = Card(G.play.T.x + G.play.T.w / 2 - G.CARD_W * 1.27 / 2, G.play.T.y + G.play.T.h / 2 - G.CARD_H * 1.27 / 2,
        G.CARD_W * 1.27, G.CARD_H * 1.27, G.P_CARDS.empty, G.P_CENTERS.p_ww_game_mega_1,
        { bypass_discovery_center = true, bypass_discovery_ui = true })
      card.cost = 0
      card.from_tag = true
      G.FUNCS.use_card({ config = { ref_table = card } })
      card:start_materialize()
      G.CONTROLLER.locks[lock] = nil
      return true
    end)
    tag.triggered = true
    return true
  end,
}
