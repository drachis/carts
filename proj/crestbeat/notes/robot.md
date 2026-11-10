# robot.lua

**robot.lua:18** `function judge()`
`judge` grades a shot against the nearest whole beat: `perfect_window` frames, `good_window` frames, else miss. A second shot on a beat already shot is a miss.
Keep: the user asked for a rhythm game of fire on the beat; `test_rhythm` checks each window at its edge.

**robot.lua:26** `function shoot()`
`shoot` hits the front alien in the robot's lane on perfect or good; a miss ends the combo and does nothing else. An on-beat shot at an empty lane keeps the combo.

**robot.lua:95** `function draw_robot()`
`draw_robot` is hivefall's mech (24x24 at sheet (0,64)) drawn at 1.5x, black edge first, white while hurt. It bobs a pixel on the beat.
