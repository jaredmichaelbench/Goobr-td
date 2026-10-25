# Elite pressure after the rhythm rework (proposal, 2026-10-25; agreed and built the same day, D-0024)

Jared's second-pass feedback (see `prototypes/M5-results.md`): too many elites too soon, the pulse is unreadable, locks last too long, Restore needs immunity, snipes feel great.

Numbers in the build he played: an elite every 6th creep from wave 2 (4 per wave by wave 3), each pulsing every 4 bars, 1 beat of tell, lock 10 s on every tower within 2.2 tiles.

## Proposal (discuss, then build)

1. **Fewer elites, later.** First elite on wave 3, one per wave, +1 every two waves (wave 3: 1, wave 5: 2, wave 7: 3). Same elite pulses at most every 8 bars.
2. **Readable pulse.** Wind-up is a full bar, not a beat: ring swells over 4 beats with a tick on each beat and the tell tone on beat 3, landing on the downbeat. Window stays Good 90 ms. Keep Space on elites so the boss isn't the first time you parry, but it should feel like a free bonus hit until wave 5, see 3.
3. **Lock is a bruise, not a wipe.** Unparried pulse locks only the nearest tower (two from wave 6) for 5 s, not everything in reach. A lock never hits a tower already locked.
4. **Restore immunity.** Towers relit by Restore can't be locked for 2 bars (shield glow). A pulse winding up when Restore lands is cancelled.
5. **Snipe feel.** Heavy note: single-target bolt at 4x (8x Perfect) with a tracer and a screen punch. Splash note: an AoE wave at 2x (4x Perfect) that hits every creep within 2 tiles of the target. Notes already come whether or not anything is in range: the tower is picked by what it can see, else by the creep nearest the Conductor.

Open: Jared's alternative of no elite parries before the boss. Risk: the first Space press would be in the boss fight; and without the pulse the elite is just a tanky creep.

## Boss additions (Jared's wrap-up, same day)

6. **Crescendo burst spreads.** One note per beat, each on a different tower, sweeping from the tower farthest from the boss to the nearest, wrapping if there are more beats than towers. Never two open notes on one tower. Pace unchanged for the first boss; slow it only if it still reads badly.
7. **Bolts leave the boss.** Bug: a bolt's launch time is arrival minus travel, which is often in the past, so it spawns mid-path. Fix: launch on the beat the string is called (boss swells, tone), fly at constant speed, arrival snapped up to the beat grid. Far = a long visible flight.
8. **One parry language: watch the thing land.** The elite's pulse becomes a visible projectile too: it leaves the elite on the downbeat tell, crawls to the tower it threatens over a bar with a tick per beat, and you parry as it lands. Same read as the boss, so Space always means "the projectile is arriving". The swelling ring goes.
