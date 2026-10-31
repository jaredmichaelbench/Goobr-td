# Demo 1 playtest 4 (rhythm fix build), 2026-10-27

Jared, 03:23Z, after 253acbf (D-0047). He won 20 waves in 12:37 with 13 of 20 health. Notes 381 of 493 (77%), Perfects 235, parries 60 of 115, calls nailed 51 of 80, staggers 14, counters 0 of 42, level 26. His picks went into XP and gold: gold +248%, XP +234%. End screen: shared folder `screens/demo1-playtest4/end-screen-2026-10-27.png`.

Verbatim:

> The level chime and notification should occur at the end of a level, and also on the end of level card. I noticed the chime is nice, I dont forget but its distracting in the middle of a wave where you need to focus on timing.
>
> First boss still died in one crescendo, about half way through it actually. I have upgraded towers at this point, but we still need to increase first boss health.
>
> The more I think about the boss being in the middle the more it makes sense, not even protected by terrain, but you have to think strategically, enemies from all sides, and in multiplayer all sides would make sense, you use your walls and towers to fortify the boss and make a maze entrance enemies have to enter from to funnel them. This should be considered for play testing as it might even function better as the default mode solving a few issues with strained focus on left or right.
>
> Notcing lag post level 15 which for this style of game doesnt work, cant hit notes
>
> Also noticing parry in melee (tower disabled) the circle with 4 dots, the timing doesnt feel right, I want to press it when the 4th dot lands or after? It feels different than the ranged arrow which I always press on the 4th dot with the beat, the melee one I struggle with, do they differ in timing?
>
> In general this run was obsurdly easy. I went into the exp/gold talents, and I basically broke it, but even without that I feel it would have been far too easy. I think we just bump health a bit faster enemies, maybe more enemy types we need to conjure up. Even with missing notes due to lag It felt easy. Just to be clear the notes felt great, and I think that 8th note talent will give players some more skill expression, its just the balance is too easy.
>
> LAg seemed to appear when more enemies m ore towers and more poison going. definitely need to be able to handle like 30x this much going on becuase endless mode and full game will require more.
>
> Something else I'm thinking to avoid what I have today (The clump) - An efficient tower set up has a maze wrap around strong tower clumps buffed by light, getting as much use out of the buffed towers as possible, so you want to build close. Maybe towers need to cost more incrementally per one you palce per type so you arent placing so many for one thing, for another maybe increase the light tower range so it covers more liberally so you almost get a 1/5th of the map, one for each quadrant so you arent incentived to clump there? Not sure yet what the full solution is, but using 1 line of the map for 20 levels feels kind of lame. Something with the economy or another mechanic could force more walls, less towers, more upgrades?
>
> And after seeing the melee parry in action again, yes, confirmed the one from elite units is bugged or intended to be much different, the 4 dots counted, then the ball traveled and it was about a beat later, if even on the beat. Please confirm

## What the code says (Claude)

- **Melee parry: confirmed as a bug.** From wave 11, half of the elite throws wind up for a bar and a half (6 beats) instead of one bar. This comes from `M7Run.throw_wind_bars` returning 1.5. The four pips still count one per beat, so they fill on beat 4 and the ball lands two beats later, on beat 3 of the next bar. Arrows always take exactly one bar, which is why they feel right. The late landing also falls on beat 3, where call notes now sit (D-0047).
- **Level-up chime.** It plays the moment XP crosses a level (`RunSim.gain_xp`).
