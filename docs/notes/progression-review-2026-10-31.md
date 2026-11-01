# Talents, cards and upgrades review (T-036)

Claude Doc (live version, with Jared's notes lines and the tree diagram): https://claude.ai/artifact/5vVeQfZWxJaCj6WzzuricA
Status: tree agreed on paper 2026-11-01 (D-0057); cards and upgrades waiting on Jared's markup. Ground rules from D-0056. Jared's canvas snapshot: `sketches/talent-tree-2026-10-31.md`.

## Talent tree (agreed on paper, D-0057; 2026-11-01)
Two sides from Counter Attack, crossing at Perfect Solo, to Jared's builder mockup (`sketches/talent-tree-screen-reference-2026-11-01.png`). You only move up. Each node taken once.

| Node | Cost | Where | What it does |
|---|---|---|---|
| Counter Attack | 1 | Bottom middle | Counter on the beat after a parry, big stagger damage |
| Well Constructed (working name) | 1 | Towers flavour 1 | +15% damage, every tower (tune) |
| ? (name pass) | 1 | Towers flavour 2 | +25% range, shown on the board (tune) |
| ? (name pass) | 1 | Towers gate | +30% attack speed |
| Unlock Lightning | 1 | Towers outer | Lightning joins your roster |
| Thorny Walls | 1 | Towers far left, power node | Creeps near walls slowed and bleed, more the longer they stay (mechanics later) |
| Improved Lightning | 1 | Towers outer, upper | Draft: arcs jump once more |
| Unlock Poison | 1 | Towers inner, to Perfect Solo | Poison joins your roster |
| Improved Poison | 1 | Towers upper inner, from Perfect Solo | Draft: poison jumps on death; gives Poison too |
| Unlock Light | 1 | Towers upper | Light joins your roster |
| Improved Light | 1 | Towers top, capstone | Draft: towers in its glow also fire on off-beats |
| Perfect Solo | 1 | Middle capstone | All-Perfect Crescendo: auto parry and counter 8 s |
| Freestyle | 1 | Rhythm flavour 1 | Good window +15 ms |
| Perfect Freestyle | 1 | Rhythm flavour 2 | Perfect window +5 ms |
| Defensive Percussion | 1 | Rhythm gate | Parry window +25 ms |
| Grace Notes | 1 | Rhythm inner, to Perfect Solo | 8th-note accents; hits 70%, Perfects 130% extra |
| Solo | 1 | Rhythm outer | Clean Crescendo: 2 shields, 1 restore |
| The Right Instrument | 1 | Rhythm far right, power node | Perfect note special per tower type |
| Melodic Healing | 1 | Rhythm upper inner, from Perfect Solo | All-Perfect Crescendo heals 1 |
| Improved Restore | 1 | Rhythm outer, upper | Restore starts the next Crescendo |
| Slowing Song | 1 | Rhythm upper | Notes slow 5% (Perfect 15%), stacks 3 |
| Improved Counter Attack | 1 | Rhythm top, capstone | Draft: +50% damage, hits all within 2 tiles, window 150 to 250 ms |

- Points: 1 after Night 1 (Counter Attack), then 3 after each of Nights 2-4: 10 in a run. Every node costs 1; the longest climb to a top capstone is 9 nodes, so one run reaches the top of one side, never both (Jared: reach the end of the tree in one run; capstones cost the investment, not points).
- XP stays a stat (D-0038), tuned so a night gives about 3 points. No respec in a run.
- Open questions: the name pass (backlog), Thorny Walls mechanics.

## Cards (proposal)
- 4 cards a run (pick of 3 after nights 1-4). Talents are the plan, cards are the twist; no card repeats a talent.
- No flat stats; one-line text; draft-only cards (reroll, wide hand, luck) removed.
- Rarity: Rare ~65%, Epic ~28%, Legendary ~7% (max one a run); luck nudges up.
- Starter 20: Splitting headache (Jared: creeps split on death, but Cannons hit two, splash reach up, Lightning +1 bounce; Epic), F beat (Jared: a third note on F; Legendary; design open), Perfect Accumulation (Jared: each Perfect +0.1% tower crit for the run; Rare), one open slot, Piercing shot, Siege engine (new), Sharpshooter, Rally, Echo, Off-beat (new), Heavy boots, Light boots, Wanted posters, Dread, Blood money (new: -3 health, +100 gold each night), Difficulty tome, Glass cannon, Fermata (L), Haunting (L), Joe's dagger (L).

## Upgrades (option A agreed by Jared, 2026-11-01)
Rung 1 = pick a fork (~2x tower price), rung 2 = that fork's mastery (~4x). One U press upgrades the whole type. Forks are today's game; masteries are drafts.

| Tower | Fork | What it does | Mastery |
|---|---|---|---|
| Cannon | Pierce | Snipes also hit the two creeps nearest the target | Skewer: snipes pass through every creep in a line behind the target |
| Cannon | Siege | Double damage to Brutes and bosses | Breach: hit creep takes +25% from all towers for 2 s |
| Splash | Quake | Hits stagger for half a beat | Aftershock: second wave a beat later, half damage, staggers again |
| Splash | Ember | Burning ground for a bar | Wildfire: burning ground spreads a tile per beat, up to 3 |
| Frost | Deep freeze | Every third hit freezes for a beat | Shatter: a frozen creep that dies freezes all within a tile |
| Frost | Brittle | Frozen creeps always take crits | Cold snap: slowed creeps count as frozen |
| Poison | Poison-splash | Poisons every creep within a tile | Plague: poison stacks 3 times |
| Poison | Virulent | Poison never wears off | Necrosis: ticks 10% harder each beat it stays |
| Lightning | Fork | One more jump | Storm: jumps lose no damage |
| Lightning | Static | Arcs reach 4 tiles | Overcharge: every fourth strike stuns for half a beat |
| Light | Beacon | Doubles radius | Lantern: towers in the light attack 15% faster |
| Light | Flare | Pulse cracks every veil | Daybreak: cracked Shades take +25% until they die |

Clashes to settle: Fork = Improved Lightning talent (lean: talent becomes "arcs chain to poisoned creeps for double"); Shatter name reuses the cut card; Siege vs the Siege engine card (lean: drop the card).

## Next
On go: a D-entry, folded into the demo plan. Then the enemy doc and UI slice markup before the scope lock. No build changes until then.
