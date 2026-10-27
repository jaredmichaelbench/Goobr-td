# Demo 1 playtest 3 (round 2 build), 2026-10-27

Jared, 01:43Z, after `git pull` of 2e60684 (round 2, D-0046). Verbatim:

> Seems like we let you pick a locked card, the cards need the same treatment as talents, they are just placeholders it seems we went with the first set of generated ideas, we need to decide on card amount per rarity when we think about the average multiplayer game or endless run. From there we will work backwards to create valuable cards that arent overpowered but are exciting and written well.
>
> Talents sort of need the same treatment but for EXP and how often you get them, how long will a multiplayer run be for talents to be impactful, but also how many you can unlock during an endless run and what the exp scaling looks like (e.g., is level 100 equivelant to the exp from levels 1-77? etc.)
>
> Im noticing phrases or crescendos, im not sure the term during normal waves that are like 6 notes on each beat, much faster than I would have wanted. especially this early (level 7) notes should always be Kick Snare Kick Snare Kick Snare rhythm, the 8th notes (fast ones) etc should be saved for something special like a talent that adds a quick note at the end of a phrase or something. I also feel like something is messed up here too because they are so close together you almost feel like your spamming and Im sure we have some spam prevention in the code to ensure usres arent just mashing buttons, and its not clear if its working or im just missing when the come this fast. The last thing ill say is this really makes it hard for the notes to land with the song, we still need to go back to the SFX drawing board, but sticking with that simple kickdrum rhythm/cadence ensures the notes always play on the beat even in slower parts of songs, the fast ones dont always fit.
>
> General question after playing some more, are the rapid 6 note phrases intended or a bug?
>
> The new UI stuff is a big improvement.

## What the code says (Claude, 2026-10-27)

- **Fast 6-note runs.** These are partly intended and partly an accident of stacking.
  - A call that is already on the towers is followed straight away by an elite's stagger (4 notes, one per beat). Nothing forces a rest between the two, so it plays as one long run of about 6 notes.
  - Pulse (talent), Double time and Virtuoso (cards) put their extra notes on 8th-note off-beats (`_with_extra`).
  - From wave 11, call shapes include 8th notes (`CALLS` bands 3 and 4). Stagger bands 3 and 4 do too.
- **Spam prevention.** There is none. A press with no note only shows "No note". A press before the window shows "Too early" and leaves the note open, so mashing early costs nothing (`m3_song.gd` `_play`).
- **Locked card.** This is the conditional card (`CardPool.LOCK_CHANCE` 0.35 for blue and up): you take it now, and it pays out if you meet a condition next wave. The card does not explain this. It goes into the card review.
