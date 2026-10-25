# Demo 0 plan

_Written 2026-10-24 after the first full review. Decision: stop refining on paper and build (D-0010)._

## Why now

The vision has a clear hook, five pillars, controls, a damage philosophy, and a boss direction. Every open question left is a **feel** question ("is this fun?", "is this too much input?", "does the music read?"), and paper can't answer those. A greybox build can.

## Approach

One evolving greybox project instead of five throwaway prototypes. Each milestone is **playable on its own** and ends with a short results note (`prototypes/M#-results.md`) recording what felt good or bad and the keep/kill calls. New ideas that come up while playing go to the backlog, not into the current milestone.

Placeholder everything: colored shapes for art and **procedurally generated synth stems** for music (kick, hats, bass, lead at 120 BPM), so nothing waits on assets.

## Milestones

| # | Milestone | Playable result | Answers |
|---|---|---|---|
| M0 | Setup | Repo, engine project, runs on Jared's Mac and PC | Workflow works |
| M1 | Beat and input feel | Click track on the audio clock. Tap Q/W/E/Space and get Good/Perfect/Miss with an offset readout and a calibration slider. | P-01: is timing tight on both OSes? |
| M2 | Maze | 20x20 grid. B for build mode, place walls and 3 tower types, creeps reroute live via flow field. Gold economy, objective health. | P-02 |
| M3 | The maze plays the song | Towers fire on their instrument patterns, stems play only while towers have targets, crossfire accents, Q/W/E Resonance, perfect = crit. | P-04: can you hear your maze, and do you rebuild for accents? |
| M4 | Suppress and Restore | An elite creep that suppresses towers, stems drop out, F restores on the downbeat with an Overcharge salvo, limited charges. | P-03: does silence create tension, and does restoring feel great? |
| M5 | First boss | Boss model C or D, 2 attack strings on the beat aimed at the Conductor, Space to parry, posture, Crescendo (+30%). | P-05 |
| M6 | Demo 0 | 10 scripted waves with five creep kinds and three elites, a pick-1-of-3 draft between waves, bosses at 5 and 10, win/lose screens, and a mouse layer (select, tower panel, buttons). | Is the whole loop fun for 10 minutes? |

The single Conduct key (P-04 arm B) is a settings toggle added in M3, so both can be compared without a separate build.

## Defaults chosen so building can start (override any time)

- **Beat:** one global BPM, with towers playing patterns on it (closes the "global vs per-tower" question; the sequencer model implies it).
- **Stems:** 3 tower stems plus a 4th "lead" stem that belongs to the Conductor and plays on Resonance, parries, and Restores.
- **Health:** one health pool at the objective. Creeps that leak and boss hits that land on the Conductor both drain it. The Conductor is a fixed marker at the objective.
- **Boss for M5:** decided when we get there, between C and D, based on what M3–M4 teach us.
- **Draft content for M6:** simple tower mods (pattern change, range, crit chance) and one wave modifier.

## Not in Demo 0

Everything in the backlog: multiplayer, quests, EXP and talents, second currency, specs, theme and art, real music, Steam integration, controller support.
