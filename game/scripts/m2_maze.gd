extends Node2D
## M2: the maze. Build walls and towers on a grid while creeps reroute live.
## Answers P-02: does live rerouting feel frictionless and readable?
##
## B = build mode. In build mode: 1 = wall, Q/W/E = kick/hat/bass tower,
## left click = place, right click = sell (75% refund).
## N = start next wave. R = restart after a win or loss. Esc twice = menu.
##
## Test tools (playtesting only, not part of the game):
## T = cycle speed 1x/2x/4x/8x   Y = auto-send waves   G = +100 gold
## H = skip ahead one wave of difficulty. After wave 10, N keeps going (endless).
##
## Towers fire on simple cooldowns here. M3 moves them onto the beat.

const GRID_SIZE := Vector2i(26, 16)  # Wider than tall: boards read horizontal (Jared, 2026-10-25).
const TILE := 30.0
const SPAWN := Vector2i(0, 8)
const GOAL := Vector2i(25, 8)
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
var _to_spawn := 0  # Creeps still to come this wave (the spawn queue's size).
var spawn_queue: Array[Dictionary] = []  # {"kind", "gap"} in spawn order; see wave_plan().
var sim_time := 0.0  # Seconds of simulation, for slows and freezes.
var _spawn_timer := 0.0
var _message := ""
var _message_time := 0.0
var _origin := Vector2.ZERO
var endless := false
var paused := false  # P. The sim and the clock hold.
var hud_left := 120.0  # Pixels the board is pushed right to leave room for the HUD column.
var selected_cell := Vector2i(-1, -1)  # A tower picked with the mouse (M6 panel), or (-1, -1).
# Map and balance knobs. M2 uses a flat map with unlimited walls; later
# milestones override these before _ready().
var terrain := {}  # Vector2i -> true. Rock: no walking, no building.
var iso := false  # Look-test: draw the board as a 2:1 isometric diamond (I toggles).
var _iso_w := TILE * 1.5  # Width of one tile diamond on screen; set per frame to fit the view.
var wall_limit := 0  # 0 = unlimited.
var creep_hp := 18.0
## Creep kinds (D-0033). hp and speed multiply the wave's base; armour is flat
## damage ignored per hit; veil = immune to towers until a note cracks it.
const CREEP_KINDS := {
	"grunt": {"hp": 1.0, "speed": 1.0, "color": Color(0.9, 0.3, 0.35), "radius": 0.28},
	"runner": {"hp": 0.5, "speed": 2.0, "color": Color(1.0, 0.75, 0.3), "radius": 0.22},
	"brute": {"hp": 3.0, "speed": 0.8, "color": Color(0.6, 0.35, 0.3), "radius": 0.36, "armour": 4.0},
	"swarm": {"hp": 0.4, "speed": 1.1, "color": Color(0.95, 0.45, 0.6), "radius": 0.16},
	"shade": {"hp": 1.2, "speed": 1.0, "color": Color(0.35, 0.3, 0.55), "radius": 0.28, "veil": true},
}
const VEIL_CRACK_BEATS := 3.0  # A landed note opens every Shade's veil for this long.
const WARDEN_COVER := 2.0  # Tiles around a Warden whose creeps it takes the damage for.
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
	spawn_queue.clear()
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
		elif event.keycode == KEY_T:
			speed_index = (speed_index + 1) % SPEEDS.size()
		elif event.keycode == KEY_Y:
			auto_send = not auto_send
			_auto_timer = AUTO_SEND_DELAY
		elif event.keycode == KEY_G:
			gold += 100
		elif event.keycode == KEY_H and not wave_active:
			wave += 1
		elif event.keycode == KEY_B:
			build_mode = not build_mode
		elif event.keycode == KEY_N:
			start_wave()
		elif event.keycode == KEY_I:
			iso = not iso
		elif event.keycode == KEY_U and state == "playing":
			upgrade(cell_at(get_local_mouse_position()))
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


## The spec a tower fires with: its base type, or its upgraded copy.
func tower_spec(cell: Vector2i) -> Dictionary:
	var s: Dictionary = structures[cell]
	return s["spec"] if s.has("spec") else builds[s["type"]]


func upgrade_cost(cell: Vector2i) -> int:
	return int(builds[structures[cell]["type"]]["cost"])


