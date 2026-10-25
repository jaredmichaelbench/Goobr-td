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


## One-shot voices for hits, parries and locks: short synth sounds in E, the
## bed's key, so feedback is half effect, half music (D-0029).

## Plucked pad: a note landed. Brighter and higher for a Perfect.
static func pluck(freq: float, bright := false) -> AudioStreamWAV:
	return _one_shot(0.28, func(t: float) -> float:
		var env := minf(t * 600.0, 1.0) * exp(-t * 9.0)
		var v := sin(TAU * freq * t) + 0.5 * sin(TAU * freq * 2.0 * t) * exp(-t * 14.0)
		if bright:
			v += 0.35 * sin(TAU * freq * 3.0 * t) * exp(-t * 20.0) + 0.2 * sin(TAU * freq * 4.0 * t) * exp(-t * 30.0)
		return v * env * 0.35)


## Filtered bass stab: a parry. A click on top for a Perfect.
static func stab(freq: float, click := false) -> AudioStreamWAV:
	return _one_shot(0.3, func(t: float) -> float:
		var env := minf(t * 900.0, 1.0) * exp(-t * 8.0)
		var cutoff := 1.0 + 6.0 * exp(-t * 18.0)  # Filter sweep down, as a few harmonics fading.
		var v := sin(TAU * freq * t)
		v += 0.5 * sin(TAU * freq * 2.0 * t) * minf(cutoff / 2.0, 1.0)
		v += 0.33 * sin(TAU * freq * 3.0 * t) * minf(cutoff / 3.0, 1.0)
		v += 0.25 * sin(TAU * freq * 4.0 * t) * minf(cutoff / 4.0, 1.0)
		if click and t < 0.02:
			v += sin(TAU * 2200.0 * t) * (1.0 - t / 0.02) * 0.8
		return v * env * 0.4)


## Low detuned thud: a tower locked, a shield broken.
static func thud() -> AudioStreamWAV:
	return _one_shot(0.35, func(t: float) -> float:
		var env := minf(t * 400.0, 1.0) * exp(-t * 7.0)
		var freq := 55.0 + 40.0 * exp(-t * 25.0)
		return (sin(TAU * freq * t) + 0.6 * sin(TAU * freq * 1.03 * t)) * env * 0.5)


## Muted tick: a miss or an off-beat press. Short and dry.
static func tick(freq := 330.0) -> AudioStreamWAV:
	return _one_shot(0.08, func(t: float) -> float:
		var env := minf(t * 2000.0, 1.0) * exp(-t * 60.0)
		return sin(TAU * freq * t) * env * 0.25)


## Feedback sounds can be replaced by dropping a WAV in game/audio/sfx/ named
## after the sheet in docs/notes/sound-sheet-2026-10-25.md (for example
## note-perfect.wav). Missing files fall back to the synth voice.
const SFX_FILES := {
	"perfect": "note-perfect", "good": "note-good", "miss": "note-miss", "clear": "wave-clear",
	"parry": "parry", "parry_perfect": "parry-perfect", "restore": "restore", "suppress": "tower-locked",
	"tell": "tell", "tick": "beat-tick", "break": "posture-break",
}


static func with_override(key: String, synth: AudioStreamWAV) -> AudioStreamWAV:
	var path := "res://audio/sfx/%s.wav" % SFX_FILES.get(key, key)
	if not FileAccess.file_exists(path):
		return synth
	var stream := AudioStreamWAV.load_from_file(ProjectSettings.globalize_path(path))
	if stream == null:
		push_warning("Could not read %s, using the synth voice" % path)
		return synth
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	print("sfx override: ", path)
	return stream


static func _one_shot(seconds: float, voice: Callable) -> AudioStreamWAV:
	var frames := int(seconds * MIX_RATE)
	var data := PackedByteArray()
	data.resize(frames * 2)
	for i in frames:
		var t := float(i) / MIX_RATE
		var v: float = voice.call(t)
		data.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 32767.0))
	var stream := BeatClock.make_loop(data)
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return stream


## A short bell. Kept for M1 and the menu.
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
