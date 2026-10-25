# M6b proposal: from a loop to a run (2026-10-25)

Where we are after playtest 5: the core loop is "great" as a loop. Jared's gap list: no progression, one boss type, two enemy types. Sounds are parked behind the swap system (D-0031, D-0032).

What a run needs that the loop doesn't have:

1. **Threats that ask different questions of the maze.** Two elites and one creep type means every wave is the same decision. Enemy variety is the cheapest change that makes mazing and tower choice matter again, and it is what draft picks need to be worth picking (a chain-snipe is only exciting if swarms exist).
2. **Power that arrives during the run.** Gold upgrades are the boring layer (D-0028). The draft between waves is the rogue-lite layer (`notes/power-and-challenge.md`): plain picks, altering picks, conditional picks you play for.
3. **A shape.** 10 waves, a mid boss at 5, the real boss at 10, a win and a lose screen with the run's numbers. Today wave 10 just says "N for endless".
4. **A second boss**, so the exam at 10 is not the exam at 5 again.

## Three slices, one playtest each

### M6b-1: enemy variety and a scripted 10 waves (challenge pass)

New creeps, each with a tower or input that answers it, so the maze question changes wave to wave:

| Creep | What it does | Answer |
|---|---|---|
| Runner | 2x speed, half HP, comes in pairs | Slow tower, freeze note, long corridors |
| Brute | 3x HP and armour (first 4 damage of every hit ignored) | Heavy tower, snipes (armour is flat, so big hits win) |
| Swarm | 6 small creeps in a tight pack, 0.4x HP each | Splash tower, waves |
| Shade | Immune to tower fire while its veil is up; a landed note on any tower cracks the veil for 3 beats | The Q/E input itself: the first creep that needs the rhythm layer, not only the maze |

One new elite: **Warden** (shield), which walks in the middle of a pack and takes all tower damage aimed at creeps within 2 tiles until it is parried (its pulse goes at the nearest tower like a Jammer's). Parry it and the pack is exposed; miss and the pack walks through under cover.

A hand-written wave script for waves 1 to 10 (today waves are a count and an HP multiplier): which creeps, how many, in what order, with elites placed on purpose. Wave 5 mid boss stays. Wave 10 is the boss with a full escort. The script is a dictionary in one file so Jared can tune it without code.

Numbers: Runner from wave 2, Swarm from 3, Brute from 4, Shade from 6, Warden from 7. Creep HP growth stays 30% a wave; the script replaces the "+6 creeps a wave" count.

### M6b-2: the draft and the run (power pass)

Between waves (after the clear sting, before N), pick 1 of 3 cards. The pool, to start:

- **Plain**: +40 gold; +1 Restore charge; +1 Conductor shield this run; +10% kill gold.
- **Altering** (one per run each): snipes chain to a second creep within 3 tiles at half damage; splash waves slow for 1 s; a freeze that lands on a frozen creep shatters it (x3); parried pulses return to every tower in the attacked tower's range; Crescendo lasts 9 s instead of 6.
- **Conditional** (shown locked with its condition, unlocks if you meet it on the next wave): "Land 4 Perfects in a row: heavy towers crit on every Perfect from now on"; "Parry every pulse this wave: Restore costs no charge once per wave"; "Clear the wave with no shield lost: +1 shield cap".

Draft rules: three cards, at most one conditional, the altering picks never repeat in a run, cards are keyboard-pickable (1/2/3) until M6c brings buttons. The draft is the seed of the talent layer later; nothing here is permanent between runs.

The run: a **win screen** after wave 10 (waves, health left, notes hit %, parries, perfect parries, gold earned, time) and a **lose screen** with the same, both with "R to run again". Endless after a win stays as a test mode.

### M6b-3: the second boss

The boss at wave 10 gets its own strings, so it reads as a different fight, not a bigger wave 5:

- **Stomp**: a slam aimed at the maze, not the Conductor. A ring grows on the path tile under the boss over a bar; parry on the downbeat or every tower within 2 tiles locks. Same read as a pulse, but the target is the ground.
- **Volley**: three bolts in a row at the Conductor, 8th notes apart, each parried separately (one press per bolt; the double-parry rule applies when they coincide with an arrow).
- Faster tempo once posture is broken twice: strings go double-time for the last third of its health.

Wave 5 keeps today's boss. A third model (a boss that changes the path) stays in the backlog.

### After M6b

M6c, the UI layer (buttons for build, draft, upgrades, pause, win and lose), then Demo 0 is done and the art decision (`notes/art-direction.md`) and the sim/view split come next.

## Recommendation

Do M6b-1 first. Reasons: it is the smallest slice, it changes what the maze is for every wave (pillar 1), and the draft needs these enemies for its altering picks to mean anything. Then M6b-2, then M6b-3. Each slice is one build and one playtest, so Jared sees a change in a day, not a week.

If Jared would rather feel progression first, M6b-2 can go first with today's enemies; the altering picks would be judged against swarms and brutes only once M6b-1 lands.

## Open for Jared

- The creep roster: four kinds plus the Warden. Fewer, more, or different?
- Draft pool: any pick that feels wrong, or a favourite not listed.
- Boss 2: stomp plus volley, or a different pair.
