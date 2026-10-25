extends "res://scripts/m3_song.gd"
## M4: suppress and Restore. Answers P-03: does silence create tension, and
## does restoring on the beat feel great?
##
## Elite creeps (big, dark red) walk the maze with the wave, a few per wave
## from ELITE_FIRST_WAVE. Two kinds, one parry language: a projectile leaves
## the elite, you watch it land, Space on arrival (D-0024, D-0027).
##
## Jammer: when it has a tower in reach it stops, raises a sword, and throws a
## pulse at the nearest tower that lands on the next downbeat, with a tick on
## every beat and a low tone on the last. Parry it and the tower fires back;
## miss it and that tower is locked (suppressed) for SUPPRESS_SECONDS. Locked
## towers don't fire, don't answer notes, and their part drops out of the music.
##
## Archer: once within ARCHER_RANGE of the Conductor (any distance now) it shoots an arrow
## straight over the maze that lands on the next downbeat. Parry it and the Conductor
## deflects it back; miss it and it breaks one of the Conductor's SHIELDS
## (SHIELDS per wave), then costs health. Creeps walking in still cost health.
## Notes never lock anything (D-0023): Space is the one defensive input.
##
## F = Restore, any time. It lands on the next 8th note (at most 250 ms later)
## so the ripple, salvo and sound sit on the grid without you timing anything
## (D-0019). A refresh ripple sweeps the board from the goal outward and every
## locked tower relights as it passes, firing an Overcharge salvo. Charges are
## limited: 3 to start, one back per wave cleared. Locks also wear off on their
## own after SUPPRESS_SECONDS.

const SUPPRESS_SECONDS := 5.0
const SUPPRESS_RADIUS := 2.2
const ELITE_FIRST_WAVE := 3
const ELITE_HP_MULT := 4.0
const ELITE_SPEED_MULT := 0.8
const ELITE_PULSE_BARS := 8  # Bars before the same elite winds up again.
const PULSE_TARGETS_WAVE_6 := 2  # From wave 6 a pulse threatens the two nearest towers.
const PARRY_DAMAGE := 40.0
const PULSE_TELL_BEATS := 1.0
const IMMUNE_BARS := 2.0  # Towers relit by Restore can't be locked for this long.
const ARCHER_RANGE := INF  # Archers shoot from anywhere on the board (Jared, playtest 5). Was 16 tiles.
const ARCHER_BARS := 4  # Bars between one Archer's shots.
const SHIELDS := 3  # Conductor shields per wave; each absorbs one ranged hit.
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
var immune := {}  # tower cell -> seconds of lock immunity left (after Restore)
var shields := SHIELDS
var arrows: Array[Dictionary] = []  # launch, arrive, from, state (flying/parried/hit), ref (the Archer)
var m4_stats := {"suppressed": 0, "restores": 0, "expired": 0, "pulses": 0, "parried": 0, "arrows": 0, "shields_lost": 0}


func _ready() -> void:
	super._ready()
	title = "M4 Suppress and Restore"
	# Defence voices, also in E (D-0029).
	for sfx in [["restore", StemSynth.stab(82.4, true), 2.0], ["suppress", StemSynth.thud(), -2.0], ["tell", StemSynth.stab(41.2), -6.0], ["parry", StemSynth.stab(82.4), -1.0], ["parry_perfect", StemSynth.stab(164.8, true), 0.0], ["tick", StemSynth.tick(660.0), -14.0]]:
		if _sfx.has(sfx[0]):
			continue
		var player := AudioStreamPlayer.new()
		player.stream = StemSynth.with_override(sfx[0], sfx[1], sfx_pack)
		player.volume_db = sfx[2]
		add_child(player)
		_sfx[sfx[0]] = player


func reset() -> void:
	super.reset()
	suppressed.clear()
	immune.clear()
	shields = SHIELDS
	arrows.clear()
	restore_charges = RESTORE_CHARGES
	_restore_at = -1.0
	_relight.clear()
	_ripple = -1.0
	m4_stats = {"suppressed": 0, "restores": 0, "expired": 0, "pulses": 0, "parried": 0, "arrows": 0, "shields_lost": 0}


