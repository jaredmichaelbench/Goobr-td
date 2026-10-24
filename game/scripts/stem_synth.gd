class_name StemSynth
extends RefCounted
## Placeholder music: one-bar loops for each instrument, built from simple
## synthesis so nothing waits on real audio. Steps are 8th notes (8 per bar).

const MIX_RATE := BeatClock.MIX_RATE

const KICK_STEPS: Array[int] = [0, 4]
const HAT_STEPS: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7]
const BASS_STEPS: Array[int] = [1, 3, 5, 7]
const BASS_NOTES: Array[float] = [55.0, 55.0, 65.41, 49.0]  # A1 A1 C2 G1
const LEAD_NOTES: Array[float] = [440.0, 523.25, 659.25, 880.0, 783.99, 659.25, 523.25, 659.25]


static func kick(bar_seconds: float) -> AudioStreamWAV:
	return _render(bar_seconds, func(step: int, t: float) -> float:
		if not KICK_STEPS.has(step) or t > 0.3:
			return 0.0
		var freq := 48.0 + 120.0 * exp(-t * 28.0)
		return sin(TAU * freq * t) * exp(-t * 10.0) * 0.9)


static func hat(bar_seconds: float) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	return _render(bar_seconds, func(step: int, t: float) -> float:
		if t > 0.08:
			return 0.0
		var accent := 0.35 if step % 2 == 1 else 0.22
		return rng.randf_range(-1.0, 1.0) * exp(-t * 70.0) * accent)


static func bass(bar_seconds: float) -> AudioStreamWAV:
	return _render(bar_seconds, func(step: int, t: float) -> float:
		var i := BASS_STEPS.find(step)
		if i < 0 or t > 0.22:
			return 0.0
		var f := BASS_NOTES[i]
		var env := minf(t * 200.0, 1.0) * exp(-t * 9.0)
		return (sin(TAU * f * t) + 0.45 * sin(TAU * 2.0 * f * t) + 0.2 * sin(TAU * 3.0 * f * t)) * env * 0.5)


static func lead(bar_seconds: float) -> AudioStreamWAV:
	return _render(bar_seconds, func(step: int, t: float) -> float:
		if t > 0.24:
			return 0.0
		var f := LEAD_NOTES[step]
		var env := minf(t * 300.0, 1.0) * exp(-t * 7.0)
		return (sin(TAU * f * t) + 0.3 * sin(TAU * 3.0 * f * t) + 0.15 * sin(TAU * 5.0 * f * t)) * env * 0.22)


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
