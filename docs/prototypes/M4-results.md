# M4 results: suppress and Restore

_Question (P-03): does silence create tension, and does restoring on the beat feel great?_

## First pass (2026-10-25, D-0016)

Built on top of M3 v4. Elites pulse on downbeats and suppress nearby towers; F Restores on the downbeat with an Overcharge salvo, late off-beat. 3 charges, +1 per wave.

Headless runs with a small test maze near the spawn:
- Bot that Restores on the beat: 5 Restores over 5 waves, all on beat, no suppression wore off, no leaks.
- Bot that Restores off-beat: Restores land one bar late, no salvo; more suppression wears off on its own.
- No Restores: suppression wears off after 10 s each time; the maze still holds early waves because towers out of the elite's reach keep firing.

Waiting on Jared's playtest.

## First pass playtest and second pass (2026-10-25)

Jared: "much harder now but want to test it more." F-keys didn't work on the Mac (moved to letters, D-0018). Downbeat Restores always landed on Q notes and felt predictable; he wanted locks to be reactive (a miss near enemies locks towers) and Restore on the beat but available more often, player's choice, never off-beat. Built as v2 (D-0017): locks only on missed notes while an elite is armed, Restore on any beat, off-beat presses do nothing.

## Second pass playtest, feedback collected (2026-10-25, not yet acted on)

- Restore and charges aren't working for Jared. Having to hit F on a beat while Q notes also sit on the beat is hard ("which is good") but charges + on-beat + wasted presses don't go together. He wants Restore usable any time, independent of the music, with a refreshing screen-wide effect that implies a full map restore, towers also recovering over time, and the sound effect aligned to the beat for satisfaction.
- Workflow: collect all feedback from a stage before changing anything, agree first, and push back where a feature may have been meant differently than it played (now rule 6 in `docs/INDEX.md`).
