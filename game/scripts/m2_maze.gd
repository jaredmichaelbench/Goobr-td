extends Node2D
## M2: the maze. Build walls and towers on a grid while creeps reroute live.
## Answers P-02: does live rerouting feel frictionless and readable?
##
## B = build mode. In build mode: 1 = wall, Q/W/E = kick/hat/bass tower,
## left click = place, right click = sell (75% refund).
## N = start next wave. R = restart after a win or loss. Esc twice = menu.
##
## Test tools (playtesting only, not part of the game):
## F1 = cycle speed 1x/2x/4x/8x   F2 = auto-send waves   F3 = +100 gold
## F4 = skip ahead one wave of difficulty. After wave 10, N keeps going (endless).
##
## Towers fire on simple cooldowns here. M3 moves them onto the beat.

const GRID_SIZE := Vector2i(20, 20)
const TILE := 30.0
const SPAWN := Vector2i(0, 10)
const GOAL := Vector2i(19, 10)
const LAST_WAVE := 10
const START_GOLD := 150
const START_HEALTH := 20
const SELL_REFUND := 0.75
const SPEEDS: Array[int] = [1, 2, 4, 8]
const AUTO_SEND_DELAY := 2.0
const ESC_CONFIRM_TIME := 1.5

const BASE_BUILDS := {
	"wall": {"cost": 4, "color": Color(0.55, 0.55, 0.6)},
	"kick": {"cost": 20, "color": Color(1.0, 0.55, 0.3), "range": 2.6, "damage": 14.0, "cooldown": 1.0, "splash": 0.0},
	"hat": {"cost": 15, "color": Color(0.4, 0.85, 1.0), "range": 2.0, "damage": 3.0, "cooldown": 0.25, "splash": 0.0},
	"bass": {"cost": 25, "color": Color(0.7, 0.45, 1.0), "range": 2.0, "damage": 7.0, "cooldown": 1.0, "splash": 1.1},
}

var builds: Dictionary = BASE_BUILDS.duplicate(true)
var grid: MazeGrid
var gold := START_GOLD
var health := START_HEALTH
var wave := 0
var wave_active := false
var build_mode := true
var selected := "wall"
var state := "playing"  # playing, won, lost

var structures := {}  # Vector2i -> {"type", "cooldown"}
var creeps: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var _to_spawn := 0
var _spawn_timer := 0.0
var _message := ""
var _message_time := 0.0
var _origin := Vector2.ZERO
var endless := false
# Map and balance knobs. M2 uses a flat map with unlimited walls; later
# milestones override these before _ready().
var terrain := {}  # Vector2i -> true. Rock: no walking, no building.
var wall_limit := 0  # 0 = unlimited.
var creep_hp := 18.0
var creep_hp_growth := 1.2
var kill_gold := 2
var title := "M2 Maze"
var build_keys := {KEY_1: "wall", KEY_Q: "kick", KEY_W: "hat", KEY_E: "bass"}

# Test tools.
var speed_index := 0
var auto_send := false
var _auto_timer := 0.0
var _esc_time := 0.0


func _ready() -> void:
	reset()


func reset() -> void:
	grid = MazeGrid.new(GRID_SIZE, SPAWN, GOAL)
	for c in terrain:
		grid.blocked[c] = true
	grid.rebuild()
	gold = START_GOLD
	health = START_HEALTH
	wave = 0
	wave_active = false
	state = "playing"
	structures.clear()
	creeps.clear()
	shots.clear()
	_to_spawn = 0
	endless = false


# --- Input -------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if _esc_time > 0.0:
				get_tree().change_scene_to_file("res://menu.tscn")
			else:
				_esc_time = ESC_CONFIRM_TIME
				_say("Press Esc again to quit to the menu")
		elif event.keycode == KEY_R and state != "playing":
			reset()
		elif event.keycode == KEY_F1:
			speed_index = (speed_index + 1) % SPEEDS.size()
		elif event.keycode == KEY_F2:
			auto_send = not auto_send
			_auto_timer = AUTO_SEND_DELAY
		elif event.keycode == KEY_F3:
			gold += 100
		elif event.keycode == KEY_F4 and not wave_active:
			wave += 1
		elif event.keycode == KEY_B:
			build_mode = not build_mode
		elif event.keycode == KEY_N:
			start_wave()
		elif build_mode and build_keys.has(event.keycode):
			selected = build_keys[event.keycode]
	elif event is InputEventMouseButton and event.pressed and build_mode and state == "playing":
		var cell := cell_at(event.position)
		if event.button_index == MOUSE_BUTTON_LEFT:
			try_place(cell, selected)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			sell(cell)


