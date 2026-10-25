extends "res://scripts/m5_boss.gd"
## M6: the run (D-0034, D-0035). Everything from M5, plus:
##
## The draft: after every cleared wave but the last, pick 1 of 3 cards with
## 1 / 2 / 3. Plain cards are small and immediate (gold, a charge, a shield).
## Altering cards change how a tower or a parry works for the rest of the run,
## once each. Conditional cards are shown locked with their condition; meet it
## on the next wave and the card unlocks, fail and it is lost.
##
## The second boss at wave 10: the same body, different strings. A Stomp is a
## slam at the maze: a ring grows on the tile under the boss over a bar; parry
## on the downbeat or every tower within STOMP_RADIUS locks. A Volley is three
## bolts on 8th notes, each parried on its own. After two posture breaks the
## strings go double-time.
##
## Win and lose screens show the run's numbers. R runs again.

const STOMP_RADIUS := 2.0
const VOLLEY := [0.0, 0.5, 1.0]  # Launch offsets in beats.
const DOUBLE_TIME_BREAKS := 2
const BOSS2_WAVE := 10

const CARDS := {
	"gold": {"name": "Coin purse", "text": "+40 gold now", "type": "plain"},
	"charge": {"name": "Spare battery", "text": "+1 Restore charge", "type": "plain"},
	"shield": {"name": "Extra shield", "text": "+1 Conductor shield every wave", "type": "plain"},
	"killgold": {"name": "Bounty", "text": "+1 gold per kill for the run", "type": "plain"},
	"chain": {"name": "Chain snipe", "text": "Snipes jump to a second creep within 3 tiles for half damage", "type": "altering"},
	"slow_wave": {"name": "Undertow", "text": "Splash waves slow everything they hit for 1 s", "type": "altering"},
	"shatter": {"name": "Shatter", "text": "A freeze on an already frozen creep does x3", "type": "altering"},
	"rally": {"name": "Rally", "text": "A parried pulse is returned by every tower near the elite", "type": "altering"},
	"long_cres": {"name": "Encore", "text": "Crescendo lasts 9 s instead of 6", "type": "altering"},
	"cond_perfects": {"name": "Sharpshooter", "text": "Perfect snipes do x12 instead of x8", "type": "conditional", "condition": "land 6 Perfects next wave"},
	"cond_parry": {"name": "Iron rhythm", "text": "One Restore a wave costs no charge", "type": "conditional", "condition": "let no pulse, arrow or bolt land next wave"},
	"cond_shield": {"name": "Bulwark", "text": "+1 Conductor shield every wave", "type": "conditional", "condition": "lose no shield next wave"},
}

var drafting := false
var draft: Array[String] = []  # Card ids on offer.
var taken: Array[String] = []  # Altering and conditional ids used this run.
var picks: Array[String] = []  # Every pick, for the run screen.
var pending: Dictionary = {}  # A locked pick waiting on next wave: id, wave.
var _base := {}  # Stats at the start of the wave, to judge a condition.
var rng := RandomNumberGenerator.new()
var stomps: Array[Dictionary] = []  # from, at, pos, state (flying/parried/hit), told, ticked
var _string_count := 0
var run_time := 0.0
var gold_earned := 0
var _last_gold := 0
var m6_stats := {"stomps": 0, "stomp_parries": 0, "stomp_hits": 0, "unlocked": 0, "lost": 0}


var hud: Hud


func _ready() -> void:
	super._ready()
	title = "M6 The run"
	rng.randomize()
	_last_gold = gold
	hud_left = 150.0
	hud = Hud.new(self)
	add_child(hud)


func toggle_pause() -> void:
	if state != "playing":
		return
	paused = not paused
	clock.set_paused(paused)
	_show_feedback("PAUSED" if paused else "", Color(1, 1, 1, 0.7))


