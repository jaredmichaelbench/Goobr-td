# Goobr TD: Demo 0

Greybox build of the game, made in milestones. The plan is in `../docs/prototypes/demo-0-plan.md`.

Engine: **Godot 4.5** (standard build, GDScript). No plugins or assets are needed, because all audio is generated in code.

Open the project, press Play (▶ top right, or Cmd+B on Mac). A menu lets you pick a milestone: **1** = M1 beat test, **2** = M2 maze, **3** = M3 the maze plays the song, **4** = M4 suppress and Restore, **5** = M5 first boss. **Esc** returns to the menu.

**Real music for testing:** drop WAVs into `game/audio/` (kept out of git). In M3, M4 or M5, **]** and **[** switch songs, and the game plays through all of them as a playlist. Tempo comes from `game/audio/songs.cfg` (the SynthWave pack is all 130 BPM). See `game/audio/README.md`.

## M5: first boss (v6)

The question: does the boss feel like learning a souls boss, not reading a chart?

Everything from M4, plus:

- **Wave 5 is the boss**, with a small escort pack at the start and another 10 seconds later. Press **O** to summon it any time instead. It walks your maze slowly (0.4 tiles a second) with a big health bar over the board and a thin yellow **posture** bar under it. Towers, parries and Restore salvos all damage it.
- **No chart notes during the boss.** The fight is Space. Your towers keep firing on their own.
- Its attacks are the event. It throws **bolts down your path at the Conductor** (the goal, marked with a ring) in short strings of four. The tell is the boss swelling for a beat, a low tone, then the bolt leaving the boss and flying along your maze. Bolts launch on the beat and land on the 8th-note grid. Same read as an elite's pulse: watch the projectile land, press Space.
- Far away, bolts take up to 3 seconds to arrive and strings are half-time. In the middle third they're on the beat. In the last third, or once it reaches the Conductor, they come on 8th notes with half a second of warning. A long maze buys you time to read it.
- **Space parries** a bolt as it reaches the Conductor. Perfect or Good deflects it back for damage and posture (Perfect counts double). Four Perfect parries in a row break posture.
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

## M4: suppress and Restore (v8)

The question: does silence create tension, and does restoring feel great?

Everything from M3, plus:

- **Elites** are big, dark red, 4x health, a bit slower. One from wave 3, two from wave 5, three from wave 7, spread through the wave. Missing a note never locks anything. Two kinds, one rule: **a projectile leaves the elite, you watch it land, Space as it arrives.** The parry window is a touch wider than a note's.
- **Jammer** (sword). When it has a tower within reach it stops walking, raises its sword, and throws a **pulse** at the nearest tower. Watch the tower: a red ring closes on it over the bar, four pips above it fill one per beat (tick, tick, tick, low tone), the pulse crawls in. Parry it and the attacked tower fires back (three times its damage, double on a Perfect). Miss it and that tower locks for 5 seconds.
- **Archer** (bow), from wave 4. Once it is within 10 tiles of the Conductor it shoots an **arrow** down your path that lands on the next downbeat, then again every 6 bars. Watch the Conductor: the same closing ring and pips. Parry it and the Conductor deflects it back into the Archer. Miss it and it breaks one of the Conductor's **3 shields** (the diamonds under the goal, refilled every wave); with no shields left it costs 1 health. Creeps walking in always cost health; shields don't help there. Miss the parry and that one tower (two from wave 6) locks for 5 seconds. The same elite throws again after 8 bars.
- Locked towers go dark with a red cross, stop firing, stop answering notes, and their instrument drops out. A locked tower can't be locked again.
- **F = Restore, any time.** It lands on the next 8th note so the sound sits on the music. A refresh ripple sweeps the board from the goal outward, and every locked tower relights as it passes with an **Overcharge salvo** (2.5x damage, splash). The melody joins for 2 bars. Relit towers get a **shield for 2 bars** (pale ring): they can't be locked, and any pulse in the air is knocked out of it.
- **3 Restore charges**, one back per wave cleared (cap 3). Locks also wear off on their own after 5 seconds.
- The HUD counts pulses, parries, locks, Restores, and locks that wore off.

### What to report back

- Is the pulse readable now that the Jammer stands still to throw? Did you ever get locked without seeing it coming?
- Do Jammer and Archer feel like two different problems to maze for? Do the shields make the Archer fair?
- Is one elite per wave at wave 3 the right start, and does a 5 s single-tower lock feel like a bruise rather than a wipe?
- Does Space feel like one clear job (defence), separate from Q/E (offence)?
- Did you reroute or rebuild to keep elites away from towers, now that a pulse means a parry?
- Are 3 charges and +1 per wave about right?

## M3: the maze plays the song (v9)

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
- **The music bed is bass and rhythm only** now: a soft kick, a sub pulse on every beat, and a low pulse layer. Nothing melodic, so when the real track ducks on a miss what's left is plain, not bad. **Intensity**: every 4 landed notes or parries in a row opens the mix one step (the track and the pulse layer get louder); any miss closes one. The HUD shows streak and intensity.
- Build phase: the "Press N" line shows gold left unspent when you can afford a tower.
- **Wave clear**: when the last creep dies, pending notes vanish, the melody drops, a sting lands on the next beat and the groove fades out. The build phase is quiet.
- Balance: 100 starting gold, 1g per kill, 12 + 3 x wave on a clear, creeps get 30% tougher each wave.

### What to report back

- Do the rings on single towers read clearly, and do you still know a note is coming without the timeline?
- Does a snipe or a wave feel like a payoff, and does the miss feel fair (just a lost bonus)?
- Do the notes pull your eyes to the maze rather than to the top of the screen?
- Did tower choice (heavy, splash, slow) and when to upgrade feel like TD decisions? Did the build phase feel worth stopping for?
- Does the bed sit under the real tracks now, and can you hear the mix open up on a streak?

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
