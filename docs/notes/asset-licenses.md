# Asset licenses

One entry per pack we bring in. Keep the license file next to the asset in the repo when we commit it.

## Free SynthWave Music Pack (VOiD1 Gaming, itch.io)

_License read 2026-10-25 from the PDF Jared bought the pack with (dated 14 March 2021, www.void1gaming.com). Summary, not legal advice._

- Non-exclusive, non-transferable license to use the tracks in personal and commercial projects, including games you sell. Applies to the free and paid assets alike.
- You can modify, adapt and make derivative works (a game counts as a derivative work).
- No attribution required, though credit is appreciated and they'd like to hear about the use.
- Forbidden: reselling or redistributing the source files (WAV, MP3, etc.) or lightly modified versions; shipping anything that lets an end user extract or export the tracks; sublicensing. One license per user.
- For us: fine to use in Demo 0 and a shipped game. **Don't commit the WAVs to the public GitHub repo**, since that is redistribution of source files. Keep them local or in a private asset store, and ship them only inside builds.

Tracks on hand: "9. Space Invaders.wav".

## HALFTONE Sound Effects Pack LITE (VOiD1 Gaming, itch.io)

_License read 2026-10-25 from the PDF Jared sent with the pack (dated 28 June 2020). Same text as the music pack. Summary, not legal advice._

- Same terms: use, modify and ship in personal and commercial games; no attribution required, credit appreciated, they'd like to hear about the use.
- Forbidden: redistributing the source WAVs or lightly modified versions; an app that lets the end user export the asset. One license per user.
- For us: the pack and our trimmed, normalised copies in `game/audio/sfx/halftone/` stay **out of git** (`game/audio/*` is ignored). Copy the folder to the Windows PC by hand, like the music. The community SFX-pack feature (backlog) must never export our shipped pack; it only reads what the player drops in.

Files on hand: 201 WAVs (Gameplay: win, loose, movement, impact, collectibles, bullets and powerups, blips, noise, ambient; UI: buttons, clicks, exit and cancel, transitions). Mapping in `notes/sound-sheet-2026-10-25.md`.

## KayKit Medieval Hexagon Pack, Skeletons and Adventurers (Kay Lousberg)

_Licence read 2026-10-26 from the LICENSE.txt in each pack's GitHub repo (github.com/KayKit-Game-Assets). CC0 1.0._

- Public domain: use, modify, ship, redistribute, commercial or not; credit appreciated (www.kaylousberg.com), not required.
- For us: committed to git in `game/assets/kaykit/` (D-0044) with the licence files beside them. Only the models the game uses are kept.

## Lilita One font (Juan Montoreano)

- SIL Open Font License 1.1 (`game/assets/fonts/license.txt`). Free to bundle and ship; the font itself can't be sold alone. Committed to git.
