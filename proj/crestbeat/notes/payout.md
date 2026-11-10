# payout.lua

**payout.lua:19** `function start_payout(won)`
The ticket payout, after the run is won or lost (the game will be a ticket arcade cabinet). Each row of `payouts` (data.lua) whose stat is above 0 becomes a line: the count times `each` tickets (civilians hit take tickets off). The rows are points; a last row sums them, and the tickets paid are `top_tickets*(2^(ticket_curve*p)-1)/(2^ticket_curve-1)` with `p` the share of `perfect_points` (capped at 1). At least one ticket is always paid.
Keep: the user asked for an exponential ticket curve: about 300 possible with mistakes, 500 only for a perfect run. `perfect_points` is the sum of every stage's golden or bell route (the `points N golden` lines the stage carts print; 601): a clean plan win of 284 pays 154, plus the three bells 271, plus a golden alien or two over 300. `stats` is reset with the run and counted where things happen: kills and golds in `hit_alien`, civilians there too, bells and titans in titan.lua.
Keep: the user asked for the payout to follow bal8tro's cash-out, which they said does it super well: a panel that springs up, lines that arrive one at a time and count up, a total that rolls up evenly, things thrown out as it pays.

**payout.lua:37** `function update_payout()`
The panel springs from below the screen to `payout_rest` with `spring` and `damping` (bal8tro's glide, overshooting about 5px at 30fps). A line arrives every `row_frames` with a tick and counts up over `count_frames`; after the last, the total rolls up over `total_frames` (at least a ticket a frame), and each ticket counted is thrown from the slot at the bottom, a ka-chunk every other one. `payout_done` once every ticket is out; only then does a press start a new run.

**payout.lua:53** `if dispensed%2==0 then`
The ticket chime: before playing sfx 15 its chime and fifth (notes 1 and 2, at 0x35fe and 0x3600) get the next pitch from `chime`, keeping each note's waveform bits; so the chimes climb as tickets pour out. Tickets fall from above the screen and are drawn last, over the panel; `cheered` plays the fanfare once when the last is out.
Keep: the user asked for the tickets to rain over the UI, shimmering in many colours, and for a more delightful, charming ticket sound.
