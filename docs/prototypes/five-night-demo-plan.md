Claude Doc: https://claude.ai/artifact/Y8KwNrVyJfqgTH7MV3iNmg (this file mirrors it; the Claude Doc is the live version until Jared's markup is in)

# Five-night demo build plan (T-039)

2026-11-03 · draft for Jared's markup

Every design piece is locked on paper: progression (D-0059), enemies (D-0061), art (D-0060), UI (D-0062 to D-0065). This is the scope-lock gate from `notes/demo-plan-2026-10-31.md`. After Jared's go, new ideas go to the backlog. One milestone at a time, each ending with a playtest and `docs/prototypes/B#-results.md`; rule 6 applies between milestones. Nothing is balanced before B5.

## Scope
In: five nights (one song each, health carries over, retry a night for testing); Arrow, Cannon, Frost, Lightning, Poison, Light plus walls; Q and E notes, parry, stagger, counter; locked talent tree (10 points, 22 nodes, between nights), 4 card picks with new rarities, fork-then-mastery upgrades; 8 renamed enemies, 6 new ones, The Foreman, The Night Manager, The Landlord; per-map no-build zones replacing the reach rule and mine radius; KayKit night look; new HUD and menus with run stats and Copy; synthy note sounds.
Out (backlog): endless, multiplayer, custom models and new art style, community songs, full sound pass, iPad, tower balance beyond the five nights.

## Milestones
| # | Milestone | What goes in | Test |
|---|---|---|---|
| B1 | Campaign shell and progression | Night-to-night flow, health carryover, retry; tower renames in code; locked talent tree; in-night unlocks removed; fork-then-mastery upgrades; card list with new rarities | Night 1 twice as a two-night campaign |
| B2 | Enemies | New names, Door-to-Door, Last Orders, Busker, Digger, Undertaker, Moths, The Foreman, The Landlord; notes target boss/elite in view | Test arena that spawns any enemy; bots |
| B3 | Nights 2 to 5 | Level file and map per night; no-build zones; reach rule and mine radius removed; Night 1 lighter roster | Night picker; full run |
| B4 | KayKit night look | Packs, lighting, camp, enemies by weapon and shield, staged towers, effects | Readability check, boss clutter |
| B5 | Balance | Bots at three skill levels per night, five nights as one curve, then Jared's full runs | Full runs with copied stats |
| B6 | Private demo build | Synth note sounds, credits, Mac and Windows builds, VOiD1 contact (T-020) first | First players |

Order: progression first (nights are tuned around it), enemies before nights, look before balance (D-0060), balance last. Alternative considered: build Night 2 end to end first; rejected because it revisits the shell and look every night.

## Open calls (recommendation first)
- Night 5 longer song (D-0049): overtime boss fight past Flanger Party into a boss song (recommended), or move Night Life to Night 5.
- Fork masteries are drafts: lock after the B1 playtest (recommended) or now.
- Synth note sounds: B4 with the look (recommended) or B6.
