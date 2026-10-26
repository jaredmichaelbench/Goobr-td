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

## Playtest round 1 (2026-10-26)

Jared's notes: `../notes/m7-playtest-2026-10-26.md` (13 points). Fixed the same night without discussion (bugs): pause let enemies keep moving (the M3 process loop ran the sim while paused, since M3; now held); HUD buttons kept keyboard focus so Space re-pressed Pause (focus off on every button); the build row spilled off narrower windows (smaller buttons, clamped to the window, in key order); the tower panel, draft and end boxes are solid so text under them no longer shows through; help lines hide under the panel. The fork: clicks work in a bot at 1280x720 and at 1250x688 (xvfb); added U / I as keyboard forks and a message on every silent failure path, and asked Jared how he reached the fork. Design points 4 to 13 go to discussion first (rule 6).

## Round 2 build (2026-10-26, D-0040)

All seven agreed points built the same night: eight drafts (bosses plus waves 3, 8, 13, 18) and a 92-card pool with bigger stat cards; escorts trickle through boss fights and later bosses summon on every third break; rolled Crescendo charts and a two-beat elite stagger with two notes; the counter on the off-beat with half posture on bosses and a burst on creeps; rung pips, fork colours, crit and poison reads, +40% rungs; the ranked and gated tree (40 nodes, 68 points of depth, shared nodes between neighbours).

Bots: tree logic (ranks cap at 3, gates at 4/8/12, shared node counts for both areas, counter-attack 5 points from Rhythm or Defence, random spending reaches all 68 points); draft odds unchanged with 92 cards; counter bot 6 parries, 6 counters on the off-beat; M6c HUD regression unchanged. Full runs at 1x, wall-less perfect bot: quick run won at 20/20 in 3:58 (four drafts, level 13); 20-wave run won at 20/20 in 9:13 with 60 towers, Cannon rung 4 Pierce, level 20, 18 talent points, seven drafts (Slack bowstrings, Shrapnel, Ghost bounty, Mud season, Double time, Light boots, Heavy boots). Easier than round 1 (which won at 18/20): the +40% rungs and bigger cards; balance held for Jared's call (D-0040 point 7).

## Playtest round 2 fixes (2026-10-26, late)

Jared's second session: won at 8/20 in 15:09; notes 54%, parries 67%, counters 45%. Notes in `docs/notes/m7-playtest-2-2026-10-26.md`. Fixed before discussion (bugs and UI only, rule 6):

- The status column still spilled onto the board: it was the M3 to M6 stack of long stat lines. `M7Run.status_lines()` now builds its own eleven short lines, and `m2_maze.gd` measures every HUD line and wraps it at the board's left edge (`_fit`), so no scene can spill again.
- Card history: a "Picks (n): ..." line in the column lists every pick in order.
- Fork buttons: a greyed fork says why on the button ("(gold 50/90)" or "(not now)"). The round 2 screenshot showed both grey with Sell bright; gold under the fork's cost is the only path that does that.
- Bottom bar: build buttons no longer grow with their text (clip), locked ones are greyed without the word "locked" (the tip under the bar carries the condition), the Tree button is back on screen.

Checked with the xvfb screenshot bot (column, panel with the fork at 50 gold, tree, end screen) and the headless bots (t_hud, t_pause, t_counter clean, scenes compile). Design points wait on the round 2 discussion doc.
