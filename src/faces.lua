-- How a modifier shows on a card: a badge over the normal rank front, a nimbus halo for *, and a tooltip.
--
-- The badge frames and the glyphs are Fable's art (art/, assets/*/mods*.png and glyphs.png). The text is composed
-- at runtime: for each distinct label, the glyphs are drawn once onto a card-sized canvas, which is then drawn
-- like a seal, with the card's dissolve shader. art/layout.lua gives the text box; art/glyphs.lua the glyph
-- order and widths.

local WW = WinningWays
local E = WW.engine
local N, Gm, P = E.num, E.game, E.play

SMODS.Atlas { key = "mods", path = "mods.png", px = 71, py = 95 }
SMODS.Atlas { key = "mods_hc", path = "mods_hc.png", px = 71, py = 95 }
SMODS.Atlas { key = "glyphs", path = "glyphs.png", px = 7, py = 9 }

local GLYPHS = assert(SMODS.load_file("art/glyphs.lua"))()
local LAYOUT = assert(SMODS.load_file("art/layout.lua"))()
local CELL = { number = 0, hot = 1, infinite = 2, game = 3, nimbus = 4 }
local index = {}
for i, name in ipairs(GLYPHS.order) do index[name] = i - 1 end
-- The small digits and slash follow ⅞ in the sheet, whatever art/glyphs.lua names them.
if not GLYPHS.small then
  GLYPHS.small = {}
  local after = index["⅞"] + 1
  for d = 0, 9 do GLYPHS.small[tostring(d)] = GLYPHS.order[after + d + 1] end
  GLYPHS.small["/"] = GLYPHS.order[after + 11]
end

-- labels ------------------------------------------------------------------------------------------------

local FRACTIONS = { [0.5] = "½", [0.25] = "¼", [0.75] = "¾", [0.125] = "⅛", [0.375] = "⅜", [0.625] = "⅝", [0.875] = "⅞" }

