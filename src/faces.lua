-- How a card's value shows. A card that is more than a plain rank draws its own front (DESIGN.md § 2.5):
--
--   the corner   reads as the value, in the rank's own letterforms and ink: 3+1/2, 7±2, ω+14, and a * before the
--                rank for a card that carries one (*5)
--   the field    shows the value's stops in pips: the Right stop's worth solid, on up to the Left stop in outline,
--                a fraction cutting the last pip. So 7±2 = {9|5} is a 9 with five pips solid, and for a switch
--                like that the solid count to the whole count is the ranks it plays as. A * turns the pips to a
--                checkerboard.
--   courts       and the Ace keep their own art, under the new corner
--   ω            is the card inside out: the body in the suit's ink to its edges, the marks white
--   {ω|x}        is split along the diagonal, the ω card above and the x card below; {ω|0} is the wild rank
--
-- src/fronts.lua decides all that and composes it as a grid of pixels, from Fable's parts (assets/parts.lua). Here
-- the grid becomes a texture, drawn once per distinct look, and takes the place of the card's front sprite, so
-- editions, debuffs and the Negative shader treat it like any other front. The tooltip gives the exact value.

local WW = WinningWays
local E = WW.engine
local N = E.num
local F = WW.fronts

local PARTS = assert(SMODS.load_file("assets/parts.lua"))()
WW.parts = PARTS

-- looks -------------------------------------------------------------------------------------------------

local specs = {}

--- What a card shows, as a src/fronts.lua spec; nil for a plain card, which keeps its own front.
function WW.look_of(card)
  local b = card.base
  if not b or not b.value or not WW.is_value(card) then return nil end
  local value = WW.value_of(card)
  if not value then return nil end
  local key = b.value .. "|" .. b.suit .. "|" .. (WW.mod_key(card) or "")
  local spec = specs[key]
  if not spec then
    spec = F.spec(PARTS, b.value, b.suit, value, WW.mod_of(card), WW.halo(card))
    spec.key = key
    specs[key] = spec
  end
  return spec
end

--- A card's look as text, for tests: "field Hearts *7±2 5..9 checker", or "none" for a plain card.
function WW.look_text(card)
  local spec = WW.look_of(card)
  return spec and F.describe(spec) or "none"
end

-- drawing -----------------------------------------------------------------------------------------------

local fronts, n_fronts = {}, 0

local function palette_of(suit)
  local chosen = G.SETTINGS.colour_palettes and G.SETTINGS.colour_palettes[suit]
  if chosen then return chosen == "hc" and "hc" or "lc" end
  return G.SETTINGS.colourblind_option and "hc" or "lc"
end

local function rgb(hex)
  return { tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255 }
end

-- The ink of each row, 1..95: the suit's own, as the deck in use draws it; for a suit we have no parts for, the
-- colour the game writes its name in.
local inks = {}
local function ink_rows(spec, suit, palette)
  local key = palette .. "|" .. suit .. "|" .. spec.ink
  local rows = inks[key]
  if rows then return rows end
  rows = {}
  local known = PARTS.inks[palette][suit]
  local c = known and known[spec.ink]
  if not known then
    local ui = G.C.SUITS[suit] or G.C.BLACK
    c = { ui[1], ui[2], ui[3] }
    for y = 1, F.H do rows[y] = c end
    return rows -- not kept: the game recolours G.C.SUITS in place
  end
  for y = 1, F.H do rows[y] = rgb(type(c) == "table" and c[y] or c) end
  inks[key] = rows
  return rows
end

-- The current atlas of a sprite's original art: textures are reloaded when the render settings change.
local function live(atlas) return G.ASSET_ATLAS[atlas.name] or atlas end

