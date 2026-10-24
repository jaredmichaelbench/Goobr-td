# Working rules for this repo

- `docs/` is the project's memory. Decisions, tasks, and backlog live there, never only in chat. Read `docs/INDEX.md` for the workflow rules before changing anything.
- Every decision gets an append-only entry in `docs/decisions/decisions.md`. Scope changes also get a line in the `docs/vision/vision.md` changelog.
- New ideas go to `docs/backlog/backlog.md` first, not straight into the build.
- The current build plan is `docs/prototypes/demo-0-plan.md`. Work one milestone at a time. Each milestone ends with `docs/prototypes/M#-results.md`.
- Game code lives in `game/` (Godot 4.5, GDScript, no plugins yet). Rhythm timing always comes from `BeatClock` (the audio clock), never from frame delta.
- Jared is the designer and playtester on a Mac Studio and a Windows PC. Explain engineering choices in plain language and give a recommendation when there's a choice to make.
