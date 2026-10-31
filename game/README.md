# Goobr TD

The game, built in milestones. Demo 0 (greybox) plan: `../docs/prototypes/demo-0-plan.md`. Demo 1 (the 3D build) plan: `../docs/prototypes/demo-1-plan.md`.

Engine: **Godot 4.5** (standard build, GDScript, no plugins). Models (KayKit, CC0) and the font (Lilita One, OFL) are in `assets/` and in git. Music and the HALFTONE sounds are copied by hand into `audio/` (never in git); without them the game uses its synth stems and synth sounds.

Press Play (Cmd+B on Mac). The **title screen** offers Night 1 (the song level), the 20-wave run, the 10-wave quick run, How to play, Settings (volumes, full screen, synth note sounds, key hints; timing calibration is fixed for the demo in `scripts/timing.gd`) and Credits. **D** on the title opens the developer menu with the Demo 0 milestones (keys 1 to 9). **Esc** twice leaves a run.

## Night 1: Night Life, the level template (L3, D-0048, D-0050)

- Needs `13. Night Life.wav` in `audio/` (from the shared folder). Without it the level plays on the drum machine.
- The map is shown and nothing can be built yet. **N** or the play button starts the night: two bars of drumsticks (the build phase), then the song from its first bar.
- The level is `levels/night_life.cfg`, plain text: the song, the count-off, the gold, then one line per section (name, push / lull / finale, bars, tier, what comes). The file explains itself. Edit it and press Play again.
- Pushes send exactly what the file says. Lulls send nothing; the music dips and goes muffled, and opens up again on the lull's last bar. The finale here brings a field boss.
- When the song ends and the board is clear: one card, then the results. If enemies are still up, the finale loops until they are gone.
- The watchman's tips show as one line over the board ("WATCHMAN ..."), each once.
- Bot: `godot --headless --path game -s tests/t_level.gd -- 0.7 0.7` plays it and prints each section with the song bar it started on.

## Demo 1: the run in 3D (D-0044)

- The board under a fixed 65-degree camera: medieval towers, walls and a keep, skeleton creeps that walk, cast and die, the Conductor (a mage) at the keep. Note badges (Q orange, E purple) float above their tower; the ring closes on the beat.
- HUD in the Warcraft 3 layout: resources top left, stats top right, the bar strip under the top bar, wave preview bottom left, tower panel bottom middle, command card bottom right. Build with a button, a number key, or **B** then a letter (**W** wall, **C** Cannon, **S** Splash, **F** Frost, **V** Poison, **L** Lightning, **G** Light).
- A note avoids a tower right next to one already holding a ring (clutter off, D-0043).
- New note sounds made in code (Settings can switch back to the pack's). The run starts on the first real song in `audio/` and plays on as a playlist; **[ ]** switch.
- The end screen has **Copy run log**: paste it back to us after a run.
- F11 or Alt+Enter: full screen.
- Builds: `export_presets.cfg` has Mac (universal, ad-hoc signed), Windows and Linux. Export from the editor (Project, Export) after installing the 4.5 export templates; builds land in `../export/` (not in git).
- **Readability pass (D-0045):** slim see-through top bar with icons; the beat bar in the middle of it (what each beat asks for, a playhead, the judgment word and "51 ms early" under it, the streak beside it); one number per target over the board; a wave-clear card; command card with pictures, key badges, costs and the shortfall when you can't afford it; the next wave as creep pictures; the tower panel with a step strip (the 8 steps it fires on, the current one outlined); P opens a pause screen with all the keys and the run's numbers; the talent tree draws each area as a line with its point gates and the shared nodes once between two areas. On the board: calmer ground, brick walls, mossy rocks, a red gate and a pulsing ring at the spawn, rank bands at a tower's base (bronze, silver, then the fork's colour) and a taller tower with a pennant from the fork on. Timing calibration is fixed at 46 ms for the demo (`scripts/timing.gd`).
- **Round 2 (D-0046), from Jared's second playtest:** notes come as a short **call** once every four bars, then three bars of rest. The call shows whole on the towers with its order (1, 2, 3...) as soon as its first ring starts. Calls grow from Q then E (waves 1 to 5) to four or five notes out of order (16+), at the same tempo. Land every note of a call and the Conductor fires a **finisher**. A parried elite **staggers** and plays its own short sequence; nail it and the finisher hits that elite. The **counter** (tap Space again right after a parry) is in the base game. Notes never share a tower. Waves have half again as many creeps, spaced wider, with more health; bosses have 2.5 times the health. The talent tree no longer pauses: the run and the music go on, Q, E and Space work, Esc or Tab closes it. Tooltips are instant, with a title, a plain sentence, green values, blue game words (with a glossary line) and rank totals. The bottom panel: build card on the right (wall, towers, Upgrade), round game controls in the middle (Talents Tab, Restore F, Start wave N) with a WoW-style XP bar under them; a level up chimes, shakes the Talents button once and it glows until spent. The beat bar, the step strip and the L timeline are gone. Fixed: five talent and card stats that showed but did nothing (damage %, Perfect damage, note window, gold per kill, crossfire, now called focus fire); the Light tower's upgrades now grow its boost and radius.
- HUD pictures are rendered from the models by `tests/t_icons.gd` into `assets/icons/`; rerun it when `art.gd` changes.
- The rules are the M7 run unchanged (`scripts/run_sim.gd` extends `M7Run`); the picture is `view3d.gd`, `indicators.gd` and `hud_rts.gd`; the art table is `art.gd`.
## M8: the look test (Demo 1, D-0042)

