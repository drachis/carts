# Witchcap retro

A look back at the session that built Witchcap, written from the chat and
the feedback in it. The last section sorts every lesson into what belongs
in the `pico8-game` skill for the next game and what belongs only here.

## What was built

From a seven-line pitch to a nine-level game in 38 commits, at 4396 of
8192 tokens. The pitch was a witch gathering mushrooms against a clock,
with lookalikes that punish haste. Everything else came out of playing:
the cauldron in the middle, Baba Yaga's hut as a giant following in the
backdrop, the moon as the clock, the forest as a cylinder, the broom, the
levels.

## How the feedback ran

The user played each build and sent notes while the next was being made:
about seventy notes in seventeen messages. Sorting them by kind says what
this user looks at.

| Kind of note | Examples | Share |
|---|---|---|
| How it looks | "why are the trees dandelions", the hut's legs, walk, turn and colours, bats, moon, witch frames | about half |
| How it plays | "cute but no longer a challenge", "hitting the edge kinda sucks", "a double punishment", levels, par | about a quarter |
| New things to add | the hut, broom, cackle, victory potion, music, foreground | about a fifth |
| How I was working | "check the pico8 docs", "can you catch this in the tests?", parallel tests, "I'm not sure you can run pico8 at 16x" | five notes |

Praise was rare and specific, and worth keeping a list of: "the look
alikes are good", "the moon was cool", "hell yeah excellent hut".

## What went well

- **One note, one commit.** Notes were written back as a numbered queue
  and taken in order, each tested and committed. When something broke, it
  was always the last step.
- **Bugs the user saw became tests that failed first.** The strip of sky
  under the ground when poisoned: 39 frames of 120 before the fix, none
  after. The gap between the hut's walls: 3 pixels, then none. Both tests
  read the screen with `pget`.
- **The pacing bot found a real bug.** Asked to "check the game pacing
  and difficulty", a bot was written to play whole runs. It stuck in 12
  of 20. Making it print where, then tracing one run, showed the witch
  never quite stopping after running left. The fix was in the game.
- **The test suite went from 75 seconds to 15** when the user asked for
  it, by running the carts at once and playing four frames for each one
  shown. After that it was run after every step without a second thought.
- **Checking the manual settled three things** before they were built
  on: how `tline` samples, what `coresume` returns on an error, and that
  PICO-8 has no speed setting.

## What went badly

Each of these cost the user something: a wait, a broken window on their
screen, or a rewrite.

- **Three inline patch scripts failed**, two of them half-applied. One
  left `endend` in the cart, which the user found as a syntax error. The
  shell halves backslashes, so a script searching for Lua's `\` operator
  never matches. The skill already said not to write such scripts.
- **Three runtime errors reached the user's screen** before any test
  caught them: the syntax error above, a test that drew before setting up
  the new hut, and the pacing cart reporting on a run before the game had
  started. The runner could only wait a minute and say "nothing printed".
- **The runner passed a cart that had printed an error**, because it
  looked for "ok" first. Found by accident while fixing something else.
- **Token counts in two commit messages were guesses**, and both were
  wrong.
- **The user's web export was committed without being noticed**, by
  staging the whole folder and reading only the top of `git status`.
- **The hut's legs took four tries**: sticks with bloomers, sheared
  textured lines, rotated textured lines, and at last solid shapes. The
  user said "dithered" after the second and again after the third. The
  third try should have been a different method, not a better version of
  the same one.
- **The hut's turn took three tries**: squashing one sprite, a face-on
  frame, and finally two faces of a box. The user supplied the idea that
  worked ("as if it is at 3/4").
- **The moon moved three times** because each place put it behind
  something. It ended up drawn last, over everything.
- **The first mushroom design was too easy and the second too hard to
  start on.** Six mushrooms with one obvious tell each was "cute but no
  longer a challenge"; sixteen with five wanted among seventeen imposters
  needed nine levels in front of it. The difficulty curve should have
  been asked about before either was built.
- **The level label, the pot arrow and the recipe collided in the status
  bar** more than once, because each was placed without laying out the
  whole bar.

## What is still not known

- Whether one-pixel differences can be read at a run. The bot never
  misreads, so its times say nothing about this.
- What the music and sounds are like. They have never been heard by the
  one who wrote them.
- Whether the pars are fair.
- Why writing a cart sometimes failed with "invalid argument" just after
  a test window closed. It happened twice and cleared on its own.

## Sorting the lessons

The first pass at updating the skill put too much of this game into it.
This is the sort, lesson by lesson.

