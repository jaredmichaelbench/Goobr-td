class_name RunSim
extends M7Run
## Demo 1 (M9, D-0044): the M7 run as the rules only. It draws nothing: View3D
## reads its fields every frame and draws the board in 3D, Indicators draws the
## marks over it, and HudRTS is the interface. Rules, timing and balance are the
## M7 chain unchanged, so the bots and the run log still hold.

var view: Node  # View3D: turns a screen point into a board cell.


func _ready() -> void:
	super._ready()
	visible = false  # Nothing 2D on the board any more.
	title = "Quick run (10 waves)" if quick else "The run (20 waves)"
	clock._player.bus = "Music"
	for key in _sfx:
		_sfx[key].bus = "SFX"
	if Prefs.get_value("synth_notes"):
		_sfx["perfect"].stream = SynthVoices.perfect()
		_sfx["good"].stream = SynthVoices.good()
		_sfx["miss"].stream = SynthVoices.miss()


func make_hud() -> Hud:
	return HudRTS.new(self)


## The board is under a 3D camera now: a screen point becomes a cell by a ray to
## the ground.
func cell_at(screen_pos: Vector2) -> Vector2i:
	if view != null:
		return view.cell_from_screen(screen_pos)
	return super.cell_at(screen_pos)


func _on_board(p: Vector2) -> bool:
	return grid.in_bounds(cell_at(p))


func _draw() -> void:
	pass


## The screen punch moved to the camera (View3D reads _punch); keep the node still.
func _tick_effects(delta: float) -> void:
	super._tick_effects(delta)
	position = Vector2.ZERO


## Esc closes the talent tree first, then leaves for the title screen after a
## confirm. The tree no longer pauses (D-0046), so every key but Tab and Esc
## plays on while it is open: Q, E and Space still land, P still pauses. L used to
## show the old timeline; the timeline is gone.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if tree_open:
				tree_open = false
				return
			if _esc_time > 0.0:
				get_tree().paused = false
				get_tree().change_scene_to_file("res://menu.tscn")
			else:
				_esc_time = ESC_CONFIRM_TIME
				_say("Press Esc again to leave the run")
			return
		if event.keycode == KEY_L:
			return
		if tree_open and event.keycode != KEY_TAB:
			tree_open = false
			super._unhandled_input(event)
			tree_open = true
			return
	super._unhandled_input(event)


## The talent tree is a panel over a live run, WC3 style: the music and the run go on.
func toggle_tree() -> void:
	if state != "playing":
		return
	tree_open = not tree_open


## One ring per tower (D-0043, tightened by D-0046): a note never lands on a
## tower that holds a ring coming, open, or finished within the last beat, and
## steers away from a tower whose neighbour (within 1.5 tiles) holds one. Notes
## hit across the whole board, so where the ring sits changes nothing but
## readability. When every tower is taken it falls back to the tower whose ring
## is furthest away in time. A call's notes all take their towers together, so
## the sequence can be read before it plays.
const NOTE_SPACING := 1.5

func _assign_note(n: Dictionary) -> void:
	_assign_one(n)
	if not n.has("seq") or n["tower"] == Vector2i(-1, -1):
		return
	var rest: Array[Dictionary] = []
	for m in notes:
		if m != n and m.get("seq", -1) == n["seq"] and m["state"] == "open" and m["tower"] == null:
			rest.append(m)
	rest.sort_custom(func(a, b): return a["time"] < b["time"])
	for m in rest:
		_assign_one(m)


func _assign_one(n: Dictionary) -> void:
	var best := Vector2i(-1, -1)
	var best_score := -INF
	var lead_creep := _lead_creep()
	var bt := beat_time()
	var beat := clock.beat_length()
	var taken := {}  # cell -> the smallest time gap to another note there
	for other in notes:
		if other == n or not (other["tower"] is Vector2i):
			continue
		var live: bool = other["state"] == "open" or (other["state"] in ["hit", "missed"] and other["time"] > bt - beat)
		if live:
			taken[other["tower"]] = minf(taken.get(other["tower"], INF), absf(other["time"] - n["time"]))
	for cell in structures:
		var type: String = structures[cell]["type"]
		if not builds[type].has("range") or not tower_ready(cell):
			continue
		var score := 0.0
		if taken.has(cell):
			score -= 1000.0 - minf(taken[cell], 8.0) * 50.0
		else:
			for b in taken:
				if Vector2(b).distance_to(Vector2(cell)) <= NOTE_SPACING:
					score -= 500.0
					break
		var near := 0.0
		for c in creeps:
			if c["hp"] > 0.0 and c["pos"].distance_to(Vector2(cell)) <= tower_spec(cell)["range"] + 1.0:
				near += 1.0 + 0.25 * _coverage(c["pos"])
		score += minf(near, 100.0)
		if near <= 0.0 and not lead_creep.is_empty():
			score -= lead_creep["pos"].distance_to(Vector2(cell)) * 0.01
		if score > best_score:
			best_score = score
			best = cell
	n["tower"] = best


