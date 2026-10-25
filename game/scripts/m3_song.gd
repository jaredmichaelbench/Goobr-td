extends "res://scripts/m2_maze.gd"
## M3: the maze plays the song. Answers P-04: can you hear your maze, and do
## you build it so your towers are in the fight when the song calls for them?
##
## The song decides the notes (D-0014), but notes are punctuation, not a
## stream (D-0022): a few accents per wave. Two beats before each note the
## game hands it to one tower, the one with the best crossfire that will have
## targets when it lands, and a ring in the note's color (Q orange, E purple)
## closes on that tower. It never moves. Press the key as the ring lands and
## that tower fires a bolt across the whole board at the creep nearest the
## Conductor: Perfect = crit, a miss costs only the bonus. Nothing else
## happens on a miss. The timeline overlay is a test aid, off by default (L).
##
## Towers: 2 = heavy (single target), 3 = splash. 1 = wall. Any tower can
## carry any note.
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
	"slow": StemSynth.SUB_STEPS,  # Every beat: a tap that slows.
}
const SLOW_BUILD := {"cost": 30, "color": Color(0.6, 0.8, 1.0), "range": 2.2, "damage": 3.0, "cooldown": 0.5, "splash": 0.0, "slow": 1.5}
const FREEZE_GOOD := 2.0  # Slow tower note: a freeze on everything near the target, damage x this.
const FREEZE_PERFECT := 4.0
const FREEZE_BEATS_GOOD := 1.0
const FREEZE_BEATS_PERFECT := 2.0
const KEYS := {"kick": KEY_Q, "bass": KEY_E}
const KEY_TYPE := {KEY_Q: "kick", KEY_E: "bass"}
## Charts are [bar in phrase, 8th-note step, tower type]. Q notes sit on the
## kick's beats, E notes on the bass's off-beats, so each note lands on a shot
## its towers are already playing. Index = level; see chart_for_wave().
const CHARTS: Array = [
	[[3, 4, "kick"]],
	[[1, 4, "kick"], [3, 4, "kick"]],
	[[1, 4, "kick"], [3, 3, "bass"]],
	[[0, 4, "kick"], [1, 3, "bass"], [3, 4, "kick"], [3, 5, "bass"]],
]
const NOTE_COLORS := {"kick": Color(1.0, 0.55, 0.3), "bass": Color(0.7, 0.45, 1.0)}
const NOTE_NAMES := {"kick": "Q", "bass": "E"}
const SNIPE_GOOD := 4.0  # Heavy tower note: single-target snipe = tower damage x this x crossfire.
const SNIPE_PERFECT := 8.0
const WAVE_GOOD := 2.0  # Splash tower note: a wave that hits everything near the target.
const WAVE_PERFECT := 4.0
const WAVE_RADIUS := 2.0
const PUNCH_SECONDS := 0.18  # Screen punch on a landed snipe.
const CROSSFIRE_BONUS := 0.25  # Per extra tower that also covers the target.
const RESONANCE_RADIUS := 1.0
const LEAD_HOLD_BARS := 2.0
const TIMELINE_AHEAD := 4.0  # Seconds of chart shown ahead of the line.
const TIMELINE_BEHIND := 0.6
## '#' = rock. Spawn is the left edge of row 10, the goal the right edge.
const MAP := [
	"......#...##....##........",
	"..........##....##........",
	"................##....#...",
	"....##....##....##........",
	"....#.....##....##........",
	"..........##..............",
	"..........##.##...........",
	"..........##.##...........",
	"..........##.##...........",
	"..........##..............",
	"..........##....##........",
	"....#.....##....##........",
	"....##....##....##....#...",
	"................##........",
	"..........##....##........",
	"......#...##....##........",
]
const START_GOLD_M3 := 100
const WALL_LIMIT := 20

