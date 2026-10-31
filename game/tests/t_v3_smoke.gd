extends SceneTree
## Night 1 v3 smoke test: the level scene runs with the HUD and the 3D view, a
## tower built on a wall replaces it with the wall's gold credited, and the
## run log prints by section.
var scene: Node; var f := 0; var cell := Vector2i(-1, -1)

func _init() -> void:
	LevelRun.active = true
	scene = load("res://run3d.tscn").instantiate()
	root.add_child(scene)

func _process(_d: float) -> bool:
	f += 1
	var sim = scene.sim
	if f == 5:
		sim.start_wave()
	if f == 200:
		for x in sim.GRID_SIZE.x:
			for y in sim.GRID_SIZE.y:
				var c := Vector2i(x, y)
				if cell.x < 0 and not sim.structures.has(c) and not sim.terrain.has(c) and c != sim.GOAL and sim.in_reach(c) and sim.grid.can_block([c] as Array[Vector2i], sim._creep_cells()):
					cell = c
		sim.gold = 500
		var ok_wall: bool = sim.try_place(cell, "wall")
		var g0: int = sim.gold
		var want: int = sim.build_cost_at(cell, "kick")
		var ok_tower: bool = sim.try_place(cell, "kick")
		print("SMOKE cell ", cell, " wall ", ok_wall, " swap ", ok_tower, " type ", sim.structures[cell]["type"], " paid ", g0 - sim.gold, " expected ", want, " (tower ", sim.builds["kick"]["cost"], ")")
	if f == 260:
		print("SMOKE view node type ", scene.view._structures[cell]["type"])
		for l in sim.run_lines():
			print("  ", l)
		return true
	return false
