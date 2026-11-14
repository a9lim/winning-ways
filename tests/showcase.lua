-- Showcase: `WINNINGWAYS_SHOWCASE=<png> balala` lays out the born ranks and every kind of modifier beside vanilla
-- cards at real scale once the main menu is up, saves a screenshot and quits. For checking the art in the engine.
-- WINNINGWAYS_SHOWCASE_PALETTE=lc or hc forces normal or high-contrast colours for the shot; the settings are
-- put back before quitting.

local WW = WinningWays
local out_path = os.getenv("WINNINGWAYS_SHOWCASE")
local palette = os.getenv("WINNINGWAYS_SHOWCASE_PALETTE")
local saved_palettes, saved_cb

local rows = {
  { "H_ww_0", "C_ww_1", "D_ww_C", "S_ww_C", "H_J", "H_Q", "H_K", "H_A", "S_T" },
  { "D_3", "C_6", "H_T", "H_7", "C_5", "S_Q" },
  { "S_9", "H_4", "S_A", "D_8", "C_K", "H_2" },
}

local function build()
  for _, ui in ipairs({ "MAIN_MENU_UI", "PROFILE_BUTTON" }) do
    if G[ui] then G[ui]:remove(); G[ui] = nil end
  end
  if G.title_top then G.title_top:remove(); G.title_top = nil end
  if G.SPLASH_LOGO then G.SPLASH_LOGO:remove(); G.SPLASH_LOGO = nil end
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
      local card = Card(area.T.x, area.T.y, G.CARD_W, G.CARD_H, G.P_CARDS[key], G.P_CENTERS.c_base,
        { bypass_discovery_center = true, bypass_discovery_ui = true })
      area:emplace(card)
      all[#all + 1] = card
    end
  end
  WW.apply_lab(all)
end

local phase, frames = "wait", 0
local update = Game.update
function Game:update(dt)
  update(self, dt)
  frames = frames + 1
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
