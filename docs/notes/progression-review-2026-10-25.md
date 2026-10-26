# Progression review (draft 2, 2026-10-26)

Status: draft 2, rewritten around Jared's notes from his first read (logged in `power-and-challenge.md`). Nothing here is decided. The live copy Jared marks up is the Claude Doc "Progression review (draft)"; this file mirrors it. Agreed points go to `decisions/decisions.md`.

## 1. What the playtest and the first read said

- Core loop is right ("feels great as a core loop"). Power today is one axis: gold into tower tiers, plus a draft of small numbers. Jared loved the infinite-range snipe most.
- First read (2026-10-26): per-tower upgrades fight the random-note play, so upgrades go global per tower type; talents are a per-run tree with areas and capstones; the draft needs rarity and category, rolled, not slotted; many more towers, unlocked with requirements; two new mechanics, counter-attack and tower combinations. Draft 1's bizarre list missed; its grey examples were too boring.

## 2. The four layers

| Layer | When | Currency | Job | Mood |
|---|---|---|---|---|
| Type upgrades | in-run, any time | gold | build more, or upgrade a whole tower type | mostly plain, sometimes transforming |
| Talent tree | in-run, one point per level from level 5 | talent points | the build you plan | deliberate, PoE-style |
| Draft | in-run, after each cleared wave | a pick | the build you react to; rolled for rarity and category | surprising, Megabonk-style specials |
| Combinations | in-run, build phase | gold and five towers | turn a crowded maze into one unique tower | poker-hand discovery |

Rules: nothing upgrades one tower (every gold upgrade applies to a whole type). The tree is chosen, the draft is dealt (no randomness in the tree, no guaranteed slot in the draft). Talents are per run; what carries between runs is at most unlocks (open question).

## 3. Towers: roster, unlocks, type upgrades

Eight base types, each with one role and one note behaviour: Cannon (today's Heavy; infinite-range snipe), Splash (wave), Frost (today's Slow; freeze), Poison (stack spreads to touching creeps), Lightning (chain to every creep for one tick), Light (every tower in 2 tiles fires once free; cracks veils), Void (holds the pack for a beat), Land mine (arms every mine at once). If two towers have the same note they are one tower.

Unlocks, Warcraft 3 style: Cannon, Splash, Frost always; the rest unlocked by an in-run requirement shown on the greyed button (Poison: 3 Frost built; Lightning: 10 Perfects; Light: a Shade killed; Void: a parried Stomp; Land mine: a wall-less wave). Numbers are tuning. Open: do unlocks persist between runs.

Type upgrades (gold): a short ladder per type applying to every tower of that type. Rungs 1 and 2 plain (+damage, +range, +rate); rung 3 transforms (Poison to Poison-splash, Cannon pierce, Frost freeze every third hit, Lightning one more jump, Light radius doubles). Price rises per rung and per tower of that type on the board (lever against mono-type mazes).

## 4. Talents: a per-run tree

One point per level from level 5; XP from kills, notes, parries, waves (tuning). A 6-minute 10-wave run gives about 8 points, so start with five areas of about 12 nodes (60 nodes), one capstone per area at 6 deep; grow the tree only when runs grow.

| Area | Nodes | Capstone idea |
|---|---|---|
| Rhythm | notes more often; hit notes echo; Perfects do more; parries add a note | Fermata: a Perfect parry freezes every creep for a beat |
| Towers | damage, crit, crit damage, range per type; cheaper type upgrades | Arsenal: unlock one extra tower type now |
| Economy | gold per kill and wave; luck; more elites and bosses | Bounty: bosses pay triple and come a wave early |
| Walls | walls slow; thorns; wall cap; crumbling walls last longer | Rampart: walls upgrade like a type |
| Defence | parry window; parry return; parries hit 4 extra; shields; Restore | Riposte: every counter lands as a second parry |

A talent never adds randomness and never names a card.

## 5. The draft: rarity times category, rolled

Three cards after each cleared wave; each is two weighted rolls (rarity, category). No guaranteed slot. Luck, talents and Draft-category cards shift the weights.

Rarity (base weight, what it may do): Grey 50 one small stat; Green 28 one large stat or small rule; Blue 14 a rule for the run; Purple 6 a rule touching two systems; Orange 2 a run-defining special, once per run, not before wave 3.

Categories: Stats; Economy; Enemy altering (speed, attack frequency, kinds, counts); Tower altering (one type's fire or note); Abilities (parries, counters, Restore, notes); Special (ghost that haunts the nearest enemy; Joe's dagger first-hit crit; walls slow; walls have thorns); Draft (a category twice as common; a reroll a wave; next draft shows five).

Rules: soft floor, no three of the same category (third rerolls once). Blue and above can come locked with a play condition for the next wave. One line per card: name, effect, trade. Draft 1's grey examples and bizarre list are dropped.

## 6. New mechanics

Counter-attack: every parry opens a yellow ring on the parried enemy on the next beat; Space on the beat lands the counter; a miss loses only the counter. Space becomes a two-beat phrase. Test on the wave 10 Volley first (six presses on alternating 8ths): counters off during a Volley, or one press per string.

Tower combinations: in a build phase, five towers plus gold become one unique tower; the other four become crumbling walls that break at the next build phase (wall cap holds). Hands, poker-style: Flush (five of a type, its ultimate), Full House (hybrid), Straight (five different, takes every note). Each hand is a designed tower. After the roster.

## 7. Open questions

Levels and XP; unlock persistence; one transformation per type or a branch at rung 3; cut two of the eight, anything missing; counters during a Volley; keep the draft floor.

## 8. Proposed order of work

1. Agree sections 2 to 6 in a decision. 2. Type upgrades replace tiers; roster to six (Poison, Lightning, Light) with unlocks. 3. Draft on rarity times category with Draft and Special categories and locked cards. 4. Counter-attack, tested on the boss. 5. Talent tree, five areas, with levels. 6. Void, Land mine, then combinations. 7. Sim/view split, then art.
