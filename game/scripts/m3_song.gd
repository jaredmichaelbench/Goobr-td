extends "res://scripts/m2_maze.gd"
## M3: the maze plays the song. Answers P-04: can you hear your maze, and do
## you rebuild it to get more accents?
##
## Towers fire on their instrument's beat pattern (8th-note steps), and each
## instrument's stem only plays while one of its towers has a target. When 2+
## towers will hit the same creep on the same step, an accent ring closes on
## that creep. Press the instrument's key (Q kick, W hat, E bass) on the hit
## for a Resonance burst. Perfect timing crits. Missing costs nothing.
##
## Build keys move to 1-4 so Q/W/E are free for playing (D-0012).
## F5 = one-key mode (P-04 arm B): any of Q/W/E/Space plays every accent.

const STEPS_PER_BAR := 8
const PATTERNS := {
	"kick": StemSynth.KICK_STEPS,
	"hat": StemSynth.HAT_STEPS,
	"bass": StemSynth.BASS_STEPS,
}
const INSTRUMENT_KEYS := {"kick": KEY_Q, "hat": KEY_W, "bass": KEY_E}
const ACCENT_PRIORITY: Array[String] = ["kick", "bass", "hat"]
const ACCENT_LEAD_STEPS := 2  # Accents are announced one beat ahead.
const RESONANCE_GOOD := 0.5  # Bonus as a share of the crossfire's normal damage.
const RESONANCE_PERFECT := 1.0
const RESONANCE_RADIUS := 1.0
const LEAD_HOLD_BARS := 2.0

const IDLE_DB := {"kick": -16.0, "hat": -80.0, "bass": -80.0, "lead": -80.0}
const ACTIVE_DB := {"kick": 0.0, "hat": -2.0, "bass": 0.0, "lead": -1.0}

var clock: BeatClock
var calibration_ms := 0.0
var one_key_mode := false

var stem_index := {}  # instrument -> BeatClock stem index
var stem_db := {}  # instrument -> current dB
var _time_offset := 0.0  # Extra time from the speed-up test tool.
var _last_step := -1
var _lead_timer := 0.0
var _flashes := {}  # tower cell -> seconds left

var accent := {}  # step, time, creep, towers, instrument, announced_at
var stats := {"accents": 0, "hits": 0, "perfects": 0, "wrong_key": 0}
var _wave_accents := 0
var _feedback := ""
var _feedback_color := Color.WHITE
var _feedback_time := 0.0
var _bursts: Array[Dictionary] = []


func _ready() -> void:
	title = "M3 The maze plays the song"
	build_keys = {KEY_1: "wall", KEY_2: "kick", KEY_3: "hat", KEY_4: "bass"}
	builds["bass"]["damage"] = 4.5  # Bass fires twice as often on the off-beats.
	calibration_ms = Timing.load_calibration_ms()
	super._ready()

	clock = BeatClock.new()
	add_child(clock)
	clock.set_muted(true)
	var bar := clock.bar_length()
	stem_index["kick"] = clock.add_stem(StemSynth.kick(bar), IDLE_DB["kick"])
	stem_index["hat"] = clock.add_stem(StemSynth.hat(bar), IDLE_DB["hat"])
	stem_index["bass"] = clock.add_stem(StemSynth.bass(bar), IDLE_DB["bass"])
	stem_index["lead"] = clock.add_stem(StemSynth.lead(bar), IDLE_DB["lead"])
	for k in IDLE_DB:
		stem_db[k] = IDLE_DB[k]
	clock.start()


func reset() -> void:
	super.reset()
	accent = {}
	stats = {"accents": 0, "hits": 0, "perfects": 0, "wrong_key": 0}
	_wave_accents = 0


func start_wave() -> void:
	var was_active := wave_active
	super.start_wave()
	if wave_active and not was_active:
		_wave_accents = 0


# --- Time ----------------------------------------------------------------------

func step_length() -> float:
	return clock.bar_length() / STEPS_PER_BAR


## Song time plus whatever the speed-up tool has added. At 1x this is the
## audio clock exactly.
func beat_time() -> float:
	return clock.song_time() + _time_offset


func _process(delta: float) -> void:
	_esc_time = maxf(0.0, _esc_time - delta)
	var speed := SPEEDS[speed_index]
	if speed > 1:
		_time_offset += delta * (speed - 1)
		accent = {}
	for i in speed:
		step(delta)
	if auto_send and state == "playing" and not wave_active:
		_auto_timer -= delta
		if _auto_timer <= 0.0:
			_auto_timer = AUTO_SEND_DELAY
			start_wave()

	var now_step := int(floor(beat_time() / step_length()))
	if _last_step < 0:
		_last_step = now_step
	# Catch up on every step since last frame, capped so a hitch can't flood.
	for s in range(maxi(_last_step + 1, now_step - 32), now_step + 1):
		fire_step(s)
	_last_step = maxi(_last_step, now_step)

	if not accent.is_empty() and beat_time() - calibration_ms / 1000.0 > accent["time"] + Timing.GOOD_MS / 1000.0:
		accent = {}  # Let it pass. No penalty.

	_update_stems(delta, speed)
	_tick_effects(delta)
	queue_redraw()


