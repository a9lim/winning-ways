-- Showcase: `WINNINGWAYS_SHOWCASE=<png> balala` lays out the born ranks and every kind of value-drawn front beside
-- vanilla cards at real scale once the main menu is up, saves a screenshot and quits. For checking the art in the
-- engine.
-- WINNINGWAYS_SHOWCASE_PALETTE=lc or hc forces normal or high-contrast colours for the shot; the settings are
-- put back before quitting.

local WW = WinningWays
local N, Gm = WW.engine.num, WW.engine.game
local out_path = os.getenv("WINNINGWAYS_SHOWCASE")
local palette = os.getenv("WINNINGWAYS_SHOWCASE_PALETTE")
local saved_palettes, saved_cb

-- WINNINGWAYS_SHOWCASE_SET=moves shows the Moves, Omega and the Game Packs beside vanilla consumables instead;
-- =jokers shows the jokers beside vanilla ones; =omega shows ω cards and wilds on every enhancement and edition;
-- =tooltips hovers each card in turn and saves one shot per tooltip, named <png>-<key>.png.
local set = os.getenv("WINNINGWAYS_SHOWCASE_SET")
local rows = set == "moves" and {
  { "c_ww_cut", "c_ww_sum", "c_ww_heat", "c_ww_cool", "c_ww_frobenius", "c_fool", "c_strength" },
  { "c_ww_tweedledum", "c_ww_repaint", "c_ww_nimbus", "c_ww_mex", "c_ww_omega", "c_trance", "c_familiar" },
  { "p_ww_game_normal_1", "p_ww_game_normal_2", "p_ww_game_jumbo_1", "p_ww_game_mega_1", "p_celestial_normal_1", "p_arcana_normal_1" },
  { "v_ww_lessons", "v_ww_onag", "v_tarot_merchant", "v_tarot_tycoon", "v_illusion" },
} or set == "jokers" and {
  { "j_ww_bouton", "j_ww_generator", "j_ww_grundy", "j_ww_hotstrat", "j_ww_thermograph", "j_joker", "j_dna" },
  { "j_ww_sprouts", "j_ww_cantor", "j_ww_paradise", "j_ww_conway", "j_triboulet", "j_fibonacci", "j_splash" },
} or set == "omega" and {
  { "S_ww_w", "H_ww_w", "C_ww_w", "D_ww_w", "S_ww_w", "H_ww_w", "C_ww_w", "D_ww_w" },
  { "S_A", "D_A", "S_A", "D_A", "S_ww_w", "H_ww_w", "C_ww_w", "D_ww_w" },
  { "H_7", "H_7", "H_7", "H_7", "S_Q", "S_Q", "S_Q", "S_Q" },
  { "S_ww_w", "H_ww_w", "C_ww_w", "D_ww_w", "S_ww_w", "H_ww_w", "C_ww_w", "D_ww_w" },
} or {
  { "H_ww_0", "C_ww_1", "D_ww_C", "S_ww_C", "S_ww_w", "H_J", "H_Q", "H_K", "H_A", "S_T" },
  { "D_3", "C_6", "H_T", "H_7", "C_5", "S_Q", "S_8", "D_5", "C_3" },
  { "S_9", "H_4", "S_K", "D_8", "S_A", "D_A", "C_K", "D_2", "H_2" },
}
-- For =omega: the body or edition of each card, row by row.
local DRESS = {
  { "c_base", "m_gold", "m_bonus", "m_mult", "m_glass", "m_steel", "m_lucky", "m_wild" },
  { "c_base", "c_base", "m_gold", "m_steel", "e_foil", "e_holo", "e_polychrome", "e_negative" },
  { "c_base", "m_gold", "e_polychrome", "e_negative", "c_base", "m_gold", "e_polychrome", "e_negative" },
  { "c_base", "c_base", "c_base", "c_base", "m_glass", "m_steel", "e_holo", "e_negative" },
}
-- For =omega, the last row: the powers of ω, ω² and the merged sums.
local POWERS = {
  N.omega2, N.new(0, 1, 1), N.new(5, 2), N.new(0, 0, 2), N.omega2, N.new(14, 0, 1), N.omega2, N.new(3, 2, 1),
}

