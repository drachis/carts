# Crestbeat (itch.io page)

## Short description (the one-line field)

A giant red robot holds a neon city at sunset as aliens pour over the hill, and its guns fire on the beat.

## Page copy

**Your guns fire themselves on the beat. Your job is to be on the right street when it lands.**

It's sunset in a neon city. You're a giant red robot at the foot of a hill, and aliens are pouring over the crest and down three streets toward you. There's no fire button: every gun shoots on its own rhythm, so you dance between the streets, left and right, putting the robot in front of the next alien just as the beat hits.

**Switch streets.** Anything that reaches the bottom costs you a heart. If it reaches the street you're standing in, you body-block it: still a heart, but it counts as downed.

**Switch guns.** Five of them, each with its own rhythm, sound and shot:

- the **minigun** brrts every half beat and throws brass off both pods
- the **shock rifle** cracks a lightning bolt on every beat
- **rockets** hit hard twice a bar, trailing smoke, and blast the aliens close behind the target
- the **flak cannon** booms a 1-2-3, rest, and sprays pellets
- the **plasma rifle** rides a long two and a short three on balls of plasma

**Fight the giants.** A titan, a behemoth and the hive queen rise over the crest with the setting sun behind their heads like a halo. Each hides behind a honeycomb force field, a panel per street, and a panel flashes and falls away when that street opens. Keep moving: stand in one street too long and the giant sends a twister of fire, lightning or acid down it.

**It's a shooting gallery.** Chase the golden alien as it glides across the streets. Don't shoot the civilians running for their lives. Ring a giant's bell with one shot on each of its streets, before you break any of them. Keep the combo going and the city catches fever.

**Then the cabinet pays out.** The tickets rain down over the screen in every colour, chiming up the scale as they fall: a few for a short run, 500 only for a perfect one.

### Features

- About two minutes from the hill to the hive queen: nine stages of swarms, climbs and three giant fights
- A synthwave and breakbeat soundtrack that follows the run: verses for the swarms, a chorus for each giant, a breakdown before the queen
- Five guns, five rhythms, all firing to the music
- A neon city at sunset: a glowing grid road, the sun reflected in it, and a halo of god rays behind every giant
- Fever at the top combo: the grid burns pink and the sun throws its rays
- Giants built from parts: flapping wings, stomping feet, cracks and smoke when you break a street, a flash and shockwaves when they fall
- Hold down to see where the beat wants you next, and where the golden alien's route goes
- A ticket payout with fireworks over the city you saved

### Controls

| Button | Action |
|---|---|
| Left / Right | Change street |
| X | Next gun |
| O (Z) | Previous gun |
| Down (hold) | Show the plan: where to be on the next beats |
| O or X | Start, and start again after the payout |

Made in PICO-8.

## Page colours

These come from the game's synthwave palette: the navy sky, the purple dusk, the pink grid and the yellow sun.

| Part of the page | Colour | Hex |
|---|---|---|
| Page background | Night navy | `#1D2B53` |
| Game column background | Black | `#000000` |
| Body text | Warm white | `#FFF1E8` |
| Links | Neon pink | `#FF77A8` |
| Buttons | Sun yellow | `#FFEC27` |
| Headings | Grid blue | `#29ADFF` |

Button text: black (`#000000`), 17:1 on the yellow. On the black column, body text is 19:1, links and headings 8.5:1. The navy page continues the GIFs' sky at their top edge, and the black column frames them like a cabinet screen.

**Second option, dusk:** purple `#7E2553` for the page background and navy `#1D2B53` for the game column, with warm white text (12.5:1 on navy), sun-yellow links (11:1), sun-orange `#FFA300` headings (7:1), and neon pink `#FF77A8` buttons with black text (8.5:1). It's warmer and closer to the sunset band, but the GIFs stand out less.

Font: a plain, rounded sans such as Rubik or Nunito. The GIFs already supply the pixels.

## Images

Upload order on the page:

1. `crestbeat_title.gif`: the title, the synthwave sun and the giant in silhouette, the robot flying in
2. `crestbeat_hill.gif`: the core loop: the swarm over the hill, the golden alien, the minigun
3. `crestbeat_titan.gif`: a giant fight: the titan haloed by the sun, the shields falling, a fire twister, the rockets
4. `crestbeat_streets.gif`: civilians and the golden alien on the streets, the shock rifle's lightning
5. `crestbeat_fever.gif`: fever at x4, the pink grid and the sun's rays, the flak cannon
6. `crestbeat_finale.gif`: a giant going down: the flash, the shockwaves, "giant down!"
7. `crestbeat_queen.gif`: the hive queen, her acid twister and the plasma rifle (the last fight; a mild spoiler)
8. `crestbeat_payout.gif`: the ticket rain and fireworks over the saved city

Screenshots: the `.png` of each name. Cover image: `cover_630x500.png` (630x500), the title at 4x with its sky and grid carried out to the sides.

Re-record with `py itch/capture.py`; it moves PICO-8's files off the Desktop into this folder. The web build is `release/crestbeat_web.zip` (`py export.py`); set the itch embed to 512x512.
