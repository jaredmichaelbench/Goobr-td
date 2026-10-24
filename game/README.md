# Goobr TD: Demo 0

Greybox build of the game, made in milestones. The plan is in `../docs/prototypes/demo-0-plan.md`.

Engine: **Godot 4.5** (standard build, GDScript). No plugins or assets are needed, because all audio is generated in code.

## Current milestone: M1, beat and input feel

The question: is rhythm timing tight and consistent on both your Mac and your PC?

### Run it

1. Install Godot 4.5 (standard, not .NET) from godotengine.org on both machines.
2. Open Godot, choose **Import**, and select this folder's `project.godot`.
3. Press **F5** (or the Play button).

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