-- Draw one look onto a card-sized canvas. Everything is written with the replace blend, so the canvas holds
-- plain (not premultiplied) colour, like the game's own textures, and the game's shaders can draw it as one.
local function build(spec, rows, body, own)
  local scale = G.SETTINGS.GRAPHICS.texture_scaling
  local layer = F.compose(PARTS, spec)
  local ref = G.ASSET_ATLAS.cards_1.image
  local ok, canvas = pcall(love.graphics.newCanvas, F.W, F.H, { dpiscale = scale, mipmaps = "auto" })
  if not ok then canvas = love.graphics.newCanvas(F.W, F.H, { dpiscale = scale }) end
  canvas:setFilter(ref:getFilter())
  if ok then canvas:setMipmapFilter(ref:getMipmapFilter()) end
  love.graphics.push("all") -- we are called in the middle of the game's own drawing
  love.graphics.setCanvas(canvas)
  love.graphics.origin()
  love.graphics.setScissor()
  love.graphics.setShader()
  love.graphics.clear(0, 0, 0, 0)
  love.graphics.setBlendMode("replace")
  if layer.tint and body then
    -- The body itself, multiplied by the ink, row by row: so it reaches the card's own edges, whatever they are.
    local atlas = live(body.atlas)
    local quad = love.graphics.newQuad(0, 0, 1, 1, atlas.image:getDimensions())
    for y = 1, F.H do
      local w = layer.tint[y]
      if w > 0 then
        quad:setViewport(body.pos.x * atlas.px, body.pos.y * atlas.py + y - 1, w, 1)
        love.graphics.setColor(rows[y][1], rows[y][2], rows[y][3], 1)
        love.graphics.draw(atlas.image, quad, 0, y - 1)
      end
    end
  end
  if layer.base and own then
    local atlas = live(own.atlas)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(atlas.image,
      love.graphics.newQuad(own.pos.x * atlas.px, own.pos.y * atlas.py, F.W, F.H, atlas.image:getDimensions()), 0, 0)
  end
  -- Our pixels, as runs along each row.
  local cells = layer.cells
  for y = 0, F.H - 1 do
    local x = 0
    while x < F.W do
      local code = cells[y * F.W + x + 1]
      local x1 = x + 1
      while x1 < F.W and cells[y * F.W + x1 + 1] == code do x1 = x1 + 1 end
      if code == F.INK then
        local c = rows[y + 1]
        love.graphics.setColor(c[1], c[2], c[3], 1)
        love.graphics.rectangle("fill", x, y, x1 - x, 1)
      elseif code == F.WHITE then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", x, y, x1 - x, 1)
      elseif code == F.ERASE and layer.base then
        love.graphics.setColor(0, 0, 0, 0)
        love.graphics.rectangle("fill", x, y, x1 - x, 1)
      end
      x = x1
    end
  end
  love.graphics.pop()
  n_fronts = n_fronts + 1
  local atlas = { name = "ww_front_" .. n_fronts, image = canvas, px = F.W, py = F.H }
  G.ASSET_ATLAS[atlas.name] = atlas
  return atlas
end

local function where(sprite)
  return { atlas = sprite.atlas, pos = { x = sprite.sprite_pos.x, y = sprite.sprite_pos.y } }
end

-- Give a card the front its value calls for, or its own back. Called as the card is drawn, so a front follows
-- its card through every change (a Move, a copy, a rank change, a new enhancement, another palette) without
-- anything having to announce it. card.ww_front remembers what is showing, and the art it replaced.
local function dress(card)
  local front = card.children.front
  if not front or front.animation then return end
  local spec = WW.look_of(card)
  local showing = card.ww_front
  if not spec then
    if showing then
      front.atlas = live(showing.own.atlas)
      front:set_sprite_pos(showing.own.pos)
      card.ww_front = nil
    end
    return
  end
  local suit = card.base.suit
  local palette = palette_of(suit)
  local own = showing and showing.own or where(front)
  -- A canvas is good for one palette and one way of loading textures (their scale and filtering).
  local ref = G.ASSET_ATLAS.cards_1.image
  local min, mag = ref:getFilter()
  local key = spec.key .. "|" .. palette .. "|" .. G.SETTINGS.GRAPHICS.texture_scaling .. min .. mag
    .. tostring(ref:getMipmapFilter())
  local layer_tint = spec.mode == "omega" or spec.mode == "split"
  local body = layer_tint and card.children.center and where(card.children.center) or nil
  if body then key = key .. "|" .. body.atlas.name .. ":" .. body.pos.x .. ":" .. body.pos.y end
  if spec.mode == "base" then key = key .. "|" .. own.atlas.name .. ":" .. own.pos.x .. ":" .. own.pos.y end
  if showing and showing.key == key then return end
  local atlas = fronts[key]
  if not atlas then
    atlas = build(spec, ink_rows(spec, suit, palette), body, own)
    fronts[key] = atlas
  end
  front.atlas = atlas
  front:set_sprite_pos({ x = 0, y = 0 })
  card.ww_front = { key = key, own = own }
end

-- A card's front sprite is made anew whenever its base or the palette changes: what we remembered is gone.
local set_sprites = Card.set_sprites
function Card:set_sprites(center, front)
  local r = set_sprites(self, center, front)
  if front then self.ww_front = nil end
  return r
end

SMODS.DrawStep {
  key = "value_front",
  order = -1, -- just before the front (0) is drawn
  func = function(card) dress(card) end,
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
  if not full_UI_table and card and card.base and (WW.is_value(card) or green) then
    local value = WW.value_of(card)
    if value then
      local ranks = WW.ranks_of(card)
      if WW.has_mod(card) or green then
        -- The wild rank: a card that plays as every rank a standard deck has.
        local from_two = 0
        for _, r in ipairs(ranks) do if r >= 2 then from_two = from_two + 1 end end
        local mod = from_two == 14 and localize("k_ww_wild_rank")
          or (WW.has_mod(card) and pretty(WW.mod_of(card), true) or "*+* = 0")
        local key = green and "ww_modifier_green" or "ww_modifier"
        generate({ set = "Other", key = key, vars = { mod, pretty(value), ranks_text(ranks) } }, ui)
      else
        generate({ set = "Other", key = "ww_value", vars = { pretty(value), ranks_text(ranks) } }, ui) -- a plain ω
      end
      if WW.is_eater(card) then generate({ set = "Other", key = "ww_omega" }, ui) end
    end
  end
  return ui
end
