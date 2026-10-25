extends "res://scripts/m4_restore.gd"
## M5: the first boss (model D, D-0020). Answers P-05: does it feel like
## learning a souls boss rather than reading a chart?
##
## On the boss wave (BOSS_WAVE, or O to summon it now) one boss walks the maze
## slowly. Its walk is quiet; its attacks are the event. It throws bolts down
## the path at the Conductor (the goal) in short strings. Every bolt leaves
## the boss on the beat grid and arrives on it, but there is no timing UI: the
## tell is the bolt itself, launched with a swell and a low tone and flying
## along your maze. Far away, bolts travel for seconds and strings are
## half-time. Close in, they arrive in a blink and strings tighten to 8th
## notes. A long maze buys you time to read it. The parry reads the same as
## an elite's pulse: watch the projectile land (D-0024).
##
## Space parries the bolt as it reaches the Conductor. A parry deflects it
## back into the boss (damage + posture, Perfect = double). A hit costs
## objective health and locks the towers near the boss, so Restore applies.
## The chart is silent while the boss is up (D-0023): parries are the fight.
## When the posture bar fills the boss staggers: it stops, and for
## CRESCENDO_SECONDS every tower does +30%, the full mix slams in, and a short
## burst of notes sweeps across your towers from the farthest to the nearest,
## one per beat. Kill the boss to clear the wave.

const BOSS_WAVE := 5
const BOSS_HP_MULT := 40.0  # x creep HP of that wave.
const BOSS_SPEED := 0.4  # Tiles per second.
const BOLT_SPEED := 10.0  # Tiles per second along the path.
const BOLT_MIN_TRAVEL := 0.5
const BOLT_MAX_TRAVEL := 3.0  # Even from the far end, a bolt lands within this.
const STRINGS := [[0.0, 1.0, 2.0, 3.5], [0.0, 0.5, 2.0, 3.0]]  # Launch offsets in beats.
const STRING_LEAD_BEATS := 2.0  # First launch this long after the string is called.
const HIT_HEALTH := 2
const POSTURE_GOOD := 15.0
const POSTURE_PERFECT := 25.0  # Four Perfect parries, one full string, break it.
const POSTURE_MAX := 100.0
const CRESCENDO_SECONDS := 6.0
const CRESCENDO_MULT := 1.3
const ESCORT_FRACTION := 0.34  # Each escort pack is this share of a normal wave.
const ESCORT_DELAY := 10.0  # Seconds after the boss appears the second pack comes.

var boss: Dictionary = {}  # The boss creep, or empty.
var bolts: Array[Dictionary] = []  # launch, arrive, from (Vector2), state: flying/parried/hit
var posture := 0.0
var crescendo := 0.0  # Seconds of Crescendo left.
var _next_string_bar := -1
var _string_index := 0
var m5_stats := {"bolts": 0, "parries": 0, "perfect": 0, "hits": 0, "breaks": 0}
var _conductor_flash := {"color": Color.WHITE, "ttl": 0.0}
var _escort_at := -1.0  # Song time the second escort pack is released, or -1.


func _ready() -> void:
	super._ready()
	title = "M5 First boss"
	var player := AudioStreamPlayer.new()
	player.stream = StemSynth.with_override("break", StemSynth.stab(41.2, true), sfx_pack)  # Posture break: the deepest stab.
	player.volume_db = 4.0
	add_child(player)
	_sfx["break"] = player


func reset() -> void:
	super.reset()
	boss = {}
	bolts.clear()
	posture = 0.0
	crescendo = 0.0
	_next_string_bar = -1
	_escort_at = -1.0
	m5_stats = {"bolts": 0, "parries": 0, "perfect": 0, "hits": 0, "breaks": 0}


func damage_scale() -> float:
	return CRESCENDO_MULT if crescendo > 0.0 else 1.0


## No chart while the boss is up: parries are the fight. Crescendo brings
## its own burst of notes.
func chart_allowed() -> bool:
	return not boss_alive()


# --- The boss wave -------------------------------------------------------------

func start_wave() -> void:
	var was_active := wave_active
	super.start_wave()
	if wave_active and not was_active and wave == BOSS_WAVE:
		# The boss brings two small packs: one now, one ESCORT_DELAY later.
		_to_spawn = _escort_size()
		_escort_at = beat_time() + ESCORT_DELAY
		_summon_boss()


