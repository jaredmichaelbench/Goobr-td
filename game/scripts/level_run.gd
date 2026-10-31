class_name LevelRun
extends RunSim
## The template level (L3, D-0048): one night is one song. The map is shown and
## nothing happens until Start level; then drumsticks count in (the build phase),
## the song starts from its first bar, and the sections of the level file play on
## the song's bars: pushes send creeps, lulls send nothing while the music calms,
## the finale can bring a field boss. When the song is over and the board is
## clear, the night is survived: one card, then the results. No Start wave
## button: the song is the clock. Rules, towers, calls and parries are RunSim's.
##
## The level file is plain text (game/levels/*.cfg) so Jared can choreograph
## levels without code. parse() reads it; the file itself explains the format.

static var active := false  # Set by the title screen: run3d builds a LevelRun.
static var level_path := "res://levels/night_life.cfg"

const LULL_CUTOFF := 650.0  # Hz: the low-pass a lull settles on.
const OPEN_CUTOFF := 20000.0
const LULL_DIP_DB := 3.0  # The song drops this much in a lull.
const LULL_FALL_BARS := 0.5  # The calm comes in over half a bar...
const LULL_LIFT_BARS := 1.0  # ...and lifts over the lull's last bar, into the push.
const STICK_GAIN := 0.5

var night := {}  # name, song, count, gold, sections, bars, problems (see parse()).
var started := false
var song_start := INF  # Beat time of the song's first bar.
var song_seconds := 0.0  # How long the song plays once through.
var section := -1  # Index of the section playing now.
var ending := false  # Song over and board clear: the card, then the results.
var _push_plan: Array[Dictionary] = []
var _pushing := false
var _level_stream: AudioStreamWAV
var _overtime_stream: AudioStreamWAV  # The finale on its own, looped once the song is over.
var _overtime := false
var _lowpass: AudioEffectLowPassFilter
var _booted := false
var _told := {}  # Watchman tips already said.
var _overtime_told := false
var _boss_due := -1.0  # Song bar a "boss at N" boss walks in on, or -1.
var _base_cost := {}  # Tower type -> its price with no towers built.
var _arp_db := -80.0
var _sweep := 0.0  # Seconds left of the posture-break filter sweep.
var _sfx_whoosh: AudioStreamPlayer
var _sfx_hit: AudioStreamPlayer
var _xp_start := {"level": 1, "xp": 0.0}  # Where XP stood when the night started.
var night_phase := ""  # "" during the night; "summary" (XP fill and talents), "card".
var misses: Array[Dictionary] = []  # One per missed note: why (none, early, late), ms, building, parry.
var _placed_at := -INF  # Beat time of the last tower or wall built.


# --- The level file ------------------------------------------------------------

## Reads a level file. Header lines are "key = value" (name, song, count, gold,
## price_step, reach, mine, asks); every other line is a section: name kind bars
## [tier] [what comes]. What comes is groups split by commas, each "kind count
## @beats" ("grunt 8 @2": eight grunts, one every two beats); "boss" (or "boss at
## 4", four bars in) brings a field boss; "quiet" means no calls in that push.
static func parse(text: String) -> Dictionary:
	var out := {"name": "Night", "song": "", "count": 2, "gold": 150, "price_step": 0.0, "reach": 0.0, "mine": 0.0, "asks": ["q", "e", "parry", "stagger", "counter"], "sections": [], "bars": 0, "problems": []}
	var bar := 0
	for raw in text.split("\n"):
		var line := raw.split(";")[0].strip_edges()
		if line == "":
			continue
		if line.contains("="):
			var kv := line.split("=", true, 1)
			var key := kv[0].strip_edges().to_lower()
			var value := kv[1].strip_edges()
			if key in ["count", "gold"]:
				out[key] = int(value)
			elif key in ["price_step", "reach", "mine"]:
				out[key] = float(value)
			elif key == "asks":
				out[key] = Array(value.to_lower().split(" ", false))
			else:
				out[key] = value
			continue
		var words := line.replace("\t", " ").split(" ", false)
		if words.size() < 3:
			out["problems"].append("Not a section: " + line)
			continue
		var kind := words[1].to_lower()
		if not kind in ["push", "lull", "finale"]:
			out["problems"].append("%s: kind must be push, lull or finale" % words[0])
			continue
		var s := {"name": words[0], "kind": kind, "bars": int(words[2]), "tier": 1, "start": bar, "groups": [], "boss": false, "boss_at": 0, "quiet": false}
		var rest_at := 3
		if words.size() > 3 and words[3].is_valid_int():
			s["tier"] = int(words[3])
			rest_at = 4
		elif kind == "lull" and not out["sections"].is_empty():
			s["tier"] = out["sections"][-1]["tier"]  # A lull's trickle is as strong as the push before it.
		var what := " ".join(words.slice(rest_at))
		for g in what.split(",", false):
			var parts := g.strip_edges().split(" ", false)
			if parts.is_empty():
				continue
			if parts[0] == "boss":
				s["boss"] = true
				if parts.size() >= 3 and parts[1] == "at":
					s["boss_at"] = int(parts[2])
				continue
			if parts[0] == "quiet":
				s["quiet"] = true
				continue
			var group := {"kind": parts[0], "count": 1, "gap": 2.0}
			for p in parts.slice(1):
				if p.begins_with("@"):
					group["gap"] = float(p.substr(1))
				elif p.is_valid_int():
					group["count"] = int(p)
			if not CREEP_KINDS.has(group["kind"]) and not ELITE_KINDS.has(group["kind"]):
				out["problems"].append("%s: no enemy called %s" % [s["name"], group["kind"]])
				continue
			s["groups"].append(group)
		if s["bars"] <= 0:
			out["problems"].append("%s: needs a number of bars" % s["name"])
			continue
		out["sections"].append(s)
		bar += s["bars"]
	out["bars"] = bar
	return out