# --- Building ----------------------------------------------------------------

func try_place(cell: Vector2i, type: String) -> bool:
	var cost: int = builds[type]["cost"]
	if not grid.in_bounds(cell):
		return false
	if terrain.has(cell):
		_say("Can't build on rock")
		return false
	if type == "wall" and wall_limit > 0 and wall_count() >= wall_limit:
		_say("Out of walls (%d max)" % wall_limit)
		return false
	if gold < cost:
		_say("Not enough gold")
		return false
	if not grid.can_block([cell], _creep_cells()):
		_say("That would block the path")
		return false
	grid.blocked[cell] = true
	grid.rebuild()
	structures[cell] = {"type": type, "cooldown": 0.0}
	gold -= cost
	return true


func sell(cell: Vector2i) -> void:
	if not structures.has(cell):
		return
	gold += int(builds[structures[cell]["type"]]["cost"] * SELL_REFUND)
	structures.erase(cell)
	grid.blocked.erase(cell)
	grid.rebuild()


func wall_count() -> int:
	var n := 0
	for cell in structures:
		if structures[cell]["type"] == "wall":
			n += 1
	return n


## Cells creeps occupy or are walking into; building there is not allowed.
func _creep_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for c in creeps:
		cells.append(Vector2i(c["pos"].round()))
		cells.append(c["target"])
	return cells


# --- Waves -------------------------------------------------------------------

func start_wave() -> void:
	if state == "won":
		endless = true
		state = "playing"
	if wave_active or state != "playing":
		return
	wave += 1
	wave_active = true
	_to_spawn = creeps_in_wave(wave)
	_spawn_timer = 0.0


func creep_hp_at(w: int) -> float:
	return creep_hp * pow(creep_hp_growth, w - 1)


func creeps_in_wave(w: int) -> int:
	return 8 + 2 * w


func _spawn_creep() -> void:
	var hp := creep_hp_at(wave)
	creeps.append({
		"pos": Vector2(SPAWN),
		"target": SPAWN,
		"hp": hp,
		"max_hp": hp,
		"speed": 1.5 + 0.04 * wave,
	})


# --- Simulation ----------------------------------------------------------------

func _process(delta: float) -> void:
	_esc_time = maxf(0.0, _esc_time - delta)
	# Speed-up runs extra simulation steps so collisions and pathing stay accurate.
	for i in SPEEDS[speed_index]:
		step(delta)
	if auto_send and state == "playing" and not wave_active:
		_auto_timer -= delta
		if _auto_timer <= 0.0:
			_auto_timer = AUTO_SEND_DELAY
			start_wave()
	queue_redraw()


## One simulation tick. Separate from _process so tests can drive it.
func step(delta: float) -> void:
	_message_time = maxf(0.0, _message_time - delta)
	var live_shots: Array[Dictionary] = []
	for s in shots:
		s["ttl"] -= delta
		if s["ttl"] > 0.0:
			live_shots.append(s)
	shots = live_shots
	if state != "playing":
		return

	if _to_spawn > 0:
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			_spawn_creep()
			_to_spawn -= 1
			_spawn_timer = 0.7

	_move_creeps(delta)
	_fire_towers(delta)

	var alive: Array[Dictionary] = []
	for c in creeps:
		if c["hp"] <= 0.0:
			gold += kill_gold
		elif c.get("leaked", false):
			health -= 1
		else:
			alive.append(c)
	creeps = alive

	if health <= 0:
		health = 0
		state = "lost"
	elif wave_active and _to_spawn == 0 and creeps.is_empty():
		wave_active = false
		gold += 10 + wave * 2
		if wave == LAST_WAVE and not endless:
			state = "won"


