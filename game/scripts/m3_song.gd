extends "res://scripts/m2_maze.gd"
## M3: the maze plays the song. Answers P-04: can you hear your maze, and do
## you build it so your towers are in the fight when the song calls for them?
##
## The song decides the notes (D-0014). During a wave a fixed chart of Q and E
## notes scrolls along the timeline under the board, so you always see what's
## coming. Pressing a note's key as it reaches the line fires a Resonance from
## every tower on that key that has a target. A tower with nothing in range
## adds nothing, so the maze decides what each note is worth.
## Perfect = crit. Missing costs nothing. The chart starts sparse and builds
## up wave by wave so early waves teach the rhythm.
##
## Towers: 2 = Q tower (on the beat), 3 = E tower (off-beat). 1 = wall.
## F5 = one-key mode (P-04 arm B): any of Q/E/Space plays any note.

const STEPS_PER_BAR := 8
const PHRASE_BARS := 4
const SCHEDULE_AHEAD_BARS := 2
const RING_LEAD_STEPS := 4  # Tower rings start two beats before a note.
const PATTERNS := {
	"kick": StemSynth.KICK_STEPS,
	"bass": StemSynth.BASS_STEPS,
}
const KEYS := {"kick": KEY_Q, "bass": KEY_E}
const KEY_TYPE := {KEY_Q: "kick", KEY_E: "bass"}
## Charts are [bar in phrase, 8th-note step, tower type]. Q notes sit on the
## kick's beats, E notes on the bass's off-beats, so each note lands on a shot
## its towers are already playing. Index = level; see chart_for_wave().
const CHARTS: Array = [
	[[0, 0, "kick"], [1, 0, "kick"], [2, 0, "kick"], [3, 0, "kick"]],
	[[0, 0, "kick"], [1, 0, "kick"], [1, 4, "kick"], [2, 0, "kick"], [3, 0, "kick"], [3, 4, "kick"]],
	[[0, 0, "kick"], [1, 0, "kick"], [1, 3, "bass"], [2, 0, "kick"], [3, 0, "kick"], [3, 3, "bass"], [3, 5, "bass"]],
	[[0, 0, "kick"], [0, 3, "bass"], [1, 0, "kick"], [1, 3, "bass"], [1, 7, "bass"], [2, 0, "kick"], [2, 4, "kick"], [3, 0, "kick"], [3, 3, "bass"], [3, 5, "bass"], [3, 7, "bass"]],
]
const RESONANCE_GOOD := 1.0  # Bonus per engaged tower = its damage x this x crossfire.
const RESONANCE_PERFECT := 2.0
const CROSSFIRE_BONUS := 0.25  # Per extra tower that also covers the target.
const RESONANCE_RADIUS := 1.0
const LEAD_HOLD_BARS := 2.0
const TIMELINE_AHEAD := 4.0  # Seconds of chart shown ahead of the line.
const TIMELINE_BEHIND := 0.6

const IDLE_DB := {"kick": -16.0, "hat": -80.0, "bass": -80.0, "lead": -80.0}
const ACTIVE_DB := {"kick": 0.0, "hat": -8.0, "bass": 0.0, "lead": -1.0}

var clock: BeatClock
var calibration_ms := 0.0
var one_key_mode := false

var stem_index := {}  # stem name -> BeatClock stem index
var stem_db := {}  # stem name -> current dB
var _time_offset := 0.0  # Extra time from the speed-up test tool.
var _last_step := -1
var _lead_timer := 0.0
var _flashes := {}  # tower cell -> seconds left

var notes: Array[Dictionary] = []  # time, type, state ("open", "hit", "missed")
var stats := {"notes": 0, "hits": 0, "perfects": 0, "wasted": 0}
var _wave_notes := 0
var _feedback := ""
var _feedback_color := Color.WHITE
var _feedback_time := 0.0
var _bursts: Array[Dictionary] = []


func _ready() -> void:
	title = "M3 The maze plays the song"
	build_keys = {KEY_1: "wall", KEY_2: "kick", KEY_3: "bass"}
	builds.erase("hat")  # Hats are background music now, not a tower (D-0014).
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
	notes.clear()
	stats = {"notes": 0, "hits": 0, "perfects": 0, "wasted": 0}
	_wave_notes = 0


## Longer waves so each one carries several phrases of practice.
func start_wave() -> void:
	var was_active := wave_active
	super.start_wave()
	if wave_active and not was_active:
		_to_spawn = 14 + 3 * wave
		_wave_notes = 0


func chart_for_wave(w: int) -> Array:
	return CHARTS[clampi((w - 1) / 2, 0, CHARTS.size() - 1)]


# --- Time ----------------------------------------------------------------------

