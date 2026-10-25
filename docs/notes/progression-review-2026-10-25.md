# Progression review (draft for Jared to mark up, 2026-10-25)

Status: draft. Nothing here is decided. It takes Jared's notes in `power-and-challenge.md` and the M6b playtest ("picks feel samey, I want them to reach into the bizarre") and turns them into a proposal with examples, so the next build can be argued about on paper first. Mark it up in the file or in chat; agreed points go to `decisions/decisions.md`.

## 1. What the playtest said

- The core loop is right: "feels great as a core loop", "I like how it plays for now".
- Power today is one axis: gold into tower tiers, and a draft that mostly adds small numbers (+40 gold, +1 shield, +1 charge). The altering cards are the only picks anyone remembers (Chain snipe, Shatter).
- Jared's own words for the three layers: a tech tree that is "kind of boring" and global; rogue-lite picks that are "game-altering, even bizarre, but balanceable"; and conditional upgrades you have to earn by playing well, which he called "sick".
- The thing Jared loved most in play is the infinite-range snipe. The best picks will make more moments like that, not more numbers.

## 2. The frame: three layers, three jobs

| Layer | When | Job | Mood | Where it lives today |
|---|---|---|---|---|
| Tower upgrades | in-run, gold | the TD economy decision every wave | boring on purpose | tiers, U / Upgrade button (M6a) |
| Draft picks | in-run, after each wave | rogue-lite: change the rules of this run | bizarre, run-defining | CARDS pool in `m6_run.gd` (M6b) |
| Talents | between runs, permanent | slow global growth, never changes what a tower does | boring, steady | not built (post Demo 0) |

The rule that keeps them from fighting: **only the draft changes what a thing does. Upgrades and talents only change how much.** If a talent ever "unlocks chain lightning", it belongs in the draft pool instead, as a card you can now see.

Why boring upgrades are right: the gold decision each wave has to be fast and legible ("do I buy a tower or a tier?"). Bizarre options there would slow the wave-to-wave rhythm the loop depends on.

## 3. The draft, rebuilt

### 3.1 Why the current pool feels samey

Every card is "a stat, a bit higher". The run plays the same with or without the pick. A card should pass this test: **after taking it, would you build the maze differently or press differently?** None of the plain cards pass it. Chain snipe and Shatter do.

### 3.2 Three rarities, by how much they bend the run