func _move_creeps(delta: float) -> void:
	for c in creeps:
		var remaining: float = c["speed"] * delta
		while remaining > 0.0:
			var target := Vector2(c["target"])
			var to_target: Vector2 = target - c["pos"]
			var d := to_target.length()
			if d > remaining:
				c["pos"] += to_target / d * remaining
				break
			c["pos"] = target
			remaining -= d
			if c["target"] == GOAL:
				c["leaked"] = true
				break
			c["target"] = grid.next_step(c["target"])


func _fire_towers(delta: float) -> void:
	for cell in structures:
		var s: Dictionary = structures[cell]
		if s["type"] == "wall":
			continue
		var spec: Dictionary = builds[s["type"]]
		s["cooldown"] = maxf(0.0, s["cooldown"] - delta)
		if s["cooldown"] > 0.0:
			continue
		var target := _pick_target(Vector2(cell), spec["range"])
		if target.is_empty():
			continue
		s["cooldown"] = spec["cooldown"]
		if spec["splash"] > 0.0:
			for c in creeps:
				if c["pos"].distance_to(target["pos"]) <= spec["splash"]:
					c["hp"] -= spec["damage"]
		else:
			target["hp"] -= spec["damage"]
		shots.append({"from": Vector2(cell), "to": target["pos"], "color": spec["color"], "ttl": 0.12, "splash": spec["splash"]})


## The creep in range that is closest to the goal.
func _pick_target(from: Vector2, tower_range: float) -> Dictionary:
	var best := {}
	var best_d := INF
	for c in creeps:
		if c["hp"] <= 0.0 or c["pos"].distance_to(from) > tower_range:
			continue
		var d: float = float(grid.dist(c["target"])) + c["pos"].distance_to(Vector2(c["target"]))
		if d < best_d:
			best = c
			best_d = d
	return best


# --- Drawing -----------------------------------------------------------------

func cell_at(screen_pos: Vector2) -> Vector2i:
	return Vector2i(((screen_pos - _origin) / TILE).floor())


func _to_screen(grid_pos: Vector2) -> Vector2:
	return _origin + (grid_pos + Vector2(0.5, 0.5)) * TILE


func _say(text: String) -> void:
	_message = text
	_message_time = 1.5


func status_lines() -> Array[String]:
	var wave_label := ("Wave %d (endless)" % wave) if endless or wave > LAST_WAVE else ("Wave %d/%d" % [wave, LAST_WAVE])
	var lines: Array[String] = [
		"Gold %d    Health %d" % [gold, health],
		(wave_label + " in progress") if wave_active else ("Press N to start wave %d" % (wave + 1)),
		"",
		"Build mode: %s (B)" % ("ON" if build_mode else "off"),
		"Selected: %s (%dg)" % [selected, builds[selected]["cost"]],
	]
	if wall_limit > 0:
		lines.append("Walls %d/%d" % [wall_count(), wall_limit])
	return lines


func help_lines() -> Array[String]:
	var keys := {}
	for k in build_keys:
		keys[build_keys[k]] = OS.get_keycode_string(k)
	return [
		"%s  Wall     4g" % keys["wall"],
		"%s  Kick    20g  slow, heavy" % keys["kick"],
		"%s  Hat     15g  fast, light" % keys["hat"],
		"%s  Bass    25g  splash" % keys["bass"],
		"Left click  place     Right click  sell (75%)",
		"Esc twice  menu",
		"",
		"TEST  F1 speed %dx   F2 auto-send %s" % [SPEEDS[speed_index], "ON" if auto_send else "off"],
		"TEST  F3 +100g   F4 skip a wave",
		"Next wave: %d creeps, %.0f HP each" % [creeps_in_wave(wave + 1), creep_hp_at(wave + 1)],
	]


