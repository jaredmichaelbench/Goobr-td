# Level template: build plan

_2026-10-31 · Jared said go on the recommendation (project chat, 04:35Z: "I want to go in your recommendation"). Design: D-0048, D-0049, `notes/single-player-journey-2026-10-31.md`._

Goal: one playable night on **Night Life** (2:57) that follows the base level template, so Jared can play it and then choreograph levels himself. Three small Demo 1 fixes come first because the level runs on the same rules.

## Milestones

| Id | Milestone | What Jared sees | Done when |
|---|---|---|---|
| L1 | Demo 1 fixes | Melee parry lands where the arrow does; level-up chime waits for the wave clear | Bot shows every throw landing one bar after it starts |
| L2 | Performance pass | No lag late in a run | Stress test at 10x and 30x a late wave, numbers before and after |
| L3 | The template level | Title screen: **Night 1: Night Life** | Bot plays the whole song, sections land on their bars |

## L1: Demo 1 fixes (from the playtest 4 discussion, step 1)

1. **Melee parry timing.** Every elite throw lands on beat 1, one bar after it starts, like arrows (was a bar and a half for half the throws from wave 11).
2. **Level-up chime.** The chime, the button shake and the "LEVEL" line wait until the wave is cleared and show on the wave-clear card. The XP bar still fills silently.

## L2: Performance pass

1. A stress test that fills the board: 10x and 30x a wave 19 (hundreds of creeps, about 300 towers, poison everywhere), timing each simulation step.
2. Fix what it shows (likely: poison numbers, every tower scanning every creep, the Light boost scan).
3. Report frame times before and after. Rendering cost has to be checked on Jared's Mac.

## L3: The template level

- **A level file** (`game/levels/night_life.cfg`): plain text Jared can edit. The song, the count-off length, then the sections in order: name, bars, kind (push, lull, finale) and what spawns.
- **Flow:** the map is shown; nothing is built until **Start level**. Then the count-off (sticks, 1 2 3 4) is the build phase, the song starts, and the sections play on its bars. No Start wave button.
- **Lulls:** nothing spawns. The music calms (a low-pass filter and a small dip), and lifts again a bar before the next push. The watchman says a short tip the first times.
- **Pushes and finale:** creeps and elites from the file, with the usual calls, parries and staggers. The finale can flag a field boss.
- **End:** when the song ends and the board is clear, the night is survived: one card (pick 1 of 3), then the results screen.
- **Not in this build:** campaign map, multiple levels, the night watchman art, path-abuse fixes, gold carry-over, beat switches. These come after Jared plays the template.

## Order

L1, then L2, then L3. Each is pushed as it lands; Jared tests once at the end (git pull, open with Edit, Play).
