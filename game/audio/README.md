# Test songs (not in git)

Drop WAV files in this folder to play them in M3 and M4. They stay out of the repo (see `.gitignore`), because the packs we buy don't allow redistributing the source files (`docs/notes/asset-licenses.md`).

- Start the filename with the song's BPM, for example `130 Space Invaders.wav`. Without a number the game assumes 120 BPM, and the notes will drift off the music.
- The game loops the song at the last whole bar, so the beat stays locked across the loop.
- In M3 or M4, press **[** and **]** to switch songs (0 = synth stems only). Switching restarts the test. The choice is remembered.
- Tower stems (Q, E, melody) still come from the synth and play over the song. The song takes the groove slot: it drops down between waves and while towers are locked.
