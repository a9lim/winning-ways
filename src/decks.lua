-- The decks (DESIGN.md § 5). The Field Deck: 64 cards, ranks 0 to A with the Cavalier in every suit. With nim arithmetic its
-- sixteen ranks are the field F₁₆.

local WW = WinningWays
local N = WW.engine.num

local ART = NFS.getInfo(WW.path .. "assets/1x/backs.png") ~= nil
if ART then SMODS.Atlas { key = "backs", path = "backs.png", px = 71, py = 95 } end

SMODS.Back {
  key = "field",
  atlas = ART and "backs" or nil,
  pos = { x = 0, y = 0 },
  -- The born ranks join the standard 52 when the deck is built (vanilla's extra_cards), so they count toward
  -- the starting deck size.
  apply = function(self)
    local extra = G.GAME.starting_params.extra_cards or {}
    for _, s in ipairs({ "S", "H", "C", "D" }) do
      for _, r in ipairs({ "ww_0", "ww_1", "ww_C" }) do extra[#extra + 1] = { s = s, r = r } end
    end
    G.GAME.starting_params.extra_cards = extra
  end,
}

-- The Ordinal Deck: the standard 52, a 0 of Spades worth exactly ω (0 + ω), and a Cut.
SMODS.Back {
  key = "ordinal",
  atlas = ART and "backs" or nil,
  pos = { x = ART and 1 or 0, y = 0 },
  config = { consumables = { "c_ww_cut" } },
  apply = function(self)
    local extra = G.GAME.starting_params.extra_cards or {}
    extra[#extra + 1] = { s = "S", r = "ww_0" }
    G.GAME.starting_params.extra_cards = extra
    G.E_MANAGER:add_event(Event({ func = function()
      for _, c in ipairs(G.playing_cards) do
        if c.base.value == "ww_0" and not WW.has_mod(c) then
          WW.add_mod(c, N.omega)
          break
        end
      end
      return true
    end }))
  end,
}
