# Hivefall

A heavy mech holds the bottom of the screen and shoots *into* it, while a
bio-swarm crests a city on a hill and comes down the slope at you. You
steer left and right, hold one button to fire and tap the other to cycle
an Unreal-style arsenal; the guns lock on to whatever is in the cone above
the mech.

What it takes from where:

- **MechWarrior:** weight and slowness. The mech accelerates, its footfalls
  shake the screen, weapons have range brackets and reload times, and
  everything is paid for in heat.
- **Geometry Wars:** the juice. A neon grid that ripples under shockwaves,
  line sparks, rings, shake, hit-stop, a kill-chain multiplier.
- **Tyranids:** the enemy. Swarms of small things, winged things, a
  segmented burrower, a clawed brute, a brood ship, a hive tyrant.
- **The pace:** slow, with "bombastic bursts". The burst is the alpha
  strike.

## Rules of the build

1. Data is strings parsed at boot (`data.lua`); a new weapon, enemy,
   upgrade or wave is a line of data.
2. Objects inherit from their data rows (`setmetatable(object,row)`).
3. Art, sound and music are drawn as text in `gen_cart.py`, which rewrites
   every cart's `__gfx__`, `__sfx__` and `__music__`. Look at `sheet.png`.
4. PICO-8 is the only token counter (`py count_tokens.py hivefall.p8`).
5. The game runs at 60fps (`_update60`). Anything that only counts down is
   clamped with `max()`: a counter left to fall wraps round after nine
   minutes.

## The picture

`project(x,z,h)` in `world.lua` is the whole 2.5d. `z` is depth, from 1 at
the mech's line to `far_z` (6) at the crest; `x` and `h` are pixels as they
would appear at the mech's line. Things shrink to 30% and close up toward
the middle as they recede, and the crest sags at the edges so the ground
reads as a hill. The view slides a quarter as far as the mech walks.

Draw order: sky, foes still behind the crest, the city and hill (which
hide them), the grid, foes far to near, aim, shots, mech, effects, HUD.
A foe behind the crest rises until it stands on the rooftops at `far_z`,
then hops down onto the slope over the next unit of depth. The city cannot
be hurt.

Sprites are 16x16 cells drawn with `sspr` at `size*scale`. A foe may have
`parts`: more cells drawn around its body, bobbing, mirrored on the right
(the brute's two claws, the tyrant's head and four claws). A `chain` is a
group whose members all weave along the same path, one behind the other
(the wyrm).

## The game

- **Controls:** left/right walk. Z (O) fires while held. X cycles weapons,
  or, when the alpha bar is full, sets off the alpha strike.
- **Aim:** the nearest foe inside the cone above the mech, out to the
  weapon in hand's `range`, is locked (green brackets). The cone and its
  range are drawn as dots. Most shots home on what was locked.
- **Weapons** (`weapon_specs`), issued one a wave and auto-equipped when
  issued: pulse (medium range, steady), flak (short, seven shards), minigun
  (fast), shock (long, pierces a line), rocket (long, blast), redeemer
  (long, slow, clears a third of the hill). Each has its own reload, so
  cycling through loaded guns is faster than waiting on one.
- **Heat:** every shot adds heat; at 100 the guns lock until it falls to
  `restart_heat`.
- **Foes** (`enemy_specs`) reach the mech's line and bite if it is within
  reach, then are gone. Most close on the mech over the last stretch.
  Brutes and the tyrant lob spit that lands where the mech stood (a red
  ring marks it): walk out of it, or shoot it down. Ships and the tyrant
  halt partway down and keep brooding until killed. A bite gives half a
  second in which further bites do nothing, and breaks the combo.
- **Combo:** kills within `combo_frames` chain; every fifth raises the
  multiplier, to x8.
- **Alpha strike:** points fill a bar (`alpha_cost`). Setting it off
  freezes the frame, then for three seconds every quick gun fires at
  anything on the hill, with no heat.
- **Waves** (`wave_specs`): eight, each a list of groups sent five seconds
  apart, sooner if the hill is empty. After each, a **field refit**: pick
  one of three upgrades (`upgrade_specs`) and get 20 armour back.
- **The tyrant** is wave eight: a health bar, and when it dies it comes
  apart over two seconds and takes the rest of the swarm with it. That is
  the win. Armour at zero is the loss.
- **The pilot** (portrait, top left) calls out new weapons, overheating,
  low armour, a ready alpha strike and the boss.

## Modules

| File | Owns |
|---|---|
| `data.lua` | Parsers and every data table |
| `world.lua` | Projection, sky, city, grid, sparks, rings, popups |
| `foes.lua` | Spawning, movement, brooding, dying, drawing |
| `mech.lua` | The mech, targeting, weapons, shots, alpha strike |
| `main.lua` | States, wave director, score, shop, HUD, callbacks |

## Tests

    py run_tests.py
    py count_tokens.py hivefall.p8

- `test_boot`: the real cart from frame one with only input and sound
  stubbed: title, start, a pacing bot, the shop forced open, the tyrant
  forced in and killed, an alpha strike, both endings, a restart. Every
  screen is drawn and dumped (`boot_*.png`). It checks nothing crashes; it
  does not check that the game is winnable.
- `test_weapons`: each weapon against a foe standing in the cone (near,
  far, flying, big) wherever the weapon's range covers it, with the mech
  kept cool; prints frames to kill. Then a staged scene with every foe
  (`scene.png`) and the CPU it costs.
- `test_feel`: a crude bot plays three whole runs unhealed and prints a
  line per wave. It measures how much is happening and whether a plain
  strategy survives. It does not measure fun.

Headless PICO-8 sometimes dies with an access violation; the runner
retries. It is PICO-8's, not the cart's.

## Not built yet, or not checked

- Nobody has played this build. Every number in `data.lua` is a first
  guess tuned only against the bot.
- The sound effects and the two-channel music loop were written as numbers
  and have not been heard.
- Whether left/right alone is enough to do: the spit is the only thing
  that asks for a dodge.
- No high score is saved.
