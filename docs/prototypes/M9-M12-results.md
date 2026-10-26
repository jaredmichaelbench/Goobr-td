# M9 to M12 results: Demo 1, the 3D build (2026-10-26)

Built in one pass under Jared's go ("do it all if you can, take liberties if necessary as long as it doesnt alter the core loop"). Decision: D-0044. One results file for the four milestones, because they shipped together. Screenshots: shared folder `screens/demo1/`. Builds: shared folder `demo1/`.

## What shipped

- **M9, the split.** `RunSim` runs the M7 rules unchanged and draws nothing. `View3D` draws the board in 3D from the sim's fields every frame (65-degree perspective camera, D-0043). `Indicators` draws health bars, note badges, lock marks, the parry ring, the counter flash and boss text above their owners. Clicks are a camera ray to the ground. Models: KayKit Medieval Hexagon, Skeletons and Adventurers (CC0), animated (walk, cast, hit, death).
- **M10, HUD and menus.** The WC3-layout HUD (`hud_rts.gd`) with one Theme (`ui_theme.gd`) and the Lilita One font, B-then-letter build keys, tooltips. The title screen over a 3D scene, How to play, Settings (volumes, full screen, synth note sounds, key hints, calibration), Credits. The old milestone menu is behind D. Clutter off: a note avoids a tower next to one already holding a ring. Copy run log on the end screen.
- **M11, sound.** Synth note voices (Perfect, Good, Miss) made in code, on by default. Music and SFX buses with their own volumes. Title music. A fresh install starts on the first real song instead of the synth stems.
- **M12, package.** `game/export_presets.cfg`: Mac universal zip (ad-hoc signed), Windows x86_64, Linux. The Linux build was run here: it finds the 11 songs, the HALFTONE pack and `songs.cfg`, and the run loads. The Mac and Windows builds are not tested on real machines yet.

## Checks

- The 3D bot (`tests/t_shot3d.gd`, quick run) played to wave 7 with no script errors (its note hit rate is low only because the cloud renderer is slow).
- The title bot (`tests/t_title.gd`) opened every panel.

## Not done, and why

- The six M2 to M7 scripts are not collapsed into one (backlog, D-0044): no play change, and a risk of rule drift.
- No balance change: that waits for Jared's playtest on the 3D build (D-0042).
- No private itch.io page: Jared publishes that himself when he wants friends to have it.
- Jared's own GarageBand note sounds: the sound sheet's file names (D-0031) still take them whenever they exist.
- Kenney and Quaternius packs couldn't be downloaded from the cloud machine; KayKit came from GitHub.
- Renaming the project to "Goobr TD" gives it a fresh user folder: calibrate once from Settings.

## For Jared's playtest

1. Mac: unzip "Goobr TD - Mac.zip", right-click the app, Open, then Open again (it isn't notarised). Or `git pull` and press Play in Godot.
2. Calibrate from Settings, then play the 20-wave run.
3. Notes as usual, plus: can you read the board at this camera; do the note badges, parry ring and lock marks read; do the towers tell apart; does the HUD feel like Legion TD; the new note sounds.
