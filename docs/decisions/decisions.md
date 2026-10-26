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

## D-0024: One parry language (watch the projectile land), elites as a bruise, Restore immunity, heavier snipes
2026-10-25 · accepted (Jared: "the whole lot", after the second-pass playtest; proposal in `notes/elite-pressure-2026-10-25.md`)
Context: The rework (D-0022, D-0023) was too punishing: an elite every 6th creep from wave 2, a one-beat tell on a swelling ring, 10 s locks on every tower in reach, and Restores undone by a pulse already charged. Boss bolts spawned mid-path (launch was computed as arrival minus flight, often in the past), so the boss parry read differently from the elite parry. Crescendo burst notes all landed on one tower.
Decision: (1) Elites: first on wave 3, one per wave, +1 every two waves, spread evenly through the wave; the same elite throws again after 8 bars. (2) The pulse is a visible projectile: it leaves the elite on a bar start, crawls to the tower it threatens over the full bar with a tick on each beat and the tell tone on the last, and lands on the downbeat. Space parries as it lands. (3) An unparried pulse locks only the nearest tower (two from wave 6) for 5 s; a locked or immune tower is left alone. Boss hits lock the same way. (4) Towers relit by Restore are immune to locks for 2 bars (shield ring), and Restore cancels any pulse in the air. (5) A landed note on a heavy tower is a snipe: damage x4 (x8 Perfect) with a tracer and a screen punch. On a splash tower it is a wave: x2 (x4 Perfect) hitting everything within 2 tiles of the target. One tower never holds two open notes. (6) Boss bolts launch on the string's beats from the boss and fly the path at 6 tiles/s; arrival snaps up to the next 8th. (7) The Crescendo burst sweeps across the towers from the farthest from the boss to the nearest, one note per beat, wrapping. Pace unchanged until the sweep has been read.
Alternatives: No elite parries before the boss (Jared's suggestion; deferred: with the softer numbers the elite parry teaches Space before wave 5, and it goes if it still feels bad). Slower Crescendo burst for the first boss (deferred until the clarity fix is judged).

## D-0025: M5 polish pass: telegraph on the tower, faster bolts, wave-clear transition
2026-10-25 · accepted (Jared agreed the path in `notes/path-ahead-2026-10-25.md`)
Context: Third-pass playtest: the loop is fun, but elite parries were 0 of 10 (indication and timing lost), far boss bolts meant long waiting with nothing to play, and the song and notes lingered after the last creep died.
Decision: (1) No circle on the elite. When it attacks it raises a sword (white, red on the last beat); the targeted tower carries the timing: a red ring closing over the bar, four beat pips filling, the pulse crawling in. Parry window unchanged; if parries stay near zero the elite window widens next (Good 90 → 120 ms). (2) Bolts fly at 10 tiles/s, flight capped at 3 s. (3) On the last kill, open notes are cancelled (not counted), the melody drops, a clear sting lands on the next beat and the groove fades to idle. Build phase is quiet.
Alternatives: Groove running through the build phase (backlog). Chart notes during the boss while no bolt is in flight (rejected for now: the boss fight stays Space-only).

## D-0026: M6a slice 1: wider parry, tower-side parry return, gold nudge, boss escorts, bass-and-rhythm bed with streak intensity
2026-10-25 · accepted (Jared: "Let's go" on `notes/m6a-proposal-2026-10-25.md`)
Context: Full run to wave 10 with the balance "almost perfect". Remaining asks: elite parry slightly wider; parry damage came from the Conductor though the attack hit a tower; gold left unspent in a boring build phase; the boss alone wasn't exciting; the synth placeholder grated under real tracks and a miss revealed it.
Decision: (1) Parries (elite pulses, boss bolts) grade with a 110 ms Good window; notes stay at 90, Perfect at 35. (2) A parried pulse is returned by the attacked tower: its damage x3, at least 40, double on Perfect. (3) The build-phase line shows unspent gold when a tower is affordable. (4) The boss wave spawns an escort pack (about a third of a normal wave) with the boss and another 10 s later. (5) The bed is bass and rhythm only: a soft kick, a sub pulse on every beat, and a low 8th-note pulse layer; no melody. Intensity has 4 steps: every 4 landed notes or parries in a row opens one, any miss closes one. The real track sits 2 dB per missing step below full and the pulse layer 4 dB; Crescendo and Restore still slam everything in.
Alternatives: Replace the lock with Conductor shields (rejected: the lock is what Restore is for; shields come with the Archer elite in slice 2). A rising-melody layer for intensity (rejected: Jared wants nothing that sounds bad when ducked).

## D-0027: Two elite kinds, Jammer and Archer, and Conductor shields
2026-10-25 · accepted (slice 2 of `notes/m6a-proposal-2026-10-25.md`)
Context: Jared wanted enemy variety, a longer telegraph for parries (the Jammer attacks from on top of the tower), and the Expedition 33 idea of a king with shields against ranged attacks, without losing the lock that Restore exists for.
Decision: Jammer (today's elite): stands still for the bar its pulse is in the air, sword raised; unparried, the nearest tower locks; parried, that tower fires back. Archer (new): once within 10 path tiles of the Conductor it shoots an arrow down the path that lands on the next downbeat, with the same beat ticks and tell, and shoots again after 6 bars; parried, the Conductor deflects it back for 40 (80 Perfect); unparried, it breaks one of the Conductor's 3 shields (per wave), and with none left costs 1 health. Boss bolts also break a shield first, then cost 2 health. Creeps walking in always cost health. Waves: Jammers on wave 3, an Archer on wave 4, alternating from wave 5. The Conductor shows its shields as three diamonds; an incoming arrow closes a ring on the Conductor with beat pips, the same read as a pulse on a tower.
Alternatives: Archer stops at range and camps (rejected: an uncovered spot would stall the wave). Shields that regenerate mid-wave (later, maybe a draft pick).

## D-0028: Third tower (slow), one upgrade tier per tower, wave bonus raised
2026-10-25 · accepted (slice 3 of `notes/m6a-proposal-2026-10-25.md`; T-019 first pass)
Context: Jared found the build phase boring and easy to skip: nothing to buy beyond more of the same two towers, and gold piled up on perfect play.
Decision: (1) Slow tower (key 4, 30g, ice blue): range 2.2, taps every beat for 3 damage and slows the target to half speed for 1.5 s. Its note is a freeze: damage x2 (x4 Perfect) on everything within 2 tiles of the target and all of them held for 1 beat (2 beats on a Perfect). Slowed creeps tint purple, frozen ones pale blue. (2) One upgrade tier per tower: U over a tower spends its base cost again for +50% damage and +0.4 range; a white chevron marks it; selling refunds 75% of everything paid. (3) Wave bonus 12 + 3 x wave (was 10 + 2 x wave) so the upgrade sink is reachable by mid-run; kill gold and start gold unchanged.
Alternatives: Two upgrade tiers (later, with the draft and real menus). Slow tower with no note (rejected: every tower carries a note so the sweep and assignment stay uniform).

## D-0029: Archers shoot early and straight, a streak ball, musical feedback voices
2026-10-25 · accepted (Jared: "go" on `notes/m6a-followup-2026-10-25.md`, after the M6a playtest)
Context: M6a playtest: the first Archer died before it shot and arrows barely showed up; arrows following the maze read like a second boss bolt; the bell chimes for hits and parries sat outside the music; Jared wants a small Guitar Hero style streak indicator paired with the mix.
Decision: (1) An Archer shoots once it is within 16 tiles of the Conductor as the crow flies (not along the path), and again every 4 bars. The arrow flies in a straight line over the maze to the Conductor, landing on the next downbeat; the ring and pips on the Conductor are unchanged. The boss keeps its path-following energy ball, so the two ranged attacks look different. (2) A streak ball sits beside the Conductor shields: grey at intensity 0, then white, yellow, orange; it fills one quarter per landed note or parry, swells on each hit and dips on a miss. No gold bonus yet; a +1% kill gold per intensity step is in the backlog if Jared wants it. (3) All feedback sounds are short synth voices in E generated by StemSynth: a bright pluck for a Perfect, a lower pluck for a Good, a dull tick for a miss, a bass stab for a parry (brighter stab on a Perfect), a clicked stab for Restore, a thud for a lock, a low stab for the tell, and a clicked sub stab for the posture break. The bell chime stays only in M1 and the menu. (4) Wave 5 ramp deferred to the balance pass (T-019).
Alternatives: Archer stops to shoot from a fixed range (rejected again: it would stall the wave). Streak multiplier on damage (rejected: the intensity mix is already the reward; a tiny gold bonus is safer if anything).

## D-0030: Archers shoot from anywhere; feedback sounds replaceable by WAV
2026-10-25 · accepted (Jared, playtest 5: "should just make it infinite range"; sound list requested)
Context: Even at 16 tiles Jared did not see the first two Archers shoot. The synth feedback voices still feel like weak music, and Jared wants to audition alternatives himself in GarageBand.
Decision: (1) Archers shoot from any distance: the first arrow leaves on the first bar start after the Archer spawns, then every 4 bars. The arc instead of a straight line is an art task, with the sim/view split. (2) Every feedback sound looks for `game/audio/sfx/<name>.wav` first (names in `docs/notes/sound-sheet-2026-10-25.md`) and falls back to the synth voice. The folder stays out of git until a set is chosen; a chosen set is committed under `game/audio/sfx/` with a licence note. (3) The sound sheet lists each sound, its trigger, intent and a recommendation; the recommendation is mostly unpitched transients so the sounds work with real tracks in any key.
Alternatives: Tune voices per song key via `songs.cfg` (kept as an option if Jared prefers pitched sounds).

## D-0031: Sound effects are files, in packs per song; one parry press clears the beat
2026-10-25 · accepted (Jared: "if we lock in how that works I can leave this for later", "Lets build")
Context: Jared wants to make his own feedback sounds in GarageBand without waiting on code, and sees a community feature in it: custom music with matching SFX swapped in per track. A pulse and an arrow landing on the same beat could only be parried one at a time.
Decision: (1) The SFX contract: every feedback sound has a fixed name (the sound sheet, `docs/notes/sound-sheet-2026-10-25.md`); the game looks for `audio/sfx/<pack>/<name>.wav` for the current song's pack, then `audio/sfx/<name>.wav`, then the built-in synth voice. A song's pack is set in `songs.cfg` under `[sfx]` (`default = ` for all, `"file.wav" = ` per song). WAV, 44.1 kHz, 16 bit; the per-sound dB offsets stay in code. Adding a sound later means adding a name to the sheet and the table in StemSynth; nothing else changes. (2) The shipped default set is whichever pack Jared settles on; until then the synth voices are the fallback and `audio/sfx/` stays out of git. (3) One Space press resolves every projectile landing inside the parry window, each graded off the same press; the sound and streak count once per press.
Alternatives: Layering in code (a transient file plus a tone file per event) rejected for now: GarageBand layers them in one export, and the attack-layer samples in the preview folder give a starting point.

## D-0032: HALFTONE LITE is the default SFX pack
2026-10-25 · accepted (Jared: "lets try and use these on the next build")
Context: Jared has VOiD1's HALFTONE Sound Effects Pack LITE (same licence as the music pack). The synth voices were judged weak music; a designed pack gives every event a real transient now and Jared can swap files per slot without code.
Decision: The pack lives at `game/audio/sfx/halftone/` (out of git) and `songs.cfg` names it as the default for every song, including synth stems. Eleven files map to the sheet slots (table in the sound sheet); each copy is peak-normalised to -7 dB and trimmed of trailing silence, nothing else. Two alternates per slot sit in `game/audio/sfx-preview/halftone-alts/` so Jared can rename one into the pack. The in-code dB offsets are unchanged until Jared reports levels. Credit VOiD1 Gaming for both packs; contacting them is now a task (T-020), not only a backlog line.
Alternatives: Keep synth voices and layer pack transients in code (rejected: the pack already has complete sounds; layering is a GarageBand job if wanted).

## D-0033: Enemy variety and a hand-written wave script
2026-10-25 · accepted (Jared picked "Enemies and wave script first" on `notes/m6b-proposal-2026-10-25.md`)
Context: Two elites and one creep made every wave the same maze decision, and draft picks would have nothing to answer.
Decision: (1) Four creep kinds beside the grunt, each answered by a different tower or input: Runner (2x speed, half HP, in pairs; slow tower), Brute (3x HP, armour ignores the first 4 damage of every hit; heavy snipes), Swarm (packs of 6 at 0.4x HP; splash), Shade (immune to tower fire behind its veil; any landed note cracks every veil on the board for 3 beats, so Q/E answer it). (2) A third elite, the Warden: it takes every hit aimed at creeps within 2 tiles until its pulse is parried, then its cover is gone for good; the boss is never covered. (3) Every hit goes through one damage call that applies cover, veil and armour. Towers do not target a veiled Shade. (4) Waves 1 to 10 are a list of groups in `game/scripts/wave_script.gd` (kind, count, gap); waves past 10 repeat wave 10. Runners from wave 2, Swarm and Jammer 3, Brute and Archer 4, Shade 6, Warden 7. (5) Boss waves are 5 and 10; the script's groups for those waves are the escorts, half with the boss and half 10 s later. Elite spawn slots are gone; elites are script entries.
Alternatives: A fast creep that skips towers, a creep that disables Restore, a path-changing boss (all in `notes/power-and-challenge.md`, later).

## D-0034: The draft and the run
2026-10-25 · accepted (Jared: "Also build M6b-2 and 3", to test all three together)
Context: The loop had no progression and no ending: wave 10 said "N for endless".
Decision: (1) M6 is a new scene (menu key 6) on top of M5. After every cleared wave but the last, three cards; 1, 2 or 3 picks one, and N waits for the pick. Plain cards (+40 gold, +1 Restore charge, +1 shield cap, +1 kill gold) are immediate. Altering cards (Chain snipe, Undertow slowing waves, Shatter x3 on frozen, Rally returns from every tower near the elite, Encore 9 s Crescendo) once per run. Conditional cards are shown locked with their condition for the next wave (6 Perfects; no attack lands; no shield lost) and unlock Sharpshooter (Perfect snipe x12), Iron rhythm (one free Restore a wave) or Bulwark (+1 shield cap); fail and the card is lost. A draft has one plain, one altering if any are left, and a conditional 60% of the time. (2) Modifiers live in one dictionary on the song scene so later layers (talents) can set the same switches. (3) Win and lose screens show time, health, gold earned, notes hit and Perfects, parries of attacks, locks, shields lost, Restores, boss numbers and the picks. R runs again; N after a win continues endless as a test.
Alternatives: Cards as Control buttons (M6c). A draft before wave 1 (later; nothing to judge yet).

## D-0035: The second boss
2026-10-25 · accepted (same message)
Context: The boss at wave 10 was the wave 5 boss with more health.
Decision: At wave 10 the boss has its own strings and a violet crown. Volley: three bolts on 8th notes at the Conductor, each parried on its own. Stomp: a ring grows on the tile under the boss over a bar (half a bar at double-time) with beat pips and lands on a downbeat; parry it and every tower in its 2-tile reach fires back and posture builds; miss and those towers lock. Volley and Stomp alternate. After two posture breaks the strings go double-time. Boss health formula unchanged.
Alternatives: A path-changing boss (backlog). A second body and walk pattern (art, later).

## D-0036: The clickable layer, and a wider board
2026-10-25 · accepted (Jared: "Right now we cant select anything or see towers or menus to upgrade", then "Go ahead and start with all of the above")
Context: Everything in M6 ran on keys and the board drew its own text. A playtester could not click a tower, see its numbers, or pick a card with the mouse. The board was 16x16, and Jared wants maps that read horizontal.
Decision: (1) A HUD layer of plain Godot Controls on top of the drawn board, built in code (`game/scripts/hud.gd`), used by the M6 scene only. Bottom bar: one toggle button per build (with cost and the wall count), Start wave, Restore with charges, Pause. Left click on a tower selects it (white ring) and opens its panel: name, tier, damage, range, rate, what its note does, an Upgrade button with the price and a Sell button with the refund. The draft cards and the win/lose screens are buttons. Every key still works; buttons call the same functions as the keys. (2) P pauses: the audio holds, so song time and everything timed off it holds; input is swallowed while paused. BeatClock keeps the paused time itself as well as pausing the player, because a player with no live playback drops the pause flag. (3) The grid is 26 wide by 16 high from M2 on; spawn and goal sit on the middle row at the left and right edges; the M3 rock map is redrawn for it. The left-hand status column gets 150 px in M6. (4) Earlier scenes keep their drawn text; the M6 scene hides the drawn help lines while a panel is open and never draws the old "N for endless" line.
Alternatives: A scene-file (`.tscn`) HUD edited in the Godot editor (rejected for now: code-built keeps the whole UI in one readable file and diffs well; the sim/view split milestone is the moment to move it into scenes). A separate "inspect" mode toggle (rejected: click to inspect, click the board to build, is what every TD does).

## D-0037: Camera and map shape (proposed, waiting on Jared)
2026-10-25 · proposed from Jared's note ("a classic tower defense look, like frozen td or line wars style camera but maybe with a slight tilt, I want the maps to read more horizontal than vertical, even in multiplayers I imagine a 1v1v1v1 each getting a corner of a big rectangle")
Context: The art-direction note (`notes/art-direction.md`) had three open styles and a hack isometric look-test. Jared's intent narrows it a lot.
Decision (proposed): (1) The look is a classic TD read: the whole board in view, no scrolling, the grid legible at a glance. (2) Built in Godot 3D with a fixed camera tilted a little off straight down (about 60 to 70 degrees from the ground, perspective with a long lens, or orthographic), never a 45-degree isometric. Models and lighting give depth; the camera stays put. (3) Maps are wider than tall (now 26x16, landscape, spawn left and goal right). A 1v1v1v1 map is one big rectangle with a corner per player, so single-player maps are drawn as a quarter of that from the start. (4) The isometric look-test (key I) is dropped at the sim/view split. (5) These decisions become binding at the sim/view split milestone, not before: nothing in the rules code depends on them, and the first asset is the first thing that does.
Alternatives: 2D sprites top-down (fine for pixel art; loses the tilt and makes animated attacks and telegraphs hand-drawn work per direction). True isometric 2D (what the look-test showed; Jared did not ask for it).

## D-0038: Progression frame, first agreed points
2026-10-26 · accepted in part (Jared, on the progression review draft 2: "Agreed here", with amendments; the rest of the review stays proposed)
Context: The progression review (`notes/progression-review-2026-10-25.md`, live copy in the Claude Doc) replaced per-tower tiers, the draft pool and a between-run tree with four layers. Jared read draft 2 and agreed the talent section with changes.
Decision: (1) Gold upgrades apply to a whole tower type, never one tower; a type's ladder is five rungs with a two-way fork at rung 3 (medium depth). (2) Talents are a per-run tree: one point per level, first point at level 2; XP from mobs, elites and bosses at their own values, so more XP, more elites and more bosses are stats cards can grant. Five areas (Rhythm, Towers, Economy, Walls, Defence) of about 12 nodes with one capstone each at 6 deep, generic percentages until each area gets a pass; the tree links so early capstones (counter-attack is the example) are reachable from most starts and deeper investment gives more specific rewards. (3) The real run is 20 to 35 waves plus endless, TFT-match length; Demo 0 stays at 10 waves for quick test runs. (4) Tower unlocks are in-run only for now. (5) The draft is rolled (rarity and category weights), never slotted; cards, talents and luck shift the weights.
Alternatives: A WoW-sized tree now (rejected: 90% untouched in one run); between-run unlocks (deferred); guaranteed draft slots (rejected by Jared).

## D-0039: M7, the progression update
2026-10-26 · accepted (Jared: "go" on the M7 build plan, `prototypes/m7-plan.md`)
Context: D-0038 fixed the frame (type upgrades, a per-run tree, a rolled draft, longer runs). The plan turned it into one build with one big test after, and Jared approved it as written.
Decision: (1) M7 is a new scene (menu key 7; key 8 is the 10-wave quick run) on top of M6; a HUD subclass (`hud7.gd`) adds its controls. (2) Per-tower tiers are gone. Gold upgrades a whole type: five rungs, a two-way fork at rung 3 (the branch is chosen then and kept); price = base x rung multiplier x (1 + 0.1 per tower of that type) x (1 - discount). Rung 2 of Frost, Poison and Lightning adds a note to their phrase. (3) Six towers: Cannon, Splash, Frost from before; Poison (stacks that tick each beat and ignore armour; note Spread), Lightning (a hit arcs to a nearby creep; note Storm), Light (no damage: buffs towers around it and its pulse cracks nearby veils; note Chorus makes towers in reach fire for free). Forks at rung 3: Cannon Pierce/Siege, Splash Quake/Ember, Frost Deep freeze/Brittle, Poison Poison-splash/Virulent, Lightning Fork/Static, Light Beacon/Flare. Poison unlocks after 3 Frost built, Lightning after 10 Perfects, Light after a Shade dies; locked buttons show the condition. (4) XP per kill (grunt 1, runner 1, swarm 0.5, brute 3, shade 3, elite 8, boss 40), level curve 10 x 1.2^(level-1), one talent point a level from level 2. (5) The tree (`talent_tree.gd`): five areas, each three columns by four rows plus a capstone; a node needs an owned node in the row above or a cross-area link; counter-attack is Defence row 3 with links from Rhythm, Walls and Towers (3 points from any of those). Tab opens it and pauses. Capstones: Fermata, Arsenal, Bounty, Rampart, Riposte. (6) Counter-attack: after a landed parry, a yellow ring on the next beat on the creep that was struck; Space in the window lands return damage and posture again; a miss costs nothing; never during a Volley. (7) The draft (`card_pool.gd`, 44 cards): each card rolls rarity (Grey 50, Green 28, Blue 14, Purple 6, Orange 2, luck added above grey) then category (Stats, Economy, Enemy altering, Tower altering, Abilities, Special, Draft; cards bias the weights); blue and above come locked 35% of the time; orange once per run; rerolls are a card. Drafts come after every boss in the long run (four), every other wave in the quick run. (8) The run is 20 waves, bosses at 5 and 15 (first boss), 10 and 20 (crowned); creep health grows 22% a wave; endless repeats the last five waves; wave 1 starts its chart on the first bar. (9) Global stats (crit chance, crit damage, luck, enemy speed, enemy attack rate, XP and gold gain and the rest) live in one dictionary that nodes and cards add to, printed on the end screen.
Alternatives: The plan's stretch slice (Void, Land mine, Flush combos) stays out until the roster settles. A 30-wave script (20 first). Tree panel as a drawn canvas (rejected: buttons, like the rest of the HUD).

## D-0040: M7 round 2, agreed from playtest 1
2026-10-26 · accepted (Jared, on the discussion doc `notes/m7-playtest-1-discussion.md`: "I've added comments to the doc, all else I agree on"; comments: elites and up stagger but never a full Crescendo; counter shapes to be judged in play; tree open points "go with your recommendation")
Context: Jared's first 20-wave run (`notes/m7-playtest-2026-10-26.md`): cards too rare, boss phase quiet, every stagger the same, counter and note colliding, upgrades invisible, tree redundant.
Decision: (1) Drafts after every boss and after waves 3, 8, 13, 18 (eight a run); pool grows to about 80 cards; stat cards bigger (grey about +15%, green +25%, blue +40% with a twist). (2) Escorts trickle through the whole boss fight (a pack every 8 s while the boss lives); bosses after 10 summon a pack on every third posture break. (3) Crescendo charts are rolled from a small set per boss; a parried elite throw opens a two-note stagger on that elite; the counter builds half posture on a boss and splashes creeps within two tiles when it lands on a creep. (4) The counter lands on the off-beat after the parry, never on a note beat. (5) Readability pass in greybox: rung pips on towers, the fork recolours the ring, typed damage popups, poisoned creeps tinted with a stack count, burning ground and arcs drawn, a flash on the type when upgraded; rungs +40% instead of +25%. (6) Tree rebuilt WoW-style: five areas, three rows plus a capstone; row 1 nodes have ranks (0/3); row 2 needs 4 points in the area, row 3 needs 8, the capstone 12; one shared node per neighbouring pair of areas (counter-attack shared by Defence and Rhythm); first point at level 2. (7) Balance held until these land; then one more 20-wave session.
Alternatives: drafts every two levels (rejected: rewards XP builds twice); elite staggers as full Crescendos (rejected by Jared).

## D-0041: M7 round 3, agreed from playtest 2
2026-10-26 · accepted (Jared, on the discussion doc `notes/m7-playtest-2-discussion.md`: "Go on the rest of the table"; doc comments: "Lets try the tap tap. the last iteration made rapid parries very hard to make any use of it" and "Any note on the veiled shade")
Context: Jared's second 20-wave run (`notes/m7-playtest-2-2026-10-26.md`): won at 8/20 with notes 54%, parries 67%, counters 45%; waves 1 to 3 trivial, waves 12 to 15 stacked notes, parries and counters on top of each other, Shades too Bloons-like, bosses a parry game after the first pack, the eye split between towers and the Conductor.
Decision: (1) The flow: one ask per beat. Elite throws land on beat 1 (late-run elites may land on beat 3), notes sit on beats 2 to 4 by a wave pattern: waves 1 to 5 Q on beat 3 every other bar; 6 to 10 Q on 3 and E on 4; 11 to 15 one rolled pattern per wave; 16 and up patterns re-roll every phrase and E may sit on the "and" of 4; a Crescendo has no throws. The bar is printed over the board with the live beat lit. (2) The counter is a quick tap: a second Space within 150 ms of a landed parry, no ring; a Perfect parry makes a Perfect counter; payoff unchanged. (3) Shades are never immune: a veiled Shade takes 10% damage; any landed note cracks every veil a step (20%, 30%, stripped), a Perfect two steps; the Light tower cracks a step per downbeat in reach. (4) Creeps start at 30 HP and grow 1.15 a wave (was 18 and 1.19). Run-long draft effects leave grey: Rabbit's foot +1 luck, Training manual green, Open hand blue. (5) Boss escorts come as three big packs on posture breaks 1, 3 and 5 (fallback 20 s), bosses after wave 10 summon on every second break; between throws the boss plays a quiet chart, one Q a bar on the tower nearest it. (6) Eye split option A: a bolt is parried at the boss as it leaves (the ring closes on the boss), an unparried bolt flies on and lands. Options B (boss stands centre) and C (Conductor in the centre) go to the backlog for the sim/view milestone. (7) A per-wave log of notes, parries, counters and health lost on the end screen and in the console. (8) Balance waits for one more 20-wave session with that log.
Alternatives: a timed counter ring copying the note ring (rejected by Jared: the tap); Shades cracking only from towers in reach (rejected: any note); snipe x5 to make sparse early notes count (left out, no call made).
