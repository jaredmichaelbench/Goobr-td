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

## Playtest 1 (Jared, 2026-10-31 13:27Z), collected, not acted on

- "This new direction feels a lot better than a 20 second wave."
- Difficulty felt right: a bad build, panicking, missed notes, tight, but he made it. No balancing asked for.
- The boss lasted forever (partly his play). It still walks very slowly and, once the pushes are done, creeps toward the towers. Idea: move faster but pause now and then, same time down the map. **To analyse: boss behaviour.**
- Missing notes in a boss fight drops the music and kills the epic feel. A boss should feel epic whether you are winning or losing; streaks are meant to add to it, misses should not take away. **To discuss.**
- Sound effects still off: notes, parries and the rest need a proper sound pass to make the game satisfying.
- He may have played without copying Night Life into `game/audio` (it was likely already there from Demo 1); next test confirms.

Run log, attempt 1 (Jared, pasted 13:28Z):

```
NIGHT SURVIVED   Night 1: Night Life
Time 3:52   Health 14/20   Gold earned 375
Notes 68 hit of 114 (59%)   Perfects 35
Parries 28 of 40   Towers locked 5   Shields lost 3   Restores 0
Calls nailed 9 of 20   Staggers 4
Boss: 32 bolts, 0 stomps, 4 breaks
Picks: Thinning
Level 10   XP 231   Talents 0 (none)
Type upgrades: Cannon 2   Unlocked: Lightning, Light
Crits 0   Arcs 0   Poison 0   Counters 0 of 28
W6  notes 68/114  parries 28/40  counters 0/28  hp -6
```

Read (Claude): about 55 s past the song's end, so the boss fight ran long. Nine talent points unspent, counters 0 of 28. Only one wave line: the board never fully cleared between pushes, so the whole night logged as one wave.

## Playtest 1, attempt 2 (Jared, 2026-10-31 13:45Z), collected, not acted on

UI and look:
1. The opening "N or the play button starts the night" line should be a pop-up: Start the night as its button, the explainer text, a way to minimise it to study the map and an easy way to bring it back. The line can stay as the "why you can't build" message, but the first load must make it clear you are locked until you start.
2. UI pass needed, later: tower upgrades are hard to see without studying, the upgrade button is in two places, and every menu item shares one look so nothing stands out.
3. The top and bottom paths run right up to the HUD bars; the board may need a buffer.
4. Grid lines only while building (WC3 style). Art decision, later pass.
5. Watch item: maybe too much start gold; he built 9 towers quickly at the start.

Gameplay:
1. Easier this time, probably because he built near the spawn. Discussion only: a build range (for example within 5 tiles of the base and 3 of a wall) to stop spawn camping. Limited build time does not solve it: even 1 second is enough for most players.
2. Still missing many notes, even as the designer: the window, or juggling parries and two note types at once? The boss still does not feel exciting (as in attempt 1).
3. Talents felt distracting, and the card shown in a lull (the push-cleared card with "LEVEL n, talent points to spend") made him think the level had ended or he was in the wrong mode. Something needs to change.

```
NIGHT SURVIVED   Night 1: Night Life
Time 2:27   Health 18/20   Gold earned 461
Notes 40 hit of 60 (66%)   Perfects 25
Parries 13 of 23   Towers locked 8   Shields lost 3   Restores 0
Calls nailed 10 of 17   Staggers 3
Boss: 16 bolts, 0 stomps, 1 breaks
Picks: Tar walls
Level 10   XP 237   Talents 8 (Sharpen 3, Reach 3, Workshop, Resonance)
Type upgrades: none   Unlocked: Poison, Lightning, Light
Crits 0   Arcs 0   Poison 0   Counters 0 of 10
Stats: damage +15%, range +0.4
W1  notes 1/6  parries 0/0  counters 0/0  hp -0   |   W2  notes 3/5  parries 1/1  counters 0/1  hp -0
W4  notes 9/11  parries 2/2  counters 0/1  hp -0   |   W5  notes 14/14  parries 2/4  counters 0/1  hp -0
W6  notes 13/24  parries 8/16  counters 0/7  hp -2
```

