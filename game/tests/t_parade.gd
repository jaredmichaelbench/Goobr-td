extends SceneTree
# Demo 1 look check: one of every creep kind, the boss and a few towers, no fighting.
var m; var run; var f := 0; var out := ""
func _init():
	out = OS.get_cmdline_user_args()[0]
	run = load("res://run3d.tscn").instantiate(); root.add_child(run)
func _process(_d):
	f += 1
	if m == null: m = run.sim
	if f == 3:
		m.gold = 2000
		for t in ["poison", "lightning", "light"]: m._unlock(t)
		var types := ["kick", "bass", "slow", "poison", "lightning", "light", "wall", "wall"]
		var cells := [Vector2i(3, 6), Vector2i(4, 6), Vector2i(5, 6), Vector2i(3, 11), Vector2i(4, 11), Vector2i(5, 11), Vector2i(6, 11), Vector2i(7, 11)]
		for i in types.size(): m.try_place(cells[i], types[i])
		var x := 1.0
		for k in ["grunt", "runner", "brute", "swarm", "shade", "jammer", "archer", "warden"]:
			var c = m._spawn_creep(k); c["pos"] = Vector2(x, 8); c["target"] = Vector2i(int(x) + 1, 8); c["speed"] = 0.0; c["base_speed"] = 0.0
			c["hp"] *= 0.6
			x += 1.5
		m.wave = 10; m._summon_boss(); m.boss["pos"] = Vector2(15, 8); m.boss["speed"] = 0.0
		m.add_note(m.beat_time() + 0.6, "kick", Vector2i(3, 6)); m.add_note(m.beat_time() + 0.9, "bass", Vector2i(4, 11))
		m.suppressed[Vector2i(5, 11)] = 5.0
	if f == 40:
		root.get_texture().get_image().save_png(out + "/parade.png"); print("SHOT parade"); quit()
	return false