## Test tool: O summons the boss into whatever is happening.
func _summon_boss() -> void:
	if boss_alive():
		return
	var hp := creep_hp_at(maxi(wave, 1)) * BOSS_HP_MULT
	boss = {"pos": Vector2(SPAWN), "target": SPAWN, "hp": hp, "max_hp": hp, "speed": BOSS_SPEED, "boss": true}
	creeps.append(boss)
	posture = 0.0
	_next_string_bar = floori(beat_time() / clock.bar_length()) + 1
	_show_feedback("THE BOSS   parry its bolts with Space", Color(1, 0.4, 0.5))


func _escort_size() -> int:
	return maxi(3, int(roundf(creeps_in_wave(wave) * ESCORT_FRACTION)))


func boss_alive() -> bool:
	return not boss.is_empty() and boss["hp"] > 0.0 and creeps.has(boss)


## How far the boss still has to walk, in tiles.
func boss_path_left() -> float:
	return float(grid.dist(boss["target"])) + boss["pos"].distance_to(Vector2(boss["target"]))


## The boss never leaks: at the goal it stands and fights.
func _move_creeps(delta: float) -> void:
	if boss.is_empty() or crescendo > 0.0:
		if not boss.is_empty():
			creeps.erase(boss)
			super._move_creeps(delta)
			creeps.append(boss)
			return
		super._move_creeps(delta)
		return
	super._move_creeps(delta)
	if boss.get("leaked", false):
		boss["leaked"] = false
		boss["pos"] = Vector2(GOAL)
		boss["target"] = GOAL
		boss["at_goal"] = true


func step(delta: float) -> void:
	super.step(delta)
	crescendo = maxf(0.0, crescendo - delta)
	# A parry can kill the boss between steps, so check every tick, not just
	# when it was alive at the start of this one.
	if not boss.is_empty() and not boss_alive():
		_show_feedback("BOSS DOWN", Color(1.0, 0.9, 0.3))
		boss = {}
		bolts.clear()
		crescendo = 0.0
	if _escort_at >= 0.0 and beat_time() >= _escort_at:
		_escort_at = -1.0
		if boss_alive():
			_to_spawn += _escort_size()
			_show_feedback("ESCORTS", Color(1, 0.4, 0.5))
	# Bolts that reached the Conductor without a parry.
	for b in bolts:
		if b["state"] == "flying" and press_time() > b["arrive"] + Timing.PARRY_GOOD_MS / 1000.0:
			b["state"] = "hit"
			_bolt_hit()
			on_streak_miss()
	var keep: Array[Dictionary] = []
	for b in bolts:
		if b["arrive"] > beat_time() - 0.5:
			keep.append(b)
	bolts = keep


# --- Attack strings ------------------------------------------------------------

func on_step(s: int) -> void:
	super.on_step(s)
	if state != "playing" or not boss_alive() or crescendo > 0.0:
		return
	if posmod(s, STEPS_PER_BAR) != 0:
		return
	var bar := floori(float(s) / STEPS_PER_BAR)
	if _next_string_bar >= 0 and bar >= _next_string_bar:
		_call_string(bar)


## How tight the boss plays, from how close it is: 2 = half-time, 1 = beats, 0.5 = 8ths.
func tempo_mult() -> float:
	if boss.get("at_goal", false):
		return 0.5
	var total := float(maxi(grid.dist(SPAWN), 1))
	var frac := boss_path_left() / total
	if frac > 0.66:
		return 2.0
	if frac > 0.33:
		return 1.0
	return 0.5


func _call_string(bar: int) -> void:
	var beat := clock.beat_length()
	var start := bar * clock.bar_length() + STRING_LEAD_BEATS * beat
	var mult := tempo_mult()
	var offsets: Array = STRINGS[_string_index % STRINGS.size()]
	_string_index += 1
	var last := start
	# Bolts leave the boss on the string's beats and arrive after a real flight
	# along the path, snapped up to the next 8th so every landing is on grid.
	var grid_len := step_length()
	for off in offsets:
		var launch: float = start + off * mult * beat
		var travel := clampf(boss_path_left() / BOLT_SPEED, BOLT_MIN_TRAVEL, BOLT_MAX_TRAVEL)
		var arrive := ceilf((launch + travel) / grid_len - 0.001) * grid_len
		bolts.append({"launch": launch, "arrive": arrive, "from": boss["pos"], "state": "flying", "told": false})
		m5_stats["bolts"] += 1
		last = arrive
	# Rest after the string: longer when far, so there is room to breathe.
	var rest_bars := 2 if mult >= 2.0 else (1 if mult >= 1.0 else 0)
	_next_string_bar = ceili(last / clock.bar_length()) + rest_bars