const IDLE_DB := {"kick": -16.0, "hat": -80.0, "bass": -80.0, "lead": -80.0}
const ACTIVE_DB := {"kick": 0.0, "hat": -8.0, "bass": 0.0, "lead": -6.0}
## A real song (test only, see audio/README.md) takes the groove slot.
const SONG_DIR := "res://audio"
const SONG_IDLE_DB := -9.0
const SONG_ACTIVE_DB := -1.0
## Intensity: the streak of landed notes and parries opens the mix one step
## per STREAK_PER_STEP hits; any miss drops a step. Step 0 is the plain bed.
const INTENSITY_STEPS := 3
const STREAK_PER_STEP := 4
const SONG_STEP_DB := 2.0  # The real track gains this per step below full.
const PULSE_STEP_DB := 4.0  # The low pulse layer gains this per step.
const SONG_CFG := "res://audio/songs.cfg"  # [bpm] "file.wav" = 130; [sfx] "file.wav" = packname
var sfx_pack := ""  # Folder under audio/sfx/ holding this song's sound effects, or "".
var mods := {}  # Run modifiers from draft picks (M6b-2): chain, slow_wave, shatter, rally, refund.
var snipe_perfect_mult := SNIPE_PERFECT  # A draft pick can raise it.
const CHAIN_RANGE := 3.0  # Chain snipe: second creep within this of the target, half damage.
const SLOW_WAVE_SECONDS := 1.0
const SHATTER_MULT := 3.0
const DEFAULT_BPM := 120.0

var clock: BeatClock
var calibration_ms := 0.0
var one_key_mode := false
var show_timeline := false

var stem_index := {}  # stem name -> BeatClock stem index
var stem_db := {}  # stem name -> current dB
var idle_db := IDLE_DB.duplicate()
var active_db := ACTIVE_DB.duplicate()
var songs: Array[Dictionary] = []  # name, path, bpm. Index 0 is "synth stems".
var song_index := 0
var _song_end := INF  # Song time when the current track finishes and the playlist moves on.
var _time_offset := 0.0  # Extra time from the speed-up test tool.
var _last_step := -1
var _lead_timer := 0.0
var _flashes := {}  # tower cell -> seconds left

var notes: Array[Dictionary] = []  # time, type, tower (Vector2i or null), state ("open", "hit", "missed")
var stats := {}  # note type -> {notes, hits, perfects, missed}
var _wave_notes := 0
var _feedback := ""
var _feedback_color := Color.WHITE
var _feedback_time := 0.0
var _bursts: Array[Dictionary] = []
var _popups: Array[Dictionary] = []  # Floating damage numbers: pos, text, color, size, ttl.
var _line_flash := {"color": Color.WHITE, "ttl": 0.0}
var _punch := 0.0  # Seconds of screen punch left.
var streak := 0  # Landed notes and parries in a row.
var intensity := 0  # 0..INTENSITY_STEPS, from the streak.
var _ball_pulse := 0.0  # Streak ball: seconds of pulse left (positive = hit, negative = miss).
var _sting_at := -1.0  # Song time the wave-clear sting lands, or -1.
var _sfx := {}  # name -> AudioStreamPlayer


func _ready() -> void:
	title = "M3 The maze plays the song"
	build_keys = {KEY_1: "wall", KEY_2: "kick", KEY_3: "bass", KEY_4: "slow"}
	builds.erase("hat")  # Hats are background music now, not a tower (D-0014).
	builds["slow"] = SLOW_BUILD.duplicate()
	builds["bass"]["damage"] = 4.5  # Splash fires twice as often, on the off-beats.
	# Tower colors are roles now; note colors (NOTE_COLORS) are the keys.
	builds["kick"]["color"] = Color(0.9, 0.78, 0.5)
	builds["bass"]["color"] = Color(0.5, 0.82, 0.75)
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
	_scan_songs()
	var song := songs[song_index]
	var song_stream: AudioStreamWAV = null
	if song["path"] != "":
		song_stream = _load_song(song["path"], song["bpm"])
	if song_stream == null:
		song_index = 0
		song = songs[0]
	clock.set_bpm(song["bpm"])
	sfx_pack = song.get("sfx", "")
	var bar := clock.bar_length()
	stem_index["kick"] = clock.add_stem(StemSynth.kick(bar), idle_db["kick"])
	if song_stream != null:
		idle_db["hat"] = SONG_IDLE_DB
		active_db["hat"] = SONG_ACTIVE_DB
		stem_index["hat"] = clock.add_stem(song_stream, idle_db["hat"])
		_song_end = BeatClock.loop_length(song_stream)
	else:
		stem_index["hat"] = clock.add_stem(StemSynth.hat(bar), idle_db["hat"])
	stem_index["bass"] = clock.add_stem(StemSynth.bass(bar), idle_db["bass"])
	stem_index["lead"] = clock.add_stem(StemSynth.lead(bar), idle_db["lead"])
	for k in idle_db:
		stem_db[k] = idle_db[k]
	# Feedback voices in E: half effect, half music (D-0029).
	for sfx in [["perfect", StemSynth.pluck(329.6, true), -3.0], ["good", StemSynth.pluck(164.8), -6.0], ["miss", StemSynth.tick(), -4.0], ["clear", StemSynth.pluck(659.3, true), -2.0]]:
		var player := AudioStreamPlayer.new()
		player.stream = StemSynth.with_override(sfx[0], sfx[1], sfx_pack)
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
	streak = 0
	intensity = 0


