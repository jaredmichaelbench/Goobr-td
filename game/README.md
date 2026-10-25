# Goobr TD: Demo 0

Greybox build of the game, made in milestones. The plan is in `../docs/prototypes/demo-0-plan.md`.

Engine: **Godot 4.5** (standard build, GDScript). No plugins or assets are needed, because all audio is generated in code.

Open the project, press Play (▶ top right, or Cmd+B on Mac). A menu lets you pick a milestone: **1** = M1 beat test, **2** = M2 maze, **3** = M3 the maze plays the song, **4** = M4 suppress and Restore, **5** = M5 first boss. **Esc** returns to the menu.

**Real music for testing:** drop WAVs into `game/audio/` (kept out of git). In M3 or M4, **]** and **[** switch songs, and the game plays through all of them as a playlist. Tempo comes from `game/audio/songs.cfg` (the SynthWave pack is all 130 BPM). See `game/audio/README.md`.

## M5: first boss

The question: does the boss feel like learning a souls boss, not reading a chart?

Everything from M4, plus:

- **Wave 5 is the boss**, alone. Press **O** to summon it any time instead. It walks your maze slowly (0.4 tiles a second) with a big health bar over the board and a thin yellow **posture** bar under it. Towers, notes and Restore salvos all damage it.
- Its attacks are the event. It throws **bolts down your path at the Conductor** (the goal, marked with a ring) in short strings of four. There is no timing UI: the tell is the boss swelling for a beat, a low tone, then the bolt itself flying along your maze. Every bolt arrives on the beat grid.
- Far away, bolts take 4-5 seconds to arrive and strings are half-time. In the middle third they're on the beat. In the last third, or once it reaches the Conductor, they come on 8th notes with half a second of warning. A long maze buys you time to read it.
- **Space parries** a bolt as it reaches the Conductor. Perfect or Good deflects it back for damage and posture (Perfect counts double). Four Perfect parries in a row break posture.
- A **hit** (no parry, or late) costs 2 health and locks the towers near the boss, so Restore applies.
- **Posture break**: the boss staggers for 6 seconds, every tower does +30%, the full mix slams in, and the board glows. Then it carries on.
- Kill it to clear the wave. If it reaches the Conductor it doesn't leak; it stands there and attacks at the fastest tempo.
- Space is the parry key, so one-key mode (K) is Q/E only here.

### What to report back

- Can you read the strings from the tell and the bolt alone, without wanting a timing bar?
- Does the half-time / on-beat / 8th-note tightening feel like the boss closing in, or like three separate fights?
- Did your maze length change how the fight felt? Did you rebuild for the boss?
- Is a posture break satisfying, and is 6 seconds of Crescendo enough to matter?
- Too hard or too easy, and where: the parry window, the bolt damage, the boss health?

## M4: suppress and Restore (v3)

The question: does silence create tension, and does restoring feel great?

Everything from M3, plus:

- From wave 2, every 6th creep is an **elite**: big, dark red, 4x health, a bit slower. While it has towers within reach, its ring pulses and it says "miss = lock".
- **Miss a note while an elite is armed** and it locks every tower in its reach for 10 seconds. Locked towers go dark with a red cross, stop firing, stop answering notes, and their instrument drops out. The groove drops out too. Clean play never gets locked. The same elite can lock again after 2 bars.
- **F = Restore, any time.** No timing, nothing wasted. It lands on the next 8th note (at most 250 ms later; a yellow mark on the timeline shows where), so the sound and the effect sit on the music. A refresh ripple sweeps the board from the goal outward, and every locked tower relights as it passes with an **Overcharge salvo** (2.5x damage, splash). The melody joins for 2 bars.
- **3 Restore charges**, yellow bars under the meters, one back per wave cleared (cap 3). Locks also wear off on their own after 10 seconds (the red bar under the tower drains).
- The HUD counts locks, Restores, and locks that wore off.

### What to report back

- Does the Restore feel like a payoff now? Does the 8th-note delay read as "on the music" or as lag?
- Are 3 charges and +1 per wave about right, or should Restore be a cooldown instead?
- Does the 10 s self-recovery register? Would 6 s be better?
- Are elites readable? Did you reroute or rebuild to keep them away from towers?

## M3: the maze plays the song (v4)

The question: can you hear your maze, and do you build it so your towers are in the fight when the song calls for them?

- Calibrate in M1 first (press **C** there). M3 uses the same calibration.
- Build keys: **1** wall, **2** Q tower (on the beat, heavy), **3** E tower (off-beat, splash). Hats are background groove only.
- **The map has rock** (brown). Creeps can't walk on it and you can't build on it. Two ridges split the board into three fields joined by gaps. **Walls are limited to 20**, so use the terrain.
- During a wave, notes scroll right to left along a faint **timeline across the top of the board** (Q lane on top, E below). Press the key as a note reaches the line. **L** hides the timeline so you can try playing from the rings and music alone.
- Two beats before a note, a ring closes on every tower of that key **that has a target**. Towers with nothing in range only glow softly.
- A hit fires a Resonance from every engaged tower of that key. You get a chime, damage numbers over the targets (yellow with "!" for a Perfect crit), and a flash on the timeline line. A note that passes with towers ready and no press is a **MISS**: low tone, red flash, "miss" over those towers. Pressing with nothing to hit says "Too early" or "No note".
- The chart builds up: one Q per bar in wave 1, more Q in wave 2, E joins at wave 3, both mixed from wave 5. The HUD shows notes, hits, crits, misses and wasted presses per key.
- Balance: 100 starting gold, 1g per kill, creeps get 30% tougher each wave. In bot runs, 4 starter towers alone fall at wave 4, and spending everything on towers with no walls and no notes falls around wave 9. Walls and notes should carry you to 10.
- Missing costs nothing. **K** toggles one-key mode. Speeding up (T) mutes the music and turns notes off.

### What to report back

- Timeline at the top: readable without stealing your eyes? Better with it on or off (L)?
- Do hits feel good now, and can you tell when you miss?
- Does the rock map make mazing more interesting? Is 20 walls too few or too many?
- Difficulty: where did it get hard, and did gold feel tight?

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
