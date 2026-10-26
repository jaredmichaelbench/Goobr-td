extends SceneTree
# Demo 1 screenshots: loads the 3D run, plays perfect notes and parries like t_m7,
# builds a maze, and saves frames. Args: out folder, then "quick" for the 10-wave run.
var m; var run; var f := 0; var out := ""; var shots := {}
func _init():
	var args := OS.get_cmdline_user_args()
	out = args[0] if args.size() > 0 else "user://"
	M7Run.quick = args.size() > 1 and args[1] == "quick"
	run = load("res://run3d.tscn").instantiate(); root.add_child(run)
func best_cell(range_: float) -> Vector2i:
	var route = m.grid.route(); var best := Vector2i(-1, -1); var best_n := -1
	for x in m.GRID_SIZE.x:
		for y in m.GRID_SIZE.y:
			var c := Vector2i(x, y)
			if m.terrain.has(c) or m.structures.has(c) or c == m.SPAWN or c == m.GOAL or route.has(c): continue
			var n := 0
			for r in route:
				if Vector2(r).distance_to(Vector2(c)) <= range_: n += 1
			if n > best_n: best_n = n; best = c
	return best
func spend():
	var types := []
	for t in ["kick", "bass", "slow", "poison", "lightning", "light"]:
		if m.unlocked.has(t): types.append(t)
	var i := 0
	while i < 30:
		var type: String = types[m.structures.size() % types.size()]
		if m.gold < m.builds[type]["cost"] + 20: break
		var c := best_cell(m.builds[type]["range"])
		if c.x < 0 or not m.try_place(c, type): break
		i += 1
	# A few walls near the spawn so the wall joins show.
	for c in [Vector2i(3, 6), Vector2i(3, 7), Vector2i(4, 7), Vector2i(3, 10), Vector2i(3, 11)]:
		if m.gold > 10 and not m.structures.has(c): m.try_place(c, "wall")
func shot(name: String):
	if shots.has(name): return
	shots[name] = true
	root.get_texture().get_image().save_png(out + "/" + name + ".png")
	print("SHOT ", name)
func _process(_d):
	f += 1
	if m == null: m = run.sim
	if f == 3:
		m.gold += 300; spend(); m.auto_send = true
	if f == 20: shot("00_build")
	if m.drafting and f % 30 == 0:
		shot("05_draft")
		m._pick(0); spend()
	if f % 200 == 0: spend()
	for n in m.notes:
		if n["state"] == "open" and n["tower"] is Vector2i and absf(m.press_time() - n["time"]) < 0.03:
			if m.wave >= 2 and m.press_time() < n["time"] - 0.005: shot("02_note_ring")
			m._play(m.KEYS[n["type"]]); break
	for n in m.notes:
		if n["state"] == "open" and n["tower"] is Vector2i and n["time"] - m.beat_time() < 0.25 and m.wave >= 2:
			shot("01_ring_closing")
	if not m._counter_open.is_empty(): m._parry()
	for cand in m._parry_candidates():
		if cand["kind"] == "elite" and cand["time"] - m.beat_time() < 0.3: shot("03_elite_throw")
		if cand["kind"] == "bolt" and cand["time"] - m.beat_time() < 0.4: shot("06_boss_bolt")
		if absf(m.press_time() - cand["time"]) < 0.03: m._parry(); break
	if m.crescendo > 0.0: shot("07_crescendo")
	if m.wave == 3 and m.wave_active and m.creeps.size() > 6: shot("04_wave3")
	if not m.suppressed.is_empty(): shot("08_locked")
	if m.wave >= 6: m.selected_cell = m.structures.keys()[0]; shot("09_selected")
	if m.state != "playing" or f > 60000 or m.wave > 6:
		shot("10_end")
		print("END state %s wave %d health %d" % [m.state, m.wave, m.health]); quit()
	return false
