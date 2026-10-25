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
## K = one-key mode (P-04 arm B): any of Q/E/Space plays any note.
## L = show or hide the timeline overlay.
##
## The map has rock (D-0015): two ridges split it into three fields joined by
## gaps, so creeps must pass chokepoints, and walls are limited.

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
## '#' = rock. Spawn is the left edge of row 10, the goal the right edge.
const MAP := [
	".....#..##....##....",
	"........##....##....",
	"..............##....",
	"..............##....",
	"........##....##..#.",
	"...##...##....##....",
	"...#....##....##....",
	"........##....##....",
	"........##..........",
	"........##.##.......",
	"........##.##.......",
	"........##..........",
	"........##..........",
	"....#...##....##....",
	"...##...##....##....",
	"........##....##..#.",
	"..............##....",
	"..............##....",
	"........##....##....",
	".....#..##....##....",
]
const START_GOLD_M3 := 100
const WALL_LIMIT := 20

const IDLE_DB := {"kick": -16.0, "hat": -80.0, "bass": -80.0, "lead": -80.0}
const ACTIVE_DB := {"kick": 0.0, "hat": -8.0, "bass": 0.0, "lead": -1.0}

var clock: BeatClock
var calibration_ms := 0.0
var one_key_mode := false
var show_timeline := true

var stem_index := {}  # stem name -> BeatClock stem index
var stem_db := {}  # stem name -> current dB
var _time_offset := 0.0  # Extra time from the speed-up test tool.
var _last_step := -1
var _lead_timer := 0.0
var _flashes := {}  # tower cell -> seconds left

var notes: Array[Dictionary] = []  # time, type, state ("open", "hit", "missed")
var stats := {}  # tower type -> {notes, hits, perfects, wasted, missed}
var _wave_notes := 0
var _feedback := ""
var _feedback_color := Color.WHITE
var _feedback_time := 0.0
var _bursts: Array[Dictionary] = []
var _popups: Array[Dictionary] = []  # Floating damage numbers: pos, text, color, size, ttl.
var _line_flash := {"color": Color.WHITE, "ttl": 0.0}
var _sfx := {}  # name -> AudioStreamPlayer


func _ready() -> void:
	title = "M3 The maze plays the song"
	build_keys = {KEY_1: "wall", KEY_2: "kick", KEY_3: "bass"}
	builds.erase("hat")  # Hats are background music now, not a tower (D-0014).
	builds["bass"]["damage"] = 4.5  # Bass fires twice as often on the off-beats.
	calibration_ms = Timing.load_calibration_ms()
	for y in MAP.size():
		for x in MAP[y].length():
			if MAP[y][x] == "#":
				terrain[Vector2i(x, y)] = true
	wall_limit = WALL_LIMIT
	creep_hp = 24.0
	creep_hp_growth = 1.3
	kill_gold = 1
	_reset_stats()
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
	for sfx in [["perfect", 1320.0, -4.0], ["good", 880.0, -8.0], ["miss", 140.0, -6.0]]:
		var player := AudioStreamPlayer.new()
		player.stream = StemSynth.chime(sfx[1])
		player.volume_db = sfx[2]
		add_child(player)
		_sfx[sfx[0]] = player
	clock.start()


func reset() -> void:
	super.reset()
	gold = START_GOLD_M3
	notes.clear()
	_reset_stats()
	_wave_notes = 0


func _reset_stats() -> void:
	stats = {}
	for type in KEYS:
		stats[type] = {"notes": 0, "hits": 0, "perfects": 0, "wasted": 0, "missed": 0}


func stat_total(field: String) -> int:
	var n := 0
	for type in stats:
		n += stats[type][field]
	return n


## Longer waves so each one carries several phrases of practice.
func start_wave() -> void:
	var was_active := wave_active
	super.start_wave()
	if wave_active and not was_active:
		_wave_notes = 0


func creeps_in_wave(w: int) -> int:
	return 14 + 3 * w


