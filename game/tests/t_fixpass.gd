extends SceneTree
# Playtest 1 fix pass (D-0070): a Digger's swing is parried and the wall holds; the
# counter lands on its half-beat ring; Pickup fires on the "and" of 4; the tree's
# Poison links; notes go to the creep nearest the camp; Restore's first-lock line.
var m; var f := 0; var wall := Vector2i(-1, -1); var dig: Dictionary = {}
var parried := false; var countered := false; var report := {}
func _init():
	M7Run.quick = false
	Campaign.begin(3)
	m = NightRun.new(); root.add_child(m)
func _process(_d):
	f += 1
	if f == 3:
		print("improved_poison after ", NightTree.NODES["improved_poison"]["after"], "  melodic after ", NightTree.NODES["melodic_healing"]["after"])
		for id in ["counter_attack", "well_constructed", "extended_reach", "pickup"]:
			print("take ", id, " ", m.take_night_talent(id))
		print("pickup ", m.gstats.get("pickup", false), " counter ", m.gstats.get("counter", false))
		m.start_wave()
		m.health = 99
	if f == 20:
		m.gold = 3000
		var route = m.grid.route()
		for i in range(route.size() - 3, 2, -1):
			for d in [Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 0), Vector2i(-1, 0)]:
				var c: Vector2i = route[i] + d
				if wall.x < 0 and not route.has(c) and m.try_place(c, "wall"):
					wall = c
		print("wall at ", wall)
		dig = m._spawn_creep("digger")
		if not m.creeps.has(dig): m.creeps.append(dig)
		dig["hp"] *= 20.0; dig["max_hp"] = dig["hp"]
		dig["pos"] = Vector2(wall) + Vector2(0.9, 0)
		dig["target"] = Vector2i(dig["pos"].round())
	if f < 21: return
	# Bot: parry the dig swing on time, then the counter on its ring.
	var pt: float = m.press_time()
	for cand in m._parry_candidates():
		if cand["kind"] == "dig" and absf(pt - cand["time"]) < 0.01 and not parried:
			parried = true
			m._parry()
			print("parried dig at bar %.2f   wall still there %s   counter at %s" % [m.song_bar(), m.structures.has(wall), m._counter_open.get("at", -1.0)])
	if not m._counter_open.is_empty() and m._counter_open.has("at") and absf(pt - m._counter_open["at"]) < 0.008 and not countered:
		countered = true
		var before: int = m.m7_stats.get("counter_hits", 0)
		m._parry()
		print("countered: open now %s" % [m._counter_open.is_empty()])
	if f % 300 == 0 and not dig.is_empty(): print("  t %.2f dig_until %.2f hp %.0f" % [m.beat_time(), dig.get("dig_until", -1.0), dig["hp"]])
	if f == 2400:
		print("dig state: dug %d held %d  wall there %s  digs %s" % [dig.get("dug", 0), dig.get("dig_held", 0), m.structures.has(wall), m.b2_stats])
		var t: Dictionary = m._totals()
		print("counters %d/%d" % [t["counter_hits"], t["counters"]])
		quit()
