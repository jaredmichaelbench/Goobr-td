extends "res://scripts/m2_maze.gd"
## M3: the maze plays the song. Answers P-04: can you hear your maze, and do
## you rebuild it to get more out of the moments you play?
##
## Towers auto-fire on their instrument's beat pattern, and each instrument's
## stem only plays while one of its towers has a target. You don't play every
## note. The song runs in 4-bar phrases:
##   bars 1-2  groove: the maze plays itself
##   bar 3     call: a chime plays a short rhythm, one note per tower to cue
##   bar 4     answer: that rhythm comes back on your towers. A ring closes on
##             each cued tower; press the key shown above it as the ring lands.
## The call tells you the rhythm by ear, and the rings confirm it by eye.
## Perfect = crit. Missing costs nothing. Towers in crossfire hit harder.
##
## Build keys are 1-4 so Q/W/E are free for playing (D-0012).
## F5 = one-key mode (P-04 arm B): any of Q/W/E/Space answers any cue.

const STEPS_PER_BAR := 8
const PHRASE_BARS := 4
const CALL_BAR := 2
const ANSWER_BAR := 3
const RING_LEAD_STEPS := 4  # Rings appear two beats before their note.
const PATTERNS := {
	"kick": StemSynth.KICK_STEPS,
	"hat": StemSynth.HAT_STEPS,
	"bass": StemSynth.BASS_STEPS,
}
const INSTRUMENT_KEYS := {"kick": KEY_Q, "hat": KEY_W, "bass": KEY_E}
const CHIME_FREQ := {"kick": 523.25, "hat": 1046.5, "bass": 659.25}
## Answer rhythms, in 8th-note steps within the bar. Each is held for two
## phrases so it can be learned, then the next one is drawn.
const MOTIFS: Array = [[0, 4], [0, 2, 4], [0, 3, 6], [2, 4, 6], [0, 1, 4], [0, 3, 4], [4, 6]]
const MOTIF_REPEATS := 2
const RESONANCE_GOOD := 1.0  # Bonus = tower damage x this x crossfire factor.
const RESONANCE_PERFECT := 2.0
const CROSSFIRE_BONUS := 0.5  # Per extra tower that also covers the target.
const RESONANCE_RADIUS := 1.0
const LEAD_HOLD_BARS := 2.0

const IDLE_DB := {"kick": -16.0, "hat": -80.0, "bass": -80.0, "lead": -80.0}
const ACTIVE_DB := {"kick": 0.0, "hat": -4.0, "bass": 0.0, "lead": -1.0}

var clock: BeatClock
var calibration_ms := 0.0
var one_key_mode := false

var stem_index := {}  # instrument -> BeatClock stem index
var stem_db := {}  # instrument -> current dB
var _chimes := {}  # instrument -> AudioStreamPlayer
var _time_offset := 0.0  # Extra time from the speed-up test tool.
var _last_step := -1
var _lead_timer := 0.0
var _flashes := {}  # tower cell -> seconds left

var _phrase := -1
var _motif: Array = []
var _motif_left := 0
var _plan: Array[Dictionary] = []  # This phrase's cues: step, tower, instrument
var cues: Array[Dictionary] = []  # Live rings: time, shown_at, tower, instrument
var stats := {"cues": 0, "hits": 0, "perfects": 0, "wrong_key": 0}
var _wave_cues := 0
var _feedback := ""
var _feedback_color := Color.WHITE
var _feedback_time := 0.0
var _bursts: Array[Dictionary] = []
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	title = "M3 The maze plays the song"
	build_keys = {KEY_1: "wall", KEY_2: "kick", KEY_3: "hat", KEY_4: "bass"}
	builds["bass"]["damage"] = 4.5  # Bass fires twice as often on the off-beats.
	calibration_ms = Timing.load_calibration_ms()
	_rng.randomize()
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
	for k in CHIME_FREQ:
		var p := AudioStreamPlayer.new()
		p.stream = StemSynth.chime(CHIME_FREQ[k])
		p.volume_db = -4.0
		add_child(p)
		_chimes[k] = p
	clock.start()


func reset() -> void:
	super.reset()
	cues.clear()
	_plan.clear()
	stats = {"cues": 0, "hits": 0, "perfects": 0, "wrong_key": 0}
	_wave_cues = 0


