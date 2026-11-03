# B3 results, with the playtest 1 fix pass

_2026-11-03 · D-0069, D-0070 · notes: `notes/b1-b2-playtest-1-2026-11-03.md` · plan: `five-night-demo-plan.md`_

Jared went with Claude's pick on every proposal in the playtest 1 doc (D-0070), to be reviewed in his next session. Everything below can still change.

## Fix pass (from playtest 1)

- **Night 5 rugpull (D-0069):** the Night Manager opens Flanger Party. The Landlord walks in when the overtime song starts. If the manager is still alive then, the Landlord waits for him to fall. The 25% health floor is gone, and the Landlord has 2x a boss's health.
- **Notes go to the creep nearest the camp** again, boss or not, so a leak can always be saved with a note. Crescendo notes (after a posture break) go to the boss. Elites have no priority.
- **The night ends when the last enemy dies.** In the last section, once nothing is left to spawn and the board is clear, the watchman says "That's the last of them" and the morning comes 2 bars later. The song plays on under it.
- **Fork tooltips.** The tower card spells out both forks, each one's mastery, and the prices.
- **Morning repair.** The camp repairs 4 health each morning, up to 20, and the morning screen says how much.
- **Diggers are a parry.** A Digger stops at a wall for 4 bars (DIG 4, 3, 2 on the wall). In the last bar the mark turns into a red PARRY ring with four pips: that's the shovel swing. Parry it and the wall holds, the Digger is staggered, and the counter opens. Miss it and the wall goes ("DUG"). The watchman explains the first one. Test `tests/t_fixpass.gd`: the first swing was parried and the wall held, the counter landed, and the second swing (left unparried) broke the wall.
- **The counter is a rhythm hit.** After a landed parry, a yellow ring marked COUNTER closes on the next half beat. Press Space as it lands; it's judged Perfect or Good like a note. A press that's too early shows "Counter early". Improved Counter Attack widens the window.
- **Pickup replaces Quick Draw.** Every tower fires an extra shot on the "and" of beat 4. It sits in the same place in the tree.
- **The Poison crossover, option A.** Improved Poison sits straight above Unlock Poison. Perfect Solo is the top of the middle and nothing leads on from it. Melodic Healing sits above Solo.
- **Restore is explained.** The first time a tower jams, the watchman says "Press F to Restore it". While a tower is locked and you have a charge, the F button glows and pulses. Night 1's start panel mentions it.
- **Bug fixed:** the night picker's Done button now closes the tree after the last point is spent.

## B3: the nights get their own maps

- **The map lives in the level file:** 16 rows of 26 between `|` marks. "." is open ground, "#" is rock, and "x" is no-build ground (creeps walk it, nobody builds on it). Jared can redraw a map in a text editor.
- **The reach rule and the mine radius are off** whenever a level file has a map, and all five do. You can build anywhere that isn't rock or marked. The wall-hop exploit is gone with the reach rule.
- **No-build ground shows on the board** as dark red tiles, a bit stronger while you're placing something. Trying to build there says "No building there: the marked ground stays open".
- **The five maps (drafts):**

| Night | Map idea |
|---|---|
| 1 Night Life | Night 1's old board, unchanged (frozen, D-0055). The mine radius is now marked no-build ground. |
| 2 Romance on Neon | Wide open with a long rock ridge in the middle, so creeps choose a lane above or below it. The top and bottom rows are no-build. Teaches building beside the path for Door-to-Door. |
| 3 Laser Party | A rock wall down the middle with two gates, top and bottom. The gates are no-build, so both stay open and you defend two lanes. |
| 4 80s, Disco, Life | Open ground for a long wall maze (the Diggers' targets), with two no-build patches (old graves) that break up the easy shapes. |
| 5 Flanger Party | Two long rock ridges make three lanes. The middle lane is no-build ground, so you can't wall the Landlord's lane cheaply. |

- **Tests:** `tests/t_b3_maps.gd` loads each night. Every map parsed with no problems and has a route. Building on no-build ground was refused, and building on open ground far from the camp was allowed. It also takes a screenshot per night.

## Bot runs (`tests/t_campaign.gd`, 85% notes and parries, real health)

| Run | Health after Nights 1 to 5 | Where each night ended (bar of song) |
|---|---|---|
| Fix pass, old board | 11, 8, 12, 16, 20 (after the morning repairs) | 101.6/96, 81.6/72, 55.5/64, 67.9/80, 102.3/132 |
| Fix pass, B3 maps | 19, 20, 20, 20, 20 (after the morning repairs) | 102.8/96, 76.8/72, 54.5/64, 66.6/80, 111.8/132 |

Before the fix pass, an 80% bot fell on Night 2, and a 90% bot finished on 7/20. **With the reach rule off, the nights got much easier:** the bot can put towers right beside the path anywhere and barely lost health. That's expected and it's B5's job. The levers are tighter no-build ground, gold, tiers, and the price step. Jared's feel on the maps comes first.

## For Jared's next session

- Pull as usual. No new songs this time.
- Things to check:
  - Counters: watch for the yellow COUNTER ring after a parry.
  - Diggers: the PARRY ring on the wall.
  - The night ending 2 bars after the last kill.
  - The fork text on the tower card.
  - Each night's map: the red no-build ground.
  - Pickup.
  - The tree's new Poison links.
- **Still open:** lull dead spots, Song 2's feel, the early load of extra notes, and the enemy design and lore pass (all on the backlog, for B4 or B5). On Nights 3 and 4 the last push still clears 8 to 12 bars before the song ends. The night now ends right after, and B5 tunes the timing.
- **Reminder:** synth note sounds go in at B4 and Jared needs them before then. B3 is now built, so B4 is next.