### Generic: these are in the skill

Working:

- Notes keep arriving mid-build. Keep a numbered queue and finish the
  step in hand.
- Edit code with the edit tool. No patch scripts, and why they fail here.
- Count tokens before writing the commit message.
- Read all of `git status` before staging a folder.
- Start every shell command with a `cd` to the project.
- A project must live under PICO-8's carts folder or its tests' logs go
  elsewhere.
- Say every time that sound has not been heard.
- If the user doubts a claim about PICO-8, say what was actually done,
  check the manual, and give the measurement.

Testing:

- Run the carts at once, each with its own log.
- Play several frames of the game for each one shown.
- Catch a test cart's runtime errors in a coroutine and print them.
- A cart that never prints "started" did not load.
- Look for errors before looking for "ok".
- A visual bug the user saw can be a `pget` test that fails first.
- A test cart reads the player's real save; set what the test plays.
- Something placed by time may be off the screen in every screenshot.
- When a rule changes, change its test and delete what it made
  unreachable.
- "Check the pacing" is a request for numbers: write a bot.
- A bot's failures are the bot's until traced. Print where, then trace
  one case.
- A user's screenshot of an error is a failure of the tests too.

PICO-8:

- A negative number multiplied towards zero stops just short of it.
- `%` on a possibly negative number; a sum of frames overflowing.
- The manual-checked entries for `coresume`, `tline`, the music channel
  mask, `\`, `sgn(0)`, `sin`, and the display palette.

Design and art, stated as principles:

- When a fix draws the same complaint again, change the method.
- Shapes that rotate freely are better drawn solid than as stretched
  textures.
- Squashing one sprite through zero width reads as a flat card.
- Sprites with empty columns at their ends leave a gap where they meet.
- Decide which colours the player must pick out and keep them for that.
- A vertical shake shows what is under the level.
- Let the art script make variations of art.
- Lay out the whole status bar before adding to it.
- Ask how hard the first minute should be before building difficulty.

### Specific to Witchcap: these stay here

These were in the first pass at the skill and have been taken out. They
are recipes for this game, or one user's taste about one design.

- **The cylinder.** Never wrap positions. Every `x` is a plain number;
  only reading the map wraps (`mget((x\8+3840)%128,y\8)`), the map is
  drawn twice (at the camera's lap and the next), and
  `near(x)=x+flr((witch.x-x)/1024+0.5)*1024` gives the copy of a place
  nearest the witch for picking, drawing and pointing. Backdrop trees
  repeat twelve to a lap so that going round brings the same ones back.
- **The two-bone leg.** The knee is the midpoint of hip and ankle pushed
  out at right angles by `sqrt(bone*bone-half*half)`, times the turn so
  that it swings through straight.
- **The gait.** Each foot lifts once for every stride the hut travels,
  the two half a stride apart, and lands as far ahead as it lifted
  behind. The body eases towards the planted foot while the other swings,
  and towards the midpoint when both are down. Stopped, a foot more than
  ten pixels from its place steps back under.
- **Solid limbs.** Twenty-one `circfill`s from joint to joint, shrinking
  from one radius to the other, drawn in an edge colour and then a pixel
  smaller in the limb's own.
- **The box at three quarters.** The side is drawn `76*turn` wide and
  the front `64-40*turn`, the front at the end the hut walks towards,
  with three columns cropped from each sprite where they meet.
- **The moon as clock.** A shadowed disc, lit row by row from the left
  limb as far as `half*(share*2-1)`, drawn last.
- **Mushroom families.** Sixteen kinds as four families of four forms;
  each form after the first is a list of changed pixels; the leaning
  dance frame is the cap rows shifted one pixel over the stem.
- **Levels by imposters.** One family is left out of every recipe so
  that fillers are plainly something else; imposters are other forms of
  wanted families; wanted and imposter counts rise by level.
- **Pars from the bot.** About twice the time of a bot that stops three
  quarters of a second at each mushroom.
- **"A double punishment."** Poison cost time and also spoiled a
  mushroom; the user wanted one cost for one mistake. This is a call
  about this game. The general habit is only to ask what a mistake costs
  the player and whether it costs it twice.
- **"The big art of the game."** A giant character in the backdrop was
  worth a fifth of the tokens to this user. The next game's user, or
  this user's next game, may want something else.
- **This user's eye.** Half the notes were about how things look, and
  colour clashes were called out three times. Expect art direction early
  and often, and show screenshots of anything new.
