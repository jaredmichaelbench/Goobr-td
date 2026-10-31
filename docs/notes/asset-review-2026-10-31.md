# Asset review: one style for the MVP

_2026-10-31 · T-030 · proposal, waiting on Jared's picks. Claude Doc (live copy, mark it up there): https://claude.ai/artifact/Wyi48aePzKqQe3t9hZoMoc. Pictures: project shared folder `screens/asset-review/`._

A coherent MVP comes from picking one artist's family of packs, not the best model for each item. Every free pack below is CC0 (free to ship, no credit needed). Recommendation: **Family A, KayKit**, because it is already in the game and covers the camp at night best; the weak spot is enemy variety (section 4). Nothing in the build changes until Jared picks (rule 6). Source: Jared's message of 2026-10-31 14:50Z ("we should do an Asset Review...").

## 1. Pick one family

Each family is one artist with one palette, one texture method and one shape language. Mixing families makes the mishmash; mixing packs inside one family is safe.

| | A. KayKit (Kay Lousberg) | B. Quaternius | C. Kenney |
| --- | --- | --- | --- |
| Look | Chunky low-poly, soft gradient colours, slightly cute | Smooth low-poly, flat colours, rounder and cuter | Clean toy-like blocks, flat colours, very simple |
| Already in the game | Yes: towers, walls, keep, rocks, trees, four skeletons, the Mage | No | No |
| Camp at night | Strong: tents, lanterns, torches, candles, banners, graves, dead trees | Good: village and props kits (not confirmed) | Good: Survival Kit (tents, campfire), Graveyard Kit |
| Enemies | Weak free set: 4 skeleton bodies plus weapons and shields | Strongest: about 50 animated monsters | Weakest: generic people; TD Kit enemies are UFOs |
| Towers and walls | Medieval towers in 4 colours, catapult, walls, castle | Modular village, over 300 pieces | Tower Defense Kit made for the genre, castle walls |
| Ground, grass, paths | Hex tiles (board is square, so pieces only), Halloween dirt paths | Stylized Nature MegaKit | TD Kit path tiles, Nature Kit |
| Downloads from the cloud | GitHub, works | Blocked; Jared downloads by hand | Blocked; Jared downloads by hand |
| Switching cost | None | Every model in `art.gd` | Every model in `art.gd` |

Why A: already wired, the only family checked file by file, and its Halloween and Dungeon packs give the night camp in the same style as the towers. The skeleton horde suits "things that hunt in the dark". Cost: thin enemy variety.

One exception to test: Quaternius monsters with KayKit everything else, only if it passes the gallery test (section 6).

**Jared's notes:**

## 2. Night does half the work

The theme comes mostly from light: the same pack reads as a night watch once the scene is dark blue with warm pools of firelight. No downloads, works with any family.

- **Moonlight.** One cool blue-grey light, low strength, board stays readable from 65 degrees.
- **Firelight.** Warm light at the camp fire and a small one at each tower's lantern or torch.
- **The dark edge.** Fog or vignette past the board; spawns come out of the night. The Peeker leans in from there.
- **Dawn.** Light warms blue to pink to gold over the last bars of the song.
- **Notes and parries keep their colours** (Q orange, E purple); they pop more on a dark board.
- **Palette rule.** No pure white or saturated green on the ground; blues and browns, so towers, enemies and rings carry the colour.

It is a Godot setting (WorldEnvironment, two or three lights, fog), not an asset.

**Jared's notes:**

## 3. The shopping list

17 kinds of thing; KayKit covers 15 from checked files, and the gaps (caravan wagon, campfire) can be built from its pieces.

| Item | In the game | A. KayKit (checked file) | B. Quaternius | C. Kenney | Pick |
| --- | --- | --- | --- | --- | --- |
| Ground | Board floor, 26 by 16 | Halloween `floor_dirt`, Dungeon `floor_dirt_large`, or tinted plane (today) | Nature MegaKit | TD Kit tiles | |
| Grass | Tufts on the floor | Little; colour on hills | Nature MegaKit grass | Nature Kit | |
| Path | Route under creeps | Halloween `path_A` to `path_D` | not confirmed | TD Kit path tiles | |
| Background | Past the board edge | Hex `mountain_*`, `hills_*_trees`, `trees_*_large`, `cloud_*` plus fog | Nature MegaKit | Nature Kit | |
| Trees and rocks | Blockers, decor | Hex `tree_single_*`, `rock_single_*`, Halloween `tree_dead_*` | Nature MegaKit | Nature Kit | |
| The camp | What you defend | Hex `tent`, `building_castle_*` or `building_tavern_*`, `flag_red`, `crate_*`, `sack`, `barrel` | Village MegaKit, Fantasy Props | Survival Kit | |
| Caravan wagon | The band travels | Gap: `wheelbarrow`, `crate_long_*` only | possibly | possibly | |
| Campfire | Camp heart and light | Gap: `resource_lumber` plus light and particles | not confirmed | Survival Kit | |
| Lanterns, torches | Light at towers | Halloween `lantern_standing`, `post_lantern`; Dungeon `torch_lit`, `torch_mounted`, `candle_lit` | Fantasy Props | Graveyard Kit | |
| The watchman | The Conductor | Adventurers `Rogue_Hooded`, `Knight`, `Mage` (today) | not checked | Mini / Animated Characters | |
| Towers (6) | Kick, Bass, Slow, Poison, Lightning, Light | Hex `building_tower_A/B`, `tower_base`, `tower_catapult`, `church`, `archeryrange`, 4 colours | not confirmed | Tower Defense Kit | |
| Walls | Maze walls | Hex `wall_straight`, corners, gates, `fence_wood_straight`, `fence_stone_straight`; Dungeon `barrier` | Village MegaKit | Castle Kit, TD Kit | |
| Build stages | Tower going up | Hex `building_scaffolding`, `building_stage_A/B/C` | none known | none known | |
| Gold mine | Mine on the board | Hex `building_mine_*` (today) | Village kit | Survival Kit | |
| Night props | Spawns, lulls | Halloween `grave_*`, `crypt`, `coffin`, `skull`, `bone_*`, `fence_broken` | Fantasy Props | Graveyard Kit | |
| Projectiles | Bolts, arrows | Hex `projectile_catapult`, `Skeleton_Arrow`, Adventurers `arrow` | Props | TD Kit | |
| HUD icons | Portraits | Rendered from the models (today) | same | same | |

