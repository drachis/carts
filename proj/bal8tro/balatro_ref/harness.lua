-- harness.lua : drives a copy of the user's Balatro to each screen bal8tro
-- copies and saves a screenshot of it, for reference only. run_balatro_ref.py
-- builds the copy (never touching the install) and appends
-- `require "harness"` to its main.lua. Screenshots and harness.log go to the
-- copy's own save folder, named after the harness exe, not Balatro's.

local function log(text)
  love.filesystem.append("harness.log", string.format("%6.1f %s\n", love.timer.getTime(), text))
end

local function shot(name)
  return function() love.graphics.captureScreenshot(name .. ".png") log("shot " .. name) end
end

-- seconds after launch, and what to do then
local steps = {
  {1, function()
    love.window.updateMode(960, 540, {fullscreen = false, borderless = false})
    if love.resize then love.resize(960, 540) end
  end},
  {9, shot("menu")},
  {10, function()
    G.SETTINGS.tutorial_complete, G.SETTINGS.tutorial_progress = true, nil
    G.FUNCS.start_run(nil, {stake = 1, seed = "BAL8TRO"})
  end},
  {15, shot("blind_select")},
  {16, function() G.FUNCS.select_blind(G.blind_select_opts.small:get_UIE_by_ID("select_blind_button")) end},
  {21, shot("hand")},
  {22, function() for i = 1, 2 do G.hand:add_to_highlighted(G.hand.cards[i]) end end},
  {23, shot("hand_picked")},
  {24, function()
    G.GAME.chips = G.GAME.blind.chips
    G.FUNCS.play_cards_from_highlighted()
  end},
  {25.5, shot("scoring")},
  {37, shot("cash_out")},
  {38, function() G.FUNCS.cash_out({config = {}}) end},
  {45, shot("shop")},
  {46, function() G.FUNCS.run_info() end},
  {48, shot("run_info")},
  {49, function() G.FUNCS.exit_overlay_menu() end},
  {50, function() G.FUNCS.deck_info() end},
  {52, shot("deck_info")},
  {53, function() G.FUNCS.exit_overlay_menu() end},
  {54, function()
    G.GAME.dollars = 50
    G.FUNCS.use_card({config = {ref_table = G.shop_booster.cards[1]}})
  end},
  {59, shot("pack")},
  {61, function() love.event.quit() end},
}

local started, next_step = love.timer.getTime(), 1
local game_update = love.update
function love.update(dt)
  game_update(dt)
  local step = steps[next_step]
  if step and love.timer.getTime() - started >= step[1] then
    next_step = next_step + 1
    local ok, message = pcall(step[2])
    if not ok then log("step " .. (next_step - 1) .. " failed: " .. tostring(message)) end
  end
end
log("harness loaded")
