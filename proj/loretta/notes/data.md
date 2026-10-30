# data.lua

**data.lua:10** `parse_record([[`
Every tuning value is a global from this record. Speeds are pixels a frame at 60fps, at the 2x scale (Loretta is 32x16).
**Keep:** the pace is a gentle trot on purpose: the user asked for "charm, not platforming excellence" and for the 2x view to stay reasonably paced.

**data.lua:22** `paddle_rise=-0.1`
paddle_lift and paddle_rise: while paddling, vy is pulled up by lift each frame but no higher than rise (a slight climb). The Yoshi flutter.
**Keep:** a hang, not a second jump; a lift of 0.4 / rise -0.3 at 1x made her rise 11px more than a held jump.

**data.lua:88** `function parse_table(text)`
parse_table keys each row by its tile number and by its name, so `thing_specs[21]` and `thing_specs.squirrel` are the same row; the row is the metatable of each thing spawned from it.

**data.lua:106** `thing_specs=parse_table[[`
dx, dy place a thing's box relative to its marker cell's top-left; w, h are its box (the sprite is drawn around it in its draw_ function). back=1 draws it behind the map.
**Keep:** the tiles are the marker sprites 16..23 gen_cart.py's LETTER_TILES writes.

**data.lua:200** `function apply_stats()`
The four stats choose the verbs' numbers: speed run_max, jump jump_a and paddle_frames, bark bark_reach, charm pet_hearts and pet_points. Upgrading a stat later is a change to `stats` then a call here.

**data.lua:143** `shapes={}`
Set pieces (props) are data: each a string of drawing steps separated by "/", a step's fields by spaces: r rectfill, b rect, l line (x0 y0 x1 y1 colour), c circfill (x y radius colour), t print (x y colour word). Coordinates are from the prop's marker cell's bottom-left, which is the ground, so up is negative. Parsed once at boot into `shapes`.
**Keep:** a word in a t step is one word (split on spaces); a new landmark is a row in thing_specs plus a line here, no code.
