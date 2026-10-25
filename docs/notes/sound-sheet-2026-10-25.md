# Sound sheet (2026-10-25)

Every sound the game plays today, when it fires, what it is, why it was made that way, and what I'd replace it with. Listen to each one in `game/audio/sfx-preview/` on your Mac (copied there, not in git) or in the shared folder `sounds/`. To try your own: export a WAV from GarageBand and drop it in `game/audio/sfx/` with the file name in the first column. The game uses it instead of the synth voice the next time the test starts. No code change needed, nothing to commit (that folder stays out of git).

## Why the current set feels weak (my own read)

All eleven voices are stacks of sine waves with a fast fade. That makes them clean and in key, but a satisfying hit in a rhythm game has three parts and mine have one:

1. **A transient**: a click or burst of noise in the first 5 to 10 ms. That is what the ear hears as "contact". Mine only have it on the Perfect parry and Restore.
2. **A body**: a pitched tone with some harmonics or a filter sweep, 50 to 150 ms. Mine are all body.
3. **A tail** that sits in the mix: a short reverb or a sub note that hands back to the bed. Mine stop dead.

Also, "in E" only works when the song is in E. The synth bed is in E, but the VOiD1 tracks are whatever key they are in (SynthBomb at 130 BPM is probably not E). A pitched feedback sound in the wrong key clashes with a real track, which is likely part of "weak music". Two ways out: mostly unpitched sounds (clicks, snaps, noise sweeps, sub thumps) with pitch only on the Perfect, or a `key = ` line per song in `songs.cfg` and voices tuned per song. I recommend the first: it works with any track and is what most rhythm games do (the hit sound in Guitar Hero or Beat Saber is a transient, the music is the reward).

## The table

Volume is in dB relative to the song. "Trigger" is the game event; "Why" is the design intent, not a claim the sound achieves it yet.

| File name | Trigger | What it is now | Why that pitch or type | Recommendation |
|---|---|---|---|---|
| `note-perfect.wav` | Q or E landed inside 35 ms | Bright pluck, E4 (329.6 Hz), 280 ms, -3 dB | High and bright so it stands above the bed; E so it sits in the synth bed's key | The most important sound. Wants a sharp transient (a snare-like snap or a short white-noise burst) with a bright pitched ping behind it. Think a laser or a glass tap, not a note. Under 250 ms. Louder than Good so a crit is heard, not read. |
| `note-good.wav` | Q or E landed inside 90 ms | Lower pluck, E3 (164.8 Hz), 280 ms, -6 dB | An octave down from Perfect so the two read as the same sound, better and worse | Same transient family as Perfect, duller and shorter. If Perfect is a snap, Good is a soft tap. A player should want the Perfect sound. |
| `note-miss.wav` | Q or E pressed late, or ring expired | Dry tick, 330 Hz, 80 ms, -4 dB | Unpitched-ish and dry so a miss feels small (a miss costs only the bonus) | Fine in role; could be a muted thunk or a short noise "pff". Should never be a musical note; a wrong note in the song is exactly what you don't want. |
| `wave-clear.wav` | Last creep dies; lands on the next beat | Bright pluck, E5 (659.3 Hz), 280 ms, -2 dB | A sting one octave up from Perfect; the only sound allowed to be melodic | Could be a real short riser or a two-note tag (up a fifth). This one can be in a key because the track fades right after. GarageBand synth presets with an arpeggio work here. |
| `parry.wav` | Space inside 110 ms as a pulse, arrow or bolt lands (Good) | Filtered bass stab, E2 (82.4 Hz), 300 ms, -1 dB | Low and fat so defence sounds different from offence (notes are high, parries are low) | A metallic "clang" transient plus the bass stab underneath. Sword-on-shield energy, electronic. The low body should be a sub thump, not a note. |
| `parry-perfect.wav` | Same, inside 35 ms | Stab E3 (164.8 Hz) with a 2200 Hz click on top, 0 dB | An octave up and a click so a Perfect parry is heard as a clean hit | Brighter clang, longer ring (300 to 400 ms), maybe a tiny pitched "shing" tail. Souls-style parry sounds are a good reference. |
| `restore.wav` | F pressed; lands on the next 8th | Stab E2 with click, 300 ms, +2 dB | The "big button": the loudest player sound, bass so it feels like power coming back | Wants a riser or a reverse-cymbal swell into a hit, 400 to 600 ms, since Restore has a ripple that sweeps the board. A whoosh then a thump. |
| `tower-locked.wav` | A pulse or boss bolt lands unparried and locks a tower | Detuned thud, 55 Hz dropping, 350 ms, -2 dB | Low and sour so a lock feels like damage, not like a musical event | Right idea. Could add a short "power down" pitch drop or a static burst. Must read as bad. |
| `tell.wav` | One beat before a pulse, arrow or bolt lands (the last pip) | Stab E1 (41.2 Hz), 300 ms, -6 dB | The deepest note so it cuts under the music as a warning without being loud | This is a timing cue, so it must be sharp. A low tom or a muted sub kick with a clear attack. Not a note. |
| `beat-tick.wav` | Each beat pip while a projectile is in the air (beats 1 to 3 of the bar) | Tick, 660 Hz, 80 ms, -14 dB | Quiet metronome so you can count the bar without it being music | A soft rim click or hi-hat tick. Keep it quiet; it is a count-in. |
| `posture-break.wav` | Fourth Perfect parry in a row breaks the boss's posture | Stab E1 with click, 300 ms, +4 dB | The deepest, loudest hit: the biggest event in the game | Wants an impact: a boom with a long sub tail and a bright crack on top, 600 ms or more. Think trailer hit. Crescendo (the music slamming in) starts at the same moment, so it can be short if the mix does the work. |

Bed loops for reference (also in the preview folder, 2 s at 120 BPM): `bed-kick-loop`, `bed-sub-loop` (E1 pulse on each beat), `bed-pulse-loop` (E2 8th notes). These only play on "synth stems"; the VOiD1 tracks replace them. `old-chime` is the bell everything used before D-0029.

## GarageBand export settings

- One sound per file, mono or stereo, 44.1 kHz, 16 bit, WAV (Share > Export Song to Disk > WAVE, uncompressed). Trim the silence at the start: the game plays the file on the event and any lead-in silence becomes lag.
- Hits under 300 ms, Restore and posture break up to 600 ms.
- Peak around -6 dB. The game adds the per-sound dB offsets in the table on top; if a file is too loud or quiet, tell me the name and I move the offset.
- File names exactly as the first column, in `game/audio/sfx/`.

## Where to get sounds instead

- GarageBand's own synth presets with the attack shortened and a noise or "click" layer (two tracks mixed) will get most of the table.
- Free packs with clean electronic hits: Kenney (CC0, "Interface Sounds", "Impact Sounds"), freesound.org (filter by CC0), Sonniss GDC bundles (free, royalty-free). All fine to commit, unlike the VOiD1 music.
- VOiD1's own SFX packs would match the music pack's character if they have one.
