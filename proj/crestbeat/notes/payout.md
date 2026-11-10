# payout.lua

**payout.lua:1** `function start_payout(won)`
The ticket payout, after the run is won or lost (the game will be a ticket arcade cabinet). Each row of `payouts` (data.lua) whose stat is above 0 becomes a line: the count times `each` tickets (civilians hit take tickets off). At least one ticket is always paid. `stats` is reset with the run and counted where things happen: kills and golds in `hit_alien`, civilians there too, bells and titans in titan.lua.
Keep: the user asked for the payout to follow bal8tro's cash-out, which they said does it super well: a panel that springs up, lines that arrive one at a time and count up, a total that rolls up evenly, things thrown out as it pays.

**payout.lua:19** `function update_payout()`
The panel springs from below the screen to `payout_rest` with `spring` and `damping` (bal8tro's glide, overshooting about 5px at 30fps). A line arrives every `row_frames` with a tick and counts up over `count_frames`; after the last, the total rolls up over `total_frames` (at least a ticket a frame), and each ticket counted is thrown from the slot at the bottom, a ka-chunk every other one. `payout_done` once every ticket is out; only then does a press start a new run.
