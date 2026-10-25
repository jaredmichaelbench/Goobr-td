class_name StemSynth
extends RefCounted
## Placeholder music bed: one-bar loops built from simple synthesis so nothing
## waits on real audio. Steps are 8th notes (8 per bar). The bed is bass and
## rhythm only (kick, sub pulse, a low 8th-note pulse), nothing melodic, so it
## sits under a real track and a ducked miss sounds plain rather than bad.

const MIX_RATE := BeatClock.MIX_RATE

const KICK_STEPS: Array[int] = [0, 4]
const HAT_STEPS: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7]
const BASS_STEPS: Array[int] = [1, 3, 5, 7]  # Off-beats: the splash tower fire pattern (M3).
const SUB_STEPS: Array[int] = [0, 2, 4, 6]  # Every beat.
const SUB_FREQ := 41.2  # E1
const PULSE_FREQ := 82.4  # E2


static func kick(bar_seconds: float) -> AudioStreamWAV:
	return _render(bar_seconds, func(step: int, t: float) -> float:
		if not KICK_STEPS.has(step) or t > 0.3:
			return 0.0
		var freq := 48.0 + 120.0 * exp(-t * 28.0)
		return sin(TAU * freq * t) * exp(-t * 10.0) * 0.6)


static func hat(bar_seconds: float) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	return _render(bar_seconds, func(step: int, t: float) -> float:
		if t > 0.08:
			return 0.0
		var accent := 0.35 if step % 2 == 1 else 0.22
		return rng.randf_range(-1.0, 1.0) * exp(-t * 70.0) * accent)


## Sub-bass pulse on every beat: a long, soft sine with a hint of the octave.
static func bass(bar_seconds: float) -> AudioStreamWAV:
	return _render(bar_seconds, func(step: int, t: float) -> float:
		if not SUB_STEPS.has(step) or t > 0.4:
			return 0.0
		var env := minf(t * 120.0, 1.0) * exp(-t * 5.0)
		return (sin(TAU * SUB_FREQ * t) + 0.25 * sin(TAU * 2.0 * SUB_FREQ * t)) * env * 0.6)


## Intensity layer: a short, low 8th-note pulse. Quiet and unmelodic; it
## opens up as the player's streak grows.
static func lead(bar_seconds: float) -> AudioStreamWAV:
	return _render(bar_seconds, func(step: int, t: float) -> float:
		if t > 0.1:
			return 0.0
		var env := minf(t * 400.0, 1.0) * exp(-t * 30.0)
		var accent := 1.0 if step % 2 == 0 else 0.6
		return (sin(TAU * PULSE_FREQ * t) + 0.3 * sin(TAU * 3.0 * PULSE_FREQ * t)) * env * 0.3 * accent)


## Renders a bar by calling voice(step, seconds_since_step) for every sample.
static func _render(bar_seconds: float, voice: Callable) -> AudioStreamWAV:
	var frames := int(round(bar_seconds * MIX_RATE))
	var step_frames := frames / 8
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in frames:
		var step := mini(i / step_frames, 7)
		var t := float(i - step * step_frames) / MIX_RATE
		var v: float = voice.call(step, t)
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	return BeatClock.make_loop(data)


## A short bell for the "call" half of a phrase. Not looped.
static func chime(freq: float) -> AudioStreamWAV:
	var frames := int(0.5 * MIX_RATE)
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in frames:
		var t := float(i) / MIX_RATE
		var env := minf(t * 400.0, 1.0) * exp(-t * 6.0)
		var v := (sin(TAU * freq * t) + 0.35 * sin(TAU * 2.76 * freq * t) * exp(-t * 10.0)) * env * 0.35
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	var stream := BeatClock.make_loop(data)
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return stream
