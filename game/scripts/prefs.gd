class_name Prefs
extends Node
## The player's settings (D-0044), kept in user://settings.cfg beside the calibration.
## Static, so any script (and the bots) can read them; the autoload "PrefsNode"
## runs ensure() at start-up and catches F11 / Alt+Enter for full screen anywhere.

const PATH := Timing.SETTINGS_PATH
const DEFAULTS := {
	"master": 0.9,
	"music": 0.8,
	"sfx": 0.9,
	"fullscreen": false,
	"synth_notes": true,  # The new synth note sounds instead of the pack's (Jared, 2026-10-26).
	"key_hints": true,
}

static var values := {}


func _ready() -> void:
	ensure()
	# Demo 1 renamed the project, so user:// is a fresh folder: calibrate once from Settings.
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_title("Goobr TD")


## Loads the settings once, makes the Music and SFX buses, applies everything.
static func ensure() -> void:
	if not values.is_empty():
		return
	values = DEFAULTS.duplicate()
	for bus in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus) < 0:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus)
			AudioServer.set_bus_send(i, "Master")
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		for k in DEFAULTS:
			values[k] = cfg.get_value("prefs", k, DEFAULTS[k])
	apply()


static func get_value(key: String):
	ensure()
	return values.get(key, DEFAULTS.get(key))


static func set_value(key: String, v) -> void:
	ensure()
	values[key] = v
	apply()
	var cfg := ConfigFile.new()
	cfg.load(PATH)
	cfg.set_value("prefs", key, v)
	cfg.save(PATH)


static func apply() -> void:
	_volume("Master", values["master"])
	_volume("Music", values["music"])
	_volume("SFX", values["sfx"])
	if DisplayServer.get_name() != "headless":
		var full: bool = values["fullscreen"]
		var mode := DisplayServer.window_get_mode()
		var is_full := mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
		if full != is_full:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if full else DisplayServer.WINDOW_MODE_WINDOWED)


static func _volume(bus: String, v: float) -> void:
	var i := AudioServer.get_bus_index(bus)
	if i >= 0:
		AudioServer.set_bus_volume_db(i, linear_to_db(maxf(v, 0.0001)))
		AudioServer.set_bus_mute(i, v <= 0.001)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed):
			set_value("fullscreen", not get_value("fullscreen"))
			get_viewport().set_input_as_handled()
