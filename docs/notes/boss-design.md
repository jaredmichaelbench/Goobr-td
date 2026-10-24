# Boss design: working notes

_Started 2026-10-23 from Jared's comment on vision pillar 5._

## Jared's direction (verbatim intent)

- Rhythm on bosses should focus on **parrying attacks**.
- **Not** a big enemy hobbling through a long maze while you play Guitar Hero.
- It should **attach** to you and feel **souls-like**.
- **A rhythm, but not extremely obvious.**

## What this rules out

- Bosses that walk the creep path like a fat creep.
- Note highways, scrolling beat bars, or any UI that turns the fight into a rhythm-game chart.
- Pure stat checks (resist X, needs damage type Y).

## Boss models (all open)

All options stay open. Each one is a candidate for P-05, and none is ruled out.

### 1. How the boss shows up ("attach")

- **A: the boss latches on.** It enters, travels a short way, then anchors to a spot on or beside your maze (a node, a wall, or the edge of the board) and fights from there. It may reposition between phases. The fight happens around it, so the long maze isn't a conveyor belt.
- B: the boss moves, but in lunges between anchor points chosen by your layout (it jumps to the nearest choke, the longest straight, the densest tower cluster).
- C: the boss stays off-board and reaches in (hands, beams, tendrils). Simpler to build, less physical. _Jared (2026-10-23): appealing because the simplicity lets us focus on rhythm and satisfaction. A strong candidate for the first prototype._
- **D (Jared, 2026-10-23): the boss walks the maze and fires at your Conductor.** The boss does walk the path, but the fight is its **ranged attacks thrown at the Conductor**, which you parry. **As it gets closer, its attacks get faster and travel a shorter distance**, so the windows tighten. A long maze buys you slower, more readable attacks.
  - Why it fits: mazing has a direct skill payoff (time and readability), not just damage. It also maps onto music naturally, because the boss's approach can raise the tempo, so the track builds as it gets closer.
  - Watch out for: the "big guy hobbling through the maze" feel Jared doesn't want. Its attacks have to be the main event, not its walk.
  - Possible hybrid with A: walk and fire (D), then latch on at the last stretch for a final close-range phase (A).

Why the maze still matters: the boss's moves read your layout. A beam cleaves down your longest straight corridor, a slam hits your densest cluster, a sweep follows a wall line. Your maze decides what attacks it has available and where its stagger lands in your kill-box.

### 2. The hidden rhythm

The rhythm lives in the boss's **attack strings**, not in the UI.

- Every attack lands on the song's beat grid, but you read it from the **tell** (wind-up animation, sound cue, a glint), like a souls boss. No timing bar.
- Strings are learnable patterns: "slam, slam, ... delayed slam" is a musical phrase you start to feel after a couple of attempts. That's the "rhythm but not obvious."
- Souls tricks map neatly onto music: **delayed swings = syncopation**, **combos = phrases**, **phase change = tempo or key change**, the final phase = the track's climax.
- Hi-Fi Rush, Sekiro deflect chains, and Crypt of the NecroDancer bosses are useful references for how hidden or visible the beat should be.

### 3. What gets hit, and what a parry does

- Targets are **your towers, walls, and the Conductor Core**, never the maze geometry permanently.
- **Parry hits:** the attack is deflected, and the boss takes **posture** damage (Sekiro-style). Your towers keep playing.
- **Missed parry:** the hit towers are **suppressed** and their stems drop out. This feeds straight into the Restore loop you already designed, so failing a parry gives you a second rhythm beat to recover.
- **Posture break:** the boss is staggered and falls into a **Crescendo** window. Every tower overcharges (about **+30% damage**, a starting number to tune), and the full mix slams in. It's a reward, not the only way to hurt the boss. _Jared (2026-10-23): don't make Crescendo all that matters, and don't make the boss feel invincible until it lands._

That gives a full souls loop: learn the tells, parry the string, break posture, punish.

### 4. Where builds fit (Jared's concern about losing "attack combat" builds)

Parry outcomes are the hook for defensive builds: thorns (deflects deal more), ward (shorter suppression), posture damage, Crescendo length. See the backlog items for talents and specs.

## The Conductor and what you're protecting (theme still open)

Jared's ideas, 2026-10-23. All kept as open questions.

- **The towers protect something** at the end of the path, and that's what creeps are heading for. It's theme-agnostic for now: a wall, a gem, a chest, "the golden sword of truth".
- **The Conductor could be a character**, such as a knight standing at the objective. The boss throws ranged attacks at them, and parries are the knight deflecting. This gives parries a physical target and an animation, which answers the earlier "what is the boss even attacking?" question from the pitch notes.
- Open: is the Conductor's health the run's health, or is the objective separate? Does the Conductor ever move, or is it fixed at the objective?
- Open: does the Conductor also need to "conduct" visually (gesture on Resonance or Restore), which would tie the music and combat identities together?

## Open questions

0. Which boss model goes first in P-05: C (simplest), D (walking boss with distance-scaled attacks), or a hybrid? Proposed: C or D, because both aim attacks at the Conductor, which keeps the prototype focused on parry feel.
1. ~~What is the player "holding" during a boss fight?~~ Answered by Jared (2026-10-23): keyboard play, League-style. Parry is a dedicated key (proposed Space), with no cursor aiming, and the mouse is for camera and pings. See `controls.md`.
2. ~~Does HP damage come mostly from Crescendo windows or steadily from towers?~~ Answered by Jared (2026-10-23): **steady tower damage is the main source.** Build, talents, tower choice, and base damage must still carry the core TD loop. A good maze plus decent note play should kill the boss. Crescendo is about a +30% damage window. **Perfect notes are critical strikes**, which spreads skill payoff across the whole fight instead of one window.
   - Damage sources, roughly in order: (1) tower base damage from build and maze, (2) note play with crits on perfects, (3) Crescendo bonus, (4) parry reflects.
   - Follow-up: tune so a strong maze with no perfects still wins (slowly), and great play shortens the fight noticeably. Watch that the boss never feels immune between Crescendos.
3. Does the boss phase use the same track as the wave, or its own track?
4. How many attack strings does the first boss need? Proposed: 2 strings plus 1 delayed variant, 2 phases.

## P-05 updated test

_Placeholder based on option A. The M5 boss will be C or D (see `prototypes/demo-0-plan.md`)._ One boss anchors at the end of the longest straight. It has two strings, a corridor beam and a cluster slam, each on the beat with an animation tell and no timing UI. A parry deflects and adds posture damage. A miss suppresses towers, and Restore applies. Posture break opens a 6-second Crescendo. Pass: it feels like learning a souls boss, not reading a chart.
