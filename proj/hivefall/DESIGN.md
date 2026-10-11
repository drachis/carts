# Hivefall

A heavy mech advances up a city street toward a hill and shoots *into* the
screen, while a bio-swarm crests the hill and comes down at it. The city is
around and behind the mech: whatever gets past it is loose in the city. You
steer left and right, hold one button to fire and tap the other to cycle an
Unreal-style arsenal; the guns lock on to whatever is in the cone above the
mech.

What it takes from where:

- **MechWarrior:** weight and slowness. The mech accelerates, its footfalls
  shake the screen, weapons have range brackets and reload times, and
  everything is paid for in heat.
- **Geometry Wars:** the juice. A neon grid that ripples under shockwaves,
  line sparks, rings, shake, hit-stop, a kill-chain multiplier.
- **Tyranids:** the enemy. Swarms of small things, winged things, a
  segmented burrower, a clawed brute, a brood ship, a hive tyrant.
- **Doom (2016):** only the pulse gun is unlimited. The rest run on ammo
  that kills drop, so the big guns are spent, not lived in, and close kills
  pay best.
- **The pace:** slow, with "bombastic bursts". The burst is the alpha
  strike; the smaller lifts are drops, coolant and a new gun each wave.

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

Draw order: sky, foes still behind the crest, the hill (which hides them),
the grid, the street's buildings, foes far to near, drops, aim, shots,
mech, the front rooftops, effects, HUD. A foe behind the crest rises over
it, then hops down onto the slope.

While there is anything on the hill the mech advances: `travel` slides the grid's cross lines and
the buildings either side of the street toward the viewer, and eases to a
stop when the hill is clear. The street's buildings cannot be hurt, but the
city has a health bar, and each foe that gets in wrecks the front rooftop
where it went in (`ruin`): shorter, dark, broken-topped and burning.

Sprites are 16x16 cells drawn with `sspr` at `size*scale`. A foe may have
`parts`: more cells drawn around its body, bobbing, mirrored on the right
(the brute's two claws, the tyrant's head and four claws). A `chain` is a
group whose members all weave along the same path, one behind the other
(the wyrm).

## The game

- **Controls:** left/right walk. O fires while held. A tap of X is the next
  weapon (on release, skipping empty ones). O and X held together vent
  heat: it falls fast and the guns are silent meanwhile. Down sets off the
  alpha strike when its bar is full. Up boosts forward: the street rolls
  faster and every foe and drop closes faster, and the next group comes
  sooner. PICO-8 has only two action buttons, which a pad repeats across
  its face buttons, so the extra actions are on the d-pad or stick.
- **Safety:** after a refit (and at the start) fire must be let go once
  before the guns answer, so confirming an upgrade does not spend a round.
- **Aim:** the nearest foe inside the cone above the mech, out to the
  weapon in hand's `range`, is locked (green brackets). The cone and its
  range are drawn as dots. Most shots home on what was locked.
- **Weapons** (`weapon_specs`), issued one a wave and auto-equipped when
  issued: pulse (medium range, steady), flak (short, seven shards), minigun
  (fast), shock (long, pierces a line), rocket (long, blast), redeemer
  (long, slow, clears a third of the hill). Each has its own reload, so
  cycling through loaded guns is faster than waiting on one.
- **Ammo:** the pulse gun is unlimited. Every other gun holds `ammo`
  rounds, shown under its name; a dry gun drops back to pulse. A refit
  reloads everything.
- **Heat:** every shot adds heat; at 100 the guns lock until it falls to
  `restart_heat`.
- **Drops:** a kill may leave a drop that slides down the hill; be under it
  when it reaches the mech's line. Bigger foes and kills made close
  (`z<2.2`) leave more. Plate when armour is low, otherwise ammo for the
  emptiest gun, a part-charge of alpha, or coolant, which clears heat and
  stops any building for four seconds.
- **Foes** (`enemy_specs`) that reach the mech's line bite the mech if it
  is within reach, and otherwise damage the city for half as much. Losing
  either bar loses the game. Skitters and wings keep their line and run
  for the city; the wyrm, brute and tyrant close on the mech.
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
- Whether the city bar is under the right amount of threat: the bot loses
  none of it before wave four, and most of it by wave eight.
- No high score is saved.