func _reset_stats() -> void:
	stats = {}
	for type in KEYS:
		stats[type] = {"notes": 0, "hits": 0, "perfects": 0, "missed": 0}


func stat_total(field: String) -> int:
	var n := 0
	for type in stats:
		n += stats[type][field]
	return n


## The last creep died: pending notes go, the melody drops, a sting lands on
## the next beat, and the groove fades to idle on its own (no towers engaged).
func step(delta: float) -> void:
	var was_active := wave_active
	super.step(delta)
	if was_active and not wave_active and state == "playing":
		_wave_cleared()
	if _sting_at >= 0.0 and beat_time() >= _sting_at:
		_sting_at = -1.0
		_sfx["clear"].play()
		_flash_line(Color(1.0, 0.9, 0.3))


func _wave_cleared() -> void:
	for n in notes:
		if n["state"] == "open":
			stats[n["type"]]["notes"] -= 1
			_wave_notes -= 1
	notes.clear()
	_lead_timer = 0.0
	var beat := clock.beat_length()
	_sting_at = (floorf(beat_time() / beat) + 1.0) * beat
	_show_feedback("WAVE %d CLEAR" % wave, Color(1.0, 0.9, 0.3))


## Longer waves so each one carries several phrases of practice.
func start_wave() -> void:
	var was_active := wave_active
	super.start_wave()
	if wave_active and not was_active:
		_wave_notes = 0


func creeps_in_wave(w: int) -> int:
	return WaveScript.plan(w).size()


## M3 and up send the hand-written waves (D-0033).
func wave_plan(w: int) -> Array[Dictionary]:
	return WaveScript.plan(w)


func wave_summary(w: int) -> String:
	return WaveScript.summary(w)


## Wave 1 = level 0, wave 2 = level 1, waves 3-4 = level 2 (E joins), wave 5+ = level 3.
func chart_for_wave(w: int) -> Array:
	return CHARTS[clampi(w - 1 if w <= 2 else (w + 1) / 2, 0, CHARTS.size() - 1)]


# --- Test songs ----------------------------------------------------------------

## Lists the WAVs in audio/. BPM comes from audio/songs.cfg, else from a
## leading number in the filename if it looks like a tempo (60-220), else 120.
func _scan_songs() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SONG_CFG)
	songs = [{"name": "synth stems", "path": "", "bpm": DEFAULT_BPM, "sfx": str(cfg.get_value("sfx", "default", ""))}]
	var dir := DirAccess.open(SONG_DIR)
	if dir == null:
		return
	var re := RegEx.new()
	re.compile("^\\s*(\\d+(?:\\.\\d+)?)[\\s_.-]*(.*)$")
	var names := Array(dir.get_files())
	names.sort()
	for f in names:
		if not f.to_lower().ends_with(".wav"):
			continue
		var base: String = f.substr(0, f.length() - 4)
		var bpm: float = float(cfg.get_value("bpm", "default", DEFAULT_BPM))
		var m := re.search(base)
		if m != null and m.get_string(2) != "":
			base = m.get_string(2)
			var lead := float(m.get_string(1))
			if lead >= 60.0 and lead <= 220.0:
				bpm = lead
		if cfg.has_section_key("bpm", f):
			bpm = float(cfg.get_value("bpm", f))
		elif cfg.has_section_key("bpm", base):
			bpm = float(cfg.get_value("bpm", base))
		var pack: String = str(cfg.get_value("sfx", "default", ""))
		if cfg.has_section_key("sfx", f):
			pack = str(cfg.get_value("sfx", f))
		elif cfg.has_section_key("sfx", base):
			pack = str(cfg.get_value("sfx", base))
		songs.append({"name": base, "path": SONG_DIR + "/" + f, "bpm": bpm, "sfx": pack})
	var want := _load_song_choice()
	for i in songs.size():
		if songs[i]["name"] == want:
			song_index = i
	if song_index > 0:
		_say("Song %d/%d: %s (%.0f BPM)   [ ] to switch, plays on as a playlist" % [song_index + 1, songs.size(), songs[song_index]["name"], songs[song_index]["bpm"]])


