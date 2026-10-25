# Decision log

One entry per decision, newest at the bottom. Never edit a past decision; supersede it with a new one that links back.

Format:

```
## D-000X: Title
Date · Status (proposed / accepted / superseded by D-00Y)
Context: why this came up.
Decision: what we chose.
Alternatives: what we didn't choose and why.
```

---

## D-0001: Target platforms
2026-10-23 · accepted (from pitch notes)
Context: Jared's target surface is Steam.
Decision: Steam on Windows and macOS (Apple Silicon native), from the first prototype.
Alternatives: Windows-only first. Rejected because rhythm latency behaves differently per OS and needs testing on both early.

## D-0002: Docs-first workflow
2026-10-23 · accepted
Context: The project should survive many sessions without relying on chat memory.
Decision: All vision, decisions, tasks, backlog, and notes live in this file structure. Chat is for conversation; anything worth keeping lands in a file the same day.
Alternatives: Google Doc as the hub. Kept only as an archive of the original scratchpad.

## D-0003: First playable scope
2026-10-23 · proposed (awaiting Jared's review)
Context: The pitch has far more ideas than a first playable can hold.
Decision: First playable = single-player, one map, core conductor loop (suppress, restore, stems), one light draft, one boss. Everything else goes to backlog. See `vision/vision.md`.
Alternatives: Include quests or EXP now. Deferred until the core loop is proven fun.

## D-0004: Engine
2026-10-23 · superseded by D-0011
Context: Unity + FMOD (lowest friction for stems and Steam multiplayer) vs. Godot 4 (lighter, fast on Mac and PC).
Decision: Not yet. Decide after P-01.

## D-0005: Boss direction
2026-10-23 · accepted (direction), partly superseded by D-0007
Context: Jared's comment on pillar 5. Bosses must not be a big enemy walking the maze while you play Guitar Hero.
Decision: Bosses are souls-like duels built on parrying. The rhythm is hidden in attack strings and tells, with no note highway. Bosses engage the maze (recommended: anchor to it) rather than walk the creep path.
Alternatives: Boss walks the maze with telegraphs (rejected by Jared). Boss buffs itself unless rhythm is kept (kept in backlog as a variant). Open sub-options in `notes/boss-design.md`.

## D-0006: Maze-to-rhythm baseline
2026-10-23 · proposed (baseline for P-04, expected to evolve)
Context: Jared asked what "the maze is the instrument" means in practice.
Decision: The maze is a sequencer. Tower types are instruments with fixed beat patterns and stems that play while they have targets. Crossfire on a shared beat creates accents. One Conduct key fires a Resonance on accents and also parries and Restores.
Alternatives: One keybind per tower type (tested as P-04 arm B). Longer maze = longer song (rejected: length gives more phrases, not a longer song).

## D-0007: Boss model options reopened
2026-10-23 · proposed (refines D-0005)
Context: Jared's comment on boss-design options A to C.
Decision: All boss models stay open (A latch-on, B lunges, C off-board, D walks the maze while firing ranged attacks at the Conductor that speed up as it approaches). D-0005's "don't walk the creep path" is relaxed: a walking boss is fine if its attacks, not its walk, are the event. First prototype likely C or D. Possible theme: the Conductor is a character (such as a knight) guarding an objective.

## D-0008: League-style keyboard controls
2026-10-23 · accepted (Jared's original vision), exact bindings proposed
Context: Jared answered the boss-design input question: traditional keyboard play, like League rather than an MMO.
Decision: 4 primary binds plus specials, all rebindable. Proposed defaults: Q/W/E = instrument Resonance, R = ultimate, Space = parry, F = restore, 1–4 = items, B = build, mouse = camera, pings, and placement. No cursor aiming during waves. This supersedes D-0006's single Conduct key, which becomes P-04 arm B.
Alternatives: One context-sensitive key (kept as a comparison and accessibility option). Cursor-targeted parries (rejected).

## D-0009: Damage balance philosophy
2026-10-23 · accepted (direction), numbers to tune
Context: Jared's answer to boss-design question 2.
Decision: Tower base damage (build, talents, tower choice, maze) is the main damage source, for bosses too. Note play adds damage, and perfect timing = critical strikes. Crescendo (posture break) is about a +30% damage window, not the main way to deal damage. A good maze plus decent note play kills the boss, and the boss never feels invincible outside Crescendo.
Alternatives: 70% of boss damage from Crescendo (rejected: it shrinks the TD loop and puts too much into one window).

## D-0010: Move to Demo 0
2026-10-24 · accepted (Jared asked to get a demo on the board)
Context: The first full review found that the remaining questions are about feel and need a build to answer.
Decision: Stop refining on paper. Build one evolving greybox project in milestones M0–M6 (`prototypes/demo-0-plan.md`). Also settled: one global BPM with per-tower patterns on it; 3 tower stems plus a Conductor lead stem; one health pool at the objective; procedural placeholder audio.
Alternatives: More design iteration first (rejected: diminishing returns). Separate throwaway prototypes (rejected: one project compounds).

## D-0011: Engine is Godot 4
2026-10-24 · accepted (Jared picked it)
Context: Demo 0 needs an engine. The options were Godot 4 and Unity + FMOD.
Decision: Godot 4 with native audio (synced stems on the audio clock). Add the FMOD GDExtension only if M1 shows native audio isn't good enough. Revisit if M1 timing fails on Windows.
Alternatives: Unity + FMOD (heavier, but the most mature middleware). Building M1 in both (unnecessary).

## D-0012: Build keys move to 1-4 in M3
2026-10-24 · proposed (for the demo; revisit when items exist)
Context: In M2, Q/W/E selected towers in build mode. In M3 they play instrument accents, and you build during waves, so the same keys can't do both.
Decision: Build selection uses 1 (wall), 2 (kick), 3 (hat), 4 (bass). Q/W/E are always instruments. When items arrive (1-4 in D-0008), build selection needs a new home, for example a build bar on the mouse or Shift+Q/W/E.
Alternatives: Q/W/E select only while build mode is on (rejected: you'd have to leave build mode to play accents mid-wave). Context-sensitive keys (rejected: confusing).

## D-0013: Call-and-response phrases replace constant accents
2026-10-24 · proposed (testing in M3)
Context: M3's first pass made an accent whenever towers crossfired on a note. With hats on every 8th note, Jared said it felt like playing the drums. He wants Expedition 33 style lock-in moments with breaks, telegraphed on the tower, with music that hints at the pattern (Silksong's Cogwork Dancers) rather than a DDR chart.
Decision: The song runs in 4-bar phrases: groove, groove, call, answer. In the call bar a chime plays a short rhythm. In the answer bar that rhythm returns as rings receding onto specific towers, and the player presses the key shown above each tower. Rhythms repeat for two phrases so they can be learned. Crossfire decides which towers get cued and multiplies the bonus, so mazing still matters (pillar 1). Instrument names stay internal; players see keys and colors.
Alternatives: Crossfire accents on every shared note (rejected: too dense). No audio call, rings only (weaker: the music should telegraph, per Jared).

## D-0014: The song chart decides the notes, shown on a timeline
2026-10-25 · accepted (Jared picked it after the M3 second-pass playtest)
Context: D-0013's cues were enemy-driven: picked from whichever towers had targets when a phrase started. Jared found them hard to parse, not telegraphed, and too rare to practice, and early waves didn't teach anything. Because cues didn't exist ahead of time, they couldn't be shown. He also wanted 1-2 rhythms instead of three, and suggested a WoW boss-mod style scrolling timeline. See `notes/rhythm-model-options.md`.
Decision: A fixed chart is part of the song and scrolls along a timeline under the board. Only two playable rhythms: Q (on the beat) and E (off-beat). Hats are background music, not a tower. Pressing a note fires a Resonance from every tower of that key that has a target (Perfect = crit, crossfire multiplies); no engaged tower means the note is wasted. So the maze question becomes "how many of my Q and E towers are in the fight when the notes come?" The chart starts with one Q note per bar and builds up every two waves. Waves are longer (14 + 3 per wave creeps). Build keys are 1 wall, 2 Q tower, 3 E tower (supersedes the key list in D-0012).
Alternatives: Keep enemy-driven cues and tune them (rejected: can't be telegraphed or trained). Three rhythms with hats (rejected by Jared: too much).
Risk: a visible chart moves toward chart reading, which D-0005 avoids for bosses. Bosses can hide the timeline later.

## D-0015: M3 map gets rock terrain and a wall limit
2026-10-25 · proposed (testing in M3, Jared asked for it)
Context: On a flat 20x20 board, unlimited cheap walls let you draw any maze you like, which felt "a little broken." Jared suggested blocked terrain like Warcraft 3 or StarCraft cliffs.
Decision: M3 uses a hand-made map with rock: two ridges split the board into three fields, joined by two gaps in the first ridge (top and bottom) and one wide gap in the second. Rock blocks walking and building. Walls are capped at 20 per run. The map lives as an ASCII grid in `m3_song.gd` (`MAP`), so it's easy to edit. M2 keeps its flat map.
Alternatives: Terrain only, unlimited walls (weaker: walls still beat the map). Rising wall cost (possible later, harder to read than a cap).

## D-0016: Suppression comes from elite creeps, Restore is timed to the downbeat
2026-10-25 · proposed (testing in M4)
Context: M4 needs a source of suppression before the boss exists (M5), and the Restore rules from the pitch notes needed numbers.
Decision: Elites (every 6th creep from wave 2, 4x health, 0.8x speed) pulse on a downbeat when towers are within 2.2 tiles, suppressing them for 10 seconds; the same elite waits 4 bars before pulsing again. Suppressed towers don't fire, don't answer notes, and their stem drops out, and the groove drops out while anything is suppressed. F Restores: on a downbeat (Good window or better) all suppressed towers return with an Overcharge salvo (2.5x damage, splash 1); off the beat the charge is still spent, the towers return one bar later, no salvo. 3 charges, +1 per wave cleared, capped at 3. Suppression also expires on its own, so Restore is about tempo, not survival.
Alternatives: Suppression only from boss attacks (rejected: nothing to test until M5). Permanent until Restored (rejected: running out of charges would end the run on its own).

## D-0017: Locks come from missed notes, Restore lands on any beat
2026-10-25 · proposed (testing in M4 v2, Jared's call)
Context: In M4 v1, elites locked towers on a timer (every downbeat in reach), and Restore only landed on the downbeat, which always coincided with a Q note and felt predictable. Jared wanted the lock to be reactive (miss a note near enemies, lose your towers, unlock fast if you're quick) and Restore to be the player's choice of moment, but still never off-beat.
Decision: An elite with towers in reach is armed. A missed note while an elite is armed locks the towers in its reach (10 s). Clean play is never locked. Restore lands on any beat (quarter notes, Good window); an off-beat press does nothing and keeps the charge. The late-restore rule from D-0016 is dropped. Beat marks show on the timeline while locked.
Alternatives: Restore on every 8th note (rejected for now: at 120 BPM with a 90 ms window, most presses would count, so "on beat" would mean little; it's one constant if we want to try it). Locks on a timer (D-0016, rejected: not reactive).

## D-0018: Test tools use letter keys, not F-keys
2026-10-25 · accepted
Context: F1-F12 are media keys on Jared's Mac keyboard and didn't reach the game.
Decision: T speed, Y auto-send, G +100 gold, H skip a wave, K one-key mode, L timeline toggle.

## D-0019: Restore is pressed any time and lands on the next 8th note
2026-10-25 · accepted (Jared, after the M4 v2 playtest)
Context: Timing Restore to the beat (D-0016, D-0017) collided with Q notes on the same beats, and a wasted charge punished a player who was already locked. Jared wanted Restore independent of the music with a refreshing full-map effect, and the sound aligned to the beat for satisfaction.
Decision: F works any time with no timing check and nothing wasted. The Restore lands on the next 8th note (`RESTORE_GRID_STEPS`, 0 = instant) so the ripple, salvo and sound sit on the grid. A refresh ripple sweeps the board from the goal outward and each locked tower relights as it passes, firing an Overcharge salvo. Charges stay at 3, +1 per wave cleared. Locks still wear off on their own after 10 s.
Alternatives: Fully detached from the music (rejected: the on-grid landing is free and keeps the music honest). A cooldown instead of charges (open, ask after the playtest).

## D-0020: The first boss walks the maze and fires at the Conductor (model D)
2026-10-25 · accepted (Jared picked it on the card)
Context: M5 needed a boss model from `notes/boss-design.md`. The candidates were C (off-board, reaches in; simplest) and D (walks the maze, ranged attacks at the Conductor that speed up as it nears).
Decision: Model D. The boss walks the creep path slowly and quietly; its ranged attacks at the Conductor are the event. Attacks land on the beat grid with tells and no timing UI. Space parries. An unparried hit locks the towers it passes over (M4's lock) and damages the objective. Parries build posture damage; a posture break opens a Crescendo window (about +30% tower damage). A long maze buys slower, more readable attacks.
Alternatives: C (rejected for now: the maze wouldn't affect the fight, and M3/M4 showed the maze is where the agency lives). A hybrid with a final latched-on phase stays open.

## D-0021: First-pass boss numbers for M5
2026-10-25 · proposed (testing in M5)
Context: D-0020 picked model D; the first build needed concrete rules.
Decision: Boss wave 5 (alone), 40x that wave's creep HP, 0.4 tiles/s. Two strings of four bolts (arrival offsets in beats: 0, 1, 2, 3.5 and 0, 0.5, 2, 3), scaled by distance: half-time in the far third of the path, on the beat in the middle, 8th notes in the last third or at the Conductor. Bolts fly along the path at 6 tiles/s (at least 0.5 s warning); tell = a beat of wind-up, a low tone, and the bolt. Space parries on arrival with the M1 timing windows: Good 40 damage and 15 posture, Perfect 80 and 25; four Perfects break posture (100). A hit costs 2 health and locks towers in the boss's reach. A posture break staggers the boss for 6 s with Crescendo (+30% tower damage, full mix). The boss never leaks; at the Conductor it fights at the fastest tempo. No timing UI (D-0005).
Alternatives: Boss plus a creep stream (later, M6). A parry ring at the Conductor (rejected for the first test: see whether the bolt alone is readable).

## D-0022: Notes are punctuation, assigned to one tower, and fire an infinite-range bolt
2026-10-25 · accepted (Jared: "go", after the M5 playtest discussion in `notes/rhythm-vs-td-2026-10-25.md`)
Context: The M3-M5 chart was a continuous stream, every note fired every engaged tower of its key, and misses locked towers. Jared's read: eyes glued to the top sequence, trained to fear a miss, the build phase felt irrelevant, and the game had drifted into a rhythm game with a maze. At its heart this has to be a TD; rhythm amplifies it.
Decision: Charts are sparse (about one accent per phrase, growing to four a bar by wave 4). Each note is assigned to one tower when its ring appears: the tower with the most creeps in range, crossfire as tiebreak, else the tower nearest the lead creep. Note colour (Q orange, E purple) is independent of tower type; tower types are TD roles (heavy, splash). The ring never vanishes while the note is open. A landed note fires a board-wide bolt from that tower at the creep closest to the Conductor: tower damage x2.5 (x5 Perfect) x crossfire, keeping the tower's splash. A miss costs only that bonus. With no towers the note is voided. The timeline is off by default (L toggles, kept for testing).
Alternatives: Keep notes tied to tower type (rejected by Jared: forces tower choice for music reasons, and one tower type should be able to carry either colour). Remove notes entirely (rejected: pillar 2 still wants real inputs; punctuation keeps them without the APM tax).

## D-0023: Space is the one defensive input; locks come only from unparried attacks
2026-10-25 · accepted (same discussion)
Context: D-0017 locked towers on a missed note while an elite was armed. That tied offence and defence to the same key and made every note a threat.
Decision: Missed notes never lock anything. An elite with towers in reach winds up a pulse that lands on the next downbeat, with a swelling ring and a tell tone a beat before. Space parries it on arrival (M1 windows): the pulse is cancelled and the elite takes 40 damage (80 Perfect). Unparried, it locks the towers it threatened when called plus any it has walked up to since, for 10 s, then 4 bars of cooldown. The boss wave has no chart notes; its bolts are parried with the same Space and windows. A posture break opens Crescendo plus a short note burst (one note per beat for 6 s on your towers, each a free bolt at the boss), the only notes during the boss.
Alternatives: Elite pulses on a timer regardless of reach (D-0016, rejected again: not reactive). Parry damage only, no lock (rejected: the lock is what makes Restore matter).
