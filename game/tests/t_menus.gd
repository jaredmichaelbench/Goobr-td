extends SceneTree
# T-038: the restyled screens as screenshots: a pinned tower card, the talent tree,
# the morning, the card pick and the results. Arg: out folder.
var m; var run; var f := 0; var out := ""; var cell := Vector2i(-1, -1)
func _init():
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "user://"
	M7Run.quick = false
	LevelRun.active = true
	run = load("res://run3d.tscn").instantiate(); root.add_child(run)
func shot(name: String):
	root.get_texture().get_image().save_png(out + "/" + name + ".png")
	print("SHOT ", name)
func _process(_d):
	f += 1
	if m == null: m = run.sim
	match f:
		5: m.start_wave()
		20:
			m.gold = 500
			var route = m.grid.route()
			for x in m.GRID_SIZE.x:
				for y in m.GRID_SIZE.y:
					var c := Vector2i(x, y)
					if cell.x < 0 and not m.terrain.has(c) and not route.has(c) and m.in_reach(c) and c != m.GOAL:
						cell = c
			print("place ", m.try_place(cell, "kick"))
			m.selected_cell = cell
			Input.warp_mouse(Vector2(200, 300))
		30: shot("m1_pinned")
		31:
			m.selected_cell = Vector2i(-1, -1)
			m.points = 3
			m.tree_open = true
		40: shot("m2_tree")
		41:
			m.tree_open = false
			m.m7_stats["xp"] = 219.0
			m._finish()
		120: shot("m3_morning")
		121: m.begin_card()
		135:
			print("drafting ", m.drafting, " cards ", m.draft_cards.size())
			shot("m4_cards")
		136:
			if m.drafting: m._pick(0)
			if m.state == "playing": m.state = "won"
		150:
			shot("m5_results")
		151: m.hud.res_details.visible = true
		155:
			shot("m6_details")
			quit()
