# robot.lua

**robot.lua:12** `function update_robot()`
`update_robot`: left/right change street; X is the next gun and O the one before (`equip`). There is no fire button.
Keep: the user's design: "ensure the robot and its reticle are on the right street when each beat lands"; X/O switch guns.

**robot.lua:35** `function update_gun()`
`update_gun`: the gun in hand fires each time `clock` crosses a multiple of its `every` (in beats: minigun 0.5, shock rifle 1, rockets 2). In the robot's street with a target it fires at once (perfect). Into an empty street it fires a dud and waits: if the robot reaches a street with a target within `good_window` frames, the shot lands late (half score, half knockback). A dud while aliens are on the hill ends the combo.
Keep: the user said 1/3s for a late shot is okay (`good_window` 10 frames at 30fps); `test_rhythm` checks each side of it and each gun's cadence.

**robot.lua:56** `function fire(judgement)`
`fire`: shock rifle pierces every alien in the street and the open hot spot; rockets splash `splash` on the front alien in each street beside. Knockback is per point of damage (`knock_per_damage`).

**robot.lua:106** `function draw_robot()`
`draw_robot` is hivefall's mech (24x24 at sheet (0,64)) drawn at 1.5x, black edge first, white while hurt. It bobs a pixel on the beat.