func start_wave() -> void:
	var was_active := wave_active
	super.start_wave()
	if wave_active and not was_active:
		shields = SHIELDS
		arrows.clear()
		if wave > 1:
			restore_charges = mini(RESTORE_CHARGES, restore_charges + 1)


# --- Elites ------------------------------------------------------------------

## How many elites a wave has: one from ELITE_FIRST_WAVE, one more every two waves.
func elites_in_wave(w: int) -> int:
	if w < ELITE_FIRST_WAVE:
		return 0
	return 1 + (w - ELITE_FIRST_WAVE) / 2


## Spawn positions (1-based) of the elites, spread evenly through the wave.
func elite_slots(w: int) -> Array[int]:
	var out: Array[int] = []
	var n := elites_in_wave(w)
	var total := creeps_in_wave(w)
	for k in n:
		out.append(int(roundf(float(total) * (k + 1) / (n + 1))))
	return out


## Which kind the k-th elite of a wave is: Jammers first, Archers from wave 4,
## then alternating.
func elite_kind(w: int, k: int) -> String:
	if w <= 3:
		return "jammer"
	if w == 4:
		return "archer"
	return "jammer" if k % 2 == 0 else "archer"


func _spawn_creep() -> void:
	super._spawn_creep()
	var index := creeps_in_wave(wave) - _to_spawn  # 1-based spawn order (this one).
	var slots := elite_slots(wave)
	if slots.has(index):
		var c: Dictionary = creeps[creeps.size() - 1]
		c["elite"] = true
		c["kind"] = elite_kind(wave, slots.find(index))
		c["hp"] *= ELITE_HP_MULT
		c["max_hp"] = c["hp"]
		c["speed"] *= ELITE_SPEED_MULT
		c["base_speed"] = c["speed"]
		c["pulse_at"] = -1.0  # Song time its next pulse lands, or -1.
		c["pulse_from"] = -1.0  # Song time the projectile left the elite.
		c["pulse_targets"] = [] as Array[Vector2i]
		c["told"] = false
		c["ticked"] = -1  # Last wind-up beat that ticked.
		c["cooldown_until"] = 0.0


func tower_ready(cell: Vector2i) -> bool:
	return not suppressed.has(cell)


func _adjust_mix(active: Dictionary) -> void:
	if not suppressed.is_empty():
		active["hat"] = false


## Jammers with towers in reach right now.
func armed_elites() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for c in creeps:
		if c.get("elite", false) and c.get("kind", "jammer") == "jammer" and c["hp"] > 0.0 and not _towers_in_reach(c["pos"]).is_empty():
			out.append(c)
	return out


func _path_left(c: Dictionary) -> float:
	return float(grid.dist(c["target"])) + c["pos"].distance_to(Vector2(c["target"]))


## A Jammer stands still while its pulse is in the air, so the throw never
## comes from on top of the tower and the projectile has a path to read.
func _move_creeps(delta: float) -> void:
	for c in creeps:
		if c.get("elite", false) and c.has("base_speed"):
			c["speed"] = 0.0 if (c["kind"] == "jammer" and c["pulse_at"] >= 0.0) else c["base_speed"]
	super._move_creeps(delta)


func _towers_in_reach(pos: Vector2) -> Array[Vector2i]:
	var hit: Array[Vector2i] = []
	for cell in structures:
		if builds[structures[cell]["type"]].has("range") and Vector2(cell).distance_to(pos) <= SUPPRESS_RADIUS:
			hit.append(cell)
	return hit


## The towers a pulse from here would threaten: the nearest one (two from wave 6).
func _pulse_targets_for(pos: Vector2) -> Array[Vector2i]:
	var cells := _towers_in_reach(pos)
	cells.sort_custom(func(a, b): return Vector2(a).distance_to(pos) < Vector2(b).distance_to(pos))
	var count := PULSE_TARGETS_WAVE_6 if wave >= 6 else 1
	var out: Array[Vector2i] = []
	for cell in cells:
		if out.size() >= count:
			break
		out.append(cell)
	return out