## One upgrade tier per tower: +50% damage, +0.4 range, for the tower's base cost.
func upgrade(cell: Vector2i) -> bool:
	if not structures.has(cell) or not builds[structures[cell]["type"]].has("range"):
		return false
	var s: Dictionary = structures[cell]
	if s.get("tier", 0) >= 1:
		_say("Already upgraded")
		return false
	var cost := upgrade_cost(cell)
	if gold < cost:
		_say("Not enough gold (%dg to upgrade)" % cost)
		return false
	gold -= cost
	var spec: Dictionary = builds[s["type"]].duplicate()
	spec["damage"] = spec["damage"] * 1.5
	spec["range"] = spec["range"] + 0.4
	s["spec"] = spec
	s["tier"] = 1
	s["paid"] = int(s.get("paid", builds[s["type"]]["cost"])) + cost
	return true


func sell(cell: Vector2i) -> void:
	if not structures.has(cell):
		return
	gold += int(structures[cell].get("paid", builds[structures[cell]["type"]]["cost"]) * SELL_REFUND)
	structures.erase(cell)
	grid.blocked.erase(cell)
	grid.rebuild()
	if selected_cell == cell:
		selected_cell = Vector2i(-1, -1)


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
	spawn_queue = wave_plan(wave)
	_to_spawn = spawn_queue.size()
	_spawn_timer = 0.0


