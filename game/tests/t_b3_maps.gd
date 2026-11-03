extends SceneTree
# B3: every night's own map. Loads each night through the campaign, checks the
# map parsed (no problems, a route from the mine to the camp, no-build cells),
# that building on no-build ground is refused and open ground far from the camp
# is allowed (the reach rule is off), and screenshots the board. Arg: out folder.
var run; var m; var f := 0; var night := 0; var out := ""
func _init():
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "user://"
	M7Run.quick = false
	_load()
func _load():
	Campaign.begin(night)
	run = load("res://run3d.tscn").instantiate(); root.add_child(run)
	m = null; f = 0
func _process(_d):
	if run == null:
		f += 1
		if f > 3: _load()
		return
	f += 1
	if m == null: m = run.sim
	if f == 6:
		m.start_wave()
		m.health = 99
	if f == 12:
		var route = m.grid.route()
		var nb: Vector2i = m.no_build.keys()[0] if not m.no_build.is_empty() else Vector2i(-1, -1)
		m.gold = 999
		var refused: bool = nb.x < 0 or not m.try_place(nb, "wall")
		# Open ground far from the camp and from anything built: allowed now.
		var far := Vector2i(-1, -1)
		for x in range(6, 12):
			for y in range(1, 15):
				var c := Vector2i(x, y)
				if far.x < 0 and not m.terrain.has(c) and not m.no_build.has(c) and not route.has(c) and m.grid.can_block([c] as Array[Vector2i], m._creep_cells()):
					far = c
		var allowed: bool = far.x >= 0 and m.try_place(far, "kick")
		print("NIGHT %d  map %s  problems %s  rocks %d  no-build %d  route %d  no-build refused %s  far build %s %s" % [night + 1, m.has_map, m.night["problems"], m.terrain.size(), m.no_build.size(), route.size(), refused, far, allowed])
		m.build_mode = true
		m.selected = "kick"
	if f == 20:
		root.get_texture().get_image().save_png(out + "/b3_night%d.png" % (night + 1))
		run.queue_free(); run = null; f = 0
		night += 1
		if night >= Campaign.NIGHTS.size():
			quit()
