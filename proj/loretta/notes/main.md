# main.lua

**main.lua:1** `function _init()`
cartdata slot 0 is the best score, in tens.

**main.lua:14** `function start_level()`
Every start (title, play, retry) reloads the level and puts Loretta at the start marker; the start is also the first respawn point.

**main.lua:68** `function update_title()`
The title is the level's first screen, Loretta hopping now and then by herself, under the logo, menu and player card.

**main.lua:127** `function score_text(points)`
Scores are kept in tens and shown with a 0 added, seven digits as in the user's picture, so they stay far below 32767.

**main.lua:205** `function _draw()`
Draw order: backdrop, things behind the map (sign, observatory), the map, things, barks, Loretta, effects, then the HUD or title over everything.
