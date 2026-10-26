# Demo 1 plan: the 3D build (proposed, 2026-10-26)

Live copy for markup: Claude Doc "Demo 1 plan: the 3D build" (https://claude.ai/artifact/VvzwoiGexB1jCzuU2Cd35S). Status: proposed, waiting on Jared's answers to the open questions and his "go" (D-0042 proposed).

Jared's call after M7 playtest 3: Demo 0 is done, the core loop is liked, parries and counters may change with distance and graphics, balance after. Goal: a private demo for a few friends and colleagues, the 20 waves with graphics and music, synthy note sounds.

## Read

Not rushing, on one condition: the rules stay separate from the picture (the sim/view split) so playtests and balance continue on the 3D build from its first week. No new towers, bosses or multiplayer before the picture exists.

## Milestones

| # | Milestone | Playable result | Size (sessions) |
|---|---|---|---|
| M8 | Look test | One throwaway 3D scene: board, one tower, one creep, a ring above the tower, camera at 60/65/70 degrees, perspective vs orthographic, three free asset packs side by side, the three-rings-in-a-row clutter case. Jared picks from screenshots | 1 |
| M9 | The split | The 20-wave run in 3D on the chosen look. Sim (rules, no drawing, on BeatClock) and view (3D scene reading the sim each frame). M2 to M7 scripts collapse into one run plus the data files; bots become the regression suite. Playtests and balance resume here; parry and counter clutter first | 3 to 4 |
| M10 | HUD and menus | Title, run select, settings (calibration, volumes, window, key hints), in-run HUD as scenes with one Theme, pause, end screen with the wave log, credits | 2 |
| M11 | Sound and music | Jared's synthy note sounds through the sound-sheet file names (D-0031), music bed, VOiD1 credit and contact (T-020) | 1 plus GarageBand time |
| M12 | Package | Mac (ad-hoc signed plus a right-click-Open instruction, or Developer ID) and Windows builds, private itch.io page, how-to-play page, run log copyable from the end screen, balance pass from the first friends' logs | 2 |

## Assets (recommendation: free CC0 first)

Kenney Tower Defense Kit and Castle Kit (CC0); KayKit Medieval packs (CC0 free packs, closest to Jared's reference watchtower); Quaternius monsters and characters (CC0, animated); Synty POLYGON only if the free look falls short (paid, per-seat, source files out of git). Sounds by Jared; music VOiD1 (owned, ships in games, no WAV redistribution). All packs stay out of the public repo; `notes/asset-licenses.md` gets an entry per pack.

## Engineering notes

Camera3D fixed, tilt from M8, one directional light, flat shading, no shadows at first; a tile is one metre; board clicks are a ray to the ground plane. Indicators (rings, locks, parry ring, counter flash, health bars) are billboards above their owner. HUD stays Controls, moved from code into scenes with a Theme. Risk: drift of a rule while its drawing moves; the bots and the run log catch it.

## Open questions for Jared (recommendation in brackets)

1. Asset source (free CC0 first). 2. Style: flat-shaded low-poly (yes). 3. Tilt: 60 to 70 or the reference's steeper 3/4 (decide from M8 screenshots). 4. One map or several (one). 5. Current roster for the 20 waves (yes). 6. Collapse the milestone scripts, drop menu keys 1 to 6 (yes). 7. Mac signing (ad-hoc for friends). 8. A date (none known). 9. The name for the title screen. 10. The Conductor as marker or character (marker now).
