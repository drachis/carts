Can this be stored (poked) in the data of the map tile? With tiles reaching a maximum capacity at the memory limit? 
Congestion model: per-road-tile agent count feeding back into commute cost — how cheaply can we track it without a per-tile counter every frame?
as long as we don't run into the SimCity4 issue with power / needs taking visible traffic capacity - those may need to have reserved "lanes"

I'd like this to be something that can be adjusted with a param. If a city is only 50 pop it may be okay to have more visible and then tune it down as it grows. The main goal is lively city it doesn't have to be visibly 100% accurate at 10,000 pop but it needs to feel correct. To work towards that everything visible at first and then we can Polish that down as needed. 
"How much aggregation is invisible? Simulate individually only what becomes visible traffic or an inspectable cause; aggregate the rest. This is also the main token lever — the more we can aggregate without the player noticing, the more sim depth fits in 8k."

One per unity of capacity - a school can serve N students, a business hires N people, ect - I might not be framing that quite right and that might run into simulation constraints. Good system to watch
Contract granularity: one contract per building, or per unit of capacity? Per-building is far cheaper and probably enough at this resolution.

Where does the polish reserve go first? Only ~820 is held back (10%), so spend it deliberately — likely congestion visuals (they reinforce the core loop) before disasters or sound. If it's not enough, trim a system, don't grow the cart.
We're going to spend this somewhere and I don't know where yet. I want to play the base game first. It's a polish budget because it's polish budget after playtesting. Hold this precious. I'm sure I'll think of something. It will be important.

The token estimation script seemed to save a lot of time as we iterated. Use that to delegate tasks to agents running other models and verify that they come in under budget.

As you work create a TaskList.md to track which work has been completed.
The goal is to work across parallel agents to create the game as designed within the technical constraints to reach fun and playable. I'm aiming to post it on itch.io after it has been play tested.

Create a .md file while working with any ideas or additions which could be incorporated into the game. I'm sure there is more that could be built and would be interesting. 

Playing the final version of citysim was fun and rewarding. There are a few bugs (subtracking numbers don't appear to work, the map overview details doesn't have a bg). BUt it's playable and entertaining which is great.