## Wave 1 = level 0, wave 2 = level 1, waves 3-4 = level 2 (E joins), wave 5+ = level 3.
func chart_for_wave(w: int) -> Array:
	return CHARTS[clampi(w - 1 if w <= 2 else (w + 1) / 2, 0, CHARTS.size() - 1)]


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
			_on_miss(n["type"])
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
		stats[entry[2]]["notes"] += 1
		_wave_notes += 1


func _fire_towers_on(pattern_step: int) -> void:
	for cell in structures:
		var type: String = structures[cell]["type"]
		if not PATTERNS.has(type) or not PATTERNS[type].has(pattern_step) or not tower_ready(cell):
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


## Can this tower act right now? M4 overrides this for suppressed towers.
func tower_ready(_cell: Vector2i) -> bool:
	return true


## A ready tower with something in range.
func tower_engaged(cell: Vector2i) -> bool:
	return tower_ready(cell) and not _pick_target(Vector2(cell), builds[structures[cell]["type"]]["range"]).is_empty()


## Towers of this type with something in range right now.
func engaged_towers(type: String) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for cell in structures:
		if structures[cell]["type"] == type and tower_engaged(cell):
			cells.append(cell)
	return cells


# --- Playing -------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_K:
			one_key_mode = not one_key_mode
			return
		if event.keycode == KEY_L:
			show_timeline = not show_timeline
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
		_show_feedback("No note", Color(1, 1, 1, 0.4))
		return
	var offset_ms: float = (press_time() - best["time"]) * 1000.0
	var g := Timing.grade(offset_ms)
	if g == "Miss":
		_show_feedback("Too early", Color(1, 1, 1, 0.5))
		return  # The note is still yours to hit.
	best["state"] = "hit"
	_resonance(best["type"], g, offset_ms)


func _resonance(type: String, g: String, offset_ms: float) -> void:
	var color: Color = builds[type]["color"]
	var crit := g == "Perfect"
	var towers := engaged_towers(type)
	stats[type]["hits"] += 1
	if crit:
		stats[type]["perfects"] += 1
	_lead_timer = clock.bar_length() * LEAD_HOLD_BARS
	_sfx["perfect" if crit else "good"].play()
	if towers.is_empty():
		stats[type]["wasted"] += 1
		_flash_line(Color(1, 0.6, 0.4))
		_show_feedback("%s, but no %s tower in the fight" % [g, OS.get_keycode_string(KEYS[type])], Color(1, 0.6, 0.4))
		return
	var spec: Dictionary = builds[type]
	var total := 0.0
	var shown := 0
	for cell in towers:
		var target := _pick_target(Vector2(cell), spec["range"])
		if target.is_empty():
			continue
		var crossfire := 1.0 + CROSSFIRE_BONUS * maxi(0, _coverage(target["pos"]) - 1)
		var bonus: float = spec["damage"] * crossfire * (RESONANCE_PERFECT if crit else RESONANCE_GOOD)
		var dealt := 0.0
		for c in creeps:
			if c["pos"].distance_to(target["pos"]) <= RESONANCE_RADIUS:
				dealt += minf(bonus, maxf(c["hp"], 0.0))
				c["hp"] -= bonus
		total += dealt
		_flashes[cell] = 0.25
		shots.append({"from": Vector2(cell), "to": target["pos"], "color": color, "ttl": 0.25, "splash": RESONANCE_RADIUS})
		_bursts.append({"pos": target["pos"], "color": color, "ttl": 0.35, "crit": crit})
		# Stagger numbers so several towers on one target stay readable.
		var spot: Vector2 = target["pos"] + Vector2(-0.7 if shown % 2 == 0 else 0.7, -0.4 * shown)
		_popup(spot, ("%d!" if crit else "%d") % roundi(dealt), Color(1.0, 0.9, 0.3) if crit else Color.WHITE, 22 if crit else 15)
		shown += 1
	_flash_line(Color(1.0, 0.9, 0.3) if crit else Color.WHITE)
	_show_feedback("%s%s  %+.0f ms   %d damage from %d tower%s" % ["CRIT  " if crit else "", g, offset_ms, roundi(total), towers.size(), "" if towers.size() == 1 else "s"], Color(1.0, 0.9, 0.3) if crit else color)


