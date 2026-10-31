# L3 results: the template level, Night 1 on Night Life

_2026-10-31 · T-028 · D-0048, D-0050 · plan: `level-template-plan.md`_

## What was built

- **Title screen:** a new first entry, **Night 1: Night Life (the level)**.
- **Level file:** `game/levels/night_life.cfg`. Plain text, explains its own format. Jared edits it and presses Play again; no code.
- **Flow:** the map is shown and nothing can be built. **N** or the play button starts the night: two bars of drumsticks while you build, then the song from bar 1. No Start wave button after that.
- **Night Life's sections**, read off the waveform (96 bars at 130 BPM):

| Bars | Section | Kind | Tier | In the song |
|---|---|---|---|---|
| 1-8 | intro | push, 7 grunts | 1 | quiet intro, no drums |
| 9-24 | verse | push, grunts, runners, a Jammer | 2 | the groove |
| 25-32 | rise | lull | | the groove, muffled, opening into the drop |
| 33-48 | chorus | push, swarms, brutes, an Archer | 4 | the chorus |
| 49-56 | breakdown | lull | | the song's own quiet breakdown |
| 57-80 | groove | push, Shades, a Warden, everything | 5 | the groove again |
| 81-96 | finale | finale, field boss and escorts | 6 | the last chorus |

- **Lulls:** nothing spawns; the song dips and goes muffled, then opens up over the lull's last bar into the next push. The watchman says a tip the first time.
- **End:** song over and board clear: one card, then the results ("NIGHT SURVIVED"). Enemies still up when the song ends: the finale loops until they are gone.

## Bot runs (`game/tests/t_level.gd`)

Every section started on its bar (within one frame, 0.004 to 0.007 of a bar). The lulls reached full calm (650 Hz) and opened by the next push. Building before Start was refused.

| Bot | Result | Health | Notes | Song over to board clear |
|---|---|---|---|---|
| fair (70% notes, 70% parries) | survived | 14/20 | 60/77 | 15 s |
| sloppy (50%, 50%) | fell to the finale boss | 0/20 | 39/80 | |
| fair, first draft (groove 6, finale 8, 150 gold) | survived | 6/20 | 67/96 | 23 s |

Tuned from the first draft: start gold 150 to 200, groove tier 6 to 5, finale tier 8 to 6. Most of the damage comes in the finale boss fight; the pushes before it cost a fair bot one health or none.

Bug found and fixed on the way: looping the finale from the middle of the song file made the clock jump about 150 s ahead. The finale is now its own loop, swapped in when the song ends.

## For Jared's playtest

Collect the feedback here, as for the other milestones (INDEX rule 6). Things to look for:

1. Is two bars of sticks enough to build, or too much?
2. Do you hear the lulls without being told (muffled, quieter), and does the lift into the chorus feel like "here they come"?
3. Is the finale boss too strong for a first night?
4. Does the level file make sense to edit?
