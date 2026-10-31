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

## Night 1 v2 playtest, runs 2 and 3 (Jared, 2026-10-31 15:17Z), collected, not acted on

Run 2: the camp fell in the groove, bar 82. Misses 10: no press 6, early 1 (avg 99 ms), late 3 (avg 140 ms); while building 4.

- Definitely harder. Ease the enemy count until some economy flows in; as a first stage it is probably too hard for a first-time player.
- Judging wave and lull cadence is hard, "basically like fight design". The lull may be too long and the waves too hard; lulls could take some enemy load (basic walkers, the odd sprinter, nothing massive).
- Build a table of assets and enemies, to choose models and to call things by their real names.

Run 3 (won, but hard):

1. Maze manipulation works: delete a wall so creeps take a long walk-around, rebuild to make them turn back. Jared will make an easy test first.
2. The new boss is "insane": erratic movement, awesome. Maybe more stops, and show up earlier, since it got to melee fast. Parries near impossible when it is close: normalise, or slow its attacks so they always land on a readable beat pattern. Question: parrying every hit at the camp, do you still take damage? Answer: yes, in v2 the boss takes 1 health a bar at the keep regardless of parries.
3. Dim notes: some notes show dark, some light, which reads as "not active". Answer: the lead is always 2 beats (about 0.9 s at 130 BPM); later notes of a call show earlier as small dim numbered discs (`scripts/indicators.gd`), likely the inconsistency. Recommend a clear colour language for waiting vs live notes.
4. The end card was satisfying. Watch talent point acquisition (10 at the end); backlog with the talent rework.
5. Level 1 is possible but hard. Towers are not balanced: unclear if splash or chain helps, poison strong, single target spam wins. Balance pass around cost (1 gold about 1 power, different profiles, splash scaling down).

Also backlogged: passive tower abilities ("every 5 attacks do X") as talent tree enhancements.

Run 3 log (Jared, 15:19Z; screenshot in the shared folder at screens/night1-v2-run3-2026-10-31.png):

```
NIGHT SURVIVED   Night 1: Night Life
Time 3:20   Health 1/20   Gold earned 318
Notes 66 hit of 89 (74%)   Perfects 44
Parries 26 of 39   Towers locked 2   Shields lost 3   Restores 0
Misses 23: no press 17, early 4 (avg 117 ms), late 2 (avg 148 ms); while building 0, near a parry 1, in the boss fight 19
Calls nailed 14 of 18   Staggers 0
Boss: 28 bolts, 0 stomps, 3 breaks
Picks: Grindstone
Level 10   XP 226   Talents 9 (Scholar 3, Lucky coin 2, Interest, Trade routes, Toll road, Hoard)
Type upgrades: none   Unlocked: Lightning, Light
Stats: damage +25%, luck +2, gold +10%, XP +24%
W5  notes 66/89  parries 26/39  counters 0/0  hp -19
```

Read (Claude): 19 of the 23 misses came in the boss fight, and 17 misses were no press at all, so the boss fight is where the night is lost, not timing. Before the boss: 4 misses all night. Won on 1 health. All 9 talents went to economy. The "by wave" line lumps the whole night into one row (W5), so the log needs a by-section breakdown instead.

## Night 1 v3 (D-0052), built 2026-10-31

What changed is in D-0052. Bot runs (`tests/t_level.gd`, towers only, no walls or maze):

| Bot (notes, parries) | Result | By section |
|---|---|---|
| 70%, 70% | fell after the song | first half lost 1 health; groove -11, finale -8 (missed bolts) |
| 75%, 85% | survived | first half lost 3; groove -5, finale -2 |
| 50%, 50% | fell in the finale, bar 83 | first half lost 2; groove -15 |

Lulls now ask no notes even with walkers in them, and a section's "offered" counts the notes that landed in it.

