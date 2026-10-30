# world.lua

**world.lua:1** `function level_tile(cell_x,cell_y)`
A level is a list of chunks (data.lua levels, level_chunks for the one being played): each 32 by 16 tiles, chunk k at map x k%4*32, y k\4*16. Map rows 32..63 are the sprite sheet's lower half (gen_cart.py map_into_gfx), so there are sixteen chunks and sprites stop at 127. Every map read goes through here.
**Keep:** chunks are shared between levels and between places in a level, so nothing may mset them.

**world.lua:7** `function flag_at(x,y,flag)`
Flags: 0 solid, 1 semisolid, 2 water, 3 slope rising right, 4 slope rising left, 7 drawn by the map. A slope tile is solid only on and below its diagonal (dustroom's test). Outside the level's width is a wall.

**world.lua:15** `function area_has(x,y,w,h,flag)`
Samples a box every 4 pixels and at its far edges, so nothing 8px or wider slips between samples.

**world.lua:24** `function on_ledge(x,y,w,h,ignore_branches)`
Standing: solid just below the feet, or a branch whose top row is exactly below them (unless dropping through).

**world.lua:33** `function load_level()`
Turns every marker tile in the level's chunks into a thing; the markers stay in the map (chunks are shared) and are not drawn, having no flag 7. Rerun at every start. Neighbours in a level's first third are not loaded (cell_x>#level_chunks*11), so the treat comes after she has had a chance to lose hearts (the user's note).

**world.lua:46** `function draw_level(cam)`
Draws only the chunks the camera sees (two at most), with map's layer 0x80, which skips markers.
