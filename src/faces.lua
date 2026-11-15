-- How a modifier shows on a card. The corner reads as the value: the modifier is written in colour right after
-- the rank's index, top-left and again rotated 180° at bottom-right, like vanilla's index. So a 3 with +½ reads
-- "3+½", a 7 with ±2 reads "7±2" and a King with +ω reads "K+ω".
--
-- Colours by role (art/layout.lua): number offsets in the chips family, heat (±t) in the mult family, ω in gold,
-- infinitesimals (↑ ↓) in the halo's blue. A * is the nimbus halo. The wild ({ω|2}, which plays as every rank) has
-- both corner indices pasted over with a wild symbol instead. Every modifier fits these: a number offset (finite or
-- not), a nimber halo, a switch ±t, ↑ or ↓, or, for the few general games (sums of hot cards, Cuts of hot cards), the
-- value's stops L|R in the heat colour. The tooltip gives the exact value.
--
-- Labels are composed at runtime: each distinct one is drawn once onto a card-sized canvas, which is then drawn like
-- a seal, with the card's dissolve shader. The glyphs, overlays and layout are Fable's (art/, assets/).

local WW = WinningWays
local E = WW.engine
local N, Gm, P = E.num, E.game, E.play

SMODS.Atlas { key = "mods", path = "mods.png", px = 71, py = 95 }
SMODS.Atlas { key = "mods_hc", path = "mods_hc.png", px = 71, py = 95 }
SMODS.Atlas { key = "glyphs", path = "glyphs.png", px = 7, py = 9 }

local GLYPHS = assert(SMODS.load_file("art/glyphs.lua"))()
local LAYOUT = assert(SMODS.load_file("art/layout.lua"))()
local CELL = {}
for i, name in ipairs(LAYOUT.cells) do CELL[name] = i - 1 end
local index = {}
for i, name in ipairs(GLYPHS.order) do index[name] = i - 1 end

-- labels ------------------------------------------------------------------------------------------------
-- A label is a list of {glyph, role}.

local FRACTIONS = {}
for frac, g in pairs({ [0.5] = "½", [0.25] = "¼", [0.75] = "¾", [0.125] = "⅛", [0.375] = "⅜", [0.625] = "⅝", [0.875] = "⅞" }) do
  if index[g] then FRACTIONS[frac] = g end
end

