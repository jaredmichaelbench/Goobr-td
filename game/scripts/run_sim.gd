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


## Esc leaves for the title screen after a confirm, as before.
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if _esc_time > 0.0:
			get_tree().paused = false
			get_tree().change_scene_to_file("res://menu.tscn")
		else:
			_esc_time = ESC_CONFIRM_TIME
			_say("Press Esc again to leave the run")
		return
	super._unhandled_input(event)


## Clutter off (D-0043): one ring per tower, and a ring also steers away from a
## tower whose neighbour (within 1.5 tiles) already holds one, so badges above
## a tight maze don't stack. Same scoring as M3 otherwise; when every ready
## tower is busy or crowded it falls back to the best of them.
const NOTE_SPACING := 1.5

func _assign_note(n: Dictionary) -> void:
	var best := Vector2i(-1, -1)
	var best_score := -INF
	var lead_creep := _lead_creep()
	var busy := {}
	for other in notes:
		if other != n and other["state"] == "open" and other["tower"] is Vector2i:
			busy[other["tower"]] = true
	for cell in structures:
		var type: String = structures[cell]["type"]
		if not builds[type].has("range") or not tower_ready(cell):
			continue
		var score := 0.0
		if busy.has(cell):
			score -= 1000.0
		else:
			for b in busy:
				if Vector2(b).distance_to(Vector2(cell)) <= NOTE_SPACING:
					score -= 500.0
					break
		var near := 0.0
		for c in creeps:
			if c["hp"] > 0.0 and c["pos"].distance_to(Vector2(cell)) <= tower_spec(cell)["range"] + 1.0:
				near += 1.0 + 0.25 * _coverage(c["pos"])
		score += near
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
