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