func start_wave() -> void:
	var was_active := wave_active
	super.start_wave()
	if wave_active and not was_active:
		_wave_cues = 0


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
		cues.clear()
		_plan.clear()
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

	# Let rings that have passed go. No penalty.
	var live: Array[Dictionary] = []
	for c in cues:
		if press_time() <= c["time"] + Timing.GOOD_MS / 1000.0:
			live.append(c)
	cues = live

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
	var bar := floori(float(s) / STEPS_PER_BAR)
	var pattern_step := posmod(s, STEPS_PER_BAR)
	var phrase := floori(float(bar) / PHRASE_BARS)
	var bar_in_phrase := posmod(bar, PHRASE_BARS)

	if phrase != _phrase:
		_phrase = phrase
		_plan.clear()
	if bar_in_phrase == CALL_BAR and pattern_step == 0 and SPEEDS[speed_index] == 1:
		_plan_answer()
	# Call: the chime plays the rhythm one bar ahead of the answer.
	if bar_in_phrase == CALL_BAR:
		for p in _plan:
			if p["step"] == pattern_step:
				_chimes[p["instrument"]].play()
	# Rings appear RING_LEAD_STEPS before each answer note.
	var answer_start := (phrase * PHRASE_BARS + ANSWER_BAR) * STEPS_PER_BAR
	for p in _plan:
		var hit_step: int = answer_start + p["step"]
		if s == hit_step - RING_LEAD_STEPS and structures.has(p["tower"]):
			cues.append({
				"time": hit_step * step_length(),
				"shown_at": s * step_length(),
				"tower": p["tower"],
				"instrument": p["instrument"],
			})
			stats["cues"] += 1
			_wave_cues += 1

	_fire_towers_on(pattern_step)


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


## Picks this phrase's answer: a rhythm, and a tower in the fight for each
## note. Towers whose target is covered by the most other towers come first,
## so a maze with real crossfire gets the best cues.
func _plan_answer() -> void:
	_plan.clear()
	if not wave_active:
		return
	if _motif_left <= 0:
		_motif = MOTIFS[_rng.randi() % MOTIFS.size()]
		_motif_left = MOTIF_REPEATS
	_motif_left -= 1

	var candidates: Array = []
	for cell in structures:
		var type: String = structures[cell]["type"]
		if not PATTERNS.has(type):
			continue
		var target := _pick_target(Vector2(cell), builds[type]["range"])
		if not target.is_empty():
			candidates.append({"cell": cell, "type": type, "cover": _coverage(target["pos"])})
	if candidates.is_empty():
		return
	candidates.sort_custom(func(a, b): return a["cover"] > b["cover"])
	for i in _motif.size():
		var c: Dictionary = candidates[i % candidates.size()]
		_plan.append({"step": _motif[i], "tower": c["cell"], "instrument": c["type"]})


## How many towers have this spot in range.
func _coverage(pos: Vector2) -> int:
	var n := 0
	for cell in structures:
		var type: String = structures[cell]["type"]
		if PATTERNS.has(type) and pos.distance_to(Vector2(cell)) <= builds[type]["range"]:
			n += 1
	return n


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


## Answers the closest ring in time that this key can play.
func _play(key: Key) -> void:
	var best := -1
	var best_off := INF
	for i in cues.size():
		if not one_key_mode and key != INSTRUMENT_KEYS[cues[i]["instrument"]]:
			continue
		var off: float = absf(press_time() - cues[i]["time"])
		if off < best_off:
			best = i
			best_off = off
	if best < 0:
		if not cues.is_empty():
			stats["wrong_key"] += 1
			_show_feedback("Wrong key", Color(1, 0.5, 0.4))
		return
	var offset_ms: float = (press_time() - cues[best]["time"]) * 1000.0
	var g := Timing.grade(offset_ms)
	if g == "Miss":
		return  # Too early: the ring is still yours to hit.
	_resonance(cues[best], g, offset_ms)
	cues.remove_at(best)


