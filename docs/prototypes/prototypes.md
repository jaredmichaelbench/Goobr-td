# Prototype plan

Greybox only. Each prototype answers one question and ends with a short write-up (what we learned, keep/kill), saved next to this file as `P-0X-results.md`.

Ordered by risk: the scariest unknowns first. **These are now built as milestones of a single Demo 0 project. See `demo-0-plan.md`.**

| Id | Question it answers | Test | Pass looks like |
|---|---|---|---|
| P-01 Audio sandbox | Can we get tight, consistent rhythm timing on Windows and Mac? | 120 BPM loop on the DSP clock, moving timing bar, tap Space, measure average offset on both machines. | Offset consistent and correctable with a calibration slider; window feels crisp on both. |
| P-02 Grid engine | Does live rerouting feel frictionless? | 20x20 grid, flow fields, place walls mid-wave, dummy creeps reroute. | No hitches; rerouting is readable. |
| P-03 Conductor loop | Is "fail, restore on the beat, overcharge" fun, and does stem-dropping create tension? | 4 towers mapped to 4 stems; a dummy hit suppresses 2 and mutes bass + drums; 200ms Restore window on the next downbeat brings them back with a salvo. | Jared wants to keep playing it. Silence feels tense, the restore feels great. |
| P-04 Maze as instrument | Does the sequencer baseline make mazing matter, and how much input is too much? | 3 tower instruments, crossfire accents, Q/W/E per instrument (arm A, baseline), over an 80-second wave in a serpentine maze. Arm B: a single Conduct key for everything. Details in `notes/maze-rhythm.md` and `notes/controls.md`. | Players hear their maze, rebuild to get more accents, and we find the accents-per-wave budget. Pick arm A or B. |
| P-05 First boss | Can a souls-like parry boss work in a player-routed maze? | Boss anchors at the end of the longest straight. 2 strings (corridor beam, cluster slam) on the beat, animation tells only. A parry builds posture; a miss suppresses towers and Restore applies; posture break opens a 6s Crescendo. Details in `notes/boss-design.md`. | Feels like learning a souls boss, not reading a chart, and mazing still matters. |

Deferred: Conductor EXP pacing test and the 2-instance multiplayer economy test (see backlog).
