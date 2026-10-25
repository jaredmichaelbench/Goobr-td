# Test songs (not in git)

Drop WAV files in this folder to play them in M3 and M4. The WAVs stay out of the repo (see `.gitignore`), because the packs we buy don't allow redistributing the source files (`docs/notes/asset-licenses.md`). Only this README and `songs.cfg` are committed.

## Your own sound effects

Drop WAVs in `sfx/` named after `docs/notes/sound-sheet-2026-10-25.md` (`note-perfect.wav`, `parry.wav`, ...) and the game plays them instead of the built-in synth voices. A song can have its own pack: a folder under `sfx/` named in `songs.cfg` under `[sfx]`; the game looks in the pack, then `sfx/`, then the synth, one sound at a time. `sfx-preview/` holds a render of the built-in voices to listen to. Both folders stay out of git. The default pack is `sfx/halftone/` (VOiD1's HALFTONE LITE, licensed like the music: never commit it; copy the folder to the PC by hand).

## Switching songs

1. Open M3 or M4 from the menu.
2. Press **]** for the next song or **[** for the previous one. The test restarts with the new song, and a line at the bottom left says which song is playing, with its BPM. Song 1 is always "synth stems" (no WAV).
3. The choice is remembered between runs, including across M3 and M4.
4. **Playlist:** once a song is playing, the game moves on to the next file when it ends, through all of them, non-stop. Songs at the same BPM hand over live with the beat carrying straight on; a song at a different BPM, or going back to synth stems, restarts the test.

The song sits in the groove slot: a bit quieter between waves and while towers are locked, full while your towers are fighting. The Q/E tower sounds and the melody still come from the synth and play over it.

## Tempo

The game needs each song's BPM or the notes drift off the music. It looks, in order, at:

1. `songs.cfg` in this folder: `default = 130` covers every file, and a line like `"9. Space Invaders.wav" = 124` overrides one.
2. A number at the start of the filename, if it looks like a tempo (60-220). Track numbers like `9.` are ignored.
3. 120 if nothing else says.

The game loops each song at its last whole bar so the beat stays locked across the loop.
