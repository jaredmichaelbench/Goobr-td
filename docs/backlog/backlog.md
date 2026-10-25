# Backlog

Ideas that are good but not in the first playable. Nothing here is rejected. Each item notes where it came from and what would bring it back. When something is promoted, move it to `tasks/tasks.md` and note the decision.

Status tags: `parked` (later), `needs-proto` (promising, needs a test), `maybe` (unsure it fits).

## Gameplay

| Item | Status | Source | Notes / what would promote it |
|---|---|---|---|
| In-run quests that unlock towers ("route a wave through the same 4-tile gauntlet twice without leaks") | needs-proto | Pitch, prompt 2 | Strong fit for pillar 1. Promote once the core loop is fun; quests should be hard and unique. |
| Conductor EXP + level-up talent drafts (Kinetic Cadence, Barbed Masonry, Overclocked Choke) | parked | Prompt 3 | Adds run identity. Risks overlapping with the per-wave draft; pick one progression spine first. |
| Conductor specs: Glass Conductor (1 Restore, perfect refunds) / Iron Metronome (max Restores, thorns while suppressed) | parked | Prompt 4 | Natural build archetypes around Restore. Needs talents first. |
| Crescendo stacking: bonus EXP for waves cleared without a Restore | parked | Prompt 4 | Small, cheap, good. Depends on EXP. |
| Thorns / defensive stats that change parry outcomes | parked | Prompt 3 | Jared's concern: don't lose "attack combat" build variety. Revisit with boss design. |
| Per-tower resonance reticles / Perfect Strike on impact | maybe | Prompt 1 | May conflict with a global beat. Decide via open question #1. |
| Wall parries / kinetic cornering knockback | needs-proto | Prompts 1–2 | Candidate second input type. |
| Pre-wave mini-encounters / an action game that sets your build options | maybe | Prompt 2 | Interesting but a second game inside the game. |
| Boss arena manipulation (temporary path cleaves, node lockdowns, shockwaves down straight corridors) | needs-proto | Prompt 2 | Expand after the first boss works. Must not permanently break mazes. |
| Boss buffs itself unless the player keeps the rhythm (alternative boss model) | maybe | Prompt 3 | Superseded as the main model by D-0005; keep as a variant mechanic for one boss. |
| Mutant unit behaviors / temporary lane modifiers per wave | parked | Prompt 2 | Content for the per-wave roll. |

## Economy

| Item | Status | Source | Notes |
|---|---|---|---|
| Difficulty curve and tower balance | needs-proto | M2 playtest | M2 never got hard by wave 9. Tracked as T-019 after M3. |
| Second currency (Aether Shards) from lotteries, quests, perfect parries | parked | Prompt 3 | Keep one currency until drafts prove they need it. |
| Inter-wave Black Market: reroll modifiers, socket runes into towers, buy panic buttons | parked | Prompt 3 | Comes with second currency. |
| Restore charges purchasable in shop | parked | Prompt 4 | |
| Unstable cores dropped by creeps with random modifiers; 3-of-a-kind synergy sets | needs-proto | Prompt 1 | The "Poker TD without cards" idea. Strong candidate for the per-wave draft content. |

## Multiplayer

| Item | Status | Source | Notes |
|---|---|---|---|
| 1v1v1v1 arena: parallel boards, income-driven sends (Line Tower Wars / Tetris 99) | parked | Prompt 3 | Big scope. Architecture is friendly (command stream over Steam Datagram Relay, no lockstep). Post-launch or late-dev. |
| Disruption sends: Frequency Jammers / Beat Breakers that break rivals' rhythm | parked | Prompt 4 | Depends on multiplayer. |
| Skill "garbage" dumps to the leader on flawless play | parked | Prompt 3 | Depends on multiplayer. |

## Later areas (own workstreams, not started)

| Area | Status | Notes |
|---|---|---|
| Theme and setting | parked | Undecided. Constraint so far: something at the path's end is protected (wall, gem, chest, sword...), and the Conductor may be a character such as a knight. See `notes/boss-design.md`. |
| Art direction | parked | Isometric / top-down. Readability of the grid and telegraphs first. |
| Asset procurement | parked | Asset store vs. commission vs. make. |
| Music | parked | Core to the game, so it starts early: need stem-friendly tracks, fixed BPM, loopable. Likely the first "later area" to open. |
| Revenue and Steam strategy | parked | Pricing, Steam page timing, Next Fest demo, wishlists. |
| Steam Input / controller support | parked | Use Steam Input API. |

- **Timeline: keep, fade, or remove?** (2026-10-25, from M3 playtest) Jared worries players will just watch the timeline. Options: fade it out after the first waves, show only the next 1-2 notes, or drop it once the rhythm is learned. F6 in M3 lets us test with and without.
- **Clickable UI and menus** (2026-10-25, Jared) The game should feel like "press B for a build menu," with more menus later for talents and a rogue-lite skill tree. Everything in Demo 0 is hand-drawn, so buttons would be custom code. Build a real UI layer (Godot Control nodes) in M6 once the menus are known.
- **Song selection for release** (2026-10-25, Jared) The `[`/`]` song switcher and the BPM-in-filename convention are test tools only. The shipped game needs a thoughtful approach to which song plays when (per map, per act, player choice?), and charts authored per song rather than the fixed M3 chart.