## Loads a WAV at runtime (no import step) and loops it on a whole bar.
func _load_song(path: String, bpm: float) -> AudioStreamWAV:
	var stream := AudioStreamWAV.load_from_file(ProjectSettings.globalize_path(path))
	if stream == null:
		push_warning("Could not load song " + path)
		return null
	var bar := 60.0 / bpm * clock.beats_per_bar
	var bars := floorf(stream.get_length() / bar + 0.01)
	if bars >= 1.0:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = int(bars * bar * stream.mix_rate)
	return stream


func _load_song_choice() -> String:
	var cfg := ConfigFile.new()
	if cfg.load(Timing.SETTINGS_PATH) == OK:
		return cfg.get_value("test", "song", "")
	return ""


func _save_song_choice(name: String) -> void:
	var cfg := ConfigFile.new()
	cfg.load(Timing.SETTINGS_PATH)
	cfg.set_value("test", "song", name)
	cfg.save(Timing.SETTINGS_PATH)


## Jumps to another song. Same BPM: swapped live, the beat carries on. Any
## other case (synth stems, a different BPM): the scene restarts.
func _switch_song(delta_index: int) -> void:
	var next := posmod(song_index + delta_index, songs.size())
	_save_song_choice(songs[next]["name"])
	if next == 0 or song_index == 0 or songs[next]["bpm"] != songs[song_index]["bpm"]:
		get_tree().reload_current_scene()
		return
	var stream := _load_song(songs[next]["path"], songs[next]["bpm"])
	if stream == null:
		return
	song_index = next
	clock.swap_stem(stem_index["hat"], stream)
	_song_end = clock.song_time() + BeatClock.loop_length(stream)
	_say("Song %d/%d: %s (%.0f BPM)   [ ] to switch" % [song_index + 1, songs.size(), songs[song_index]["name"], songs[song_index]["bpm"]])


## Playlist: when the track ends, move to the next one (skipping synth stems).
func _tick_playlist() -> void:
	if song_index == 0 or songs.size() < 3 or clock.song_time() < _song_end - 0.05:
		return
	var next := song_index + 1
	if next >= songs.size():
		next = 1
	_switch_song(next - song_index)


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
	if _last_step < 0 or now_step < _last_step:
		_last_step = now_step  # First frame, or the clock went backwards: never wait for it.
	# Catch up on every step since last frame, capped so a hitch can't flood.
	for s in range(maxi(_last_step + 1, now_step - 32), now_step + 1):
		on_step(s)
	_last_step = maxi(_last_step, now_step)

	var lead := RING_LEAD_STEPS * step_length()
	for n in notes:
		if n["state"] != "open":
			continue
		if n["tower"] == null and n["time"] - beat_time() <= lead:
			_assign_note(n)
			if n["tower"] == Vector2i(-1, -1):
				n["state"] = "void"  # No towers at all: the note never existed.
				stats[n["type"]]["notes"] -= 1
				_wave_notes -= 1
		elif n["tower"] is Vector2i and not structures.has(n["tower"]):
			_assign_note(n)  # Its tower was sold.
		# A note that slid past the ring is missed. It only costs the bonus.
		if press_time() > n["time"] + Timing.GOOD_MS / 1000.0:
			n["state"] = "missed"
			_on_miss(n)
	var keep: Array[Dictionary] = []
	for n in notes:
		if n["state"] != "void" and n["time"] > beat_time() - TIMELINE_BEHIND:
			keep.append(n)
	notes = keep

	_update_stems(delta, speed)
	_tick_effects(delta)
	_tick_playlist()
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
	if not chart_allowed():
		return
	var bar_in_phrase := posmod(bar, PHRASE_BARS)
	for entry in chart_for_wave(wave):
		if entry[0] != bar_in_phrase:
			continue
		add_note((bar * STEPS_PER_BAR + entry[1]) * step_length(), entry[2])


## Hook: M5 turns the chart off during the boss fight.
func chart_allowed() -> bool:
	return true


func add_note(time: float, type: String, tower = null) -> void:
	notes.append({"time": time, "type": type, "tower": tower, "state": "open"})
	stats[type]["notes"] += 1
	_wave_notes += 1