func _bolt_hit() -> void:
	m5_stats["hits"] += 1
	_sfx["miss"].play()
	_conductor_flash = {"color": Color(1, 0.3, 0.3), "ttl": 0.4}
	# A shield takes the bolt if one is left; otherwise it costs health.
	if shields > 0:
		shields -= 1
		m4_stats["shields_lost"] += 1
		_show_feedback("HIT   shield broken, %d left" % shields, Color(1, 0.5, 0.4))
	else:
		health -= HIT_HEALTH
		_show_feedback("HIT   -%d health" % HIT_HEALTH, Color(1, 0.3, 0.3))
	# The boss presses its advantage: the nearest tower(s) in its reach lock.
	if boss_alive():
		if _lock_towers(_pulse_targets_for(boss["pos"])) > 0:
			_shockwaves.append({"pos": boss["pos"], "ttl": 0.5, "color": Color(0.9, 0.2, 0.3)})
	if health <= 0:
		health = 0
		state = "lost"


# --- Parry -----------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_O and state == "playing":
		_summon_boss()
		return
	super._unhandled_input(event)


func _parry_candidates() -> Array[Dictionary]:
	var out := super._parry_candidates()
	for b in bolts:
		if b["state"] == "flying":
			out.append({"time": b["arrive"], "kind": "bolt", "ref": b})
	return out


func _resolve_parry(cand: Dictionary, g: String, offset_ms: float) -> void:
	if cand["kind"] != "bolt":
		super._resolve_parry(cand, g, offset_ms)
		return
	var best: Dictionary = cand["ref"]
	best["state"] = "parried"
	var perfect := g == "Perfect"
	m5_stats["parries"] += 1
	if perfect:
		m5_stats["perfect"] += 1
	_conductor_flash = {"color": Color(1.0, 0.9, 0.3) if perfect else Color.WHITE, "ttl": 0.4}
	if boss_alive():
		var dmg := PARRY_DAMAGE * (2.0 if perfect else 1.0)
		boss["hp"] -= dmg
		shots.append({"from": Vector2(GOAL), "to": boss["pos"], "color": Color(1.0, 0.9, 0.3), "ttl": 0.3, "splash": 0.0})
		_popup(boss["pos"], ("%d!" if perfect else "%d") % roundi(dmg), Color(1.0, 0.9, 0.3) if perfect else Color.WHITE, 20 if perfect else 15)
		posture += POSTURE_PERFECT if perfect else POSTURE_GOOD
		if posture >= POSTURE_MAX:
			_posture_break()
	_show_feedback("%sPARRY  %+.0f ms" % ["PERFECT " if perfect else "", offset_ms], Color(1.0, 0.9, 0.3) if perfect else Color.WHITE)


func _posture_break() -> void:
	posture = 0.0
	crescendo = CRESCENDO_SECONDS
	m5_stats["breaks"] += 1
	bolts.clear()
	_sfx["break"].play()
	_lead_timer = CRESCENDO_SECONDS
	_restore_flash = 0.5
	_show_feedback("POSTURE BREAK   CRESCENDO  +30%% for %.0f s   play!" % CRESCENDO_SECONDS, Color(1.0, 0.9, 0.3))
	_next_string_bar = floori((beat_time() + CRESCENDO_SECONDS) / clock.bar_length()) + 1
	# The burst: a note on every beat of the Crescendo, Q and E alternating,
	# starting two beats out so the first ring has time to close. It sweeps
	# across the towers from the farthest from the boss to the nearest, one
	# ring per tower, wrapping if there are more beats than towers.
	var towers: Array[Vector2i] = []
	for cell in structures:
		if builds[structures[cell]["type"]].has("range"):
			towers.append(cell)
	if towers.is_empty():
		return
	var bp: Vector2 = boss["pos"]
	towers.sort_custom(func(a, b): return Vector2(a).distance_to(bp) > Vector2(b).distance_to(bp))
	var beat := clock.beat_length()
	var first := (floorf(beat_time() / beat) + 2.0) * beat
	var i := 0
	while first + i * beat < beat_time() + CRESCENDO_SECONDS - 0.2:
		add_note(first + i * beat, "kick" if i % 2 == 0 else "bass", towers[i % towers.size()])
		i += 1


## Crescendo: everything plays.
func _adjust_mix(active: Dictionary) -> void:
	super._adjust_mix(active)
	if crescendo > 0.0:
		for k in active:
			active[k] = true


# --- Drawing -------------------------------------------------------------------

