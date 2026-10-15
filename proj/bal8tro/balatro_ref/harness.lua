-- harness.lua : drives a copy of the user's Balatro to each screen bal8tro
-- copies and saves a screenshot of it, for reference only. run_balatro_ref.py
-- builds the copy (never touching the install) and appends
-- `require "harness"` to its main.lua. Screenshots, harness.log and
-- motion.log go to the copy's own save folder, named after the harness exe,
-- not Balatro's.
--
-- motion.log, while logging is on, has one line per card per frame:
--   card <seconds> <sort_id> <area> <x> <y> <scale> <rotation>
-- x and y are the drawn position (VT) in card widths and heights from the
-- hand area's top left, so they compare with bal8tro's at any scale; and
--   hud <seconds> <chips> <mult> <score>   and   event <seconds> <name>
-- compare_motion.py turns these into tracks for plot_motion.py.

local function log(text)
  love.filesystem.append("harness.log", string.format("%6.1f %s\n", love.timer.getTime(), text))
end

local motion, logging = {}, false

local function mark(name)
  return function() motion[#motion + 1] = string.format("event %.3f %s", love.timer.getTime(), name) end
end

local function shot(name)
  return function() love.graphics.captureScreenshot(name .. ".png") log("shot " .. name) end
end

local function highlight(first, last)
  for i = first, last do G.hand:add_to_highlighted(G.hand.cards[i]) end
end

-- a pair if the hand has one, so the play scores two cards and jolly fires
local function highlight_pair()
  local seen = {}
  for i, card in ipairs(G.hand.cards) do
    local rank = card:get_id()
    if seen[rank] then
      G.hand:add_to_highlighted(G.hand.cards[seen[rank]])
      G.hand:add_to_highlighted(card)
      return
    end
    seen[rank] = i
  end
  highlight(1, 2)
end

-- seconds after launch, and what to do then
local steps = {
  {1, function()
    love.window.updateMode(960, 540, {fullscreen = false, borderless = false})
    if love.resize then love.resize(960, 540) end
  end},
  {1.5, shot("intro_joker")},
  {3.5, shot("intro_vortex")},
  {5, shot("intro_cards")},
  {6.5, shot("intro_flash")},
  {9, shot("menu")},
  {10, function()
    G.SETTINGS.tutorial_complete, G.SETTINGS.tutorial_progress = true, nil
    G.FUNCS.start_run(nil, {stake = 1, seed = "BAL8TRO"})
  end},
  {15, shot("blind_select")},
  {15.5, function() logging = true end},
  {16, function() mark("deal")() G.FUNCS.select_blind(G.blind_select_opts.small:get_UIE_by_ID("select_blind_button")) end},
  {21, shot("hand")},
  {21.5, function() mark("joker")() add_joker("j_joker") add_joker("j_jolly") end},
  {22.5, function() mark("pick_discard")() highlight(#G.hand.cards - 1, #G.hand.cards) end},
  {23.5, function() mark("discard")() G.FUNCS.discard_cards_from_highlighted() end},
  {26, function() mark("pick")() highlight_pair() end},
  {27, shot("hand_picked")},
  {28, function()
    mark("play")()
    G.GAME.chips = G.GAME.blind.chips
    G.FUNCS.play_cards_from_highlighted()
  end},
  {29.5, shot("scoring")},
  {41, shot("cash_out")},
  {42, function() mark("cash_out")() G.FUNCS.cash_out({config = {}}) end},
  {49, shot("shop")},
  {50, function() G.FUNCS.run_info() end},
  {52, shot("run_info")},
  {53, function() G.FUNCS.exit_overlay_menu() end},
  {54, function() G.FUNCS.deck_info() end},
  {56, shot("deck_info")},
  {57, function() G.FUNCS.exit_overlay_menu() end},
  {58, function()
    mark("pack_open")()
    G.GAME.dollars = 50
    G.FUNCS.use_card({config = {ref_table = G.shop_booster.cards[1]}})
  end},
  {63, shot("pack")},
  {64, function() mark("pack_skip")() G.FUNCS.skip_booster() end},
  {68, function() mark("shop_exit")() G.FUNCS.toggle_shop() end},
  {72, shot("blind_select")},
  {74, function() mark("select_blind")() G.FUNCS.select_blind(G.blind_select_opts.big:get_UIE_by_ID("select_blind_button")) end},
  {80, function()
    mark("lose_play")()
    G.GAME.current_round.hands_left = 1
    highlight(1, 1)
    G.FUNCS.play_cards_from_highlighted()
  end},
  {92, shot("game_over")},
  {95, function()
    mark("new_run")()
    G.FUNCS.start_run(nil, {stake = 1, seed = "BAL8TRO"})
  end},
  {101, function() mark("win")() win_game() end},
  {108, shot("win")},
  {111, function()
    logging = false
    love.filesystem.write("motion.log", table.concat(motion, "\n") .. "\n")
  end},
  {112, function() love.event.quit() end},
}

local function log_motion()
  local now, hand = love.timer.getTime(), G.hand
  if not hand then return end
  local left, top = hand.T.x, hand.T.y
  for name, area in pairs({hand = G.hand, play = G.play, jokers = G.jokers, discard = G.discard,
      shop_jokers = G.shop_jokers, shop_booster = G.shop_booster, pack = G.pack_cards}) do
    for _, card in ipairs(area and area.cards or {}) do
      local seen = card.VT
      motion[#motion + 1] = string.format("card %.3f %d %s %.3f %.3f %.3f %.3f", now, card.sort_id,
        name, (seen.x - left) / G.CARD_W, (seen.y - top) / G.CARD_H, seen.scale or 1, seen.r or 0)
    end
  end
  -- panels: ui <seconds> <name> <x> <y> in the same units, from their drawn top left
  for name, box in pairs({cash_out = G.round_eval, shop = G.shop, sign = G.SHOP_SIGN, blind_select = G.blind_select, overlay = G.OVERLAY_MENU}) do
    if box and box.VT then
      motion[#motion + 1] = string.format("ui %.3f %s %.3f %.3f", now, name,
        (box.VT.x - left) / G.CARD_W, (box.VT.y - top) / G.CARD_H)
    end
  end
  local current = G.GAME.current_round.current_hand
  motion[#motion + 1] = string.format("hud %.3f %s %s %s", now, tostring(current.chips), tostring(current.mult), tostring(G.GAME.chips))
end

-- the splash and menu entrance, every frame of the first 12 seconds:
--   splash <seconds> <state> <logo dissolve, 1 hidden to 0 shown> <cards>
--   intro <seconds> <x> <y> <scale> <facing>
-- x and y are each card's centre in card widths and heights from the
-- screen's centre; scale is its drawn width in card widths.
local function log_splash()
  local now, room = love.timer.getTime(), G.ROOM and G.ROOM.T
  if not room then return end
  local cards = 0
  for _, card in ipairs(G.I.CARD or {}) do
    local seen = card.VT
    if seen then
      cards = cards + 1
      motion[#motion + 1] = string.format("intro %.3f %.3f %.3f %.3f %s", now,
        (seen.x + seen.w / 2 - room.w / 2) / G.CARD_W, (seen.y + seen.h / 2 - room.h / 2) / G.CARD_H,
        seen.w * (seen.scale or 1) / G.CARD_W, tostring(card.facing))
    end
  end
  motion[#motion + 1] = string.format("splash %.3f %s %s %d %.3f", now, tostring(G.STATE),
    G.SPLASH_LOGO and string.format("%.3f", G.SPLASH_LOGO.dissolve or 0) or "-", cards, G.TIMERS and G.TIMERS.REAL or -1)
end

-- BAL8TRO_INTRO=1 runs only the splash and the menu's entrance: a
-- screenshot a second and the splash log for 20 seconds, then quits.
if os.getenv("BAL8TRO_INTRO") then
  steps = {{1, function()
    love.window.updateMode(960, 540, {fullscreen = false, borderless = false})
    if love.resize then love.resize(960, 540) end
  end}}
  for second = 2, 18 do steps[#steps + 1] = {second, shot("intro_" .. second)} end
  steps[#steps + 1] = {19, function()
    love.filesystem.write("intro.log", table.concat(motion, "\n") .. "\n")
  end}
  steps[#steps + 1] = {20, function() love.event.quit() end}
end

local started, next_step = love.timer.getTime(), 1
local game_update = love.update
function love.update(dt)
  game_update(dt)
  if love.timer.getTime() - started < 19 then
    local ok, message = pcall(log_splash)
    if not ok then log("splash failed: " .. tostring(message)) end
  end
  if logging then
    local ok, message = pcall(log_motion)
    if not ok then log("motion failed: " .. tostring(message)) logging = false end
  end
  local step = steps[next_step]
  if step and love.timer.getTime() - started >= step[1] then
    next_step = next_step + 1
    local ok, message = pcall(step[2])
    if not ok then log("step " .. (next_step - 1) .. " failed: " .. tostring(message)) end
  end
end
log("harness loaded")
