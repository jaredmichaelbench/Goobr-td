class_name MazeGrid
extends RefCounted
## The build grid and its flow field. Every open cell stores its step distance
## to the goal, and creeps walk downhill. Recomputed whenever the maze changes.

const UNREACHABLE := -1
const DIRS: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]

var size: Vector2i
var spawn: Vector2i
var goal: Vector2i
var blocked := {}  # Vector2i -> true
var distance := PackedInt32Array()


func _init(grid_size: Vector2i, spawn_cell: Vector2i, goal_cell: Vector2i) -> void:
	size = grid_size
	spawn = spawn_cell
	goal = goal_cell
	rebuild()


func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < size.x and c.y < size.y


func is_open(c: Vector2i) -> bool:
	return in_bounds(c) and not blocked.has(c)


func dist(c: Vector2i) -> int:
	return distance[c.y * size.x + c.x] if in_bounds(c) else UNREACHABLE


## Breadth-first search outward from the goal.
func rebuild() -> void:
	distance = _compute(blocked)


## Would blocking these cells still leave a route from spawn to goal, and
## keep every cell in `must_reach` (cells creeps stand on) connected?
func can_block(cells: Array[Vector2i], must_reach: Array[Vector2i]) -> bool:
	for c in cells:
		if not is_open(c) or c == spawn or c == goal:
			return false
	var trial := blocked.duplicate()
	for c in cells:
		trial[c] = true
	var d := _compute(trial)
	if d[spawn.y * size.x + spawn.x] == UNREACHABLE:
		return false
	for c in must_reach:
		if trial.has(c) or d[c.y * size.x + c.x] == UNREACHABLE:
			return false
	return true


## The open neighbour one step closer to the goal, or the cell itself at the goal.
func next_step(c: Vector2i) -> Vector2i:
	var best := c
	var best_d := dist(c)
	for dir in DIRS:
		var n := c + dir
		var nd := dist(n)
		if nd != UNREACHABLE and (best_d == UNREACHABLE or nd < best_d):
			best = n
			best_d = nd
	return best


## Cells along the current route from spawn to goal, for drawing.
func route() -> Array[Vector2i]:
	var cells: Array[Vector2i] = [spawn]
	var c := spawn
	var guard := size.x * size.y
	while c != goal and guard > 0:
		var n := next_step(c)
		if n == c:
			break
		cells.append(n)
		c = n
		guard -= 1
	return cells


func _compute(walls: Dictionary) -> PackedInt32Array:
	var d := PackedInt32Array()
	d.resize(size.x * size.y)
	d.fill(UNREACHABLE)
	d[goal.y * size.x + goal.x] = 0
	var queue: Array[Vector2i] = [goal]
	var head := 0
	while head < queue.size():
		var c := queue[head]
		head += 1
		var cd := d[c.y * size.x + c.x]
		for dir in DIRS:
			var n := c + dir
			if in_bounds(n) and not walls.has(n) and d[n.y * size.x + n.x] == UNREACHABLE:
				d[n.y * size.x + n.x] = cd + 1
				queue.append(n)
	return d
