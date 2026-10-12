# Hivefall

A heavy mech flies low over a city that covers a hillside and shoots *into*
the screen, while a bio-swarm crests the hill and comes down at it. The
mech is locked to the bottom of the screen; the city rolls under it as it
advances. Whatever gets past the mech is loose in the city, and the city
shows it. You steer left and right, hold one button to fire and tap the
other to cycle an Unreal-style arsenal; the guns lock on to whatever is in
the cone ahead of the mech.

What it takes from where:

- **MechWarrior:** weight, range brackets, reload times, heat and venting,
  jump jets, the alpha strike.
- **Geometry Wars:** the juice. Streets that ripple under shockwaves, line
  sparks, rings, shake, hit-stop, a kill-chain multiplier.
- **Tyranids:** the enemy. Swarms of small things, winged things, a
  segmented burrower, a clawed brute, a brood ship, a hive tyrant.
- **Doom (2016):** only the pulse gun is unlimited. The rest run on ammo
  that kills drop, so the big guns are spent, not lived in, and close kills
  pay best.
- **The pace:** slow, with "bombastic bursts". The burst is the alpha
  strike; the smaller lifts are drops, coolant, a fireball that throws a
  pack back up the hill, and a new gun each hill.

A wave is a **district** on screen (`district_names`): the mech flies in
from the suburbs to the capitol, and the towers grow from low houses to
three times the height on the way. The code says `wave`.

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
the middle as they recede, and the crest sags at the edges (`globe` is the
radius of the circle it follows) so the ground reads as the top of a
globe, with a lit rim along the horizon. Depths a little under 1 project below the mech, which is
how the city carries on to the bottom of the screen. The view slides a
quarter as far as the mech moves.

Draw order: sky, foes still behind the crest, the hill (which hides them),
streets, houses far to near, foes far to near, drops, aim, shots, mech,
fireballs and sparks, HUD.

**The city is the ground**, and is meant to read like a sim city laid on
a sphere: green land, grey roads, blocks of coloured towers, parks. It is cut into cells 20 across and 0.625 deep.
Roads run on both diagonals of that grid, at 45 degrees to the flight
path, drawn as lines that bend with the hill and ripple under shockwaves.
They leave diamonds between them, and each diamond (the cells where
column+row is even) holds a block of two towers, or, one in five, a park
of three trees. `draw_tower` draws each as a roof and a front wall; a fixed hash
of its column and row (`seed`) gives it a height, one of four wall and
roof colours, one of three window colours, a grid of windows when it is
near, and a mast with a blinking light or a box on the roof. `travel`
slides the rows toward the viewer while there is anything on the hill,
faster under boost, and eases to a stop when the hill is clear.

There is no city health bar: the towers show it. `city` runs from 100 to
0. Each tower has its turn, by `seed`: shortly before it falls it is
*damaged* (windows dark, a few lit orange by fire, a bite out of its top),
then it is a *ruin* (a third the height, scorched black, gutted so that from
above it is a grey rim round a dark inside, its top edge broken, a
little grey smoke). Parks burn black in the same order. At 70 a third of the city
is one or the other; at 10 it is rubble. Nothing on a tower flashes or
flickers, so damage is not mistaken for enemy fire; the only flash is the
near rows turning red for a moment when something gets in.

The mech is drawn with a black edge so it stands off the rooftops.

Sprites are 16x16 cells drawn with `sspr` at `size*scale`. A foe may have
`parts`: more cells drawn around its body, bobbing, mirrored on the right
(the brute's two claws, the tyrant's head and four claws). A `chain` is a
group whose members all weave along the same path, one behind the other
(the wyrm).

## The game

- **Controls:** left/right move. O fires while held. A tap of X is the next
  weapon (on release, skipping empty ones). O and X held together vent
  heat: it falls fast and the guns are silent meanwhile. Down sets off the
  alpha strike when its bar is full. Up boosts forward: the city rolls
  faster, every foe and drop closes faster, and the next group comes
  sooner. PICO-8 has only two action buttons, which a pad repeats across
  its face buttons, so the extra actions are on the d-pad or stick.
- **Safety:** after a refit (and at the start) fire must be let go once
  before the guns answer, so confirming an upgrade does not spend a round.
- **Aim:** the lock cone lies on the ground, so it bends with the hill:
  `cone_base` wide at the guns, widening by `player.cone` per unit of
  depth, out to the `range` of the gun in hand, where an arc in the gun's
  colour closes it. The nearest foe inside is locked (green brackets) and
  most shots home on it.
- **Weapons** (`weapon_specs`), issued one a hill and auto-equipped when
  issued: pulse (medium range, steady, unlimited), flak (short, seven
  shards), minigun (fast), shock (long, pierces a line), rocket (long,
  blast), redeemer (long, slow, one round, clears a third of the hill).
  Each has its own reload, so cycling through loaded guns beats waiting.
- **Which gun for which foe.** Three things make the choice matter:
  - *Armour:* a shot that does less damage than a foe's `armor` glances
    for a third, with a grey spark and a tick instead of a flash. The brute
    (4) shrugs off pulse, flak and minigun; the tyrant (1.5) shrugs off
    pulse and minigun but not flak.
  - *Weakness:* the gun named in a foe's `weak` does double: flak on
    wings, shock on wyrm segments, rocket on brutes, minigun on ships,
    redeemer on the tyrant.
  - *Flight:* pulse, minigun and shock home on what was locked. Flak,
    rockets and the redeemer fly straight at where the target was, so they
    suit the slow and the bunched and tend to miss a weaving wing; a
    rocket that meets nothing bursts where it was aimed.
  The lock brackets say which case the gun in hand is: yellow for a
  weakness, red for a glance, green otherwise.
