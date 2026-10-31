# Tasks

Active work. Each task has an id, status, and a link to the decision or prototype it serves. Status: `todo`, `doing`, `done`, `blocked`.

## Now

| Id | Task | Status | Notes |
|---|---|---|---|
| T-011 | Agree how we build: who writes code, how Jared runs builds | doing | Waiting on Jared |
| T-012 | M0: set up the engine project in the repo | done | `game/` in this repo |
| T-013 | M1: beat and input feel, tested on Mac and PC | doing | Mac passed 2026-10-24 (`docs/prototypes/M1-results.md`). PC still to test. |

## Next

| Id | Task | Status | Notes |
|---|---|---|---|
| T-014 | M2: maze, grid, flow-field pathing | done | Passed 2026-10-24 (`docs/prototypes/M2-results.md`) |
| T-015 | M3: the maze plays the song | done | Four passes, 2026-10-24 to 25. Song chart + timeline (D-0014), rock map (D-0015). Tuning notes in `prototypes/M3-results.md` |
| T-020 | Contact VOiD1 Gaming: tell them about the use of the SynthWave music and HALFTONE SFX packs, ask about full packs and credit wording | todo | Jared, 2026-10-25: more emphasis on reaching out. Their licence asks to be told; credit appreciated. Handles in `notes/asset-licenses.md` (void1gaming.com, itch.io, Instagram, Twitter, Facebook). Before any public build |
| T-019 | Economy and relative tower power pass | doing | First pass in M6a slice 3 (D-0028): upgrade sink, wave bonus 12 + 3w. Jared: balance at wave 9 "almost perfect" before it; re-check after |
| T-016 | M4: suppress and Restore | done | Three passes 2026-10-25 (D-0016 to D-0019). Keep: Restore feels great, silence is recoverable tension |
| T-017 | M5: first boss | doing | Three passes 2026-10-25 (D-0020 to D-0024): "genuinely fun". Polish pass D-0025 built; one more playtest then done |
| T-018 | M6: Demo 0 wrap-up | doing | M6c built 2026-10-25 (D-0036: click to select, tower panel, build bar, clickable draft and run screens, pause, 26x16 board), awaiting Jared's playtest. M6b played 2026-10-25: "fun, an improvement", picks samey (parked to the progression review, `notes/progression-review-2026-10-25.md`). M6a built incl. follow-up D-0029 (straight arrows, streak ball, musical voices), awaiting playtest. Agreed 2026-10-25: three slices, M6a TD depth (third tower, upgrades, economy = T-019), M6b the run (10 waves, draft, boss at 10, win/lose), M6c UI layer. See `notes/path-ahead-2026-10-25.md` |
| T-026 | L1 Demo 1 fixes: melee parry lands one bar after the throw; level-up chime on the wave-clear card | done | `prototypes/level-template-plan.md` |
| T-027 | L2 performance pass: stress test at 10x and 30x a late wave, fix the hot spots | done | Jared saw lag after wave 15 (playtest 4) |
| T-028 | L3 the template level on Night Life: editable level file, count-off build, pushes and lulls, card at the end | review | D-0048; Jared choreographs from here |
| T-029 | Night 1 v2 (D-0051): economy, build range, boss on the song clock, boss music, start panel, talents after the night, miss log, Night 1 asks less | review | `notes/night-1-playtest-discussion.md`; waiting on Jared's playtest |
| T-030 | Asset review (major): list every model and visual the MVP needs (ground, grass, background, paths, the camp and keep, every enemy type, towers, walls, attack and build animations, effects) and give Jared options from free libraries to pick a coherent MVP style for the night-watchman theme; custom art later, possibly by Jared | todo | Jared, 2026-10-31 14:50Z. Major task alongside the card and talent passes (T-024). Backlog: camp assets, build animations |
| T-025 | Multiplayer discussion doc, like the single-player journey doc: closer to Legion TD (downtime after each wave, sends) | todo | Jared, 2026-10-31, comment on `notes/single-player-journey-2026-10-31.md`. Single player is song levels; multiplayer stays on waves |
| T-024 | Demo 1 bundle 4 (D-0046): talent tree shape and linking, tower unlocks in the Towers tree, card review with a new lens, card look and information | waiting on Jared's sketches | Jared will draw the tree and the cards. Draft cadence proposal: about 12 drafts a run (every other wave plus bosses). Playtest 3 (2026-10-27): start from run length (multiplayer match, endless): cards per rarity, then write cards that are exciting but not overpowered; XP curve and how many talents a multiplayer run and an endless run reach (is level 100 the XP of levels 1-77?); conditional "locked" cards must explain themselves |
| T-022 | M7: the progression update (type upgrades, six towers, levels and tree, counter-attack, rolled draft, 20-wave run, stats) | done: three playtests; M7 closes Demo 0 (D-0042) | Jared's go 2026-10-26; shipped the same day (D-0039). Results in `prototypes/M7-results.md`. One big test and notes session next |
| T-021 | Sim/view split milestone (rules as data, one view layer) before any asset; camera and 2D/3D become binding here (D-0037) | todo | After Demo 0 is called done. About a week, no visible change |
| T-009 | Apple Developer account ($99/yr) for signing and notarization | todo | Only needed before sharing Mac builds |

## Done

| Id | Task | Notes |
|---|---|---|
| T-001 | GitHub repo | jaredmichaelbench/goobr-td, created 2026-10-24 |
| T-002 | Jared reviews the vision | Done 2026-10-23 via comments (D-0005 to D-0009) |
| T-003 | Global beat vs per-tower timing | Settled in D-0010 |
| T-010 | Choose the engine | Godot 4 (D-0011) |
| T-004 | Latency sandbox in both engines | Replaced by M1 in one engine |
| T-008 | Stem-split test track | Replaced by procedural placeholder stems |
| T-023 | Demo 1: the 3D build (`prototypes/demo-1-plan.md`): M8 look test, M9 sim/view split, M10 HUD and menus, M11 sound and music, M12 private demo package | M8 to M12 built (D-0044), waiting on Jared's playtest | Jared's go 2026-10-26 (D-0042): recommendations stand, one map, Conductor inside a keep model, RTS-style HUD |