## Called every step. On a bar start, an armed Jammer with its cooldown done
## throws a pulse that lands on the next downbeat (a full bar in the air), and
## an Archer in range shoots an arrow that lands on the same downbeat.
func _arm_elites(s: int) -> void:
	if posmod(s, STEPS_PER_BAR) != 0:
		return
	var bar_time := floori(float(s) / STEPS_PER_BAR) * clock.bar_length()
	for c in creeps:
		if not c.get("elite", false) or c.get("kind", "") != "archer" or c["hp"] <= 0.0:
			continue
		if beat_time() < c["cooldown_until"] or c["pos"].distance_to(Vector2(GOAL)) > ARCHER_RANGE:
			continue
		c["cooldown_until"] = beat_time() + ARCHER_BARS * clock.bar_length()
		arrows.append({"launch": bar_time, "arrive": bar_time + clock.bar_length(), "from": c["pos"], "state": "flying", "ref": c, "ticked": -1, "told": false})
		m4_stats["arrows"] += 1
	for c in armed_elites():
		if c["pulse_at"] >= 0.0 or beat_time() < c["cooldown_until"]:
			continue
		var targets := _pulse_targets_for(c["pos"])
		if targets.is_empty():
			continue
		c["pulse_from"] = bar_time
		c["pulse_at"] = bar_time + clock.bar_length()
		c["told"] = false
		c["ticked"] = -1
		c["pulse_targets"] = targets
		m4_stats["pulses"] += 1


func _cancel_pulse(c: Dictionary) -> void:
	c["pulse_at"] = -1.0
	c["pulse_from"] = -1.0
	c["cooldown_until"] = beat_time() + ELITE_PULSE_BARS * clock.bar_length()


## The pulse landed unparried: lock the tower(s) it was thrown at. A tower
## that is already locked or immune (just Restored) is left alone.
func _pulse_lands(c: Dictionary) -> void:
	var targets: Array = c.get("pulse_targets", [])
	_cancel_pulse(c)
	var fresh := _lock_towers(targets)
	_shockwaves.append({"pos": c["pos"], "ttl": 0.5, "color": Color(0.9, 0.2, 0.3)})
	if fresh > 0:
		_show_feedback("PULSE   %d tower%s LOCKED   F to Restore" % [fresh, "" if fresh == 1 else "s"], Color(1, 0.3, 0.3))
	elif not targets.is_empty():
		_show_feedback("PULSE   shrugged off", Color(1, 1, 1, 0.6))


## Lock these towers. Returns how many were freshly locked.
func _lock_towers(cells: Array) -> int:
	var fresh := 0
	for cell in cells:
		if not structures.has(cell) or suppressed.has(cell) or immune.has(cell):
			continue
		suppressed[cell] = SUPPRESS_SECONDS
		fresh += 1
	if fresh > 0:
		m4_stats["suppressed"] += fresh
		_sfx["suppress"].play()
	return fresh


# --- Parry (Space) -------------------------------------------------------------

## Things Space can parry right now: {time, kind, ref}. M5 adds boss bolts.
func _parry_candidates() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for c in creeps:
		if c.get("elite", false) and c["hp"] > 0.0 and c["pulse_at"] >= 0.0:
			out.append({"time": c["pulse_at"], "kind": "elite", "ref": c})
	for a in arrows:
		if a["state"] == "flying":
			out.append({"time": a["arrive"], "kind": "arrow", "ref": a})
	return out


## An arrow reached the Conductor unparried: a shield breaks, or health goes.
func _arrow_hit(a: Dictionary) -> void:
	a["state"] = "hit"
	_shockwaves.append({"pos": Vector2(GOAL), "ttl": 0.5, "color": Color(0.9, 0.2, 0.3)})
	_sfx["miss"].play()
	if shields > 0:
		shields -= 1
		m4_stats["shields_lost"] += 1
		_show_feedback("ARROW   shield broken, %d left" % shields, Color(1, 0.5, 0.4))
	else:
		health -= 1
		_show_feedback("ARROW   -1 health", Color(1, 0.3, 0.3))
		if health <= 0:
			health = 0
			state = "lost"


