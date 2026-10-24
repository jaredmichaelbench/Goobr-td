# Goobr TD: Demo 0

Greybox build of the game, made in milestones. The plan is in `../docs/prototypes/demo-0-plan.md`.

Engine: **Godot 4.5** (standard build, GDScript). No plugins or assets are needed, because all audio is generated in code.

Open the project, press Play (▶ top right, or Cmd+B on Mac). A menu lets you pick a milestone: **1** = M1 beat test, **2** = M2 maze. **Esc** returns to the menu.

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

### Test tools (playtesting only)

- **F1** speed 1x / 2x / 4x / 8x
- **F2** auto-send the next wave 2 seconds after one ends
- **F3** +100 gold
- **F4** skip ahead a wave of difficulty
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
