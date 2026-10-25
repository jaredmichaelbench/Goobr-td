# M3 results: the maze plays the song

## First pass (2026-10-24): too busy

Accents fired whenever 2+ towers would hit the same creep on the same note. With hats on every 8th note, that was constant.

Jared's feedback:
- "The rhythm is too much for the player. Hi-hats on 8th notes, it's like they're playing the drums."
- Wants it to feel like an Expedition 33 boss fight: breaks, then moments where you need to lock in, and those moments are telegraphed.
- Put the telegraph on the **tower**: a highlight circle slowly receding, press the note on collapse.
- Show the **key above each tower**.
- Kick / bass / hats are a useful way to think about it, but they'll be invisible to the player in the end.
- The music should make a pattern without giving it away on the nose like DDR. Reference: the Cogwork Dancers fight in Silksong, where the music plays into the fight.

## Second pass (2026-10-24): call and response

Changed (D-0013):
- Towers still auto-fire on their patterns. The player no longer plays along with them.
- The song runs in 4-bar phrases: two bars of groove (nothing to press), a **call** bar where a chime plays a short rhythm, and an **answer** bar where that rhythm comes back on your towers.
- Each answer note is a ring that recedes onto a specific tower over two beats. Press the key shown above that tower as it lands. Perfect = crit.
- Each rhythm is held for two phrases, then changes, so it can be learned.
- Towers whose target is covered by the most other towers are picked first, and crossfire multiplies the bonus, so the maze still matters.
- Every tower shows its key above it.

Headless test: about one cue every 5 seconds during waves, none between waves.

Waiting on Jared's playtest.

## Second pass playtest (2026-10-25)

Not landing yet: hard to parse, not telegraphed, too few attempts per wave, and early waves don't train. Jared wants to drop hats to 1-2 rhythms and suggested a scrolling timeline. Root cause: cues are enemy-driven, so they can't be known in advance. Options and recommendation in `docs/notes/rhythm-model-options.md`.

## Third pass: song chart and timeline (2026-10-25, D-0014)

Changed:
- The song's chart decides the notes. They scroll along a timeline under the board (Q lane, E lane) and are known 2 bars ahead.
- Two rhythms only: Q tower (on the beat) and E tower (off-beat). Hats are background groove. Build keys are 1 wall, 2 Q tower, 3 E tower.
- A ring closes on every tower of the next note's key two beats out: bright if that tower has a target, faint if not.
- A hit fires a Resonance from every engaged tower of that key. No engaged tower = wasted note.
- The chart ramps every two waves: one Q per bar, then extra Qs, then E notes, then a mix.
- Waves are longer: 14 + 3 per wave creeps.

Headless test (dense test maze, so waves end fast): waves 1-2 had 6-8 notes, wave 3 had 14. All scenes load and the 8x speed tool still works.

Waiting on Jared's playtest.

## Third pass playtest and fourth pass (2026-10-25)

Jared's notes on v3: put the timeline at the top as a faint overlay (and he's unsure about having one at all, since eyes go there); balance is off (he reached wave 6 on starter gold); the flat map with unlimited walls feels broken, so try WC3/StarCraft-style blocked terrain; rings on towers out of range are still too loud; hits need to feel exciting, and you can't tell when you fail.

Changed in v4:
- Timeline moved to a faint overlay across the top of the board. F6 toggles it.
- Rock map with two ridges and gaps, plus a 20-wall cap (D-0015).
- Balance: start 100g (was 150), 1g per kill (was 2), creep HP 24 growing 30% per wave (was 18, 20%). Bot runs: starter towers only fall at wave 4; all-in towers with no walls and no notes fall at wave 9.
- Out-of-range towers get a soft glow instead of a ring.
- Hit feedback: chime (higher on Perfect), damage numbers per target (yellow "!" for crits), damage total in the banner, and a flash on the timeline line. Misses (note passes while towers had targets) play a low tone, flash red, and show "miss" over those towers. They're counted in the HUD.

Waiting on Jared's playtest.