## A fresh install starts on the first real song (the playlist plays on from
## there), not the synth stems; a saved choice from [ ] still wins.
func _load_song_choice() -> String:
	var want := super._load_song_choice()
	if want == "" and songs.size() > 1:
		return songs[1]["name"]
	return want


## The readability pass (D-0045): the line under the beat bar is one short word
## (PERFECT, GOOD, MISS, PARRY) and the timing as a small "51 ms early"; the long
## breakdown (damage, crossfire, veils) is kept in feedback_detail for the log.
var feedback_ms := ""
var feedback_detail := ""
var _ms_re: RegEx


func _show_feedback(text: String, color: Color) -> void:
	super._show_feedback(text, color)
	feedback_detail = text
	if _ms_re == null:
		_ms_re = RegEx.new()
		_ms_re.compile("([+-]\\d+) ms")
	feedback_ms = ""
	var m := _ms_re.search(text)
	if m != null:
		var ms := int(m.get_string(1))
		feedback_ms = "on the beat" if absi(ms) < 8 else ("%d ms %s" % [absi(ms), "early" if ms < 0 else "late"])
	_feedback = short_feedback(text)


static func short_feedback(text: String) -> String:
	var up := text.to_upper()
	if up.contains("COUNTER LATE"):
		return "COUNTER LATE"
	if up.contains("PARRY") and not up.begins_with("NOTHING"):
		return "PERFECT PARRY" if up.begins_with("PERFECT") else "PARRY"
	var crit := "CRIT " if up.begins_with("CRIT") else ""
	for g in ["PERFECT", "GOOD"]:
		if up.contains(" " + g + " ") or up.contains("  " + g):
			return crit + g
	if up.begins_with("MISS"):
		return "MISS"
	return text.split("   ")[0]


# --- Demo 1 round 2 (D-0046): calls, staggers, a tougher run --------------------------

## Notes come as a short call once every four bars, then three bars of rest where
## towers fire and parries happen (Jared: "sequence, nail it, pause"). The tempo
## never rises; the shape of the call does. Each string is one bar of 8th-note
## steps; step 0 (beat 1) stays free for elite throws.
const CALL_BARS := 4
const CALLS := {
	1: ["..Q.E...", "..Q...E."],
	2: ["..Q.E.Q.", "..Q.Q.E.", "..E.Q.E.", "..Q.E.E."],
	3: ["..Q.EEQ.", "..QQE.E.", "..E.Q.QE", "..Q.E.QQ", ".QE.Q.E."],
	4: [".QE.Q.EQ", "..EQ.QE.", "..QE.EQ.", ".E.QE.Q.", "..E.EQ.Q", "..QEQ.E."],
}
## A parried elite staggers and plays one of these, the boss feeling in short.
## The elite holds until it ends; nailing it lands the finisher on that elite.
const STAGGERS := {
	1: ["Q.E.Q.E."],
	2: ["Q.E.Q.E.", "Q.Q.E.E.", "E.Q.E.Q."],
	3: ["Q.EQ.E..", "QE..Q.E.", "Q.E.QQE."],
	4: ["QE.QE.Q.", "Q.EEQ.E.", "E.QQ.EQ."],
}
const FINISHER_PER_NOTE := 2.0  # The finisher: the strongest tower's damage x this x notes in the call.
const FINISHER_SPLASH := 1.5
## The tougher run (D-0046): more creeps, spaced wider, with more health, and
## bosses that need two or three staggers. Tuned with the balance bot.
const CREEP_HP_D1 := 48.0
const CREEP_HP_GROWTH_D1 := 1.17
const COUNT_MULT := 1.5
const GAP_MULT := 1.25
const BOSS_HP_EXTRA := 1.0  # Plus BOSS_HP_PER_WAVE a wave: x1.3 at wave 5, x2.2 at 20.
const BOSS_HP_PER_WAVE := 0.06

