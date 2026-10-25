# Art direction (discussion, 2026-10-25)

Status: nothing decided. Jared asked whether we are in a good place for a big graphics change (isometric, 3D assets).

## Where the code is

Every milestone draws itself with `_draw` calls in the same script that runs the rules. Sim and picture are one thing. All board drawing goes through one mapping function (`_to_screen`), so a different projection is cheap to try, but real assets, animation and lighting are not.

## Recommendation

1. Finish Demo 0 in greybox (M6). Rules are still moving daily; art on top of moving rules is rework.
2. Decide the style in parallel as a design task with no code: top-down 2D, isometric 2D, or 3D with a locked isometric camera. Engineering lean: **3D with an orthographic camera in Godot**. Attack animations, telegraphs and Crescendo lighting are easier, there are no eight-direction sprite sets, and the grid stays readable. Pixel art is the main reason to choose 2D instead.
3. One milestone for the **sim/view split** before any asset lands: the maze, creeps, towers, notes and parries become data; a view layer renders them. About a week with no visible change. After it, assets never block rules and rules never break assets.

Look-test built 2026-10-25 (Jared asked for it): press **I** in any milestone. Board corners go through one projection function; rock, walls and tower bases are raised blocks drawn back to front. Circles, rings and text are not rescaled, so they read slightly large. Screenshots in the project `screens/iso/` folder.

Constraints already on record: readability of the grid and telegraphs first (backlog); something at the path's end is protected and the Conductor may be a character (`notes/boss-design.md`).