## The run screen's lines; the HUD shows them.
func run_lines() -> Array[String]:
	var won := state == "won"
	return [
		"RUN COMPLETE   the Conductor stands" if won else "RUN OVER   the Conductor fell on wave %d" % wave,
		"Time %d:%02d   Health %d/%d   Gold earned %d" % [int(run_time) / 60, int(run_time) % 60, health, START_HEALTH, gold_earned],
		"Notes %d hit of %d (%d%%)   Perfects %d" % [stat_total("hits"), stat_total("notes"), int(100.0 * stat_total("hits") / maxi(stat_total("notes"), 1)), stat_total("perfects")],
		"Parries %d of %d   Towers locked %d   Shields lost %d   Restores %d" % [m4_stats["parried"] + m5_stats["parries"], m4_stats["pulses"] + m4_stats["arrows"] + m5_stats["bolts"] + m6_stats["stomps"], m4_stats["suppressed"], m4_stats["shields_lost"], m4_stats["restores"]],
		"Boss: %d bolts, %d stomps, %d breaks" % [m5_stats["bolts"], m6_stats["stomps"], m5_stats["breaks"]],
		"Picks: %s" % (", ".join(picks.map(func(id): return CARDS[id]["name"])) if not picks.is_empty() else "none"),
	]


func reset() -> void:
	super.reset()
	if paused:
		paused = false
		clock.set_paused(false)
	selected_cell = Vector2i(-1, -1)
	drafting = false
	draft.clear()
	taken.clear()
	picks.clear()
	pending = {}
	stomps.clear()
	mods = {}
	snipe_perfect_mult = SNIPE_PERFECT
	shield_cap = SHIELDS
	crescendo_seconds = CRESCENDO_SECONDS
	run_time = 0.0
	gold_earned = 0
	_last_gold = gold
	_string_count = 0
	m6_stats = {"stomps": 0, "stomp_parries": 0, "stomp_hits": 0, "unlocked": 0, "lost": 0}


# --- The run ---------------------------------------------------------------------

func start_wave() -> void:
	if drafting:
		_show_feedback("Pick a card first (1, 2 or 3)", Color(1, 1, 1, 0.6))
		return
	var was_active := wave_active
	super.start_wave()
	if wave_active and not was_active:
		_base = {"perfects": stat_total("perfects"), "landed": m4_stats["suppressed"] + m4_stats["shields_lost"] + m5_stats["hits"] + m6_stats["stomp_hits"], "shields": m4_stats["shields_lost"]}
		if wave == 1:
			run_time = 0.0


func step(delta: float) -> void:
	var was_active := wave_active
	super.step(delta)
	if wave_active or was_active:
		run_time += delta
	if gold > _last_gold:
		gold_earned += gold - _last_gold
	_last_gold = gold
	if was_active and not wave_active and state == "playing":
		_judge_pending()
		if wave < LAST_WAVE:
			_open_draft()
	# Stomps: ticks, the tell, and the slam if nobody parried.
	for st in stomps:
		if st["state"] != "flying":
			continue
		var beat := clock.beat_length()
		var beat_index := floori((beat_time() - st["from"]) / beat)
		if beat_index > st["ticked"] and beat_time() < st["at"] - PULSE_TELL_BEATS * beat:
			st["ticked"] = beat_index
			_sfx["tick"].play()
		if not st["told"] and beat_time() >= st["at"] - PULSE_TELL_BEATS * beat:
			st["told"] = true
			_sfx["tell"].play()
		if press_time() > st["at"] + Timing.PARRY_GOOD_MS / 1000.0:
			_stomp_lands(st)
			on_streak_miss()
	var keep: Array[Dictionary] = []
	for st in stomps:
		if st["at"] > beat_time() - 0.5:
			keep.append(st)
	stomps = keep


