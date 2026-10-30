-- plain_sky.lua : stands in for scenery.lua in test carts that look at
-- Loretta, the level and its things, not the backdrop, so that the game
-- and the test fit 8192 tokens together. only test_scenes
-- and test_title include the real scenery.

function set_palette() end
function draw_backdrop() cls(1) end
