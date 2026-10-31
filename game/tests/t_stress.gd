extends SceneTree
# Performance stress test (T-027): fills the board like a late run times N and
# times each simulation step. Args: multiplier (10 or 30), seconds to measure.
# Builds as many towers as the board takes (every type, poison everywhere), then
# spawns wave 19 x N in one go, and reports the average and worst step in ms,
# plus how many creeps and towers were on the board. A third arg "view" loads the
# whole 3D scene and times the full frame (sim, View3D, Indicators, HUD) instead;
# headless has no GPU, so this is the CPU side only.
var m; var run; var view := false; var f := 0; var mult := 10; var secs := 20.0
var max_towers := 1000
var off := ""  # view mode: a part to switch off ("view", "marks", "hud") to see what it costs.
var last_us := 0
var times: Array[float] = []; var t0 := 0.0; var peak_creeps := 0
func _init():
	var args := OS.get_cmdline_user_args()
	if args.size() > 0: mult = int(args[0])
	if args.size() > 1: secs = float(args[1])
	view = args.size() > 2 and args[2] == "view"
	if args.size() > 3: max_towers = int(args[3])
	if args.size() > 4: off = args[4]
	M7Run.quick = false
	if view:
		run = load("res://run3d.tscn").instantiate(); root.add_child(run)
	else:
		m = RunSim.new(); root.add_child(m)
func setup():
	if view:
		m = run.sim
		if off != "":
			var node: Node = m.hud if off == "hud" else run.get(off)
			node.set_process(false)
			if node is CanvasItem or node is Node3D: node.visible = false
	else: m.set_process(false)  # This test drives _process() itself and times it.
	for t in ["poison", "lightning", "light"]:
		if not m.unlocked.has(t): m._unlock(t)
	m.gold = 1000000
	m.wave = 18
	var types := ["poison", "kick", "bass", "slow", "poison", "lightning", "light", "poison"]
	var i := 0
	for x in m.GRID_SIZE.x:
		for y in m.GRID_SIZE.y:
			var c := Vector2i(x, y)
			if m.terrain.has(c) or c == m.SPAWN or c == m.GOAL or i >= max_towers: continue
			if m.try_place(c, types[i % types.size()]): i += 1
	for t in ["kick", "bass", "slow", "poison", "lightning", "light"]:
		while m.type_rank[t] < 5 and m.upgrade_type(t, 1): pass
	m.health = 1000000
	m.start_wave()
	var plan: Array = m.spawn_queue.duplicate()
	m.spawn_queue.clear()
	for k in mult:
		for e in plan:
			m.spawn_queue.append({"kind": e["kind"], "gap": 0.02})
	m._to_spawn = m.spawn_queue.size()
	print("STRESS x%d towers %d queued creeps %d" % [mult, m.structures.size(), m.spawn_queue.size()])
	t0 = Time.get_ticks_msec() / 1000.0
func _process(_d):
	f += 1
	if f == 5: setup()
	if f < 6: return
	if view:
		var now := Time.get_ticks_usec()
		if last_us > 0: times.append((now - last_us) / 1000.0)
		if times.size() <= 3 and last_us > 0: print("STRESS early frame %.1f ms" % times[-1])
		last_us = now
	else:
		var a := Time.get_ticks_usec()
		m._process(1.0 / 60.0)
		times.append((Time.get_ticks_usec() - a) / 1000.0)
	peak_creeps = maxi(peak_creeps, m.creeps.size())
	if f % 60 == 0: print("STRESS t %.1f frame %.2f ms creeps %d popups %d fps %d" % [Time.get_ticks_msec() / 1000.0 - t0, times[-1], m.creeps.size(), m._popups.size(), Engine.get_frames_per_second()])
	if Time.get_ticks_msec() / 1000.0 - t0 > secs:
		var s := times.duplicate(); s.sort()
		var total := 0.0
		for v in s: total += v
		print("STRESS x%d steps %d avg %.2f ms  p95 %.2f ms  worst %.2f ms  peak creeps %d  towers %d  popups %d" % [mult, s.size(), total / s.size(), s[int(s.size() * 0.95)], s[-1], peak_creeps, m.structures.size(), m._popups.size()])
		quit()
