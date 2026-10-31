# Demo 1 playtest 2: discussion

Proposed 2026-10-26 by the thread. Jared's raw notes are in `demo-1-playtest-2-2026-10-26.md`. Nothing is built until Jared agrees (rule 6).

## The short version

I agree with nearly all of it. The biggest point is the note spam, and it is tied to "too easy". Every note you land fires a snipe with infinite range. So 100 notes a wave is also 100 free snipes, and that is a big part of why waves melt.

If we phrase the notes into short sequences with rests, two things happen at once. Each note matters more, and your damage comes down. Then we raise enemy health on top of that, and the waves get longer.

I'd build this in three bundles. Bundle 4 waits for your sketches:

1. **Fixes:** clear and small, no design change.
2. **Rhythm and difficulty together:** sequences and rests, tougher and longer waves, a tougher boss.
3. **The bottom panel:** your game-controls layout and a WoW-style XP bar.
4. **After your sketches:** talent tree shape, tower unlocks in the tree, the card review and card look.

## Bundle 1: fixes (just say go)

| # | What you saw | What I'd do |
|---|---|---|
| 1 | Talents pause the music | The talent tree stops pausing the game, WC3 style. The music and the run keep going while it's open, and P still pauses. Pausing the game has to stop the music, because the beat comes from the song. So this is the only way to keep the music going. Spending between waves stays completely safe. |
| 2 | Tooltips are slow | Tooltips show instantly, right next to the cursor. |
| 3 | Tooltips are a wall of text | Every talent, card and tower gets the same layout. A clear title comes first. A plain explainer follows in white. Values are green, game terms are blue, and the rank line shows totals, like "Rank 1/3: +8% now, next rank +8% (16% total)". The game terms are words like snipe, parry, stagger and crossfire. |
| 4 | "Crossfire" means nothing | Crossfire is a bonus on note snipes. A snipe deals more for each *other* tower whose range also covers the target. Resonance raises that bonus by 20% per tower. I'd rename it to something self-explaining, like "Focus fire: note snipes deal +20% for each other tower covering the target", or cut it in the tree rework. |
| 5 | Light tower +40% to what? | It boosts the damage of towers inside its light. Its own damage is zero by design. The text will say so, and the upgrade line will say "towers in its light deal +40%". |
| 6 | Q and E on the same tower | This is a bug. The check only avoided towers whose ring was already open, and missed rings still coming up. The fix: never put a note on a tower that has a ring coming, open, or just finished. Notes keep infinite range, as you said. |
| 7 | Beat bar and step boxes | Both go, and the L timeline goes too. The rings above the towers carry the timing on their own, and bundle 2 makes them easy to read. |
| 8 | Poison locked with no explanation | Interim fix until the tree rework: a locked card says exactly what unlocks it, with progress, like "Build 3 Frost (2/3)". Today it only says "locked". The real fix is in bundle 4. |
| 9 | Talent points pile up | On a level-up: a chime, a "Talent point!" flash, and one shake of the Talents button. After that the button glows softly until the point is spent. A constant shake gets tuned out or turns annoying; one shake per level plus a glow is the usual answer. |

## Bundle 2: rhythm and difficulty (this one needs your yes)

### Notes as sequences, not a stream

Today every bar asks for three or four notes, all wave long, from wave 11 on. Wave 19 offered 102 notes. That's the spam you felt.

My proposal:
- **Phrases of four bars.** One bar is the call, a short sequence of notes. The other three bars rest. Towers fire, elites wind up, and parries live in the rests. At 150 BPM that's a sequence about every 6 seconds.
- **The tempo stays the same all run.** What grows is the shape of the sequence:
  - Waves 1-5: Q then E. Two notes.
  - Waves 6-10: three notes, like Q E Q or Q Q E.
  - Waves 11-15: four notes, with one off the beat (on an "and").
  - Waves 16-20: four or five notes in an unexpected order, mixed hands and one syncopation. You read it rather than react.
- **Nailing the whole sequence pays out.** Landing every note in a sequence fires a finisher: one extra snipe, a "PHRASE" flash and a sound. That's the "nail it" moment.
- **Elites bring the boss feeling, in short.** Parry an elite's throw and it staggers. A short four-note stagger sequence plays, like a mini Crescendo. It happens a few times a wave, not every bar.

That takes wave 19 from about 100 notes to about 25 to 35. Each one counts and lines up with the music.

### Tougher, longer waves

The run took 9 minutes, about 27 seconds a wave including breaks. You lost 5 health, all on waves 18 and 19.

Targets I'd tune to with the bot:
- **Run length:** about 18 to 20 minutes.
- **Wave length:** early waves last about 40 seconds of fighting, late waves about 60.
- **Creeps:** about 50% more creeps per wave, spaced wider so waves last longer. Health goes up about 1.6 times at wave 1, rising to about 2.2 times by wave 20, because power stacks up through the run.
- **Bosses:** about 2.5 times the health. A Crescendo can't kill a boss on its own, so the boss takes two or three staggers.
- **Losing health:** at a 50% note rate you start losing health around wave 10 to 12.

Fewer notes already cuts your damage a lot, so I'd tune the health numbers after the sequences are in, not before.

### One more thing from your end screen

Counters were 0 of 0. The counter-attack, which you liked, is locked behind a card or talent, and you didn't take either. **I'd make it part of the base game again.** It fits the "parry, then hit back" feel. With the rests from the sequences, there's room for it again.

## Bundle 3: the bottom panel (agree, and I'd build it from your description)

- **Right:** the build card. Only the wall, the towers and Upgrade, with the B-then-letter keys.
- **Middle:** game controls as round buttons with hotkeys and instant tooltips. Talents on the left, Restore pulse in the middle, Start wave on the right. Under them sits a WoW-style XP bar: segmented bubbles, a percent, and "Level 7".
- **Left:** next wave and song, as now. The selected tower's info goes in the space above the round buttons when a tower is selected.

If you'd rather sketch this one too, say so; otherwise I'll build it as described and you can mark it up.

## Bundle 4: after your sketches

- **Talent tree shape and linking.** I'll wait for your drawing.
- **Tower unlocks in the Towers tree.** I agree. This replaces today's unlock rules (3 Frost for Poison, 10 Perfects for Lightning, a Shade kill for Light) and the catch-all capstone.
- **Cards: more often, a new lens, better look.**
  - Today there are 8 drafts a run: after each boss, plus waves 3, 8, 13 and 18.
  - I'd go to about 12: every other wave, plus each boss.
  - The lens I'd use: a good card changes a decision you make (where to build, what to aim for, when to parry). If a card only adds a percent, it should be grey filler at best.
  - I'll wait for your card sketch for the look and information, then do the full card review against it.

## What I need from you

- Go on bundle 1?
- Bundle 2: sequences every four bars, the finisher, elite mini-staggers, the health targets, and the counter back in the base game. Yes, or change any of it?
- Bundle 3: build from your description, or wait for a sketch?
