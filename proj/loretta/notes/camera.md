# camera.lua

**camera.lua:11** `function camera_x()`
The whole-pixel camera, worked out from Loretta's rounded x, so her place on the screen is round(her x minus the view's), which moves smoothly; the background takes the uneven pixel steps. Rounding the camera and her separately made the whole dog wobble a pixel back and forth while she ran (test_motion counted 33 reversals in 110 frames).
**Keep:** test_motion fails if her place on screen reverses more than twice while she trots.

**camera.lua:15** `function update_camera(view,hero)`
dustroom's camera: eases after her, leads the way she runs, stops at the level's ends. It never moves up or down: the level is one screen tall.

**Framing**
The view centres between her and a chased squirrel only while it is within squirrel_safe px; beyond that it goes back to her. A hard clamp keeps her camera_margin px inside the screen whatever the view is doing.
**Keep:** the user: she can never be off screen; a squirrel out of the safe zone is not followed.