## Two beats out, a note is handed to one tower: the one covering the most
## creeps, ties broken by crossfire. With no creeps near any tower, the tower
## nearest the creep closest to the Conductor. The ring stays there.
func _assign_note(n: Dictionary) -> void:
	var best := Vector2i(-1, -1)
	var best_score := -INF
	var lead_creep := _lead_creep()
	# One ring per tower: a tower already holding an open note is skipped
	# unless every tower is busy.
	var busy := {}
	for other in notes:
		if other != n and other["state"] == "open" and other["tower"] is Vector2i:
			busy[other["tower"]] = true
	for cell in structures:
		var type: String = structures[cell]["type"]
		if not builds[type].has("range") or not tower_ready(cell):
			continue
		var score := 0.0 if not busy.has(cell) else -1000.0
		for c in creeps:
			if c["hp"] > 0.0 and c["pos"].distance_to(Vector2(cell)) <= tower_spec(cell)["range"] + 1.0:
				score += 1.0 + 0.25 * _coverage(c["pos"])
		if score <= 0.0 and not lead_creep.is_empty():
			score -= lead_creep["pos"].distance_to(Vector2(cell)) * 0.01
		if score > best_score:
			best_score = score
			best = cell
	n["tower"] = best


## The creep closest to the Conductor, anywhere on the board.
func _lead_creep() -> Dictionary:
	var best := {}
	var best_d := INF
	for c in creeps:
		if c["hp"] <= 0.0:
			continue
		var d: float = float(grid.dist(c["target"])) + c["pos"].distance_to(Vector2(c["target"]))
		if d < best_d:
			best = c
			best_d = d
	return best


func _fire_towers_on(pattern_step: int) -> void:
	for cell in structures:
		var type: String = structures[cell]["type"]
		if not PATTERNS.has(type) or not PATTERNS[type].has(pattern_step) or not tower_ready(cell):
			continue
		var spec: Dictionary = tower_spec(cell)
		var target := _pick_target(Vector2(cell), spec["range"])
		if target.is_empty():
			continue
		_hit(target, spec, spec["damage"] * damage_scale())
		if spec.has("slow"):
			target["slow_until"] = sim_time + spec["slow"]
		_flashes[cell] = 0.12
		shots.append({"from": Vector2(cell), "to": target["pos"], "color": spec["color"], "ttl": 0.12, "splash": spec["splash"]})


## Global tower damage multiplier. M5's Crescendo raises it.
func damage_scale() -> float:
	return 1.0


func _hit(target: Dictionary, spec: Dictionary, amount: float) -> void:
	if spec["splash"] > 0.0:
		for c in creeps:
			if c["pos"].distance_to(target["pos"]) <= spec["splash"]:
				damage(c, amount)
	else:
		damage(target, amount)


## How many towers have this spot in range.
func _coverage(pos: Vector2) -> int:
	var n := 0
	for cell in structures:
		var type: String = structures[cell]["type"]
		if PATTERNS.has(type) and pos.distance_to(Vector2(cell)) <= tower_spec(cell)["range"]:
			n += 1
	return n


## Can this tower act right now? M4 overrides this for suppressed towers.
func tower_ready(_cell: Vector2i) -> bool:
	return true


## A ready tower with something in range.
func tower_engaged(cell: Vector2i) -> bool:
	return tower_ready(cell) and not _pick_target(Vector2(cell), tower_spec(cell)["range"]).is_empty()


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
		if event.keycode == KEY_BRACKETLEFT or event.keycode == KEY_BRACKETRIGHT:
			_switch_song(1 if event.keycode == KEY_BRACKETRIGHT else -1)
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
		if n["state"] != "open" or n["tower"] == null:
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
	_resonance(best, g, offset_ms)


