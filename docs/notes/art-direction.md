# Art direction (discussion, 2026-10-25)

Status: direction given by Jared 2026-10-25, written up as D-0037 (proposed). Jared asked whether we are in a good place for a big graphics change (isometric, 3D assets), and when the camera and 2D/3D decisions become important.

## Where the code is

Every milestone draws itself with `_draw` calls in the same script that runs the rules. Sim and picture are one thing. All board drawing goes through one mapping function (`_to_screen`), so a different projection is cheap to try, but real assets, animation and lighting are not.

## Recommendation

1. Finish Demo 0 in greybox (M6). Rules are still moving daily; art on top of moving rules is rework.
2. Decide the style in parallel as a design task with no code: top-down 2D, isometric 2D, or 3D with a locked isometric camera. Engineering lean: **3D with an orthographic camera in Godot**. Attack animations, telegraphs and Crescendo lighting are easier, there are no eight-direction sprite sets, and the grid stays readable. Pixel art is the main reason to choose 2D instead.
3. One milestone for the **sim/view split** before any asset lands: the maze, creeps, towers, notes and parries become data; a view layer renders them. About a week with no visible change. After it, assets never block rules and rules never break assets.

Look-test built 2026-10-25 (Jared asked for it): press **I** in any milestone. Board corners go through one projection function; rock, walls and tower bases are raised blocks drawn back to front. Circles, rings and text are not rescaled, so they read slightly large. Screenshots in the project `screens/iso/` folder.

Constraints already on record: readability of the grid and telegraphs first (backlog); something at the path's end is protected and the Conductor may be a character (`notes/boss-design.md`).


## Jared's direction (2026-10-25)

"A classic tower defense look, like Frozen TD or Line Tower Wars style camera but maybe with a slight tilt. Maps should read more horizontal than vertical. Even in multiplayer, 1v1v1v1 each getting a corner of a big rectangle."

What that settles (proposed as D-0037):

- **Whole board in view, no scrolling.** The camera is fixed. That is the classic read and it is also what the rhythm needs: every telegraph on screen at once.
- **3D with a slightly tilted fixed camera.** Straight-down is 90 degrees; "slight tilt" is about 60 to 70. In Godot that is one Camera3D that never moves, either a long-lens perspective (a touch of depth, towers lean away at the edges) or orthographic (no distortion, rows stay parallel, a flatter look). Recommendation: start perspective with a long lens, because it gives the "slight tilt" feel Jared describes and is a one-number change to flatten. The 45-degree isometric look-test (key I) was a different thing and goes away.
- **Landscape maps.** The board is 26 wide by 16 high from M6c on, spawn left, goal right. A 1v1v1v1 map is one rectangle with a corner per player, so a single-player map is drawn as a quarter of that rectangle from the start. Nothing is built for multiplayer now; this only decides the shape of the maps we draw.

### When these decisions become important

Not yet, and the deadline is clear: **the sim/view split milestone** (the next milestone after Demo 0 is called done). Today the rules and the picture are the same script. The split moves the picture into its own layer, and the first thing that layer needs to know is "what camera and what kind of asset". Until then nothing in the rules depends on 2D or 3D: the grid, the paths, the timings and the telegraph shapes are all data that any camera can show.

What would move the deadline earlier: wanting a screenshot or trailer with real art before the loop is finished (then the split comes first and the progression work waits). What would move it later: nothing; after the split, every new feature is built twice (rules and view) if the view does not exist, so the split should not slide past the first asset.

Open until the split: perspective vs orthographic (one number, try both), the ground tile size in metres, and whether towers are models or billboarded cards (models, unless pixel art is wanted).

## HUD reference (Jared, 2026-10-26)

Warcraft 3 / StarCraft layout, Legion TD 2 as the example (screenshot in the shared folder: screens/jared-hud-reference-legion-td-2026-10-26.png): wave banner top centre with both sides' health, player list with gold and record on the right, build and action command card bottom centre with hotkeys (B then a letter), resources bottom right, event log bottom left. Our mapping is in `prototypes/demo-1-plan.md` (M10): command card bottom right, tower panel bottom centre, resources top left, minimap slot bottom left. Tower reference: a low-poly wooden watchtower with the note ring floating above it (screens/jared-tower-reference-2026-10-26.png).
