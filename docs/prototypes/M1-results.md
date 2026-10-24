# M1 results: beat and input feel

## Mac Studio (2026-10-24)

- Calibration: not yet applied (0 ms) when measured.
- Raw mean offset: **+45.8 ms** (Jared's taps land consistently late against the audio). Calibration (C) corrects this.
- Spread (std dev, last 16 taps): **20.0 ms**. That's right at the "good" threshold. Some of it is the up-to-one-frame input jitter noted in `game/README.md`.
- Grades uncalibrated: Perfect 13, Good 23, Miss 0. Most Goods are the +46 ms offset; after calibration they should mostly become Perfects.
- Feel (Jared): "Perfect feels fair. Missing means you aren't locked in; it's not hard to get Good on every note if you're ready."

**Verdict (Mac): pass.** Godot's native audio clock is consistent enough to build on. The Perfect (35 ms) and Good (90 ms) windows feel right and stay as defaults.

## Windows PC

- Not yet tested.

## Follow-ups

- Make calibration part of first launch (it's needed: a 46 ms offset turns Perfects into Goods).
- If the PC spread is much higher than the Mac's, improve input timing (timestamp inputs between frames) before M3.
