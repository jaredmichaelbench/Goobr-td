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

## Readability pass (D-0045, 2026-10-26 evening)

After Jared's first look, two outside reviews and his recording, the seven-item pass shipped with no rule change: slim top bar with icons and an always-on beat bar (playhead, judgment word, "ms early/late", streak); one number per target; a wave-clear card; command card with pictures (rendered from the models by `tests/t_icons.gd`), key badges, costs and shortfalls; creep pictures in the wave preview; a pause screen with the keys and run stats; a step strip in the tower panel; the talent tree as area lines with point gates and shared nodes drawn once; calmer ground, brick walls, mossy rocks, a spawn gate, rank bands and a fork pennant on towers. Calibration is fixed at 46 ms (Jared's M1 measurement) with no setting.

Checks: `tests/t_ui.gd` (HUD states as screenshots), `tests/t_title.gd`, and the 3D bot quick run, all without script errors. The counter logic was read through and is unchanged; Jared's 0 of 11 in the recording should be re-checked with calibration back.

Left for the backlog: a three-model upgrade line per tower, controller and key remapping, colour-blind palettes, text scaling, respec, beat-reactive grass, coin pop animations, a custom app icon. Tooltips in the talent tree can still cover a neighbour (Godot places them at the mouse).

## Round 2 (D-0046, 2026-10-26 night)

Bundles 1 to 3 from Jared's second playtest shipped. Notes now come as a short call once per four bars with rests between, and nailing a whole call fires a finisher. A parried elite staggers into a short sequence of its own. The counter-attack is in the base game, and the talent tree no longer pauses. The bottom panel now has round Talents, Restore and Start wave buttons with an XP bar under them, a level-up chime and flash, and coloured tooltips with totals. The beat bar, the step strip and the L timeline are gone.

While writing the tooltips, several talent and card stats turned out to be dead: they were shown but never read by the rules. These were Perfect damage, kill gold, global damage, crossfire bonus, note window and counter window. All six are now wired in. The Light tower's rung text now says what it actually boosts.

Balance bot (`tests/t_bal1.gd`, plays the 20-wave run in real time; hit rate and parry rate given):

| Bot | Result | Run time | Notes |
|---|---|---|---|
| Old rules, 0.6 / 0.65 | lost at wave 20 | 9:01 | waves 15 to 25 s |
| New rules, 0.6 / 0.65 | lost at wave 15 | 10:12 | wave 4 cost 10 health |
| New rules, 0.85 / 0.85 | won, 18 of 20 health | 16:51 | waves 26 to 107 s |

Boss health is based on the old creep curve times 1.0 + 0.06 per wave. The new creep health is about 1.7 times higher by wave 5, and putting the boss multiplier on top of it walled the bot at the first boss. Late waves still offer many notes (65 on wave 19, down from 102). The bot's late hit rate is low because calls overlap with staggers. Jared's playtest decides the next tuning step. No Mac or Windows builds were made (Jared, 22:59Z).