local function clear_menu()
  for _, ui in ipairs({ "MAIN_MENU_UI", "PROFILE_BUTTON" }) do
    if G[ui] then G[ui]:remove(); G[ui] = nil end
  end
  -- Hidden, not removed: the menu still deals a Joker into the title a few seconds in.
  if G.title_top then G.title_top.states.visible = false end
  if G.SPLASH_LOGO then G.SPLASH_LOGO:remove(); G.SPLASH_LOGO = nil end
end

local function build()
  -- With Quintessence installed, a row of its Wild suit: the born ranks and a Wild 7±2 beside its own Wild cards.
  -- (Asked here, not at load: the cards exist only once every mod has loaded.)
  if not set and G.P_CARDS.quint_W_ww_0 then
    rows[#rows + 1] = { "quint_W_ww_0", "quint_W_ww_1", "quint_W_ww_C", "quint_W_7", "quint_W_J", "quint_W_T" }
  end
  clear_menu()
  if palette then
    saved_palettes, saved_cb = copy_table(G.SETTINGS.colour_palettes), G.SETTINGS.colourblind_option
    for _, suit in ipairs(SMODS.Suit.obj_buffer) do G.SETTINGS.colour_palettes[suit] = palette end
    G.SETTINGS.colourblind_option = palette == "hc"
  end
  local w, h = G.ROOM.T.w, G.ROOM.T.h
  local row_h = G.CARD_H * 1.12
  local top = (h - row_h * #rows) / 2
  local all = {}
  for r, keys in ipairs(rows) do
    local width = math.min(w - 1, #keys * G.CARD_W * 1.05)
    local area = CardArea((w - width) / 2, top + (r - 1) * row_h, width, G.CARD_H, { card_limit = #keys, type = "title" })
    for _, key in ipairs(keys) do
      local params = { bypass_discovery_center = true, bypass_discovery_ui = true }
      local card
      if G.P_CARDS[key] then
        card = Card(area.T.x, area.T.y, G.CARD_W, G.CARD_H, G.P_CARDS[key], G.P_CENTERS.c_base, params)
      else
        card = Card(area.T.x, area.T.y, G.CARD_W, G.CARD_H, G.P_CARDS.empty, G.P_CENTERS[key], params)
      end
      area:emplace(card)
      all[#all + 1] = card
    end
  end
  if set == "omega" then
    local wild = Gm.of({ N.omega }, { N.zero })
    for r, keys in ipairs(rows) do
      for i, key in ipairs(keys) do
        local c = all[(r - 1) * #keys + i]
        if key:find("_A$") then WW.set_value(c, wild) end
        if key == "H_7" then WW.add_mod(c, Gm.of({ N.new(2) }, { N.new(-2) })) end
        if key == "S_Q" then WW.add_mod(c, Gm.of({ N.new(1) }, { N.new(-1) })) end
        if r == #rows then WW.set_value(c, POWERS[i]) end
        local how = DRESS[r][i]
        if how:sub(1, 2) == "e_" then c:set_edition({ [how:sub(3)] = true }, true, true)
        elseif how ~= "c_base" then c:set_ability(G.P_CENTERS[how]) end
      end
    end
  else
    WW.apply_lab(all)
  end
  for _, c in ipairs(all) do
    if c.base.suit == "quint_Wild" and c.base.value == "7" then WW.add_mod(c, Gm.of({ N.new(2) }, { N.new(-2) })) end
  end
  -- A line of the game's own font, to check the symbol fallback (src/font.lua).
  local last = WW.value_of(all[#all - 1])
  local sample = "Worth {ω|2}  ±½  ⅜  ↑ ↓  ∞ ⊕ ⊗  −¼  " .. ((last and WW.pretty) and WW.pretty(last) or "")
  G.ww_font_check = UIBox {
    definition = { n = G.UIT.ROOT, config = { colour = G.C.CLEAR }, nodes = {
      { n = G.UIT.T, config = { text = sample, scale = 0.5, colour = G.C.WHITE, shadow = true } },
    } },
    config = { align = "bm", offset = { x = 0, y = -0.3 }, major = G.ROOM_ATTACH },
  }
end

-- Tooltips: one card at a time, left of centre so its box opens to the right, hovered as the mouse would.
local TIPS = {
  "j_ww_bouton", "j_ww_generator", "j_ww_grundy", "j_ww_hotstrat", "j_ww_thermograph", "j_ww_sprouts",
  "j_ww_cantor", "j_ww_paradise", "j_ww_birthday", "j_ww_hilbert", "j_ww_conway", "j_ww_berlekamp", "j_ww_guy",
  "c_ww_cut", "c_ww_sum", "c_ww_heat", "c_ww_cool", "c_ww_frobenius", "c_ww_tweedledum", "c_ww_repaint",
  "c_ww_nimbus", "c_ww_mex", "c_ww_omega", "p_ww_game_normal_1", "H_7", "S_ww_w", "c_lovers", "quint_W_5",
  "v_ww_lessons", "v_ww_onag", "omega2",
}
local tip, tip_card = 0, nil
local function next_tip()
  if tip_card then tip_card:stop_hover(); tip_card:remove(); tip_card = nil end
  tip = tip + 1
  local key = TIPS[tip]
  if not key then return false end
  local value
  if key == "omega2" then key, value = "S_ww_w", N.omega2 end -- an ω²: the powers box
  if not (G.P_CENTERS[key] or G.P_CARDS[key]) then return next_tip() end
  local x, y = G.ROOM.T.w * 0.3, (G.ROOM.T.h - G.CARD_H) / 2
  local params = { bypass_discovery_center = true, bypass_discovery_ui = true }
  if G.P_CARDS[key] then
    tip_card = Card(x, y, G.CARD_W, G.CARD_H, G.P_CARDS[key], G.P_CENTERS.c_base, params)
    if key == "H_7" then WW.set_value(tip_card, Gm.of({ N.new(9) }, { N.new(5) })) end -- 7±2: the Modifier box
    if value then WW.set_value(tip_card, value) end
  else
    tip_card = Card(x, y, G.CARD_W, G.CARD_H, G.P_CARDS.empty, G.P_CENTERS[key], params)
  end
  tip_card:hover()
  return true
end

local phase, frames = "wait", 0
local update = Game.update
function Game:update(dt)
  update(self, dt)
  frames = frames + 1
  if set == "tooltips" then
    if phase == "wait" and G.STATE == G.STATES.MENU and G.MAIN_MENU_UI and frames > 60 then
      clear_menu()
      phase, frames = next_tip() and "settle" or "done", 0
    elseif phase == "settle" and frames > 45 then
      phase = "shot"
      local key = TIPS[tip]
      love.graphics.captureScreenshot(function(image)
        local f = io.open(out_path:gsub("%.png$", "") .. "-" .. key .. ".png", "wb")
        if f then f:write(image:encode("png"):getString()); f:close() end
        phase, frames = next_tip() and "settle" or "done", 0
      end)
    elseif phase == "done" then
      love.event.quit()
    end
    return
  end
  if phase == "wait" and G.STATE == G.STATES.MENU and G.MAIN_MENU_UI and frames > 60 then
    build()
    phase, frames = "settle", 0
  elseif phase == "settle" and frames > 120 then
    phase = "shot"
    love.graphics.captureScreenshot(function(image)
      local f = io.open(out_path, "wb")
      if f then f:write(image:encode("png"):getString()); f:close() end
      phase = "done"
    end)
  elseif phase == "done" then
    if saved_palettes then
      G.SETTINGS.colour_palettes, G.SETTINGS.colourblind_option = saved_palettes, saved_cb
    end
    love.event.quit()
  end
end
