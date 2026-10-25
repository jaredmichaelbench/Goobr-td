# Path ahead after the M5 third pass (proposal, 2026-10-25)

Where we are: M3-M5 play as one loop and Jared calls it genuinely fun. The rhythm rework (D-0022 to D-0024) settled the big question: this is a TD, rhythm amplifies it, Q/E are offence, Space is defence, F is recovery.

## Step 1: M5 polish pass (one build, one playtest)

Small, agreed items only. Nothing structural.

1. **Elite telegraph lives on the tower.** No circle on the elite. The elite raises a sword (a small blade mark over it, turning red on the last beat). The targeted tower gets the emphasis: a red ring that closes over the bar with four beat pips lighting up, the projectile crawling in, the tell tone on beat 4. Parry window unchanged. If parries are still at 0% after this, we widen the elite window (Good 90 → 120 ms) before anything else.
2. **Boss bolts faster from afar.** Bolt speed 6 → 10 tiles/s, flight capped at 3 s. Strings still half-time when far. Less dead waiting, same read.
3. **Wave-to-build transition.** On the last kill: open notes are cancelled, a "wave clear" sting lands on the next beat, the melody drops out and the groove fades to idle over a bar. Build phase stays quiet. (The alternative, groove running through build, is in the backlog if this feels like a hard stop.)

Then M5 is done. Verdict and numbers go in `prototypes/M5-results.md`.

## Step 2: M6 = Demo 0, in three playable slices

M6 is the plan's wrap-up (10 waves, draft, boss at wave 10, win/lose) plus the TD depth Jared wants. Three slices so each gets a playtest:

- **M6a: TD depth.** A third tower (slow: short range, slows creeps, its note is a freeze). One upgrade tier per tower (right-click menu: +damage / +range, costs gold). Economy pass (T-019): starting gold, kill gold, wave bonus, sell value, so tower choice and upgrade timing are real decisions by wave 5.
- **M6b: the run.** 10 waves, pick-1-of-3 draft between waves (tower mods, a Restore charge, gold, a wave modifier), boss at wave 10 (second string set, faster tempo), win and lose screens with the run's stats. This is the seed of the rogue-lite path: drafts are where talents live later.
- **M6c: UI layer.** Real buttons (Godot Control nodes): B build menu, draft cards, upgrade menu, pause. Replaces the hand-drawn text HUD. Clickable, as Jared asked in M3.

After M6 we have Demo 0: a 10-minute run to show people. Then the big-rocks list (rogue-lite paths, talents, more tower types, theme, music) gets its own plan.

## Recommendation

Do step 1 now (it's a day), then M6a. M6a before M6b because the draft needs things worth drafting (upgrades, a third tower) or the cards are empty.