## Where a projectile flying the path from `from` is right now.
func _path_pos(b: Dictionary) -> Vector2:
	var frac: float = clampf((beat_time() - b["launch"]) / maxf(b["arrive"] - b["launch"], 0.01), 0.0, 1.0)
	var from: Vector2 = b["from"]
	var total := float(grid.dist(Vector2i(from.round())))
	if total <= 0.0:
		return Vector2(GOAL)
	var to_go := total * (1.0 - frac)
	var cell := Vector2i(from.round())
	var guard := 400
	while grid.dist(cell) > to_go + 1.0 and guard > 0:
		cell = grid.next_step(cell)
		guard -= 1
	var next := grid.next_step(cell)
	var t := clampf(float(grid.dist(cell)) - to_go, 0.0, 1.0)
	return Vector2(cell).lerp(Vector2(next), t)


func _parry() -> void:
	var best := {}
	var best_off := INF
	var cands := _parry_candidates()
	for cand in cands:
		var off: float = absf(press_time() - cand["time"])
		if off < best_off:
			best = cand
			best_off = off
	if best.is_empty():
		_show_feedback("Nothing to parry", Color(1, 1, 1, 0.4))
		return
	var offset_ms: float = (press_time() - best["time"]) * 1000.0
	var g := Timing.grade_parry(offset_ms)
	if g == "Miss":
		_show_feedback("Too early (%+.0f ms)" % offset_ms, Color(1, 1, 1, 0.5))
		return
	on_streak_hit()
	_sfx["parry_perfect" if g == "Perfect" else "parry"].play()
	_lead_timer = clock.bar_length()
	_resolve_parry(best, g, offset_ms)
	# One press, every projectile landing in that window (D-0031): a pulse and
	# an arrow on the same beat both go, each graded off the same press.
	for cand in cands:
		if is_same(cand["ref"], best["ref"]):
			continue
		var off_ms: float = (press_time() - cand["time"]) * 1000.0
		var g2 := Timing.grade_parry(off_ms)
		if g2 != "Miss":
			_resolve_parry(cand, g2, off_ms)


## What a parry does, by kind. M5 extends this for bolts.
func _resolve_parry(cand: Dictionary, g: String, offset_ms: float) -> void:
	var perfect := g == "Perfect"
	if cand["kind"] == "arrow":
		var a: Dictionary = cand["ref"]
		a["state"] = "parried"
		m4_stats["parried"] += 1
		var archer: Dictionary = a["ref"]
		var dmg := PARRY_DAMAGE * (2.0 if perfect else 1.0)
		if creeps.has(archer):
			archer["hp"] -= dmg
			shots.append({"from": Vector2(GOAL), "to": archer["pos"], "color": Color(1.0, 0.9, 0.3), "ttl": 0.35, "splash": 0.0, "width": 3.0})
			_popup(archer["pos"], ("%d!" if perfect else "%d") % roundi(dmg), Color(1.0, 0.9, 0.3) if perfect else Color.WHITE, 20 if perfect else 15)
		_shockwaves.append({"pos": Vector2(GOAL), "ttl": 0.4, "color": Color(1.0, 0.9, 0.3)})
		_show_feedback("%sPARRY  %+.0f ms   arrow returned" % ["PERFECT " if perfect else "", offset_ms], Color(1.0, 0.9, 0.3) if perfect else Color.WHITE)
		return
	if cand["kind"] == "elite":
		var c: Dictionary = cand["ref"]
		var targets: Array = c.get("pulse_targets", [])
		_cancel_pulse(c)
		m4_stats["parried"] += 1
		# The attacked tower fires back: its own damage x3, at least PARRY_DAMAGE.
		var from := Vector2(GOAL)
		var base := PARRY_DAMAGE
		if not targets.is_empty() and structures.has(targets[0]):
			from = Vector2(targets[0])
			base = maxf(PARRY_DAMAGE, tower_spec(targets[0])["damage"] * 3.0)
			_flashes[targets[0]] = 0.3
		var dmg := base * (2.0 if perfect else 1.0)
		c["hp"] -= dmg
		shots.append({"from": from, "to": c["pos"], "color": Color(1.0, 0.9, 0.3), "ttl": 0.35, "splash": 0.0, "width": 3.0})
		_popup(c["pos"], ("%d!" if perfect else "%d") % roundi(dmg), Color(1.0, 0.9, 0.3) if perfect else Color.WHITE, 20 if perfect else 15)
		_show_feedback("%sPARRY  %+.0f ms" % ["PERFECT " if perfect else "", offset_ms], Color(1.0, 0.9, 0.3) if perfect else Color.WHITE)


