# M5 results: first boss

_Question (P-05): does it feel like learning a souls boss, not reading a chart?_

## First pass (2026-10-25, D-0020, D-0021)

Model D: the boss walks the maze and throws bolts at the Conductor; Space parries; posture break opens a 6 s Crescendo.

Headless, dense test maze (11 towers): a bot that parries every bolt Perfectly kills the boss in about 25 s with two posture breaks. A bot that never parries loses the objective in about 30 s (10 hits at 2 health). Bolts took 4-5 s to arrive while the boss was far.

Waiting on Jared's playtest.

## First pass playtest, feedback collected (2026-10-25, not yet acted on)

Jared played waves 1-5, then on to wave 12 in a second run (stats: Q 70% hits, E 73%, 74 locks, 9 Restores, boss: 24 bolts, 14 parries, 9 perfect, 9 hits, 2 breaks).

- Boss: difficult. The music not lining up with the parries made it hard to focus on both; the game had trained him to fear missing a note, and the lock is debilitating.
- Waves: challenging, but "eyes glued to the top sequence". Something is missing. The top bar might need to go, towers need better indication, maybe less punishing. "Not quite there."
- Bug: O didn't re-summon the boss after it died (fixed: a parry kill left the boss record behind).
- Open: iron out now or dial later? Some of this may be solved by rogue-lite elements, talents, tower upgrades, more tower types.
- Core concern: not sold on music as the centre of the game. Rhythm should amplify the TD action; at heart it must be a TD. The sequence bar makes the build phase feel irrelevant: maze length is king, you extend with all your gold, then you're locked into timings for the fight. "Maybe we need to tone that down."

## Second pass: the rhythm rework (2026-10-25, D-0022, D-0023)

Agreed with Jared after `notes/rhythm-vs-td-2026-10-25.md`: notes as punctuation on single towers with infinite-range bolts, Space parries for elites and the boss, no chart during the boss, timeline off by default.

Headless bots after the change:

- M3, perfect bot, 24 towers: 2 / 5 / 6 notes in waves 1-3 (was a note every beat or two), no misses, health 20 at wave 4.
- M4, parry bot: 12 pulses, 11 parried, no locks. A bot that stops parrying: 7 pulses, 12 tower locks, health 20 to 2 by wave 3 without Restore. The first build let an elite walk past its targets and fizzle; a landing pulse now also hits the towers it threatened when called.
- M5, perfect parry bot: boss dead in about 25 s with two breaks, no notes until the Crescendo burst. No-parry bot still loses in about 30 s.

Waiting on Jared's playtest.

## Second pass playtest, feedback collected (2026-10-25, not yet acted on)

Jared, two runs (first died at wave 3 with 10 elite pulses, 0 parried, 10 locks; second lost at about wave 2).

- "Quite difficult." The lock can't be that long, and there are too many elites too quickly.
- Loved the infinite-range snipe on a landed note; wants to push that feeling further: heavy towers do a big snipe, splash towers lob an AoE wave. Wondering whether towers should always get notes even with nothing in range (not sure).
- Parrying elites is too hard to time and read, and there are too many of them. Suggests leaving parry for bosses and later enemies and working on the telegraph. Locking the only 4 towers in play is an instant wipe.
- Restore should grant a period of immunity: towers came back and an elite's charged pulse locked them straight away.
- Boss, Crescendo burst: the notes come fast (maybe too fast, probably fine late game) but the real problem is they all land on the single closest tower, so the timing isn't readable. Not sure spreading them helps. First boss a bit slower post-stagger, not much, until it's clear whether it's a clarity problem. The Crescendo length felt good.
- Boss bolts don't come from the boss: they spawn part-way down the path. That telegraphs parry differently from elites (you watch the path and the target, not a circle on the enemy), which he finds better than the circle, but eyes get split between towers on the left (elite rings) and the Conductor on the right. Review wrapped; discuss and put together the next package.

## Third pass: elite pressure and one parry language (2026-10-25, D-0024)

Built the whole package from `notes/elite-pressure-2026-10-25.md`. Headless bots:

- M3, perfect bot: unchanged note counts (2 / 5 / 6 per wave), snipes land with a tracer and punch, waves hit 2 tiles.
- M4, two towers, wave 3, no parries: one elite, one pulse, one tower locked for 5 s; Restore relit it and it stayed immune for 2 bars. The dense test maze kills elites before they throw, so the 8-tower bots saw only 2 pulses across waves 3-5.
- M5, perfect parry bot: 4 bolts, 4 parries, one break, boss dead in about 25 s; bolts now leave the boss (flight 5.25 s from the far third). No-parry bot still loses in about 35 s with 3 single-tower locks.
- Crescendo sweep: one ring at a time, starting at the tower farthest from the boss.

Waiting on Jared's playtest.

## Third pass playtest, feedback collected (2026-10-25)

Jared, one run to wave 8 with a boss summoned mid wave 7 (stats: Q 66% hits, E 56%, 10 elite pulses, 0 parried, 17 locks, 1 Restore; boss 44 bolts, 28 parries, 21 perfect, 1 hit, 6 breaks).

- Waves 1-3 already feel much better as an opening. Crits are satisfying; a weak maze can finish stragglers on the beat.
- Wave 7 with a boss summoned: "awesome". Fighting locks, parrying the boss, the stagger notes clearing the wave with snipes, then focusing the boss. Notes hard to hit but readability way better. "Genuinely fun, we are on to something."
- Boss bolts: travel time is long, and with no notes to play it's a lot of waiting. Minor tweak.
- Elite parries are still hard to hit: indication and timing are lost on him (0 of 10 parried). Idea: drop the circle on the elite; show it raising a sword instead, and put the emphasis on the ring of the tower(s) it attacks.
- Song and notes sometimes linger awkwardly after the last creep dies: discuss the wave-to-build transition.
- Default synth music behind the new tracks is getting stale (later). Backlog: how to get Geometry Dash-style music; songs should get more intense as you do well (partly there, not the full effect); single-player waves should be long and scripted to the music so songs play out.
- Verdict: finish some polish here, then move on. "So much exciting stuff: rogue-lite paths, talents, tower types."

## Polish pass (2026-10-25, D-0025)

Telegraph moved to the tower (sword on the elite, closing red ring and beat pips on the target), bolts 10 tiles/s capped at 3 s, wave-clear transition. Bots unchanged: M3 perfect, M4 parry bot 2 of 2, M5 perfect parry bot kills the boss with flights of 2.75-3 s (was 5.25). Waiting on Jared's playtest; then M5 is done.
