# UI and UX rethink: eyeline, not corners (2026-10-31, T-034)

Claude Doc for Jared's markup: https://claude.ai/artifact/8qVtAzW4GrfeVnj6S9xwEV (the doc is the live copy). Nothing builds until Jared agrees.

Idea: the game is played like a fight, so what you act on in under a second lives at the camp or the cursor (WeakAuras-style); corners hold between-fight information. The WC3/Legion TD model stays only for between-night screens.

1. Today: gold, health, shields, restores top left; boss bar, PARRY words, streak top centre; build buttons bottom right; Next push and tower info bottom left/middle. Eyes in a fight are on the camp (right side).
2. Principles: two places to look (camp, cursor); a number shows only when it changes a decision; feedback lands where it happened; warnings come to you (pulse at the camp plus sound); corners for between fights, dimmed in a push; keys first, no menu click mid-fight.
3. Sketch: camp readout (health, shields, restore pips, PARRY words, damage pulse), cursor tag while building ("Cannon 27 · you 109", red if short), posture bar on the boss, PERFECT on the tower, corners faded, slim key strip instead of the bottom panel.
4. Building: keys 1-7 as now plus cursor tag; Shift-click chain building; X to sell (refund at the cursor); U on hover to upgrade a type; F restore with pips at the camp; Alt shows details.
5. Slice A first (cursor tag, feedback at the camp/tower, camp readout, corners and bottom bar fade in a push), playtest, then X sell, Shift chain, Alt details, gold pops at kills, boss bar on the boss. Between-night screens and art out of scope.

## Decided and built: slice A with Jared's notes (2026-11-01, D-0062)

Jared's notes: "Build is just B, and you have a mouse scroll for the towers while in build mode, pressing B again closes the build mode. We can also keep 1-7" (Esc having cost him a tower's gold was the pain); cursor tag "all that information next to the cursor, not in the top"; Shift-click chain "sure"; tower on a wall "agreed"; sell "the refund to animate like a sell in any other game would"; upgrade "hover just like sell, pop up menu shows both on hover".

Built on branch claude/project-thread-ifc428 (D-0062): B toggles build mode, wheel cycles unlocked towers, 1-7 pick; a click builds one and exits, Shift-click keeps going; right click and Esc only close build mode. Cursor tag with price and gold (red when short, wall credit shown). Hover a tower: popup with X sell (+refund) and U / I upgrade or fork; selling pops a spinning coin and "+N". Judgments over the tower that fired or over the camp; camp readout (health with damage pulse, shields, restore pips); top bar and bottom panel dim to half in a push. Still to come: Alt details, gold pops at kills, boss bar on the boss, the slim key strip.