func on_step(s: int) -> void:
	super.on_step(s)
	if state == "playing":
		_arm_elites(s)


func step(delta: float) -> void:
	super.step(delta)
	# Pulses in the air: a tick on each wind-up beat, the tell on the last,
	# and the lock if nobody parried.
	for c in creeps:
		if c.get("elite", false) and c["pulse_at"] >= 0.0:
			var beat := clock.beat_length()
			var beat_index := floori((beat_time() - c["pulse_from"]) / beat)
			if beat_index > c["ticked"] and beat_time() < c["pulse_at"] - PULSE_TELL_BEATS * beat:
				c["ticked"] = beat_index
				_sfx["tick"].play()
			if not c["told"] and beat_time() >= c["pulse_at"] - PULSE_TELL_BEATS * beat:
				c["told"] = true
				_sfx["tell"].play()
			if press_time() > c["pulse_at"] + Timing.PARRY_GOOD_MS / 1000.0:
				_pulse_lands(c)
				on_streak_miss()
	# Arrows in the air: ticks, the tell, and the hit if nobody parried.
	for a in arrows:
		if a["state"] != "flying":
			continue
		var beat := clock.beat_length()
		var beat_index := floori((beat_time() - a["launch"]) / beat)
		if beat_index > a["ticked"] and beat_time() < a["arrive"] - PULSE_TELL_BEATS * beat:
			a["ticked"] = beat_index
			_sfx["tick"].play()
		if not a["told"] and beat_time() >= a["arrive"] - PULSE_TELL_BEATS * beat:
			a["told"] = true
			_sfx["tell"].play()
		if press_time() > a["arrive"] + Timing.PARRY_GOOD_MS / 1000.0:
			_arrow_hit(a)
			on_streak_miss()
	var keep: Array[Dictionary] = []
	for a in arrows:
		if a["arrive"] > beat_time() - 0.5:
			keep.append(a)
	arrows = keep
	for cell in immune.keys():
		immune[cell] -= delta
		if immune[cell] <= 0.0 or not structures.has(cell):
			immune.erase(cell)
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
	immune.erase(cell)


# --- Restore -----------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F:
			_press_restore()
			return
		if event.keycode == KEY_SPACE:
			_parry()
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


## The ripple starts at the goal. Towers relight as it reaches them. Any
## pulse in the air is knocked out of it, so a Restore is never undone at once.
func _restore() -> void:
	_relight.clear()
	for cell in suppressed:
		_relight[cell] = Vector2(cell).distance_to(Vector2(GOAL))
	for c in creeps:
		if c.get("elite", false) and c["pulse_at"] >= 0.0:
			_cancel_pulse(c)
	_ripple = 0.0
	_restore_flash = 0.5
	_lead_timer = clock.bar_length() * LEAD_HOLD_BARS
	_sfx["restore"].play()
	_show_feedback("RESTORE   Overcharge salvo!", Color(1.0, 0.9, 0.3))