func _resonance(cue: Dictionary, g: String, offset_ms: float) -> void:
	var cell: Vector2i = cue["tower"]
	if not structures.has(cell):
		return
	var spec: Dictionary = builds[structures[cell]["type"]]
	var target := _pick_target(Vector2(cell), spec["range"])
	var color: Color = spec["color"]
	stats["hits"] += 1
	if g == "Perfect":
		stats["perfects"] += 1
	_lead_timer = clock.bar_length() * LEAD_HOLD_BARS
	_flashes[cell] = 0.25
	_show_feedback(("CRIT  " if g == "Perfect" else "") + "%s  %+.0f ms" % [g, offset_ms], color)
	if target.is_empty():
		return
	var crossfire := 1.0 + CROSSFIRE_BONUS * maxi(0, _coverage(target["pos"]) - 1)
	var bonus: float = spec["damage"] * crossfire * (RESONANCE_PERFECT if g == "Perfect" else RESONANCE_GOOD)
	for c in creeps:
		if c["pos"].distance_to(target["pos"]) <= RESONANCE_RADIUS:
			c["hp"] -= bonus
	shots.append({"from": Vector2(cell), "to": target["pos"], "color": color, "ttl": 0.25, "splash": RESONANCE_RADIUS})
	_bursts.append({"pos": target["pos"], "color": color, "ttl": 0.35, "crit": g == "Perfect"})


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

	# Every tower shows its key. Cued towers get a ring closing on the note.
	var cued := {}
	for c in cues:
		cued[c["tower"]] = c
	for cell in structures:
		var type: String = structures[cell]["type"]
		if not INSTRUMENT_KEYS.has(type):
			continue
		var p := _to_screen(Vector2(cell))
		var color: Color = builds[type]["color"]
		if _flashes.has(cell):
			var a: float = clampf(_flashes[cell] / 0.12, 0.0, 1.0)
			draw_circle(p, TILE * (0.32 + 0.15 * a), color * Color(1, 1, 1, 0.5 * a))
		var key := OS.get_keycode_string(INSTRUMENT_KEYS[type])
		if cued.has(cell):
			var c: Dictionary = cued[cell]
			var span: float = maxf(0.001, c["time"] - c["shown_at"])
			var left := clampf((c["time"] - beat_time()) / span, 0.0, 1.0)
			draw_arc(p, TILE * (0.5 + 2.0 * left), 0, TAU, 48, color * Color(1, 1, 1, 0.4 + 0.6 * (1.0 - left)), 3.0)
			draw_arc(p, TILE * 0.5, 0, TAU, 48, color, 2.0)
			draw_string(font, p + Vector2(-20, 5), key, HORIZONTAL_ALIGNMENT_CENTER, 40, 14, Color.WHITE)
		else:
			# Key sits right on the tower, small and dark on its colour.
			draw_string(font, p + Vector2(-20, 4), key, HORIZONTAL_ALIGNMENT_CENTER, 40, 11, Color(0, 0, 0, 0.7))

	for b in _bursts:
		var a: float = b["ttl"] / 0.35
		draw_arc(_to_screen(b["pos"]), TILE * (RESONANCE_RADIUS + 0.6 * (1.0 - a)), 0, TAU, 48, b["color"] * Color(1, 1, 1, a), 6.0 if b["crit"] else 3.0)

	var board_w := GRID_SIZE.x * TILE
	if _feedback_time > 0.0:
		draw_string(font, _origin + Vector2(board_w * 0.5 - 150, -20), _feedback, HORIZONTAL_ALIGNMENT_CENTER, 300, 20, _feedback_color)

	# Phrase position: groove, groove, call, answer.
	var bar_pos := fposmod(beat_time() / clock.bar_length(), PHRASE_BARS)
	var seg_w := board_w / PHRASE_BARS
	for i in PHRASE_BARS:
		var r := Rect2(_origin + Vector2(i * seg_w + 2, GRID_SIZE.y * TILE + 8), Vector2(seg_w - 4, 4))
		var col := Color(1, 1, 1, 0.08)
		if i == CALL_BAR:
			col = Color(1.0, 0.85, 0.3, 0.25)
		elif i == ANSWER_BAR:
			col = Color(1.0, 0.85, 0.3, 0.45)
		draw_rect(r, col)
		if int(bar_pos) == i:
			draw_rect(Rect2(r.position, Vector2(r.size.x * fmod(bar_pos, 1.0), r.size.y)), Color(1, 1, 1, 0.5))

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
	var rate: float = 0.0 if stats["cues"] == 0 else 100.0 * stats["hits"] / stats["cues"]
	lines.append("")
	lines.append("Cues this wave %d   total %d" % [_wave_cues, stats["cues"]])
	lines.append("Hits %d (%.0f%%)   Crits %d" % [stats["hits"], rate, stats["perfects"]])
	lines.append("Calibration %+.0f ms (set in M1)%s" % [calibration_ms, "   ONE-KEY MODE" if one_key_mode else ""])
	return lines


func help_lines() -> Array[String]:
	var lines := super.help_lines()
	lines.insert(4, "Q / W / E  answer a ringed tower (key shown above it)")
	lines.insert(5, "F5  one-key mode (any key answers any ring)")
	return lines
