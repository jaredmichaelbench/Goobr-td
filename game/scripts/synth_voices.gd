class_name SynthVoices
extends RefCounted
## Demo 1 note sounds (Jared, 2026-10-26: "more synthy" for perfect, good and miss).
## Built in code like StemSynth, in E so they sit on the bed: a Perfect is a bright
## detuned-saw stab with an octave sparkle, a Good a softer square pluck, a Miss a
## short falling buzz. Prefs "synth_notes" picks these over a sound pack's files.

const MIX_RATE := BeatClock.MIX_RATE


static func _saw(phase: float) -> float:
	return 2.0 * (phase - floorf(phase + 0.5))


static func _render(seconds: float, voice: Callable) -> AudioStreamWAV:
	var frames := int(seconds * MIX_RATE)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var lp := 0.0
	for i in frames:
		var t := float(i) / MIX_RATE
		var out: Array = voice.call(t)  # [sample, cutoff 0..1]
		lp += (float(out[0]) - lp) * clampf(out[1], 0.01, 1.0)
		data.encode_s16(i * 2, int(clampf(lp, -1.0, 1.0) * 32767.0))
	var stream := BeatClock.make_loop(data)
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return stream


## Perfect: E5 major-ish stab, three detuned saws, filter opening then closing.
static func perfect() -> AudioStreamWAV:
	return _render(0.45, func(t: float) -> Array:
		var env := minf(t * 300.0, 1.0) * exp(-t * 7.0)
		var v := 0.0
		for f in [659.3, 663.1, 655.5, 987.8, 1318.5]:
			v += _saw(f * t) * (0.5 if f > 1000.0 else 0.32)
		v += sin(TAU * 2637.0 * t) * exp(-t * 22.0) * 0.35  # Sparkle.
		var cutoff := 0.08 + 0.55 * exp(-t * 9.0)
		return [v * env * 0.32, cutoff])


## Good: E4 square pluck, rounder and shorter.
static func good() -> AudioStreamWAV:
	return _render(0.3, func(t: float) -> Array:
		var env := minf(t * 400.0, 1.0) * exp(-t * 12.0)
		var sq := 1.0 if fmod(329.6 * t, 1.0) < 0.5 else -1.0
		var v := sq * 0.5 + _saw(659.3 * t) * 0.2
		return [v * env * 0.35, 0.06 + 0.3 * exp(-t * 18.0)])


## Miss: a detuned saw falling an octave, quiet, so it reads without stinging.
static func miss() -> AudioStreamWAV:
	var phase := [0.0, 0.0]
	return _render(0.25, func(t: float) -> Array:
		var f := 164.8 * pow(0.5, t * 4.0)
		phase[0] += f / MIX_RATE
		phase[1] += f * 1.03 / MIX_RATE
		var env := minf(t * 200.0, 1.0) * exp(-t * 10.0)
		return [(_saw(phase[0]) + _saw(phase[1])) * 0.3 * env, 0.12])