local function digits(n, small, role, out)
  for d in ("%.0f"):format(n):gmatch("%d") do out[#out + 1] = { small and ("s" .. d) or d, role } end
end

-- A dyadic: an optional sign, the whole part, and the fraction as one glyph (½) or small numerator / denominator.
local function dyadic(x, signed, role, out)
  if x < 0 then out[#out + 1] = { "−", role } elseif signed then out[#out + 1] = { "+", role } end
  local a = math.abs(x)
  local whole, frac = math.floor(a), a - math.floor(a)
  if whole > 0 or frac == 0 then digits(whole, false, role, out) end
  if frac > 0 then
    if FRACTIONS[frac] then out[#out + 1] = { FRACTIONS[frac], role }
    else
      local q = 1
      while frac * q ~= math.floor(frac * q) do q = q * 2 end
      digits(frac * q, true, role, out)
      out[#out + 1] = { "s/", role }
      digits(q, true, role, out)
    end
  end
  return out
end

-- k·ω + x: the ω part in gold, the finite part in `role` (an offset unless said otherwise).
local function number(v, signed, role, out)
  out = out or {}
  role = role or "offset"
  if v.k == 0 then return dyadic(v.x, signed, role, out) end
  if v.k < 0 then out[#out + 1] = { "−", "infinite" } elseif signed then out[#out + 1] = { "+", "infinite" } end
  if math.abs(v.k) ~= 1 then dyadic(math.abs(v.k), false, "infinite", out) end
  out[#out + 1] = { "ω", "infinite" }
  if v.x ~= 0 then dyadic(v.x, true, role, out) end
  return out
end

local STAR = Gm.of({ N.zero }, { N.zero })
local UP = Gm.of({ N.zero }, { STAR })
local DOWN = Gm.neg(UP)

local function is_switch(g)
  return Gm.is_game(g) and #g.L == 1 and #g.R == 1 and N.is(g.L[1]) and N.is(g.R[1])
    and N.eq(g.L[1], N.neg(g.R[1]))
end

-- A modifier's look: {glyphs = label, nimbus = bool, wild = bool}, or nil when it shows nothing.
local function classify(rank, mod)
  local value = Gm.add(N.new(rank), mod)
  local every = 0
  for _, r in ipairs(P.ranks(value)) do if r >= 2 and r <= 15 then every = every + 1 end end
  if every == 14 then return { glyphs = {}, wild = true } end
  if N.is(mod) then
    if N.eq(mod, N.zero) then return nil end
    return { glyphs = number(mod, true) }
  end
  -- A * is the halo (WW.has_star, which nim-sums read too): take it off and draw what's left under it.
  local halo = WW.has_star(mod)
  local plain = halo and Gm.add(mod, STAR) or mod
  if N.is(plain) then
    return { glyphs = N.eq(plain, N.zero) and {} or number(plain, true), nimbus = halo }
  end
  local mean = Gm.mean(plain)
  local rest = Gm.sub(plain, mean)
  local out = N.eq(mean, N.zero) and {} or number(mean, true)
  for _, tiny in ipairs({ { UP, "↑" }, { DOWN, "↓" } }) do
    if Gm.eq(rest, tiny[1]) then
      out[#out + 1] = { tiny[2], "infinitesimal" }
      return { glyphs = out, nimbus = halo }
    end
  end
  if is_switch(rest) then
    out[#out + 1] = { "±", "heat" }
    return { glyphs = number(rest.L[1], false, "heat", out), nimbus = halo }
  end
  -- A general game: its stops, L|R.
  local glyphs = number(Gm.left_stop(value), false, "heat")
  glyphs[#glyphs + 1] = { "|", "heat" }
  number(Gm.right_stop(value), false, "heat", glyphs)
  return { glyphs = glyphs }
end

local looks = {}
function WW.badge_of(card)
  if not WW.has_mod(card) then return nil end
  local rank = WW.rank_int(card.base.value)
  if not rank then return nil end
  local key = rank .. "|" .. WW.mod_key(card)
  if looks[key] == nil then looks[key] = classify(rank, WW.mod_of(card)) or false end
  return looks[key] or nil
end

--- A look as text, for tests: "role:glyph ..." plus " *" for the halo and "wild".
function WW.look_text(b)
  if not b then return "none" end
  if b.wild then return "wild" end
  local parts = {}
  for i, g in ipairs(b.glyphs) do parts[i] = g[2] .. ":" .. g[1] end
  return table.concat(parts, " ") .. (b.nimbus and " *" or "")
end

-- drawing -----------------------------------------------------------------------------------------------

local overlays, labels, n_labels = {}, {}, 0

local function overlay(cell)
  local atlas = G.SETTINGS.colourblind_option and "ww_mods_hc" or "ww_mods"
  local key = atlas .. cell
  if not overlays[key] then
    overlays[key] = SMODS.create_sprite(0, 0, G.CARD_W, G.CARD_H, atlas, { x = CELL[cell], y = 0 })
  end
  return overlays[key]
end

-- Where each glyph goes, following art/glyphs.py's layout(): glyphs advance by inked width + spacing; a run of
-- small digits before "s/" is a numerator (raised), the run after it a denominator (dropped), and the slash
-- tucks in by slash_gap on both sides. Returns {name, x, dy, role} and the inked width.
local function place(glyphs)
  local out, x = {}, 0
  local function small(g) return g and g[1]:sub(1, 1) == "s" and g[1] ~= "s/" end
  for i, g in ipairs(glyphs) do
    local n, dy = g[1], 0
    if small(g) then
      local j = i
      while small(glyphs[j]) do j = j + 1 end
      local k = i
      while small(glyphs[k]) do k = k - 1 end
      if glyphs[j] and glyphs[j][1] == "s/" then dy = GLYPHS.small.num_dy
      elseif glyphs[k] and glyphs[k][1] == "s/" then dy = GLYPHS.small.den_dy end
    end
    if i > 1 then
      x = x + ((n == "s/" or glyphs[i - 1][1] == "s/") and GLYPHS.small.slash_gap or GLYPHS.spacing)
    end
    out[#out + 1] = { n, x, dy, g[2] }
    x = x + (GLYPHS.widths[n] or GLYPHS.cell.w)
  end
  return out, x
end

local function rgb(hex)
  return tonumber(hex:sub(2, 3), 16) / 255, tonumber(hex:sub(4, 5), 16) / 255, tonumber(hex:sub(6, 7), 16) / 255
end

-- The label drawn onto a transparent card-sized canvas after the rank's index, then again rotated 180° about the
-- card's centre for the bottom-right corner.
local function label(glyphs, rank_key)
  local scale = G.SETTINGS.GRAPHICS.texture_scaling
  local parts = {}
  for i, g in ipairs(glyphs) do parts[i] = g[2] .. ":" .. g[1] end
  local key = scale .. ":" .. rank_key .. ":" .. table.concat(parts, " ")
  if labels[key] then return labels[key] end
  local sheet = G.ASSET_ATLAS.ww_glyphs
  local placed = place(glyphs)
  local anchor = LAYOUT.label[rank_key]
  local canvas = love.graphics.newCanvas(71, 95, { dpiscale = scale })
  canvas:setFilter("nearest", "nearest")
  love.graphics.push("all")
  love.graphics.setCanvas(canvas)
  love.graphics.clear(0, 0, 0, 0)
  local function glyphs_at(dx, dy, colour)
    for _, p in ipairs(placed) do
      local i = index[p[1]]
      if i then
        love.graphics.setColor(rgb(colour or LAYOUT.colours[p[4]] or "#000000"))
        local quad = love.graphics.newQuad(i * GLYPHS.cell.w, 0, GLYPHS.cell.w, GLYPHS.cell.h, sheet.image:getDimensions())
        love.graphics.draw(sheet.image, quad, anchor.x + p[2] + dx, anchor.y + p[3] + dy)
      end
    end
  end
  for pass = 1, 2 do
    love.graphics.origin()
    if pass == 2 then
      -- 180° about LAYOUT.turn: pixel (x, y) goes to (70 − x, 94 − y).
      love.graphics.translate(2 * LAYOUT.turn.x, 2 * LAYOUT.turn.y)
      love.graphics.rotate(math.pi)
    end
    -- A one-pixel card-white knockout first, so the label stays legible where it runs over pips or portraits.
    for dx = -1, 1 do
      for dy = -1, 1 do
        if dx ~= 0 or dy ~= 0 then glyphs_at(dx, dy, LAYOUT.colours.knockout) end
      end
    end
    glyphs_at(0, 0)
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
    if b.wild then draw(overlay("wild"), card) end
    if #b.glyphs > 0 and LAYOUT.label[card.base.value] then draw(label(b.glyphs, card.base.value), card) end
    if b.nimbus then draw(overlay("nimbus"), card) end
  end,
  conditions = { vortex = false, facing = "front" },
}

-- tooltip -----------------------------------------------------------------------------------------------

-- Text for the tooltip: numbers as mixed fractions, games in {L|R} notation. Balatro's pixel font lacks ω, ½ and
-- the like; with Fable's symbol font attached (src/font.lua) they show, and without it ω is written w and
-- fractions as p/q.
local SYMBOL_FRACTIONS = { [0.5] = "½", [0.25] = "¼", [0.75] = "¾", [0.125] = "⅛", [0.375] = "⅜", [0.625] = "⅝", [0.875] = "⅞" }
local function pretty(v, signed)
  local symbols = WW.symbols
  if N.is(v) then
    local function dy(x)
      local sign = x < 0 and (symbols and "−" or "-") or ""
      local a = math.abs(x)
      local whole, frac = math.floor(a), a - math.floor(a)
      if frac == 0 then return sign .. ("%.0f"):format(whole) end
      local f = symbols and SYMBOL_FRACTIONS[frac]
      if f then return sign .. (whole > 0 and ("%.0f"):format(whole) or "") .. f end
      if whole == 0 then return sign .. N.dyadic_str(frac) end
      return sign .. ("%.0f"):format(whole) .. " " .. N.dyadic_str(frac)
    end
    local s
    if v.k == 0 then
      s = dy(v.x)
    else
      local omega = symbols and "ω" or "w"
      s = (v.k == 1 and "" or (v.k == -1 and (symbols and "−" or "-") or dy(v.k))) .. omega
      if v.x > 0 then s = s .. "+" .. dy(v.x) elseif v.x < 0 then s = s .. dy(v.x) end
    end
    if signed and not (s:sub(1, 1) == "-" or s:sub(1, 3) == "−") then s = "+" .. s end
    return s
  end
  -- Games with a familiar shape read the way the badges do: x* for {x|x}, m±t for a finite switch.
  if #v.L == 1 and #v.R == 1 and N.is(v.L[1]) and N.is(v.R[1]) then
    local a, b = v.L[1], v.R[1]
    if N.eq(a, b) then return (N.eq(a, N.zero) and "" or pretty(a, signed)) .. "*" end
    if N.is_finite(a) and N.is_finite(b) then
      local m, t = N.half(N.add(a, b)), N.half(N.sub(a, b))
      return (N.eq(m, N.zero) and "" or pretty(m, signed)) .. "±" .. pretty(t)
    end
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
  -- A Wild card always says what it's worth: its * (Wild 5 is 5*), or, once Nimbus has cancelled it, a plain 5.
  local green = card and WW.is_green(card)
  if not full_UI_table and card and (WW.has_mod(card) or green) then
    local value = WW.value_of(card)
    if value then
      local look = WW.badge_of(card)
      local mod = look and look.wild and localize("k_ww_wild_rank")
        or (WW.has_mod(card) and pretty(WW.mod_of(card), true) or "*+* = 0")
      local key = green and "ww_modifier_green" or "ww_modifier"
      generate({ set = "Other", key = key, vars = { mod, pretty(value), ranks_text(WW.ranks_of(card)) } }, ui)
    end
  end
  return ui
end