local function digits(n, small, out)
  for d in ("%.0f"):format(n):gmatch("%d") do out[#out + 1] = small and GLYPHS.small[d] or d end
end

-- Glyph names for a dyadic: an optional sign, the whole part, and the fraction as one glyph (½) or small
-- numerator / denominator.
local function dyadic(x, signed, out)
  out = out or {}
  if x < 0 then out[#out + 1] = "−" elseif signed then out[#out + 1] = "+" end
  local a = math.abs(x)
  local whole, frac = math.floor(a), a - math.floor(a)
  if whole > 0 or frac == 0 then digits(whole, false, out) end
  if frac > 0 then
    if FRACTIONS[frac] then out[#out + 1] = FRACTIONS[frac]
    else
      local q = 1
      while frac * q ~= math.floor(frac * q) do q = q * 2 end
      digits(frac * q, true, out)
      out[#out + 1] = GLYPHS.small["/"]
      digits(q, true, out)
    end
  end
  return out
end

-- k·ω + x, signed or not.
local function number(v, signed, out)
  out = out or {}
  if v.k == 0 then return dyadic(v.x, signed, out) end
  if v.k < 0 then out[#out + 1] = "−" elseif signed then out[#out + 1] = "+" end
  if math.abs(v.k) ~= 1 then dyadic(math.abs(v.k), false, out) end
  out[#out + 1] = "ω"
  if v.x ~= 0 then dyadic(v.x, true, out) end
  return out
end

local STAR = Gm.of({ N.zero }, { N.zero })

-- A modifier's badge: {kind, glyphs, nimbus}, or nil when it shows nothing.
local function classify(rank, mod)
  if N.is(mod) then
    if N.eq(mod, N.zero) then return nil end
    return { kind = N.is_finite(mod) and "number" or "infinite", glyphs = number(mod, true) }
  end
  local mean = Gm.mean(mod)
  local rest = Gm.sub(mod, mean)
  if Gm.eq(rest, STAR) then
    return { kind = "number", glyphs = N.eq(mean, N.zero) and {} or number(mean, true), nimbus = true }
  end
  -- A switch: rest = ±t.
  if Gm.is_game(rest) and #rest.L == 1 and #rest.R == 1 and N.is(rest.L[1]) and N.is(rest.R[1])
      and N.eq(rest.L[1], N.neg(rest.R[1])) and N.is_finite(rest.L[1]) then
    local out = N.eq(mean, N.zero) and {} or number(mean, true)
    out[#out + 1] = "±"
    return { kind = "hot", glyphs = number(rest.L[1], false, out) }
  end
  -- Anything else shows the value's stops, L|R.
  local value = Gm.add(N.new(rank), mod)
  local ls, rs = Gm.left_stop(value), Gm.right_stop(value)
  local out = number(ls, false)
  out[#out + 1] = "|"
  number(rs, false, out)
  return { kind = (N.is_finite(ls) and N.is_finite(rs)) and "game" or "infinite", glyphs = out }
end

local badges = {}
function WW.badge_of(card)
  if not WW.has_mod(card) then return nil end
  local rank = WW.rank_int(card.base.value)
  if not rank then return nil end
  local key = rank .. "|" .. card.ability.ww_mod
  if badges[key] == nil then badges[key] = classify(rank, WW.mod_of(card)) or false end
  return badges[key] or nil
end

-- drawing -----------------------------------------------------------------------------------------------

local frames, labels, n_labels = {}, {}, 0

local function frame(cell)
  local atlas = G.SETTINGS.colourblind_option and "ww_mods_hc" or "ww_mods"
  local key = atlas .. cell
  if not frames[key] then
    frames[key] = SMODS.create_sprite(0, 0, G.CARD_W, G.CARD_H, atlas, { x = CELL[cell], y = 0 })
  end
  return frames[key]
end

-- The label's glyphs drawn onto a transparent card-sized canvas, centred in the text box.
local function label(glyphs)
  local scale = G.SETTINGS.GRAPHICS.texture_scaling
  local key = scale .. ":" .. table.concat(glyphs, " ")
  if labels[key] then return labels[key] end
  local sheet = G.ASSET_ATLAS.ww_glyphs
  local gap = GLYPHS.gap or 1
  local width = 0
  for i, g in ipairs(glyphs) do width = width + (GLYPHS.widths[g] or GLYPHS.cell.w) + (i > 1 and gap or 0) end
  local box = LAYOUT.text
  local x = box.x + math.max(0, math.floor((box.w - width) / 2))
  local y = box.y + math.floor((box.h - GLYPHS.cell.h) / 2)
  local canvas = love.graphics.newCanvas(71, 95, { dpiscale = scale })
  canvas:setFilter("nearest", "nearest")
  love.graphics.push("all")
  love.graphics.setCanvas(canvas)
  love.graphics.clear(0, 0, 0, 0)
  love.graphics.origin()
  love.graphics.setColor(1, 1, 1, 1)
  for _, g in ipairs(glyphs) do
    local i = index[g]
    if i then
      local quad = love.graphics.newQuad(i * GLYPHS.cell.w, 0, GLYPHS.cell.w, GLYPHS.cell.h, sheet.image:getDimensions())
      love.graphics.draw(sheet.image, quad, x, y)
      x = x + (GLYPHS.widths[g] or GLYPHS.cell.w) + gap
    end
  end
  love.graphics.pop()
  n_labels = n_labels + 1
  local atlas = { name = "ww_label_" .. n_labels, image = canvas, px = 71, py = 95 }
  G.ASSET_ATLAS[atlas.name] = atlas
  labels[key] = Sprite(0, 0, G.CARD_W, G.CARD_H, atlas, { x = 0, y = 0 })
  return labels[key]
end

local function draw(sprite, card)
  sprite.role.draw_major = card
  sprite:draw_shader("dissolve", nil, nil, nil, card.children.center)
end

SMODS.DrawStep {
  key = "modifier",
  order = 35, -- after the seal (30), before stickers (40)
  func = function(card, layer)
    local b = WW.badge_of(card)
    if not b then return end
    if #b.glyphs > 0 then
      draw(frame(b.kind), card)
      draw(label(b.glyphs), card)
    end
    if b.nimbus then draw(frame("nimbus"), card) end
  end,
  conditions = { vortex = false, facing = "front" },
}

-- tooltip -----------------------------------------------------------------------------------------------

-- Text for the tooltip: numbers as mixed fractions, games in {L|R} notation.
local TEXT_FRACTIONS = { [0.5] = "½", [0.25] = "¼", [0.75] = "¾" }
local function pretty(v)
  if N.is(v) then
    local function dy(x)
      local sign = x < 0 and "-" or ""
      local a = math.abs(x)
      local whole, frac = math.floor(a), a - math.floor(a)
      if frac == 0 then return sign .. ("%.0f"):format(whole) end
      local f = TEXT_FRACTIONS[frac] or N.dyadic_str(frac)
      if whole == 0 then return sign .. f end
      return sign .. ("%.0f"):format(whole) .. (TEXT_FRACTIONS[frac] and f or (" " .. f))
    end
    if v.k == 0 then return dy(v.x) end
    local s = (v.k == 1 and "" or (v.k == -1 and "-" or dy(v.k))) .. "ω"
    if v.x > 0 then s = s .. "+" .. dy(v.x) elseif v.x < 0 then s = s .. dy(v.x) end
    return s
  end
  local parts = {}
  for _, side in ipairs({ v.L, v.R }) do
    local p = {}
    for i, o in ipairs(side) do p[i] = pretty(o) end
    parts[#parts + 1] = table.concat(p, ",")
  end
  return "{" .. parts[1] .. "|" .. parts[2] .. "}"
end
WW.pretty = pretty

local NAMES = { [11] = "J", [12] = "C", [13] = "Q", [14] = "K", [15] = "A" }
local function rank_name(r) return NAMES[r] or tostring(r) end

local function ranks_text(ranks)
  if #ranks == 0 then return localize("k_ww_no_rank") end
  if #ranks >= 3 and ranks[#ranks] - ranks[1] == #ranks - 1 then
    return rank_name(ranks[1]) .. "-" .. rank_name(ranks[#ranks])
  end
  local out = {}
  for i, r in ipairs(ranks) do out[i] = rank_name(r) end
  return table.concat(out, ", ")
end

local generate = generate_card_ui
function generate_card_ui(_c, full_UI_table, specific_vars, card_type, badges_, hide_desc, main_start, main_end, card)
  local ui = generate(_c, full_UI_table, specific_vars, card_type, badges_, hide_desc, main_start, main_end, card)
  if not full_UI_table and card and WW.has_mod(card) then
    local value = WW.value_of(card)
    if value then
      generate({ set = "Other", key = "ww_modifier", vars = {
        pretty(WW.mod_of(card)), pretty(value), ranks_text(WW.ranks_of(card)),
      } }, ui)
    end
  end
  return ui
end
