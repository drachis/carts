# data.lua

**data.lua:29** `parse_record([[`
Tuning: `frames_per_beat` assumes a speed-15 note lasts 15*183 samples at 22050Hz (not in the manual); `sync_clock` covers the error. `wave_chart` is one character a beat.

**data.lua:1** `function parse_table(text)`
`stages` is not here: it is `levels.lua`, written by `levels.py` (the plan, the golden route and their checks). Edit `levels.py` and run it; never edit `levels.lua`.
