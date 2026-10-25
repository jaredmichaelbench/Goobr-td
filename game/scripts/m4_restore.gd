extends "res://scripts/m3_song.gd"
## M4: suppress and Restore. Answers P-03: does silence create tension, and
## does restoring on the beat feel great?
##
## Elite creeps (big, dark red) walk the maze with the wave. While an elite has
## towers in reach it is armed. Miss a note then, and it pulses: every tower in
## its reach is locked (suppressed). Locked towers don't fire, don't answer
## notes, and their part drops out of the music. The groove drops too, so the
## mix goes thin. Clean play never gets locked (Jared, 2026-10-25).
##
## F = Restore, any time. It lands on the next 8th note (at most 250 ms later)
## so the ripple, salvo and sound sit on the grid without you timing anything
## (D-0019). A refresh ripple sweeps the board from the goal outward and every
## locked tower relights as it passes, firing an Overcharge salvo. Charges are
## limited: 3 to start, one back per wave cleared. Locks also wear off on their
## own after SUPPRESS_SECONDS.

const SUPPRESS_SECONDS := 10.0
const SUPPRESS_RADIUS := 2.2
const ELITE_EVERY := 6  # One elite per this many creeps, from wave 2.
const ELITE_HP_MULT := 4.0
const ELITE_SPEED_MULT := 0.8
const ELITE_PULSE_BARS := 2  # Bars before the same elite can lock again.
const RESTORE_GRID_STEPS := 1  # Restore lands on the next 8th note. 0 = instant.
const RIPPLE_SPEED := 28.0  # Tiles per second the refresh ripple travels.
const RESTORE_CHARGES := 3
const OVERCHARGE_MULT := 2.5  # Salvo damage = tower damage x this, splash radius 1.

var suppressed := {}  # tower cell -> seconds left
var restore_charges := RESTORE_CHARGES
var _shockwaves: Array[Dictionary] = []
var _restore_flash := 0.0
var _restore_at := -1.0  # Song time a pressed Restore lands, or -1.
var _relight := {}  # cell -> distance from the goal, waiting for the ripple
var _ripple := -1.0  # Ripple radius in tiles, or -1 when idle.
var m4_stats := {"suppressed": 0, "restores": 0, "expired": 0}


func _ready() -> void:
	super._ready()
	title = "M4 Suppress and Restore"
	var boom := AudioStreamPlayer.new()
	boom.stream = StemSynth.chime(110.0)
	boom.volume_db = 2.0
	add_child(boom)
	_sfx["restore"] = boom
	var zap := AudioStreamPlayer.new()
	zap.stream = StemSynth.chime(220.0)
	zap.volume_db = -6.0
	add_child(zap)
	_sfx["suppress"] = zap


func reset() -> void:
	super.reset()
	suppressed.clear()
	restore_charges = RESTORE_CHARGES
	_restore_at = -1.0
	_relight.clear()
	_ripple = -1.0
	m4_stats = {"suppressed": 0, "restores": 0, "expired": 0}


func start_wave() -> void:
	var was_active := wave_active
	super.start_wave()
	if wave_active and not was_active and wave > 1:
		restore_charges = mini(RESTORE_CHARGES, restore_charges + 1)


# --- Elites ------------------------------------------------------------------

func _spawn_creep() -> void:
	super._spawn_creep()
	if wave < 2:
		return
	var index := creeps_in_wave(wave) - _to_spawn  # 1-based spawn order (this one).
	if index % ELITE_EVERY == 0:
		var c: Dictionary = creeps[creeps.size() - 1]
		c["elite"] = true
		c["hp"] *= ELITE_HP_MULT
		c["max_hp"] = c["hp"]
		c["speed"] *= ELITE_SPEED_MULT
		c["pulse_bar"] = -1


func tower_ready(cell: Vector2i) -> bool:
	return not suppressed.has(cell)


func _adjust_mix(active: Dictionary) -> void:
	if not suppressed.is_empty():
		active["hat"] = false


## Elites with towers in reach right now.
func armed_elites() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for c in creeps:
		if c.get("elite", false) and c["hp"] > 0.0 and not _towers_in_reach(c["pos"]).is_empty():
			out.append(c)
	return out


func _towers_in_reach(pos: Vector2) -> Array[Vector2i]:
	var hit: Array[Vector2i] = []
	for cell in structures:
		if KEYS.has(structures[cell]["type"]) and Vector2(cell).distance_to(pos) <= SUPPRESS_RADIUS:
			hit.append(cell)
	return hit


