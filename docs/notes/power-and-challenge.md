# Power and challenge (design notes, started 2026-10-25)

Jared wants two passes before Demo 0 is called done: one over every way the player gains power, one over every mechanic that challenges the player and how it can be levered. This note collects the raw ideas; decisions go to `decisions/decisions.md` when made.

## Jared's notes (2026-10-25, verbatim-ish)

- **Tech tree should be kind of boring**: straightforward, mostly global tower improvements. Range per power type. Parry damage per tower type. Parry window. AoE range on a perfect parry. AoE range on a perfect note. Damage. Crit damage.
- **Rogue-lite elements should be game-altering**: all archer towers become chain-lightning towers; unlocks for additional tower types. Elevate the game without making balance impossible.
- Wants a good amount of enemy variety, tower variety and interactions. Keeps coming back to poker TDs (combine towers into a hold'em hand): don't copy, but have dynamic stuff and upgrade options that are more "out there".
- Maybe the tech tree should also dabble in exciting. Number of tower types still open: could be a low starter count that evolves or unlocks variations through quests or trees.
- **Dynamic conditional upgrades**: shoot for a build but you have to hit perfects (or similar) to unlock the tree or talent nodes. "Sick", not settled.

## Working frame (Claude, to discuss)

Three layers, each with its own job, so they don't fight:

1. **Tower upgrades (in-run, gold)**: boring on purpose. One or two tiers per tower: damage, range, fire pattern. This is the TD economy decision every wave. M6a slice 3.
2. **Draft picks (in-run, between waves, pick 1 of 3)**: the rogue-lite layer. Some plain (gold, a Restore charge, +1 shield), some altering (heavy towers chain their snipe to a second target; splash waves slow; the next boss opens staggered). Conditional unlocks live here: a pick can be "locked" until a condition is met this wave (4 perfects in a row, a flawless parry string) and shows what it would be, so you can play for it. M6b.
3. **Talents (between runs, permanent)**: the global, boring tree Jared describes: parry window, parry damage, crit damage, range per type. Slow, steady, never changes what a tower does. Post Demo 0.

Towers: start with 3 (heavy, splash, slow) and let draft picks and talents reshape them (evolutions) rather than adding many base types early. Variety from interactions beats variety from count.

## Challenge inventory (what levers exist today)

- Creep count and HP growth per wave (30%/wave), speed growth.
- Elites: Jammer (tower lock via pulse), Archer (shields via arrows), their counts and kinds per wave, pulse/arrow cooldowns, lock length, lock radius.
- Boss: HP mult, speed, string shapes, tempo by distance, bolt speed, escorts.
- Map: rock layout, wall cap, path length.
- Rhythm: chart density, note windows, parry window.
- Economy: start gold, kill gold, wave bonus, tower costs, sell value.

Gaps to fill for variety (ideas): fast runners that skip towers, a shielded creep that only notes break, swarms that favour splash, a creep that disables Restore for a bar, a boss that changes the path.

## After M6b (2026-10-25, Jared)

- The first draft pool (D-0034) plays but feels samey: plain stat bumps and small rule tweaks. Jared wants picks that reach "even into the spectrum of the bizarre". Parked until the power progression review; the draft system and its hooks stay, the pool gets replaced.
- Candidates for the bizarre end, to discuss: snipes ricochet off walls; a tower that fires only on Perfects but at x10; swarms count as one creep for splash; the Conductor walks (goal moves one tile a wave); a parry that freezes time for a beat; towers that trade range for a second note ring; a Shade of your own that hides a tower from Jammers; gold that decays unless spent; a wave played backwards (creeps spawn at the goal, walk to the start, you defend the start).

## Jared's notes on the progression review (2026-10-26, discussion only, condensed)

- **Way more towers.** Unlock them WC3-style (a requirement gates each) or outright. Wanted: poison / damage over time, land mine, cannon (have), single target (have), frost, light, void, lightning.
- **Global upgrades instead of per-tower tiers.** Like the WC3 workshop: gold buys armour/damage for a whole tower type. Per-tower bumps fight the random-note play (you hope the upgraded tower gets the note). Keep the "build more or upgrade more" decision, just not on one tower. Need not be boring: an upgrade could turn poison towers into poison-splash towers.
- **Talents are per run**: one point per level from level 5, a tree the size of WoW Midnight with the flavour of PoE 2 (where you start decides what you get). Areas: more notes / music, towers, economy (more gold, more bosses, more elites), walls, parries. Capstones for unique towers or abilities. Not a get-stronger-the-longer-you-play meta.
- **Draft needs the most work.** Rarity (grey, green, blue, purple, orange) **and** category (enemy altering, economy, abilities, stats such as luck / crit / damage, special). Megabonk-style specials: killing an enemy spawns a ghost that haunts another; Joe's-dagger items; walls slow; walls have thorns. The grey examples in the review are too boring; Encore is broken strong; Breathing room unnoticeable.
- **Stat ideas**: luck (card rarity), crit, crit damage, damage, enemy speed (bosses/elites separately if needed), enemy attack frequency.
- **Talent and pick ideas**: parries hit 4 extra targets; parries add notes to a sequence; hit notes echo damage; notes appear more often; notes do effects; Perfect talents; wall talents; parry talents; rhythm talents; tower-or-economy lean.
- **New mechanic: counter-attack.** Every parry leads to a counter press on the next beat (same visual, maybe a yellow ring) that lands on the enemy.
- **Tower combinations.** Combine 5 towers into one stronger tower for gold; the 4 leftovers become crumbling walls that break at the next build phase (so the wall cap holds). Poker-TD style hands for unique towers.
- Not sold on the review's bizarre list, and blanking too. Still reading the doc.
- **Draft composition (comment on 3.4):** no guaranteed slots. Each card is a roll for rarity and a roll for category; cards (and talents) shift those weights ("X cards show more often", luck raises rarity).
