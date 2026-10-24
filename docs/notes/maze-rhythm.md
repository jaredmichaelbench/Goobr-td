# How the maze makes the rhythm: baseline v0.1

> **Update 2026-10-23 (D-0008):** controls changed to Jared's League-style layout. Q/W/E fire Resonance per instrument, R is an ultimate, Space parries, F restores. Rules 1–2 still stand. Rules 3–4 below describe the older one-key version, now P-04's comparison arm. See `controls.md`.

_Started 2026-10-23 from Jared's comment on pillar 1. This is a baseline for the first test, not a final answer. It is expected to evolve._

## Jared's questions

1. Does a longer maze mean a longer rhythm section?
2. Does a maze with varied towers produce unique rhythm patterns?
3. Do different towers give you different keybinds to press?

## Baseline answer: the maze is a sequencer

Think of the creep path as a **timeline** and each tower as an **instrument** placed along it. As a wave flows through your maze, the maze plays a song. You compose it in the build phase and conduct it in the wave phase.

### Rule 1: each tower type is an instrument with a fixed pattern (answers Q2: yes)

- One global BPM per track.
- Each tower type auto-fires on its own beat pattern, quantized to the song, and owns one stem. Example for the first test:
  - **Kick tower** (heavy, slow): fires on beats 1 and 3. Drum stem.
  - **Hat tower** (fast, light): fires on every 8th note. Percussion stem.
  - **Bass tower** (slow, area): fires on the off-beats. Bass stem.
- A tower's stem only plays while it has a target. **What you hear is your maze's coverage.** A section with no creeps in range is silent, while a dense kill-box is loud and full.
- A varied maze therefore really does sound different. Two players with different tower mixes hear different songs.

### Rule 2: the path decides when you play (answers Q1: partly)

- A longer maze doesn't lengthen the song. It means each creep group passes through more instruments, so you get **more phrases per wave** and more chances to act.
- The **order** of towers along the path is the order of the phrase. Kick, then hat, then bass sounds different from the reverse.
- **Corners and switchbacks** slow creeps and keep them in range longer, which sustains a phrase. That gives corners a musical reason to exist, not just a damage reason.

### Rule 3: crossfire creates the notes you press (superseded on keys by D-0008: Q/W/E per instrument)

- **One "Conduct" key** for the baseline.
- When 2 or more towers have the **same creep group in range on the same beat** (crossfire), an **accent** appears on that beat, as a subtle pulse on the tiles. It is not a note highway.
- Tapping Conduct on an accent fires a **Resonance**: a damage bonus that scales with the number of overlapping towers, plus a bright musical hit. _Numbers to tune: keep it moderate so tower base damage stays the main source (D-0009)._
- Timing grades: Good hit = normal Resonance. **Perfect hit = critical strike** (Jared, 2026-10-23).
- Missing an accent costs nothing. Towers keep auto-firing at baseline. Accents are upside, never a tax.
- So **good mazing creates more and bigger accents**. Overlapping ranges, crossfire at corners, and stacking different instruments on one tile all pay off. A bad maze plays itself and gives you little to do. That is "the maze is the instrument" in practice.

### Rule 4: the same key handles trouble

- Elite or boss attack tells: tap Conduct on the hit to **parry** (see `boss-design.md`).
- Towers suppressed: tap Conduct on the next downbeat to **Restore**. Restores are limited charges.
- One key, three contexts. If testing shows they collide, split Restore onto its own key.

## Why not one keybind per tower type (for now)

- It is the most "instrument-like" option and the most fun on paper, but it turns waves into Guitar Hero, which Jared doesn't want even for bosses, and it multiplies APM with every new tower type.
- It is cheap to test against the baseline, so **P-04 includes it as a comparison arm** (Q/W/E for kick, hat, and bass). If it wins, a hybrid could work: one key per tower *group* or *zone*, not per type.

## What the first test needs

- 3 tower types with fixed patterns and stems, a global BPM, stems gated by "has target".
- Accent detection: 2+ towers with the same target group on the same beat.
- Q/W/E per instrument (baseline) and a settings toggle for the single Conduct key (comparison). See `controls.md`.
- Debug overlay showing accents per wave and Resonance hit rate.

## What we're watching for

- Can players **hear** their maze? Does a better maze sound better without being told?
- Do players rebuild their maze to get more accents? If so, the core idea works.
- How many accents per wave feels good before it becomes fatiguing? This sets the input budget.

## Ideas for later (backlog candidates)

- Tower upgrades that change the pattern (half-time, triplets, swing).
- Synergy sets: 3 of an instrument in one crossfire unlocks a fill or solo.
- A per-map track and tempo, and wave modifiers that shift the tempo.
- Pattern clashes as a puzzle: off-beat towers next to on-beat towers create syncopated accents worth more.