## A missed note while an elite is armed locks the towers in its reach.
func _on_miss(type: String) -> void:
	super._on_miss(type)
	var bar := floori(beat_time() / clock.bar_length())
	var fresh := 0
	for c in armed_elites():
		if c["pulse_bar"] >= 0 and bar - c["pulse_bar"] < ELITE_PULSE_BARS:
			continue
		c["pulse_bar"] = bar
		for cell in _towers_in_reach(c["pos"]):
			if not suppressed.has(cell):
				fresh += 1
			suppressed[cell] = SUPPRESS_SECONDS
		_shockwaves.append({"pos": c["pos"], "ttl": 0.5, "color": Color(0.9, 0.2, 0.3)})
	if fresh > 0:
		m4_stats["suppressed"] += fresh
		_sfx["suppress"].play()
		_show_feedback("MISS   %d tower%s LOCKED   F to Restore" % [fresh, "" if fresh == 1 else "s"], Color(1, 0.3, 0.3))


func step(delta: float) -> void:
	super.step(delta)
	if _restore_at >= 0.0 and beat_time() >= _restore_at:
		_restore_at = -1.0
		_restore()
	if _ripple >= 0.0:
		_ripple += RIPPLE_SPEED * delta
		for cell in _relight.keys():
			if _relight[cell] <= _ripple:
				_relight.erase(cell)
				_relight_tower(cell)
		if _ripple > GRID_SIZE.x + GRID_SIZE.y:
			_ripple = -1.0
	for cell in suppressed.keys():
		if not structures.has(cell):
			suppressed.erase(cell)
			continue
		if _relight.has(cell):
			continue  # The ripple is on its way.
		suppressed[cell] -= delta
		if suppressed[cell] <= 0.0:
			suppressed.erase(cell)
			m4_stats["expired"] += 1


func sell(cell: Vector2i) -> void:
	super.sell(cell)
	suppressed.erase(cell)


# --- Restore -----------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F:
		_press_restore()
		return
	super._unhandled_input(event)


func _press_restore() -> void:
	if state != "playing":
		return
	if suppressed.is_empty():
		_show_feedback("Nothing to Restore", Color(1, 1, 1, 0.5))
		return
	if _restore_at >= 0.0 or not _relight.is_empty():
		return  # Already on its way.
	if restore_charges <= 0:
		_show_feedback("No Restore charges left", Color(1, 0.5, 0.4))
		return
	restore_charges -= 1
	m4_stats["restores"] += 1
	if RESTORE_GRID_STEPS <= 0:
		_restore()
		return
	var grid := step_length() * RESTORE_GRID_STEPS
	_restore_at = (floorf(beat_time() / grid) + 1.0) * grid
	if _restore_at - beat_time() < 0.03:
		_restore_at += grid


## The ripple starts at the goal. Towers relight as it reaches them.
func _restore() -> void:
	_relight.clear()
	for cell in suppressed:
		_relight[cell] = Vector2(cell).distance_to(Vector2(GOAL))
	_ripple = 0.0
	_restore_flash = 0.5
	_lead_timer = clock.bar_length() * LEAD_HOLD_BARS
	_sfx["restore"].play()
	_show_feedback("RESTORE   Overcharge salvo!", Color(1.0, 0.9, 0.3))


func _relight_tower(cell: Vector2i) -> void:
	suppressed.erase(cell)
	if not structures.has(cell):
		return
	_flashes[cell] = 0.3
	var spec: Dictionary = builds[structures[cell]["type"]]
	var target := _pick_target(Vector2(cell), spec["range"])
	if target.is_empty():
		return
	var dmg: float = spec["damage"] * OVERCHARGE_MULT * damage_scale()
	var dealt := 0.0
	for c in creeps:
		if c["pos"].distance_to(target["pos"]) <= 1.0:
			dealt += minf(dmg, maxf(c["hp"], 0.0))
			c["hp"] -= dmg
	shots.append({"from": Vector2(cell), "to": target["pos"], "color": Color(1.0, 0.9, 0.3), "ttl": 0.3, "splash": 1.0})
	_popup(target["pos"], "%d!" % roundi(dealt), Color(1.0, 0.9, 0.3), 20)


# --- Drawing -----------------------------------------------------------------

func _tick_effects(delta: float) -> void:
	super._tick_effects(delta)
	_restore_flash = maxf(0.0, _restore_flash - delta)
	var live: Array[Dictionary] = []
	for w in _shockwaves:
		w["ttl"] -= delta
		if w["ttl"] > 0.0:
			live.append(w)
	_shockwaves = live


