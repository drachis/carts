# robot.lua

**robot.lua:17** `function update_robot()`
`update_robot`: left/right change street; X is the next gun and O the one before (`equip`). There is no fire button.
Keep: the user's design: "ensure the robot and its reticle are on the right street when each beat lands"; X/O switch guns.

**robot.lua:41** `function update_gun()`
`update_gun`: the gun in hand fires on each eighth note whose slot in its `pattern` is `x` (8 slots a 4/4 bar, the bar starting at `clock` 0; `fires_on`). In the robot's street with a target it fires at once (perfect). Into an empty street nothing fires; the robot's lights glow and it waits: if the robot reaches a street with a target within `good_window` frames, the shot lands late (half score, half knockback), unless the target is a civilian: passing through a civilian's street must never shoot them. An empty beat while aliens are on the hill ends the combo.
Keep: the user said 1/3s for a late shot is okay (`good_window` 10 frames at 30fps); `test_rhythm` checks each side of it and each gun's pattern. The flak cannon's 3/4 (`123_`) and the plasma rifle's `12_123` are the user's rhythms; the plasma's reading as `x.x.xxx.` is ours.

**robot.lua:61** `function fire(judgement)`
`fire`: every gun hits only the target in the robot's street (front alien, else the open hot spot). Keep: no pierce on the shock rifle; the user: "it looks weird and don't feel great". Rockets splash `splash` on the front alien in each street beside. Knockback is per point of damage (`knock_per_damage`).

**robot.lua:101** `function draw_robot()`
`draw_robot` is hivefall's mech (24x24 at sheet (0,64)) drawn at 1.5x, black edge first, white while hurt. It bobs a pixel on the beat.