## The locked pick from last draft: did the wave meet its condition?
func _judge_pending() -> void:
	if pending.is_empty() or pending["wave"] != wave:
		return
	var id: String = pending["id"]
	pending = {}
	var ok := false
	match id:
		"cond_perfects":
			ok = stat_total("perfects") - _base["perfects"] >= 6
		"cond_parry":
			ok = m4_stats["suppressed"] + m4_stats["shields_lost"] + m5_stats["hits"] + m6_stats["stomp_hits"] - _base["landed"] == 0
		"cond_shield":
			ok = m4_stats["shields_lost"] - _base["shields"] == 0
	if ok:
		_apply(id)
		m6_stats["unlocked"] += 1
		_show_feedback("UNLOCKED   %s: %s" % [CARDS[id]["name"], CARDS[id]["text"]], Color(1.0, 0.9, 0.3))
	else:
		m6_stats["lost"] += 1
		_show_feedback("%s stays locked (%s)" % [CARDS[id]["name"], CARDS[id]["condition"]], Color(1, 0.5, 0.4))


func _open_draft() -> void:
	var plain: Array[String] = []
	var altering: Array[String] = []
	var conditional: Array[String] = []
	for id in CARDS:
		match CARDS[id]["type"]:
			"plain":
				plain.append(id)
			"altering":
				if not taken.has(id):
					altering.append(id)
			"conditional":
				if not taken.has(id) and pending.is_empty():
					conditional.append(id)
	draft.clear()
	draft.append(plain[rng.randi() % plain.size()])
	if not altering.is_empty():
		draft.append(altering[rng.randi() % altering.size()])
	if not conditional.is_empty() and rng.randf() < 0.6:
		draft.append(conditional[rng.randi() % conditional.size()])
	while draft.size() < 3:
		var id: String = plain[rng.randi() % plain.size()]
		if not draft.has(id):
			draft.append(id)
	draft.shuffle()
	drafting = true


func _pick(i: int) -> void:
	if not drafting or i < 0 or i >= draft.size():
		return
	var id := draft[i]
	drafting = false
	picks.append(id)
	var card: Dictionary = CARDS[id]
	if card["type"] == "conditional":
		taken.append(id)
		pending = {"id": id, "wave": wave + 1}
		_show_feedback("LOCKED PICK   %s: %s" % [card["name"], card["condition"]], Color(0.8, 0.8, 1.0))
		return
	if card["type"] == "altering":
		taken.append(id)
	_apply(id)
	_show_feedback("PICKED   %s: %s" % [card["name"], card["text"]], Color(1.0, 0.9, 0.3))


func _apply(id: String) -> void:
	match id:
		"gold":
			gold += 40
		"charge":
			restore_charges = mini(RESTORE_CHARGES + 1, restore_charges + 1)
		"shield", "cond_shield":
			shield_cap += 1
		"killgold":
			kill_gold += 1
		"chain", "slow_wave", "shatter", "rally":
			mods[id] = true
		"long_cres":
			crescendo_seconds = 9.0
		"cond_perfects":
			snipe_perfect_mult = 12.0
		"cond_parry":
			mods["refund"] = true


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if drafting and [KEY_1, KEY_2, KEY_3].has(event.keycode):
			_pick([KEY_1, KEY_2, KEY_3].find(event.keycode))
			return
		if event.keycode == KEY_P:
			toggle_pause()
			return
		if event.keycode == KEY_U and structures.has(selected_cell) and state == "playing":
			upgrade(selected_cell)
			return
	if paused and not (event is InputEventKey and event.keycode == KEY_ESCAPE):
		return
	# Left click on a tower or wall selects it for the panel; elsewhere it builds.
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and state == "playing":
		var cell := cell_at(event.position)
		if structures.has(cell):
			selected_cell = cell
			return
		if _on_board(event.position):
			selected_cell = Vector2i(-1, -1)
	super._unhandled_input(event)


# --- The second boss -------------------------------------------------------------

func boss2() -> bool:
	return boss_alive() and boss.get("second", false)


func _summon_boss() -> void:
	var had := boss_alive()
	super._summon_boss()
	if boss_alive() and not had and wave >= BOSS2_WAVE:
		boss["second"] = true
		_string_count = 0
		_show_feedback("THE SECOND BOSS   it stomps the maze and volleys the Conductor", Color(0.8, 0.5, 1.0))


func tempo_mult() -> float:
	var m := super.tempo_mult()
	if boss2() and m5_stats["breaks"] >= DOUBLE_TIME_BREAKS:
		m = maxf(m * 0.5, 0.25)
	return m


