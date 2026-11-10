# robot.lua

**robot.lua:17** `function update_robot()`
`update_robot`: left/right change street; X is the next gun and O the one before (`equip`). There is no fire button.
Keep: the user's design: "ensure the robot and its reticle are on the right street when each beat lands"; X/O switch guns.

**robot.lua:42** `function update_gun()`
`update_gun`: the gun in hand fires on each eighth note whose slot in its `pattern` is `x` (8 slots a 4/4 bar, the bar starting at `clock` 0; `fires_on`). In the robot's street with a target it fires at once (perfect). Into an empty street nothing fires; the robot's lights glow and it waits: if the robot reaches a street with a target within `good_window` frames, the shot lands late (half score, half knockback), unless the target is a civilian: passing through a civilian's street must never shoot them. An empty beat while aliens are on the hill ends the combo.
Keep: the user said 1/3s for a late shot is okay (`good_window` 10 frames at 30fps); `test_rhythm` checks each side of it and each gun's pattern. The flak cannon's 3/4 (`123_`) and the plasma rifle's `12_123` are the user's rhythms; the plasma's reading as `x.x.xxx.` is ours.

**robot.lua:62** `function fire(judgement)`
`fire`: every gun hits only the target in the robot's street (front alien, else the open hot spot). Keep: no pierce on the shock rifle; the user: "it looks weird and don't feel great". Rockets splash `splash` on the front alien in each street beside. Knockback is per point of damage (`knock_per_damage`).

**robot.lua:102** `function draw_robot()`
`draw_robot` draws the robot 1:1 at 36x36 (art.py's `robot`, seen from behind), black edge first, white while hurt, its lights (9, a) in the gun's colour on an empty beat. It bobs a pixel on the beat.

**robot.lua:129** `function from_map(size,draw)`
The robot's pixels live in the map's top half (0x2000, which this game has no map for; gen_cart's build_map writes them there in sprite-sheet layout). For each of its rows this saves the sheet's top-left corner to upper memory (0x8000), copies the robot's row over it, runs `draw`, then puts the corner back. That corner holds swarm sprites, all drawn earlier in the frame.
Keep: the user asked to use the map's half for sprites rather than scale the robot; the manual lets 0x5F54 map the sheet only to 0x00 or 0x60, so the pixels are copied in. test_rhythm checks the sheet is restored.
