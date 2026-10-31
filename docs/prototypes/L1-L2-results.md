# L1 and L2 results

_2026-10-31 · T-026, T-027 · plan: `level-template-plan.md`_

## L1: Demo 1 fixes

- **Melee parry timing.** Every elite throw now winds up for exactly one bar and lands on beat 1, like arrows. Before, from wave 11, half the throws took a bar and a half, so the parry ring closed somewhere the music didn't say.
- **Level-up chime.** During a wave the XP bar fills silently. The chime, the talent-button shake and the LEVEL line wait until the wave is cleared, and the wave-clear card says "LEVEL n, x talent points to spend (Tab)".

## L2: Performance pass

Test: `game/tests/t_stress.gd`. It fills the board with 80 towers of every type at max rank, poison everywhere, then sends wave 19 at 10x or 30x in one go. Run it with:

```
godot --headless --path game -s tests/t_stress.gd -- 10 20        # game logic only
godot --headless --path game -s tests/t_stress.gd -- 10 20 view 80 # whole 3D scene
```

Numbers from the cloud machine (one slow CPU core, no GPU, so they show the CPU side only):

| Case | Before | After |
|---|---|---|
| Game logic, 10x wave 19 | spikes of 160 to 400 ms, and freezes, when notes were handed out | avg 1.4 ms, worst about 30 ms (about 400 creeps) |
| Whole scene, 10x wave 19 | avg 214 ms, one 25 s freeze | avg 17 ms, p95 29 ms |
| Whole scene, 30x wave 19 | not finishable | avg 18 ms, p95 30 ms |

What was slow, and the fix:

1. **Handing out notes** asked every tower how many creeps it covers, and each of those questions rebuilt the tower's stats, scanning every other tower for Light boosts. Tower stats are now cached until something changes them (a build, sell, upgrade, talent or card), and on a crowded board coverage is read from a density grid instead of counting creeps one by one.
2. **Tower targeting** scanned every creep for every tower on every beat. On a crowded board creeps are sorted into grid buckets once per beat and towers only look at nearby buckets. Small boards keep the old code.
3. **Creep animation** (the 3D models) was the biggest drawing cost, and dying creeps kept animating for 1.6 s each. Up to 32 creeps and corpses animate every frame as before; past that they take turns, each one catching up on the time it missed. A normal wave looks the same; a 10x swarm animates a little choppier.

Not checked here: GPU cost. If Jared still sees lag late in a run on the Mac, the next suspects are shadows and the number of separate meshes per creep.