## The note's tower fires across the whole board at the creep nearest the
## Conductor. A heavy tower snipes it (big single-target hit, screen punch);
## a splash tower lobs a wave that hits everything near it. Crossfire on that
## creep multiplies it; Perfect doubles it.
func _resonance(n: Dictionary, g: String, offset_ms: float) -> void:
	var type: String = n["type"]
	var color: Color = NOTE_COLORS[type]
	var crit := g == "Perfect"
	stats[type]["hits"] += 1
	if crit:
		stats[type]["perfects"] += 1
	on_streak_hit()
	_lead_timer = clock.bar_length() * LEAD_HOLD_BARS
	_sfx["perfect" if crit else "good"].play()
	var cell: Vector2i = n["tower"]
	if not structures.has(cell):
		_assign_note(n)
		cell = n["tower"]
	var target := _lead_creep()
	if target.is_empty() or not structures.has(cell):
		_flash_line(color)
		_show_feedback("%s   nothing to hit" % g, color)
		return
	var spec: Dictionary = tower_spec(cell)
	var crossfire := 1.0 + CROSSFIRE_BONUS * maxi(0, _coverage(target["pos"]) - 1)
	var is_freeze: bool = spec.has("slow")
	var is_wave: bool = spec["splash"] > 0.0 or is_freeze
	var mult: float
	if is_freeze:
		mult = FREEZE_PERFECT if crit else FREEZE_GOOD
	elif is_wave:
		mult = WAVE_PERFECT if crit else WAVE_GOOD
	else:
		mult = snipe_perfect_mult if crit else SNIPE_GOOD
	var bonus: float = spec["damage"] * damage_scale() * crossfire * mult
	var radius: float = WAVE_RADIUS if is_wave else 0.0
	var freeze_for: float = (FREEZE_BEATS_PERFECT if crit else FREEZE_BEATS_GOOD) * clock.beat_length()
	var dealt := 0.0
	var struck := 0
	# A landed note cracks every Shade's veil first, so the bolt itself lands.
	var cracked := crack_veils(VEIL_CRACK_BEATS * clock.beat_length())
	for c in creeps:
		if c == target or (radius > 0.0 and c["pos"].distance_to(target["pos"]) <= radius):
			var amount := bonus
			if is_freeze and mods.get("shatter", false) and c.get("frozen_until", 0.0) > sim_time:
				amount *= SHATTER_MULT  # Shatter: a freeze on a frozen creep.
			dealt += damage(c, amount)
			struck += 1
			if is_freeze:
				c["frozen_until"] = sim_time + freeze_for
			elif is_wave and mods.get("slow_wave", false):
				c["slow_until"] = maxf(c.get("slow_until", 0.0), sim_time + SLOW_WAVE_SECONDS)
	if not is_wave and mods.get("chain", false):
		# Chain snipe: the bolt jumps to the next creep near the target for half.
		var second := {}
		var best_d := CHAIN_RANGE
		for c in creeps:
			if c != target and c["hp"] > 0.0 and c["pos"].distance_to(target["pos"]) <= best_d:
				second = c
				best_d = c["pos"].distance_to(target["pos"])
		if not second.is_empty():
			dealt += damage(second, bonus * 0.5)
			struck += 1
			shots.append({"from": target["pos"], "to": second["pos"], "color": Color.WHITE, "ttl": 0.4, "splash": 0.0, "width": 2.5})
	_flashes[cell] = 0.3
	if is_wave:
		shots.append({"from": Vector2(cell), "to": target["pos"], "color": color, "ttl": 0.4, "splash": radius, "width": 3.0})
		_bursts.append({"pos": target["pos"], "color": color, "ttl": 0.5, "crit": crit, "radius": radius})
	else:
		# A snipe: a bright tracer that lingers, and the screen punches.
		shots.append({"from": Vector2(cell), "to": target["pos"], "color": Color.WHITE, "ttl": 0.5, "splash": 0.0, "width": 5.0 if crit else 3.5})
		shots.append({"from": Vector2(cell), "to": target["pos"], "color": color, "ttl": 0.7, "splash": 0.0, "width": 1.5})
		_bursts.append({"pos": target["pos"], "color": color, "ttl": 0.35, "crit": crit})
		_punch = PUNCH_SECONDS * (1.5 if crit else 1.0)
	_popup(target["pos"], ("%d!" if crit else "%d") % roundi(dealt), Color(1.0, 0.9, 0.3) if crit else Color.WHITE, 24 if crit else 16)
	_flash_line(Color(1.0, 0.9, 0.3) if crit else Color.WHITE)
	var what := ("FREEZE  %d held" % struck) if is_freeze else (("WAVE  %d hit" % struck) if is_wave else "SNIPE")
	_show_feedback("%s%s  %s  %+.0f ms   %d damage%s%s" % ["CRIT  " if crit else "", what, g, offset_ms, roundi(dealt), "   x%.2f crossfire" % crossfire if crossfire > 1.0 else "", ("   %d veil%s cracked" % [cracked, "" if cracked == 1 else "s"]) if cracked > 0 else ""], Color(1.0, 0.9, 0.3) if crit else color)


## Streak bookkeeping: hits climb the intensity, a miss drops one step.
func on_streak_hit() -> void:
	streak += 1
	_ball_pulse = 0.25
	if streak % STREAK_PER_STEP == 0:
		intensity = mini(INTENSITY_STEPS, intensity + 1)


func on_streak_miss() -> void:
	streak = 0
	intensity = maxi(0, intensity - 1)
	_ball_pulse = -0.35


