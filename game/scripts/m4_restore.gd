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
## F = Restore. It only lands on a beat (RESTORE_GRID_STEPS), but any beat, so
## you choose when. On the beat every locked tower comes back at once with an
## Overcharge salvo. Off the beat nothing happens and no charge is spent.
## Charges are limited: 3 to start, one back per wave cleared. Locks also wear
## off on their own after SUPPRESS_SECONDS.

const SUPPRESS_SECONDS := 10.0
const SUPPRESS_RADIUS := 2.2
const ELITE_EVERY := 6  # One elite per this many creeps, from wave 2.
const ELITE_HP_MULT := 4.0
const ELITE_SPEED_MULT := 0.8
const ELITE_PULSE_BARS := 2  # Bars before the same elite can lock again.
const RESTORE_GRID_STEPS := 4  # Restore lands on every beat (8th-note steps per bar = 8).
const RESTORE_CHARGES := 3
const OVERCHARGE_MULT := 2.5  # Salvo damage = tower damage x this, splash radius 1.

var suppressed := {}  # tower cell -> seconds left
var restore_charges := RESTORE_CHARGES
var _shockwaves: Array[Dictionary] = []
var _restore_flash := 0.0
var m4_stats := {"suppressed": 0, "restores": 0, "off_beat": 0, "expired": 0}


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
	m4_stats = {"suppressed": 0, "restores": 0, "off_beat": 0, "expired": 0}


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
		_show_feedback("MISS   %d tower%s LOCKED   F on a beat to Restore" % [fresh, "" if fresh == 1 else "s"], Color(1, 0.3, 0.3))


func step(delta: float) -> void:
	super.step(delta)
	for cell in suppressed.keys():
		if not structures.has(cell):
			suppressed.erase(cell)
			continue
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
	if restore_charges <= 0:
		_show_feedback("No Restore charges left", Color(1, 0.5, 0.4))
		return
	var grid := step_length() * RESTORE_GRID_STEPS
	var phase := fposmod(press_time(), grid)
	var offset_ms := (phase if phase < grid * 0.5 else phase - grid) * 1000.0
	var g := Timing.grade(offset_ms)
	if g == "Miss":
		m4_stats["off_beat"] += 1
		_show_feedback("Off the beat (%+.0f ms)   Restore only lands on a beat" % offset_ms, Color(1, 0.6, 0.4))
		return
	restore_charges -= 1
	m4_stats["restores"] += 1
	_show_feedback("%s RESTORE  %+.0f ms   Overcharge salvo!" % [g.to_upper(), offset_ms], Color(1.0, 0.9, 0.3))
	_restore()


func _restore() -> void:
	var cells := suppressed.keys()
	suppressed.clear()
	_lead_timer = clock.bar_length() * LEAD_HOLD_BARS
	_restore_flash = 0.4
	_sfx["restore"].play()
	for cell in cells:
		if not structures.has(cell):
			continue
		_flashes[cell] = 0.3
		var spec: Dictionary = builds[structures[cell]["type"]]
		var target := _pick_target(Vector2(cell), spec["range"])
		if target.is_empty():
			continue
		var dmg: float = spec["damage"] * OVERCHARGE_MULT
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
		draw_rect(Rect2(_origin, Vector2(board_w, GRID_SIZE.y * TILE)), Color(1.0, 0.9, 0.3, 0.25 * _restore_flash / 0.4))

	# While locked: small white marks on every beat you could Restore on.
	if show_timeline and not suppressed.is_empty():
		var grid := step_length() * RESTORE_GRID_STEPS
		var now := beat_time()
		var left := _origin.x + TILE * 1.5
		var width := board_w - TILE * 3.0
		var line_x := left + width * (TIMELINE_BEHIND / (TIMELINE_AHEAD + TIMELINE_BEHIND))
		var px_per_s := width / (TIMELINE_AHEAD + TIMELINE_BEHIND)
		var top := _origin.y + 8.0
		var first := ceili(now / grid)
		var last := floori((now + TIMELINE_AHEAD) / grid)
		for i in range(first, last + 1):
			var x := line_x + (i * grid - now) * px_per_s
			draw_line(Vector2(x, top - 3), Vector2(x, top + 35), Color(1, 1, 1, 0.7), 2.0)
		draw_string(font, Vector2(line_x + 6, top + 48), "F on any beat", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.8))

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
	lines.append("Locked %d   Restores %d   Off-beat presses %d   Wore off %d" % [m4_stats["suppressed"], m4_stats["restores"], m4_stats["off_beat"], m4_stats["expired"]])
	return lines


func help_lines() -> Array[String]:
	var lines := super.help_lines()
	lines.insert(5, "F  Restore locked towers, on any beat (%d/%d charges)" % [restore_charges, RESTORE_CHARGES])
	return lines