func step_length() -> float:
	return clock.bar_length() / STEPS_PER_BAR


## Song time plus whatever the speed-up tool has added. At 1x this is the
## audio clock exactly.
func beat_time() -> float:
	return clock.song_time() + _time_offset


## When the player meant to press, after calibration.
func press_time() -> float:
	return beat_time() - calibration_ms / 1000.0


func _process(delta: float) -> void:
	_esc_time = maxf(0.0, _esc_time - delta)
	var speed := SPEEDS[speed_index]
	if speed > 1:
		_time_offset += delta * (speed - 1)
		notes.clear()
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
		on_step(s)
	_last_step = maxi(_last_step, now_step)

	# Notes that slid past the line are missed. No penalty, they just fade.
	for n in notes:
		if n["state"] == "open" and press_time() > n["time"] + Timing.GOOD_MS / 1000.0:
			n["state"] = "missed"
	var keep: Array[Dictionary] = []
	for n in notes:
		if n["time"] > beat_time() - TIMELINE_BEHIND:
			keep.append(n)
	notes = keep

	_update_stems(delta, speed)
	_tick_effects(delta)
	queue_redraw()


# --- The beat ------------------------------------------------------------------

## Cooldown firing from M2 is replaced by on_step().
func _fire_towers(_delta: float) -> void:
	pass


func on_step(s: int) -> void:
	if state != "playing":
		return
	if posmod(s, STEPS_PER_BAR) == 0 and wave_active and SPEEDS[speed_index] == 1:
		_schedule_bar(floori(float(s) / STEPS_PER_BAR) + SCHEDULE_AHEAD_BARS)
	_fire_towers_on(posmod(s, STEPS_PER_BAR))


## Writes one bar of the chart onto the timeline, a couple of bars ahead.
func _schedule_bar(bar: int) -> void:
	var bar_in_phrase := posmod(bar, PHRASE_BARS)
	for entry in chart_for_wave(wave):
		if entry[0] != bar_in_phrase:
			continue
		var time: float = (bar * STEPS_PER_BAR + entry[1]) * step_length()
		notes.append({"time": time, "type": entry[2], "state": "open"})
		stats["notes"] += 1
		_wave_notes += 1


func _fire_towers_on(pattern_step: int) -> void:
	for cell in structures:
		var type: String = structures[cell]["type"]
		if not PATTERNS.has(type) or not PATTERNS[type].has(pattern_step):
			continue
		var spec: Dictionary = builds[type]
		var target := _pick_target(Vector2(cell), spec["range"])
		if target.is_empty():
			continue
		_hit(target, spec, spec["damage"])
		_flashes[cell] = 0.12
		shots.append({"from": Vector2(cell), "to": target["pos"], "color": spec["color"], "ttl": 0.12, "splash": spec["splash"]})


func _hit(target: Dictionary, spec: Dictionary, damage: float) -> void:
	if spec["splash"] > 0.0:
		for c in creeps:
			if c["pos"].distance_to(target["pos"]) <= spec["splash"]:
				c["hp"] -= damage
	else:
		target["hp"] -= damage


## How many towers have this spot in range.
func _coverage(pos: Vector2) -> int:
	var n := 0
	for cell in structures:
		var type: String = structures[cell]["type"]
		if PATTERNS.has(type) and pos.distance_to(Vector2(cell)) <= builds[type]["range"]:
			n += 1
	return n


