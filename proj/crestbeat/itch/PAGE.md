# Crestbeat (itch.io page)

## Short description (the one-line field)

A giant red robot holds the bottom of the hill while aliens pour over the crest, and its guns fire on the beat.

## Page copy

**Your guns fire themselves on the beat. Your job is to be on the right street when it lands.**

You are a giant red robot at the foot of a hill. Aliens pour over the crest and down three streets toward you. There is no fire button: every gun shoots on its own rhythm, so you dance between the streets, left and right, putting the robot in front of the next alien just as the beat hits.

**Switch streets.** Anything that reaches the bottom costs you a heart. If it reaches the bottom in the street you're standing in, you body-block it: still a heart, but it counts as downed.

**Switch guns.** Five of them, each with its own rhythm. The minigun fires every half beat. The shock rifle fires on every beat. Rockets hit hard twice a bar and splash the aliens close behind the target. The flak cannon fires a 1-2-3, rest, and the plasma rifle a long two and a short three.

**Fight the giants.** A titan, a behemoth and the hive queen rise over the crest. Each one hides behind a honeycomb force field, one panel per street, and a panel flashes and falls away when that street opens. Shoot fast, keep moving, and don't stand still: anyone who stays in one street too long gets spat at.

**It's a shooting gallery.** Chase the golden alien as it glides across the streets. Don't shoot the civilians running for their lives. Ring a giant's bell with one shot on each of its streets before you break any of them. When the run ends, the cabinet pays out in tickets: a few for a short run, and 500 for a perfect one.

### Features

- About a minute and a half from the hill to the hive queen, nine stages of swarms, climbs and three giant fights
- Five guns, five rhythms, all firing to the music
- Hold down to see where the beat wants you next, and where the golden alien's route goes
- A neon city at sunset: a synthwave sky, a glowing grid road, and each giant haloed by the setting sun as it fights you
- Giants built from parts: flapping wings, stomping feet, cracks and smoke when you break a street
- A ticket payout at the end, counted up and thrown out of the slot

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

These come from the game's synthwave palette, so the page reads as the same neon night.

| Part of the page | Colour | Hex |
|---|---|---|
| Page background | Night navy | `#1D2B53` |
| Game column background | Black | `#000000` |
| Body text | Warm white | `#FFF1E8` |
| Links | Neon pink | `#FF77A8` |
| Buttons | Sun yellow | `#FFEC27` |
| Headings | Grid blue | `#29ADFF` |

Button text: black (`#000000`), 17:1 on the yellow. On the black column, body text is 19:1, links and headings 8.5:1.

**Second option, warmer:** dusk purple `#7E2553` for the page background and night navy `#1D2B53` for the game column, with the same text colour (12.5:1 on navy), sun-yellow links (11:1), sun-orange `#FFA300` headings (7:1), and neon pink `#FF77A8` buttons with black text (8.5:1). I prefer the first one: the black column frames the GIFs like a cabinet screen.

Font: a plain, rounded sans such as Rubik or Nunito. The GIFs already supply the pixels.

## Images

Upload order on the page:

1. `crestbeat_title.gif`: the title, the synthwave sun and the robot flying in
2. `crestbeat_hill.gif`: the core loop, the swarm over the hill and the golden alien
3. `crestbeat_titan.gif`: a giant fight: the titan haloed by the sun, the shields falling, the bell ringing, the titan going down
4. `crestbeat_streets.gif`: civilians and the golden alien on the streets
5. `crestbeat_queen.gif`: the hive queen (the last fight; a mild spoiler)
6. `crestbeat_payout.gif`: the ticket payout

Screenshots: the `.png` of each name. Cover image: `cover_630x500.png` (630x500), the title at 4x with its sky and grid carried out to the sides.

Re-record with `py itch/capture.py`; it moves PICO-8's files off the Desktop into this folder. The web build is `release/crestbeat_web.zip` (`py export.py`); set the itch embed to 512x512.