Read (Claude): the boss went down in one break this time (16 bolts vs 32). Counters 0 of 38 across both runs: nobody lands the tap after a parry, so either it is not seen or the window is too tight. The intro push gave 6 notes and he hit 1, while building.

## Playtest 1, attempt 3 (Jared, 2026-10-31 14:05Z), collected, not acted on

- Same problems. Tower spam saves you from danger, so the economy is the biggest feedback now.
- The slow boss stands out more each run: it is still far from the base, there is no danger, and you just hope to land notes so it ends sooner.
- He did not try the counter at all (so the 0 counters across all runs are not a window problem).
- Asked: is the boss timed to reach the end with the song, and how do slow towers change that? Answer (Claude): no. The boss walks 0.4 tiles a second whatever the song, Frost slows and freezes it like any creep, it stops during a Crescendo, and it never leaks (at the keep it stands and fights). On a long maze it needs minutes, while the finale is about 30 s.

```
NIGHT SURVIVED   Night 1: Night Life
Time 3:12   Health 20/20   Gold earned 640
Notes 71 hit of 100 (71%)   Perfects 37
Parries 20 of 29   Towers locked 1   Shields lost 3   Restores 0
Calls nailed 14 of 16   Staggers 6
Boss: 20 bolts, 0 stomps, 2 breaks
Picks: Treasure chest
Level 10   XP 237   Talents 5 (Pulse 2, Accent 3)
Type upgrades: none   Unlocked: Lightning, Light
Crits 0   Arcs 0   Poison 0   Counters 0 of 19
W2  notes 16/16  parries 1/1  counters 0/1  hp -0   |   W4  notes 15/18  parries 2/2  counters 0/2  hp -0
W6  notes 40/66  parries 17/26  counters 0/16  hp -0
```

Watch item (Jared, 2026-10-31 14:31Z, no change yet): "notes always hit the closest enemy" feeds the boss problem. Notes clear the wave, so you are always left with only the boss walking. Decide after testing Night 1 v2.

## Night 1 v2 (D-0051), built 2026-10-31

What changed is in D-0051. Bot runs (`tests/t_level.gd`; the bot builds towers only, no walls or maze, so it is weaker than a player):

| Version | Bot | Result |
|---|---|---|
| v1 (200 gold, no range, Q and E) | 70% notes | survived 14/20 |
| v2, 100 gold | 70% | fell in the groove |
| v2, 150 gold, tiers lowered (shipped) | 70% | fell after the song, boss at 12% |
| v2, 150 gold, tiers lowered | 50% | fell in the groove |

The bot never builds walls, so it cannot reach past 4 tiles from the keep and fights a short straight path. Expect a player who mazes to do much better; Jared's run decides whether 150 gold and the 5% price step are right. All of it is in the level file: `gold`, `price_step`, `reach`, `mine`, the tiers.

The boss now strides on the beat at 2.3 tiles a second, 4 when it is behind, and reached the keep after the song in the bot run, then hit the camp each bar.

## Night 1 v2 playtest, run 1 (Jared, 2026-10-31 14:48Z), collected, not acted on

```
THE CAMP FELL   in the finale, bar 89 of 96
Time 2:42   Health 0/20   Gold earned 154
Notes 36 hit of 52 (69%)   Perfects 19
Parries 7 of 19   Towers locked 2   Shields lost 3   Restores 0
Misses 14: no press 7, early 5 (avg 116 ms), late 2 (avg 129 ms); while building 3, near a parry 2, in the boss fight 4
Calls nailed 12 of 18   Staggers 0
Boss: 8 bolts, 0 stomps, 0 breaks
Level 7   XP 105   Talents 0 (none)
```

1. Pathing: when the maze changes, creeps already past a decision point keep walking their old route with no path drawn under them. The behaviour is fine; the old path should stay drawn and fade: one step dimmer at once (no longer the main path), then tile by tile as the last creep leaves it.
2. Ranged parries may be harder now that the fight is near the camp (a lot happens by the keep), but it fixes the left/right vision split. Unsure yet.
3. Backlog: new assets for the camp and the night-watchman theme, build animations.

Read (Claude): the early and late misses average 116 and 129 ms, just past the 90 ms Good window. Parries were 7 of 19, the weak spot this run.