## A note slid past its ring. It costs the bonus and nothing else.
func _on_miss(n: Dictionary) -> void:
	stats[n["type"]]["missed"] += 1
	on_streak_miss()
	_sfx["miss"].play()
	_flash_line(Color(1, 0.3, 0.3))
	_show_feedback("MISS", Color(1, 0.3, 0.3))
	if n["tower"] is Vector2i and structures.has(n["tower"]):
		_popup(Vector2(n["tower"]), "miss", Color(1, 0.35, 0.35, 0.9), 13)


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
	var active := {"kick": false, "hat": false, "bass": false, "lead": _lead_timer > 0.0 or intensity > 0}
	for cell in structures:
		var type: String = structures[cell]["type"]
		if active.has(type) and not active[type] and tower_engaged(cell):
			active[type] = true
	active["hat"] = active["kick"] or active["bass"]  # Background groove while fighting.
	_adjust_mix(active)
	for k in stem_db:
		var target_db: float = active_db[k] if active[k] else idle_db[k]
		# Intensity: the track and the pulse layer open up with the streak.
		if active[k] and k == "hat" and song_index > 0:
			target_db -= SONG_STEP_DB * (INTENSITY_STEPS - intensity)
		if active[k] and k == "lead" and _lead_timer <= 0.0:
			target_db -= PULSE_STEP_DB * (INTENSITY_STEPS - intensity)
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
	_punch = maxf(0.0, _punch - delta)
	_ball_pulse = move_toward(_ball_pulse, 0.0, delta)
	if _punch > 0.0:
		var k := _punch / PUNCH_SECONDS
		position = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * 5.0 * k
	else:
		position = Vector2.ZERO


# --- Drawing -------------------------------------------------------------------

func _draw() -> void:
	super._draw()
	var font := ThemeDB.fallback_font
	var board_w := GRID_SIZE.x * TILE

	# Tower fire flashes.
	for cell in _flashes:
		if not structures.has(cell):
			continue
		var p := _to_screen(Vector2(cell))
		var a: float = clampf(_flashes[cell] / 0.12, 0.0, 1.0)
		draw_circle(p, TILE * (0.32 + 0.15 * a), tower_spec(cell)["color"] * Color(1, 1, 1, 0.5 * a))

	# Each pending note is one ring on one tower, in the note's color, closing
	# over two beats and holding at the tower until the note is gone.
	var lead := RING_LEAD_STEPS * step_length()
	for n in notes:
		if n["state"] != "open" or not (n["tower"] is Vector2i) or not structures.has(n["tower"]):
			continue
		if n["time"] - beat_time() > lead:
			continue  # Pre-assigned (Crescendo sweep) but not yet in its two-beat window.
		var p := _to_screen(Vector2(n["tower"]))
		var color: Color = NOTE_COLORS[n["type"]]
		var left := clampf((n["time"] - beat_time()) / lead, 0.0, 1.0)
		draw_arc(p, TILE * (0.5 + 2.2 * left), 0, TAU, 48, color * Color(1, 1, 1, 0.5 + 0.5 * (1.0 - left)), 3.0)
		draw_arc(p, TILE * 0.55, 0, TAU, 48, color, 3.0)
		draw_string_outline(font, p + Vector2(-20, 6), NOTE_NAMES[n["type"]], HORIZONTAL_ALIGNMENT_CENTER, 40, 16, 4, Color(0, 0, 0, 0.9))
		draw_string(font, p + Vector2(-20, 6), NOTE_NAMES[n["type"]], HORIZONTAL_ALIGNMENT_CENTER, 40, 16, Color.WHITE)

	for b in _bursts:
		if b.has("radius"):
			# A splash wave: a ring that grows out to the wave's reach.
			var a: float = b["ttl"] / 0.5
			draw_arc(_to_screen(b["pos"]), TILE * b["radius"] * (1.0 - a), 0, TAU, 64, b["color"] * Color(1, 1, 1, a), 8.0 if b["crit"] else 5.0)
			continue
		var a: float = b["ttl"] / 0.35
		draw_arc(_to_screen(b["pos"]), TILE * (0.6 + 0.8 * (1.0 - a)), 0, TAU, 48, b["color"] * Color(1, 1, 1, a), 6.0 if b["crit"] else 3.0)

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
	_draw_streak_ball()


