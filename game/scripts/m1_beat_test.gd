extends Node2D
## M1: beat and input feel. Tap Q/W/E/Space on the beat and read how far off
## you were. Answers P-01: is timing tight and consistent on Mac and PC?
##
## Keys: Q W E Space = tap   [ ] = calibration -/+ 5 ms   C = auto-calibrate
##       - = = BPM -/+ 5   M = mute click (visual only)   R = reset stats

const PERFECT_MS := 35.0
const GOOD_MS := 90.0
const HISTORY := 16
const SETTINGS_PATH := "user://settings.cfg"

const COLOR_PERFECT := Color(1.0, 0.85, 0.3)
const COLOR_GOOD := Color(0.4, 0.85, 1.0)
const COLOR_MISS := Color(1.0, 0.35, 0.35)
const COLOR_DIM := Color(1, 1, 1, 0.25)

var clock: BeatClock
var calibration_ms := 0.0
var muted := false

var _raw_offsets: Array[float] = []
var _counts := {"Perfect": 0, "Good": 0, "Miss": 0}
var _last_grade := ""
var _last_offset_ms := 0.0
var _last_key := ""
var _flash := 0.0
var _beat_pulse := 0.0


func _ready() -> void:
	Input.use_accumulated_input = false
	_load_settings()
	clock = BeatClock.new()
	add_child(clock)
	clock.beat.connect(_on_beat)
	clock.start()


func _on_beat(_index: int) -> void:
	_beat_pulse = 1.0


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_Q, KEY_W, KEY_E, KEY_SPACE:
			_tap(OS.get_keycode_string(event.keycode))
		KEY_BRACKETLEFT:
			_set_calibration(calibration_ms - 5.0)
		KEY_BRACKETRIGHT:
			_set_calibration(calibration_ms + 5.0)
		KEY_C:
			if not _raw_offsets.is_empty():
				_set_calibration(_mean(_raw_offsets))
		KEY_MINUS:
			clock.set_bpm(clock.bpm - 5.0)
			_reset_stats()
		KEY_EQUAL:
			clock.set_bpm(clock.bpm + 5.0)
			_reset_stats()
		KEY_M:
			muted = not muted
			clock.set_muted(muted)
		KEY_R:
			_reset_stats()


func _tap(key_name: String) -> void:
	var raw_ms := clock.offset_to_nearest_beat(clock.song_time()) * 1000.0
	_raw_offsets.append(raw_ms)
	if _raw_offsets.size() > HISTORY:
		_raw_offsets.pop_front()
	_last_offset_ms = raw_ms - calibration_ms
	_last_grade = grade(_last_offset_ms)
	_counts[_last_grade] += 1
	_last_key = key_name
	_flash = 1.0


static func grade(offset_ms: float) -> String:
	var a := absf(offset_ms)
	if a <= PERFECT_MS:
		return "Perfect"
	if a <= GOOD_MS:
		return "Good"
	return "Miss"


func _process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta * 3.0)
	_beat_pulse = maxf(0.0, _beat_pulse - delta * 5.0)
	queue_redraw()


func _draw() -> void:
	var size := get_viewport_rect().size
	var font := ThemeDB.fallback_font
	var t := clock.song_time() - calibration_ms / 1000.0
	var beat_len := clock.beat_length()

	# Moving bar across one bar of beats.
	var left := size.x * 0.15
	var width := size.x * 0.7
	var y := size.y * 0.3
	draw_line(Vector2(left, y), Vector2(left + width, y), COLOR_DIM, 2.0)
	for i in clock.beats_per_bar + 1:
		var x := left + width * i / clock.beats_per_bar
		draw_line(Vector2(x, y - 18), Vector2(x, y + 18), Color.WHITE if i % clock.beats_per_bar == 0 else COLOR_DIM, 3.0)
	var bar_phase := fposmod(t, clock.bar_length()) / clock.bar_length()
	var bx := left + width * bar_phase
	draw_line(Vector2(bx, y - 30), Vector2(bx, y + 30), COLOR_GOOD, 4.0)

	# Approach ring that closes onto the target circle on each beat.
	var center := Vector2(size.x * 0.5, size.y * 0.6)
	var to_next := 1.0 - fposmod(t, beat_len) / beat_len
	draw_arc(center, 60.0 + 140.0 * to_next, 0, TAU, 64, COLOR_DIM, 3.0)
	draw_circle(center, 60.0 + 10.0 * _beat_pulse, Color(1, 1, 1, 0.15 + 0.35 * _beat_pulse))
	if _flash > 0.0:
		draw_arc(center, 70.0, 0, TAU, 64, _grade_color(_last_grade) * Color(1, 1, 1, _flash), 8.0)
		draw_string(font, center + Vector2(-80, -90), "%s  %+.0f ms" % [_last_grade, _last_offset_ms],
			HORIZONTAL_ALIGNMENT_CENTER, 160, 28, _grade_color(_last_grade))

	# Stats and help.
	var lines := [
		"M1 Beat Test   %.0f BPM   calibration %+.0f ms%s" % [clock.bpm, calibration_ms, "   (click muted)" if muted else ""],
		"Last: %s %s %+.0f ms" % [_last_key, _last_grade, _last_offset_ms] if _last_grade != "" else "Tap Q / W / E / Space on the beat",
		"Last %d taps (raw): mean %+.1f ms   spread (std dev) %.1f ms" % [_raw_offsets.size(), _mean(_raw_offsets), _stddev(_raw_offsets)],
		"Perfect %d   Good %d   Miss %d" % [_counts["Perfect"], _counts["Good"], _counts["Miss"]],
		"",
		"[ ] calibration -/+5 ms    C auto-calibrate to mean    - = BPM    M mute click    R reset",
	]
	for i in lines.size():
		draw_string(font, Vector2(24, 36 + i * 26), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 18,
			Color.WHITE if i < 4 else COLOR_DIM)


func _grade_color(g: String) -> Color:
	match g:
		"Perfect":
			return COLOR_PERFECT
		"Good":
			return COLOR_GOOD
	return COLOR_MISS


func _set_calibration(ms: float) -> void:
	calibration_ms = clampf(round(ms), -250.0, 250.0)
	var cfg := ConfigFile.new()
	cfg.set_value("timing", "calibration_ms", calibration_ms)
	cfg.save(SETTINGS_PATH)


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		calibration_ms = cfg.get_value("timing", "calibration_ms", 0.0)


func _reset_stats() -> void:
	_raw_offsets.clear()
	_counts = {"Perfect": 0, "Good": 0, "Miss": 0}
	_last_grade = ""


static func _mean(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var s := 0.0
	for v in values:
		s += v
	return s / values.size()


static func _stddev(values: Array[float]) -> float:
	if values.size() < 2:
		return 0.0
	var m := _mean(values)
	var s := 0.0
	for v in values:
		s += (v - m) * (v - m)
	return sqrt(s / (values.size() - 1))