func _draw() -> void:
	super._draw()
	var font := ThemeDB.fallback_font
	var board_w := GRID_SIZE.x * TILE

	# Elites: a dark ring and their suppression reach.
	for c in creeps:
		if not c.get("elite", false):
			continue
		var p := _to_screen(c["pos"])
		var armed := not _towers_in_reach(c["pos"]).is_empty()
		var pulse := 0.5 + 0.5 * sin(beat_time() * TAU * 2.0)
		draw_circle(p, TILE * 0.4, Color(0.55, 0.1, 0.2))
		draw_arc(p, TILE * 0.4, 0, TAU, 32, Color(1, 0.3, 0.4), 2.0)
		draw_arc(p, SUPPRESS_RADIUS * TILE, 0, TAU, 48, Color(1, 0.3, 0.4, 0.15 + 0.35 * pulse if armed else 0.12), 2.0 if armed else 1.0)
		if armed:
			draw_string(font, p + Vector2(-30, -TILE * 0.6), "miss = lock", HORIZONTAL_ALIGNMENT_CENTER, 60, 11, Color(1, 0.4, 0.45, 0.6 + 0.4 * pulse))

	# Suppressed towers: greyed out with a cross and a draining bar.
	for cell in suppressed:
		var r := Rect2(_origin + Vector2(cell) * TILE, Vector2(TILE, TILE)).grow(-2)
		draw_rect(r, Color(0.1, 0.1, 0.12, 0.75))
		draw_line(r.position, r.end, Color(1, 0.3, 0.3, 0.8), 2.0)
		draw_line(Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), Color(1, 0.3, 0.3, 0.8), 2.0)
		var frac: float = suppressed[cell] / SUPPRESS_SECONDS
		draw_rect(Rect2(r.position + Vector2(0, r.size.y - 3), Vector2(r.size.x * frac, 3)), Color(1, 0.3, 0.3))

	for w in _shockwaves:
		var a: float = w["ttl"] / 0.5
		draw_arc(_to_screen(w["pos"]), SUPPRESS_RADIUS * TILE * (1.0 - a * 0.7), 0, TAU, 48, w["color"] * Color(1, 1, 1, a), 4.0)

	if _restore_flash > 0.0:
		draw_rect(Rect2(_origin, Vector2(board_w, GRID_SIZE.y * TILE)), Color(1.0, 0.9, 0.3, 0.12 * _restore_flash / 0.5))
	if _ripple >= 0.0:
		# The refresh ripple: a bright ring with a soft band behind it.
		var center := _to_screen(Vector2(GOAL))
		var board := Rect2(_origin, Vector2(GRID_SIZE) * TILE)
		for i in 4:
			var r: float = (_ripple - i * 0.8) * TILE
			if r <= 0.0:
				continue
			# Drawn as segments so the ring stays inside the board.
			var color := Color(1.0, 0.95, 0.6, 0.8 - i * 0.18)
			var prev := center + Vector2(r, 0)
			for k in range(1, 97):
				var ang := TAU * k / 96.0
				var pt := center + Vector2(cos(ang), sin(ang)) * r
				if board.has_point(prev) and board.has_point(pt):
					draw_line(prev, pt, color, 6.0 - i * 1.2)
				prev = pt

	# A pressed Restore shows where it lands on the timeline.
	if show_timeline and _restore_at >= 0.0:
		var now := beat_time()
		var left := _origin.x + TILE * 1.5
		var width := board_w - TILE * 3.0
		var line_x := left + width * (TIMELINE_BEHIND / (TIMELINE_AHEAD + TIMELINE_BEHIND))
		var x := line_x + (_restore_at - now) * width / (TIMELINE_AHEAD + TIMELINE_BEHIND)
		var top := _origin.y + 8.0
		draw_line(Vector2(x, top - 3), Vector2(x, top + 35), Color(1.0, 0.9, 0.3, 0.9), 3.0)

	# Restore charges under the meters.
	var x := _origin.x + board_w + 20
	var y := _origin.y + 190
	draw_string(font, Vector2(x, y), "Restore (F)", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 1, 1, 0.7))
	for i in RESTORE_CHARGES:
		var filled := i < restore_charges
		draw_rect(Rect2(x + i * 22, y + 6, 18, 10), Color(1.0, 0.9, 0.3) if filled else Color(1, 1, 1, 0.1))
	if not suppressed.is_empty():
		draw_string(font, Vector2(x, y + 36), "%d suppressed" % suppressed.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 0.3, 0.3))


func status_lines() -> Array[String]:
	var lines := super.status_lines()
	lines.append("Locked %d   Restores %d   Wore off %d" % [m4_stats["suppressed"], m4_stats["restores"], m4_stats["expired"]])
	return lines


func help_lines() -> Array[String]:
	var lines := super.help_lines()
	lines.insert(5, "F  Restore locked towers (%d/%d charges)" % [restore_charges, RESTORE_CHARGES])
	return lines
