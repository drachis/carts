# world.lua

**world.lua:3** `function level_tile(cell_x,cell_y)`
The level is 256 tiles wide: columns 0..127 are map rows 0..15, columns 128..255 are map rows 16..31 (gen_cart.py build_map). Every map read goes through here.

**world.lua:8** `function flag_at(x,y,flag)`
Flags: 0 solid, 1 semisolid, 2 water, 3 slope rising right, 4 slope rising left. A slope tile is solid only on and below its diagonal (dustroom's test). Outside the level's width is a wall.

**world.lua:16** `function area_has(x,y,w,h,flag)`
Samples a box every 4 pixels and at its far edges, so nothing 8px or wider slips between samples.

**world.lua:25** `function on_ledge(x,y,w,h,ignore_branches)`
Standing: solid just below the feet, or a branch whose top row is exactly below them (unless dropping through).

**world.lua:34** `function load_level()`
Reloads the map, then turns every marker tile into a thing and clears it. Rerun at every start.

**world.lua:48** `function draw_level()`
The two strips drawn side by side, the second at x 1024.
