extends SceneTree
# Demo 1 readability pass (D-0045): the HUD states one by one, as screenshots.
# Arg: out folder.
var m; var run; var f := 0; var out := ""
func _init():
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "user://"
	M7Run.quick = false
	run = load("res://run3d.tscn").instantiate(); root.add_child(run)
func shot(name: String):
	root.get_texture().get_image().save_png(out + "/" + name + ".png")
	print("SHOT ", name)
func _process(_d):
	f += 1
	if m == null: m = run.sim
	match f:
		5:
			m.gold = 2000
			for t in ["poison", "lightning", "light"]:
				if not m.unlocked.has(t): m.unlocked.append(t)
			var cells := [Vector2i(4, 5), Vector2i(5, 5), Vector2i(6, 5), Vector2i(4, 9), Vector2i(5, 9), Vector2i(6, 9), Vector2i(8, 5), Vector2i(8, 9)]
			var types := ["kick", "kick", "bass", "slow", "poison", "lightning", "light", "kick"]
			for i in cells.size(): m.try_place(cells[i], types[i])
			for c in [Vector2i(10, 6), Vector2i(10, 7), Vector2i(11, 7), Vector2i(10, 10)]: m.try_place(c, "wall")
			m.type_rank["kick"] = 3; m.type_branch["kick"] = 1
			m.type_rank["bass"] = 1
			m.type_rank["slow"] = 2
			m.selected_cell = Vector2i(4, 5)
			m.gold = 40
		30: shot("u1_selected")
		32:
			m.start_wave()
		90:
			m._show_feedback("CRIT  SNIPE  Good  -51 ms   52 damage   x2.00 crossfire   5 veils cracked", Color(1, 0.9, 0.3))
			m.streak = 12; m.intensity = 2
		95: shot("u2_judgment")
		100:
			m.points = 5; m.level = 6
			m.toggle_tree()
		110: shot("u3_tree")
		112: m.toggle_tree()
		115: m.toggle_pause()
		125: shot("u4_pause")
		127: m.toggle_pause()
		130:
			m.creeps.clear(); m.wave_active = false
			m.wave_log.append("W1  notes 5/6  parries 1/1  counters 0/0  hp -0")
		140: shot("u5_wave_card")
		150: quit()
