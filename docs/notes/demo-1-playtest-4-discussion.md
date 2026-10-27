# Demo 1 playtest 4: discussion

_Claude Doc: https://claude.ai/artifact/Hi85fsLfsFhDZaoLYvhRmZ (proposed, waiting on Jared)._

Your notes from the 12:37 run (won at 13 of 20 health, notes 77%), with what the code says and what I recommend. The log is in `docs/notes/demo-1-playtest-4-2026-10-27.md`. Nothing has been built yet.

## 1. Melee parry timing: confirmed bug

You read it right. From wave 11, half of the elite throws wind up for a bar and a half (6 beats) instead of one bar. The four dots still count one per beat, so they fill on beat 4 and the ball lands two beats later. Arrows always take exactly one bar, which is why pressing on the 4th dot works for them. The late landing also falls on beat 3, where the Kick Snare notes now sit.

**Recommend:** every throw lands on beat 1, one bar after it starts, so it matches arrows: press on the 4th dot. Late-wave variety should come from new enemy types (section 6), not from a hidden timing change.

## 2. Level-up chime and flash

Today they fire the moment XP crosses a level, in the middle of the wave.

**Recommend:** hold them until the wave is cleared. The chime and the shake then play on the wave-clear card, and the card gets a line such as "Level 14, 2 talent points to spend (Tab)". The XP bar still fills during the wave, silently.

## 3. Too easy, and the first boss

Your run: the first boss died halfway through its first Crescendo. Gold +248% and XP +234% from talents snowballed the run. My bot says the same thing: a good bot now wins at full health.

**Recommend, tuned with the bot:**
- **Bosses:** about 2.5x health at the wave 5 boss and about 2x on later bosses. The target is that it takes two or three staggers, not one.
- **Creeps:** health grows faster from wave 6 on (about 1.20 a wave instead of 1.17). Creeps move about 10% faster from wave 8 and 20% faster from wave 15.
- **Gold and XP talents:** cap them. Each rank gives less than the one before, and gold and XP bonuses together stop around +100%. Bundle 4 redoes these properly. This is just a cap so the next tests are not broken.
- **The bot's target:** a good bot finishes at about 8 to 14 of 20 health, and a sloppy bot loses around wave 12 to 15.

## 4. Lag after wave 15 (and 30x for endless)

I agree this is a blocker for a rhythm game: a late frame is a missed note. I have not measured it yet. From the code, the likely causes are:
- **Poison:** it ticks on every beat on every creep, and each tick may spawn a floating number.
- **Creeps:** each creep is its own 3D model.
- **Targeting:** every tower scans every creep each step.
- **Light:** every shot works out its Light boost by scanning every building on the board.

**Recommend a performance pass as its own milestone:**
1. **Stress test:** build a scene with 10x and 30x your wave 19 (hundreds of creeps, about 300 towers, poison everywhere). Measure frame time here and on your Mac.
2. **Fix what it shows.** Likely fixes:
   - merge poison numbers into one per creep;
   - draw creeps with one batched mesh per kind;
   - make towers look up nearby creeps from a grid instead of scanning all of them;
   - move the rules off the drawing frame, so a slow frame never moves the beat.
3. **Bar:** solid 60 fps at 10x on your Mac. 30x is the stretch goal. If plain GDScript can't reach it, the hot loops can move to compiled code later. That is a bigger step, and I'd only take it with numbers in hand.

## 5. The clump, and a Conductor in the middle

You're right that the best play today is one Light-buffed clump with the maze wrapped around it, so most of the map goes unused. Classic TDs solve this with geography, not prices. A centre keep with enemies from every side does it naturally: you have to fortify all around, and there is no single best line.

**Recommend:**
- **Centre map:** add a second map choice for the 20-wave run, "Centre keep". The Conductor sits in the middle and spawns come from all four sides, taking turns, then together in late waves. You choose the map on the title screen and A/B test it against today's map. If it plays better, it becomes the default (and it suits 1v1v1v1).
- **Light:** a much bigger radius (about a quarter of the board), and Light buffs stop stacking. Today they add up: a tower inside three Lights gets three boosts, which is what makes the clump so strong. With one boost per tower, the best play is to spread Lights over the quadrants.
- **Escalating cost per type:** hold until after the centre map test. It works (each Cannon costs +10% more), but it reads as a tax. The map plus Light changes may be enough.

## 6. More enemy types

Agreed: "lots of attack and enemy variation" from your earlier notes. These are ideas to pick from, each one a different question for your maze:
- **Sprinter:** fast, low health; punishes short mazes.
- **Splitter:** splits into three on death.
- **Medic:** heals creeps around it; focus it first.
- **Shieldbearer:** blocks shots from the front only, so corners matter.
- **Sapper:** stops at a wall and breaks it after a few bars unless killed.
- **Swarm boss escort:** many tiny creeps that make splash towers shine.

**Recommend:** pick 3 for the next build. I'd take Sprinter, Medic and Sapper, since each one asks something new of your maze.

## 7. Counters 0 of 42

The counter-attack is a second Space within about 150 ms of a landed parry (a quick tap-tap). Zero of 42 suggests it's either too tight or not clear on screen.

**Question:** were you trying to counter? If not, I'd make the counter window longer (about 250 ms) and show a clear "TAP" flash on the tower.

## Proposed order

1. **Now (small):** the parry fix (1), the level-up timing (2) and the balance pass (3), tuned with the bot.
2. **Next:** the performance pass (4), with a stress test first. I'd do it before more content, because endless mode depends on it.
3. **Then:** the centre keep map and the Light change (5), plus three new enemies (6).
4. **Bundle 4:** cards, talents and XP, still waiting on your sketches.

Say "go" for step 1 and I'll build it, and tell me your enemy picks and counter answer when you can.
