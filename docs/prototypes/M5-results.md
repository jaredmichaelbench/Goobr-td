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
