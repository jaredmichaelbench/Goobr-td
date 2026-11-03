# B1 + B2 results: the five-night campaign and its enemies

_2026-11-03 · T-040 · D-0067 (built together at Jared's ask) · plan: `five-night-demo-plan.md` (T-039)_

## What was built

**B1, campaign shell and progression**

- **Five nights in a row.** The title screen's first button is now **Play: the five nights**. Each night is its own level file (`game/levels/night_life.cfg`, `night_2.cfg` to `night_5.cfg`). The scene reloads between nights.
- **What carries over:** health (20 for the whole run, D-0056), level and XP, talents and unspent points, and cards. Towers, walls, gold and tower upgrades stay behind at the old camp.
- **Results screen in the campaign:** **Next night** (N) if you held, **Retry night** (R), and **New run**. Retry puts you back at the start of that night with what you had then. After Night 5 the screen reads "THE FIVE NIGHTS ARE DONE" and there's no card.
- **Test a night 1-5** (title screen, under the menu). Starts at any night with the talent points and level you'd have by then, nothing spent. The start panel has a **Spend talents** button, so the tree can be tried before Start.
- **Start panel:** shows "NIGHT N OF 5", what's new tonight, and what you carried in (health, level, talents, cards, points).
- **Towers renamed:** Arrow (the old Cannon, snipes) and Cannon (the old Splash, area), per D-0059.
- **The locked talent tree (D-0057 to D-0059):** 22 nodes laid out like Jared's builder, Towers left and Rhythm right, Perfect Solo in the middle. Every node costs 1 point. The points come on the morning: 1 after Night 1, then 3 after Nights 2, 3 and 4, so 10 in a run. Hovering a node says what it does and why it's closed. Data in `game/scripts/night_tree.gd`, which can be edited without code.
- **No in-night unlocks.** Lightning, Poison and Light come only from the tree. Counter Attack is off until you take it, and it is the tree's first node.
- **Upgrades: a fork, then a mastery** (option A). Pick a fork on a tower type (U or I) for 2x the tower's price, then its mastery for 4x. The old flat damage rungs are gone. The masteries are drafts for Jared to review:

| Tower | Fork 1 then mastery | Fork 2 then mastery |
|---|---|---|
| Arrow | Pierce, then Skewer (shots go through a line) | Siege, then Breach (+25% damage taken for 2 s) |
| Cannon | Quake, then Aftershock (a second wave a beat later) | Ember, then Wildfire (fire spreads down the path) |
| Frost | Deep freeze, then Shatter (a frozen kill freezes neighbours) | Brittle, then Cold snap (slowed counts as frozen) |
| Poison | Poison-splash, then Plague (stacks to 3) | Virulent, then Necrosis (ticks harder each beat) |
| Lightning | Fork, then Storm (no damage lost per jump) | Static, then Overcharge (every 4th strike stuns) |
| Light | Beacon, then Lantern (+15% attack speed in the light) | Flare, then Daybreak (cracked Hushes take +25%) |

- **New cards (D-0059):** 16 in the pool, in Rare, Epic and Legendary (about 65 / 28 / 7%, luck nudges up, at most one Legendary a run). There are no flat stat cards and no rerolls. F beat is designed but not in the pool yet. You get one pick after each of Nights 1 to 4. Data in `game/scripts/night_cards.gd`.

**B2, enemies**

- **Renamed (D-0061):** Bonehead, Legger, Knucklebones, Big Lad, Hush, Spanner, Pot-shot, Crossing Guard, The Night Manager. Level files take either the new or the old names.
- **Notes go for the boss, then an elite,** while one is on the board; otherwise the creep nearest the camp. This closes the "lone boss walking" watch item.
- **Six new enemies.** They use the existing skeletons with their own size and tint until the B4 look pass.

| Enemy | First night | What it does | Answer |
|---|---|---|---|
| Door-to-Door | 2 | Carries a door: hits from ahead do 20% | Towers beside and behind the path |
| Busker | 3 | Its drum speeds up creeps within 3 tiles | Kill it first |
| Last Orders | 3 | Rings a bell (four-beat ring, BELL on the ground) | Parry it, or the next bar's notes go quiet |
| Digger | 4 | Stops at a wall and tunnels through it in 4 bars (DIG count on the ground) | Kill it before the wall goes |
| Moths | 4 | Fly over the maze straight at the fire; every third one costs 1 health | Area towers near the camp |
| Undertaker | 4 | Digs a grave (GRAVE ring) | Parry it, or three Boneheads rise from it two bars later |

- **The Foreman** (Night 3 finale): a field boss whose drum speeds up everything near it.
- **The Landlord** (Night 5): walks in at the top of Flanger Party with 2.5x a boss's health. He Stomps with a two-bar wind-up: if the stomp lands, nearby towers lock and his two nearest walls break. He Volleys the camp with 4, 6, then 8 bolts as the song goes on. He calls a Last Orders as the overtime starts. **He holds at a quarter of his health until the last section** (see below), so the overtime song on Psychedelia Flashback is where he falls.
- **Test arena:** during a night, **J** (or Shift+J to go back) picks any enemy or boss, and **K** drops it at the mine. Moths come as a flight of 8.
- **Night 5 overtime:** Psychedelia Flashback plays straight after Flanger Party on the same clock, 132 bars in all.

## Nights (drafts; all five are tuned together in B5)

| Night | Song | Bars | Start gold | New | Boss |
|---|---|---|---|---|---|
| 1 | Night Life | 96 | 150 | (frozen, D-0055; specials swapped for Big Lads) | The Night Manager |
| 2 | Romance on Neon | 72 | 175 | E notes, Door-to-Door | none, a heavy last push |
| 3 | Laser Party | 64 | 200 | Busker, Last Orders | The Foreman |
| 4 | 80s, Disco, Life | 80 | 225 | Digger, Moths, Undertaker | The Night Manager |
| 5 | Flanger Party, then Psychedelia Flashback | 80 + 52 | 250 | everything | The Landlord |

## Bot runs (`game/tests/t_campaign.gd`)

The bot plays every night at 1x, carries state over the same way the game does, spends talents up the Towers side, and takes the first card it's offered.

| Bot | Result |
|---|---|
| 85% notes and parries, no health loss (checks that the mechanics work) | All five nights held. Health, level, talents and cards carried over every time. Points arrived 1, 3, 3, 3. Door blocks, bells, graves and both new bosses were all seen. |
| Night 5 from the night picker (10 points, no health loss) | Before the floor, the Landlord died at bar 40, half way through Flanger Party. With the floor he held at 25% from bar 73 to 80, then fell in the overtime at bar 94 of 132. No card after Night 5. |
| 90% notes and parries, real health, Nights 1 to 5 | **Held all five nights** on 7/20 health at the end. Health after each night was 14, 9, 9, 7, 7. It reached level 20 and took 10 talents (up the Towers side), with four cards. |
| 80% notes and parries, real health, Night 1 then 2 | Held Night 1 on 10/20 health, then fell in Night 2's finale (that finale cost 10). |

`game/tests/t_b1b2_shots.gd` takes screenshots of the start panel, the tree, the arena enemies, the Foreman, the morning, the card and the results (won and lost). The menus, slice A and title tests still pass.

## Calls made in the build (Jared to check)

- **The Landlord can't fall before the overtime.** The enemy doc says he fights through every section, and D-0066 makes the overtime his fight. A strong bot killed him half way through Flanger Party, so his health now holds at 25% until the last section starts, and the watchman says so once.
- **The Night 1 specials.** Spanner, Pot-shot, Hush and Crossing Guard were swapped for Big Lads on Night 1, so the specials arrive across the later nights.
- **No rerolls in the campaign.** Each card pick is one hand of three.
- **Points before Start** happen only with the night picker. In a normal run, points are spent on the morning.

## Known gaps (later milestones)

- **Health across five nights is harsh.** 20 health has to last the whole run, and A 90% bot finished on 7/20, and an 80% bot fell on Night 2. This is B5 balance, but expect to use Retry night.
- **Diggers need walls.** The bot builds towers only, so it never saw a dig. Test them by hand with walls (J to Digger, then K).
- **Looks.** The new enemies are tinted skeletons with borrowed icons, and they still need their own props. That is B4, together with the synth note sounds Jared needs before then.
- **No-build zones** replace the reach rule in B3, together with the night maps. Every night uses Night 1's map until then.
- **The 20-wave run and the Demo 0 milestones** are unchanged and still on the title screen.