static func load_file(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		var empty := parse("")
		empty["problems"].append("Level file missing: " + path)
		return empty
	return parse(f.get_as_text())


## Beats from the start of a push until its last creep is out.
func spawn_beats(s: Dictionary) -> float:
	var beats := 0.0
	for g in s["groups"]:
		beats += g["count"] * g["gap"]
	return beats


# --- Setup ---------------------------------------------------------------------

func _ready() -> void:
	night = load_file(level_path)
	super._ready()
	title = night["name"]
	boss_waves = []  # Bosses come from the file, not from wave numbers.
	bolt_damage = LEVEL_BOLT_DAMAGE
	last_wave = 1000000  # The night ends with the song, not on a wave count.
	gold = night["gold"]
	for t in builds:
		_base_cost[t] = builds[t]["cost"]
	if not asks("counter"):
		gstats["counter"] = false  # Taught on a later night.
	clock.set_stem_volume_db(stem_index["hat"], -80.0)
	stem_db["hat"] = -80.0
	# The streak layer for boss fights: an arp in E, silent until earned.
	stem_index["arp"] = clock.add_stem(_arp(clock.bar_length()), -80.0)
	_sfx_whoosh = _player(_whoosh(clock.beat_length()), -6.0)
	_sfx_hit = _player(StemSynth.thud(), 0.0)
	_level_stream = _build_level_stream()
	var bus := AudioServer.get_bus_index("Music")
	if bus >= 0:
		_lowpass = AudioEffectLowPassFilter.new()
		_lowpass.cutoff_hz = OPEN_CUTOFF
		AudioServer.add_bus_effect(bus, _lowpass)
	for p in night["problems"]:
		push_warning(p)
	if song_index == 0 and night["song"] != "":
		_watchman("Can't find %s in game/audio. Playing on the drum machine." % night["song"], 6.0)
	elif not night["problems"].is_empty():
		_watchman("The level file has a problem: " + night["problems"][0], 6.0)
	_booted = true


## Which asks this night makes: q, e, parry, stagger, counter (header "asks").
func asks(what: String) -> bool:
	return night["asks"].has(what)


func _player(stream: AudioStream, db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = db
	p.bus = "SFX"
	add_child(p)
	return p


func _exit_tree() -> void:
	var bus := AudioServer.get_bus_index("Music")
	if bus >= 0 and _lowpass != null:
		for i in AudioServer.get_bus_effect_count(bus):
			if AudioServer.get_bus_effect(bus, i) == _lowpass:
				AudioServer.remove_bus_effect(bus, i)
				break


## R after the night ends: the whole level again, from the map.
func reset() -> void:
	super.reset()
	if _booted:
		get_tree().reload_current_scene()


## The level's song, by file name, wins over the playlist choice.
func _load_song_choice() -> String:
	var want: String = night.get("song", "")
	if want == "":
		return super._load_song_choice()
	var re := RegEx.new()
	re.compile("^\\s*\\d+(?:\\.\\d+)?[\\s_.-]*(.*)\\.wav$")
	var m := re.search(want)
	return m.get_string(1) if m != null else want.trim_suffix(".wav")


## No song switching in a level: the song is the level.
func _switch_song(_delta_index: int) -> void:
	_say("The song is the level here")


func _tick_playlist() -> void:
	pass


## The count-off and the song as one stream, so the sticks and the first bar are
## exactly one bar apart. Stick hits: beats 1 and 3 in the first bars, then all
## four ("1 . 2 . 1 2 3 4"). With no song file it is the sticks and then silence.
## Also builds the overtime loop: the finale's bars on their own, padded to whole
## bars, which takes over when the song ends (a loop that starts mid-file would
## confuse the clock, which counts wraps from the start).
func _build_level_stream() -> AudioStreamWAV:
	var bar := clock.bar_length()
	var song: AudioStreamWAV = null
	if song_index > 0:
		song = AudioFiles.load_wav(songs[song_index]["path"])
		if song != null and song.format != AudioStreamWAV.FORMAT_16_BITS:
			push_warning("Level song is not 16-bit; the count-off plays without it")
			song = null
	var rate: int = song.mix_rate if song != null else BeatClock.MIX_RATE
	var channels := 2 if song != null and song.stereo else 1
	var count_frames := int(round(night["count"] * bar * rate))
	var data := PackedByteArray()
	data.resize(count_frames * channels * 2)
	var beat_frames := bar / 4.0 * rate
	for b in night["count"] * 4:
		var last_bar: bool = b >= (night["count"] - 1) * 4
		if not last_bar and b % 2 == 1:
			continue
		var start := int(round(b * beat_frames))
		var pitch := 2300.0 if b % 4 == 0 else 1800.0
		for i in int(rate * 0.09):
			var t := float(i) / rate
			var v := sin(TAU * pitch * t) * exp(-t * 55.0) + sin(TAU * pitch * 2.7 * t) * exp(-t * 120.0) * 0.4
			var s := int(clampf(v * STICK_GAIN, -1.0, 1.0) * 32767.0)
			for c in channels:
				data.encode_s16(((start + i) * channels + c) * 2, s)
	if song != null:
		song_seconds = song.get_length()
		data.append_array(song.data)
	else:
		song_seconds = night["bars"] * bar
		var silence := PackedByteArray()
		silence.resize(int(song_seconds * rate) * channels * 2)
		data.append_array(silence)
	var out := _wav(data, rate, channels)
	var last: Dictionary = night["sections"][-1] if not night["sections"].is_empty() else {"start": 0, "bars": 1}
	var bpf := channels * 2
	var from := (count_frames + int(round(last["start"] * bar * rate))) * bpf
	var loop := data.slice(mini(from, data.size()), mini(from + int(round(last["bars"] * bar * rate)) * bpf, data.size()))
	var want := int(round(last["bars"] * bar * rate)) * bpf
	if loop.size() < want:
		var pad := PackedByteArray()
		pad.resize(want - loop.size())
		loop.append_array(pad)
	_overtime_stream = _wav(loop, rate, channels)
	if absf(song_seconds / bar - night["bars"]) > 1.0:
		night["problems"].append("The sections add up to %d bars; the song is %.1f bars long" % [night["bars"], song_seconds / bar])
	return out


static func _wav(data: PackedByteArray, rate: int, channels: int) -> AudioStreamWAV:
	var out := AudioStreamWAV.new()
	out.format = AudioStreamWAV.FORMAT_16_BITS
	out.mix_rate = rate
	out.stereo = channels == 2
	out.data = data
	out.loop_mode = AudioStreamWAV.LOOP_FORWARD
	out.loop_begin = 0
	out.loop_end = data.size() / (channels * 2)
	return out


# --- The night -------------------------------------------------------------------

## N and the play button: Start level once. After that the song sends the pushes.
func start_wave() -> void:
	if _pushing:
		super.start_wave()
		return
	if not started and state == "playing" and not drafting:
		_start_level()


func _start_level() -> void:
	started = true
	_xp_start = {"level": level, "xp": xp}
	clock.swap_stem(stem_index["hat"], _level_stream)
	song_start = clock._offset + night["count"] * clock.bar_length()
	_last_step = -1
	_watchman("Hey, I just work here. Walls and a tower by the camp, quick.", 4.0)


## Where the song is, in bars from its first bar (negative during the count).
func song_bar() -> float:
	if not started:
		return -INF
	return (beat_time() - song_start) / clock.bar_length()


func song_over() -> bool:
	return started and beat_time() >= song_start + song_seconds


func current_section() -> Dictionary:
	if section < 0 or section >= night["sections"].size():
		return {}
	return night["sections"][section]


## The next push the board will see: the one playing, or the one after a lull.
func next_push() -> Dictionary:
	var from := maxi(section, 0)
	if section >= 0 and current_section().get("kind", "") != "lull" and wave_active:
		from = section + 1
	for i in range(from, night["sections"].size()):
		if night["sections"][i]["kind"] != "lull":
			return night["sections"][i]
	return {}


func step(delta: float) -> void:
	super.step(delta)
	if not started or state != "playing":
		return
	var b := song_bar()
	while section + 1 < night["sections"].size() and b >= night["sections"][section + 1]["start"]:
		_log_section()
		section += 1
		_section_base = _totals()
		_section_base["health"] = health
		_section_base["boss"] = false
		_section_base["resolved"] = _resolved_notes()
		_enter_section(night["sections"][section])
	if _boss_due >= 0.0 and b >= _boss_due:
		_boss_due = -1.0
		_boss_enters()
	_tick_boss_threat()
	if boss_alive() and not _section_base.is_empty():
		_section_base["boss"] = true
	_sweep = maxf(0.0, _sweep - delta)
	var s := current_section()
	if s.get("kind", "") == "lull" and not _told.has("lift") and b >= s["start"] + s["bars"] - 1.0 and section + 1 < night["sections"].size():
		_told["lift"] = true
		_watchman("Hear the drums? Here they come again.", 3.0)
	if not song_over():
		return
	if not _overtime:
		# The song is over: the finale loops on (quieter once the night is won).
		_overtime = true
		clock.swap_stem(stem_index["hat"], _overtime_stream)
		_last_step = -1
	if not spawn_queue.is_empty() or not creeps.is_empty() or boss_alive() or not _escort_queue.is_empty():
		if not _overtime_told:
			_overtime_told = true
			_watchman("Song's over. They aren't. Finish them.", 4.0)
		return
	if not ending:
		_finish()


func _enter_section(s: Dictionary) -> void:
	if s["kind"] == "lull":
		if not _told.has("lull"):
			_told["lull"] = true
			_watchman("Quiet. Build while it lasts.", 3.5)
		if s["groups"].is_empty():
			return
		# A lull can carry a light trickle (v3, D-0052): it spawns like a push
		# but keeps the lull's calm music and its quiet chart.
	_push_plan.clear()
	var beat := clock.beat_length()
	for g in s["groups"]:
		for i in g["count"]:
			_push_plan.append({"kind": g["kind"], "gap": g["gap"] * beat})
	if wave_active:
		# The last push is still on the board: this one joins it.
		wave = s["tier"]
		spawn_queue.append_array(_push_plan)
		_to_spawn = spawn_queue.size()
	else:
		wave = s["tier"] - 1
		_pushing = true
		start_wave()
		_pushing = false
	if s["boss"]:
		if s["boss_at"] > 0:
			_boss_due = s["start"] + s["boss_at"]
		else:
			_boss_enters()


func _boss_enters() -> void:
	# The boss is as strong as the night's hardest push, whichever section it walks in on.
	var keep := wave
	for s in night["sections"]:
		wave = maxi(wave, s["tier"])
	_summon_boss()
	wave = keep
	if not _told.has("boss"):
		_told["boss"] = true
		_watchman("That one's big. Not my department.", 3.5)


## Live notes (v3.1, D-0053): a note shows, and picks its tower, only when its
## ring starts two beats out. The rest of its call is not shown ahead.
func _assign_note(n: Dictionary) -> void:
	_assign_one(n)


## A push sends exactly what the file says (no run multipliers).
func wave_plan(_w: int) -> Array[Dictionary]:
	return _push_plan.duplicate()


func wants_draft() -> bool:
	return false


func _wave_cleared() -> void:
	super._wave_cleared()
	var s := current_section()
	if not s.is_empty():
		_show_feedback("%s CLEARED" % s["name"].to_upper(), Color(1.0, 0.9, 0.3))


## The wave-clear card's title.
func clear_title() -> String:
	var s := current_section()
	return ("%s CLEARED" % s["name"].to_upper()) if not s.is_empty() else "CLEARED"


## Morning: the XP earned fills up on the end screen, talents are spent there
## (Jared: out of the level, so nobody juggles building and spending), then the card.
func _finish() -> void:
	_log_section()
	ending = true
	night_phase = "summary"
	_held_level_ups = 0
	tree_open = false
	_watchman("Made it to morning. Hey, I just work here.", 4.0)


## The end screen's Continue: the card, then the results.
func begin_card() -> void:
	if night_phase != "summary":
		return
	tree_open = false
	night_phase = "card"
	_open_draft()
	if not drafting:
		state = "won"


func xp_start() -> Dictionary:
	return _xp_start


## Level-ups stay silent during the night; the end screen plays them.
func _announce_levels() -> void:
	pass


## Talents are for after the night; before Start, Tab brings the start panel back.
func toggle_tree() -> void:
	if not started:
		if hud != null and hud.has_method("show_start"):
			hud.show_start()
		return
	if night_phase != "summary":
		_say("Talents are spent after the night")
		return
	tree_open = not tree_open


func _pick(i: int) -> void:
	super._pick(i)
	if ending and not drafting:
		state = "won"


## Nothing is built before Start level: the count-off is the build phase. The
## camp grows outward (D-0051): a cell within reach of the keep or of anything
## built, never near the mine. Each tower on the board makes the next one dearer.
func try_place(cell: Vector2i, type: String) -> bool:
	if not started:
		_say("N or the play button starts the night; build during the count-off")
		return false
	if not structures.has(cell) and not in_reach(cell):
		_say("Too far from the camp: build near the keep or what you have built" if not near_mine(cell) else "Too close to the mine")
		return false
	var cost: int = builds[type]["cost"] if builds.has(type) else 0
	var ok := false
	if wall_swap(cell, type):
		ok = _build_on_wall(cell, type)
	else:
		ok = super.try_place(cell, type)
	if ok:
		_placed_at = beat_time()
		if structures.has(cell) and type != "wall":
			structures[cell]["paid"] = cost
		_apply_prices()
	return ok


## A tower built on a wall replaces it (v3, D-0052): the wall's gold goes into
## the tower, like upgrading the wall, and the tile never stands empty.
func wall_swap(cell: Vector2i, type: String) -> bool:
	return structures.has(cell) and structures[cell]["type"] == "wall" and is_tower(type)


## What building `type` on `cell` costs after a wall's credit.
func build_cost_at(cell: Vector2i, type: String) -> int:
	var cost: int = builds[type]["cost"]
	return maxi(0, cost - builds["wall"]["cost"]) if wall_swap(cell, type) else cost


func _build_on_wall(cell: Vector2i, type: String) -> bool:
	var wall: Dictionary = structures[cell]
	var credit: int = builds["wall"]["cost"]
	structures.erase(cell)
	grid.blocked.erase(cell)
	grid.rebuild()
	gold += credit
	if super.try_place(cell, type):
		return true
	gold -= credit
	structures[cell] = wall
	grid.blocked[cell] = true
	grid.rebuild()
	return false


## A left click on a wall with a tower picked builds the tower there.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and state == "playing" and build_mode:
		var cell := cell_at(event.position)
		if wall_swap(cell, selected):
			try_place(cell, selected)
			get_viewport().set_input_as_handled()
			return
	super._unhandled_input(event)


func sell(cell: Vector2i) -> void:
	super.sell(cell)
	_apply_prices()


func near_mine(cell: Vector2i) -> bool:
	return night["mine"] > 0.0 and Vector2(cell).distance_to(Vector2(SPAWN)) <= night["mine"]


func in_reach(cell: Vector2i) -> bool:
	if near_mine(cell):
		return false
	var r: float = night["reach"]
	if r <= 0.0 or Vector2(cell).distance_to(Vector2(GOAL)) <= r:
		return true
	for c in structures:
		if Vector2(c).distance_to(Vector2(cell)) <= r:
			return true
	return false


func _apply_prices() -> void:
	var towers := 0
	for c in structures:
		if structures[c]["type"] != "wall":
			towers += 1
	for t in builds:
		if t != "wall" and _base_cost.has(t):
			builds[t]["cost"] = roundi(_base_cost[t] * (1.0 + night["price_step"] * towers))


# --- Asks --------------------------------------------------------------------------

## Night 1 asks less (D-0051): with no "e" every note is a Q; no "stagger" and a
## parried elite just takes the hit; "quiet" pushes and the count-off have no calls.
func _stagger_notes(struck: Dictionary) -> void:
	if asks("stagger"):
		super._stagger_notes(struck)


func _schedule_bar(bar: int) -> void:
	if not boss_alive() and started:
		# Look at the section the bar falls in, not the one playing now: the
		# chart is written two bars ahead. Lulls ask for no notes, even with a
		# trickle walking (v3, D-0052), and neither do quiet pushes.
		var sb := (bar * clock.bar_length() - song_start) / clock.bar_length()
		for s in night["sections"]:
			if sb >= s["start"] and sb < s["start"] + s["bars"]:
				if s["kind"] == "lull" or s["quiet"]:
					return
				break
	super._schedule_bar(bar)


# --- The miss log ------------------------------------------------------------------

## Why each note was missed (D-0051): no press, early or late (by how much), and
## whether a build or a parry was close. Printed in the run log.
func _play(key: Key) -> void:
	var type: String = KEY_TYPE.get(key, "")
	var near := {}
	var near_off := INF
	for n in notes:
		if n["type"] == type and n["tower"] is Vector2i and absf(press_time() - n["time"]) < near_off and n["state"] in ["open", "missed"]:
			near = n
			near_off = absf(press_time() - n["time"])
	super._play(key)
	if near.is_empty() or near_off > 0.3:
		return
	var off: float = (press_time() - near["time"]) * 1000.0
	if near["state"] == "open" and off < 0.0:
		near["early_ms"] = off  # Pressed too early; the note stayed open.
	elif near["state"] == "missed" and off > 0.0 and near.has("_miss"):
		var m: Dictionary = near["_miss"]
		if m["why"] == "none":
			m["why"] = "late"
			m["ms"] = off


func _on_miss(n: Dictionary) -> void:
	super._on_miss(n)
	if not started:
		return
	var m := {"why": "early" if n.has("early_ms") else "none", "ms": n.get("early_ms", 0.0),
		"building": beat_time() - _placed_at < 2.0, "parry": false, "boss": boss_alive()}
	for cand in _parry_candidates():
		if absf(cand["time"] - n["time"]) < clock.beat_length():
			m["parry"] = true
	n["_miss"] = m
	misses.append(m)


func miss_line() -> String:
	var c := {"none": 0, "early": 0, "late": 0}
	var ms := {"early": 0.0, "late": 0.0}
	var building := 0
	var parry := 0
	var boss_n := 0
	for m in misses:
		c[m["why"]] += 1
		if ms.has(m["why"]):
			ms[m["why"]] += absf(m["ms"])
		building += 1 if m["building"] else 0
		parry += 1 if m["parry"] else 0
		boss_n += 1 if m["boss"] else 0
	return "Misses %d: no press %d, early %d (avg %d ms), late %d (avg %d ms); while building %d, near a parry %d, in the boss fight %d" % [
		misses.size(), c["none"], c["early"], roundi(ms["early"] / maxi(c["early"], 1)), c["late"], roundi(ms["late"] / maxi(c["late"], 1)), building, parry, boss_n]


# --- The boss ------------------------------------------------------------------------

const BOSS_STRIDE_MAX := 4.0  # Tiles a second at most while striding.
const BOSS_FLIGHT_MIN_BEATS := 2  # A bolt is in the air at least this long, even at the camp.
const BOSS_FLIGHT_MAX_BEATS := 4
const BOSS_NOTE_GAP_BEATS := 1.0  # No note lands this close to a bolt.
const BOSS_REST_BARS := 2  # Walk bars between strings.
const LEVEL_BOLT_DAMAGE := 1  # A missed bolt costs 1 health in a level (v3.1), not 2.

var _throw_bar := -1
var section_log: Array[String] = []  # One run-log row per section played.
var _section_base := {}  # Totals when the current section began.  # The bar the boss stands still and throws in.

## v3 (D-0052): the boss has one readable pattern at every distance. On a walk
## bar it strides on beats 1 and 2 and plants on 3 and 4. On a throw bar it
## stands still the whole bar and launches one bolt on each beat; each flies a
## whole number of beats (2 to 4), so every bolt lands on a beat. After a
## string comes at least one walk bar (two when it is far away), so stopping
## always means "bolts are coming". Its pace still brings it to the camp as the
## song ends; frost holds it and it strides harder to catch up, up to a cap.
func _move_creeps(delta: float) -> void:
	if boss_alive() and not boss.get("at_goal", false):
		var beat := clock.beat_length()
		var bar := floori(beat_time() / clock.bar_length())
		var moving := bar != _throw_bar and posmod(floori(beat_time() / beat), 4) < 2
		var left := maxf(song_start + song_seconds - beat_time(), 0.0) * 0.35
		var want := boss_path_left() / maxf(left, 0.5)
		boss["speed"] = clampf(want, BOSS_SPEED, BOSS_STRIDE_MAX) if moving else 0.0
	super._move_creeps(delta)


func _call_string(bar: int) -> void:
	var beat := clock.beat_length()
	var start := bar * clock.bar_length()
	_throw_bar = bar
	var flight := clampi(ceili(boss_path_left() / BOLT_SPEED / beat - 0.001), BOSS_FLIGHT_MIN_BEATS, BOSS_FLIGHT_MAX_BEATS)
	var landings: Array[float] = []
	for i in 4:
		var launch := start + i * beat
		var arrive := launch + flight * beat
		bolts.append({"launch": launch, "arrive": arrive, "from": boss["pos"], "state": "flying", "told": false})
		m5_stats["bolts"] += 1
		landings.append(arrive)
	_clear_notes_near(landings)
	# Two walk bars after every string, near or far (v3.1, D-0053).
	_next_string_bar = bar + 1 + BOSS_REST_BARS


## Notes already on the board that would land within a beat of a bolt are
## taken back, so a note never sits on top of a parry.
func _clear_notes_near(landings: Array[float]) -> void:
	var gap := BOSS_NOTE_GAP_BEATS * clock.beat_length() - 0.001
	var keep: Array[Dictionary] = []
	for n in notes:
		var clash := false
		if n["state"] == "open":
			for t in landings:
				if absf(n["time"] - t) < gap:
					clash = true
					break
		if clash:
			stats[n["type"]]["notes"] -= 1
			_wave_notes -= 1
		else:
			keep.append(n)
	notes = keep


## Boss notes in a bar the boss will throw in are not scheduled at all.
func add_note(time: float, type: String, tower = null) -> void:
	if boss_alive():
		var gap := BOSS_NOTE_GAP_BEATS * clock.beat_length() - 0.001
		for b in bolts:
			if b["state"] == "flying" and absf(b["arrive"] - time) < gap:
				return
	super.add_note(time, type if asks("e") else "kick", tower)


## At the camp it keeps throwing; only the bolts you miss cost health (v3, D-0052).
func _tick_boss_threat() -> void:
	if not boss_alive() or not boss.get("at_goal", false):
		return
	if not _told.has("keep"):
		_told["keep"] = true
		_watchman("It's at the camp! Parry it, break it!", 3.0)


func _posture_break() -> void:
	super._posture_break()
	_sweep = clock.bar_length()
	_sfx_hit.play()


func _watchman(text: String, seconds: float) -> void:
	_message = "WATCHMAN   " + text
	_message_time = seconds


# --- The music -------------------------------------------------------------------

## How far into "calm" the music is: 0 open, 1 fully calmed (a lull).
func calm() -> float:
	var s := current_section()
	if ending:
		return 1.0  # Morning: the loop under the card and the results is calm.
	if s.get("kind", "") != "lull":
		return 0.0
	var b := song_bar()
	var into: float = b - s["start"]
	var left: float = s["start"] + s["bars"] - b
	if section + 1 >= night["sections"].size():
		left = INF  # A lull at the very end never lifts.
	return clampf(minf(into / LULL_FALL_BARS, left / LULL_LIFT_BARS), 0.0, 1.0)


## The song sits at full level once the night starts, whatever the towers do;
## a lull dips it and closes the low-pass. Before Start it is silent.
func _update_stems(delta: float, speed: int) -> void:
	var k := calm()
	var target := -80.0
	if started:
		target = SONG_ACTIVE_DB - LULL_DIP_DB * k
	idle_db["hat"] = target
	# A boss fight only goes up (D-0051): the bed stays at full whatever the
	# streak, a streak of 4 adds the arp on top, and misses are quieter.
	var fight := boss_alive()
	var held := intensity
	if fight:
		intensity = INTENSITY_STEPS
	active_db["hat"] = target + (SONG_STEP_DB * (INTENSITY_STEPS - intensity) if song_index > 0 else 0.0)
	super._update_stems(delta, speed)
	intensity = held
	var arp_target := -7.0 if fight and streak >= 4 and speed == 1 else -80.0
	var arp := move_toward(_arp_db, arp_target, (240.0 if arp_target > _arp_db else 60.0) * delta)
	if arp != _arp_db:
		_arp_db = arp
		clock.set_stem_volume_db(stem_index["arp"], arp)
	_sfx["miss"].volume_db = -16.0 if fight else -4.0
	# Bolts get a rising whoosh into the beat they land on.
	for b in bolts:
		if b["state"] == "flying" and not b.has("_whoosh") and b["arrive"] - beat_time() <= clock.beat_length():
			b["_whoosh"] = true
			_sfx_whoosh.play()
	if _lowpass != null:
		var cutoff := OPEN_CUTOFF * pow(LULL_CUTOFF / OPEN_CUTOFF, k)
		if _sweep > 0.0:
			# A posture break: the music ducks under a low-pass and opens over a bar.
			cutoff = minf(cutoff, 400.0 * pow(OPEN_CUTOFF / 400.0, 1.0 - _sweep / clock.bar_length()))
		_lowpass.cutoff_hz = cutoff
		var bus := AudioServer.get_bus_index("Music")
		for i in AudioServer.get_bus_effect_count(bus):
			if AudioServer.get_bus_effect(bus, i) == _lowpass:
				AudioServer.set_bus_effect_enabled(bus, i, cutoff < OPEN_CUTOFF - 1.0)


# --- Results ---------------------------------------------------------------------

func run_lines() -> Array[String]:
	var lines := super.run_lines()
	if state == "won":
		lines[0] = "NIGHT SURVIVED   %s" % night["name"]
	else:
		var s := current_section()
		if song_over():
			lines[0] = "THE CAMP FELL   after the song, in the %s" % s.get("name", "finale")
		else:
			lines[0] = "THE CAMP FELL   in the %s, bar %d of %d" % [s.get("name", "count-off"), maxi(1, floori(song_bar()) + 1), night["bars"]]
	lines.insert(mini(4, lines.size()), miss_line())
	# By section, not by wave (v3, D-0052): one row per part of the song.
	_log_section()
	var at := lines.find("By wave (hit/offered):")
	if at >= 0:
		lines.resize(at)
	elif lines.is_empty() or lines[-1] != "":
		lines.append("")
	lines.append("By section (notes hit/offered, parries, health lost):")
	lines.append_array(section_log)
	return lines


## Notes hit or missed so far: a section's "offered" counts the notes that
## landed in it, not the ones written into it two bars ahead.
func _resolved_notes() -> int:
	var n := 0
	for type in stats:
		n += stats[type]["hits"] + stats[type]["missed"]
	return n


## One row of the run log for the section that just ended.
func _log_section() -> void:
	if _section_base.is_empty() or section < 0:
		return
	var t := _totals()
	var name: String = night["sections"][section]["name"]
	section_log.append("%-10s notes %d/%d   parries %d/%d   hp -%d%s" % [name,
		t["hits"] - _section_base["hits"], _resolved_notes() - _section_base["resolved"],
		t["parried"] - _section_base["parried"], t["throws"] - _section_base["throws"],
		maxi(0, _section_base["health"] - health), "   boss" if _section_base["boss"] else ""])
	print("SECTION LOG  " + section_log[-1])
	_section_base = {}


# --- Synth voices for the level -------------------------------------------------------

## The boss streak layer: a bar of 8th notes up and down an E minor arpeggio.
static func _arp(bar_seconds: float) -> AudioStreamWAV:
	var notes := [329.6, 392.0, 493.9, 659.3, 493.9, 392.0, 329.6, 246.9]
	return StemSynth._render(bar_seconds, func(step: int, t: float) -> float:
		var f: float = notes[step]
		var env := minf(t * 500.0, 1.0) * exp(-t * 9.0)
		var saw := 2.0 * (f * t - floorf(f * t + 0.5))
		return (saw * 0.6 + sin(TAU * f * 2.0 * t) * 0.3) * env * 0.35)


## A rising noise whoosh, one beat long, that lands on the beat.
static func _whoosh(seconds: float) -> AudioStreamWAV:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var lp := [0.0]
	return StemSynth._one_shot(seconds, func(t: float) -> float:
		var k := clampf(t / seconds, 0.0, 1.0)
		var cut := 0.02 + 0.5 * k * k
		lp[0] += (rng.randf_range(-1.0, 1.0) - lp[0]) * cut
		return lp[0] * (k * k) * 0.9)
