# M7 results: the progression update

_Question: does a 20-wave run with a build to plan (the tree), a build to react to (the draft) and type-wide upgrades stay interesting from wave 1 to the last boss?_ Plan: `m7-plan.md`. Scope: D-0039.

## Build (2026-10-26, D-0039)

All eight slices in one build on top of M6: type upgrades with a fork at rung 3, six towers with in-run unlocks, XP and levels, the five-area talent tree (Tab), the counter-attack, the rolled draft (44 cards, after every boss), the 20-wave script with the 10-wave quick run, and the stats block. Slice I (Void, Land mine, Flush) not built. Menu keys 7 and 8.

### Headless bots, all at 1x (notes only schedule at 1x)

- **Draft roll, 10,000 cards:** rarity split 48.9% grey, 28.7% green, 14.3% blue, 6.1% purple, 2.1% orange (weights 50/28/14/6/2). Luck 5 lifts orange to 6% and purple to 8.8%. A x3 Special bias lifts Special from 2.9% to 3.8% of rolls (the pool has only five Special cards, so the bias is capped by what exists). 44 cards, every id unique.
- **Tree:** 65 nodes; random spending reaches all 65. Counter-attack costs 3 points from Rhythm, Towers, Walls or Defence, 99 (unreachable in a run) from Economy: an Economy link is a candidate for the next pass. Stats and specs add up (Cannonry gives a Cannon 16.1 damage from 14).
- **Counter on the boss:** 4 parries, 4 counters, 4 counter hits, boss dead in 25 s.
- **Quick run (10 waves), perfect notes and parries, no walls, round-robin builds:** won at 20/20 health, 4:10, 28 towers, Cannon rung 2, level 16 with 15 talents, four drafts (Wide hand, Wanted posters, Chilling crits, Grindstone).
- **Long run (20 waves), same bot, creep health growth 1.22:** lost on wave 20 at 9:34 with 60 towers, Cannon rung 5 Pierce, level 18 with 17 talents; health held at 20 until wave 17, then 16, 9, 6, 0. A run without upgrades lost on wave 19. Growth eased to 1.19; see below.
- **Long run at growth 1.19:** won at 18/20 health, 9:36, 56 towers, Cannon rung 5 Pierce and Splash rung 1, level 19 with 17 talents, 282 of 283 notes, 98 of 100 parries, 10 posture breaks across four bosses; the two health lost on wave 19. Shipped at 1.19.
- **Regressions:** M3, M4, M5 and the M6c HUD bots unchanged.

What the bot does not test: walls, the fork choices other than Pierce, the counter inside a real run (the bot's talent order never reaches it), rerolls, locked cards. Those are Jared's.

### Known rough edges

- Levels come fast (level 12 by wave 10, 18 by wave 20): the tree is 65 nodes, so about a quarter is taken in a run. Fine for the test; Jared wanted more levels and the curve is one number (`XP_GROWTH`).
- The tree panel is a greybox grid of buttons; links are listed in the node's hover text, not drawn.
- Balance is tuned only until the wall-less bot clears 20 waves.

Waiting on Jared's test session (two 20-wave runs, one quick run; report in one pass, see the plan's section "The test session").