- **Grey, small (immediate).** Keep a few as the safe option, but make them about tempo and choice, not stats: *Head start* (next wave spawns with +60 gold already spent on a free tower of your choice), *Breathing room* (next wave's groups spawn 2 s further apart), *Encore* (the next boss opens staggered for 4 s).
- **Orange, altering (once per run).** The core of the layer. Each one changes what a tower, a note or a parry does. Examples that pass the test:
  - *Ricochet*: snipes that kill bounce to the next creep in a straight line through walls.
  - *Overclock*: the heavy tower fires only on Perfect notes, at x10.
  - *Undertow*: splash waves push creeps back one tile.
  - *Glass cannon*: +100% damage on every tower; every leaked creep costs double.
  - *Long arm*: the Conductor's parry also hits every creep within 2 tiles of the goal.
  - *Echo*: a landed E note repeats on the next off-beat for free.
- **Blue, conditional (locked, earn it next wave).** Jared's "sick" layer. The condition is always a play-skill test, never luck: 6 Perfects, no attack lands, no shield lost, a flawless Volley. Rewards sit above orange: *Sharpshooter* (Perfect snipe x12), *Iron rhythm* (one free Restore a wave), *Metronome* (the parry window widens by 40 ms for the run).

### 3.3 The bizarre end (candidates, from `power-and-challenge.md`)

These are the ones to argue about. Each one is balanceable because it trades something:

- *The Conductor walks*: the goal moves one tile along the path toward the spawn every wave; shorter path, but every tower near the old goal is now mid-maze crossfire. Trade: pressure for position.
- *Backwards wave*: the next wave spawns at the goal and walks to the start; you defend the start for one wave. Trade: your maze is built the wrong way round; the reward is double gold.
- *Time stop*: a Perfect parry freezes every creep for one beat. Trade: it replaces the parry's return damage.
- *Your own Shade*: one tower of your choice is veiled from Jammers and Wardens; it cannot answer notes. Trade: safety for silence.
- *Decay*: gold shrinks 10% every wave it is unspent; kill gold is +50%. Trade: forces spending, rewards greed.
- *Swarm as one*: a pack counts as a single creep for splash (the whole pack takes the full hit). Trade: Swarm waves become trivial, Brute waves get no help.

Recommendation: ship one bizarre card per run in the pool so every run has one "oh no" moment, not three.

### 3.4 Pool rules

- A draft always shows one grey, one orange, and a blue 60% of the time (as now).
- No duplicates in a run; orange and blue are once per run.
- Cards can be **tower-specific**: an orange card names a tower type and rewrites its note. That is how "evolving towers" works without a tree (section 4).
- Every card has a short name, a one-line effect, and the trade in the same sentence. If the trade does not fit in one line, the card is too complicated.

## 4. Evolving towers

Jared's instinct: a low starter count that evolves, not many base towers. Proposal:

- **Three base towers**, as now: Heavy (single target, snipe note), Splash (area, wave note), Slow (control, freeze note). Walls are not a tower.
- **Each base tower has two evolutions**, reached by taking its orange card in the draft. The card changes the tower's fire and its note for the whole run and recolours the tower. Six evolved forms, one draft pick each:

| Base | Evolution A | Evolution B |
|---|---|---|
| Heavy | *Marksman*: fires half as often for triple damage; its note pierces through every creep in a line | *Chain*: its snipe jumps to two more creeps within 3 tiles |
| Splash | *Quake*: hits stagger creeps for a beat; its note knocks back | *Ember*: leaves a burning tile for a bar; its note ignites the whole path segment |
| Slow | *Frost*: frozen creeps shatter for x3 on the next hit (Shatter becomes built in); its note freezes a whole pack | *Tar*: slowed creeps also take +50% from every tower; its note halves a creep's speed for the wave |

- Tiers (gold) still apply to an evolved tower and keep being "how much".
- Only one evolution per base per run. Choosing Chain means no Marksman this run. That is the rogue-lite decision.

Why this beats more base towers: three build buttons stay readable, every run can end with a different six-tower set from the same three buttons, and the draft gets six cards that obviously pass the "would you build differently" test.

## 5. Talents (sketch, post Demo 0)

Global, permanent, bought with a currency earned per run (score or waves cleared). Rows of plain nodes, each a few percent: parry window, parry return damage, note crit damage, range per tower type, start gold, Restore charges. One row per tower type so a player who loves Slow can lean in. No node changes what a thing does. Deferred until the draft and evolutions are proven, because talents can hide a weak draft.

## 6. Challenge side (the other half of the review)

Every power above needs a wall to push on. The levers in `power-and-challenge.md` are all still right. New ones from M6b: Shade and Warden already force notes and parries; the wave 10 boss forces reads. Candidates for the next pass: a creep that disables Restore for a bar, a Jammer that locks two towers at once from wave 8, a boss that changes the path. Jared's "lots of attack and enemy variation is going to be key" applies here as much as to picks.

## 7. Proposed order of work

1. Agree this frame (sections 2 and 3.4) in a decision.
2. Build the evolutions (section 4) as six orange cards: one milestone, every pick passes the test by construction.
3. Replace the plain cards with the grey list in 3.2 and add two or three bizarre cards.
4. Play, then decide if the pool needs a currency (reroll, bank a card) or not.
5. Talents after the sim/view split.

## 8. Questions for Jared

- Does the "only the draft changes what a thing does" rule hold for you, or do you want some bizarre nodes in the tree too?
- Of the bizarre list in 3.3, which two would you take in a run tonight? Which one is too much?
- Evolutions: six is a proposal. Do any of the six names make you want them? Which base tower is missing its obvious evolution?
- Conditional picks: is "earn it next wave" right, or should some be "earn it this run" (a longer target)?