## Boss 2 alternates: a Volley at the Conductor, then a Stomp at the maze.
func _call_string(bar: int) -> void:
	if not boss2():
		super._call_string(bar)
		return
	var beat := clock.beat_length()
	var start := bar * clock.bar_length() + STRING_LEAD_BEATS * beat
	var mult := tempo_mult()
	_string_count += 1
	var last := start
	if _string_count % 2 == 1:
		var grid_len := step_length()
		for off in VOLLEY:
			var launch: float = start + off * mult * beat
			var travel := clampf(boss_path_left() / BOLT_SPEED, BOLT_MIN_TRAVEL, BOLT_MAX_TRAVEL)
			var arrive := ceilf((launch + travel) / grid_len - 0.001) * grid_len
			bolts.append({"launch": launch, "arrive": arrive, "from": boss["pos"], "state": "flying", "told": false})
			m5_stats["bolts"] += 1
			last = arrive
	else:
		# The stomp winds up over a bar (half a bar at double-time) and lands on a downbeat.
		var wind := clock.bar_length() * (0.5 if mult <= 0.5 else 1.0)
		var at := ceilf((start + wind) / clock.bar_length() - 0.001) * clock.bar_length()
		stomps.append({"from": at - wind, "at": at, "pos": boss["pos"], "state": "flying", "told": false, "ticked": -1})
		m6_stats["stomps"] += 1
		last = at
	var rest_bars := 2 if mult >= 2.0 else (1 if mult >= 1.0 else 0)
	_next_string_bar = ceili(last / clock.bar_length()) + rest_bars


func _stomp_targets(pos: Vector2) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for cell in structures:
		if builds[structures[cell]["type"]].has("range") and Vector2(cell).distance_to(pos) <= STOMP_RADIUS:
			out.append(cell)
	return out


func _stomp_lands(st: Dictionary) -> void:
	st["state"] = "hit"
	m6_stats["stomp_hits"] += 1
	_sfx["suppress"].play()
	_shockwaves.append({"pos": st["pos"], "ttl": 0.6, "color": Color(0.9, 0.2, 0.3)})
	var n := _lock_towers(_stomp_targets(st["pos"]))
	_show_feedback("STOMP   %d tower%s locked" % [n, "" if n == 1 else "s"] if n > 0 else "STOMP   nothing in reach", Color(1, 0.5, 0.4))


func _parry_candidates() -> Array[Dictionary]:
	var out := super._parry_candidates()
	for st in stomps:
		if st["state"] == "flying":
			out.append({"time": st["at"], "kind": "stomp", "ref": st})
	return out


func _resolve_parry(cand: Dictionary, g: String, offset_ms: float) -> void:
	if cand["kind"] != "stomp":
		super._resolve_parry(cand, g, offset_ms)
		return
	var st: Dictionary = cand["ref"]
	st["state"] = "parried"
	var perfect := g == "Perfect"
	m6_stats["stomp_parries"] += 1
	m5_stats["parries"] += 1
	if perfect:
		m5_stats["perfect"] += 1
	if boss_alive():
		# The maze answers: every tower in the stomp's reach fires back at the boss.
		var cells := _stomp_targets(st["pos"])
		var dmg := PARRY_DAMAGE * (2.0 if perfect else 1.0)
		for cell in cells:
			dmg += tower_spec(cell)["damage"] * 3.0 * (2.0 if perfect else 1.0)
			_flashes[cell] = 0.3
			shots.append({"from": Vector2(cell), "to": boss["pos"], "color": Color(1.0, 0.9, 0.3), "ttl": 0.35, "splash": 0.0, "width": 2.5})
		boss["hp"] -= dmg
		_popup(boss["pos"], ("%d!" if perfect else "%d") % roundi(dmg), Color(1.0, 0.9, 0.3) if perfect else Color.WHITE, 20 if perfect else 15)
		posture += POSTURE_PERFECT if perfect else POSTURE_GOOD
		if posture >= POSTURE_MAX:
			_posture_break()
	_shockwaves.append({"pos": st["pos"], "ttl": 0.4, "color": Color(1.0, 0.9, 0.3)})
	_show_feedback("%sPARRY  %+.0f ms   stomp turned" % ["PERFECT " if perfect else "", offset_ms], Color(1.0, 0.9, 0.3) if perfect else Color.WHITE)


