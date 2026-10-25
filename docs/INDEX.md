# Goobr's Tower Defense: project docs

The single source of truth for the game. If it isn't in here, it wasn't decided.

## Layout

| Folder | What lives there |
|---|---|
| `vision/vision.md` | The hook, pillars, and first-playable line. Living doc with a changelog. |
| `decisions/decisions.md` | Decision log (D-000X). Append-only. |
| `tasks/tasks.md` | Active work (T-0XX), Now / Next. |
| `backlog/backlog.md` | Parked ideas with source and what would promote them. |
| `prototypes/` | Prototype plan and per-prototype results write-ups. |
| `notes/` | Research, competition, raw inputs (the original pitch is archived here). |

Later workstreams (art direction, music, assets, revenue/Steam) get their own folder when they open, each with the same shape: a brief, decisions in the main log, tasks in the main task list.

## Rules of the workflow

1. Anything decided in conversation is written to `decisions/` the same day.
2. New ideas go to `backlog/` first, never straight into scope.
3. Promoting an idea means: a decision entry, a task, and a vision changelog line if it changes scope.
4. Every prototype ends with a results file and a keep/kill call.
5. Discarded ideas stay in the backlog marked `dropped`, with a reason. Nothing is deleted.
6. **Playtest, then agree, then build.** (Jared, 2026-10-25) A build pass goes to Jared whole. He plays it and collects all his feedback, even if it arrives in pieces, and says when he's done testing. Claude then replies with a discussion: what it would change, where it pushes back (the feature may have been meant differently than it played), and open questions. Nothing changes in the build until both agree. Feedback is logged in the milestone's results file as it comes in, marked as collected or acted on.
