extends Node2D
## Milestone picker. Esc in any milestone scene returns here.

const SCENES := {
	KEY_1: "res://m1_beat_test.tscn",
	KEY_2: "res://m2_maze.tscn",
	KEY_3: "res://m3_song.tscn",
	KEY_4: "res://m4_restore.tscn",
	KEY_5: "res://m5_boss.tscn",
	KEY_6: "res://m6_run.tscn",
	KEY_7: "res://m7_run.tscn",
	KEY_8: "res://m7_run.tscn",
}


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and SCENES.has(event.keycode):
		M7Run.quick = event.keycode == KEY_8
		get_tree().change_scene_to_file(SCENES[event.keycode])


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var lines := [
		"Goobr TD - Demo 0",
		"",
		"1   M1 Beat test",
		"2   M2 Maze",
		"3   M3 The maze plays the song",
		"4   M4 Suppress and Restore",
		"5   M5 First boss",
		"6   M6 The run (draft, 10 waves, two bosses)",
		"7   M7 The progression run (20 waves, towers, tree, rolled draft)",
		"8   M7 quick run (10 waves)",
		"",
		"Esc in any test returns here",
	]
	for i in lines.size():
		draw_string(font, Vector2(80, 120 + i * 40), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 28 if i == 0 else 22)