func _relight_tower(cell: Vector2i) -> void:
	suppressed.erase(cell)
	if not structures.has(cell):
		return
	immune[cell] = IMMUNE_BARS * clock.bar_length()
	_flashes[cell] = 0.3
	var spec: Dictionary = tower_spec(cell)
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

	# Elites: a big dark creep. No circle on it: when it attacks it raises a
	# sword, and the timing lives on the tower it is attacking.
	var beat := clock.beat_length()
	for c in creeps:
		if not c.get("elite", false):
			continue
		var p := _to_screen(c["pos"])
		draw_circle(p, TILE * 0.4, Color(0.55, 0.1, 0.2))
		draw_arc(p, TILE * 0.4, 0, TAU, 32, Color(1, 0.3, 0.4), 2.0)
		if c.get("kind", "jammer") == "archer":
			# A bow: an arc on its back, red while an arrow of its is in the air.
			var shooting := false
			for a in arrows:
				if a["state"] == "flying" and a["ref"] == c:
					shooting = true
			draw_arc(p + Vector2(TILE * 0.3, -TILE * 0.2), TILE * 0.38, -PI * 0.6, PI * 0.6, 16, Color(1, 0.35, 0.4) if shooting else Color(1, 1, 1, 0.85), 3.0)
			continue
		if c["pulse_at"] < 0.0:
			continue
		var frac: float = clampf((beat_time() - c["pulse_from"]) / maxf(c["pulse_at"] - c["pulse_from"], 0.01), 0.0, 1.0)
		var last: bool = c["told"]
		var beats_gone := clampi(floori((beat_time() - c["pulse_from"]) / beat), 0, 4)
		# The sword: raised over the elite, white while winding up, red on the last beat.
		var sword := Color(1, 0.35, 0.4) if last else Color(1, 1, 1, 0.9)
		var hilt := p + Vector2(TILE * 0.35, -TILE * 0.3)
		draw_line(hilt, hilt + Vector2(TILE * 0.2, -TILE * 0.75), sword, 3.0)
		draw_line(hilt + Vector2(-TILE * 0.12, -TILE * 0.05), hilt + Vector2(TILE * 0.12, TILE * 0.05), sword, 3.0)
		# The targeted tower: a red ring closing over the bar, four beat pips
		# filling up, and the pulse crawling in. Space as it lands.
		for cell in c["pulse_targets"]:
			if not structures.has(cell):
				continue
			var tp := _to_screen(Vector2(cell))
			var bp := p.lerp(tp, frac)
			draw_line(p, tp, Color(1, 0.3, 0.4, 0.15), 1.0)
			draw_arc(tp, TILE * (0.55 + 1.3 * (1.0 - frac)), 0, TAU, 48, Color(1, 0.3, 0.4, 0.35 + 0.65 * frac), 2.0 + 2.5 * frac)
			draw_arc(tp, TILE * 0.55, 0, TAU, 32, Color(1, 0.3, 0.4, 0.9 if last else 0.5), 3.5 if last else 2.0)
			for i in 4:
				var pip := tp + Vector2(-15 + i * 10, -TILE * 0.72)
				draw_circle(pip, 3.5, Color(1, 0.35, 0.4) if i < beats_gone else Color(1, 1, 1, 0.25))
			draw_line(p.lerp(tp, maxf(frac - 0.08, 0.0)), bp, Color(1, 0.5, 0.6, 0.5), 4.0)
			draw_circle(bp, TILE * (0.2 if not last else 0.26), Color(1, 0.5, 0.6))
			draw_circle(bp, TILE * 0.09, Color.WHITE)

	# Suppressed towers: greyed out with a cross and a draining bar.
	for cell in suppressed:
		var poly := _cell_poly(cell, 0.07)
		draw_colored_polygon(poly, Color(0.1, 0.1, 0.12, 0.75))
		draw_line(poly[0], poly[2], Color(1, 0.3, 0.3, 0.8), 2.0)
		draw_line(poly[1], poly[3], Color(1, 0.3, 0.3, 0.8), 2.0)
		var frac: float = suppressed[cell] / SUPPRESS_SECONDS
		draw_line(poly[3], poly[3].lerp(poly[2], frac), Color(1, 0.3, 0.3), 3.0)

	# Arrows: fly the path to the Conductor; the Conductor's ring closes over
	# the bar with beat pips, the same read as a pulse on a tower.
	var gp := _to_screen(Vector2(GOAL))
	for a in arrows:
		if a["state"] != "flying":
			continue
		var frac: float = clampf((beat_time() - a["launch"]) / maxf(a["arrive"] - a["launch"], 0.01), 0.0, 1.0)
		var last: bool = a["told"]
		var beats_gone := clampi(floori((beat_time() - a["launch"]) / beat), 0, 4)
		# A straight arrow over the maze: shaft, head, faint line of flight.
		var from: Vector2 = a["from"]
		var ap := _to_screen(from.lerp(Vector2(GOAL), frac))
		var dir := (gp - _to_screen(from)).normalized()
		draw_line(_to_screen(from), gp, Color(1, 0.3, 0.4, 0.12), 1.0)
		draw_line(ap - dir * TILE * 0.5, ap, Color(1, 0.5, 0.6) if not last else Color(1, 0.3, 0.4), 3.0)
		var side := Vector2(-dir.y, dir.x)
		draw_colored_polygon(PackedVector2Array([ap + dir * 6.0, ap - side * 4.0, ap + side * 4.0]), Color.WHITE)
		draw_arc(gp, TILE * (0.6 + 1.3 * (1.0 - frac)), 0, TAU, 48, Color(1, 0.3, 0.4, 0.35 + 0.65 * frac), 2.0 + 2.5 * frac)
		for i in 4:
			var pip := gp + Vector2(-15 + i * 10, -TILE * 0.95)
			draw_circle(pip, 3.5, Color(1, 0.35, 0.4) if i < beats_gone else Color(1, 1, 1, 0.25))
	# Conductor shields: small diamonds under the goal.
	for i in SHIELDS:
		var sp := gp + Vector2(-12 + i * 12, TILE * 0.85)
		var filled := i < shields
		draw_colored_polygon(PackedVector2Array([sp + Vector2(0, -5), sp + Vector2(4, 0), sp + Vector2(0, 5), sp + Vector2(-4, 0)]), Color(0.6, 0.85, 1.0) if filled else Color(1, 1, 1, 0.15))

	# Immune towers: a soft shield ring.
	for cell in immune:
		var a: float = clampf(immune[cell] / (IMMUNE_BARS * clock.bar_length()), 0.0, 1.0)
		draw_arc(_to_screen(Vector2(cell)), TILE * 0.62, 0, TAU, 32, Color(1.0, 0.95, 0.6, 0.25 + 0.45 * a), 2.0)

	for w in _shockwaves:
		var a: float = w["ttl"] / 0.5
		draw_arc(_to_screen(w["pos"]), SUPPRESS_RADIUS * TILE * (1.0 - a * 0.7), 0, TAU, 48, w["color"] * Color(1, 1, 1, a), 4.0)

	if _restore_flash > 0.0:
		draw_colored_polygon(_board_poly(), Color(1.0, 0.9, 0.3, 0.12 * _restore_flash / 0.5))
	if _ripple >= 0.0:
		# The refresh ripple: a bright ring with a soft band behind it.
		var center := _to_screen(Vector2(GOAL))
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
				if _on_board(prev) and _on_board(pt):
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
	lines.append("Pulses %d   Arrows %d   parried %d   Locked %d   Shields lost %d   Restores %d" % [m4_stats["pulses"], m4_stats["arrows"], m4_stats["parried"], m4_stats["suppressed"], m4_stats["shields_lost"], m4_stats["restores"]])
	return lines


func help_lines() -> Array[String]:
	var lines := super.help_lines()
	lines.insert(5, "F  Restore locked towers (%d/%d charges)" % [restore_charges, RESTORE_CHARGES])
	lines.insert(6, "Space  parry pulses (on towers) and arrows (at the Conductor, %d/%d shields)" % [shields, SHIELDS])
	return lines
