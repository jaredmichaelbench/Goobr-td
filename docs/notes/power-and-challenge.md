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