- **Blasts:** a rocket or redeemer bursts in a fireball that swells white
  to red and leaves the spot burning for a moment. Whatever survives is
  thrown back up the hill and aside.
- **Ammo:** every gun but pulse holds `ammo` rounds, shown beside its icon;
  a dry gun drops back to pulse. A refit reloads everything.
- **Heat:** every shot adds heat; at 100 the guns lock until it falls to
  `restart_heat`. Venting gets there much sooner.
- **Drops:** a kill may leave a drop that slides down the hill; be under it
  when it reaches the mech's line. Bigger foes and kills made close
  (`z<2.2`) leave more. Plate when armour is low; otherwise ammo for a gun
  with room, the heavier the shell the rarer; a part-charge of alpha; or
  coolant, which clears heat and stops any building for four seconds.
- **Foes** (`enemy_specs`) that reach the mech's line are **body-blocked**
  if the mech is in the way: the foe is gone and its remaining health comes
  off the mech's armour, so a wounded foe is cheap to stop. Otherwise it
  is in the city, which loses half the foe's `bite`. Losing all armour or
  all of the city loses the game. Skitters and wings keep their line and
  run for the city; the wyrm, brute and tyrant close on the mech.
- **Spit:** brutes and the tyrant lob it at where the mech is (a red ring
  marks the landing). Move, or shoot it down. It does not hurt the city.
- **Ships and the tyrant** halt partway down and keep brooding until killed.
- **Combo:** kills within `combo_frames` chain; every fifth raises the
  multiplier, to x8.
- **Alpha strike:** points fill a bar (`alpha_cost`). Setting it off
  freezes the frame, then for three seconds every quick gun fires at
  anything on the hill, with no heat and no ammo spent. It ends when the
  hill is clear and does not carry into the next.
- **Hills** (`wave_specs`): eight, each a list of groups sent five seconds
  apart, sooner if the hill is empty. After each, a **field refit**: pick
  one of three upgrades (`upgrade_specs`), get 20 armour back and reload.
- **The tyrant** is hill eight: a health bar under the HUD, and when it
  dies it comes apart over two seconds and takes the rest of the swarm
  with it. That is the win.
- **The HUD** is a strip along the top: portrait, three bars on grey back
  plates (armour, heat, alpha), the icon of the gun in hand with its
  rounds and name, a pip per gun, score, multiplier, hill. The pilot's
  line sits just under it.

## Modules

| File | Owns |
|---|---|
| `data.lua` | Parsers and every data table |
| `world.lua` | Projection, sky, hill, city, sparks, rings, fireballs, popups |
| `foes.lua` | Spawning, movement, brooding, dying, drops, drawing |
| `mech.lua` | The mech, input, targeting, weapons, shots, alpha strike |
| `main.lua` | States, wave director, score, city damage, shop, HUD, callbacks |

## Tests

    py run_tests.py
    py count_tokens.py hivefall.p8

- `test_boot`: the real cart from frame one with only input and sound
  stubbed: title, start, a pacing bot that also boosts and vents, the shop
  forced open, the tyrant forced in and killed, an alpha strike, drops,
  the city falling, the win, a restart. Every screen is drawn and dumped
  (`boot_*.png`). It checks nothing crashes; it does not check that the
  game is winnable.
- `test_weapons`: each weapon against a foe standing in the cone (near,
  far, flying, big) wherever the weapon's range covers it, with the mech
  kept cool and loaded; prints frames to kill. Then a staged scene with
  every foe (`scene.png`) and the CPU it costs.
- `test_city`: the empty city drawn at 100, 70, 40 and 10 health
  (`city_*.png`) with the CPU each costs. Look at the pictures: it cannot
  tell whether the damage reads.
- `test_feel`: a crude bot plays three whole runs unhealed and prints a
  line per wave. It never boosts or vents. It measures how much is
  happening and whether a plain strategy survives. It does not measure fun.

Headless PICO-8 sometimes dies with an access violation; the runner
retries. It is PICO-8's, not the cart's.

## Not built yet, or not checked

- Every number in `data.lua` is tuned only against the bot, which wins two
  or three runs in three: it is probably too easy for a person who has
  learned it.
- CPU is about 50% with an empty hill and 70% with 24 foes and an alpha
  strike; the most the bot has seen is 34 foes, which is not measured.
- The sound effects and the two-channel music loop were written as numbers.
- Boost has no reward beyond time; nothing yet pays for pushing forward.
- Headless PICO-8 (`-x`, which the manual calls experimental) often dies
  with an access violation while running these tests, and the cause is
  not known. What was seen on 2026-10-11, on one build: the boot test
  crashed 30 runs of 30 launched by `run_tests.py`, and passed 5 of 5
  launched by hand from the shell with output sent to a file. Sending the
  runner's output to a file instead of a pipe did not stop it. Three
  causes were announced and each was wrong (how near a tower is drawn, a
  line printed per frame, the pipe). It has not been reported in real
  play. Until it is understood, a test that fails this way has not
  passed: say so rather than retry until it does.
- Whether the game holds 60fps on the user's machine. `stat(7)` reported
  60 in the empty-city test at about 55% `stat(1)`; with a full hill it
  has not been measured, and the manual does not say whether `stat(1)` is
  a share of a 60fps or a 30fps frame.
- No high score is saved.