## Towers of this type with something in range right now.
func engaged_towers(type: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell in structures:
		if structures[cell]["type"] == type and not _pick_target(Vector2(cell), builds[type]["range"]).is_empty():
			cells.append(cell)
	return cells


# --- Playing -------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F5:
			one_key_mode = not one_key_mode
			return
		if event.keycode in [KEY_Q, KEY_E] or (one_key_mode and event.keycode == KEY_SPACE):
			_play(event.keycode)
			return
	super._unhandled_input(event)


## Plays the open note closest in time that this key can play.
func _play(key: Key) -> void:
	var best := {}
	var best_off := INF
	for n in notes:
		if n["state"] != "open":
			continue
		if not one_key_mode and KEY_TYPE.get(key, "") != n["type"]:
			continue
		var off: float = absf(press_time() - n["time"])
		if off < best_off:
			best = n
			best_off = off
	if best.is_empty():
		return
	var offset_ms: float = (press_time() - best["time"]) * 1000.0
	var g := Timing.grade(offset_ms)
	if g == "Miss":
		return  # Too early: the note is still yours to hit.
	best["state"] = "hit"
	_resonance(best["type"], g, offset_ms)


func _resonance(type: String, g: String, offset_ms: float) -> void:
	var color: Color = builds[type]["color"]
	var towers := engaged_towers(type)
	stats["hits"] += 1
	if g == "Perfect":
		stats["perfects"] += 1
	_lead_timer = clock.bar_length() * LEAD_HOLD_BARS
	if towers.is_empty():
		stats["wasted"] += 1
		_show_feedback("%s, but no %s tower in the fight" % [g, OS.get_keycode_string(KEYS[type])], Color(1, 0.6, 0.4))
		return
	_show_feedback(("CRIT  " if g == "Perfect" else "") + "%s  %+.0f ms  x%d towers" % [g, offset_ms, towers.size()], color)
	var spec: Dictionary = builds[type]
	for cell in towers:
		var target := _pick_target(Vector2(cell), spec["range"])
		if target.is_empty():
			continue
		var crossfire := 1.0 + CROSSFIRE_BONUS * maxi(0, _coverage(target["pos"]) - 1)
		var bonus: float = spec["damage"] * crossfire * (RESONANCE_PERFECT if g == "Perfect" else RESONANCE_GOOD)
		for c in creeps:
			if c["pos"].distance_to(target["pos"]) <= RESONANCE_RADIUS:
				c["hp"] -= bonus
		_flashes[cell] = 0.25
		shots.append({"from": Vector2(cell), "to": target["pos"], "color": color, "ttl": 0.25, "splash": RESONANCE_RADIUS})
		_bursts.append({"pos": target["pos"], "color": color, "ttl": 0.35, "crit": g == "Perfect"})


func _show_feedback(text: String, color: Color) -> void:
	_feedback = text
	_feedback_color = color
	_feedback_time = 0.9


# --- Music ---------------------------------------------------------------------

func _update_stems(delta: float, speed: int) -> void:
	var active := {"kick": false, "hat": false, "bass": false, "lead": _lead_timer > 0.0}
	for cell in structures:
		var type: String = structures[cell]["type"]
		if active.has(type) and not active[type] and not _pick_target(Vector2(cell), builds[type]["range"]).is_empty():
			active[type] = true
	active["hat"] = active["kick"] or active["bass"]  # Background groove while fighting.
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
	var board_w := GRID_SIZE.x * TILE

	# The next note of each key puts a closing ring on that key's towers:
	# bright on towers in the fight, faint on towers that would add nothing.
	var next_note := {}
	for n in notes:
		if n["state"] == "open" and (not next_note.has(n["type"]) or n["time"] < next_note[n["type"]]["time"]):
			next_note[n["type"]] = n
	var lead := RING_LEAD_STEPS * step_length()
	for cell in structures:
		var type: String = structures[cell]["type"]
		if not KEYS.has(type):
			continue
		var p := _to_screen(Vector2(cell))
		var color: Color = builds[type]["color"]
		if _flashes.has(cell):
			var a: float = clampf(_flashes[cell] / 0.12, 0.0, 1.0)
			draw_circle(p, TILE * (0.32 + 0.15 * a), color * Color(1, 1, 1, 0.5 * a))
		var key := OS.get_keycode_string(KEYS[type])
		var ringed := false
		if next_note.has(type):
			var to_go: float = next_note[type]["time"] - beat_time()
			if to_go <= lead:
				ringed = true
				var left := clampf(to_go / lead, 0.0, 1.0)
				var engaged := not _pick_target(Vector2(cell), builds[type]["range"]).is_empty()
				var alpha := 1.0 if engaged else 0.25
				draw_arc(p, TILE * (0.5 + 2.0 * left), 0, TAU, 48, color * Color(1, 1, 1, alpha * (0.4 + 0.6 * (1.0 - left))), 3.0)
				draw_arc(p, TILE * 0.5, 0, TAU, 48, color * Color(1, 1, 1, alpha), 2.0)
		if ringed:
			draw_string(font, p + Vector2(-20, 5), key, HORIZONTAL_ALIGNMENT_CENTER, 40, 14, Color.WHITE)
		else:
			draw_string(font, p + Vector2(-20, 4), key, HORIZONTAL_ALIGNMENT_CENTER, 40, 11, Color(0, 0, 0, 0.7))

	for b in _bursts:
		var a: float = b["ttl"] / 0.35
		draw_arc(_to_screen(b["pos"]), TILE * (RESONANCE_RADIUS + 0.6 * (1.0 - a)), 0, TAU, 48, b["color"] * Color(1, 1, 1, a), 6.0 if b["crit"] else 3.0)

	if _feedback_time > 0.0:
		draw_string(font, _origin + Vector2(board_w * 0.5 - 200, -20), _feedback, HORIZONTAL_ALIGNMENT_CENTER, 400, 18, _feedback_color)

	_draw_timeline(font, board_w)
	_draw_meters(font, board_w)


## Boss-mod style strip under the board: notes scroll right to left into the
## line. Q notes on the top lane, E notes on the bottom lane.
func _draw_timeline(font: Font, board_w: float) -> void:
	var top := _origin.y + GRID_SIZE.y * TILE + 10
	var lane_h := 16.0
	var rect := Rect2(_origin.x, top, board_w, lane_h * 2 + 6)
	draw_rect(rect, Color(1, 1, 1, 0.05))
	var line_x := _origin.x + board_w * (TIMELINE_BEHIND / (TIMELINE_AHEAD + TIMELINE_BEHIND))
	var px_per_s := board_w / (TIMELINE_AHEAD + TIMELINE_BEHIND)
	var now := beat_time()

	# Beat ticks, with bar lines brighter.
	var beat := clock.beat_length()
	var first := ceili((now - TIMELINE_BEHIND) / beat)
	var last := floori((now + TIMELINE_AHEAD) / beat)
	for b in range(first, last + 1):
		var x := line_x + (b * beat - now) * px_per_s
		var is_bar := posmod(b, clock.beats_per_bar) == 0
		draw_line(Vector2(x, top), Vector2(x, top + rect.size.y), Color(1, 1, 1, 0.18 if is_bar else 0.07), 1.0)

	draw_string(font, Vector2(_origin.x - 18, top + 13), "Q", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, builds["kick"]["color"])
	draw_string(font, Vector2(_origin.x - 18, top + lane_h + 17), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, builds["bass"]["color"])
	for n in notes:
		var x: float = line_x + (n["time"] - now) * px_per_s
		if x < rect.position.x or x > rect.end.x:
			continue
		var lane := 0 if n["type"] == "kick" else 1
		var center := Vector2(x, top + 3 + lane * lane_h + lane_h * 0.5)
		var color: Color = builds[n["type"]]["color"]
		if n["state"] == "hit":
			color = Color(1, 1, 1, 0.9)
		elif n["state"] == "missed":
			color = color * Color(1, 1, 1, 0.25)
		var r := 6.0
		draw_colored_polygon(PackedVector2Array([center + Vector2(0, -r), center + Vector2(r, 0), center + Vector2(0, r), center + Vector2(-r, 0)]), color)
	draw_line(Vector2(line_x, top - 3), Vector2(line_x, top + rect.size.y + 3), Color(1, 1, 1, 0.8), 2.0)


## Stem meters, so you can see what you're hearing.
func _draw_meters(font: Font, board_w: float) -> void:
	var x := _origin.x + board_w + 20
	var names := {"kick": "Q tower", "bass": "E tower", "hat": "Groove", "lead": "Melody"}
	var i := 0
	for k in ["kick", "bass", "hat", "lead"]:
		var level := clampf((stem_db[k] + 40.0) / 40.0, 0.0, 1.0)
		var color: Color = builds[k]["color"] if builds.has(k) else Color(1.0, 0.85, 0.3)
		var y := _origin.y + 20 + i * 40
		draw_string(font, Vector2(x, y), names[k], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 0.7))
		draw_rect(Rect2(x, y + 6, 60, 8), Color(1, 1, 1, 0.08))
		draw_rect(Rect2(x, y + 6, 60 * level, 8), color)
		i += 1


