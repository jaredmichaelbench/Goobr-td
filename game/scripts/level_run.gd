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


# --- The level file ------------------------------------------------------------

## Reads a level file. Header lines are "key = value" (name, song, count, gold);
## every other line is a section: name kind bars [tier] [what comes]. What comes
## is groups split by commas, each "kind count @beats" ("grunt 8 @2": eight
## grunts, one every two beats); "boss" in a finale brings a field boss.
static func parse(text: String) -> Dictionary:
	var out := {"name": "Night", "song": "", "count": 2, "gold": 150, "sections": [], "bars": 0, "problems": []}
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
		var s := {"name": words[0], "kind": kind, "bars": int(words[2]), "tier": 1, "start": bar, "groups": [], "boss": false}
		var rest_at := 3
		if words.size() > 3 and words[3].is_valid_int():
			s["tier"] = int(words[3])
			rest_at = 4
		var what := " ".join(words.slice(rest_at))
		for g in what.split(",", false):
			var parts := g.strip_edges().split(" ", false)
			if parts.is_empty():
				continue
			if parts[0] == "boss":
				s["boss"] = true
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
	last_wave = 1000000  # The night ends with the song, not on a wave count.
	gold = night["gold"]
	clock.set_stem_volume_db(stem_index["hat"], -80.0)
	stem_db["hat"] = -80.0
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
	else:
		_watchman("%s.  Study the map, then N or the play button starts the night. The sticks count you in: build fast." % night["name"], 8.0)
	_booted = true


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
		section += 1
		_enter_section(night["sections"][section])
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
		return
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
		_summon_boss()
		if not _told.has("boss"):
			_told["boss"] = true
			_watchman("That one's big. Not my department.", 3.5)


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


func _finish() -> void:
	ending = true
	_watchman("Made it to morning. Take something for the road.", 4.0)
	_open_draft()
	if not drafting:
		state = "won"


func _pick(i: int) -> void:
	super._pick(i)
	if ending and not drafting:
		state = "won"


## Nothing is built before Start level: the count-off is the build phase.
func try_place(cell: Vector2i, type: String) -> bool:
	if not started:
		_say("N or the play button starts the night; build during the count-off")
		return false
	return super.try_place(cell, type)


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
	active_db["hat"] = target + (SONG_STEP_DB * (INTENSITY_STEPS - intensity) if song_index > 0 else 0.0)
	super._update_stems(delta, speed)
	if _lowpass != null:
		_lowpass.cutoff_hz = OPEN_CUTOFF * pow(LULL_CUTOFF / OPEN_CUTOFF, k)
		var bus := AudioServer.get_bus_index("Music")
		for i in AudioServer.get_bus_effect_count(bus):
			if AudioServer.get_bus_effect(bus, i) == _lowpass:
				AudioServer.set_bus_effect_enabled(bus, i, k > 0.001)


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
	return lines