## Balance bot only: play the run as it was before D-0046 (M7's flow, old numbers).
static var legacy := false
var _call_origin := 0
var _seq_next := 1
var _seqs := {}  # id -> {missed, target (a creep or empty), size, stagger}
var _stagger_until := -1.0  # Beat time the current elite stagger ends.
var phrase_stats := {"calls": 0, "nailed": 0, "staggers": 0}
var level_ups := 0  # Counts up on every level; the HUD nudges the Talents button.
var _sfx_phrase: AudioStreamPlayer
var _sfx_level: AudioStreamPlayer


func _enter_tree() -> void:
	_sfx_phrase = AudioStreamPlayer.new()
	_sfx_phrase.stream = SynthVoices.phrase()
	_sfx_phrase.bus = "SFX"
	add_child(_sfx_phrase)
	_sfx_level = AudioStreamPlayer.new()
	_sfx_level.stream = SynthVoices.level_up()
	_sfx_level.bus = "SFX"
	add_child(_sfx_level)


func _reset_progression() -> void:
	super._reset_progression()
	if not legacy:
		creep_hp = CREEP_HP_D1
		creep_hp_growth = CREEP_HP_GROWTH_D1
	_seqs.clear()
	_stagger_until = -1.0
	phrase_stats = {"calls": 0, "nailed": 0, "staggers": 0}


func start_wave() -> void:
	if not wave_active:
		_call_origin = floori(beat_time() / clock.bar_length()) + 1
		_seqs.clear()
		_stagger_until = -1.0
	super.start_wave()


## More creeps a wave, spaced wider: waves last long enough to read (Jared:
## "the levels early just need to last longer"). Elites stay as written.
func wave_plan(w: int) -> Array[Dictionary]:
	var plan := super.wave_plan(w)
	if legacy:
		return plan
	var out: Array[Dictionary] = []
	var acc := 0.0
	for e in plan:
		var e2: Dictionary = e.duplicate()
		e2["gap"] = e["gap"] * GAP_MULT
		if ELITE_KINDS.has(e["kind"]):
			out.append(e2)
			continue
		acc += COUNT_MULT
		while acc >= 1.0:
			out.append(e2)
			acc -= 1.0
	return out


## How many of a kind a written group brings in this run (the wave preview).
func group_count(kind: String, count: int) -> int:
	return count if ELITE_KINDS.has(kind) or legacy else roundi(count * COUNT_MULT)


func _summon_boss() -> void:
	var had := boss_alive()
	super._summon_boss()
	if boss_alive() and not had and not legacy:
		# Boss health is set against the old creep curve (M7: 30 HP, x1.15 a wave), so
		# the tougher creeps don't stack on top of the boss's own multiplier.
		var old_hp: float = CREEP_HP_M7 * pow(CREEP_HP_GROWTH_M7, maxi(wave, 1) - 1)
		boss["hp"] *= old_hp / creep_hp_at(maxi(wave, 1)) * (BOSS_HP_EXTRA + BOSS_HP_PER_WAVE * wave)
		boss["max_hp"] = boss["hp"]


## Bosses keep M7's quiet chart and Crescendos. Other waves play one call per
## four bars, unless an elite's stagger holds the floor.
func _schedule_bar(bar: int) -> void:
	if boss_alive() or legacy:
		super._schedule_bar(bar)
		return
	if posmod(bar - _call_origin, CALL_BARS) != 0:
		return
	var bar_t := bar * STEPS_PER_BAR * step_length()
	if _stagger_until > bar_t - step_length():
		return
	var shapes: Array = CALLS[band(wave)]
	var shape: String = shapes[rng.randi() % shapes.size()]
	_add_sequence(bar_t, _with_extra(shape, int(gstats.get("note_rate", 0))), {}, false)


## Pulse (talent) and Virtuoso (card): an extra note in every call, on a free off-beat.
func _with_extra(shape: String, extra: int) -> String:
	var out := shape
	for i in extra:
		for step in [3, 5, 7, 1]:
			if out[step] == ".":
				out = out.substr(0, step) + ("Q" if i % 2 == 0 else "E") + out.substr(step + 1)
				break
	return out


func _add_sequence(t0: float, shape: String, target: Dictionary, stagger: bool) -> int:
	var id := _seq_next
	_seq_next += 1
	var size := 0
	for i in shape.length():
		var ch := shape[i]
		if ch == ".":
			continue
		add_note(t0 + i * step_length(), "kick" if ch == "Q" else "bass")
		notes[notes.size() - 1]["seq"] = id
		size += 1
	_seqs[id] = {"missed": false, "target": target, "size": size, "stagger": stagger}
	if stagger:
		phrase_stats["staggers"] += 1
	else:
		phrase_stats["calls"] += 1
	return id


