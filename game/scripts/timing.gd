class_name Timing
extends RefCounted
## Shared timing windows and the player's saved calibration.

const PERFECT_MS := 35.0
const GOOD_MS := 90.0
const PARRY_GOOD_MS := 110.0  # Parries (elite pulses, boss bolts) are a touch wider than notes.
const SETTINGS_PATH := "user://settings.cfg"
## Demo 1 (Jared, 2026-10-26): calibration is fixed at Jared's Mac Studio value,
## not something testers set. The beat test (dev menu, key 1) still measures and
## saves, but nothing reads the saved value while this is on.
const FIXED_CALIBRATION := true
const DEMO_CALIBRATION_MS := 46.0  # Jared's M1 measurement (M1-results: taps +45.8 ms late).


static func grade(offset_ms: float) -> String:
	var a := absf(offset_ms)
	if a <= PERFECT_MS:
		return "Perfect"
	if a <= GOOD_MS:
		return "Good"
	return "Miss"


static func grade_parry(offset_ms: float, good_ms := PARRY_GOOD_MS) -> String:
	var a := absf(offset_ms)
	if a <= PERFECT_MS:
		return "Perfect"
	if a <= good_ms:
		return "Good"
	return "Miss"


static func load_calibration_ms() -> float:
	if FIXED_CALIBRATION:
		return DEMO_CALIBRATION_MS
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		return cfg.get_value("timing", "calibration_ms", 0.0)
	return 0.0


static func save_calibration_ms(ms: float) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("timing", "calibration_ms", ms)
	cfg.save(SETTINGS_PATH)