func _draw() -> void:
	var view := get_viewport_rect().size
	_origin = Vector2((view.x - GRID_SIZE.x * TILE) * 0.5 + 120.0, (view.y - GRID_SIZE.y * TILE) * 0.5)
	var font := ThemeDB.fallback_font

	# Board and route.
	draw_rect(Rect2(_origin, Vector2(GRID_SIZE) * TILE), Color(0.13, 0.14, 0.17))
	for x in GRID_SIZE.x + 1:
		draw_line(_origin + Vector2(x * TILE, 0), _origin + Vector2(x * TILE, GRID_SIZE.y * TILE), Color(1, 1, 1, 0.05))
	for y in GRID_SIZE.y + 1:
		draw_line(_origin + Vector2(0, y * TILE), _origin + Vector2(GRID_SIZE.x * TILE, y * TILE), Color(1, 1, 1, 0.05))
	var route := grid.route()
	for i in route.size() - 1:
		draw_line(_to_screen(Vector2(route[i])), _to_screen(Vector2(route[i + 1])), Color(1, 1, 1, 0.12), 3.0)
	for c in terrain:
		var rock := Rect2(_origin + Vector2(c) * TILE, Vector2(TILE, TILE))
		draw_rect(rock, Color(0.29, 0.25, 0.22))
		draw_rect(Rect2(rock.position, Vector2(TILE, 4)), Color(0.38, 0.33, 0.29))
	draw_rect(Rect2(_origin + Vector2(SPAWN) * TILE, Vector2(TILE, TILE)), Color(0.3, 0.8, 0.4, 0.5))
	draw_rect(Rect2(_origin + Vector2(GOAL) * TILE, Vector2(TILE, TILE)), Color(1.0, 0.85, 0.3, 0.6))

	# Structures.
	for cell in structures:
		var type: String = structures[cell]["type"]
		var r := Rect2(_origin + Vector2(cell) * TILE, Vector2(TILE, TILE)).grow(-2)
		if type == "wall":
			draw_rect(r, builds[type]["color"])
		else:
			draw_rect(r, Color(0.2, 0.2, 0.24))
			draw_circle(r.get_center(), TILE * 0.32, builds[type]["color"])

	# Creeps and shots.
	for c in creeps:
		var p := _to_screen(c["pos"])
		draw_circle(p, TILE * 0.28, Color(0.9, 0.3, 0.35))
		var frac: float = clampf(c["hp"] / c["max_hp"], 0.0, 1.0)
		draw_rect(Rect2(p + Vector2(-12, -16), Vector2(24 * frac, 3)), Color(0.4, 1.0, 0.4))
	for s in shots:
		var a := clampf(s["ttl"] / 0.12, 0.0, 1.0)
		draw_line(_to_screen(s["from"]), _to_screen(s["to"]), s["color"] * Color(1, 1, 1, a), 2.0)
		if s["splash"] > 0.0:
			draw_arc(_to_screen(s["to"]), s["splash"] * TILE, 0, TAU, 32, s["color"] * Color(1, 1, 1, a * 0.6), 2.0)

	# Hover ghost and range.
	var hover := cell_at(get_local_mouse_position())
	if build_mode and grid.in_bounds(hover) and state == "playing":
		var ok: bool = gold >= builds[selected]["cost"] and grid.can_block([hover], _creep_cells())
		if selected == "wall" and wall_limit > 0 and wall_count() >= wall_limit:
			ok = false
		draw_rect(Rect2(_origin + Vector2(hover) * TILE, Vector2(TILE, TILE)), Color(0.3, 1.0, 0.4, 0.3) if ok else Color(1.0, 0.3, 0.3, 0.3))
		if builds[selected].has("range"):
			draw_arc(_to_screen(Vector2(hover)), builds[selected]["range"] * TILE, 0, TAU, 48, Color(1, 1, 1, 0.3), 1.5)
	if structures.has(hover) and builds[structures[hover]["type"]].has("range"):
		draw_arc(_to_screen(Vector2(hover)), builds[structures[hover]["type"]]["range"] * TILE, 0, TAU, 48, Color(1, 1, 1, 0.4), 1.5)

	# HUD: bright status lines, then dimmer help lines.
	var y := 40.0
	draw_string(font, Vector2(24, y), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
	for line in status_lines():
		y += 22.0
		draw_string(font, Vector2(24, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
	y += 10.0
	for line in help_lines():
		y += 21.0
		draw_string(font, Vector2(24, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 1, 1, 0.55))
	if _message_time > 0.0:
		draw_string(font, Vector2(24, view.y - 40), _message, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(1, 0.5, 0.4))
	if state != "playing":
		var text := "Wave 10 cleared!  N for endless, R to restart" if state == "won" else "The goal fell.  R to try again"
		draw_string(font, Vector2(_origin.x, _origin.y - 16), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1, 0.85, 0.3))