## The streak ball: beside the Conductor, filling toward the next intensity
## step, coloured by the step, pulsing on a hit and dropping on a miss.
func _draw_streak_ball() -> void:
	var p := _to_screen(Vector2(GOAL)) + Vector2(TILE * 0.95, -TILE * 0.55)
	var colors := [Color(0.5, 0.5, 0.55), Color(0.9, 0.9, 0.95), Color(1.0, 0.85, 0.35), Color(1.0, 0.6, 0.2)]
	var color: Color = colors[clampi(intensity, 0, colors.size() - 1)]
	var r := 7.0 + 3.0 * intensity + (10.0 * _ball_pulse if _ball_pulse > 0.0 else 0.0)
	if _ball_pulse < 0.0:
		draw_circle(p, r + 4.0 * (-_ball_pulse / 0.35), Color(1, 0.3, 0.3, 0.5 * (-_ball_pulse / 0.35)))
	if intensity >= INTENSITY_STEPS:
		draw_circle(p, r + 5.0 + 2.0 * sin(beat_time() * TAU * 2.0), color * Color(1, 1, 1, 0.25))
	draw_circle(p, r, Color(0, 0, 0, 0.5))
	var fill: float = 1.0 if intensity >= INTENSITY_STEPS else float(streak % STREAK_PER_STEP) / STREAK_PER_STEP
	if fill > 0.0:
		draw_arc(p, r - 2.0, -PI / 2, -PI / 2 + TAU * fill, 32, color, 3.0)
	draw_circle(p, r * 0.45, color)


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

	draw_string(font, Vector2(left - 14, top + 12), "Q", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, NOTE_COLORS["kick"] * Color(1, 1, 1, 0.5))
	draw_string(font, Vector2(left - 14, top + lane_h + 14), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, NOTE_COLORS["bass"] * Color(1, 1, 1, 0.5))
	for n in notes:
		var x: float = line_x + (n["time"] - now) * px_per_s
		if x < rect.position.x or x > rect.end.x:
			continue
		var lane := 0 if n["type"] == "kick" else 1
		var center := Vector2(x, top + 2 + lane * lane_h + lane_h * 0.5)
		var color: Color = NOTE_COLORS[n["type"]] * Color(1, 1, 1, 0.6)
		if n["state"] == "hit":
			color = Color(1, 1, 1, 0.7)
		elif n["state"] == "missed":
			color = NOTE_COLORS[n["type"]] * Color(1, 1, 1, 0.15)
		var r := 5.0
		draw_colored_polygon(PackedVector2Array([center + Vector2(0, -r), center + Vector2(r, 0), center + Vector2(0, r), center + Vector2(-r, 0)]), color)
	draw_line(Vector2(line_x, top - 2), Vector2(line_x, rect.end.y + 2), Color(1, 1, 1, 0.45), 2.0)
	if _line_flash["ttl"] > 0.0:
		var fa: float = _line_flash["ttl"] / 0.3
		draw_rect(Rect2(line_x - 6, top - 4, 12, rect.size.y + 8), _line_flash["color"] * Color(1, 1, 1, 0.6 * fa))


## Stem meters, so you can see what you're hearing.
func _draw_meters(font: Font, board_w: float) -> void:
	var x := _origin.x + board_w + 20
	var names := {"kick": "Heavy", "bass": "Splash", "hat": "Groove", "lead": "Melody"}
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
		lines.append("%s  notes %d   hits %d (%.0f%%)   crits %d   missed %d" % [OS.get_keycode_string(KEYS[type]), st["notes"], st["hits"], rate, st["perfects"], st["missed"]])
	lines.append("Calibration %+.0f ms (set in M1)%s" % [calibration_ms, "   ONE-KEY MODE" if one_key_mode else ""])
	lines.append("Song: %s (%.0f BPM)   [ ] switch (%d/%d)   streak %d   intensity %d/%d" % [songs[song_index]["name"], clock.bpm, song_index + 1, songs.size(), streak, intensity, INTENSITY_STEPS])
	return lines


func help_lines() -> Array[String]:
	var keys := {}
	for k in build_keys:
		keys[build_keys[k]] = OS.get_keycode_string(k)
	return [
		"%s  Wall       4g" % keys["wall"],
		"%s  Heavy tower   20g  single target; its note is a snipe" % keys["kick"],
		"%s  Splash tower  25g  splash; its note is a wave" % keys["bass"],
		"%s  Slow tower    30g  taps every beat, slows; its note is a freeze" % keys["slow"],
		"U  upgrade the tower under the mouse (its cost again: +50% damage, +range)",
		"Q / E  press the key shown on a tower as its ring lands",
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
