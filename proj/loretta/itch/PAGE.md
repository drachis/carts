# Loretta: Corgi Quest (itch.io page)

## Short description (the one-line field)

A corgi chases squirrels across Los Feliz at sunset, all the way up to Griffith Observatory.

## Page copy

**The squirrels were never going to get caught. Loretta has never once let that stop her.**

Loretta is a very good, very short corgi, and tonight she's walking home the long way: from Fred 62 on Hillhurst, through Barnsdall Park and Fern Dell, up the trails of Griffith Park, to the observatory on the hill.

There is just one problem. There are squirrels.

**Chase them.** Get close and they bolt, bounding away in big springy arcs with their tails flying behind them. Stay close and your score climbs. Fall behind and the points dry up. The longer the chase, the faster Loretta runs, ears back and tongue out.

**Bark. Hop the hedges. Tap down to belly-slide** at full speed for a burst that closes the gap.

**They always get away.** Up a tree or into a bush, every time. But squirrels drop coins when they're rattled, and the longer the chase, the more fall.

**Say hello to the neighbours.** Sit near one and they'll come over with a treat and a pat, pat, pat. It's good for your hearts. Stay a while and they'll keep patting, just because.

Nobody gets hurt in this game, except by falling in a pond. It's about the chase, the sunset, and a very good dog.

### Features

- Six short levels through real Los Feliz places, about 20 seconds each if you never stop to chase anything
- A corgi drawn and animated entirely in code: floppy ears, a waggling tongue, a belly that flops, and a sploot
- A sunset that deepens the whole way there, with the Hollywood sign and the observatory drawing closer
- An ending worth the walk: when you reach the observatory, look up

### Controls

| Button | Action |
|---|---|
| Left / Right | Run |
| O (Z) | Jump, hold to jump higher |
| X | Bark |
| Down | Sit. While running, belly-slide |

Made in PICO-8.

## Page colours

These come from the game's own sunset palette, so the page reads as the same evening.

| Part of the page | Colour | Hex |
|---|---|---|
| Page background | Night navy | `#111D35` |
| Game column background | Dusk plum | `#422136` |
| Body text | Warm white | `#FFF1E8` |
| Links | Sun orange | `#FFA300` |
| Buttons | Marquee pink | `#FF77A8` |
| Headings | Coin yellow | `#FFEC27` |

Button text should be night navy (`#111D35`), since white on that pink is hard to read.

**Second option, warmer:** use mauve `#754665` for the page background and navy `#111D35` for the game column, so the game sits in a dark frame, with the same text and accent colours. I prefer the navy first option: it makes the sunset in the GIFs glow.

Font: a plain, rounded sans such as Nunito or Rubik. Pixel fonts look nostalgic but tire the eye over a whole page, and the GIFs already supply the pixels.

## Images

Upload order on the page:

1. `loretta_chase.gif`: the chase, the best first impression
2. `loretta_hills.gif`: rolling hills
3. `loretta_pet.gif`: a neighbour's pats
4. `loretta_finale.gif`: the ending (a spoiler; leave it out if you want it to be a surprise)
5. `loretta_title.gif`: the title screen, sitting

Screenshots: the `.png` of each name. For the cover image, `loretta_chase.png` is the strongest, but itch covers are 630x500, so it needs cropping or a frame.

Re-record with `py itch/capture.py`. PICO-8 saves to the Desktop; move the files here.