## A note slid past the line. Only counts as a miss if towers were ready to fire.
func _on_miss(type: String) -> void:
	var towers := engaged_towers(type)
	if towers.is_empty():
		return
	stats[type]["missed"] += 1
	_sfx["miss"].play()
	_flash_line(Color(1, 0.3, 0.3))
	_show_feedback("MISS", Color(1, 0.3, 0.3))
	for cell in towers:
		_popup(Vector2(cell), "miss", Color(1, 0.35, 0.35, 0.9), 13)


func _popup(pos: Vector2, text: String, color: Color, size: int) -> void:
	_popups.append({"pos": pos, "text": text, "color": color, "size": size, "ttl": 0.8})


func _flash_line(color: Color) -> void:
	_line_flash = {"color": color, "ttl": 0.3}


func _show_feedback(text: String, color: Color) -> void:
	_feedback = text
	_feedback_color = color
	_feedback_time = 0.9


# --- Music ---------------------------------------------------------------------

func _update_stems(delta: float, speed: int) -> void:
	var active := {"kick": false, "hat": false, "bass": false, "lead": _lead_timer > 0.0}
	for cell in structures:
		var type: String = structures[cell]["type"]
		if active.has(type) and not active[type] and tower_engaged(cell):
			active[type] = true
	active["hat"] = active["kick"] or active["bass"]  # Background groove while fighting.
	_adjust_mix(active)
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


## Hook for later milestones to change which stems play. M4 drops the groove
## while any tower is suppressed.
func _adjust_mix(_active: Dictionary) -> void:
	pass


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
	var popups: Array[Dictionary] = []
	for p in _popups:
		p["ttl"] -= delta
		if p["ttl"] > 0.0:
			popups.append(p)
	_popups = popups
	_line_flash["ttl"] = maxf(0.0, _line_flash["ttl"] - delta)


# --- Drawing -------------------------------------------------------------------

func _draw() -> void:
	super._draw()
	var font := ThemeDB.fallback_font
	var board_w := GRID_SIZE.x * TILE

	# The next note of each key puts a closing ring on that key's towers that
	# are in the fight. Towers with nothing in range only glow softly, so you
	# know the note is coming but your eye goes to the towers that matter.
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
				var left := clampf(to_go / lead, 0.0, 1.0)
				if tower_engaged(cell):
					ringed = true
					draw_arc(p, TILE * (0.5 + 2.0 * left), 0, TAU, 48, color * Color(1, 1, 1, 0.4 + 0.6 * (1.0 - left)), 3.0)
					draw_arc(p, TILE * 0.5, 0, TAU, 48, color, 2.0)
				else:
					draw_circle(p, TILE * 0.45, color * Color(1, 1, 1, 0.25 * (1.0 - left)))
		if ringed:
			draw_string(font, p + Vector2(-20, 5), key, HORIZONTAL_ALIGNMENT_CENTER, 40, 14, Color.WHITE)
		else:
			draw_string(font, p + Vector2(-20, 4), key, HORIZONTAL_ALIGNMENT_CENTER, 40, 11, Color(0, 0, 0, 0.7))

	for b in _bursts:
		var a: float = b["ttl"] / 0.35
		draw_arc(_to_screen(b["pos"]), TILE * (RESONANCE_RADIUS + 0.6 * (1.0 - a)), 0, TAU, 48, b["color"] * Color(1, 1, 1, a), 6.0 if b["crit"] else 3.0)

	for pop in _popups:
		var age: float = 1.0 - pop["ttl"] / 0.8
		var at := _to_screen(pop["pos"]) + Vector2(-40, -14 - 26 * age)
		var c: Color = pop["color"]
		c.a *= clampf(pop["ttl"] / 0.3, 0.0, 1.0)
		draw_string_outline(font, at, pop["text"], HORIZONTAL_ALIGNMENT_CENTER, 80, pop["size"], 4, Color(0, 0, 0, c.a * 0.8))
		draw_string(font, at, pop["text"], HORIZONTAL_ALIGNMENT_CENTER, 80, pop["size"], c)

	if _feedback_time > 0.0:
		draw_string(font, _origin + Vector2(board_w * 0.5 - 300, -20), _feedback, HORIZONTAL_ALIGNMENT_CENTER, 600, 18, _feedback_color)

	if show_timeline:
		_draw_timeline(font, board_w)
	_draw_meters(font, board_w)