func status_lines() -> Array[String]:
	var lines := super.status_lines()
	var rate: float = 0.0 if stats["notes"] == 0 else 100.0 * stats["hits"] / stats["notes"]
	lines.append("")
	lines.append("Notes this wave %d   total %d" % [_wave_notes, stats["notes"]])
	lines.append("Hits %d (%.0f%%)   Crits %d   No tower %d" % [stats["hits"], rate, stats["perfects"], stats["wasted"]])
	lines.append("Calibration %+.0f ms (set in M1)%s" % [calibration_ms, "   ONE-KEY MODE" if one_key_mode else ""])
	return lines


func help_lines() -> Array[String]:
	var keys := {}
	for k in build_keys:
		keys[build_keys[k]] = OS.get_keycode_string(k)
	return [
		"%s  Wall       4g" % keys["wall"],
		"%s  Q tower   20g  on the beat, heavy" % keys["kick"],
		"%s  E tower   25g  off-beat, splash" % keys["bass"],
		"Q / E  play notes as they reach the line",
		"F5  one-key mode (any key plays any note)",
		"Left click  place     Right click  sell (75%)",
		"Esc twice  menu",
		"",
		"TEST  F1 speed %dx   F2 auto-send %s" % [SPEEDS[speed_index], "ON" if auto_send else "off"],
		"TEST  F3 +100g   F4 skip a wave",
	]