# --- Firing on the beat --------------------------------------------------------

## Cooldown firing from M2 is replaced by fire_step().
func _fire_towers(_delta: float) -> void:
	pass


func fire_step(s: int) -> void:
	if state != "playing":
		return
	var pattern_step := posmod(s, STEPS_PER_BAR)
	for cell in structures:
		var type: String = structures[cell]["type"]
		if not PATTERNS.has(type) or not PATTERNS[type].has(pattern_step):
			continue
		var spec: Dictionary = builds[type]
		var target := _pick_target(Vector2(cell), spec["range"])
		if target.is_empty():
			continue
		_hit(target, spec)
		_flashes[cell] = 0.12
		shots.append({"from": Vector2(cell), "to": target["pos"], "color": spec["color"], "ttl": 0.12, "splash": spec["splash"]})
	if accent.is_empty() and SPEEDS[speed_index] == 1:
		_predict_accent(s + ACCENT_LEAD_STEPS)


func _hit(target: Dictionary, spec: Dictionary) -> void:
	if spec["splash"] > 0.0:
		for c in creeps:
			if c["pos"].distance_to(target["pos"]) <= spec["splash"]:
				c["hp"] -= spec["damage"]
	else:
		target["hp"] -= spec["damage"]


## Looks ahead to step s: if 2+ towers that play on that step have the same
## creep in range, that creep gets an accent ring.
func _predict_accent(s: int) -> void:
	var pattern_step := posmod(s, STEPS_PER_BAR)
	var best := {}
	var best_towers: Array = []
	for c in creeps:
		if c["hp"] <= 0.0:
			continue
		var towers: Array = []
		for cell in structures:
			var type: String = structures[cell]["type"]
			if PATTERNS.has(type) and PATTERNS[type].has(pattern_step) \
					and c["pos"].distance_to(Vector2(cell)) <= builds[type]["range"]:
				towers.append(cell)
		if towers.size() >= 2 and towers.size() > best_towers.size():
			best = c
			best_towers = towers
	if best.is_empty():
		return
	var instrument := "hat"
	for p in ACCENT_PRIORITY:
		if best_towers.any(func(cell): return structures[cell]["type"] == p):
			instrument = p
			break
	accent = {
		"step": s,
		"time": s * step_length(),
		"creep": best,
		"towers": best_towers,
		"instrument": instrument,
		"announced_at": beat_time(),
	}
	stats["accents"] += 1
	_wave_accents += 1


# --- Playing -------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F5:
			one_key_mode = not one_key_mode
			return
		if event.keycode in [KEY_Q, KEY_W, KEY_E] or (one_key_mode and event.keycode == KEY_SPACE):
			_play(event.keycode)
			return
	super._unhandled_input(event)


func _play(key: Key) -> void:
	if accent.is_empty():
		return
	var press := beat_time() - calibration_ms / 1000.0
	var offset_ms: float = (press - accent["time"]) * 1000.0
	var g := Timing.grade(offset_ms)
	if g == "Miss":
		return  # Too early or too late: the ring is still yours to hit (or let go).
	if not one_key_mode and key != INSTRUMENT_KEYS[accent["instrument"]]:
		stats["wrong_key"] += 1
		_show_feedback("Wrong key", Color(1, 0.5, 0.4))
		return
	_resonance(g, offset_ms)


func _resonance(g: String, offset_ms: float) -> void:
	var total := 0.0
	for cell in accent["towers"]:
		if structures.has(cell):
			total += builds[structures[cell]["type"]]["damage"]
	var bonus := total * (RESONANCE_PERFECT if g == "Perfect" else RESONANCE_GOOD)
	var center: Vector2 = accent["creep"]["pos"]
	for c in creeps:
		if c["pos"].distance_to(center) <= RESONANCE_RADIUS:
			c["hp"] -= bonus
	stats["hits"] += 1
	if g == "Perfect":
		stats["perfects"] += 1
	_lead_timer = clock.bar_length() * LEAD_HOLD_BARS
	var color: Color = builds[accent["instrument"]]["color"]
	_bursts.append({"pos": center, "color": color, "ttl": 0.35, "crit": g == "Perfect"})
	_show_feedback(("CRIT  " if g == "Perfect" else "") + "%s  %+.0f ms" % [g, offset_ms], color)
	accent = {}


func _show_feedback(text: String, color: Color) -> void:
	_feedback = text
	_feedback_color = color
	_feedback_time = 0.8


# --- Music ---------------------------------------------------------------------

func _update_stems(delta: float, speed: int) -> void:
	var active := {"kick": false, "hat": false, "bass": false, "lead": _lead_timer > 0.0}
	for cell in structures:
		var type: String = structures[cell]["type"]
		if active.has(type) and not active[type] and not _pick_target(Vector2(cell), builds[type]["range"]).is_empty():
			active[type] = true
	for k in stem_db:
		var target_db: float = ACTIVE_DB[k] if active[k] else IDLE_DB[k]
		if speed > 1:
			target_db = -80.0
		var cur: float = stem_db[k]
		# Fast attack so instruments land on the beat, slower release.
		var rate := 240.0 if target_db > cur else 60.0
		cur = move_toward(cur, target_db, rate * delta)
		if cur != stem_db[k]:
			stem_db[k] = cur
			clock.set_stem_volume_db(stem_index[k], cur)


