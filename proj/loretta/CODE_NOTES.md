# Loretta code notes

Reference for an AI working on this cart: what the code does and what to
keep when changing it. The cart's Lua has no comments (PICO-8 caps a cart
at 65535 characters as well as 8192 tokens, and comments cost characters),
so everything a comment would say is in `notes/`, one file per module.
Read only the file for the module you are changing.

| Notes | Module |
|---|---|
| [notes/data.md](notes/data.md) | tuning, thing specs, stats |
| [notes/world.md](notes/world.md) | the two map strips, flags, slopes, spawning things |
| [notes/scenery.md](notes/scenery.md) | palette, sky, haze, hills, palms, the far observatory |
| [notes/loretta.md](notes/loretta.md) | her movement, sit, paddle, bark, hurt, drawing |
| [notes/things.md](notes/things.md) | coins, bones, squirrels, hydrants, neighbours, the observatory, barks, effects |
| [notes/camera.md](notes/camera.md) | the camera |
| [notes/main.md](notes/main.md) | modes, loop, screens, HUD, draw order, cartdata layout |

**Format.** Each note is headed

    **module.lua:N** `start of line N`

The quoted code is what the note is about; N is where it was last seen.
The body is short facts about that code. A **Keep:** line is a constraint
for future changes: behaviour the user asked for or tuned, or something a
test or another module relies on. Notes are in line order.

**Using them.** Before changing a function, open its module's notes file
and read the notes around it (grep for the function name in a quote).
Notes in one file can point at another module; follow those.

**Keeping them right.** Change a note in the same commit as its code.
`py notes_lines.py` checks that every heading's quote is still on its line;
`py notes_lines.py --fix` moves headings whose code only moved; a quote
found nowhere means the code changed, and the note and its quote need
rewriting by hand. A new note's heading is given its quote by
`py notes_lines.py --anchor`. A new module gets a new `notes/<module>.md`
and a row above. `py run_tests.py --no-comments` fails if a note is stale,
sits in the wrong module's file, or a comment is back in the Lua.