## What a wave sends, in order. M2 sends grunts; M3+ use the wave script.
func wave_plan(w: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in creeps_in_wave(w):
		out.append({"kind": "grunt", "gap": 0.7})
	return out


func creep_hp_at(w: int) -> float:
	return creep_hp * pow(creep_hp_growth, w - 1)


func creeps_in_wave(w: int) -> int:
	return 8 + 2 * w


## One line about the wave for the HUD.
func wave_summary(w: int) -> String:
	return "%d creeps" % creeps_in_wave(w)


func _spawn_creep(kind := "grunt") -> Dictionary:
	var k: Dictionary = CREEP_KINDS.get(kind, CREEP_KINDS["grunt"])
	var hp: float = creep_hp_at(wave) * k["hp"]
	var c := {
		"pos": Vector2(SPAWN),
		"target": SPAWN,
		"hp": hp,
		"max_hp": hp,
		"speed": (1.5 + 0.04 * wave) * k["speed"],
		"kind": kind,
	}
	if k.has("armour"):
		c["armour"] = k["armour"]
	if k.get("veil", false):
		c["veil"] = true
		c["veil_open_until"] = 0.0
	creeps.append(c)
	return c


## Is this creep's veil up right now (towers can't hurt it)?
func veiled(c: Dictionary) -> bool:
	return c.get("veil", false) and c.get("veil_open_until", 0.0) <= sim_time


## A note landed: every Shade's veil opens for a few beats.
func crack_veils(seconds: float) -> int:
	var n := 0
	for c in creeps:
		if c.get("veil", false) and c["hp"] > 0.0:
			c["veil_open_until"] = sim_time + seconds
			n += 1
	return n


## The Warden covering this creep, if one is near and still unbroken.
func cover_for(c: Dictionary) -> Dictionary:
	if c.get("covering", false) or c.get("boss", false):
		return {}
	for w in creeps:
		if w.get("covering", false) and w["hp"] > 0.0 and w != c and w["pos"].distance_to(c["pos"]) <= WARDEN_COVER:
			return w
	return {}


## Every hit on a creep goes through here (D-0033): a Warden's cover takes it,
## a veiled Shade ignores it, a Brute's armour knocks a flat amount off.
## Returns the damage actually dealt.
func damage(c: Dictionary, amount: float) -> float:
	var cover := cover_for(c)
	if not cover.is_empty():
		c = cover
	if veiled(c):
		return 0.0
	amount = maxf(0.0, amount - c.get("armour", 0.0))
	var dealt := minf(amount, maxf(c["hp"], 0.0))
	c["hp"] -= amount
	return dealt


# --- Simulation ----------------------------------------------------------------

func _process(delta: float) -> void:
	_esc_time = maxf(0.0, _esc_time - delta)
	# Speed-up runs extra simulation steps so collisions and pathing stay accurate.
	if not paused:
		for i in SPEEDS[speed_index]:
			step(delta)
	if auto_send and state == "playing" and not wave_active and not paused:
		_auto_timer -= delta
		if _auto_timer <= 0.0:
			_auto_timer = AUTO_SEND_DELAY
			start_wave()
	queue_redraw()


## One simulation tick. Separate from _process so tests can drive it.
func step(delta: float) -> void:
	_message_time = maxf(0.0, _message_time - delta)
	sim_time += delta
	var live_shots: Array[Dictionary] = []
	for s in shots:
		s["ttl"] -= delta
		if s["ttl"] > 0.0:
			live_shots.append(s)
	shots = live_shots
	if state != "playing":
		return

	if not spawn_queue.is_empty():
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			var e: Dictionary = spawn_queue.pop_front()
			_spawn_creep(e["kind"])
			_spawn_timer = e["gap"]
	_to_spawn = spawn_queue.size()

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
		gold += 12 + wave * 3
		if wave == LAST_WAVE and not endless:
			state = "won"


func _move_creeps(delta: float) -> void:
	for c in creeps:
		var factor := 1.0
		if c.get("frozen_until", 0.0) > sim_time:
			factor = 0.0
		elif c.get("slow_until", 0.0) > sim_time:
			factor = 0.5
		var remaining: float = c["speed"] * delta * factor
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
		var spec: Dictionary = tower_spec(cell)
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
					damage(c, spec["damage"])
		else:
			damage(target, spec["damage"])
		shots.append({"from": Vector2(cell), "to": target["pos"], "color": spec["color"], "ttl": 0.12, "splash": spec["splash"]})


## The creep in range that is closest to the goal.
func _pick_target(from: Vector2, tower_range: float) -> Dictionary:
	var best := {}
	var best_d := INF
	for c in creeps:
		if c["hp"] <= 0.0 or veiled(c) or c["pos"].distance_to(from) > tower_range:
			continue
		var d: float = float(grid.dist(c["target"])) + c["pos"].distance_to(Vector2(c["target"]))
		if d < best_d:
			best = c
			best_d = d
	return best


# --- Drawing -----------------------------------------------------------------

func cell_at(screen_pos: Vector2) -> Vector2i:
	if iso:
		var d := screen_pos - _origin
		var u := d.x / (_iso_w * 0.5)
		var v := d.y / (_iso_w * 0.25)
		return Vector2i(Vector2((u + v) * 0.5, (v - u) * 0.5).floor())
	return Vector2i(((screen_pos - _origin) / TILE).floor())


## A grid corner (not a cell centre) on screen. Everything board-shaped goes
## through here, so the isometric look-test is one projection swap.
func _grid_to_screen(g: Vector2) -> Vector2:
	if iso:
		return _origin + Vector2((g.x - g.y) * _iso_w * 0.5, (g.x + g.y) * _iso_w * 0.25)
	return _origin + g * TILE


## The four screen corners of a cell, optionally inset (in tiles) and lifted
## (in pixels, for raised blocks).
func _cell_poly(cell: Vector2i, inset := 0.0, lift := 0.0) -> PackedVector2Array:
	var c := Vector2(cell)
	var up := Vector2(0, -lift)
	return PackedVector2Array([
		_grid_to_screen(c + Vector2(inset, inset)) + up,
		_grid_to_screen(c + Vector2(1.0 - inset, inset)) + up,
		_grid_to_screen(c + Vector2(1.0 - inset, 1.0 - inset)) + up,
		_grid_to_screen(c + Vector2(inset, 1.0 - inset)) + up,
	])


func _draw_cell(cell: Vector2i, color: Color, inset := 0.0, lift := 0.0) -> void:
	draw_colored_polygon(_cell_poly(cell, inset, lift), color)


## A raised block: top face plus the two visible side faces in iso, or a flat
## cell with a lighter top edge in plain view.
func _draw_block(cell: Vector2i, top: Color, side: Color, height: float, inset := 0.0) -> void:
	if not iso:
		_draw_cell(cell, side, inset)
		var r := Rect2(_origin + Vector2(cell) * TILE, Vector2(TILE, TILE)).grow(-inset * TILE)
		draw_rect(Rect2(r.position, Vector2(r.size.x, 4)), top)
		return
	var base := _cell_poly(cell, inset)
	var lift := Vector2(0, -height)
	# base[1] is the right corner, base[2] the bottom, base[3] the left.
	draw_colored_polygon(PackedVector2Array([base[1], base[2], base[2] + lift, base[1] + lift]), side * Color(0.85, 0.85, 0.85))
	draw_colored_polygon(PackedVector2Array([base[2], base[3], base[3] + lift, base[2] + lift]), side * Color(0.7, 0.7, 0.7))
	draw_colored_polygon(_cell_poly(cell, inset, height), top)


func _board_poly() -> PackedVector2Array:
	return PackedVector2Array([
		_grid_to_screen(Vector2.ZERO),
		_grid_to_screen(Vector2(GRID_SIZE.x, 0)),
		_grid_to_screen(Vector2(GRID_SIZE)),
		_grid_to_screen(Vector2(0, GRID_SIZE.y)),
	])


func _on_board(p: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(p, _board_poly())


func _to_screen(grid_pos: Vector2) -> Vector2:
	return _grid_to_screen(grid_pos + Vector2(0.5, 0.5))


func _say(text: String) -> void:
	_message = text
	_message_time = 1.5


## Nudge: gold sitting unspent in the build phase.
func _unspent_hint() -> String:
	var cheapest := INF
	for type in builds:
		if type != "wall":
			cheapest = minf(cheapest, builds[type]["cost"])
	if gold >= cheapest:
		return "   (%d gold unspent)" % gold
	return ""


func status_lines() -> Array[String]:
	var wave_label := ("Wave %d (endless)" % wave) if endless or wave > LAST_WAVE else ("Wave %d/%d" % [wave, LAST_WAVE])
	var lines: Array[String] = [
		"Gold %d    Health %d" % [gold, health],
		(wave_label + " in progress") if wave_active else ("Press N to start wave %d%s" % [wave + 1, _unspent_hint()]),
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
		"TEST  T speed %dx   Y auto-send %s" % [SPEEDS[speed_index], "ON" if auto_send else "off"],
		"TEST  G +100g   H skip a wave   I isometric look-test %s" % ("ON" if iso else "off"),
		"Next wave: %s   (%.0f HP each)" % [wave_summary(wave + 1), creep_hp_at(wave + 1)],
	]


func _draw() -> void:
	var view := get_viewport_rect().size
	if iso:
		# Fit the diamond beside the HUD: width (W+H)/2 tiles, height (W+H)/4.
		var n := float(GRID_SIZE.x + GRID_SIZE.y)
		_iso_w = minf(TILE * 1.5, minf(2.0 * (view.x - 500.0) / n, 4.0 * (view.y - 90.0) / n))
		var center := Vector2((view.x + hud_left * 4.0) * 0.5, view.y * 0.5 + 10.0)
		_origin = center - Vector2((GRID_SIZE.x - GRID_SIZE.y) * _iso_w * 0.25, n * _iso_w * 0.125)
	else:
		_origin = Vector2((view.x - GRID_SIZE.x * TILE) * 0.5 + hud_left, (view.y - GRID_SIZE.y * TILE) * 0.5)
	var font := ThemeDB.fallback_font

	# Board and route.
	draw_colored_polygon(_board_poly(), Color(0.13, 0.14, 0.17))
	for x in GRID_SIZE.x + 1:
		draw_line(_grid_to_screen(Vector2(x, 0)), _grid_to_screen(Vector2(x, GRID_SIZE.y)), Color(1, 1, 1, 0.05))
	for y in GRID_SIZE.y + 1:
		draw_line(_grid_to_screen(Vector2(0, y)), _grid_to_screen(Vector2(GRID_SIZE.x, y)), Color(1, 1, 1, 0.05))
	var route := grid.route()
	for i in route.size() - 1:
		draw_line(_to_screen(Vector2(route[i])), _to_screen(Vector2(route[i + 1])), Color(1, 1, 1, 0.12), 3.0)
	_draw_cell(SPAWN, Color(0.3, 0.8, 0.4, 0.5))
	_draw_cell(GOAL, Color(1.0, 0.85, 0.3, 0.6))

	# Rock and structures, back to front so raised blocks overlap correctly in iso.
	var raised: Array[Vector2i] = []
	for c in terrain:
		raised.append(c)
	for cell in structures:
		raised.append(cell)
	raised.sort_custom(func(a, b): return a.x + a.y < b.x + b.y)
	var block_h := _iso_w * 0.45 if iso else 0.0
	for cell in raised:
		if terrain.has(cell):
			_draw_block(cell, Color(0.38, 0.33, 0.29), Color(0.29, 0.25, 0.22), block_h)
			continue
		var type: String = structures[cell]["type"]
		if type == "wall":
			_draw_block(cell, builds[type]["color"] * Color(1.1, 1.1, 1.1), builds[type]["color"], block_h * 0.7, 0.07)
		else:
			_draw_block(cell, Color(0.26, 0.26, 0.3), Color(0.2, 0.2, 0.24), block_h * 0.35, 0.07)
			var tc := _to_screen(Vector2(cell)) + Vector2(0, -block_h * 0.35)
			draw_circle(tc, TILE * 0.32, builds[type]["color"])
			if structures[cell].get("tier", 0) >= 1:
				# Upgraded: a white chevron over the tower.
				draw_polyline(PackedVector2Array([tc + Vector2(-6, -8), tc + Vector2(0, -13), tc + Vector2(6, -8)]), Color.WHITE, 2.0)

	# Creeps and shots.
	for c in creeps:
		var p := _to_screen(c["pos"])
		var k: Dictionary = CREEP_KINDS.get(c.get("kind", "grunt"), CREEP_KINDS["grunt"])
		var body: Color = k["color"]
		if c.get("frozen_until", 0.0) > sim_time:
			body = Color(0.75, 0.9, 1.0)
		elif c.get("slow_until", 0.0) > sim_time:
			body = Color(0.7, 0.5, 0.8)
		var r: float = TILE * k["radius"]
		if veiled(c):
			# A Shade behind its veil: a dark body in a pale halo.
			draw_circle(p, r * 1.5, Color(0.6, 0.6, 0.9, 0.18))
			draw_arc(p, r * 1.5, 0, TAU, 24, Color(0.75, 0.75, 1.0, 0.6), 1.5)
			body = body.darkened(0.3)
		draw_circle(p, r, body)
		if c.get("kind", "") == "brute":
			draw_arc(p, r, 0, TAU, 24, Color(0.85, 0.85, 0.9), 2.5)  # Armour plate.
		elif c.get("kind", "") == "runner":
			draw_line(p + Vector2(-r * 1.6, 0), p - Vector2(r * 0.4, 0), Color(1, 1, 1, 0.5), 2.0)  # Speed line.
		elif c.get("kind", "") == "shade" and not veiled(c):
			draw_arc(p, r * 1.5, 0, TAU, 24, Color(1, 1, 1, 0.5), 1.0)  # Cracked veil.
		var frac: float = clampf(c["hp"] / c["max_hp"], 0.0, 1.0)
		var w: float = maxf(12.0, r * 1.6)
		draw_rect(Rect2(p + Vector2(-w, -r - 8), Vector2(2.0 * w * frac, 3)), Color(0.4, 1.0, 0.4))
	for s in shots:
		var a := clampf(s["ttl"] / 0.12, 0.0, 1.0)
		draw_line(_to_screen(s["from"]), _to_screen(s["to"]), s["color"] * Color(1, 1, 1, a), s.get("width", 2.0))
		if s["splash"] > 0.0:
			draw_arc(_to_screen(s["to"]), s["splash"] * TILE, 0, TAU, 32, s["color"] * Color(1, 1, 1, a * 0.6), 2.0)

	# The selected tower (M6 panel): a white ring and its range.
	if structures.has(selected_cell) and tower_spec(selected_cell).has("range"):
		var sp := _to_screen(Vector2(selected_cell))
		draw_arc(sp, TILE * 0.5, 0, TAU, 32, Color.WHITE, 2.5)
		draw_arc(sp, tower_spec(selected_cell)["range"] * TILE, 0, TAU, 64, Color(1, 1, 1, 0.5), 1.5)

	# Hover ghost and range.
	var hover := cell_at(get_local_mouse_position())
	if build_mode and grid.in_bounds(hover) and state == "playing":
		var ok: bool = gold >= builds[selected]["cost"] and grid.can_block([hover], _creep_cells())
		if selected == "wall" and wall_limit > 0 and wall_count() >= wall_limit:
			ok = false
		_draw_cell(hover, Color(0.3, 1.0, 0.4, 0.3) if ok else Color(1.0, 0.3, 0.3, 0.3))
		if builds[selected].has("range"):
			draw_arc(_to_screen(Vector2(hover)), builds[selected]["range"] * TILE, 0, TAU, 48, Color(1, 1, 1, 0.3), 1.5)
	if structures.has(hover) and tower_spec(hover).has("range"):
		draw_arc(_to_screen(Vector2(hover)), tower_spec(hover)["range"] * TILE, 0, TAU, 48, Color(1, 1, 1, 0.4), 1.5)

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
	if state != "playing" and get("hud") == null:  # M6 shows this on its run screen instead.
		var text := "Wave 10 cleared!  N for endless, R to restart" if state == "won" else "The goal fell.  R to try again"
		draw_string(font, Vector2(_origin.x, _origin.y - 16), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(1, 0.85, 0.3))