func _tick_effects(delta: float) -> void:
	super._tick_effects(delta)
	_conductor_flash["ttl"] = maxf(0.0, _conductor_flash["ttl"] - delta)
	for b in bolts:
		if b["state"] == "flying" and not b["told"] and beat_time() >= b["launch"]:
			b["told"] = true
			_sfx["tell"].play()


## Where along the path a bolt is: from its launch spot to the goal.
func _bolt_pos(b: Dictionary) -> Vector2:
	return _path_pos(b)


func _draw() -> void:
	super._draw()
	var font := ThemeDB.fallback_font
	var board_w := GRID_SIZE.x * TILE

	if crescendo > 0.0:
		draw_colored_polygon(_board_poly(), Color(1.0, 0.85, 0.3, 0.06 + 0.04 * sin(beat_time() * TAU * 2.0)))

	if boss_alive():
		var p := _to_screen(boss["pos"])
		var staggered := crescendo > 0.0
		draw_circle(p, TILE * 0.75, Color(0.35, 0.05, 0.15) if not staggered else Color(0.5, 0.4, 0.1))
		draw_arc(p, TILE * 0.75, 0, TAU, 48, Color(1, 0.3, 0.5) if not staggered else Color(1.0, 0.9, 0.3), 3.0)
		# Wind-up tell: the boss swells in the last beat before a launch.
		for b in bolts:
			if b["state"] == "flying" and not b["told"]:
				var to_launch: float = b["launch"] - beat_time()
				if to_launch < clock.beat_length():
					var a: float = 1.0 - to_launch / clock.beat_length()
					draw_arc(p, TILE * (0.75 + 0.6 * a), 0, TAU, 48, Color(1, 0.5, 0.6, 0.3 + 0.6 * a), 4.0)
				break
		if staggered:
			draw_string(font, p + Vector2(-40, -TILE), "STAGGERED", HORIZONTAL_ALIGNMENT_CENTER, 80, 13, Color(1.0, 0.9, 0.3))

	# Bolts in flight, with a short trail.
	for b in bolts:
		if b["state"] != "flying" or not b["told"]:
			continue
		var p := _to_screen(_bolt_pos(b))
		draw_circle(p, TILE * 0.22, Color(1, 0.5, 0.6))
		draw_circle(p, TILE * 0.1, Color.WHITE)

	# The Conductor at the goal.
	var gp := _to_screen(Vector2(GOAL))
	draw_arc(gp, TILE * 0.55, 0, TAU, 48, Color(1, 1, 1, 0.5), 2.0)
	if _conductor_flash["ttl"] > 0.0:
		var a: float = _conductor_flash["ttl"] / 0.4
		draw_arc(gp, TILE * (0.6 + 1.2 * (1.0 - a)), 0, TAU, 48, _conductor_flash["color"] * Color(1, 1, 1, a), 5.0)

	# Boss health and posture over the board.
	if boss_alive():
		var w := board_w * 0.5
		var x := (get_viewport_rect().size.x + 480.0) * 0.5 - w * 0.5
		var y := 14.0
		draw_rect(Rect2(x, y, w, 10), Color(1, 1, 1, 0.1))
		draw_rect(Rect2(x, y, w * clampf(boss["hp"] / boss["max_hp"], 0.0, 1.0), 10), Color(0.9, 0.25, 0.4))
		draw_rect(Rect2(x, y + 13, w, 5), Color(1, 1, 1, 0.08))
		draw_rect(Rect2(x, y + 13, w * clampf(posture / POSTURE_MAX, 0.0, 1.0), 5), Color(1.0, 0.9, 0.3))
		draw_string(font, Vector2(x - 60, y + 10), "Boss", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.7))
		draw_string(font, Vector2(x + w + 8, y + 10), "%d" % maxi(int(boss["hp"]), 0), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.7))


func status_lines() -> Array[String]:
	var lines := super.status_lines()
	lines.append("Boss bolts %d   parries %d (perfect %d)   hits %d   breaks %d" % [m5_stats["bolts"], m5_stats["parries"], m5_stats["perfect"], m5_stats["hits"], m5_stats["breaks"]])
	if crescendo > 0.0:
		lines.append("CRESCENDO  %.1f s" % crescendo)
	return lines


func help_lines() -> Array[String]:
	var lines := super.help_lines()
	lines.insert(7, "Space  also parries boss bolts as they reach the Conductor")
	lines.append("TEST  O summon the boss now (boss wave is %d)" % BOSS_WAVE)
	return lines
