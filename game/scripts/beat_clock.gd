class_name BeatClock
extends Node
## Plays a looping one-bar click track and reports song time from the audio
## clock, not from frame delta. Every rhythm system reads time from here.
##
## Extra one-bar stems can be added before start(). They play sample-locked
## with the click (one AudioStreamSynchronized), and each has its own volume,
## which is how towers bring their instrument in and out of the mix.

signal beat(index: int)

const MIX_RATE := 44100

@export var bpm := 120.0
@export var beats_per_bar := 4

var _player: AudioStreamPlayer
var _sync: AudioStreamSynchronized
var _stems: Array[AudioStream] = []
var _stem_db := PackedFloat32Array()
var _click_muted := false
var _bar_count := 0
var _last_raw_pos := 0.0
var _last_beat := -1


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	add_child(_player)
	_rebuild_stream()


func _exit_tree() -> void:
	_player.stop()
	_player.stream = null


func start() -> void:
	_bar_count = 0
	_last_raw_pos = 0.0
	_last_beat = -1
	_player.play()


func set_bpm(value: float) -> void:
	bpm = clampf(value, 60.0, 200.0)
	var was_playing := _player.playing
	_player.stop()
	_rebuild_stream()
	if was_playing:
		start()


## Mutes only the click (stem 0).
func set_muted(muted: bool) -> void:
	_click_muted = muted
	_sync.set_sync_stream_volume(0, -80.0 if muted else 0.0)


## Adds a looping stem one bar long at the current BPM. Returns its index,
## which is what set_stem_volume_db() takes. Call before start().
func add_stem(stream: AudioStream, volume_db := 0.0) -> int:
	_stems.append(stream)
	_stem_db.append(volume_db)
	_rebuild_stream()
	return _stems.size()


func set_stem_volume_db(index: int, db: float) -> void:
	_sync.set_sync_stream_volume(index, db)


func beat_length() -> float:
	return 60.0 / bpm


func bar_length() -> float:
	return beat_length() * beats_per_bar


## Seconds since start() as heard by the player, compensated for mix and
## output latency.
func song_time() -> float:
	if not _player.playing:
		return 0.0
	var raw := _player.get_playback_position()
	if raw + 0.0001 < _last_raw_pos:
		_bar_count += 1
	_last_raw_pos = raw
	var t := _bar_count * bar_length() + raw
	return t + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()


## Signed seconds from time t to the nearest beat (negative = early).
func offset_to_nearest_beat(t: float) -> float:
	var phase := fposmod(t, beat_length())
	return phase if phase < beat_length() * 0.5 else phase - beat_length()


func _process(_delta: float) -> void:
	var b := int(floor(song_time() / beat_length()))
	if b != _last_beat and b >= 0:
		_last_beat = b
		beat.emit(b)


func _rebuild_stream() -> void:
	var frames := int(round(bar_length() * MIX_RATE))
	var data := PackedByteArray()
	data.resize(frames * 2)
	var beat_frames := int(round(beat_length() * MIX_RATE))
	for i in frames:
		var in_beat := i % beat_frames
		var t := float(in_beat) / MIX_RATE
		var accent := (i / beat_frames) == 0
		data.encode_s16(i * 2, int(_kick(t, accent) * 32767.0))
	var click := make_loop(data)
	_sync = AudioStreamSynchronized.new()
	_sync.stream_count = 1 + _stems.size()
	_sync.set_sync_stream(0, click)
	_sync.set_sync_stream_volume(0, -80.0 if _click_muted else 0.0)
	for i in _stems.size():
		_sync.set_sync_stream(i + 1, _stems[i])
		_sync.set_sync_stream_volume(i + 1, _stem_db[i])
	_player.stream = _sync


## Wraps 16-bit mono samples as a forward-looping WAV stream.
static func make_loop(data: PackedByteArray) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = data.size() / 2
	return stream


## Synth kick: a pitch-swept sine with a short click, louder on the downbeat.
func _kick(t: float, accent: bool) -> float:
	if t > 0.25:
		return 0.0
	var freq := 50.0 + 110.0 * exp(-t * 30.0)
	var body := sin(TAU * freq * t) * exp(-t * 14.0)
	var click := sin(TAU * (2000.0 if accent else 1400.0) * t) * exp(-t * 300.0)
	return clampf((body * 0.8 + click * 0.35) * (1.0 if accent else 0.7), -1.0, 1.0)