## A parried elite staggers: it holds while its sequence plays, and a call that
## would overlap gives way. One stagger at a time; a second parried elite just holds.
func _stagger_notes(struck: Dictionary) -> void:
	if legacy:
		super._stagger_notes(struck)
		return
	_popup(struck["pos"], "STAGGER", Color(1.0, 0.9, 0.3), 13)
	if _stagger_until > beat_time() or boss_alive():
		return
	var beat := clock.beat_length()
	var step := step_length()
	var shapes: Array = STAGGERS[band(wave)]
	var shape: String = shapes[rng.randi() % shapes.size()]
	var t0 := (floorf(beat_time() / beat) + 2.0) * beat
	var t1 := t0 + shape.length() * step
	# Calls not shown yet give way; one already on the towers plays first.
	var drop := {}
	for m in notes:
		if m["state"] == "open" and m.has("seq") and m["time"] >= t0 - step and m["time"] <= t1 + step:
			if m["tower"] == null:
				drop[m["seq"]] = true
			else:
				t0 = maxf(t0, ceilf((m["time"] + beat) / beat) * beat)
	for m in notes.duplicate():
		if m["state"] == "open" and drop.has(m.get("seq", -1)) and m["tower"] == null:
			notes.erase(m)
			_wave_notes -= 1
			stats[m["type"]]["notes"] -= 1
	for id in drop:
		_seqs.erase(id)
		phrase_stats["calls"] -= 1
	t1 = t0 + shape.length() * step
	_stagger_until = t1
	struck["frozen_until"] = maxf(struck.get("frozen_until", 0.0), sim_time + (t1 - beat_time()) + beat)
	_add_sequence(t0, shape, struck, true)


func _on_miss(n: Dictionary) -> void:
	super._on_miss(n)
	if _seqs.has(n.get("seq", -1)):
		_seqs[n["seq"]]["missed"] = true


func _resonance(n: Dictionary, g: String, offset_ms: float) -> void:
	var before := notes.size()
	super._resonance(n, g, offset_ms)
	# A card's free echo note takes its own tower like any other (one ring per tower).
	for i in range(before, notes.size()):
		if notes[i]["state"] == "open":
			notes[i]["tower"] = null
	var id: int = n.get("seq", -1)
	if not _seqs.has(id) or _seqs[id]["missed"]:
		return
	for m in notes:
		if m.get("seq", -1) == id and m["state"] == "open":
			return
	_finisher(_seqs[id])
	_seqs.erase(id)


## Every note of a call landed: the Conductor fires one big shot (the "nail it").
func _finisher(s: Dictionary) -> void:
	phrase_stats["nailed"] += 1
	_sfx_phrase.play()
	var target: Dictionary = s["target"]
	if target.is_empty() or not creeps.has(target) or target["hp"] <= 0.0:
		target = _lead_creep()
	if target.is_empty():
		_show_feedback("PHRASE", UiTheme.GOLD)
		return
	var best := 0.0
	for cell in structures:
		var type: String = structures[cell]["type"]
		if is_tower(type) and type != "light":
			best = maxf(best, tower_spec(cell)["damage"])
	var dmg: float = best * damage_scale() * FINISHER_PER_NOTE * s["size"]
	var dealt := damage(target, dmg)
	for c in creeps:
		if c != target and c["hp"] > 0.0 and not c.get("boss", false) and c["pos"].distance_to(target["pos"]) <= FINISHER_SPLASH:
			dealt += damage(c, dmg * 0.5)
	shots.append({"from": Vector2(GOAL), "to": target["pos"], "color": UiTheme.GOLD, "ttl": 0.6, "splash": 0.0, "width": 6.0})
	_shockwaves.append({"pos": target["pos"], "ttl": 0.5, "color": UiTheme.GOLD})
	_bursts.append({"pos": target["pos"], "color": UiTheme.GOLD, "ttl": 0.5, "crit": true, "radius": FINISHER_SPLASH})
	_popup(target["pos"], "PHRASE %d" % roundi(dealt), UiTheme.GOLD, 22)
	_punch = PUNCH_SECONDS * 1.5
	_show_feedback("PHRASE   %d damage" % roundi(dealt), UiTheme.GOLD)


func gain_xp(amount: float) -> void:
	var before := level
	super.gain_xp(amount)
	if level > before:
		level_ups += level - before
		_sfx_level.play()


func run_lines() -> Array[String]:
	var lines := super.run_lines()
	lines.insert(mini(4, lines.size()), "Calls nailed %d of %d   Staggers %d" % [phrase_stats["nailed"], phrase_stats["calls"], phrase_stats["staggers"]])
	return lines