Menu key **9**. Not a game: the 26 by 16 board in 3D at one metre a tile, built from flat-coloured primitives, with the things the look test has to answer on screen at once: three note rings in a row (the clutter case from the round 3 run), a locked tower, the parry ring on the Conductor's keep, the counter flash on a creep, a 3.6-tile range circle, creeps walking the path.

- **1 2 3** camera tilt 60, 65, 70 degrees. **P** perspective or orthographic. **R** rings above the towers (Jared's sketch) or flat on the ground as in Demo 0. **C** the three rings on or off. **Esc** menu.
- **S** swaps the primitives for models when `assets/models/tower.glb`, `creep.glb`, `keep.glb`, `rock.glb`, `wall.glb` exist (see `assets/README.md`; packs stay out of git).
- Take screenshots of the combinations you like and say which. The questions: can you read the grid, a ring on a tower, three rings close together, the locked mark and the boss ring at this height; does the scale (tower against creep against range) feel right; which tilt and projection.

## M7: the progression run (v3)

New in v3 (round 3, after Jared's second 20-wave run, D-0041):

- **One ask per beat.** Throws (Jammer pulses, arrows, boss bolts, stomps) land on **beat 1**. Notes sit on **beats 2 to 4**. A strip over the board shows the bar with the live beat lit: `1 parry  2 Q  3 -  4 E`. Waves 1 to 5 are Q only (beat 3, every other bar); 6 to 10 add E on beat 4; 11 to 15 roll one pattern per wave and late elites may land on beat 3; 16 and up re-roll every phrase and E can sit on the "and". A Crescendo has no throws.
- **The counter is a tap.** Land a parry, then press **Space again within 150 ms**: no ring, no beat to wait for. A Perfect parry makes a Perfect counter. The target flashes "TAP" for the window; a late tap says so.
- **Shades are never immune.** A veiled Shade takes **10%** damage (shown under it). Any landed note cracks every veil a step (20%, 30%, then stripped); a Perfect cracks two. The Light tower cracks a step per downbeat in reach.
- **Early waves bite**: creeps start at 30 HP (was 18) and grow 1.15 a wave (was 1.19), so waves 1 to 3 are about 60% harder and wave 20 a little softer.
- **Boss fights**: the escorts come as three big packs on posture breaks 1, 3 and 5 (a pack comes anyway after 20 s without a break); bosses after wave 10 summon on every second break. Between throws the boss plays a **quiet chart**: one Q a bar on the tower nearest it.
- **Parry at the boss.** The parry ring closes on the boss as it throws; a bolt you miss flies red to the Conductor and lands. Your eyes stay on the boss.
- **Per-wave log** on the end screen: notes, parries and counters hit of offered, and health lost, wave by wave. The same lines print to the Godot console as `WAVE LOG`.
- Grey draft cards no longer carry run-long draft effects (Rabbit's foot +1 luck; Training manual is green; Open hand is blue).

### Round 2 (v2)

New in v2 (round 2, after Jared's first 20-wave run, D-0040):

- **Eight drafts a run**: after every boss and after waves 3, 8, 13, 18. The pool is 92 cards and the stat cards are bigger. Some cards give talent points, rerolls or a fourth and fifth card.
- **Boss fights stay busy**: the escorts trickle in a pack every 8 s while the boss lives. Bosses after wave 10 summon runners on every third posture break.
- **Every stagger is different**: a posture break rolls its Crescendo chart from a set (the pattern is shown on the break). **Elites stagger too**: parry a Jammer, Warden or Archer and it holds for two beats while two notes open on the tower nearest it.
- **The counter lands on the off-beat** (the "and" after the parry), so it never shares a beat with a note. On a boss it builds half posture. On a creep it bursts: everything within two tiles takes half the hit.
- **You can see upgrades**: rung pips under every tower, the fork colours its ring (blue first branch, orange second), crits pop up blue, poisoned creeps are tinted green with their stack count, and the whole type flashes when you upgrade it. Rungs give +40% instead of +25%.
- **The tree is rebuilt** (Tab): five areas, three rows and a capstone. Row 1 nodes take up to three ranks. Row 2 needs 4 points in the area, row 3 needs 8, the capstone 12. The outer row 2 nodes are shared with the neighbour area and count for both, so a Defence start can take Counter-attack and carry on into Rhythm. Each area shows its points.
- One bottom bar, smaller fonts, nothing overlaps; pause holds everything; buttons never steal Space.

### Round 1 (v1)

The question: does a 20-wave run with a build to plan (the tree), a build to react to (the draft) and type-wide upgrades stay interesting from wave 1 to the last boss? Menu **7** is the full run, **8** the 10-wave quick run. Plan: `../docs/prototypes/m7-plan.md`.

- **Six towers, two rows of buttons.** Keys **1** wall, **2** Cannon, **3** Splash, **4** Frost, **5** Poison, **6** Lightning, **7** Light. Poison, Lightning and Light start locked; their buttons show what unlocks them (build 3 Frost; land 10 Perfects; kill a Shade). Poison stacks tick every beat and ignore armour. Lightning arcs from its target to a creep nearby. Light does no damage: towers around it hit harder, its pulse cracks veils near it. Each new tower has its own note (Poison **Spread**, Lightning **Storm**, Light **Chorus**).
- **Upgrades are per type, not per tower.** Click any tower, or press **U** with one selected: the panel shows the type's five-rung ladder and the price (it rises with the rung and with how many of that type you own). At rung 3 you pick a **fork** for that type and keep it (Cannon: Pierce or Siege; Splash: Quake or Ember; Frost: Deep freeze or Brittle; Poison: Poison-splash or Virulent; Lightning: Fork or Static; Light: Beacon or Flare). Sell still refunds 75%.
- **Levels.** Kills give XP (bosses most, swarm least); the bar under the status column fills; every level from 2 gives a talent point.
- **The tree (Tab, pauses).** Five areas side by side: Rhythm, Towers, Economy, Walls, Defence. Take any top-row node; below that a node needs one owned node above it, or a link from another area. **Counter-attack** is three points in from Rhythm, Walls, Towers or Defence. Each area ends in a capstone (Fermata, Arsenal, Bounty, Rampart, Riposte).
- **Counter-attack.** After a parry lands, a yellow ring on the creep you struck on the next beat. **Space** on it returns the damage again and builds posture. Missing it costs nothing. Not during a Volley.
- **The draft** comes after every boss (every other wave in the quick run). Each card rolls a rarity (grey, green, blue, purple, orange) and a category (Stats, Economy, Enemy altering, Tower altering, Abilities, Special, Draft). Blue and above may come locked with a condition for the next wave. Keys **1 to 5** pick; some cards give rerolls or a fifth card. The pool is `scripts/card_pool.gd` and the tree `scripts/talent_tree.gd`: numbers and text, no code.
- **20 waves.** Bosses at 5 and 15 (the first boss, more health later), 10 and 20 (the crowned boss). Creep health grows 22% a wave. After 20 the waves repeat. Wave 1 now has its chart from the first bar.
- **Stats block** on the end screen: crit, crit damage, luck, enemy speed and attack rate, XP and gold gain, plus counters, crits, arcs and poison dealt.

### What to report back

- Tower or rung: when did you choose to upgrade a type instead of building, and did the fork at rung 3 feel like a choice?
- Which towers did you never build? Which notes did you wait for?
- Did an unlock change how you played (did you build Frost to get Poison)?
- First talent point: too early, too late? How many points by wave 20, and did you plan a route or take what was open? Which capstone mattered?
- The counter: a riposte you reach for, or a tax after every parry?
- The four drafts: did each one matter? Any card broken or boring? Did a locked card make you play for it?
- Where did the run drag, and where did it rush? Health and gold at waves 10, 15 and 20.

## M6: the run (v2)

The question: is a 10-wave run with picks and two bosses fun from start to finish, and can you play it with the mouse?

New in v2 (M6c, the clickable layer):

- **The board is wider**: 26 by 16, spawn on the left, goal on the right. Every milestone uses it.
- **Click a tower** to select it (white ring). Its panel opens at the bottom left: name and tier, damage, range, rate, what its note does, **Upgrade** with the price, **Sell** with the refund. Click an empty tile to build what is selected, or to clear the selection. Right click still sells.
- **Bottom bar**: one button per build with its cost (the wall button shows the wall count), **Start wave**, **Restore** with charges, **Pause**. The keys still do everything the buttons do.
- **P pauses.** The music holds, so the beat and every timer holds with it. Nothing but P and Esc works while paused.
- **Draft cards are buttons** (1, 2, 3 still work). Grey, orange and blue as before.
- **Win and lose screens** have Run again, Keep going (after a win; endless as a test) and Menu.
- The line under the bar is a tip for whatever you are doing.

Everything from M5, plus (M6b):

- **Ten hand-written waves.** The "Next wave" line says what is coming. Five creep kinds, each with an answer: **Runner** (yellow, fast, half health, pairs: slow tower, long corridors), **Brute** (big, armour plate: ignores the first 4 damage of every hit, so heavy snipes win), **Swarm** (packs of six small pink ones: splash), **Shade** (dark, in a pale halo: towers can't touch it until a landed Q or E cracks every veil on the board for 3 beats). Runners from wave 2, Swarm 3, Brute 4, Shade 6.
- **Warden** (elite with a shield, from wave 7): a faint blue dome around it. Every hit aimed at a creep under the dome goes to the Warden instead, until its pulse is parried; then the cover is gone for good. Same throw as a Jammer, so the parry read is the same.
- **Bosses at 5 and 10.** The wave's creeps are the escorts, half with the boss and half 10 s later. The wave 10 boss wears a violet crown and plays differently: a **Volley** of three bolts on 8th notes (parry each), and a **Stomp**: a ring grows on the tile under it over a bar with beat pips, towers in its reach glow. Space on the downbeat and those towers fire back; miss and they lock. After two posture breaks it goes double-time.
- **The draft.** After every cleared wave but the last, three cards. **1, 2 or 3** picks one; N waits until you do. Grey cards are small and immediate. Orange cards change a tower or a parry for the rest of the run, once each. Blue cards are **locked picks**: they name a condition for the next wave (6 Perfects, no attack lands, no shield lost); meet it and the card unlocks, fail and it is gone.
- **Win and lose screens** with the run's numbers. R runs again.
- The wave script is `scripts/wave_script.gd`: a list per wave of kind, count and seconds between. Change numbers there, no code.

### What to report back

- Which creep made you change the maze or the towers, and which one you ignored?
- Did the Shade make you want the notes? Did the Warden parry feel worth going for?
- The draft: did a card ever change how you played the next wave? Did a locked pick make you play for it, or was the condition unfair?
- Boss 2: can you read a Stomp from a Volley? Is double-time at two breaks a thrill or a wall?
- Where did health go: creeps leaking, arrows, boss hits? Which wave is too easy or too hard?
- Is 10 waves the right length for one sitting?
- The mouse: did you reach for a key or a button? Is the tower panel enough to decide an upgrade? Anything you wanted to click that did nothing?

## M5: first boss (v6)

The question: does the boss feel like learning a souls boss, not reading a chart?

Everything from M4, plus:

- **Wave 5 is the boss**, with a small escort pack at the start and another 10 seconds later. Press **O** to summon it any time instead. It walks your maze slowly (0.4 tiles a second) with a big health bar over the board and a thin yellow **posture** bar under it. Towers, parries and Restore salvos all damage it.
- **No chart notes during the boss.** The fight is Space. Your towers keep firing on their own.
- Its attacks are the event. It throws **bolts down your path at the Conductor** (the goal, marked with a ring) in short strings of four. The tell is the boss swelling for a beat, a low tone, then the bolt leaving the boss and flying along your maze. Bolts launch on the beat and land on the 8th-note grid. Same read as an elite's pulse: watch the projectile land, press Space.
- Far away, bolts take up to 3 seconds to arrive and strings are half-time. In the middle third they're on the beat. In the last third, or once it reaches the Conductor, they come on 8th notes with half a second of warning. A long maze buys you time to read it.
- **Space parries** a bolt as it reaches the Conductor. One press parries everything landing in that window, a pulse, an arrow and a bolt together. Perfect or Good deflects it back for damage and posture (Perfect counts double). Four Perfect parries in a row break posture.
- A **hit** (no parry, or late) breaks a Conductor shield if one is left, otherwise costs 2 health, and locks the nearest tower to the boss, so Restore applies.
- **Posture break**: the boss staggers for 6 seconds, every tower does +30%, the full mix slams in, and the board glows. A short **note burst** opens too: one note per beat, sweeping across your towers from the farthest from the boss to the nearest, each a free snipe or wave at the boss. That is the only time notes appear in the boss fight.
- Kill it to clear the wave. If it reaches the Conductor it doesn't leak; it stands there and attacks at the fastest tempo.

### What to report back

- Does the fight feel like a duel now that there is no chart to follow during it?
- Can you read the strings from the swell, the tone and the bolt leaving the boss?
- Does the Crescendo sweep read? Is one note per beat right for the first boss?
- Did your maze length change how the fight felt? Did you rebuild for the boss?
- Is a posture break satisfying, and does the note burst feel like a reward rather than a test?
- Too hard or too easy, and where: the parry window, the bolt damage, the boss health?

## M4: suppress and Restore (v9)

The question: does silence create tension, and does restoring feel great?

Everything from M3, plus:

- **Elites** are big, dark red, 4x health, a bit slower. One from wave 3, two from wave 5, three from wave 7, spread through the wave. Missing a note never locks anything. Two kinds, one rule: **a projectile leaves the elite, you watch it land, Space as it arrives.** The parry window is a touch wider than a note's.
- **Jammer** (sword). When it has a tower within reach it stops walking, raises its sword, and throws a **pulse** at the nearest tower. Watch the tower: a red ring closes on it over the bar, four pips above it fill one per beat (tick, tick, tick, low tone), the pulse crawls in. Parry it and the attacked tower fires back (three times its damage, double on a Perfect). Miss it and that tower locks for 5 seconds.
- **Archer** (bow), from wave 4. It shoots from anywhere on the board: an **arrow straight over the maze** that lands on the next downbeat, then again every 4 bars. (The boss's energy ball is the one that follows your path.) Watch the Conductor: the same closing ring and pips. Parry it and the Conductor deflects it back into the Archer. Miss it and it breaks one of the Conductor's **3 shields** (the diamonds under the goal, refilled every wave); with no shields left it costs 1 health. Creeps walking in always cost health; shields don't help there. Miss the parry and that one tower (two from wave 6) locks for 5 seconds. The same elite throws again after 8 bars.
- Locked towers go dark with a red cross, stop firing, stop answering notes, and their instrument drops out. A locked tower can't be locked again.
- **F = Restore, any time.** It lands on the next 8th note so the sound sits on the music. A refresh ripple sweeps the board from the goal outward, and every locked tower relights as it passes with an **Overcharge salvo** (2.5x damage, splash). The melody joins for 2 bars. Relit towers get a **shield for 2 bars** (pale ring): they can't be locked, and any pulse in the air is knocked out of it.
- **3 Restore charges**, one back per wave cleared (cap 3). Locks also wear off on their own after 5 seconds.
- The HUD counts pulses, parries, locks, Restores, and locks that wore off.

### What to report back

- Is the pulse readable now that the Jammer stands still to throw? Did you ever get locked without seeing it coming?
- Do Jammer and Archer feel like two different problems to maze for? Do the shields make the Archer fair? Does the straight arrow read as a different attack from the boss's ball?
- Is one elite per wave at wave 3 the right start, and does a 5 s single-tower lock feel like a bruise rather than a wipe?
- Does Space feel like one clear job (defence), separate from Q/E (offence)?
- Did you reroute or rebuild to keep elites away from towers, now that a pulse means a parry?
- Are 3 charges and +1 per wave about right?

## M3: the maze plays the song (v10)

The question: can you hear your maze, and do you build it so your towers are in the fight when the song calls for them?

- Calibrate in M1 first (press **C** there). M3 uses the same calibration.
- Build keys: **1** wall, **2** heavy tower (sand), **3** splash tower (teal), **4** slow tower (ice blue: taps every beat, slows to half speed). Tower type doesn't decide which notes you get; it is a role, like any TD.
- **U** over a tower upgrades it once for its base cost again: +50% damage, +0.4 range, white chevron. Selling refunds 75% of everything you paid.
- **The map has rock** (brown). Creeps can't walk on it and you can't build on it. **Walls are limited to 20**, so use the terrain.
- **Notes are punctuation now.** A wave has a few notes per phrase, not a stream. Two beats before a note, a coloured ring closes on **one tower** (orange = Q, on the beat; purple = E, off the beat) with the key written on it. The ring stays on that tower until the note is gone, even if its target walks off.
- Press the key as the ring closes and that tower fires across the whole board at the creep closest to the Conductor. A **heavy tower snipes**: 4x its damage, 8x on a Perfect, a bright tracer and a screen punch. A **splash tower lobs a wave**: 2x (4x Perfect) on everything within 2 tiles of the target. A **slow tower freezes**: 2x (4x Perfect) on everything within 2 tiles and holds them for a beat (two on a Perfect). Both do more when other towers also have that creep in range (crossfire). A tower never carries two rings at once.
- **A miss costs only the bonus.** Nothing locks, nothing else happens. If you have no towers, the note is skipped.
- **The timeline is off by default.** Press **L** to show the faint scrolling strip at the top if you want to compare. Play from the rings and the music.
- The chart grows: one note per bar in wave 1, two in wave 2, Q and E mixed from wave 3, four from wave 4.
- **The music bed is bass and rhythm only** now: a soft kick, a sub pulse on every beat, and a low pulse layer. Nothing melodic, so when the real track ducks on a miss what's left is plain, not bad. **Intensity**: every 4 landed notes or parries in a row opens the mix one step (the track and the pulse layer get louder); any miss closes one. The HUD shows streak and intensity, and a small **streak ball** beside the Conductor shields fills a quarter per hit and changes colour per step (grey, white, yellow, orange), swelling on a hit and dipping on a miss.
- **Feedback sounds are replaceable**: drop a WAV in `game/audio/sfx/` named as in `docs/notes/sound-sheet-2026-10-25.md` and it plays instead of the synth voice; a song can name its own pack folder in `songs.cfg`. The defaults: short synth plucks and bass stabs in E instead of bell chimes. Bright pluck = Perfect, lower pluck = Good, dull tick = miss, bass stab = parry (brighter on a Perfect), clicked stab = Restore, thud = a tower locking.
- Build phase: the "Press N" line shows gold left unspent when you can afford a tower.
- **Wave clear**: when the last creep dies, pending notes vanish, the melody drops, a sting lands on the next beat and the groove fades out. The build phase is quiet.
- Balance: 100 starting gold, 1g per kill, 12 + 3 x wave on a clear, creeps get 30% tougher each wave.

### What to report back

- Do the rings on single towers read clearly, and do you still know a note is coming without the timeline?
- Does a snipe or a wave feel like a payoff, and does the miss feel fair (just a lost bonus)?
- Do the notes pull your eyes to the maze rather than to the top of the screen?
- Did tower choice (heavy, splash, slow) and when to upgrade feel like TD decisions? Did the build phase feel worth stopping for?
- Does the bed sit under the real tracks now, and can you hear the mix open up on a streak?
- Do the new hit, miss and parry sounds belong to the music? Is the streak ball visible enough without pulling your eyes?

## M2: the maze

The question: does building a maze while creeps reroute live feel smooth and readable?

### How to play

- **B** toggles build mode (on by default).
- In build mode, pick what to place: **1** wall (4g), **Q** kick tower (slow, heavy), **W** hat tower (fast, light), **E** bass tower (splash). These match the instrument keys from the controls plan.
- **Left click** places, **right click** sells for 75%. Hover shows a green or red preview and the tower's range.
- You can't fully block the path, and you can't build on a creep.
- **N** starts the next wave. You can keep building during a wave, and creeps reroute immediately. The faint line shows the current route.
- 10 waves, then **N** keeps going in endless mode. Leaks cost 1 health out of 20. Kills give 2g, and clearing a wave gives a bonus.
- **Esc twice** returns to the menu.

### Test tools (playtesting only, plain letter keys because the F-keys are media keys on the Mac)

- **I** toggles the **isometric look-test**: the same board drawn as a 2:1 diamond with raised rock and walls. Circles and rings are not rescaled, so they look a little big; it is only to judge whether the maze reads at that angle (`docs/notes/art-direction.md`).
- **T** speed 1x / 2x / 4x / 8x
- **Y** auto-send the next wave 2 seconds after one ends
- **G** +100 gold
- **H** skip ahead a wave of difficulty
- The HUD shows how many creeps the next wave has and their HP.

Towers fire on simple timers for now. M3 puts them on the beat.

### What to report back

- Does rerouting feel instant and readable? Can you always tell where creeps will go?
- Is building fast enough with the keys and clicks? What's annoying?
- Rough difficulty: did you win, and on what wave did it get hard?
- Anything you wanted to do and couldn't.

## M1: beat and input feel

The question: is rhythm timing tight and consistent on both your Mac and your PC?

### Run it

1. Install Godot 4.5 (standard, not .NET) from godotengine.org on both machines.
2. Open Godot, choose **Import**, and select this folder's `project.godot`.
3. Press **Play** (▶ top right; Cmd+B on Mac, F5 on Windows), then **1**.

### What to do

- A kick plays at 120 BPM, louder on beat 1. Tap **Q, W, E, or Space** on the beat.
- Each tap shows **Perfect** (within 35 ms), **Good** (within 90 ms), or **Miss**, plus how early (−) or late (+) you were.
- After about 16 taps, press **C** to auto-calibrate. This sets the offset to your average, so your taps center on 0. The setting is saved.
- **[ ]** nudges calibration by 5 ms. **- / =** changes BPM. **M** mutes the click, so you can test with the visuals only. **R** resets stats.

### What to report back (once per machine)

- Mac or PC, and your speakers or headphones (wired, Bluetooth, or monitor speakers).
- Your calibration value after pressing C.
- The **spread** number after 16 taps, once calibrated. Under about 20 ms means the timing is consistent; much higher means jitter we need to fix.
- Whether Perfect felt fair or stingy, and whether the visuals felt in sync with the sound.
- Try once with Bluetooth headphones if you have them. They add a lot of latency, which is exactly what calibration is for.

### Known limits

- Input is read once per frame, so there's up to about one frame (about 7–16 ms) of input jitter. If the spread is too high, this is the first thing to improve.
- There's only one calibration value for now. A separate visual offset comes later if the visuals feel out of sync.

## Layout

- `scripts/beat_clock.gd`: the audio-clock beat source every rhythm system will use.
- `scripts/m1_beat_test.gd`: the M1 test scene.
- `scripts/maze_grid.gd`: the grid and flow field (pathing).
- `scripts/m2_maze.gd`: the M2 maze scene.
- `scripts/menu.gd`: milestone picker.
- `scripts/timing.gd`: shared Perfect/Good windows and saved calibration.
- `scripts/stem_synth.gd`: generated placeholder music, one loop per instrument.
- `scripts/m3_song.gd`: the M3 scene (builds on M2).