**Jared's notes:**

## 4. Enemies

KayKit gives all ten types a different look from four skeleton bodies: size, weapon and shield rather than creature. Today most elites differ only by a colour tint.

| Enemy | Job | KayKit today | KayKit better (same packs) | Quaternius idea (to check) |
| --- | --- | --- | --- | --- |
| Grunt | Basic | Minion | Minion with `Skeleton_Blade` | Small goblin-like |
| Runner | Fast | small Rogue | small Rogue, no weapon | Wolf or small beast |
| Brute | Tough | Warrior | Warrior with `Skeleton_Axe` | Ogre |
| Swarm | Many tiny | tiny pink Minion | tiny Minion or bats | Bats |
| Shade | Damage reduction | Mage | Mage with `Skeleton_Staff`, darker, glow | Ghost or wisp |
| Jammer (elite) | Winds up | red Warrior | Warrior, `Skeleton_Shield_Large_B`, axe | Shaman |
| Archer (elite) | Ranged | red Rogue | Rogue, `Skeleton_Crossbow`, `Skeleton_Quiver` | Ranged monster |
| Warden (elite) | Shields | blue Warrior | Warrior, `Skeleton_Shield_Large_A` | Golem |
| Boss | Stage boss | giant Mage | giant Mage plus props | One large monster each |
| Crowned boss | Wave 10/20 | giant Warrior | giant Warrior plus props | One large monster each |
| Field bosses (new) | Top elites | none | no good option | Most choice |
| Named stage bosses | Peeker, Tunneler, Twins... | none | no good option | Quaternius, or custom art |

Lean: the "better" KayKit column for the MVP; test Quaternius for field and stage bosses only. If they clash, bosses are the first custom art.

**Jared's notes:**

## 5. Animations and effects

The KayKit characters in the game carry 95 animations (skeletons) and 76 (Mage); only walk cycles are used today.

| Moment | Animation in the files |
| --- | --- |
| Walk, run | `Walking_A`-`D`, `Running_A`-`C` (in use) |
| Rise at the spawn | `Skeletons_Awaken_Floor`, `Spawn_Ground_Skeletons` |
| Hit | `Hit_A`, `Hit_B` |
| Death | `Death_A`, `Death_B`, `Death_C_Skeletons` (falls apart) |
| Elite wind-up and throw | `2H_Melee_Attack_Chop`, `Throw`, `Spellcast_Raise` then `Spellcast_Shoot` |
| Archer | `2H_Ranged_Aiming`, `2H_Ranged_Shoot` |
| Boss taunt, stagger | `Taunt`, `Taunt_Longer`, `Hit_B`, `Block_Hit` |
| Watchman parry, counter | `Block`, `Block_Attack`, `1H_Melee_Attack_Stab` |
| Watchman in a lull | `Sit_Floor_Idle`, `Idle_B`, `Cheer` at dawn |
| Sleeping caravan | `Lie_Idle` |
| Tower or wall goes up | Hex `building_stage_A`, `B`, `C` (about 0.3, 0.6, 1.0 of a tile tall), then the model: the WC3 construction |

Effects are made in Godot as one set: note bolt with a trail in the ring colour; parry ring burst and counter streak; bone-dust hit and death puffs (green poison, blue frost, yellow arcs); camp light flickering with the kick drum; dawn as a light change.

**Jared's notes:**

## 6. How Jared picks, and what comes after

1. Jared marks the doc: family, a pick per row, the enemy column. "Use your lean" is fine for any row.
2. Downloads: KayKit from GitHub in the cloud; Quaternius or Kenney by hand into `game/assets/` with exact links.
3. Model gallery screen (dev menu key): the real camera and night lighting, candidates side by side, enemies walking and dying, towers going up, the camp with its fire; keys flip day/night and swap a candidate.
4. Jared picks from the gallery; picks become a decision; models swap in `art.gd` (rules do not move).
5. Night lighting and effects come with the swap as one look pass.

Not touched: rules, balance, level template, card and talent passes (T-024). Custom art later slots into the same `art.gd` table.

**Jared's notes:**

## Sources and licences

All CC0 1.0. KayKit asks that unmodified files are not resold or claimed as your own.

- KayKit, checked file by file from GitHub: Medieval Hexagon, Skeletons, Adventurers, Halloween Bits, Dungeon Remastered (https://kaylousberg.itch.io). Not checked: Forest, Character Animations.
- Quaternius (search results only; site blocked from the cloud): Medieval Village MegaKit, Stylized Nature MegaKit, Fantasy Props MegaKit, Ultimate Monsters (https://quaternius.com/packs/).
- Kenney (search results only; site blocked): Tower Defense Kit, Graveyard Kit, Fantasy Town Kit, Survival Kit, Mini Characters (https://kenney.nl/assets).
- Licence log: `notes/asset-licenses.md`.
