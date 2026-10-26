# M7 build plan: the progression update (proposal, 2026-10-26)

Status: proposed, waiting on Jared's go. Live copy for markup: Claude Doc "M7 build plan: the progression update". One large build on top of M6 that packs in everything agreed in the progression review (D-0038) and as much of the rest as fits, then one big test and notes session.

The question: does a 20-wave run with a build to plan (the tree), a build to react to (the draft) and type-wide upgrades stay interesting from wave 1 to the last boss?

## Slices, in build order

| # | Slice | What goes in |
|---|---|---|
| A | Type upgrades | per-tower tiers removed; five-rung ladder per type, two-way fork at rung 3; price scales with rung and towers of that type; Upgrade per type on the build bar |
| B | Six towers | Poison, Lightning, Light join Cannon, Splash, Frost; each with its own note; in-run unlocks on greyed buttons (Poison: 3 Frost built; Lightning: 10 Perfects; Light: a Shade dies) |
| C | Levels and XP | XP per kind (grunt 1, runner 1, swarm 0.5, brute 3, shade 3, elite 8, boss 40); curve from 10 XP, +20% a level; level bar; a point per level from level 2 |
| D | Talent tree | five areas (Rhythm, Towers, Economy, Walls, Defence), ~12 nodes each, generic %; capstones Fermata, Arsenal, Bounty, Rampart, Riposte; three cross-area links; counter-attack as Defence's early capstone 3 points in; tree panel (T) pauses the game |
| E | Counter-attack | after a landed parry, a yellow ring on the next beat; Space lands return damage again and posture; miss loses nothing; off during a Volley |
| F | Draft rebuilt | rolled rarity (Grey 50, Green 28, Blue 14, Purple 6, Orange 2; luck adds above grey) and category (Stats, Economy, Enemy altering, Tower altering, Abilities, Special, Draft); soft floor vs three of a kind; locked cards at blue+; ~40 cards; after every boss; M6 cards retired |
| G | Longer run | wave script to 20; bosses 5 and 15 (first boss), 10 and 20 (crowned), later ones with more health and one new string each; endless after 20; 10-wave quick run on the menu; wave 1 fixed (chart from the first bar, 5 creeps) |
| H | Global stats | crit, crit damage, luck, enemy speed, enemy attack frequency, XP gain, gold gain as one block nodes and cards add to; printed on the run screen |
| I | Stretch | Void, Land mine, Flush combos (five of a type plus gold become its ultimate; the other four become crumbling walls that break next build phase) |

## Out of M7

Void, Land mine and combos beyond Flush (after the roster settles); art and the sim/view split (after M7's playtest); between-run anything (deferred); sounds (parked); a 30-wave script (20 first).

## How it ships

Build order A to H, each pushed when its bots pass; M7 is menu key 7 on top of M6. Bots: full 1x 20-wave run, tree bot, draft roll check (10,000 cards), counter timing on the boss, M3 to M6 regressions. Docs with the build: D-0039 scope, README M7, M7-results, wave script and card pool as editable files.

## The test session

Two 20-wave runs (one deep in one area, one spread), then a 10-wave quick run. Report in one pass: tower-or-rung decision and the fork; towers never built and notes waited for; whether unlocks changed play; first point timing, points by wave 20, planned route or not, capstones that mattered; counter as riposte or tax; whether four drafts each mattered, broken or boring cards, locked cards; where the run dragged or rushed; health and gold at 10, 15, 20 and the stats block.

## Risks and calls made alone

Balance will be off (tuned only until bots clear 20 waves wall-less at 1x). The tree panel is a greybox grid. If scope fights the clock, cut from the end (H, then G's new strings, then F's pool), never A to E. Calls made without asking: node percentages, prices, XP values, the script, the 40 cards, unlock counts. Anything that changes what a layer is comes back to Jared first.