The first half is now gentle; the boss fight is decided by parries, which is the point. A bolt you miss still costs 2 health (or a shield). `tests/t_v3_smoke.gd` loads the full scene (HUD and 3D view), builds a tower on a wall (charged the tower price minus the wall's) and prints the run log by section.

## Night 1 v3 playtest, run 1 (Jared, 2026-10-31 17:02Z), collected, not acted on

Survived on 3 health ("difficult, but beatable even with mistakes and a non optimized route"). Level 10, XP 208, 9 talent points. Misses 28: no press 19, early 8 (avg 122 ms), late 1 (avg 295 ms); while building 1, near a parry 3, in the boss fight 25. Screenshot: shared folder screens/night1-v3-run1-2026-10-31.png.

- Notes are less readable than ever: they seem to stack on each other, very hard to read when many notes line up on only a few towers.
- Which tower gets a note may need work; keep watching. Jared will record a run for Claude to review.

Read (Claude): while the boss is up, every boss note goes to the tower nearest the boss (`m7_run.gd` `_schedule_bar`, `_nearest_tower(boss["pos"])`), and call notes pick the tower covering the most creeps, which near the camp is the same cluster. That likely explains the stacking.

Run 1 log (Jared, 17:05Z):

```
NIGHT SURVIVED   Night 1: Night Life
Time 3:22   Health 3/20   Gold earned 511
Notes 54 hit of 82 (65%)   Perfects 28
Parries 36 of 55   Towers locked 2   Shields lost 3   Restores 0
Misses 28: no press 19, early 8 (avg 122 ms), late 1 (avg 295 ms); while building 1, near a parry 3, in the boss fight 25
Calls nailed 10 of 13   Staggers 0
Boss: 44 bolts, 0 stomps, 5 breaks
Picks: Treasure chest
Unlocked: Lightning, Light, Poison   Arcs 84
intro      notes 0/0   parries 0/0   hp -0
verse      notes 6/8   parries 0/0   hp -0
rise       notes 0/0   parries 1/1   hp -0
chorus     notes 11/12   parries 2/2   hp -0
breakdown  notes 0/0   parries 1/1   hp -0
groove     notes 15/24   parries 9/12   hp -1   boss
finale     notes 22/38   parries 23/39   hp -16   boss
```

- Hollow waiting rings: they read differently, "but it wasnt really helpful". Jared would rather not show waiting notes at all, only the closing ring; the waiting display is what confuses him. The stacking adds to it.
- Read (Claude): the first half cost nothing; the finale is where the night is decided (38 notes and 39 bolts in 16 bars, 16 health lost). Groove with the boss was fine (-1).

## Night 1 v3 playtest, run 2 (Jared, 2026-10-31 17:12Z), collected, not acted on

```
THE CAMP FELL   in the finale, bar 90 of 96
Time 2:45   Health 0/20   Gold earned 171
Notes 43 hit of 51 (84%)   Perfects 16
Parries 16 of 32   Towers locked 1   Shields lost 3   Restores 0
Misses 8: no press 7, early 1 (avg 98 ms), late 0; while building 3, near a parry 0, in the boss fight 4
Calls nailed 11 of 13   Boss: 20 bolts, 1 break   Level 7   XP 109
intro      notes 0/0   parries 0/0   hp -0
verse      notes 8/8   parries 0/0   hp -0
rise       notes 0/0   parries 1/1   hp -0
chorus     notes 10/10   parries 1/2   hp -0
breakdown  notes 0/0   parries 0/2   hp -0
groove     notes 20/27   parries 8/12   hp -4   boss
finale     notes 4/4   parries 6/15   hp -16   boss
```

- Jared's note ask, in his words: "we shouldnt pre-load notes at all during the phrase ... it seems like we pre load the phrase/crescendo marking every note that will be in it, and then rings show the order live, but instead I want to drop the pre-load, let everything read live." That is the D-0046 call preview: when a call's first note is near, all its notes are assigned to towers and shown. Proposal: drop it; each note appears only when its ring starts (2 beats out) and picks its tower then.
- Read (Claude): notes were 84% this run; the finale was all bolts (6 of 15 parried, 9 missed at 2 health each = the 16 lost). The boss fight's parries decide the night.

## Night 1 v3.1 (D-0053), built 2026-10-31

Live notes only, missed bolt 1 health, two rest bars after each string. Bot runs (towers only, no maze; results vary run to run because the bot plays in real time):

| Bot (notes, parries) | Result | Groove / finale health lost |
|---|---|---|
| 70%, 70% | fell after the song | -11 / -6 |
| 75%, 85% | fell after the song once, survived on 6 the next run | -11 / -6, then -9 / -2 |
| 50%, 50% | fell in the groove, bar 78 | -17 |

The finale now costs the bot far less (-2 to -6, from -8 to -16); most of the bot's losses are leaks in the groove, where a towers-only bot with 7 or 8 towers and no maze cannot hold tier 4. Jared lost 1 and 4 there in his v3 runs.
