extends SceneTree
# UI slice A (D-0062): build mode on B, the wheel, Shift-click, the cursor tag, the
# hover menu with X sell and U upgrade, the coin pop, judgments at the camp and the
# tower, the camp readout and the corners fading in a push. Arg: out folder.
var m; var run; var f := 0; var out := ""; var cell := Vector2i(-1, -1); var cell2 := Vector2i(-1, -1)
func _init():
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "user://"
	M7Run.quick = false
	LevelRun.active = true
	run = load("res://run3d.tscn").instantiate(); root.add_child(run)
func shot(name: String):
	root.get_texture().get_image().save_png(out + "/" + name + ".png")
	print("SHOT ", name)
func key(k: int, shift := false):
	var e := InputEventKey.new(); e.keycode = k; e.pressed = true; e.shift_pressed = shift
	Input.parse_input_event(e)
func screen(c: Vector2i) -> Vector2:
	return run.view.screen_at(View3D.world(Vector2(c), 0.0))
func move(c: Vector2i):
	var p := screen(c)
	Input.warp_mouse(p)
	var e := InputEventMouseMotion.new(); e.position = p; e.global_position = p
	Input.parse_input_event(e)
func click(c: Vector2i, button := MOUSE_BUTTON_LEFT, shift := false):
	var p := screen(c)
	var e := InputEventMouseButton.new(); e.button_index = button; e.pressed = true; e.position = p; e.global_position = p; e.shift_pressed = shift
	Input.parse_input_event(e)
	var u := e.duplicate(); u.pressed = false
	Input.parse_input_event(u)
func free_cells() -> Array:
	var route = m.grid.route(); var out_cells := []
	for x in m.GRID_SIZE.x:
		for y in m.GRID_SIZE.y:
			var c := Vector2i(x, y)
			if m.terrain.has(c) or m.structures.has(c) or c == m.SPAWN or c == m.GOAL or route.has(c) or not m.in_reach(c): continue
			out_cells.append(c)
	out_cells.sort_custom(func(a, b): return Vector2(a).distance_to(Vector2(m.GOAL)) < Vector2(b).distance_to(Vector2(m.GOAL)))
	return out_cells
func _process(_d):
	f += 1
	if m == null: m = run.sim
	match f:
		5:
			print("build_mode at start: ", m.build_mode)
			m.start_wave()
		20:
			m.gold = 400
			var fc := free_cells(); cell = fc[2]; cell2 = fc[5]
			print("cells ", cell, " ", cell2)
			key(KEY_B)
		22:
			print("after B: build_mode=", m.build_mode, " selected=", m.selected)
			var e := InputEventMouseButton.new(); e.button_index = MOUSE_BUTTON_WHEEL_DOWN; e.pressed = true; e.position = screen(cell)
			Input.parse_input_event(e)
		24:
			print("after wheel: selected=", m.selected)
			key(KEY_2)
			move(cell)
		30: shot("a1_cursor_tag")
		31:
			click(cell, MOUSE_BUTTON_LEFT, true)
		33:
			print("shift-click: placed=", m.structures.has(cell), " build_mode=", m.build_mode)
			m.gold = 5
			move(cell2)
		38: shot("a2_cursor_short")
		39:
			m.gold = 400
			click(cell2)
		41:
			print("plain click: placed=", m.structures.has(cell2), " build_mode=", m.build_mode)
			key(KEY_B)
		42:
			click(cell, MOUSE_BUTTON_RIGHT)
		44:
			print("right click: build_mode=", m.build_mode, " tower kept=", m.structures.has(cell))
			move(cell)
		50: shot("a3_hover_menu")
		51:
			set_meta("r0", m.type_rank.get("kick", 0))
			key(KEY_U)
		52:
			print("U on hover: rank ", get_meta("r0"), " -> ", m.type_rank.get("kick", 0))
			set_meta("g0", m.gold)
			key(KEY_X)
		54:
			print("X sold: ", not m.structures.has(cell), " gold ", get_meta("g0"), " -> ", m.gold, " coins ", m.coin_pops.size())
		58: shot("a4_coin_pop")
		60:
			m._note_ctx = cell2
			m._show_feedback("SNIPE  Perfect  +3 ms", Color(1, 0.9, 0.3))
			m._note_ctx = Vector2i(-1, -1)
			print("feedback cell ", m.feedback_cell)
		64: shot("a5_perfect_at_tower")
		70:
			m._show_feedback("PERFECT PARRY  -12 ms", Color(1, 0.9, 0.3))
			m.health -= 1
		74: shot("a6_parry_at_camp_hurt")
	if f > 80:
		if m.current_section().get("kind", "lull") != "lull" or f > 4000:
			if f % 30 == 0:
				move(m.GOAL)
			if f % 30 == 20 or f > 4000:
				print("section ", m.current_section().get("name", "?"), " kind ", m.current_section().get("kind", "?"), " corner alpha ", m.hud.top_bar.modulate.r)
				shot("a7_push_faded")
				quit()