func _posture_break() -> void:
	super._posture_break()
	stomps.clear()


# --- Drawing ---------------------------------------------------------------------

func _draw() -> void:
	super._draw()
	var font := ThemeDB.fallback_font
	var beat := clock.beat_length()

	# Boss 2: a violet crown so it reads as a different boss.
	if boss2():
		var p := _to_screen(boss["pos"])
		draw_arc(p, TILE * 0.75, 0, TAU, 48, Color(0.75, 0.45, 1.0), 3.0)
		draw_polyline(PackedVector2Array([p + Vector2(-14, -TILE * 0.8), p + Vector2(-8, -TILE * 1.1), p + Vector2(0, -TILE * 0.85), p + Vector2(8, -TILE * 1.1), p + Vector2(14, -TILE * 0.8)]), Color(0.85, 0.6, 1.0), 2.5)

	# Stomps: a ring grows on the ground under the boss over the bar, pips count
	# the beats, towers in reach glow. Space on the downbeat.
	for st in stomps:
		if st["state"] != "flying":
			continue
		var sp := _to_screen(st["pos"])
		var frac: float = clampf((beat_time() - st["from"]) / maxf(st["at"] - st["from"], 0.01), 0.0, 1.0)
		var last: bool = st["told"]
		var beats_gone := clampi(floori((beat_time() - st["from"]) / beat), 0, 4)
		draw_circle(sp, STOMP_RADIUS * TILE * frac, Color(0.9, 0.3, 0.5, 0.12 + 0.15 * frac))
		draw_arc(sp, STOMP_RADIUS * TILE * frac, 0, TAU, 48, Color(1, 0.35, 0.5, 0.4 + 0.6 * frac), 2.0 + 3.0 * frac)
		draw_arc(sp, STOMP_RADIUS * TILE, 0, TAU, 48, Color(1, 0.35, 0.5, 0.9 if last else 0.4), 3.5 if last else 1.5)
		for i in 4:
			var pip := sp + Vector2(-15 + i * 10, -TILE * 1.0)
			draw_circle(pip, 3.5, Color(1, 0.35, 0.5) if i < beats_gone else Color(1, 1, 1, 0.25))
		for cell in _stomp_targets(st["pos"]):
			draw_arc(_to_screen(Vector2(cell)), TILE * 0.5, 0, TAU, 32, Color(1, 0.35, 0.5, 0.5 + 0.5 * frac), 2.0)

func status_lines() -> Array[String]:
	var lines := super.status_lines()
	var extra := "Picks %d" % picks.size()
	if not pending.is_empty():
		extra += "   locked: %s (%s)" % [CARDS[pending["id"]]["name"], CARDS[pending["id"]]["condition"]]
	if boss2():
		extra += "   Stomps %d parried %d landed %d" % [m6_stats["stomps"], m6_stats["stomp_parries"], m6_stats["stomp_hits"]]
	lines.append(extra)
	return lines


## The buttons carry the build and action help now; keep the keys that have none.
func help_lines() -> Array[String]:
	if selected_cell.x >= 0:
		return []  # The tower panel sits where these go.
	return [
		"Q / E  press the key shown on a tower as its ring lands",
		"Space  parry: a pulse on a tower, an arrow or bolt at the Conductor, a stomp on the ground",
		"Click a tower for its panel.  Right click sells.  Esc twice  menu",
		"",
		"TEST  T speed %dx   Y auto-send %s   G +100g   H skip   O boss   [ ] song" % [SPEEDS[speed_index], "ON" if auto_send else "off"],
		"Next wave: %s   (%.0f HP each)" % [wave_summary(wave + 1), creep_hp_at(wave + 1)],
	]