## Boss-mod style strip, drawn faintly over the top of the board: notes
## scroll right to left into the line. Q notes on the top lane, E below.
func _draw_timeline(font: Font, board_w: float) -> void:
	var lane_h := 14.0
	var left := _origin.x + TILE * 1.5
	var width := board_w - TILE * 3.0
	var top := _origin.y + 8.0
	var rect := Rect2(left, top, width, lane_h * 2 + 4)
	draw_rect(rect, Color(0, 0, 0, 0.18))
	var line_x := left + width * (TIMELINE_BEHIND / (TIMELINE_AHEAD + TIMELINE_BEHIND))
	var px_per_s := width / (TIMELINE_AHEAD + TIMELINE_BEHIND)
	var now := beat_time()

	# Beat ticks, with bar lines a little brighter.
	var beat := clock.beat_length()
	var first := ceili((now - TIMELINE_BEHIND) / beat)
	var last := floori((now + TIMELINE_AHEAD) / beat)
	for b in range(first, last + 1):
		var x := line_x + (b * beat - now) * px_per_s
		var is_bar := posmod(b, clock.beats_per_bar) == 0
		draw_line(Vector2(x, top + 2), Vector2(x, rect.end.y - 2), Color(1, 1, 1, 0.12 if is_bar else 0.05), 1.0)

	draw_string(font, Vector2(left - 14, top + 12), "Q", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, builds["kick"]["color"] * Color(1, 1, 1, 0.5))
	draw_string(font, Vector2(left - 14, top + lane_h + 14), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, builds["bass"]["color"] * Color(1, 1, 1, 0.5))
	for n in notes:
		var x: float = line_x + (n["time"] - now) * px_per_s
		if x < rect.position.x or x > rect.end.x:
			continue
		var lane := 0 if n["type"] == "kick" else 1
		var center := Vector2(x, top + 2 + lane * lane_h + lane_h * 0.5)
		var color: Color = builds[n["type"]]["color"] * Color(1, 1, 1, 0.6)
		if n["state"] == "hit":
			color = Color(1, 1, 1, 0.7)
		elif n["state"] == "missed":
			color = builds[n["type"]]["color"] * Color(1, 1, 1, 0.15)
		var r := 5.0
		draw_colored_polygon(PackedVector2Array([center + Vector2(0, -r), center + Vector2(r, 0), center + Vector2(0, r), center + Vector2(-r, 0)]), color)
	draw_line(Vector2(line_x, top - 2), Vector2(line_x, rect.end.y + 2), Color(1, 1, 1, 0.45), 2.0)
	if _line_flash["ttl"] > 0.0:
		var fa: float = _line_flash["ttl"] / 0.3
		draw_rect(Rect2(line_x - 6, top - 4, 12, rect.size.y + 8), _line_flash["color"] * Color(1, 1, 1, 0.6 * fa))


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
	lines.append("")
	lines.append("Notes this wave %d   total %d" % [_wave_notes, stat_total("notes")])
	for type in KEYS:
		var st: Dictionary = stats[type]
		var rate: float = 0.0 if st["notes"] == 0 else 100.0 * st["hits"] / st["notes"]
		lines.append("%s  notes %d   hits %d (%.0f%%)   crits %d   missed %d   no tower %d" % [OS.get_keycode_string(KEYS[type]), st["notes"], st["hits"], rate, st["perfects"], st["missed"], st["wasted"]])
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
		"K  one-key mode (any key plays any note)",
		"L  timeline %s" % ("on" if show_timeline else "off"),
		"Left click  place     Right click  sell (75%)",
		"Brown = rock. Walls are limited to %d." % WALL_LIMIT,
		"Esc twice  menu",
		"",
		"TEST  T speed %dx   Y auto-send %s" % [SPEEDS[speed_index], "ON" if auto_send else "off"],
		"TEST  G +100g   H skip a wave",
		"Next wave: %d creeps, %.0f HP each" % [creeps_in_wave(wave + 1), creep_hp_at(wave + 1)],
	]
