# Demo 1 UI review: discussion (2026-10-26)

Live copy for markup: Claude Doc "Demo 1 UI review: discussion" (https://claude.ai/artifact/UZDw8n5KT4Fk7mMuiBqWMX). Status: proposed, waiting on Jared.

Sources: Jared's first look at the 3D build, two outside AI reviews he pasted (Gemini, Claude Sonnet), and his 36 s recording of waves 11 to 13 (notes 110/200, parries 26/37, counters 0/11; "hitting notes/parries was extremely hard").

## Agreed by both reviews and Claude
HUD eats the board; combat text piles mid-screen; everything is text (buttons, wave preview, tower panel, tree); rhythm layer too quiet; towers alike and rank dots unreadable; flat lime board with beige everything; talent tree reads as a spreadsheet; top bar has no icons or priorities.

## Claude's pushback
- No Q W E R build keys (Q and E are note keys); no Space to start a wave (Space is parry).
- No auto-zoom or orthographic camera: fixed 65 degree camera stands (D-0043); a smaller HUD gives the room back.
- Award polish (controller, colour-blind, text scaling, respec) goes to the backlog.

## Why timing felt hard (Claude's read of the recording)
1. The project rename reset the saved calibration to 0 ms (notes landing about -50 ms early).
2. The game ran embedded in the Godot 4.5 editor, which can add display delay.
3. A small window on a 4K screen.

## Proposed readability pass (no rule change, about 2 to 3 sessions)
1. Room for the board plus an always-on beat bar with playhead, judgment and streak.
2. Text cleanup and a wave-clear card.
3. Pictures: tower buttons, creep icons in the wave preview, top-bar icons.
4. One type scale, nothing clipped.
5. Calmer board, distinct walls, marked spawn, rank bands, fork model swap.
6. Talent tree with lines, area colours, shared nodes once, board dimmed.
7. First-launch calibration prompt, step strip in the tower panel, counter re-check.

Questions to Jared: package size, keys, and a recalibrated full-screen two-wave check before building.