func _tick_effects(delta: float) -> void:
	_lead_timer = maxf(0.0, _lead_timer - delta)
	_feedback_time = maxf(0.0, _feedback_time - delta)
	for cell in _flashes.keys():
		_flashes[cell] -= delta
		if _flashes[cell] <= 0.0:
			_flashes.erase(cell)
	var live: Array[Dictionary] = []
	for b in _bursts:
		b["ttl"] -= delta
		if b["ttl"] > 0.0:
			live.append(b)
	_bursts = live


# --- Drawing -------------------------------------------------------------------

func _draw() -> void:
	super._draw()
	var font := ThemeDB.fallback_font

	# Towers pop when they fire.
	for cell in _flashes:
		if structures.has(cell):
			var a: float = _flashes[cell] / 0.12
			draw_circle(_to_screen(Vector2(cell)), TILE * (0.32 + 0.15 * a), builds[structures[cell]["type"]]["color"] * Color(1, 1, 1, 0.5 * a))

	# Beat pulse along the top of the board.
	var phase := fposmod(beat_time(), clock.beat_length()) / clock.beat_length()
	var board_w := GRID_SIZE.x * TILE
	draw_rect(Rect2(_origin + Vector2(0, -8), Vector2(board_w, 4)), Color(1, 1, 1, 0.08))
	draw_rect(Rect2(_origin + Vector2(0, -8), Vector2(board_w * (1.0 - phase), 4)), Color(1, 1, 1, 0.25 * (1.0 - phase)))

	# Accent ring closing on its creep.
	if not accent.is_empty():
		var creep: Dictionary = accent["creep"]
		var p := _to_screen(creep["pos"])
		var span: float = maxf(0.001, accent["time"] - accent["announced_at"])
		var left := clampf((accent["time"] - beat_time()) / span, 0.0, 1.0)
		var color: Color = builds[accent["instrument"]]["color"]
		draw_arc(p, TILE * (0.45 + 1.6 * left), 0, TAU, 40, color, 3.0)
		draw_arc(p, TILE * 0.45, 0, TAU, 40, color * Color(1, 1, 1, 0.5), 2.0)
		var label := "any" if one_key_mode else OS.get_keycode_string(INSTRUMENT_KEYS[accent["instrument"]])
		draw_string(font, p + Vector2(-20, -TILE * 0.9), "%s x%d" % [label, accent["towers"].size()], HORIZONTAL_ALIGNMENT_CENTER, 40, 16, color)

	for b in _bursts:
		var a: float = b["ttl"] / 0.35
		draw_arc(_to_screen(b["pos"]), TILE * (RESONANCE_RADIUS + 0.6 * (1.0 - a)), 0, TAU, 48, b["color"] * Color(1, 1, 1, a), 6.0 if b["crit"] else 3.0)

	if _feedback_time > 0.0:
		draw_string(font, _origin + Vector2(board_w * 0.5 - 150, -20), _feedback, HORIZONTAL_ALIGNMENT_CENTER, 300, 20, _feedback_color)

	# Stem meters, so you can see what you're hearing.
	var x := _origin.x + board_w + 20
	var names := {"kick": "Kick", "hat": "Hat", "bass": "Bass", "lead": "Lead"}
	var i := 0
	for k in ["kick", "hat", "bass", "lead"]:
		var level := clampf((stem_db[k] + 40.0) / 40.0, 0.0, 1.0)
		var color: Color = builds[k]["color"] if builds.has(k) else Color(1.0, 0.85, 0.3)
		var y := _origin.y + 20 + i * 40
		draw_string(font, Vector2(x, y), names[k], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 0.7))
		draw_rect(Rect2(x, y + 6, 60, 8), Color(1, 1, 1, 0.08))
		draw_rect(Rect2(x, y + 6, 60 * level, 8), color)
		i += 1


func status_lines() -> Array[String]:
	var lines := super.status_lines()
	var rate: float = 0.0 if stats["accents"] == 0 else 100.0 * stats["hits"] / stats["accents"]
	lines.append("")
	lines.append("Accents this wave %d   total %d" % [_wave_accents, stats["accents"]])
	lines.append("Resonance %d (%.0f%%)   Crits %d" % [stats["hits"], rate, stats["perfects"]])
	lines.append("Calibration %+.0f ms (set in M1)%s" % [calibration_ms, "   ONE-KEY MODE" if one_key_mode else ""])
	return lines


func help_lines() -> Array[String]:
	var lines := super.help_lines()
	lines.insert(4, "Q / W / E  play kick / hat / bass accents")
	lines.insert(5, "F5  one-key mode (any key plays any accent)")
	return lines
