# Vision (working draft v0.1)

_Status: draft, 2026-10-23. Expected to change as prototypes teach us things. Every change gets a line in the changelog at the bottom._

## The one-liner

**A maze tower defense where the wave is played, not watched.** You build the maze, then you *conduct* it: the soundtrack is your feedback, your towers are the band, and keeping the music alive is how you survive.

## The problem we're solving

Modern TDs fall into the "screensaver" rut: the build phase is the game and the wave phase is 2x-speed spectating. Games that fix this (Orcs Must Die, Sanctum, X-Morph) bolt on a shooter, and mazing stops mattering. Nobody has made the maze itself the thing you play during the wave.

## Pillars

Use these to settle arguments. If a feature doesn't serve at least one, it goes to the backlog.

1. **The maze is the instrument.** Mazing and routing are the core skill. Every active mechanic must reward a good layout (crossfire, corners, long corridors), never replace it. In practice the maze is a **sequencer**. Each tower type is an instrument with its own beat pattern and stem, the path decides which towers are in the fight when the song's notes come, and crossfire (2+ towers on the same target) makes those notes hit harder. The song's notes are sparse punctuation: each one lands on a single tower in the fight (Q on the beat, E off the beat, independent of tower type) and a landed note fires that tower's bolt anywhere on the board, harder with crossfire (D-0022). Tower types are TD roles. See `notes/maze-rhythm.md` and `notes/controls.md`.
2. **Played, not watched.** The wave phase asks for real inputs, landed on the music's beat. Inputs are punctuation, not constant drumming: high-stakes moments, not APM tax. Q/E are offence (a bonus you can only gain), Space is defence (a parry you can lose); a miss on offence never punishes (D-0022, D-0023). This is a TD first; rhythm amplifies it.
3. **The music tells the truth.** Game state is audible. Healthy towers = full mix. Suppressed towers = stems drop out. Restoring on the beat slams them back in.
4. **Light, fair chance.** Each wave has a small roll or draft that changes your plan. Randomness shapes options; your maze decides the outcome.
5. **Bosses are exams.** A boss is a souls-like duel, not a big creep walking the maze while you play Guitar Hero. It attacks you and your maze in learnable strings (several models are still open, including a boss that walks the maze but whose attacks speed up as it nears the Conductor). You parry by reading its tells, and the rhythm is felt rather than shown. Your maze and towers do most of the damage, perfect notes crit, and breaking its posture opens a Crescendo bonus window (about +30%). See `notes/boss-design.md`.

## The core loop (first playable)

1. **Build**: place walls and towers on a grid; creeps reroute live.
2. **Draft**: a light per-wave roll (pick 1 of 3 modifiers or tower mods).
3. **Wave**: towers auto-fire, and your maze plays the song. A few notes per phrase land on single towers; hitting Q or E as the ring closes fires that tower's bolt anywhere on the board. Elites and bosses attack on the beat with a tell; Space parries, and an unparried attack suppresses towers so their stems drop out.
4. **Restore**: spend a limited Restore charge any time to snap towers back with a ripple and an Overcharge salvo, landing on the next 8th note.
5. Repeat; every few waves, a boss tests all of it.

The "bump bump bump, failed, shoot, restore, next" cadence from the notes is the heartbeat of the game. Prove that it feels good before building anything else.

## Line for the first playable (in scope)

- One map, ~20x20 grid, flow-field pathing with live rerouting.
- 3 tower types, walls, gold only (one currency).
- One global music track at a fixed BPM: 3 tower stems plus a Conductor lead stem. Procedural placeholder audio for the demo.
- Maze-as-sequencer: 3 tower instruments, crossfire accents.
- League-style keyboard controls: Q/W/E instruments, R ultimate, Space parry, F restore, B build, mouse for camera and pings. All rebindable.
- Suppression + Restore loop.
- One light per-wave draft.
- ~10 waves and one boss: 2 attack strings on the beat aimed at the Conductor (no timing UI), parry into posture break into Crescendo. Boss model still open (C or D).
- Latency calibration screen (required for rhythm on Windows).
- Windows + Mac builds from day one.

## Deliberately out (parked in backlog)

1v1v1v1 multiplayer, in-run quests, conductor EXP and talents, second currency and shop, conductor specs (Glass Conductor, Iron Metronome), thorns/defensive builds, pre-wave mini-encounters, per-tower resonance reticles, meta-progression. Most are good ideas; they're held until the core loop is proven fun. See `backlog/backlog.md`.

## Biggest open questions

These are the things prototypes need to answer. Tracked in `decisions/` once settled.

1. ~~What is the beat?~~ Settled (D-0010): one global BPM, with each tower type playing its own pattern on it.
2. **How do QWER bind?** Per tower type (instrument) or per player-assigned zone, and what happens with more than 3 tower types (a loadout per run?). See `notes/controls.md`.
3. **How does a souls-like boss work in a maze?** Four models are open (`notes/boss-design.md`), with C or D likely first. Its attack strings land on the beat with animation tells and no timing UI. A parry builds posture damage; a miss suppresses towers and Restore applies. A posture break opens a Crescendo punish window. Needs P-05.
4. ~~Engine~~ Settled (D-0011): Godot 4, with FMOD only if needed.

## Next step

Build Demo 0. See `prototypes/demo-0-plan.md`.

## Changelog

- 2026-10-25: v0.8 scope change: notes become sparse punctuation on single towers, not tied to tower type; Space is the only defensive input and misses never lock; the boss has no chart; "TD first, rhythm amplifies" written into pillar 2 (D-0022, D-0023).
- 2026-10-25: v0.7 the song chart decides the notes, shown on a timeline; two rhythms (Q, E), hats become background (D-0014).
- 2026-10-24: v0.6 first full review: global beat settled, stems clarified, moving to Demo 0 (D-0010). Engine: Godot 4 (D-0011).
- 2026-10-23: v0.5 damage philosophy: towers are the main source, perfects crit, Crescendo is about +30% (D-0009).
- 2026-10-23: v0.4 controls set to Jared's League-style layout (D-0008); boss pillar loosened to match D-0007.
- 2026-10-23: v0.3 pillar 1 made concrete: maze as sequencer, crossfire accents, one Conduct key (`notes/maze-rhythm.md`).
- 2026-10-23: v0.2 boss pillar rewritten per Jared: souls-like parry duels, hidden rhythm, no boss walking the maze.
- 2026-10-23: v0.1 distilled from the pitch scratchpad (`notes/pitch-scratchpad-2026-10.md`).
