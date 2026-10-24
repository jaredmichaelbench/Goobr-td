class_name Timing
extends RefCounted
## Shared timing windows and the player's saved calibration.

const PERFECT_MS := 35.0
const GOOD_MS := 90.0
const SETTINGS_PATH := "user://settings.cfg"


static func grade(offset_ms: float) -> String:
	var a := absf(offset_ms)
	if a <= PERFECT_MS:
		return "Perfect"
	if a <= GOOD_MS:
		return "Good"
	return "Miss"


static func load_calibration_ms() -> float:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		return cfg.get_value("timing", "calibration_ms", 0.0)
	return 0.0


static func save_calibration_ms(ms: float) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("timing", "calibration_ms", ms)
	cfg.save(SETTINGS_PATH)
